// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "./Lane09Migrate.t.sol";

struct WithdrawalTransaction {
    uint256 nonce;
    address sender;
    address target;
    uint256 value;
    uint256 gasLimit;
    bytes data;
}

interface IPortalFin {
    function finalizeWithdrawalTransaction(WithdrawalTransaction memory) external;
    function finalizedWithdrawals(bytes32) external view returns (bool);
}

/// @notice LANE 09. Post-migration (OP Mainnet + Unichain shared ETHLockbox) call-context probes.
///         The migration itself is the PLANNED documented governance action, executed here through the
///         real deployed OPCM as the ProxyAdmin-owner Safe. Withdrawal *proof validity* is MOCKED
///         (vm.store of provenWithdrawals + vm.mockCall of ASR.isGameClaimValid) purely to drive the real
///         portal/lockbox code with an arbitrary L2-originated withdrawal; nothing here claims a proof bypass.
contract Lane09PostMigrationTest is Lane09Base {
    address constant ATTACKER_L2 = address(0xA77AC4E2);
    address constant FAKE_GAME = address(0xF00DCAFE);
    uint256 nonce = 1 << 240;

    function setUp() public {
        vm.createSelectFork("l1");
        _migrate();
    }

    function _hash(WithdrawalTransaction memory t) internal pure returns (bytes32) {
        return keccak256(abi.encode(t.nonce, t.sender, t.target, t.value, t.gasLimit, t.data));
    }

    /// @dev mocks "this withdrawal was validly proven 8 days ago against a valid game"
    function _mockProven(IPortal portal, WithdrawalTransaction memory t) internal {
        bytes32 h = _hash(t);
        bytes32 outer = keccak256(abi.encode(h, uint256(57)));
        bytes32 slot = keccak256(abi.encode(address(this), outer));
        uint256 ts = block.timestamp - 8 days;
        vm.store(address(portal), slot, bytes32((ts << 160) | uint256(uint160(FAKE_GAME))));
        vm.mockCall(FAKE_GAME, abi.encodeWithSignature("createdAt()"), abi.encode(uint64(ts - 1)));
        vm.mockCall(
            portal.anchorStateRegistry(), abi.encodeWithSignature("isGameClaimValid(address)", FAKE_GAME), abi.encode(true)
        );
    }

    function _wd(address target, uint256 value, bytes memory data) internal returns (WithdrawalTransaction memory t) {
        t = WithdrawalTransaction({ nonce: nonce++, sender: ATTACKER_L2, target: target, value: value, gasLimit: 300_000, data: data });
    }

    /// target == shared lockbox is rejected before anything else (BadTarget), on both portals.
    function test_post_target_sharedLockbox_isBadTarget() public {
        WithdrawalTransaction memory t = _wd(address(sharedLB), 0, abi.encodeWithSignature("unlockETH(uint256)", 1 ether));
        _mockProven(OP_PORTAL, t);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_BadTarget()")));
        IPortalFin(address(OP_PORTAL)).finalizeWithdrawalTransaction(t);
        _mockProven(UNI_PORTAL, t);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_BadTarget()")));
        IPortalFin(address(UNI_PORTAL)).finalizeWithdrawalTransaction(t);
    }

    /// PRIM-0901: the retired per-chain lockbox is NOT an unsafe target any more and still authorizes the
    /// portal. lockETH{value} from a withdrawal succeeds (ETH stranded in retired lockbox); unlockETH is
    /// stopped only by the l2Sender guard.
    function test_post_target_oldLockbox_lockSucceeds_unlockBlocked() public {
        uint256 sharedBefore = address(sharedLB).balance;
        assertEq(address(OP_LB).balance, 0);
        assertTrue(OP_LB.authorizedPortals(address(OP_PORTAL)));

        // (a) withdrawal value 1 ETH -> old lockbox.lockETH()
        WithdrawalTransaction memory t = _wd(address(OP_LB), 1 ether, abi.encodeWithSignature("lockETH()"));
        _mockProven(OP_PORTAL, t);
        IPortalFin(address(OP_PORTAL)).finalizeWithdrawalTransaction(t);
        assertEq(address(OP_LB).balance, 1 ether, "stranded in retired lockbox");
        assertEq(address(sharedLB).balance, sharedBefore - 1 ether);

        // (b) try to pull it back out with unlockETH from a second withdrawal: sub-call reverts with
        //     ETHLockbox_NoWithdrawalTransactions, withdrawal is finalized as failed, nothing moves.
        WithdrawalTransaction memory u = _wd(address(OP_LB), 0, abi.encodeWithSignature("unlockETH(uint256)", 1 ether));
        _mockProven(OP_PORTAL, u);
        vm.expectCall(address(OP_LB), abi.encodeWithSignature("unlockETH(uint256)", 1 ether));
        IPortalFin(address(OP_PORTAL)).finalizeWithdrawalTransaction(u);
        assertTrue(IPortalFin(address(OP_PORTAL)).finalizedWithdrawals(_hash(u)));
        assertEq(address(OP_LB).balance, 1 ether, "still stranded");
        assertEq(address(OP_PORTAL).balance, 0);

        // direct proof of which guard fires: msg.sender == portal while l2Sender != DEFAULT
        vm.store(address(OP_PORTAL), bytes32(uint256(50)), bytes32(uint256(uint160(ATTACKER_L2))));
        vm.prank(address(OP_PORTAL));
        vm.expectRevert(bytes4(keccak256("ETHLockbox_NoWithdrawalTransactions()")));
        OP_LB.unlockETH(1 ether);
        vm.store(address(OP_PORTAL), bytes32(uint256(50)), bytes32(uint256(uint160(DEFAULT_L2_SENDER))));

        // other portal of the set is not authorized on OP's retired lockbox
        vm.prank(address(UNI_PORTAL));
        vm.expectRevert(bytes4(keccak256("ETHLockbox_Unauthorized()")));
        OP_LB.unlockETH(1 ether);

        // only the ProxyAdmin owner can recover it
        vm.prank(SAFE);
        OP_LB.migrateLiquidity(address(sharedLB));
        assertEq(address(sharedLB).balance, sharedBefore);
    }

    /// Cross-portal: OP withdrawal -> Unichain portal.depositTransaction{value}. Value is conserved in the
    /// shared lockbox (unlock by OP portal, re-lock by UNI portal). No authority is gained.
    function test_post_crossPortal_deposit_conserves() public {
        uint256 sharedBefore = address(sharedLB).balance;
        WithdrawalTransaction memory t = _wd(
            address(UNI_PORTAL),
            3 ether,
            abi.encodeWithSignature("depositTransaction(address,uint256,uint64,bool,bytes)", ATTACKER_L2, 3 ether, uint64(100000), false, "")
        );
        _mockProven(OP_PORTAL, t);
        IPortalFin(address(OP_PORTAL)).finalizeWithdrawalTransaction(t);
        assertEq(address(sharedLB).balance, sharedBefore);
        assertEq(address(UNI_PORTAL).balance, 0);
        assertEq(address(OP_PORTAL).balance, 0);
    }

    /// Cross-portal: OP withdrawal -> UNI portal privileged functions / UNI retired lockbox: all fail,
    /// withdrawal value is re-locked into the shared lockbox.
    function test_post_crossPortal_privileged_calls_fail() public {
        uint256 sharedBefore = address(sharedLB).balance;
        bytes[4] memory datas = [
            abi.encodeWithSignature("migrateLiquidity()"),
            abi.encodeWithSignature("migrateToSharedDisputeGame(address,address)", address(OP_LB), address(OP_ASR)),
            abi.encodeWithSignature("initialize(address,address,address)", address(OP_SC), address(OP_ASR), address(OP_LB)),
            abi.encodeWithSignature("lockETH()")
        ];
        address[4] memory targets = [address(UNI_PORTAL), address(UNI_PORTAL), address(UNI_PORTAL), address(UNI_LB)];
        for (uint256 i; i < 4; i++) {
            WithdrawalTransaction memory t = _wd(targets[i], i == 3 ? 1 ether : 0, datas[i]);
            _mockProven(OP_PORTAL, t);
            vm.expectEmit(true, false, false, true, address(OP_PORTAL));
            emit WithdrawalFinalized(_hash(t), false);
            IPortalFin(address(OP_PORTAL)).finalizeWithdrawalTransaction(t);
        }
        assertEq(address(sharedLB).balance, sharedBefore);
        assertEq(UNI_PORTAL.ethLockbox(), address(sharedLB));
    }

    event WithdrawalFinalized(bytes32 indexed withdrawalHash, bool success);

    /// Documented trust model (NOT a finding): once shared, one portal can unlock more than its chain
    /// contributed. Shown only to pin the number: Unichain contributed ~18.27k ETH.
    function test_post_pooledLiability_byDesign() public {
        address rcpt = address(0xBEEF01);
        WithdrawalTransaction memory t = _wd(rcpt, 100_000 ether, "");
        _mockProven(UNI_PORTAL, t);
        IPortalFin(address(UNI_PORTAL)).finalizeWithdrawalTransaction(t);
        assertEq(rcpt.balance, 100_000 ether);
    }

    /// PRIM-0902: permissionless 1-wei donation after migration falsifies the validator's
    /// `portal.balance == 0` equality (MIG-CHAIN-N-150); only the ProxyAdmin owner can sweep.
    function test_post_donation_breaks_validator_equality() public {
        vm.deal(address(this), 1);
        OP_PORTAL.donateETH{ value: 1 }();
        assertEq(address(OP_PORTAL).balance, 1);
        vm.expectRevert();
        OP_PORTAL.migrateLiquidity(); // not owner
        vm.prank(SAFE);
        OP_PORTAL.migrateLiquidity();
        assertEq(address(OP_PORTAL).balance, 0);
    }
}

/// @notice LANE 09. Present-state (block 26433900, INTEROP false) isolation checks, real bytecode, no mocks.
contract Lane09TodayTest is Lane09Base {
    ILockbox constant INK_LB = ILockbox(0xbd4AbB321138e8Eddc399cE64E66451294325a14);
    ILockbox constant SON_LB = ILockbox(0x67B4de6FfA66EF201Ea6099A89cA397D56622E31);
    IPortal constant INK_PORTAL = IPortal(0x5d66C1782664115999C47c9fA5cd031f495D3e4F);
    IPortal constant SON_PORTAL = IPortal(0x88e529A6ccd302c948689Cd5156C83D4614FAE92);

    function setUp() public {
        vm.createSelectFork("l1");
    }

    function test_today_crossProduct_isolation() public {
        ILockbox[4] memory lbs = [OP_LB, UNI_LB, INK_LB, SON_LB];
        IPortal[4] memory ps = [OP_PORTAL, UNI_PORTAL, INK_PORTAL, SON_PORTAL];
        for (uint256 i; i < 4; i++) {
            for (uint256 j; j < 4; j++) {
                assertEq(lbs[i].authorizedPortals(address(ps[j])), i == j);
                assertFalse(lbs[i].authorizedLockboxes(address(lbs[j])));
                if (i != j) {
                    vm.deal(address(ps[j]), 1 ether);
                    vm.prank(address(ps[j]));
                    vm.expectRevert(bytes4(keccak256("ETHLockbox_Unauthorized()")));
                    lbs[i].lockETH{ value: 1 }();
                    vm.prank(address(ps[j]));
                    vm.expectRevert(bytes4(keccak256("ETHLockbox_Unauthorized()")));
                    lbs[i].unlockETH(1);
                    vm.prank(address(lbs[j]));
                    vm.expectRevert(bytes4(keccak256("ETHLockbox_Unauthorized()")));
                    lbs[i].receiveLiquidity();
                    vm.deal(address(ps[j]), 0);
                }
            }
            assertEq(ps[i].ethLockbox(), address(lbs[i]));
        }
    }

    function test_today_ownLockbox_isBadTarget_and_adminFns_closed() public {
        WithdrawalTransaction memory t = WithdrawalTransaction({
            nonce: 1, sender: address(0xA77AC4E2), target: address(OP_LB), value: 0, gasLimit: 100000,
            data: abi.encodeWithSignature("unlockETH(uint256)", 1 ether)
        });
        vm.expectRevert(bytes4(keccak256("OptimismPortal_BadTarget()")));
        IPortalFin(address(OP_PORTAL)).finalizeWithdrawalTransaction(t);

        vm.expectRevert(bytes4(keccak256("ProxyAdminOwnedBase_NotProxyAdminOwner()")));
        OP_LB.authorizePortal(address(UNI_PORTAL));
        vm.expectRevert(bytes4(keccak256("ProxyAdminOwnedBase_NotProxyAdminOwner()")));
        OP_LB.authorizeLockbox(address(UNI_LB));
        vm.expectRevert(bytes4(keccak256("ProxyAdminOwnedBase_NotProxyAdminOwner()")));
        OP_LB.migrateLiquidity(address(UNI_LB));
        vm.expectRevert(bytes4(keccak256("ETHLockbox_Unauthorized()")));
        OP_LB.receiveLiquidity{ value: 0 }();
        vm.expectRevert(bytes4(keccak256("ETHLockbox_Unauthorized()")));
        OP_LB.unlockETH(1);
        // the authorized portal itself, but inside a withdrawal (l2Sender != DEFAULT)
        vm.store(address(OP_PORTAL), bytes32(uint256(50)), bytes32(uint256(0xA77AC4E2)));
        vm.prank(address(OP_PORTAL));
        vm.expectRevert(bytes4(keccak256("ETHLockbox_NoWithdrawalTransactions()")));
        OP_LB.unlockETH(1);
    }
}
