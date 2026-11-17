// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./U21Fixtures.sol";

// ------------------------------------------------------------------------------------------------
// Invariant suite around REAL finalizations and deposits on the post-U21 fork (`l1`, v9 code).
//
// Handlers (all permissionless unless stated):
//   deposit / depositViaMessenger / donateETH / prove (replay of the recorded mainnet proof
//   calldata by a DIFFERENT submitter) / finalize (own proof, external proof, random gas) /
//   replay (L1CDM.relayMessage of a failed message) / deleteProof / warp /
//   etchTarget (HARNESS: vm.etch adversarial code at a fixture's (inner) target: revert, burn,
//   return-bomb, re-enter every portal/lockbox/messenger entry point) /
//   pause / unpause (vm.prank GUARDIAN on SuperchainConfig.pause(lockbox) - the production
//   incident path) / blacklist (vm.prank GUARDIAN on ASR.blacklistDisputeGame - production
//   incident path for an invalid game).
// The privileged pranks only set up states production can be in; no invariant below depends on a
// privileged actor misbehaving.
// ------------------------------------------------------------------------------------------------

address constant BRAIN = address(0xb7a1b7a1B7a1b7A1b7A1b7A1B7A1B7a1b7a1B7A1);

interface IBrain {
    function onCall() external payable;
}

contract StubRevert {
    fallback() external payable {
        revert("stub");
    }
}

contract StubBurn {
    fallback() external payable {
        assembly {
            invalid()
        }
    }
}

contract StubBomb {
    fallback() external payable {
        assembly {
            return(0, 200000)
        }
    }
}

contract StubReenter {
    fallback() external payable {
        IBrain(BRAIN).onCall{ value: msg.value }();
    }
}

/// @dev Lives at the fixed BRAIN address; the stateless StubReenter code etched at a target
///      forwards here, so no foreign storage is ever touched by the adversary.
contract Brain {
    IPortal constant PORTAL = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    ILockbox constant LOCKBOX = ILockbox(0x322b47Ff1FA8D5611F761e3E275C45B71b294D43);
    IMessenger constant L1CDM = IMessenger(0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1);

    bytes public otherFinalize;
    bytes public selfRelay;
    uint256 public forbiddenMask; // sticky: bit set => a forbidden re-entrant call SUCCEEDED
    uint256 public calls;
    uint256 public deposited; // ETH re-deposited into the portal from inside a withdrawal
    uint256 public donated; // ETH donated to the portal from inside a withdrawal

    function arm(bytes calldata a, bytes calldata b) external {
        otherFinalize = a;
        selfRelay = b;
    }

    function onCall() external payable {
        calls++;
        bool ok;
        if (otherFinalize.length != 0) {
            (ok,) = address(PORTAL).call{ gas: gasleft() / 6 }(otherFinalize);
            if (ok) forbiddenMask |= 1;
        }
        if (selfRelay.length != 0) {
            (ok,) = address(L1CDM).call{ gas: gasleft() / 6 }(selfRelay);
            if (ok) forbiddenMask |= 2;
        }
        (ok,) = address(LOCKBOX).call{ gas: gasleft() / 6 }(abi.encodeCall(ILockbox.unlockETH, (1 ether)));
        if (ok) forbiddenMask |= 4;
        (ok,) = address(LOCKBOX).call{ gas: gasleft() / 6 }(abi.encodeCall(ILockbox.lockETH, ()));
        if (ok) forbiddenMask |= 8;
        (ok,) = address(PORTAL).call{ gas: gasleft() / 6 }(abi.encodeCall(IPortal.migrateLiquidity, ()));
        if (ok) forbiddenMask |= 16;
        // Legit value-moving re-entrancy: deposit half of what we got, donate 1 wei.
        if (msg.value > 3) {
            uint256 half = msg.value / 2;
            (ok,) = address(PORTAL).call{ gas: gasleft() / 3, value: half }(
                abi.encodeCall(IPortal.depositTransaction, (address(this), half, uint64(100_000), false, bytes("")))
            );
            if (ok) deposited += half;
            (ok,) = address(PORTAL).call{ gas: gasleft() / 3, value: 1 }(abi.encodeCall(IPortal.donateETH, ()));
            if (ok) donated += 1;
        }
    }
}

contract PortalHandler is U21FixtureBase {
    bytes32 constant WITHDRAWAL_FINALIZED = keccak256("WithdrawalFinalized(bytes32,bool)");

    Fixture[] internal fx;
    address[3] public actors;
    Brain public brain;

    // ghosts
    uint256 public gDeposits;
    uint256 public gDonations;
    uint256 public gDelivered; // value that left the lockbox/portal/messenger system to a target
    uint256 public gHeldByMessenger; // value of failed-not-yet-relayed messenger messages
    mapping(bytes32 => uint256) public finalizeCount;
    mapping(bytes32 => bool) public msgDelivered;
    mapping(bytes32 => bool) public msgHeld;
    mapping(address => bytes) internal originalCode;
    mapping(address => bool) internal codeSaved;

    // violation counters (each must stay 0)
    uint256 public vDoubleFinalize;
    uint256 public vDoubleDelivery;
    uint256 public vNeither;
    uint256 public vPausedSuccess;
    uint256 public vIsolation;
    uint256 public vFinalizeWithoutValidProof;
    uint256 public vDeleteMismatch;
    uint256 public vPortalBalanceDrift;
    uint256 public vProveBookkeeping;
    string public firstViolation;

    // coverage counters
    mapping(bytes32 => uint256) public cov;
    bytes32[] public covKeys;

    address[] internal stubs;
    uint256[] internal failedIdx; // fixtures finalized into failedMessages
    uint256[] internal plainIdx;
    uint256 internal curFi;

    constructor() {
        uint256 n = _fixtureCount();
        for (uint256 i; i < n; i++) {
            fx.push(_loadFixture(i));
            if (!fx[i].messenger) plainIdx.push(i);
        }
        actors[0] = address(0xA11CE01);
        actors[1] = address(0xB0B02);
        actors[2] = address(0xCA401);
        for (uint256 i; i < 3; i++) {
            vm.deal(actors[i], 1_000_000 ether);
        }
        vm.etch(BRAIN, address(new Brain()).code);
        brain = Brain(BRAIN);
        stubs.push(address(new StubRevert()));
        stubs.push(address(new StubBurn()));
        stubs.push(address(new StubBomb()));
        stubs.push(address(new StubReenter()));
    }

    function fixtureCount() external view returns (uint256) {
        return fx.length;
    }

    function fixtureHash(uint256 i) external view returns (bytes32) {
        return fx[i].hash;
    }

    function fixtureIsMessenger(uint256 i) external view returns (bool) {
        return fx[i].messenger;
    }

    function fixtureMsgHash(uint256 i) external view returns (bytes32) {
        return keccak256(fx[i].wd.data);
    }

    function fixtureSubmitter(uint256 i) external view returns (address) {
        return fx[i].proofSubmitter;
    }

    function covCount() external view returns (uint256) {
        return covKeys.length;
    }

    function _cov(string memory k) internal {
        bytes32 h = bytes32(bytes(k));
        if (cov[h] == 0) covKeys.push(h);
        cov[h]++;
    }

    function _viol(string memory what) internal {
        if (bytes(firstViolation).length == 0) firstViolation = what;
    }

    function _postCall() internal {
        if (address(PORTAL).balance != gDonations + brain.donated()) {
            vPortalBalanceDrift++;
            _viol("portal balance != donations after call");
        }
    }

    function _innerTarget(Fixture memory f) internal pure returns (address) {
        return f.messenger ? decodeInner(f.wd).target : f.wd.target;
    }

    // ------------------------------------------------------------------ deposits
    function deposit(uint256 actorSeed, uint256 value, uint256 dataLen, bool viaReceive) external {
        address a = actors[actorSeed % 3];
        value = bound(value, 0, 50 ether);
        dataLen = bound(dataLen, 0, 2_000);
        bool ok;
        vm.prank(a, a);
        if (viaReceive) {
            (ok,) = address(PORTAL).call{ value: value }("");
        } else {
            (ok,) = address(PORTAL).call{ value: value }(
                abi.encodeCall(
                    IPortal.depositTransaction, (a, value, uint64(21_000 + 40 * dataLen + 50_000), false, new bytes(dataLen))
                )
            );
        }
        if (ok) gDeposits += value;
        _cov(ok ? "deposit.ok" : "deposit.revert");
        if (ok && PORTAL.paused()) _cov("deposit.ok.whilePaused"); // by design: locks are not paused
        _postCall();
    }

    function depositViaMessenger(uint256 actorSeed, uint256 value) external {
        address a = actors[actorSeed % 3];
        value = bound(value, 0, 10 ether);
        vm.prank(a, a);
        (bool ok,) = address(L1CDM).call{ value: value }(
            abi.encodeCall(IMessenger.sendMessage, (a, bytes(""), uint32(100_000)))
        );
        if (ok) gDeposits += value;
        _cov(ok ? "sendMessage.ok" : "sendMessage.revert");
        _postCall();
    }

    function donate(uint256 actorSeed, uint256 value) external {
        address a = actors[actorSeed % 3];
        value = bound(value, 0, 1 ether);
        vm.prank(a, a);
        PORTAL.donateETH{ value: value }();
        gDonations += value;
        _cov("donate.ok");
        _postCall();
    }

    // ------------------------------------------------------------------ prove
    function prove(uint256 fi, uint256 actorSeed) external {
        Fixture memory f = fx[fi % fx.length];
        address b = actors[actorSeed % 3];
        // snapshot every OTHER submitter's entry
        (address g0, uint64 t0) = PORTAL.provenWithdrawals(f.hash, f.proofSubmitter);
        address[3] memory og;
        uint64[3] memory ot;
        for (uint256 i; i < 3; i++) {
            (og[i], ot[i]) = PORTAL.provenWithdrawals(f.hash, actors[i]);
        }
        uint256 nBefore = PORTAL.numProofSubmitters(f.hash);
        bool wasPaused = PORTAL.paused();
        (bool ok,) = _reproveAs(f, b);
        if (ok && wasPaused) {
            vPausedSuccess++;
            _viol("prove succeeded while paused");
        }
        (address g1, uint64 t1) = PORTAL.provenWithdrawals(f.hash, f.proofSubmitter);
        if (f.proofSubmitter != b && (g1 != g0 || t1 != t0)) {
            vIsolation++;
            _viol("prove by B changed A's entry");
        }
        for (uint256 i; i < 3; i++) {
            (address g, uint64 t) = PORTAL.provenWithdrawals(f.hash, actors[i]);
            if (actors[i] != b && (g != og[i] || t != ot[i])) {
                vIsolation++;
                _viol("prove by B changed C's entry");
            }
            if (actors[i] == b && ok && t != uint64(block.timestamp)) {
                vProveBookkeeping++;
                _viol("prove ok but timestamp not now");
            }
            if (actors[i] == b && !ok && (g != og[i] || t != ot[i])) {
                vProveBookkeeping++;
                _viol("prove reverted but entry changed");
            }
        }
        if (PORTAL.numProofSubmitters(f.hash) != nBefore + (ok ? 1 : 0)) {
            vProveBookkeeping++;
            _viol("numProofSubmitters bookkeeping");
        }
        _cov(ok ? "prove.ok" : "prove.revert");
        _postCall();
    }

    // ------------------------------------------------------------------ finalize
    function finalize(uint256 fi, uint256 callerSeed, uint256 subSeed, uint256 gasSeed) external {
        curFi = fi % fx.length;
        Fixture memory f = fx[fi % fx.length];
        address sub = subSeed % 8 < 5 ? f.proofSubmitter : actors[subSeed % 3];
        address caller = callerSeed % 4 == 3 ? sub : actors[callerSeed % 4];
        uint256 gas_ = gasSeed % 3 == 0 ? bound(gasSeed >> 8, 60_000, 2_500_000) : 6_000_000;

        // independent precondition, computed BEFORE the call
        bool pre;
        {
            (address game, uint64 ts) = PORTAL.provenWithdrawals(f.hash, sub);
            pre = ts != 0 && !PORTAL.finalizedWithdrawals(f.hash)
                && block.timestamp - ts > PORTAL.proofMaturityDelaySeconds() && ASR.isGameClaimValid(game) && !PORTAL.paused();
        }
        bool wasFinalized = PORTAL.finalizedWithdrawals(f.hash);
        bool wasPaused = PORTAL.paused();
        bytes32 mh = keccak256(f.wd.data);
        bool sBefore = f.messenger && L1CDM.successfulMessages(mh);

        // arm the adversary (only matters if the target currently carries the re-enter stub)
        {
            Fixture memory other = fx[(fi + 1) % fx.length];
            brain.arm(
                abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (other.wd, other.proofSubmitter)),
                f.messenger ? f.wd.data : bytes("")
            );
        }

        vm.recordLogs();
        vm.prank(caller, caller);
        (bool ok,) =
            address(PORTAL).call{ gas: gas_ }(abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (f.wd, sub)));
        if (!ok) {
            _cov(pre ? "finalize.revert.preOK(gas)" : "finalize.revert");
            _postCall();
            return;
        }
        _cov("finalize.ok");
        finalizeCount[f.hash]++;
        if (wasFinalized) {
            vDoubleFinalize++;
            _viol("finalized twice");
        }
        if (wasPaused) {
            vPausedSuccess++;
            _viol("finalize succeeded while paused");
        }
        if (!pre) {
            vFinalizeWithoutValidProof++;
            _viol("finalize ok without mature valid proof");
        }
        if (f.messenger) {
            bool s = L1CDM.successfulMessages(mh);
            bool fl = L1CDM.failedMessages(mh);
            if (s) {
                if (sBefore || msgDelivered[mh]) {
                    vDoubleDelivery++;
                    _viol("message delivered twice");
                }
                msgDelivered[mh] = true;
                gDelivered += f.wd.value;
                _cov("finalize.ok.relayed");
            } else if (fl) {
                msgHeld[mh] = true;
                gHeldByMessenger += f.wd.value;
                failedIdx.push(curFi);
                _cov("finalize.ok.failedMsg");
            } else {
                vNeither++;
                _viol("finalized with neither mapping recorded");
            }
        } else {
            bool success;
            Vm.Log[] memory logs = vm.getRecordedLogs();
            for (uint256 k; k < logs.length; k++) {
                if (logs[k].emitter == address(PORTAL) && logs[k].topics[0] == WITHDRAWAL_FINALIZED) {
                    success = abi.decode(logs[k].data, (bool));
                }
            }
            if (success) gDelivered += f.wd.value;
            _cov(success ? "finalize.ok.plainOk" : "finalize.ok.plainFail");
        }
        _postCall();
    }

    // ------------------------------------------------------------------ replay through L1CDM
    /// @dev Replays a message that the campaign previously drove into failedMessages, optionally
    ///      after restoring the original code of its target (HARNESS etch undo).
    function replayFailed(uint256 pick, bool restore, uint256 callerSeed, uint256 gasSeed) external {
        if (failedIdx.length == 0) return;
        uint256 fi = failedIdx[pick % failedIdx.length];
        if (restore) {
            address t = _innerTarget(fx[fi]);
            if (codeSaved[t]) vm.etch(t, originalCode[t]);
        }
        replay(fi, callerSeed, gasSeed | 1); // odd*... keep mostly ample gas
    }

    function replay(uint256 fi, uint256 callerSeed, uint256 gasSeed) public {
        Fixture memory f = fx[fi % fx.length];
        if (!f.messenger) return;
        Inner memory m = decodeInner(f.wd);
        bytes32 mh = keccak256(f.wd.data);
        bool sBefore = L1CDM.successfulMessages(mh);
        bool fBefore = L1CDM.failedMessages(mh);
        bool wasPaused = PORTAL.paused();
        uint256 gas_ = gasSeed % 3 == 0 ? bound(gasSeed >> 8, 60_000, 2_500_000) : 6_000_000;
        brain.arm(bytes(""), f.wd.data);
        address caller = actors[callerSeed % 3];
        vm.prank(caller, caller);
        (bool ok,) = address(L1CDM).call{ gas: gas_ }(
            abi.encodeCall(IMessenger.relayMessage, (m.nonce, m.sender, m.target, m.value, m.minGasLimit, m.message))
        );
        if (ok) {
            if (wasPaused) {
                vPausedSuccess++;
                _viol("replay succeeded while paused");
            }
            if (!fBefore || sBefore) {
                vDoubleDelivery++;
                _viol("replay ok for a message that was not failed / already successful");
            }
            if (L1CDM.successfulMessages(mh) && !sBefore) {
                if (msgDelivered[mh]) {
                    vDoubleDelivery++;
                    _viol("replay delivered twice");
                }
                msgDelivered[mh] = true;
                if (msgHeld[mh]) {
                    msgHeld[mh] = false;
                    gHeldByMessenger -= f.wd.value;
                }
                gDelivered += f.wd.value;
                _cov("replay.ok.relayed");
            } else {
                _cov("replay.ok.stillFailed");
            }
        } else {
            _cov("replay.revert");
        }
        _postCall();
    }

    // ------------------------------------------------------------------ delete proof (v9)
    function deleteProof(uint256 fi, uint256 subSeed, uint256 callerSeed) external {
        Fixture memory f = fx[fi % fx.length];
        address sub = subSeed % 4 == 3 ? f.proofSubmitter : actors[subSeed % 4];
        (address game, uint64 ts) = PORTAL.provenWithdrawals(f.hash, sub);
        bool pre = ts != 0 && (IGame(game).status() == 1 || ASR.isGameBlacklisted(game));
        // other submitters' entries
        address other = sub == f.proofSubmitter ? actors[0] : f.proofSubmitter;
        (address g0, uint64 t0) = PORTAL.provenWithdrawals(f.hash, other);
        address caller = actors[callerSeed % 3];
        vm.prank(caller, caller);
        (bool ok,) = address(PORTAL).call(abi.encodeCall(IPortal.deleteProvenWithdrawal, (f.hash, sub)));
        if (ok != pre) {
            vDeleteMismatch++;
            _viol("deleteProvenWithdrawal outcome != (proven && game permanently invalid)");
        }
        (address g1, uint64 t1) = PORTAL.provenWithdrawals(f.hash, other);
        if (g1 != g0 || t1 != t0) {
            vIsolation++;
            _viol("delete of A's proof changed B's entry");
        }
        if (ok) {
            (, uint64 t2) = PORTAL.provenWithdrawals(f.hash, sub);
            if (t2 != 0) {
                vDeleteMismatch++;
                _viol("delete ok but entry remains");
            }
        }
        _cov(ok ? "delete.ok" : "delete.revert");
        _postCall();
    }

    // ------------------------------------------------------------------ environment
    function warp(uint256 dt) external {
        dt = bound(dt, 1, 4 days);
        vm.warp(block.timestamp + dt);
        vm.roll(block.number + dt / 12 + 1);
        _cov("warp");
    }

    /// @dev HARNESS: adversarial code at the (inner) target of a fixture. kind 0 restores.
    function etchTarget(uint256 fi, uint256 kind) external {
        if (fi % 3 == 0 && plainIdx.length != 0) fi = plainIdx[(fi / 3) % plainIdx.length];
        Fixture memory f = fx[fi % fx.length];
        address t = _innerTarget(f);
        if (t == address(PORTAL) || t == address(LOCKBOX) || t == address(L1CDM) || t == BRAIN) return;
        if (!codeSaved[t]) {
            originalCode[t] = t.code;
            codeSaved[t] = true;
        }
        kind = kind % 5;
        if (kind == 0) vm.etch(t, originalCode[t]);
        else vm.etch(t, stubs[kind - 1].code);
        _cov(kind == 0 ? "etch.restore" : kind == 1 ? "etch.revert" : kind == 2 ? "etch.burn" : kind == 3 ? "etch.bomb" : "etch.reenter");
    }

    /// @dev PRIVILEGED PRANK (production incident path): guardian pauses the lockbox identifier
    ///      or the global identifier; or unpauses.
    function setPause(uint256 mode) external {
        mode = mode % 8;
        address id = mode % 2 == 0 ? address(LOCKBOX) : address(0);
        vm.prank(GUARDIAN);
        if (mode < 2) {
            try SUPERCHAIN_CONFIG.pause(id) {
                _cov("pause.ok");
            } catch {
                _cov("pause.revert");
            }
        } else {
            try SUPERCHAIN_CONFIG.unpause(id) {
                _cov("unpause.ok");
            } catch {
                _cov("unpause.revert");
            }
        }
    }

    /// @dev PRIVILEGED PRANK (production incident path): guardian blacklists a game.
    function blacklist(uint256 fi, uint256 gate) external {
        if (gate % 12 != 0) return; // keep it rare
        Fixture memory f = fx[fi % fx.length];
        vm.prank(GUARDIAN);
        try ASR.blacklistDisputeGame(f.game) {
            _cov("blacklist.ok");
        } catch {
            _cov("blacklist.revert");
        }
    }
}

contract PortalInvariantsTest is U21FixtureBase {
    PortalHandler internal h;
    uint256 internal lockbox0;
    uint256 internal portal0;
    uint256 internal cdm0;

    function setUp() public {
        vm.createSelectFork("l1");
        // Honest preparation: resolve every in-progress fixture game through public functions,
        // then warp past all maturity / finality air-gaps.
        uint256 n = _fixtureCount();
        uint256 t = block.timestamp;
        for (uint256 i; i < n; i++) {
            Fixture memory f = _loadFixture(i);
            if (_resolveGameHonestly(f.game) != 2) continue;
            uint256 t1 = uint256(f.proofTimestamp) + PORTAL.proofMaturityDelaySeconds() + 1;
            uint256 t2 = uint256(IGame(f.game).resolvedAt()) + PORTAL.disputeGameFinalityDelaySeconds() + 1;
            if (t1 > t) t = t1;
            if (t2 > t) t = t2;
        }
        vm.warp(t);
        h = new PortalHandler();
        lockbox0 = address(LOCKBOX).balance;
        portal0 = address(PORTAL).balance;
        cdm0 = address(L1CDM).balance;
        require(portal0 == 0, "portal starts empty");

        bytes4[] memory sel = new bytes4[](14);
        sel[12] = h.replayFailed.selector;
        sel[13] = h.etchTarget.selector; // weight
        sel[0] = h.deposit.selector;
        sel[1] = h.depositViaMessenger.selector;
        sel[2] = h.donate.selector;
        sel[3] = h.prove.selector;
        sel[4] = h.finalize.selector;
        sel[5] = h.finalize.selector; // weight
        sel[6] = h.replay.selector;
        sel[7] = h.deleteProof.selector;
        sel[8] = h.warp.selector;
        sel[9] = h.etchTarget.selector;
        sel[10] = h.setPause.selector;
        sel[11] = h.blacklist.selector;
        targetSelector(FuzzSelector({ addr: address(h), selectors: sel }));
        targetContract(address(h));
    }

    /// ETH conservation, per contract and in total.
    function _ethConservation() internal view {
        Brain b = h.brain();
        uint256 deposits = h.gDeposits() + b.deposited();
        uint256 donations = h.gDonations() + b.donated();
        assertEq(address(PORTAL).balance, portal0 + donations, "portal balance == donations only");
        assertEq(address(L1CDM).balance, cdm0 + h.gHeldByMessenger(), "messenger holds exactly failed-message value");
        assertEq(
            address(LOCKBOX).balance + h.gDelivered() + h.gHeldByMessenger(),
            lockbox0 + deposits,
            "lockbox == initial + deposits - delivered - heldByMessenger"
        );
    }

    function _noViolations() internal view {
        assertEq(h.vDoubleFinalize(), 0, h.firstViolation());
        assertEq(h.vDoubleDelivery(), 0, h.firstViolation());
        assertEq(h.vNeither(), 0, h.firstViolation());
        assertEq(h.vPausedSuccess(), 0, h.firstViolation());
        assertEq(h.vIsolation(), 0, h.firstViolation());
        assertEq(h.vFinalizeWithoutValidProof(), 0, h.firstViolation());
        assertEq(h.vDeleteMismatch(), 0, h.firstViolation());
        assertEq(h.vPortalBalanceDrift(), 0, h.firstViolation());
        assertEq(h.vProveBookkeeping(), 0, h.firstViolation());
        assertEq(h.brain().forbiddenMask(), 0, "a forbidden re-entrant call succeeded");
    }

    function _uniquenessAndReplayability() internal view {
        uint256 n = h.fixtureCount();
        for (uint256 i; i < n; i++) {
            bytes32 hash_ = h.fixtureHash(i);
            assertLe(h.finalizeCount(hash_), 1, "hash finalized more than once");
            if (PORTAL.finalizedWithdrawals(hash_) && h.fixtureIsMessenger(i)) {
                bytes32 mh = h.fixtureMsgHash(i);
                assertTrue(
                    L1CDM.successfulMessages(mh) || L1CDM.failedMessages(mh), "finalized => delivered or replayable"
                );
            }
        }
        assertEq(PORTAL.l2Sender(), DEFAULT_L2_SENDER, "l2Sender reset");
    }

    /// @notice Single campaign checking every invariant group after every handler call.
    function invariant_all() public view {
        _ethConservation();
        _noViolations();
        _uniquenessAndReplayability();
    }

    /// @dev Appends this run's handler coverage to evidence/invariant-coverage.txt.
    function afterInvariant() public {
        uint256 n = h.covCount();
        string memory s = "";
        for (uint256 i; i < n; i++) {
            bytes32 k = h.covKeys(i);
            uint256 len;
            while (len < 32 && k[len] != 0) len++;
            bytes memory name = new bytes(len);
            for (uint256 j; j < len; j++) name[j] = k[j];
            s = string.concat(s, string(name), "=", vm.toString(h.cov(k)), " ");
        }
        vm.writeLine("evidence/invariant-coverage.txt", s);
    }
}
