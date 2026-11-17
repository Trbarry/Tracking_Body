// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// LANE 03 — Portal / ETHLockbox conservation. Fork tests against the REAL deployed post-U21
// implementations on Ethereum mainnet @ 26433900 (local anvil `l1`). Nothing is broadcast.
//
// Withdrawals in Fixtures.sol are REAL OP Mainnet withdrawals (MessagePassed logs on L2) that are
// proven on L1 and not finalized at the fork block. Wherever a test substitutes behaviour with
// vm.etch / vm.mockCallRevert / vm.prank(privileged) it says so in a `// SUBSTITUTION:` comment.

import "forge-std/Test.sol";
import { Fixtures, Fixture, WithdrawalTransaction } from "./Fixtures.sol";

interface IPortal {
    function version() external view returns (string memory);
    function ethLockbox() external view returns (address);
    function systemConfig() external view returns (address);
    function anchorStateRegistry() external view returns (address);
    function paused() external view returns (bool);
    function l2Sender() external view returns (address);
    function finalizedWithdrawals(bytes32) external view returns (bool);
    function provenWithdrawals(bytes32, address) external view returns (address game, uint64 ts);
    function numProofSubmitters(bytes32) external view returns (uint256);
    function checkWithdrawal(bytes32, address) external view;
    function donateETH() external payable;
    function depositTransaction(address, uint256, uint64, bool, bytes memory) external payable;
    function finalizeWithdrawalTransaction(WithdrawalTransaction memory) external;
    function finalizeWithdrawalTransactionExternalProof(WithdrawalTransaction memory, address) external;
    function proveWithdrawalTransaction(
        WithdrawalTransaction memory,
        uint256,
        OutputRootProof calldata,
        bytes[] calldata
    )
        external;
    function deleteProvenWithdrawal(bytes32, address) external;
    function migrateLiquidity() external;
    function migrateToSharedDisputeGame(address, address) external;
    function initialize(address, address, address) external;
}

struct OutputRootProof {
    bytes32 version;
    bytes32 stateRoot;
    bytes32 messagePasserStorageRoot;
    bytes32 latestBlockhash;
}

interface ILockbox {
    function version() external view returns (string memory);
    function paused() external view returns (bool);
    function authorizedPortals(address) external view returns (bool);
    function authorizedLockboxes(address) external view returns (bool);
    function superchainConfig() external view returns (address);
    function lockETH() external payable;
    function unlockETH(uint256) external;
    function receiveLiquidity() external payable;
    function migrateLiquidity(address) external;
    function authorizePortal(address) external;
    function authorizeLockbox(address) external;
    function initialize(address, address[] calldata) external;
}

interface ICDM {
    function successfulMessages(bytes32) external view returns (bool);
    function failedMessages(bytes32) external view returns (bool);
    function xDomainMessageSender() external view returns (address);
    function paused() external view returns (bool);
}

interface ISystemConfig {
    function isFeatureEnabled(bytes32) external view returns (bool);
    function setFeature(bytes32, bool) external;
    function paused() external view returns (bool);
}

interface ISuperchainConfig {
    function pause(address) external;
    function paused(address) external view returns (bool);
    function guardian() external view returns (address);
}

interface IGame {
    function resolveClaim(uint256, uint256) external;
    function resolve() external returns (uint8);
    function status() external view returns (uint8);
    function createdAt() external view returns (uint64);
}

interface IASR {
    function isGameClaimValid(address) external view returns (bool);
    function paused() external view returns (bool);
    function ethLockbox() external view returns (address);
}

/// @dev Adversarial code etched over a withdrawal recipient/target. Records what each re-entrant
///      attempt did. All state lives in this contract's own storage.
contract Reenter {
    IPortal constant PORTAL = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    ILockbox constant LOCKBOX = ILockbox(0x322b47Ff1FA8D5611F761e3E275C45B71b294D43);
    address constant CDM = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;

    // configuration
    address public probeVia; // optional forwarder for the direct lockbox probes
    bytes public otherFinalizeCalldata; // abi-encoded finalizeWithdrawalTransactionExternalProof(...)
    bytes public replayCalldata; // L1CDM.relayMessage(...) of the message being relayed
    uint256 public depositBack; // amount to re-deposit through the portal
    uint256 public donateBack; // amount to donate to the portal
    bool public revertAtEnd; // revert after doing everything
    bool public burnGas; // consume all gas

    // observations
    uint256 public calls;
    uint256 public received;
    address public seenL2Sender;
    bytes4 public errFinalize;
    bool public okFinalize;
    bytes4 public errUnlock;
    bool public okUnlock;
    bytes4 public errLock;
    bool public okLock;
    bool public okReplay;
    bytes public errReplay;
    bool public okDeposit;
    bool public okDonate;
    bytes4 public errMigrate;
    bool public okMigrate;

    function setProbeVia(address _via) external {
        probeVia = _via;
    }

    function arm(
        bytes calldata _otherFinalize,
        bytes calldata _replay,
        uint256 _depositBack,
        uint256 _donateBack,
        bool _revertAtEnd,
        bool _burnGas
    )
        external
    {
        otherFinalizeCalldata = _otherFinalize;
        replayCalldata = _replay;
        depositBack = _depositBack;
        donateBack = _donateBack;
        revertAtEnd = _revertAtEnd;
        burnGas = _burnGas;
    }

    function _sel(bytes memory r) internal pure returns (bytes4 s) {
        if (r.length >= 4) {
            assembly {
                s := mload(add(r, 32))
            }
        }
    }

    receive() external payable {
        _run();
    }

    fallback() external payable {
        _run();
    }

    function _run() internal {
        if (burnGas) {
            while (true) { }
        }
        calls++;
        received += msg.value;
        seenL2Sender = PORTAL.l2Sender();

        bytes memory r;
        // 1. nested finalize of ANOTHER ready withdrawal
        if (otherFinalizeCalldata.length != 0) {
            (okFinalize, r) = address(PORTAL).call(otherFinalizeCalldata);
            errFinalize = _sel(r);
        }
        // 2. direct lockbox unlock / lock / liquidity migration
        (okUnlock, r) = Fwd(probeVia).fwd(address(LOCKBOX), abi.encodeCall(ILockbox.unlockETH, (1 ether)));
        errUnlock = _sel(r);
        (okLock, r) = Fwd(probeVia).fwd(address(LOCKBOX), abi.encodeCall(ILockbox.lockETH, ()));
        errLock = _sel(r);
        (okMigrate, r) = address(PORTAL).call(abi.encodeCall(IPortal.migrateLiquidity, ()));
        errMigrate = _sel(r);
        // 3. replay the message that is currently being relayed
        if (replayCalldata.length != 0) {
            (okReplay, errReplay) = CDM.call(replayCalldata);
        }
        // 4. push part of the value back in as a fresh deposit
        if (depositBack != 0) {
            (okDeposit,) = address(PORTAL).call{ value: depositBack }(
                abi.encodeCall(IPortal.depositTransaction, (address(this), depositBack, 100_000, false, ""))
            );
        }
        // 5. push part of the value back as a donation (no deposit)
        if (donateBack != 0) {
            (okDonate,) = address(PORTAL).call{ value: donateBack }(abi.encodeCall(IPortal.donateETH, ()));
        }
        if (revertAtEnd) revert("adversary: revert");
    }
}

/// @dev Stateless forwarder. Etched at the test's `attacker` address so that the adversary's direct
///      lockbox probes come from an address whose `authorizedPortals` slot is already cached by
///      the shared anvil (purely an RPC-availability workaround; any unauthorized caller behaves
///      identically).
contract Fwd {
    function fwd(address to, bytes calldata data) external payable returns (bool ok, bytes memory ret) {
        (ok, ret) = to.call{ value: msg.value }(data);
    }
}

/// @dev Code actually etched over the recipient/target: forwards the call (and value) to the
///      locally deployed `Reenter` brain and bubbles a failure up. Keeps all adversary storage
///      off the forked account.
contract Shim {
    address immutable BRAIN;

    constructor(address _brain) {
        BRAIN = _brain;
    }

    receive() external payable {
        _fwd();
    }

    fallback() external payable {
        _fwd();
    }

    function _fwd() internal {
        (bool ok,) = BRAIN.call{ value: msg.value }("");
        require(ok, "shim: brain reverted");
    }
}

contract Lane03ConservationTest is Test {
    IPortal constant PORTAL = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    ILockbox constant LOCKBOX = ILockbox(0x322b47Ff1FA8D5611F761e3E275C45B71b294D43);
    ICDM constant CDM = ICDM(0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1);
    address constant BRIDGE = 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1;
    ISystemConfig constant SYSCFG = ISystemConfig(0x229047fed2591dbec1eF1118d64F7aF3dB9EB290);
    ISuperchainConfig constant SUPERCFG = ISuperchainConfig(0x95703e0982140D16f8ebA6d158FccEde42f04a4C);
    IASR constant ASR = IASR(0x23B2C62946350F4246f9f9D027e071f0264FD113);
    address constant GUARDIAN = 0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2;
    address constant PAO = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A;
    address constant DEFAULT_L2_SENDER = 0x000000000000000000000000000000000000dEaD;
    address constant L2CDM = 0x4200000000000000000000000000000000000007;

    bytes32 constant T_ETH_LOCKED = keccak256("ETHLocked(address,uint256)");
    bytes32 constant T_ETH_UNLOCKED = keccak256("ETHUnlocked(address,uint256)");
    bytes32 constant T_DEPOSITED = keccak256("TransactionDeposited(address,address,uint256,bytes)");
    bytes32 constant T_FINALIZED = keccak256("WithdrawalFinalized(bytes32,bool)");

    address attacker = makeAddr("lane03-attacker");

    struct Bal {
        uint256 lockbox;
        uint256 portal;
        uint256 cdm;
        uint256 bridge;
    }

    function setUp() public {
        // Default: shared anvil `l1`. LANE03_RPC=l1lane03 selects the lane's private anvil on
        // port 18030 (same pinned block), used when the shared anvil's upstream is rate-limited.
        vm.createSelectFork(vm.envOr("LANE03_RPC", string("l1")));
        assertEq(block.number, 26433900);
        assertEq(PORTAL.version(), "6.1.0");
        assertEq(LOCKBOX.version(), "2.0.0");
        assertEq(PORTAL.ethLockbox(), address(LOCKBOX));
        assertEq(address(PORTAL).balance, 0, "portal holds no ETH post-U21");
        assertEq(address(CDM).balance, 0, "no failed-message ETH parked in L1CDM");
        assertTrue(LOCKBOX.authorizedPortals(address(PORTAL)));
        vm.deal(attacker, 1000 ether);
    }

    function _bal() internal view returns (Bal memory b) {
        b = Bal(address(LOCKBOX).balance, address(PORTAL).balance, address(CDM).balance, BRIDGE.balance);
    }

    function _sel(string memory sig) internal pure returns (bytes4) {
        return bytes4(keccak256(bytes(sig)));
    }

    function _finalize(Fixture memory f) internal {
        vm.prank(attacker, attacker);
        PORTAL.finalizeWithdrawalTransactionExternalProof{ gas: 8_000_000 }(f.wd, f.submitter);
    }

    function _etchAdversary(address where) internal returns (Reenter r) {
        // SUBSTITUTION: adversarial code is placed over `where` with vm.etch. The etched code is
        // a Shim that forwards the call and value to the returned Reenter "brain".
        r = new Reenter();
        // forge's deterministic CREATE addresses hold dust on mainnet; zero it so that balance
        // assertions on the adversary are exact.
        vm.deal(address(r), 0);
        vm.etch(where, address(new Shim(address(r))).code);
        vm.etch(attacker, address(new Fwd()).code);
        r.setProbeVia(attacker);
    }

    function _bridgeRecipient(Fixture memory f) internal pure returns (address to) {
        // wd.data = relayMessage(nonce, sender, target, value, minGas, message); message =
        // finalizeBridgeETH(from, to, amount, extraData). `to` sits at a fixed offset.
        bytes memory d = f.wd.data;
        // 4 (sel) + 6*32 head + 32 (len) + 4 (inner sel) + 32 (from) => to
        uint256 off = 4 + 6 * 32 + 32 + 4 + 32;
        assembly {
            to := mload(add(add(d, 32), off))
        }
    }

    // ---------------------------------------------------------------------------------------
    // A. Deposits: where value enters and where liability is created
    // ---------------------------------------------------------------------------------------

    function test_A_deposit_valueGoesToLockbox_mintEqualsLocked() public {
        Bal memory b0 = _bal();
        vm.recordLogs();
        vm.prank(attacker, attacker);
        PORTAL.depositTransaction{ value: 3 ether }(attacker, 1 ether, 100_000, false, "");
        Vm.Log[] memory logs = vm.getRecordedLogs();
        uint256 locked;
        uint256 mint;
        for (uint256 i; i < logs.length; i++) {
            if (logs[i].topics[0] == T_ETH_LOCKED) locked += abi.decode(logs[i].data, (uint256));
            if (logs[i].topics[0] == T_DEPOSITED) {
                bytes memory od = abi.decode(logs[i].data, (bytes));
                uint256 m;
                assembly {
                    m := mload(add(od, 32))
                }
                mint += m;
            }
        }
        Bal memory b1 = _bal();
        assertEq(locked, 3 ether, "ETHLocked == msg.value");
        assertEq(mint, 3 ether, "L2 mint (liability) == msg.value, NOT _value");
        assertEq(b1.lockbox - b0.lockbox, 3 ether);
        assertEq(b1.portal, 0);
    }

    function test_A_receive_isDeposit_zeroValueDoesNotTouchLockbox_donateStaysInPortal() public {
        Bal memory b0 = _bal();
        vm.prank(attacker, attacker);
        (bool ok,) = address(PORTAL).call{ value: 2 ether }("");
        assertTrue(ok);
        assertEq(address(LOCKBOX).balance - b0.lockbox, 2 ether, "receive() locks");

        vm.recordLogs();
        vm.prank(attacker, attacker);
        PORTAL.depositTransaction(attacker, 0, 100_000, false, "");
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i; i < logs.length; i++) {
            assertTrue(logs[i].topics[0] != T_ETH_LOCKED, "zero-value deposit must not call lockETH");
        }

        vm.prank(attacker, attacker);
        PORTAL.donateETH{ value: 5 ether }();
        assertEq(address(PORTAL).balance, 5 ether, "donation is custody in the portal, not the lockbox");
        assertEq(address(LOCKBOX).balance - b0.lockbox, 2 ether, "donation never reaches the lockbox");
    }

    function test_A_deposit_valueExceedingMsgValue_isOnlyAnL2Concern() public {
        // _value > msg.value: L1 locks msg.value only; the L2 tx will fail/succeed on the
        // aliased sender's L2 balance. No L1 value is created.
        Bal memory b0 = _bal();
        vm.prank(attacker, attacker);
        PORTAL.depositTransaction{ value: 1 wei }(attacker, 1_000_000 ether, 100_000, false, "");
        assertEq(address(LOCKBOX).balance - b0.lockbox, 1 wei);
    }

    // ---------------------------------------------------------------------------------------
    // B. Negative tests: every caller restriction on a value-moving edge
    // ---------------------------------------------------------------------------------------

    function test_B_lockbox_callerRestrictions() public {
        vm.startPrank(attacker, attacker);

        vm.expectRevert(_sel("ETHLockbox_Unauthorized()"));
        LOCKBOX.lockETH{ value: 1 ether }();

        vm.expectRevert(_sel("ETHLockbox_Unauthorized()"));
        LOCKBOX.unlockETH(1 ether);

        vm.expectRevert(_sel("ETHLockbox_Unauthorized()"));
        LOCKBOX.receiveLiquidity{ value: 1 ether }();

        vm.expectRevert(_sel("ProxyAdminOwnedBase_NotProxyAdminOwner()"));
        LOCKBOX.migrateLiquidity(attacker);

        vm.expectRevert(_sel("ProxyAdminOwnedBase_NotProxyAdminOwner()"));
        LOCKBOX.authorizePortal(attacker);

        vm.expectRevert(_sel("ProxyAdminOwnedBase_NotProxyAdminOwner()"));
        LOCKBOX.authorizeLockbox(attacker);

        address[] memory p = new address[](1);
        p[0] = attacker;
        vm.expectRevert(bytes("Initializable: contract is already initialized"));
        LOCKBOX.initialize(attacker, p);

        // No receive()/fallback: plain ETH cannot be pushed in (only forced ETH can).
        (bool ok,) = address(LOCKBOX).call{ value: 1 ether }("");
        assertFalse(ok, "lockbox has no receive()");
        vm.stopPrank();
    }

    function test_B_portal_callerRestrictions() public {
        vm.startPrank(attacker, attacker);

        vm.expectRevert(_sel("ProxyAdminOwnedBase_NotProxyAdminOwner()"));
        PORTAL.migrateLiquidity();

        vm.expectRevert(_sel("OptimismPortal_NotUsingInterop()"));
        PORTAL.migrateToSharedDisputeGame(attacker, attacker);

        vm.expectRevert(bytes("Initializable: contract is already initialized"));
        PORTAL.initialize(attacker, attacker, attacker);

        vm.expectRevert();
        SYSCFG.setFeature(bytes32("CUSTOM_GAS_TOKEN"), true);
        vm.stopPrank();

        // Even the ProxyAdmin owner cannot turn the lockbox feature off in v9.
        // SUBSTITUTION: vm.prank(PAO) only to show the guard, no state is changed.
        vm.prank(PAO);
        vm.expectRevert(_sel("SystemConfig_InvalidFeatureState()"));
        SYSCFG.setFeature(bytes32("ETH_LOCKBOX"), false);
    }

    function test_B_finalize_guards() public {
        Fixture memory f = Fixtures.wBridgeA();

        // wrong proof submitter -> Unproven
        vm.prank(attacker, attacker);
        vm.expectRevert(_sel("OptimismPortal_Unproven()"));
        PORTAL.finalizeWithdrawalTransaction(f.wd);

        // tampered value -> different hash -> Unproven (value is committed to by the hash)
        WithdrawalTransaction memory t = f.wd;
        t.value = 1000 ether;
        vm.prank(attacker, attacker);
        vm.expectRevert(_sel("OptimismPortal_Unproven()"));
        PORTAL.finalizeWithdrawalTransactionExternalProof(t, f.submitter);

        // unsafe targets
        t = f.wd;
        t.target = address(PORTAL);
        vm.prank(attacker, attacker);
        vm.expectRevert(_sel("OptimismPortal_BadTarget()"));
        PORTAL.finalizeWithdrawalTransactionExternalProof(t, f.submitter);
        t.target = address(LOCKBOX);
        vm.prank(attacker, attacker);
        vm.expectRevert(_sel("OptimismPortal_BadTarget()"));
        PORTAL.finalizeWithdrawalTransactionExternalProof(t, f.submitter);

        // not enough gas for the sub-call -> whole tx reverts, nothing is finalized or unlocked
        f = Fixtures.wBridgeA(); // fresh copy (t aliases f.wd in memory)
        Bal memory b0 = _bal();
        vm.prank(attacker, attacker);
        (bool ok, bytes memory ret) = address(PORTAL).call{ gas: 400_000 }(
            abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (f.wd, f.submitter))
        );
        assertFalse(ok);
        assertEq(bytes4(ret), bytes4(0x08c379a0)); // Error(string) "SafeCall: Not enough gas"
        assertFalse(PORTAL.finalizedWithdrawals(f.hash));
        assertEq(address(LOCKBOX).balance, b0.lockbox);

        // real finalize, then replay -> AlreadyFinalized
        _finalize(f);
        assertTrue(PORTAL.finalizedWithdrawals(f.hash));
        vm.prank(attacker, attacker);
        vm.expectRevert(_sel("OptimismPortal_AlreadyFinalized()"));
        PORTAL.finalizeWithdrawalTransactionExternalProof(f.wd, f.submitter);
    }

    function test_B_unlockGuard_l2Sender_mockedPortalCaller() public {
        // SUBSTITUTION (mock, guard location only): msg.sender is forced to the portal and
        // portal.l2Sender is forced with vm.store. No production path lets the portal call
        // unlockETH on its *current* lockbox from inside a withdrawal (BadTarget blocks it).
        // slot 50 = l2Sender (see snapshots/storageLayout/OptimismPortal2.json).
        assertEq(address(uint160(uint256(vm.load(address(PORTAL), bytes32(uint256(50)))))), DEFAULT_L2_SENDER);
        vm.store(address(PORTAL), bytes32(uint256(50)), bytes32(uint256(uint160(attacker))));
        assertEq(PORTAL.l2Sender(), attacker);
        vm.prank(address(PORTAL));
        vm.expectRevert(_sel("ETHLockbox_NoWithdrawalTransactions()"));
        LOCKBOX.unlockETH(1 ether);

        // over-balance request
        vm.store(address(PORTAL), bytes32(uint256(50)), bytes32(uint256(uint160(DEFAULT_L2_SENDER))));
        uint256 bal = address(LOCKBOX).balance;
        vm.prank(address(PORTAL));
        vm.expectRevert(_sel("ETHLockbox_InsufficientBalance()"));
        LOCKBOX.unlockETH(bal + 1);
    }

    // ---------------------------------------------------------------------------------------
    // C. Real finalizations through the messenger (value: lockbox -> portal -> L1CDM -> target)
    // ---------------------------------------------------------------------------------------

    function test_C_finalize_real638ETH_exactOnce() public {
        Fixture memory f = Fixtures.w638();
        PORTAL.checkWithdrawal(f.hash, f.submitter); // ready at the fork block, no warp
        Bal memory b0 = _bal();
        address l1Target = 0x23CA5E5300d3b35a47DFeF6A36Ecba5AC0a96E03; // relayMessage `_target`
        uint256 t0 = l1Target.balance;

        vm.recordLogs();
        _finalize(f);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        uint256 unlocked;
        uint256 locked;
        for (uint256 i; i < logs.length; i++) {
            if (logs[i].emitter != address(LOCKBOX)) continue;
            if (logs[i].topics[0] == T_ETH_UNLOCKED) unlocked += abi.decode(logs[i].data, (uint256));
            if (logs[i].topics[0] == T_ETH_LOCKED) locked += abi.decode(logs[i].data, (uint256));
        }
        Bal memory b1 = _bal();
        emit log_named_uint("unlocked", unlocked);
        emit log_named_uint("re-locked in same tx", locked);
        emit log_named_uint("lockbox delta (wei, negative)", b0.lockbox - b1.lockbox);
        emit log_named_uint("L1 target balance delta", l1Target.balance - t0);
        emit log_named_uint("L1CDM balance after", b1.cdm);

        assertEq(unlocked, f.wd.value, "exactly _tx.value unlocked, once");
        assertEq(b1.portal, 0, "nothing left in the portal");
        assertEq(b1.bridge, b0.bridge, "bridge untouched");
        assertTrue(PORTAL.finalizedWithdrawals(f.hash));
        assertEq(PORTAL.l2Sender(), DEFAULT_L2_SENDER);
        bytes32 msgHash = keccak256(f.wd.data);
        // Either relayed (value left the system) or recorded as failed (value parked in L1CDM).
        assertTrue(CDM.successfulMessages(msgHash) != CDM.failedMessages(msgHash), "relayed XOR failed");
        if (CDM.successfulMessages(msgHash)) {
            assertEq(b1.cdm, 0);
            // value conservation across the whole tx: every wei that left the lockbox is either
            // re-locked (the target re-deposited) or left the system.
            assertEq(b0.lockbox - b1.lockbox, unlocked - locked);
        } else {
            assertEq(b1.cdm, f.wd.value, "failed message value is custody of L1CDM");
        }

        // second finalize / other submitter cannot unlock again
        vm.prank(attacker, attacker);
        vm.expectRevert(_sel("OptimismPortal_AlreadyFinalized()"));
        PORTAL.finalizeWithdrawalTransactionExternalProof(f.wd, f.submitter);
    }

    function test_C_bridgeWithdrawal_adversarialRecipient_reentrancyMatrix() public {
        Fixture memory f = Fixtures.wBridgeB(); // 0.0466792496235 ETH to an EOA via L1StandardBridge
        Fixture memory other = Fixtures.wBridgeC(); // another ready withdrawal to try to nest
        address recipient = _bridgeRecipient(f);
        // NOTE: the real recipient is an EIP-7702 delegated EOA (23-byte 0xef0100… designator).
        assertEq(recipient.code.length, 23, "real recipient: 7702-delegated EOA");
        Reenter adv = _etchAdversary(recipient);
        uint256 v = f.wd.value;
        adv.arm({
            _otherFinalize: abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (other.wd, other.submitter)),
            _replay: f.wd.data,
            _depositBack: v / 4,
            _donateBack: v / 4,
            _revertAtEnd: false,
            _burnGas: false
        });
        uint256 r0 = recipient.balance;
        Bal memory b0 = _bal();
        _finalize(f);
        Bal memory b1 = _bal();

        assertEq(adv.calls(), 1);
        assertEq(adv.received(), v);
        assertEq(adv.seenL2Sender(), L2CDM, "l2Sender is set for the whole call tree");
        // nested finalize of another withdrawal
        assertFalse(adv.okFinalize());
        assertEq(adv.errFinalize(), _sel("OptimismPortal_NoReentrancy()"));
        // direct lockbox access
        assertFalse(adv.okUnlock());
        assertEq(adv.errUnlock(), _sel("ETHLockbox_Unauthorized()"));
        assertFalse(adv.okLock());
        assertEq(adv.errLock(), _sel("ETHLockbox_Unauthorized()"));
        assertFalse(adv.okMigrate());
        // replay of the in-flight message: not marked failed -> rejected
        assertFalse(adv.okReplay());
        // re-deposit and donation are allowed mid-withdrawal
        assertTrue(adv.okDeposit());
        assertTrue(adv.okDonate());

        // State deltas: unlocked v, re-locked v/4 by the nested deposit, v/4 stranded in portal.
        assertEq(b0.lockbox - b1.lockbox, v - v / 4, "lockbox: -v + v/4");
        assertEq(b1.portal, v / 4, "donation is stranded in the portal");
        assertEq(recipient.balance, r0, "shim forwarded everything to the brain");
        assertEq(address(adv).balance, v - v / 4 - v / 4, "adversary keeps the rest");
        assertFalse(PORTAL.finalizedWithdrawals(other.hash), "other withdrawal untouched");
        assertTrue(CDM.successfulMessages(keccak256(f.wd.data)));

        // The stranded donation cannot be spent by any later withdrawal: finalize `other` and
        // check the portal balance is untouched.
        _finalize(other);
        assertEq(address(PORTAL).balance, v / 4, "later withdrawals never spend portal-held ETH");
    }

    function test_C_bridgeWithdrawal_recipientReverts_valueParkedInCDM_replayOnce() public {
        Fixture memory f = Fixtures.wBridgeC();
        address recipient = _bridgeRecipient(f);
        Reenter adv = _etchAdversary(recipient);
        adv.arm("", "", 0, 0, true, false); // revert on receive
        uint256 v = f.wd.value;
        uint256 r0 = recipient.balance;
        Bal memory b0 = _bal();
        _finalize(f);
        Bal memory b1 = _bal();
        bytes32 msgHash = keccak256(f.wd.data);

        assertTrue(PORTAL.finalizedWithdrawals(f.hash), "portal: finalized (messenger returned)");
        assertTrue(CDM.failedMessages(msgHash));
        assertFalse(CDM.successfulMessages(msgHash));
        assertEq(b0.lockbox - b1.lockbox, v, "value left the lockbox exactly once");
        assertEq(b1.cdm - b0.cdm, v, "value is now custody of L1CDM");
        assertEq(b1.portal, 0);

        // SUBSTITUTION: restore the recipient to an EOA and replay permissionlessly.
        vm.etch(recipient, "");
        vm.prank(attacker, attacker);
        (bool ok,) = address(CDM).call{ gas: 3_000_000 }(f.wd.data);
        assertTrue(ok);
        assertTrue(CDM.successfulMessages(msgHash));
        assertEq(address(CDM).balance, b0.cdm, "L1CDM pays out exactly the parked value");
        assertEq(recipient.balance - r0, v);

        // second replay rejected
        vm.prank(attacker, attacker);
        (ok,) = address(CDM).call{ gas: 3_000_000 }(f.wd.data);
        assertFalse(ok);
        assertEq(address(LOCKBOX).balance, b1.lockbox, "replays never touch the lockbox");
    }

    function test_C_L1CDMCallFailed_keepsWithdrawalReplayable_mockedRevert() public {
        // SUBSTITUTION (mock): the messenger is forced to revert. In production this happens on
        // OOG inside relayMessage, a blocked relay target, or an already-relayed legacy message.
        Fixture memory f = Fixtures.wBridgeD();
        Bal memory b0 = _bal();
        vm.mockCallRevert(address(CDM), f.wd.value, f.wd.data, "forced");
        vm.prank(attacker, attacker);
        vm.expectRevert(_sel("OptimismPortal_L1CDMCallFailed()"));
        PORTAL.finalizeWithdrawalTransactionExternalProof{ gas: 8_000_000 }(f.wd, f.submitter);
        Bal memory b1 = _bal();
        assertFalse(PORTAL.finalizedWithdrawals(f.hash), "v9: stays unfinalized");
        assertEq(b1.lockbox, b0.lockbox, "unlock rolled back");
        assertEq(b1.portal, 0);
        assertEq(PORTAL.l2Sender(), DEFAULT_L2_SENDER);

        vm.clearMockedCalls();
        _finalize(f);
        assertTrue(PORTAL.finalizedWithdrawals(f.hash));
        assertEq(b0.lockbox - address(LOCKBOX).balance, f.wd.value);
    }

    // ---------------------------------------------------------------------------------------
    // D. Direct (non-messenger) withdrawal: real SequencerFeeVault withdrawal of 53.47 ETH
    // ---------------------------------------------------------------------------------------

    /// @dev Advances time so the REAL proof matures. The withdrawal was proven at 1794824939
    ///      against game 0x4527…700f, which is IN_PROGRESS and unchallenged at the fork block.
    ///      Time passes, then the permissionless resolveClaim/resolve are called.
    function _matureFeeVault(Fixture memory f) internal {
        IGame g = IGame(f.game);
        assertEq(g.status(), 0, "IN_PROGRESS at fork");
        vm.warp(uint256(g.createdAt()) + 302_400 + 1);
        g.resolveClaim(0, 0);
        g.resolve();
        assertEq(g.status(), 2, "DEFENDER_WINS");
        vm.warp(uint256(f.provenAt) + 604_800 + 1);
        assertTrue(ASR.isGameClaimValid(f.game));
        PORTAL.checkWithdrawal(f.hash, f.submitter);
    }

    function test_D_direct_feeVault_realTarget_success() public {
        Fixture memory f = Fixtures.wFeeVault();
        _matureFeeVault(f);
        uint256 t0 = f.wd.target.balance;
        Bal memory b0 = _bal();
        _finalize(f);
        Bal memory b1 = _bal();
        assertTrue(PORTAL.finalizedWithdrawals(f.hash));
        assertEq(b0.lockbox - b1.lockbox, f.wd.value);
        assertEq(f.wd.target.balance - t0, f.wd.value, "real target received the value");
        assertEq(b1.portal, 0);
    }

    function test_D_direct_targetReverts_valueRelocked_liabilityGone() public {
        Fixture memory f = Fixtures.wFeeVault();
        _matureFeeVault(f);
        Reenter adv = _etchAdversary(f.wd.target);
        adv.arm("", "", 0, 0, true, false);
        Bal memory b0 = _bal();
        vm.recordLogs();
        _finalize(f);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        uint256 unlocked;
        uint256 locked;
        bool sawFailed;
        for (uint256 i; i < logs.length; i++) {
            if (logs[i].topics[0] == T_ETH_UNLOCKED) unlocked += abi.decode(logs[i].data, (uint256));
            if (logs[i].topics[0] == T_ETH_LOCKED) locked += abi.decode(logs[i].data, (uint256));
            if (logs[i].topics[0] == T_FINALIZED) sawFailed = !abi.decode(logs[i].data, (bool));
        }
        Bal memory b1 = _bal();
        assertTrue(sawFailed, "WithdrawalFinalized(success=false)");
        assertEq(unlocked, f.wd.value);
        assertEq(locked, f.wd.value, "exact relock");
        assertEq(b1.lockbox, b0.lockbox, "net zero");
        assertEq(b1.portal, 0);
        assertTrue(PORTAL.finalizedWithdrawals(f.hash), "finalized: L2 burn is now unbacked surplus in the lockbox");
    }

    function test_D_direct_targetBurnsAllGas_relockStillFits() public {
        Fixture memory f = Fixtures.wFeeVault();
        _matureFeeVault(f);
        Reenter adv = _etchAdversary(f.wd.target);
        adv.arm("", "", 0, 0, false, true);
        Bal memory b0 = _bal();
        // Minimum gas that passes SafeCall.hasMinGas for gasLimit=400k is ~ 400k*64/63 + 40k
        // plus the pre-call work. Sweep a few tx gas limits: the tx must either revert entirely
        // (nothing changes) or finalize with an exact relock. Never "unlocked but not relocked".
        uint256[6] memory gasLimits =
            [uint256(480_000), 520_000, 560_000, 600_000, 800_000, 3_000_000];
        for (uint256 i; i < gasLimits.length; i++) {
            uint256 snap = vm.snapshotState();
            vm.prank(attacker, attacker);
            (bool ok,) = address(PORTAL).call{ gas: gasLimits[i] }(
                abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (f.wd, f.submitter))
            );
            Bal memory b1 = _bal();
            emit log_named_uint(ok ? "finalized(failed) with tx gas" : "reverted with tx gas", gasLimits[i]);
            assertEq(b1.lockbox, b0.lockbox, "lockbox whole in both outcomes");
            assertEq(b1.portal, 0, "no ETH stranded in the portal");
            assertEq(PORTAL.finalizedWithdrawals(f.hash), ok);
            vm.revertToState(snap);
        }
    }

    function test_D_direct_reentrantTarget_matrix_and_strandedDonation() public {
        Fixture memory f = Fixtures.wFeeVault();
        Fixture memory other = Fixtures.w638();
        _matureFeeVault(f);
        Reenter adv = _etchAdversary(f.wd.target);
        uint256 v = f.wd.value;
        uint256 t0 = f.wd.target.balance;
        adv.arm({
            _otherFinalize: abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (other.wd, other.submitter)),
            _replay: "",
            _depositBack: 10 ether,
            _donateBack: 20 ether,
            _revertAtEnd: false,
            _burnGas: false
        });
        Bal memory b0 = _bal();
        _finalize(f);
        Bal memory b1 = _bal();

        assertEq(adv.seenL2Sender(), f.wd.sender);
        assertFalse(adv.okFinalize());
        assertEq(adv.errFinalize(), _sel("OptimismPortal_NoReentrancy()"));
        assertFalse(adv.okUnlock());
        assertEq(adv.errUnlock(), _sel("ETHLockbox_Unauthorized()"));
        assertFalse(adv.okLock());
        assertFalse(adv.okMigrate());
        assertTrue(adv.okDeposit());
        assertTrue(adv.okDonate());

        assertEq(b0.lockbox - b1.lockbox, v - 10 ether, "unlock v, nested deposit relocks 10");
        assertEq(b1.portal, 20 ether, "donation stranded in portal");
        assertEq(f.wd.target.balance, t0);
        assertEq(address(adv).balance, v - 30 ether);

        // Nobody but the ProxyAdmin owner can move the stranded 20 ETH.
        vm.prank(attacker, attacker);
        vm.expectRevert(_sel("ProxyAdminOwnedBase_NotProxyAdminOwner()"));
        PORTAL.migrateLiquidity();
        _finalize(other);
        assertEq(address(PORTAL).balance, 20 ether, "a later 638 ETH withdrawal does not spend it");

        // SUBSTITUTION: vm.prank(PAO) to show the documented admin recovery path.
        uint256 lb = address(LOCKBOX).balance;
        vm.prank(PAO);
        PORTAL.migrateLiquidity();
        assertEq(address(PORTAL).balance, 0);
        assertEq(address(LOCKBOX).balance - lb, 20 ether);
    }

    function test_D_direct_estimationOrigin_revertsBeforeRelock() public {
        Fixture memory f = Fixtures.wFeeVault();
        _matureFeeVault(f);
        Reenter adv = _etchAdversary(f.wd.target);
        adv.arm("", "", 0, 0, true, false);
        Bal memory b0 = _bal();
        vm.prank(attacker, address(1)); // tx.origin = ESTIMATION_ADDRESS (eth_call only)
        vm.expectRevert(_sel("OptimismPortal_GasEstimation()"));
        PORTAL.finalizeWithdrawalTransactionExternalProof{ gas: 8_000_000 }(f.wd, f.submitter);
        assertEq(address(LOCKBOX).balance, b0.lockbox);
        assertFalse(PORTAL.finalizedWithdrawals(f.hash));
    }

    // ---------------------------------------------------------------------------------------
    // E. Pause-state asymmetry
    // ---------------------------------------------------------------------------------------

    function test_E_pause_identifierIsLockbox_depositsStillLock_withdrawalsBlocked() public {
        Fixture memory f = Fixtures.wBridgeA();
        assertEq(SUPERCFG.guardian(), GUARDIAN);

        // SUBSTITUTION: vm.prank(guardian) — a state production can be in (guardian pause).
        // 1. Pausing the *portal* identifier (the pre-lockbox convention) pauses nothing.
        uint256 snap = vm.snapshotState();
        vm.prank(GUARDIAN);
        SUPERCFG.pause(address(PORTAL));
        assertTrue(SUPERCFG.paused(address(PORTAL)));
        assertFalse(PORTAL.paused(), "portal identifier is not the chain's pause key");
        assertFalse(SYSCFG.paused());
        assertFalse(CDM.paused());
        assertFalse(ASR.paused());
        _finalize(f); // withdrawals still flow
        assertTrue(PORTAL.finalizedWithdrawals(f.hash));
        vm.revertToState(snap);

        // 2. Pausing the lockbox identifier pauses the chain.
        vm.prank(GUARDIAN);
        SUPERCFG.pause(address(LOCKBOX));
        assertTrue(PORTAL.paused());
        assertTrue(SYSCFG.paused());
        assertTrue(CDM.paused());
        assertTrue(ASR.paused());
        assertTrue(LOCKBOX.paused());

        vm.prank(attacker, attacker);
        vm.expectRevert(_sel("OptimismPortal_CallPaused()"));
        PORTAL.finalizeWithdrawalTransactionExternalProof(f.wd, f.submitter);

        // deposits (lock) still work while paused: value in, nothing out.
        uint256 lb = address(LOCKBOX).balance;
        vm.prank(attacker, attacker);
        PORTAL.depositTransaction{ value: 1 ether }(attacker, 1 ether, 100_000, false, "");
        assertEq(address(LOCKBOX).balance - lb, 1 ether);

        // unlock is blocked at the lockbox too (independent check).
        vm.prank(address(PORTAL)); // SUBSTITUTION (mock caller) to reach the lockbox check directly
        vm.expectRevert(_sel("ETHLockbox_Paused()"));
        LOCKBOX.unlockETH(1);
    }

    // ---------------------------------------------------------------------------------------
    // F. Sequence fuzz: Σ locks − Σ unlocks == Δ lockbox, portal never accumulates, no double pay
    // ---------------------------------------------------------------------------------------

    function testFuzz_F_sequenceConservation(uint256 seed) public {
        Fixture[5] memory fx =
            [Fixtures.wBridgeA(), Fixtures.wBridgeB(), Fixtures.wBridgeC(), Fixtures.wBridgeD(), Fixtures.w638()];
        bool[5] memory done;
        uint256 lb0 = address(LOCKBOX).balance;
        int256 expected; // expected lockbox delta
        uint256 donated;
        for (uint256 step; step < 12; step++) {
            seed = uint256(keccak256(abi.encode(seed, step)));
            uint256 op = seed % 5;
            uint256 amt = (seed >> 8) % 3 ether;
            if (op == 0) {
                vm.prank(attacker, attacker);
                PORTAL.depositTransaction{ value: amt }(attacker, amt, 100_000, false, "");
                expected += int256(amt);
            } else if (op == 1) {
                vm.prank(attacker, attacker);
                PORTAL.donateETH{ value: amt }();
                donated += amt;
            } else {
                uint256 i = (seed >> 40) % 5;
                vm.prank(attacker, attacker);
                (bool ok,) = address(PORTAL).call{ gas: 8_000_000 }(
                    abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (fx[i].wd, fx[i].submitter))
                );
                assertEq(ok, !done[i], "finalizes exactly once");
                if (ok) {
                    done[i] = true;
                    expected -= int256(fx[i].wd.value);
                }
            }
            assertEq(int256(address(LOCKBOX).balance) - int256(lb0), expected, "lockbox reconciles");
            assertEq(address(PORTAL).balance, donated, "portal holds donations only");
            assertEq(PORTAL.l2Sender(), DEFAULT_L2_SENDER);
        }
    }

    // ---------------------------------------------------------------------------------------
    // G. Upgrade-boundary object: message sent on L2 BEFORE U21 (gasLimit computed with the old
    //    relay constants), relayed by the v9 L1CDM (RESERVED 135k / BUFFER 15k) at the minimum
    //    tx gas the portal accepts. Outcome must be: relayed, or failed-and-replayable with the
    //    value parked in L1CDM. Never "finalized with value nowhere".
    // ---------------------------------------------------------------------------------------

    function _minGasOutcome(Fixture memory f) internal returns (uint256 minGas, bool relayed, bool failed) {
        uint256 lo = 100_000;
        uint256 hi = 3_000_000;
        bytes memory cd = abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (f.wd, f.submitter));
        while (hi - lo > 500) {
            uint256 mid = (lo + hi) / 2;
            uint256 snap = vm.snapshotState();
            vm.prank(attacker, attacker);
            (bool ok,) = address(PORTAL).call{ gas: mid }(cd);
            vm.revertToState(snap);
            if (ok) hi = mid;
            else lo = mid;
        }
        minGas = hi;
        Bal memory b0 = _bal();
        vm.prank(attacker, attacker);
        (bool ok2,) = address(PORTAL).call{ gas: minGas }(cd);
        assertTrue(ok2);
        Bal memory b1 = _bal();
        bytes32 h = keccak256(f.wd.data);
        relayed = CDM.successfulMessages(h);
        failed = CDM.failedMessages(h);
        assertTrue(relayed != failed, "exactly one of relayed/failed");
        assertEq(b0.lockbox - b1.lockbox, f.wd.value, "unlock == value");
        assertEq(b1.portal, 0);
        assertEq(b1.cdm - b0.cdm, failed ? f.wd.value : 0, "failed => value parked in L1CDM");
    }

    function test_G_inflightPreU21Message_minimumGas_bridgeETH() public {
        Fixture memory f = Fixtures.wBridgeA(); // minGasLimit 350_000, _tx.gasLimit 668_851 (old baseGas)
        (uint256 g, bool relayed, bool failed) = _minGasOutcome(f);
        emit log_named_uint("min tx gas accepted by portal", g);
        emit log_named_string("outcome at min gas", relayed ? "relayed" : "failed (replayable)");
        assertTrue(relayed, "old-constant baseGas still relays under v9 L1CDM at min gas");
        failed;
    }

    function test_G_inflightPreU21Message_minimumGas_638ETH_minGasLimitZero() public {
        Fixture memory f = Fixtures.w638(); // minGasLimit 0, _tx.gasLimit 313_808
        (uint256 g, bool relayed, bool failed) = _minGasOutcome(f);
        emit log_named_uint("min tx gas accepted by portal", g);
        emit log_named_string("outcome at min gas", relayed ? "relayed" : "failed (replayable)");
        if (failed) {
            // permissionless replay with ample gas pays out exactly once
            uint256 c0 = address(CDM).balance;
            vm.prank(attacker, attacker);
            (bool ok,) = address(CDM).call{ gas: 5_000_000 }(f.wd.data);
            assertTrue(ok);
            assertTrue(CDM.successfulMessages(keccak256(f.wd.data)));
            assertEq(c0 - address(CDM).balance, f.wd.value);
        }
    }

    // ---------------------------------------------------------------------------------------
    // H. Third-party custody shift: finalize a victim's L2CDM withdrawal from INSIDE an L1CDM
    //    replay. portal.l2Sender is DEFAULT in a replay context (so the portal guard does not
    //    trip) while L1CDM.xDomainMsgSender is set, so the victim's message is recorded as
    //    failed: the value leaves the lockbox and is parked in L1CDM until someone replays it.
    // ---------------------------------------------------------------------------------------

    function test_H_nestedFinalizeInsideReplay_parksVictimValueInCDM_thenReplayPaysOnce() public {
        Fixture memory mine = Fixtures.wBridgeC(); // attacker-controlled carrier message
        Fixture memory victim = Fixtures.w638(); // 638.18 ETH, REAL third-party withdrawal
        address recipient = _bridgeRecipient(mine);

        // step 1: make the carrier message fail once so that it becomes replayable.
        Reenter adv = _etchAdversary(recipient);
        adv.arm("", "", 0, 0, true, false);
        _finalize(mine);
        assertTrue(CDM.failedMessages(keccak256(mine.wd.data)));

        // step 2: replay the carrier; inside it, finalize the victim's withdrawal.
        adv.arm(
            abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (victim.wd, victim.submitter)),
            "",
            0,
            0,
            false,
            false
        );
        Bal memory b0 = _bal();
        address victimTarget = 0x23CA5E5300d3b35a47DFeF6A36Ecba5AC0a96E03;
        uint256 vt0 = victimTarget.balance;
        vm.prank(attacker, attacker);
        (bool ok,) = address(CDM).call{ gas: 8_000_000 }(mine.wd.data);
        assertTrue(ok);
        Bal memory b1 = _bal();
        bytes32 vh = keccak256(victim.wd.data);

        assertEq(adv.seenL2Sender(), DEFAULT_L2_SENDER, "replay context: portal guard is open");
        assertTrue(adv.okFinalize(), "nested finalize of the victim withdrawal succeeded");
        assertTrue(PORTAL.finalizedWithdrawals(victim.hash));
        assertTrue(CDM.failedMessages(vh), "victim message recorded as failed");
        assertFalse(CDM.successfulMessages(vh));
        assertEq(b0.lockbox - b1.lockbox, victim.wd.value, "638 ETH left the lockbox");
        // carrier value (parked in step 1) left L1CDM in this tx, victim value entered it
        assertEq(b1.cdm + mine.wd.value - b0.cdm, victim.wd.value, "638 ETH now custody of L1CDM");
        assertEq(victimTarget.balance, vt0, "victim target not paid yet");

        // step 3: anyone replays the victim message; it pays exactly once.
        uint256 c0 = address(CDM).balance;
        vm.prank(attacker, attacker);
        (ok,) = address(CDM).call{ gas: 8_000_000 }(victim.wd.data);
        assertTrue(ok);
        assertTrue(CDM.successfulMessages(vh));
        assertEq(c0 - address(CDM).balance, victim.wd.value);
        vm.prank(attacker, attacker);
        (ok,) = address(CDM).call{ gas: 8_000_000 }(victim.wd.data);
        assertFalse(ok, "no second payout");
        assertEq(address(LOCKBOX).balance, b1.lockbox);
    }
}
