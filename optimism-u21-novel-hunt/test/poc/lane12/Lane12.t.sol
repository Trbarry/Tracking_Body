// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

// LANE 12 — negative-space / omitted-check fork tests against the deployed U21 (op-contracts/v9.0.0)
// implementations on the `l1` fork (Ethereum mainnet @ 26433900). No transaction is ever broadcast.
//
// Setup note (applies to every test that finalizes a withdrawal): a real proven withdrawal needs an
// L2 state proof. Instead we write ONE storage slot, `provenWithdrawals[hash][submitter]`, pointing
// at a real, finalized, respected, DEFENDER_WINS game (the chain's current anchor game). This is the
// exact state `proveWithdrawalTransaction` would have written for a genuine withdrawal, so every
// check that runs afterwards (checkWithdrawal, lockbox, messenger) is the real deployed code.
// It is used to OBSERVE the behaviour of sibling paths, never to claim mainnet exploitability.

struct WithdrawalTransaction {
    uint256 nonce;
    address sender;
    address target;
    uint256 value;
    uint256 gasLimit;
    bytes data;
}

interface IPortal {
    function version() external view returns (string memory);
    function ethLockbox() external view returns (address);
    function anchorStateRegistry() external view returns (address);
    function systemConfig() external view returns (address);
    function paused() external view returns (bool);
    function guardian() external view returns (address);
    function superchainConfig() external view returns (address);
    function l2Sender() external view returns (address);
    function finalizedWithdrawals(bytes32) external view returns (bool);
    function provenWithdrawals(bytes32, address) external view returns (address game, uint64 ts);
    function numProofSubmitters(bytes32) external view returns (uint256);
    function finalizeWithdrawalTransactionExternalProof(WithdrawalTransaction memory, address) external;
    function finalizeWithdrawalTransaction(WithdrawalTransaction memory) external;
    function checkWithdrawal(bytes32, address) external view;
    function deleteProvenWithdrawal(bytes32, address) external;
    function migrateLiquidity() external;
    function donateETH() external payable;
    function depositTransaction(address, uint256, uint64, bool, bytes memory) external payable;
}

interface IL1CDM {
    function version() external view returns (string memory);
    function relayMessage(uint256, address, address, uint256, uint256, bytes memory) external payable;
    function successfulMessages(bytes32) external view returns (bool);
    function failedMessages(bytes32) external view returns (bool);
    function xDomainMessageSender() external view returns (address);
    function baseGas(bytes memory, uint32) external view returns (uint64);
    function paused() external view returns (bool);
    function RELAY_RESERVED_GAS() external view returns (uint64);
    function RELAY_GAS_CHECK_BUFFER() external view returns (uint64);
}

interface ILockbox {
    function paused() external view returns (bool);
    function superchainConfig() external view returns (address);
    function guardian() external view returns (address);
    function authorizedPortals(address) external view returns (bool);
    function lockETH() external payable;
    function unlockETH(uint256) external;
    function receiveLiquidity() external payable;
    function authorizePortal(address) external;
    function authorizeLockbox(address) external;
    function migrateLiquidity(address) external;
}

interface IASR {
    function paused() external view returns (bool);
    function ethLockbox() external view returns (address);
    function anchorGame() external view returns (address);
    function isGameClaimValid(address) external view returns (bool);
    function isGameProper(address) external view returns (bool);
    function isGameBlacklisted(address) external view returns (bool);
    function blacklistDisputeGame(address) external;
    function setRespectedGameType(uint32) external;
    function respectedGameType() external view returns (uint32);
    function disputeGameFactory() external view returns (address);
}

interface IGame {
    function status() external view returns (uint8);
    function createdAt() external view returns (uint64);
    function resolvedAt() external view returns (uint64);
    function gameType() external view returns (uint32);
}

interface IDGF {
    function gameAtIndex(uint256) external view returns (uint32, uint64, address);
    function gameCount() external view returns (uint256);
}

interface ISuperchainConfig {
    function pause(address) external;
    function unpause(address) external;
    function paused(address) external view returns (bool);
    function isLocalOrGlobalPaused(address) external view returns (bool);
    function guardian() external view returns (address);
}

interface ISystemConfig {
    function paused() external view returns (bool);
    function delayedWETH() external view returns (address);
    function setFeature(bytes32, bool) external;
    function l1StandardBridge() external view returns (address);
    function l1ERC721Bridge() external view returns (address);
    function l1CrossDomainMessenger() external view returns (address);
    function optimismPortal() external view returns (address);
}

interface IPausable {
    function paused() external view returns (bool);
}

interface IDelayedWETH {
    function withdraw(address, uint256) external;
    function ethLockbox() external view returns (address);
}

interface IValidator {
    struct ValidationInputDev {
        address sysCfg;
        bytes32 cannonPrestate;
        bytes32 cannonKonaPrestate;
        uint256 l2ChainID;
        address proposer;
    }

    function validate(ValidationInputDev memory, bool) external view returns (string memory);
}

/// @dev Message target used by the messenger tests.
contract Receiver {
    uint256 public mode; // 0 = accept, 1 = revert, 2 = burn all gas
    uint256 public calls;
    uint256 public lastGas;
    address public lastXSender;

    function setMode(uint256 _m) external {
        mode = _m;
    }

    fallback() external payable {
        lastGas = gasleft();
        calls++;
        if (mode == 1) revert("nope");
        if (mode == 2) {
            while (true) { }
        }
        (bool ok, bytes memory ret) = msg.sender.staticcall(abi.encodeWithSignature("xDomainMessageSender()"));
        if (ok && ret.length == 32) lastXSender = abi.decode(ret, (address));
    }
}

/// @dev Attacker-controlled message target: when its (failed) message is REPLAYED on the messenger it
///      re-enters the portal and finalizes somebody else's messenger withdrawal.
contract ReentrantTarget {
    IPortal public portal;
    WithdrawalTransaction internal victimTx;
    address public victimSubmitter;
    bool public armed;
    bool public reentered;
    bytes public reenterRevert;

    constructor(IPortal _p) {
        portal = _p;
    }

    function arm(WithdrawalTransaction memory _tx, address _s) external {
        victimTx = _tx;
        victimSubmitter = _s;
        armed = true;
    }

    fallback() external payable {
        if (!armed) revert("first relay fails on purpose");
        try portal.finalizeWithdrawalTransactionExternalProof(victimTx, victimSubmitter) {
            reentered = true;
        } catch (bytes memory err) {
            reenterRevert = err;
        }
    }
}

contract Lane12Test is Test {
    // OP Mainnet (post-U21)
    IPortal constant PORTAL = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    IL1CDM constant L1CDM = IL1CDM(0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1);
    ILockbox constant LOCKBOX = ILockbox(0x322b47Ff1FA8D5611F761e3E275C45B71b294D43);
    IASR constant ASR = IASR(0x23B2C62946350F4246f9f9D027e071f0264FD113);
    ISystemConfig constant SYSCFG = ISystemConfig(0x229047fed2591dbec1eF1118d64F7aF3dB9EB290);
    ISuperchainConfig constant SUPERCFG = ISuperchainConfig(0x95703e0982140D16f8ebA6d158FccEde42f04a4C);
    IDGF constant DGF = IDGF(0xe5965Ab5962eDc7477C8520243A95517CD252fA9);
    address constant GUARDIAN = 0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2;
    address constant L2CDM = 0x4200000000000000000000000000000000000007;
    address constant VALIDATOR = 0x9E1D01E25f411c5da20C33d1EaDe0F83256d41B2;

    uint256 constant PROVEN_SLOT = 57;

    address submitter = address(0xBEEF01);
    address anchorGame;
    Receiver receiver;

    uint256 receiverDust;

    function setUp() public {
        vm.createSelectFork("l1");
        assertEq(block.number, 26433900);
        assertEq(PORTAL.version(), "6.1.0");
        assertEq(L1CDM.version(), "2.13.0");
        anchorGame = ASR.anchorGame();
        assertTrue(ASR.isGameClaimValid(anchorGame), "anchor game must be a valid claim");
        receiver = new Receiver();
        // the deterministic forge deployment address holds mainnet dust; track it
        receiverDust = address(receiver).balance;
    }

    // ---------------------------------------------------------------- helpers

    function _hashWithdrawal(WithdrawalTransaction memory _tx) internal pure returns (bytes32) {
        return keccak256(abi.encode(_tx.nonce, _tx.sender, _tx.target, _tx.value, _tx.gasLimit, _tx.data));
    }

    function _hashMsgV1(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _minGas,
        bytes memory _data
    )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodeWithSignature(
                "relayMessage(uint256,address,address,uint256,uint256,bytes)",
                _nonce,
                _sender,
                _target,
                _value,
                _minGas,
                _data
            )
        );
    }

    /// @dev Writes provenWithdrawals[hash][submitter] = (game, ts). See the setup note at the top.
    function _plantProof(bytes32 _hash, address _submitter, address _game, uint64 _ts) internal {
        bytes32 inner = keccak256(abi.encode(_hash, PROVEN_SLOT));
        bytes32 slot = keccak256(abi.encode(_submitter, inner));
        vm.store(address(PORTAL), slot, bytes32((uint256(_ts) << 160) | uint256(uint160(_game))));
        (address g, uint64 ts) = PORTAL.provenWithdrawals(_hash, _submitter);
        assertEq(g, _game);
        assertEq(ts, _ts);
    }

    function _plantValidProof(WithdrawalTransaction memory _tx) internal returns (bytes32 h) {
        h = _hashWithdrawal(_tx);
        _plantProof(h, submitter, anchorGame, IGame(anchorGame).createdAt() + 1);
        PORTAL.checkWithdrawal(h, submitter); // must not revert: the withdrawal is finalizable
    }

    /// @dev Builds the withdrawal the L2CrossDomainMessenger (v2.2.1 on OP Mainnet, not upgraded by U21)
    ///      would have produced for sendMessage(target, message, minGas) with msg.value = value.
    function _cdmWithdrawal(
        uint256 _n,
        address _l2From,
        address _target,
        uint256 _value,
        uint32 _minGas,
        bytes memory _message
    )
        internal
        view
        returns (WithdrawalTransaction memory tx_, bytes32 msgHash_)
    {
        uint256 nonce = (uint256(1) << 240) | _n;
        bytes memory data = abi.encodeWithSignature(
            "relayMessage(uint256,address,address,uint256,uint256,bytes)", nonce, _l2From, _target, _value, _minGas, _message
        );
        // L1CDM.baseGas() reports the REMOTE (L2) budget, numerically identical to what the live
        // L2CrossDomainMessenger 2.2.1 computes (cross-checked with cast: 310160 for an empty message).
        tx_ = WithdrawalTransaction({
            nonce: nonce,
            sender: L2CDM,
            target: address(L1CDM),
            value: _value,
            gasLimit: L1CDM.baseGas(_message, _minGas),
            data: data
        });
        msgHash_ = _hashMsgV1(nonce, _l2From, _target, _value, _minGas, _message);
    }

    // ------------------------------------------------------------------------------------------
    // ROW R05 — OptimismPortal_L1CDMCallFailed (new revert)
    // ------------------------------------------------------------------------------------------

    /// Checked path: L2CDM withdrawal whose relay the messenger rejects (unsafe target = portal).
    function test_R05_checkedPath_unsafeTarget_reverts_L1CDMCallFailed() public {
        (WithdrawalTransaction memory w,) = _cdmWithdrawal(1001, address(0xA11CE), address(PORTAL), 1 ether, 100_000, "");
        bytes32 h = _plantValidProof(w);
        uint256 lbBefore = address(LOCKBOX).balance;

        vm.expectRevert(bytes4(keccak256("OptimismPortal_L1CDMCallFailed()")));
        PORTAL.finalizeWithdrawalTransactionExternalProof(w, submitter);

        assertFalse(PORTAL.finalizedWithdrawals(h));
        assertEq(address(LOCKBOX).balance, lbBefore);
        emit log_named_bytes32("R05 checked path stays unfinalized, hash", h);
    }

    /// Sibling 1: same failing call, but the L2 sender is NOT the L2CDM => finalized as failed,
    /// value goes back into the lockbox (pre-U21 behaviour, unchanged).
    function test_R05_sibling_otherSender_failure_isFinalizedAsFailed() public {
        receiver.setMode(1);
        WithdrawalTransaction memory w = WithdrawalTransaction({
            nonce: (uint256(1) << 240) | 1002,
            sender: address(0xA11CE),
            target: address(receiver),
            value: 1 ether,
            gasLimit: 100_000,
            data: hex"1234"
        });
        bytes32 h = _plantValidProof(w);
        uint256 lbBefore = address(LOCKBOX).balance;
        uint256 portalBefore = address(PORTAL).balance;

        PORTAL.finalizeWithdrawalTransactionExternalProof(w, submitter);

        assertTrue(PORTAL.finalizedWithdrawals(h));
        assertEq(address(LOCKBOX).balance, lbBefore, "value re-locked");
        assertEq(address(PORTAL).balance, portalBefore);
        assertEq(address(receiver).balance, receiverDust);
    }

    /// Sibling 2: the check keys ONLY on _tx.sender. A (hypothetical, not producible on L2) withdrawal
    /// with sender == L2CDM and an arbitrary reverting target also reverts with L1CDMCallFailed.
    function test_R05_checkKeysOnSenderOnly() public {
        receiver.setMode(1);
        WithdrawalTransaction memory w = WithdrawalTransaction({
            nonce: (uint256(1) << 240) | 1003,
            sender: L2CDM,
            target: address(receiver),
            value: 0,
            gasLimit: 100_000,
            data: hex""
        });
        _plantValidProof(w);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_L1CDMCallFailed()")));
        PORTAL.finalizeWithdrawalTransactionExternalProof(w, submitter);
    }

    /// Sibling 3: a messenger withdrawal can still be FINALIZED WITHOUT BEING DELIVERED, without
    /// tripping the new revert: the messenger returns normally after recording the message as
    /// failed when it is re-entered. An attacker replays his own failed message; its target
    /// re-enters the portal (l2Sender is the default during a replay, so the portal's guard does
    /// not fire) and finalizes the victim's withdrawal. Outcome: victim message parked in
    /// failedMessages, ETH held by the messenger, replayable by anyone. Funds are NOT lost.
    function test_R05_sibling_replayReentrancy_finalizesVictimAsFailedButReplayable() public {
        ReentrantTarget evil = new ReentrantTarget(PORTAL);

        // 1. attacker's own messenger withdrawal; first relay fails => failedMessages[atk] = true
        (WithdrawalTransaction memory wa, bytes32 ma) = _cdmWithdrawal(2001, address(0xBAD), address(evil), 0, 2_000_000, "");
        _plantValidProof(wa);
        PORTAL.finalizeWithdrawalTransactionExternalProof(wa, submitter);
        assertTrue(L1CDM.failedMessages(ma), "attacker message parked as failed");

        // 2. victim's messenger withdrawal: 5 ETH to a plain receiver
        (WithdrawalTransaction memory wv, bytes32 mv) =
            _cdmWithdrawal(2002, address(0x51C71), address(receiver), 5 ether, 200_000, "");
        bytes32 hv = _plantValidProof(wv);
        evil.arm(wv, submitter);

        uint256 lbBefore = address(LOCKBOX).balance;
        uint256 cdmBefore = address(L1CDM).balance;

        // 3. attacker replays his message; target re-enters portal.finalize(victim)
        L1CDM.relayMessage((uint256(1) << 240) | 2001, address(0xBAD), address(evil), 0, 2_000_000, "");

        assertTrue(evil.reentered(), "re-entered finalize did not revert");
        assertTrue(PORTAL.finalizedWithdrawals(hv), "victim withdrawal finalized");
        assertFalse(L1CDM.successfulMessages(mv), "victim message NOT delivered");
        assertTrue(L1CDM.failedMessages(mv), "victim message parked as failed");
        assertEq(receiver.calls(), 0);
        assertEq(address(LOCKBOX).balance, lbBefore - 5 ether, "ETH left the lockbox");
        assertEq(address(L1CDM).balance, cdmBefore + 5 ether, "ETH sits in the messenger");

        // 4. anyone can replay the victim's message; ETH is delivered
        vm.prank(address(0xCAFE));
        L1CDM.relayMessage((uint256(1) << 240) | 2002, address(0x51C71), address(receiver), 5 ether, 200_000, "");
        assertTrue(L1CDM.successfulMessages(mv));
        assertEq(address(receiver).balance, receiverDust + 5 ether);
        assertEq(receiver.lastXSender(), address(0x51C71));
    }

    // ------------------------------------------------------------------------------------------
    // ROWS R17/R18/R20 — L1 relay reserve raised to 135k+15k while the live L2CDM still budgets 40k+5k
    // ------------------------------------------------------------------------------------------

    /// One finalize call with exactly `g` gas forwarded to the portal. Returns:
    /// 0 = portal reverted, 1 = finalized + message delivered, 2 = finalized + message parked failed.
    function _tryFinalize(WithdrawalTransaction memory w, bytes32 m, uint256 g) internal returns (uint8 r) {
        uint256 snap = vm.snapshotState();
        try PORTAL.finalizeWithdrawalTransactionExternalProof{ gas: g }(w, submitter) {
            if (L1CDM.successfulMessages(m)) r = 1;
            else if (L1CDM.failedMessages(m)) r = 2;
            else r = 3;
        } catch {
            r = 0;
        }
        vm.revertToState(snap);
    }

    function _gasWindow(uint32 _minGas, uint256 _value, bytes memory _message, uint256 _mode) internal {
        receiver.setMode(_mode);
        (WithdrawalTransaction memory w, bytes32 m) =
            _cdmWithdrawal(3000 + _minGas, address(0xA11CE), address(receiver), _value, _minGas, _message);
        _plantValidProof(w);

        // lowest gas at which the portal call does not revert
        uint256 lo = 50_000;
        uint256 hi = 20_000_000;
        require(_tryFinalize(w, m, hi) != 0, "must not revert with plenty of gas");
        while (hi - lo > 1) {
            uint256 mid = (lo + hi) / 2;
            if (_tryFinalize(w, m, mid) == 0) lo = mid;
            else hi = mid;
        }
        uint256 gNoRevert = hi;
        uint8 atMin = _tryFinalize(w, m, gNoRevert);

        // lowest gas at which the message is delivered (mode 0) — scan upward from gNoRevert
        uint256 gDelivered = 0;
        if (_mode == 0) {
            uint256 lo2 = gNoRevert - 1;
            uint256 hi2 = 20_000_000;
            while (hi2 - lo2 > 1) {
                uint256 mid = (lo2 + hi2) / 2;
                if (_tryFinalize(w, m, mid) == 1) hi2 = mid;
                else lo2 = mid;
            }
            gDelivered = hi2;
        }

        // The revert/no-revert boundary need not be monotonic: scan 200k gas below and 150k above
        // the threshold in 500-gas steps and count every finalize that succeeds without delivery.
        uint256 parked;
        uint256 firstParked;
        if (_mode == 0) {
            for (uint256 g = gNoRevert - 200_000; g < gNoRevert + 150_000; g += 500) {
                uint8 r = _tryFinalize(w, m, g);
                if (r == 2 || r == 3) {
                    parked++;
                    if (firstParked == 0) firstParked = g;
                }
            }
        }
        emit log_named_uint("scan: finalize-succeeds-but-not-delivered samples", parked);
        if (parked != 0) emit log_named_uint("scan: first such gas", firstParked);

        emit log_named_uint("minGasLimit", _minGas);
        emit log_named_uint("message bytes", _message.length);
        emit log_named_uint("withdrawal gasLimit (L2 baseGas, old constants)", w.gasLimit);
        emit log_named_uint("lowest portal gas that does not revert", gNoRevert);
        emit log_named_uint("outcome at that gas (1=delivered,2=parked failed)", atMin);
        emit log_named_uint("lowest portal gas that delivers", gDelivered);
        if (gDelivered > gNoRevert) emit log_named_uint("forced-fail window (gas units)", gDelivered - gNoRevert);
    }

    function test_R17_gasWindow_emptyMessage_minGas0() public {
        _gasWindow(0, 0, "", 0);
    }

    function test_R17_gasWindow_emptyMessage_minGas100k_value() public {
        _gasWindow(100_000, 1 ether, "", 0);
    }

    function test_R17_gasWindow_2kbMessage_minGas200k() public {
        _gasWindow(200_000, 0, new bytes(2048), 0);
    }

    function test_R17_gasWindow_20kbMessage_minGas200k() public {
        bytes memory big = new bytes(20_000);
        for (uint256 i; i < big.length; i++) {
            big[i] = 0xff;
        }
        _gasWindow(200_000, 0, big, 0);
    }

    /// Target burns all forwarded gas: the messenger must still record the failure (reserved gas).
    function test_R18_gasBurningTarget_isRecordedNotReverted() public {
        _gasWindow(100_000, 1 ether, "", 2);
    }


    // ------------------------------------------------------------------------------------------
    // ROW R17 (measurement) — gas the L1CDM frame itself needs, called as the portal with
    // l2Sender == L2CDM, from a COLD context (worst case: in a real finalize the SystemConfig,
    // portal, lockbox and SuperchainConfig are already warm). Compared with what the live
    // L2CrossDomainMessenger 2.2.1 budgets (its baseGas == withdrawal gasLimit).
    // ------------------------------------------------------------------------------------------

    struct Frame {
        uint256 nonce;
        uint256 value;
        uint32 minGas;
        bytes message;
        bytes32 m;
    }

    function _frameOutcome(Frame memory f, uint256 g) internal returns (uint8 r) {
        uint256 snap = vm.snapshotState();
        vm.deal(address(PORTAL), f.value);
        vm.prank(address(PORTAL));
        try L1CDM.relayMessage{ gas: g, value: f.value }(
            f.nonce, address(0xA11CE), address(receiver), f.value, f.minGas, f.message
        ) {
            if (L1CDM.successfulMessages(f.m)) r = 1;
            else if (L1CDM.failedMessages(f.m)) r = 2;
            else r = 3;
        } catch {
            r = 0;
        }
        vm.revertToState(snap);
    }

    function _search(Frame memory f, uint256 lo, uint8 want) internal returns (uint256) {
        // lowest g > lo with outcome == want (want == 255 means "any non-revert")
        uint256 hi = 20_000_000;
        while (hi - lo > 1) {
            uint256 mid = (lo + hi) / 2;
            uint8 r = _frameOutcome(f, mid);
            bool ok = want == 255 ? r != 0 : r == want;
            if (ok) hi = mid;
            else lo = mid;
        }
        return hi;
    }

    function _measureFrame(uint32 minGas, uint256 value, bytes memory message, uint256 mode) internal {
        receiver.setMode(mode);
        Frame memory f;
        f.nonce = (uint256(1) << 240) | (3000 + minGas); // same message hashes as the _gasWindow tests
        f.value = value;
        f.minGas = minGas;
        f.message = message;
        f.m = _hashMsgV1(f.nonce, address(0xA11CE), address(receiver), value, minGas, message);
        // portal.l2Sender (slot 50) := L2CDM, i.e. the portal is mid-finalize of a messenger withdrawal
        vm.store(address(PORTAL), bytes32(uint256(50)), bytes32(uint256(uint160(L2CDM))));

        uint256 budget = L1CDM.baseGas(message, minGas);
        uint256 gNoRevert = _search(f, 20_000, 255);
        emit log_named_uint("minGasLimit", minGas);
        emit log_named_uint("message bytes", message.length);
        emit log_named_uint("L2 budget for the frame (withdrawal gasLimit)", budget);
        emit log_named_uint("frame gas: lowest that does not revert", gNoRevert);
        emit log_named_uint("  outcome there (1 delivered, 2 parked failed)", _frameOutcome(f, gNoRevert));
        emit log_named_uint("outcome with exactly the L2 budget", _frameOutcome(f, budget));
        if (mode == 0) {
            uint256 gDeliver = _search(f, gNoRevert - 1, 1);
            emit log_named_uint("frame gas: lowest that delivers", gDeliver);
            if (budget >= gDeliver) emit log_named_uint("margin (budget - needed)", budget - gDeliver);
            else emit log_named_uint("SHORTFALL (needed - budget)", gDeliver - budget);
        }
    }

    function test_R17_frame_empty_minGas0() public {
        _measureFrame(0, 0, "", 0);
    }

    function test_R17_frame_empty_minGas100k_value() public {
        _measureFrame(100_000, 1 ether, "", 0);
    }

    function test_R17_frame_20kb_minGas200k() public {
        bytes memory big = new bytes(20_000);
        for (uint256 i; i < big.length; i++) {
            big[i] = 0xff;
        }
        _measureFrame(200_000, 0, big, 0);
    }

    function test_R17_frame_100kb_minGas200k() public {
        bytes memory big = new bytes(100_000);
        for (uint256 i; i < big.length; i++) {
            big[i] = 0xff;
        }
        _measureFrame(200_000, 0, big, 0);
    }

    function test_R18_frame_burner_minGas100k_value() public {
        _measureFrame(100_000, 1 ether, "", 2);
    }

    // ------------------------------------------------------------------------------------------
    // ROW R06 — deleteProvenWithdrawal (new, permissionless, no pause check)
    // ------------------------------------------------------------------------------------------

    function test_R06_delete_validGame_reverts_NotInvalidated() public {
        (WithdrawalTransaction memory w,) = _cdmWithdrawal(4001, address(0xA11CE), address(receiver), 1 ether, 100_000, "");
        bytes32 h = _plantValidProof(w);
        vm.prank(address(0xBAD));
        vm.expectRevert(bytes4(keccak256("OptimismPortal_DisputeGameNotInvalidated()")));
        PORTAL.deleteProvenWithdrawal(h, submitter);

        vm.expectRevert(bytes4(keccak256("OptimismPortal_Unproven()")));
        PORTAL.deleteProvenWithdrawal(h, address(0x1234));
    }

    function test_R06_delete_inProgressGame_reverts_NotInvalidated() public {
        (,, address g) = DGF.gameAtIndex(DGF.gameCount() - 1);
        assertEq(IGame(g).status(), 0, "latest game should be in progress");
        bytes32 h = keccak256("some withdrawal");
        _plantProof(h, submitter, g, IGame(g).createdAt() + 1);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_DisputeGameNotInvalidated()")));
        PORTAL.deleteProvenWithdrawal(h, submitter);
    }

    /// Guardian blacklists a game (a state production can be in: it is the documented incident
    /// response). Then ANY account deletes the proof, even while the chain is paused.
    function test_R06_delete_afterBlacklist_permissionless_evenWhenPaused() public {
        (WithdrawalTransaction memory w,) = _cdmWithdrawal(4002, address(0xA11CE), address(receiver), 1 ether, 100_000, "");
        bytes32 h = _plantValidProof(w);

        vm.startPrank(GUARDIAN);
        ASR.blacklistDisputeGame(anchorGame);
        SUPERCFG.pause(address(LOCKBOX));
        vm.stopPrank();
        assertTrue(PORTAL.paused());

        vm.prank(address(0xBAD));
        PORTAL.deleteProvenWithdrawal(h, submitter);
        (address g, uint64 ts) = PORTAL.provenWithdrawals(h, submitter);
        assertEq(g, address(0));
        assertEq(ts, 0);

        vm.prank(GUARDIAN);
        SUPERCFG.unpause(address(LOCKBOX));
        vm.expectRevert(bytes4(keccak256("OptimismPortal_Unproven()")));
        PORTAL.finalizeWithdrawalTransactionExternalProof(w, submitter);
    }

    /// A CHALLENGER_WINS game from 2024 (index 0, type 0, long retired): proof deletable by anyone.
    function test_R06_delete_challengerWinsGame_permissionless() public {
        (,, address g) = DGF.gameAtIndex(0);
        assertEq(IGame(g).status(), 1, "index 0 is CHALLENGER_WINS");
        bytes32 h = keccak256("old withdrawal");
        _plantProof(h, submitter, g, IGame(g).createdAt() + 1);
        vm.prank(address(0xBAD));
        PORTAL.deleteProvenWithdrawal(h, submitter);
        (address g2,) = PORTAL.provenWithdrawals(h, submitter);
        assertEq(g2, address(0));
    }

    /// The deleted entry is the CURRENT entry of that submitter only; a second submitter's proof
    /// against a valid game for the same withdrawal is untouched and still finalizes.
    function test_R06_delete_doesNotAffectOtherSubmitters() public {
        (WithdrawalTransaction memory w, bytes32 m) =
            _cdmWithdrawal(4003, address(0xA11CE), address(receiver), 1 ether, 100_000, "");
        bytes32 h = _hashWithdrawal(w);
        (,, address bad) = DGF.gameAtIndex(0);
        _plantProof(h, address(0xBAD), bad, IGame(bad).createdAt() + 1);
        _plantProof(h, submitter, anchorGame, IGame(anchorGame).createdAt() + 1);

        PORTAL.deleteProvenWithdrawal(h, address(0xBAD));
        PORTAL.finalizeWithdrawalTransactionExternalProof(w, submitter);
        assertTrue(L1CDM.successfulMessages(m));
        assertEq(address(receiver).balance, receiverDust + 1 ether);

        // a proof of an already-finalized withdrawal can still be deleted later: harmless
        vm.prank(GUARDIAN);
        ASR.blacklistDisputeGame(anchorGame);
        PORTAL.deleteProvenWithdrawal(h, submitter);
        assertTrue(PORTAL.finalizedWithdrawals(h));
    }

    // ------------------------------------------------------------------------------------------
    // ROWS R01/R10/R16/R22/R25 — pause is resolved through the ETHLockbox everywhere
    // ------------------------------------------------------------------------------------------

    function _allPaused() internal view returns (bool[7] memory p) {
        p[0] = PORTAL.paused();
        p[1] = SYSCFG.paused();
        p[2] = ASR.paused();
        p[3] = L1CDM.paused();
        p[4] = IPausable(SYSCFG.l1StandardBridge()).paused();
        p[5] = IPausable(SYSCFG.l1ERC721Bridge()).paused();
        p[6] = LOCKBOX.paused();
    }

    function test_pause_lockboxIdentifier_pausesEverything() public {
        vm.prank(GUARDIAN);
        SUPERCFG.pause(address(LOCKBOX));
        bool[7] memory p = _allPaused();
        for (uint256 i; i < 7; i++) {
            assertTrue(p[i]);
        }
        IDelayedWETH dw = IDelayedWETH(SYSCFG.delayedWETH());
        vm.expectRevert(bytes("DelayedWETH: contract is paused"));
        dw.withdraw(address(this), 0);
    }

    function test_pause_globalIdentifier_pausesEverything() public {
        vm.prank(GUARDIAN);
        SUPERCFG.pause(address(0));
        bool[7] memory p = _allPaused();
        for (uint256 i; i < 7; i++) {
            assertTrue(p[i]);
        }
    }

    /// Negative space: every OTHER address in the system is a dead pause identifier.
    function test_pause_portalOrSystemConfigIdentifier_pausesNothing() public {
        vm.startPrank(GUARDIAN);
        SUPERCFG.pause(address(PORTAL));
        SUPERCFG.pause(address(SYSCFG));
        SUPERCFG.pause(address(ASR));
        SUPERCFG.pause(address(L1CDM));
        vm.stopPrank();
        bool[7] memory p = _allPaused();
        for (uint256 i; i < 7; i++) {
            assertFalse(p[i]);
        }
        // not paused: the DelayedWETH pause check passes and the next require fires
        IDelayedWETH dw = IDelayedWETH(SYSCFG.delayedWETH());
        vm.expectRevert(bytes("DelayedWETH: withdrawal not unlocked"));
        dw.withdraw(address(this), 0);
    }

    /// Sibling escrow that the lockbox-identifier pause does NOT reach: the three legacy DelayedWETH
    /// proxies (v1.0.0 / v1.1.0 / v1.3.0, 0.16 + 0.08 + 0.08 ETH of old bonds) read the argument-less
    /// SuperchainConfig.paused() == paused(address(0)), i.e. only the GLOBAL pause. Pre-existing, dust.
    function test_pause_legacyDelayedWETH_onlyGlobalPauseReachesThem() public {
        address[3] memory legacy = [
            0xE497B094d6DbB3D5E4CaAc9a14696D7572588d14,
            0x82511d494B5C942BE57498a70Fdd7184Ee33B975,
            0x323dFC63c9B83CB83f40325AaB74b245937cbdF0
        ];
        vm.prank(GUARDIAN);
        SUPERCFG.pause(address(LOCKBOX));
        assertTrue(PORTAL.paused());
        for (uint256 i; i < 3; i++) {
            // pause check passes, the next require fires
            vm.expectRevert(bytes("DelayedWETH: withdrawal not unlocked"));
            IDelayedWETH(legacy[i]).withdraw(address(this), 0);
        }
        vm.prank(GUARDIAN);
        SUPERCFG.pause(address(0));
        for (uint256 i; i < 3; i++) {
            vm.expectRevert(bytes("DelayedWETH: contract is paused"));
            IDelayedWETH(legacy[i]).withdraw(address(this), 0);
        }
    }

    /// Pause does not stop deposits (lockETH has no pause check) and does not stop proof deletion;
    /// it does stop prove/finalize and unlockETH.
    function test_pause_scope() public {
        (WithdrawalTransaction memory w,) = _cdmWithdrawal(5001, address(0xA11CE), address(receiver), 1 ether, 100_000, "");
        _plantValidProof(w);
        vm.prank(GUARDIAN);
        SUPERCFG.pause(address(LOCKBOX));

        vm.expectRevert(bytes4(keccak256("OptimismPortal_CallPaused()")));
        PORTAL.finalizeWithdrawalTransactionExternalProof(w, submitter);

        uint256 lb = address(LOCKBOX).balance;
        vm.deal(address(this), 2 ether);
        vm.prank(address(this), address(this)); // EOA-style caller
        PORTAL.depositTransaction{ value: 1 ether }(address(this), 1 ether, 100_000, false, "");
        assertEq(address(LOCKBOX).balance, lb + 1 ether, "deposit accepted while paused");
    }

    // ------------------------------------------------------------------------------------------
    // ROW R21 — SafeCall.callWithMinGas reserves 183,600 extra gas for value to an empty account
    // ------------------------------------------------------------------------------------------

    function _minPortalGas(WithdrawalTransaction memory w) internal returns (uint256) {
        uint256 lo = 30_000;
        uint256 hi = 5_000_000;
        while (hi - lo > 1) {
            uint256 mid = (lo + hi) / 2;
            uint256 snap = vm.snapshotState();
            bool ok;
            try PORTAL.finalizeWithdrawalTransactionExternalProof{ gas: mid }(w, submitter) {
                ok = true;
            } catch { }
            vm.revertToState(snap);
            if (ok) hi = mid;
            else lo = mid;
        }
        return hi;
    }

    function test_R21_newAccountStateGas_reservation() public {
        address fresh = address(uint160(uint256(keccak256("lane12 fresh account"))));
        address funded = address(uint160(uint256(keccak256("lane12 funded account"))));
        vm.deal(funded, 1 wei);
        assertEq(fresh.codehash, bytes32(0));
        assertTrue(funded.codehash != bytes32(0));

        WithdrawalTransaction memory a = WithdrawalTransaction({
            nonce: (uint256(1) << 240) | 6001,
            sender: address(0xA11CE),
            target: fresh,
            value: 1 ether,
            gasLimit: 0,
            data: hex""
        });
        WithdrawalTransaction memory b = WithdrawalTransaction({
            nonce: (uint256(1) << 240) | 6002,
            sender: address(0xA11CE),
            target: funded,
            value: 1 ether,
            gasLimit: 0,
            data: hex""
        });
        WithdrawalTransaction memory c = WithdrawalTransaction({
            nonce: (uint256(1) << 240) | 6003,
            sender: address(0xA11CE),
            target: fresh,
            value: 0,
            gasLimit: 0,
            data: hex""
        });
        _plantValidProof(a);
        _plantValidProof(b);
        _plantValidProof(c);
        uint256 ga = _minPortalGas(a);
        uint256 gb = _minPortalGas(b);
        uint256 gc = _minPortalGas(c);
        emit log_named_uint("min portal gas, value -> empty account", ga);
        emit log_named_uint("min portal gas, value -> funded EOA", gb);
        emit log_named_uint("min portal gas, zero value -> empty account", gc);
        emit log_named_uint("delta empty vs funded", ga - gb);
    }

    // ------------------------------------------------------------------------------------------
    // ROWS R03/R09/R11 — authorization siblings on portal / lockbox
    // ------------------------------------------------------------------------------------------

    function test_auth_siblings() public {
        address rando = address(0xBAD);
        vm.deal(rando, 10 ether);
        vm.startPrank(rando);

        vm.expectRevert(bytes4(keccak256("ProxyAdminOwnedBase_NotProxyAdminOwner()")));
        PORTAL.migrateLiquidity();

        vm.expectRevert(bytes4(keccak256("ETHLockbox_Unauthorized()")));
        LOCKBOX.lockETH{ value: 1 }();
        vm.expectRevert(bytes4(keccak256("ETHLockbox_Unauthorized()")));
        LOCKBOX.unlockETH(1);
        vm.expectRevert(bytes4(keccak256("ETHLockbox_Unauthorized()")));
        LOCKBOX.receiveLiquidity{ value: 1 }();
        vm.expectRevert(bytes4(keccak256("ProxyAdminOwnedBase_NotProxyAdminOwner()")));
        LOCKBOX.authorizePortal(rando);
        vm.expectRevert(bytes4(keccak256("ProxyAdminOwnedBase_NotProxyAdminOwner()")));
        LOCKBOX.authorizeLockbox(rando);
        vm.expectRevert(bytes4(keccak256("ProxyAdminOwnedBase_NotProxyAdminOwner()")));
        LOCKBOX.migrateLiquidity(rando);
        vm.expectRevert(bytes4(keccak256("ProxyAdminOwnedBase_NotProxyAdminOrProxyAdminOwner()")));
        SYSCFG.setFeature(bytes32("INTEROP"), true);
        vm.expectRevert(bytes4(keccak256("AnchorStateRegistry_Unauthorized()")));
        ASR.setRespectedGameType(5);

        // plain ETH transfer to the lockbox is refused (no receive/fallback)
        (bool ok,) = address(LOCKBOX).call{ value: 1 }("");
        assertFalse(ok);

        // donateETH is the only unauthenticated way to put ETH on the portal: it stays there
        uint256 lb = address(LOCKBOX).balance;
        PORTAL.donateETH{ value: 1 ether }();
        assertEq(address(PORTAL).balance, 1 ether);
        assertEq(address(LOCKBOX).balance, lb);
        vm.stopPrank();

        // a donated balance does not change withdrawal accounting
        (WithdrawalTransaction memory w, bytes32 m) =
            _cdmWithdrawal(7001, address(0xA11CE), address(receiver), 2 ether, 100_000, "");
        _plantValidProof(w);
        PORTAL.finalizeWithdrawalTransactionExternalProof(w, submitter);
        assertTrue(L1CDM.successfulMessages(m));
        assertEq(address(PORTAL).balance, 1 ether);
        assertEq(address(LOCKBOX).balance, lb - 2 ether);
    }

    /// The lockbox refuses to unlock while the portal is mid-withdrawal (l2Sender set): a withdrawal
    /// target cannot make the portal pull more ETH. Portal blocks the re-entry first.
    function test_unlockETH_duringWithdrawal_blocked() public {
        ReentrantTarget evil = new ReentrantTarget(PORTAL);
        WithdrawalTransaction memory inner = WithdrawalTransaction({
            nonce: (uint256(1) << 240) | 7101,
            sender: address(0xA11CE),
            target: address(receiver),
            value: 1 ether,
            gasLimit: 100_000,
            data: hex""
        });
        _plantValidProof(inner);
        evil.arm(inner, submitter);
        WithdrawalTransaction memory outer = WithdrawalTransaction({
            nonce: (uint256(1) << 240) | 7102,
            sender: address(0xA11CE),
            target: address(evil),
            value: 0,
            gasLimit: 1_000_000,
            data: hex""
        });
        _plantValidProof(outer);
        PORTAL.finalizeWithdrawalTransactionExternalProof(outer, submitter);
        assertFalse(evil.reentered());
        assertEq(bytes4(evil.reenterRevert()), bytes4(keccak256("OptimismPortal_NoReentrancy()")));
    }

    // ------------------------------------------------------------------------------------------
    // Validator (off-path assertions) evaluated on the fork for all four upgraded chains
    // ------------------------------------------------------------------------------------------

    function test_validator_allFourChains() public {
        bytes32 pre = 0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9;
        string memory op = IValidator(VALIDATOR).validate(
            IValidator.ValidationInputDev(address(SYSCFG), bytes32(0), pre, 10, 0xc27ba3E0Fc01567a5E57Ae0c391AA98cECBA5bE0), true
        );
        string memory ink = IValidator(VALIDATOR).validate(
            IValidator.ValidationInputDev(
                0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364, bytes32(0), pre, 57073, 0x3832bfbeF03173E4C49a00ec0DD178817A02D177
            ),
            true
        );
        string memory son = IValidator(VALIDATOR).validate(
            IValidator.ValidationInputDev(
                0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3, bytes32(0), pre, 1868, 0x400c164C4a8cA84385B70EEd6eB03ea847c8E1b8
            ),
            true
        );
        string memory uni = IValidator(VALIDATOR).validate(
            IValidator.ValidationInputDev(
                0xc407398d063f942feBbcC6F80a156b47F3f1BDA6, bytes32(0), pre, 130, 0x86b392cA30aD7453c8d88B56EB5A04fD0E2175b7
            ),
            true
        );
        emit log_named_string("OP Mainnet ", op);
        emit log_named_string("Ink        ", ink);
        emit log_named_string("Soneium    ", son);
        emit log_named_string("Unichain   ", uni);
        assertEq(op, "");
        assertEq(ink, "");
        assertEq(uni, "");
    }

    /// A permissionless actor CAN move one validator-visible value: PORTAL-80 (l2Sender == default)
    /// is false for the duration of any withdrawal call. Read from inside a withdrawal target.
    function test_validator_PORTAL80_isTransientlyFalse() public {
        L2SenderProbe probe = new L2SenderProbe(PORTAL);
        WithdrawalTransaction memory w = WithdrawalTransaction({
            nonce: (uint256(1) << 240) | 8001,
            sender: address(0xA11CE),
            target: address(probe),
            value: 0,
            gasLimit: 200_000,
            data: hex""
        });
        _plantValidProof(w);
        PORTAL.finalizeWithdrawalTransactionExternalProof(w, submitter);
        assertEq(probe.seen(), address(0xA11CE));
        assertEq(PORTAL.l2Sender(), address(0x000000000000000000000000000000000000dEaD));
    }
}

contract L2SenderProbe {
    IPortal immutable portal;
    address public seen;

    constructor(IPortal _p) {
        portal = _p;
    }

    fallback() external payable {
        seen = portal.l2Sender();
    }
}
