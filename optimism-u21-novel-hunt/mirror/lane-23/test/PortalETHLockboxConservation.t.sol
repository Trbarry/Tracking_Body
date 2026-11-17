// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

struct WithdrawalTransaction {
    uint256 nonce;
    address sender;
    address target;
    uint256 value;
    uint256 gasLimit;
    bytes data;
}

interface IPortalLane23 {
    function depositTransaction(address, uint256, uint64, bool, bytes memory) external payable;
    function donateETH() external payable;
    function migrateLiquidity() external;
    function migrateToSharedDisputeGame(address, address) external;
    function finalizeWithdrawalTransactionExternalProof(WithdrawalTransaction memory, address) external;
    function checkWithdrawal(bytes32, address) external view;
    function deleteProvenWithdrawal(bytes32, address) external;
    function finalizedWithdrawals(bytes32) external view returns (bool);
    function l2Sender() external view returns (address);
    function ethLockbox() external view returns (address);
}

interface ILockboxLane23 {
    function lockETH() external payable;
    function unlockETH(uint256) external;
    function receiveLiquidity() external payable;
    function migrateLiquidity(address) external;
    function paused() external view returns (bool);
}

interface ISystemConfigLane23 {
    function isFeatureEnabled(bytes32) external view returns (bool);
}

library WithdrawalFixture23 {
    bytes32 internal constant HASH = 0xb16e5fc2aab1c33e0426b1ad64aa82484b4fe2a637027d2854ad00677f7ed612;
    address internal constant SUBMITTER = 0x67E10B7764A99165665557B3E6cF24555bfC88c3;

    function transaction() internal pure returns (WithdrawalTransaction memory txn_) {
        txn_ = WithdrawalTransaction({
            nonce: 1766847064778384329583297500742918515827483896875618958121606201292655285,
            sender: 0x4200000000000000000000000000000000000007,
            target: 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1,
            value: 638177259920741319864,
            gasLimit: 313808,
            data: hex"d764ad0b0001000000000000000000000000000000000000000000000000000000008a91000000000000000000000000c9475e18e2c5c26ea6adcd55fabe07920bea887e00000000000000000000000023ca5e5300d3b35a47dfef6a36ecba5ac0a96e03000000000000000000000000000000000000000000000022987d14b09beb44b8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000e43a69197e000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000759f51ebeaa40a4a059535ac7d0ebd606bd55f07c3fbfa4ca923b159d8171a335bb1000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000000000000000000000000022987d14b09beb44b800000000000000000000000000000000000000000000001f3b950f998da42d3f00000000000000000000000000000000000000000000000000000000"
        });
    }

    function hash(WithdrawalTransaction memory txn_) internal pure returns (bytes32) {
        return keccak256(abi.encode(txn_.nonce, txn_.sender, txn_.target, txn_.value, txn_.gasLimit, txn_.data));
    }
}

/// @dev Etched over the real withdrawal target only in a local fork. A second finalize must fail
///      at the portal's l2Sender guard before another unlock can occur.
contract ReenterFinalizeTarget23 {
    IPortalLane23 internal constant PORTAL = IPortalLane23(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);

    fallback() external payable {
        WithdrawalTransaction memory txn_ = WithdrawalFixture23.transaction();
        (bool ok, bytes memory returndata) = address(PORTAL).call(
            abi.encodeCall(
                IPortalLane23.finalizeWithdrawalTransactionExternalProof,
                (txn_, WithdrawalFixture23.SUBMITTER)
            )
        );
        require(!ok, "reentrant finalize unexpectedly succeeded");
        require(returndata.length >= 4, "missing reentrancy error");
        bytes4 actual;
        assembly {
            actual := mload(add(returndata, 0x20))
        }
        require(actual == bytes4(keccak256("OptimismPortal_NoReentrancy()")), "wrong reentrancy error");
    }
}

/// @dev Etched over the real withdrawal target only in a local fork. It re-deposits one ETH from
///      the value just unlocked, creating a new L2 liability backed by the same one ETH.
contract ReenterDepositTarget23 {
    IPortalLane23 internal constant PORTAL = IPortalLane23(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);

    fallback() external payable {
        PORTAL.depositTransaction{ value: 1 ether }(address(this), 1 ether, 100_000, false, bytes(""));
    }
}

contract RevertingTarget23 {
    fallback() external payable {
        revert("target failure");
    }
}

contract ForceETH23 {
    constructor() payable { }

    function force(address payable target_) external {
        selfdestruct(target_);
    }
}

contract PortalETHLockboxConservationTest is Test {
    IPortalLane23 internal constant PORTAL = IPortalLane23(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    ILockboxLane23 internal constant LOCKBOX = ILockboxLane23(0x322b47Ff1FA8D5611F761e3E275C45B71b294D43);
    ISystemConfigLane23 internal constant SYSTEM_CONFIG =
        ISystemConfigLane23(0x229047fed2591dbec1eF1118d64F7aF3dB9EB290);
    address internal constant PROXY_ADMIN_OWNER = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A;
    address internal constant DEFAULT_L2_SENDER = address(0xdead);
    bytes32 internal constant CUSTOM_GAS_TOKEN = bytes32("CUSTOM_GAS_TOKEN");

    function setUp() public {
        vm.createSelectFork("l1");
        assertEq(block.number, 26_433_900);
        assertEq(PORTAL.ethLockbox(), address(LOCKBOX));
    }

    function test_depositMovesValueDirectlyIntoLockbox() public {
        vm.deal(address(this), 2 ether);
        uint256 lockboxBefore = address(LOCKBOX).balance;

        PORTAL.depositTransaction{ value: 1 ether }(address(this), 1 ether, 100_000, false, bytes(""));

        assertEq(address(PORTAL).balance, 0);
        assertEq(address(LOCKBOX).balance, lockboxBefore + 1 ether);
        assertEq(address(this).balance, 1 ether);
    }

    function test_receiveAlsoMovesValueDirectlyIntoLockbox() public {
        vm.deal(address(this), 1 ether);
        uint256 lockboxBefore = address(LOCKBOX).balance;

        (bool ok,) = address(PORTAL).call{ value: 0.25 ether }(bytes(""));

        assertTrue(ok);
        assertEq(address(PORTAL).balance, 0);
        assertEq(address(LOCKBOX).balance, lockboxBefore + 0.25 ether);
    }

    function test_donationAndForcedETHStayInPortalUntilAdminMigration() public {
        vm.deal(address(this), 3 ether);
        uint256 lockboxBefore = address(LOCKBOX).balance;
        uint256 portalBefore = address(PORTAL).balance;
        PORTAL.donateETH{ value: 1 ether }();
        ForceETH23 force = new ForceETH23();
        // A deterministic CREATE address can already contain forced dust on a mainnet fork.
        vm.deal(address(force), 1 ether);
        force.force(payable(address(PORTAL)));

        assertEq(address(PORTAL).balance, portalBefore + 2 ether);
        assertEq(address(LOCKBOX).balance, lockboxBefore);

        // Privileged impersonation is only used to exercise the production admin sweep path.
        vm.prank(PROXY_ADMIN_OWNER);
        PORTAL.migrateLiquidity();
        assertEq(address(PORTAL).balance, 0);
        assertEq(address(LOCKBOX).balance, lockboxBefore + portalBefore + 2 ether);
    }

    function test_realMatureWithdrawalFinalizesAndConservesValue() public {
        WithdrawalTransaction memory txn_ = WithdrawalFixture23.transaction();
        bytes32 withdrawalHash = WithdrawalFixture23.hash(txn_);
        assertEq(withdrawalHash, WithdrawalFixture23.HASH);
        assertFalse(PORTAL.finalizedWithdrawals(withdrawalHash));
        PORTAL.checkWithdrawal(withdrawalHash, WithdrawalFixture23.SUBMITTER);

        uint256 lockboxBefore = address(LOCKBOX).balance;
        uint256 portalBefore = address(PORTAL).balance;
        PORTAL.finalizeWithdrawalTransactionExternalProof(txn_, WithdrawalFixture23.SUBMITTER);

        assertTrue(PORTAL.finalizedWithdrawals(withdrawalHash));
        assertEq(address(LOCKBOX).balance, lockboxBefore - txn_.value);
        assertEq(address(PORTAL).balance, portalBefore);
        assertEq(PORTAL.l2Sender(), DEFAULT_L2_SENDER);

        vm.expectRevert(bytes4(keccak256("OptimismPortal_AlreadyFinalized()")));
        PORTAL.finalizeWithdrawalTransactionExternalProof(txn_, WithdrawalFixture23.SUBMITTER);
    }

    function test_realProofEtchedMessengerFailureRevertsUnlockAndFinalization() public {
        WithdrawalTransaction memory txn_ = WithdrawalFixture23.transaction();
        bytes32 withdrawalHash = WithdrawalFixture23.hash(txn_);
        uint256 lockboxBefore = address(LOCKBOX).balance;
        uint256 portalBefore = address(PORTAL).balance;

        // Local-only target-code substitution. The real proof and deployed portal/lockbox remain intact.
        RevertingTarget23 replacement = new RevertingTarget23();
        vm.etch(txn_.target, address(replacement).code);

        vm.expectRevert(bytes4(keccak256("OptimismPortal_L1CDMCallFailed()")));
        PORTAL.finalizeWithdrawalTransactionExternalProof(txn_, WithdrawalFixture23.SUBMITTER);

        assertFalse(PORTAL.finalizedWithdrawals(withdrawalHash));
        assertEq(address(LOCKBOX).balance, lockboxBefore);
        assertEq(address(PORTAL).balance, portalBefore);
        assertEq(PORTAL.l2Sender(), DEFAULT_L2_SENDER);
    }

    function test_modeledDirectWithdrawalFailureRelocksExactValueAndPreservesPortalSurplus() public {
        // Use the exact end-of-upgrade-block fork and advance only time to proof maturity. This
        // keeps the arbitrary modeled mapping slot isolated from the rate-limited later fork cache.
        vm.createSelectFork("l1n");
        vm.warp(1_794_908_075);
        WithdrawalTransaction memory txn_ = WithdrawalFixture23.transaction();
        txn_.sender = address(0x1234); // Non-messenger withdrawals take the finalize-and-relock branch.
        txn_.value = 1 ether;
        bytes32 modeledHash = WithdrawalFixture23.hash(txn_);

        // Local-only reachability setup: copy the real fixture's valid ProvenWithdrawal word to the
        // modeled hash. The portal and lockbox code remain the deployed implementations.
        bytes32 realProofSlot = _proofSlot(WithdrawalFixture23.HASH, WithdrawalFixture23.SUBMITTER);
        bytes32 modeledProofSlot = _proofSlot(modeledHash, WithdrawalFixture23.SUBMITTER);
        bytes32 realProof = vm.load(address(PORTAL), realProofSlot);
        assertNotEq(realProof, bytes32(0));
        vm.store(address(PORTAL), modeledProofSlot, realProof);
        PORTAL.checkWithdrawal(modeledHash, WithdrawalFixture23.SUBMITTER);

        vm.deal(address(this), 2 ether);
        PORTAL.donateETH{ value: 2 ether }();
        uint256 lockboxBefore = address(LOCKBOX).balance;
        uint256 portalBefore = address(PORTAL).balance;
        RevertingTarget23 replacement = new RevertingTarget23();
        vm.etch(txn_.target, address(replacement).code);

        PORTAL.finalizeWithdrawalTransactionExternalProof(txn_, WithdrawalFixture23.SUBMITTER);

        assertTrue(PORTAL.finalizedWithdrawals(modeledHash));
        assertEq(address(LOCKBOX).balance, lockboxBefore);
        assertEq(address(PORTAL).balance, portalBefore);
        assertEq(PORTAL.l2Sender(), DEFAULT_L2_SENDER);
    }

    function test_realProofEtchedReentrantFinalizeCannotDoubleUnlock() public {
        WithdrawalTransaction memory txn_ = WithdrawalFixture23.transaction();
        uint256 lockboxBefore = address(LOCKBOX).balance;
        uint256 targetBefore = txn_.target.balance;

        // Local-only target-code substitution. The fixture target is fixed by the real withdrawal hash.
        ReenterFinalizeTarget23 replacement = new ReenterFinalizeTarget23();
        vm.etch(txn_.target, address(replacement).code);
        PORTAL.finalizeWithdrawalTransactionExternalProof(txn_, WithdrawalFixture23.SUBMITTER);

        assertTrue(PORTAL.finalizedWithdrawals(WithdrawalFixture23.HASH));
        assertEq(address(LOCKBOX).balance, lockboxBefore - txn_.value);
        assertEq(address(PORTAL).balance, 0);
        assertEq(txn_.target.balance, targetBefore + txn_.value);
        assertEq(PORTAL.l2Sender(), DEFAULT_L2_SENDER);
    }

    function test_realProofEtchedReentrantDepositRelocksExactlyNestedValue() public {
        WithdrawalTransaction memory txn_ = WithdrawalFixture23.transaction();
        uint256 lockboxBefore = address(LOCKBOX).balance;
        uint256 targetBefore = txn_.target.balance;

        // Local-only target-code substitution. One ETH of the unlocked value is deposited again.
        ReenterDepositTarget23 replacement = new ReenterDepositTarget23();
        vm.etch(txn_.target, address(replacement).code);
        PORTAL.finalizeWithdrawalTransactionExternalProof(txn_, WithdrawalFixture23.SUBMITTER);

        assertTrue(PORTAL.finalizedWithdrawals(WithdrawalFixture23.HASH));
        assertEq(address(LOCKBOX).balance, lockboxBefore - txn_.value + 1 ether);
        assertEq(address(PORTAL).balance, 0);
        assertEq(txn_.target.balance, targetBefore + txn_.value - 1 ether);
        assertEq(PORTAL.l2Sender(), DEFAULT_L2_SENDER);
    }

    function test_badTargetsRejectedBeforeProofLookup() public {
        WithdrawalTransaction memory txn_ = WithdrawalFixture23.transaction();
        txn_.target = address(PORTAL);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_BadTarget()")));
        PORTAL.finalizeWithdrawalTransactionExternalProof(txn_, WithdrawalFixture23.SUBMITTER);

        txn_.target = address(LOCKBOX);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_BadTarget()")));
        PORTAL.finalizeWithdrawalTransactionExternalProof(txn_, WithdrawalFixture23.SUBMITTER);
    }

    function test_lockboxRejectsUnauthorizedAndInWithdrawalUnlocks() public {
        vm.expectRevert(bytes4(keccak256("ETHLockbox_Unauthorized()")));
        LOCKBOX.unlockETH(1);

        vm.expectRevert(bytes4(keccak256("ETHLockbox_Unauthorized()")));
        LOCKBOX.lockETH{ value: 0 }();

        // Local storage mutation models the exact interval after the portal sets l2Sender.
        vm.store(address(PORTAL), bytes32(uint256(50)), bytes32(uint256(uint160(address(0xbeef)))));
        vm.prank(address(PORTAL));
        vm.expectRevert(bytes4(keccak256("ETHLockbox_NoWithdrawalTransactions()")));
        LOCKBOX.unlockETH(1);
    }

    function test_pauseBlocksFinalizationButNotAdditionalLocking() public {
        vm.deal(address(this), 1 ether);
        uint256 lockboxBefore = address(LOCKBOX).balance;
        vm.mockCall(address(LOCKBOX), abi.encodeCall(ILockboxLane23.paused, ()), abi.encode(true));

        PORTAL.depositTransaction{ value: 1 ether }(address(this), 1 ether, 100_000, false, bytes(""));
        assertEq(address(LOCKBOX).balance, lockboxBefore + 1 ether);

        vm.expectRevert(bytes4(keccak256("OptimismPortal_CallPaused()")));
        PORTAL.finalizeWithdrawalTransactionExternalProof(
            WithdrawalFixture23.transaction(), WithdrawalFixture23.SUBMITTER
        );
    }

    function test_cgtModeRejectsETHLiabilityPathsButDonationStillAccepts() public {
        bytes32 featureSlot = keccak256(abi.encode(CUSTOM_GAS_TOKEN, uint256(109)));
        vm.store(address(SYSTEM_CONFIG), featureSlot, bytes32(uint256(1)));
        assertTrue(SYSTEM_CONFIG.isFeatureEnabled(CUSTOM_GAS_TOKEN));
        vm.deal(address(this), 2 ether);

        vm.expectRevert(bytes4(keccak256("OptimismPortal_NotAllowedOnCGTMode()")));
        PORTAL.depositTransaction{ value: 1 ether }(address(this), 1 ether, 100_000, false, bytes(""));

        vm.expectRevert(bytes4(keccak256("OptimismPortal_NotAllowedOnCGTMode()")));
        PORTAL.finalizeWithdrawalTransactionExternalProof(
            WithdrawalFixture23.transaction(), WithdrawalFixture23.SUBMITTER
        );

        uint256 portalBefore = address(PORTAL).balance;
        PORTAL.donateETH{ value: 1 ether }();
        assertEq(address(PORTAL).balance, portalBefore + 1 ether);

        // Privileged impersonation only reaches and verifies the CGT migration guard.
        vm.prank(PROXY_ADMIN_OWNER);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_NotAllowedOnCGTMode()")));
        PORTAL.migrateLiquidity();
    }

    function test_migrationAndProofDeletionGuards() public {
        vm.expectRevert(bytes4(keccak256("ProxyAdminOwnedBase_NotProxyAdminOwner()")));
        PORTAL.migrateLiquidity();

        vm.expectRevert(bytes4(keccak256("OptimismPortal_NotUsingInterop()")));
        PORTAL.migrateToSharedDisputeGame(address(1), address(2));

        vm.expectRevert(bytes4(keccak256("ETHLockbox_Unauthorized()")));
        LOCKBOX.receiveLiquidity{ value: 0 }();

        vm.expectRevert(bytes4(keccak256("ProxyAdminOwnedBase_NotProxyAdminOwner()")));
        LOCKBOX.migrateLiquidity(address(1));

        vm.expectRevert(bytes4(keccak256("OptimismPortal_DisputeGameNotInvalidated()")));
        PORTAL.deleteProvenWithdrawal(WithdrawalFixture23.HASH, WithdrawalFixture23.SUBMITTER);
    }

    function _proofSlot(bytes32 withdrawalHash_, address submitter_) internal pure returns (bytes32) {
        bytes32 outer = keccak256(abi.encode(withdrawalHash_, uint256(57)));
        return keccak256(abi.encode(submitter_, outer));
    }
}
