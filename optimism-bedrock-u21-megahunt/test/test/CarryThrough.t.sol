// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../src/InFlightObjects.sol";

/// F6 piece 4 — carry REAL in-flight objects through every official upgrade replay up to U21.
///
///  (a) withdrawal: the real prove calldata of an era fixture is sent from a FRESH submitter at the
///      real prove block (a proof object provenWithdrawals[hash][fresh] that never existed on
///      mainnet). Only the portal is persistent. The fork is then carried with `_carry`
///      (vm.rollFork to block-1 of every later fork point + replay of the real upgrade tx).
///      At every stage: pointers == table, proof still stored, checkWithdrawal, and a finalize
///      attempt inside a snapshot. Final stage: finalize under v9 for real (as-is, then after
///      permissionless game resolution + warp if needed).
///  (b) failed messenger message: the real tx that produced FailedRelayedMessage is replayed at its
///      block; only the messenger is persistent; carried the same way; at every stage a
///      permissionless relayMessage replay is attempted inside a snapshot; final replay under v9.
///  (c) differential runner: one permissionless call executed on two forks, diffing outcome
///      (success / revert selector), events and balance deltas, with a five-call table.
///
/// Every stage table goes to ../evidence/F6-carry-*.md and ../evidence/F6-differential.md.
/// Staleness of carried slots (slots of the persistent holder that real non-upgrade traffic
/// changed while the carry kept the local value) is MEASURED at the end of (a) and (b) against the
/// real end of the U21 block and written to the same file.
contract CarryThroughTest is InFlightObjects {
    address constant FRESH = address(uint160(0xF6F6F6C0FFEE));
    address constant ALICE = address(uint160(0xA11CE0F6F6));
    bytes32 constant TOPIC_WD_FINALIZED = 0xdb5c7652857aa163daadd670e116628fb42e869d8ac4251ef8971d9e5727df1b;
    uint256 constant FINALIZE_GAS = 15_000_000;
    uint256 constant RELAY_GAS = 10_000_000;

    // ==========================================================================================
    // helpers shared by (a) and (b)
    // ==========================================================================================

    /// @dev distinct slots in `a` and `b`
    function _uniq(bytes32[] memory a, bytes32[] memory b) internal pure returns (bytes32[] memory u) {
        u = new bytes32[](a.length + b.length);
        uint256 n;
        for (uint256 k; k < a.length + b.length; k++) {
            bytes32 s = k < a.length ? a[k] : b[k - a.length];
            bool seen;
            for (uint256 q; q < n; q++) {
                if (u[q] == s) {
                    seen = true;
                    break;
                }
            }
            if (!seen) u[n++] = s;
        }
        assembly {
            mstore(u, n)
        }
    }

    function _contains(bytes32[] memory a, bytes32 s) internal pure returns (bool) {
        for (uint256 k; k < a.length; k++) {
            if (a[k] == s) return true;
        }
        return false;
    }

    /// @dev Compares carried values `vals` of `slots` of `holder` with the real chain at `realBlock`,
    ///      skipping `objectSlots`. Must be called last (revokes persistence, re-pins the fork).
    function _staleReport(address holder, bytes32[] memory slots, bytes32[] memory vals, bytes32[] memory objectSlots, uint256 realBlock)
        internal
        returns (uint256 stale, uint256 objectDiff, string memory detail)
    {
        vm.revokePersistent(holder);
        _rollTo(realBlock);
        for (uint256 k; k < slots.length; k++) {
            bytes32 real = vm.load(holder, slots[k]);
            if (real == vals[k]) continue;
            if (_contains(objectSlots, slots[k])) {
                objectDiff++;
                continue;
            }
            stale++;
            detail = string.concat(detail, "- slot ", vm.toString(slots[k]), ": carried ", vm.toString(vals[k]), ", real ", vm.toString(real), "\n");
        }
    }

    function _assertPointersAt(uint256 k) internal {
        assertEq(_implMismatches(k, true), 0, string.concat("carried fork pointers == real post-block pointers at ", HFData.label(k)));
    }

    // ==========================================================================================
    // (a) withdrawal carry
    // ==========================================================================================

    function _gameCell(address game) internal view returns (string memory s) {
        if (game == address(0) || game.code.length == 0) return "no game code";
        s = string.concat("status ", vm.toString(uint256(IGame(game).status())));
        (bool ok, bytes memory ret) = OP_PORTAL.staticcall(abi.encodeWithSignature("anchorStateRegistry()"));
        if (ok && ret.length == 32) {
            address asr = abi.decode(ret, (address));
            (bool ok2, bytes memory r2) = asr.staticcall(abi.encodeCall(IASR.isGameClaimValid, (game)));
            if (ok2 && r2.length == 32) s = string.concat(s, abi.decode(r2, (bool)) ? ", claimValid" : ", NOT claimValid");
        }
    }

    function _checkCell(bytes32 hash) internal view returns (string memory) {
        (bool ok, bytes memory ret) = OP_PORTAL.staticcall(abi.encodeCall(IPortal.checkWithdrawal, (hash, FRESH)));
        return _outcome(ok, ret);
    }

    /// @dev finalize as FRESH with a 15M gas cap; returns call outcome and the WithdrawalFinalized `success` flag.
    function _finalizeFresh(WithdrawalTransaction memory wd) internal returns (bool ok, bytes memory ret, bool success, bool emitted) {
        vm.recordLogs();
        vm.prank(FRESH, FRESH);
        (ok, ret) = OP_PORTAL.call{ gas: FINALIZE_GAS }(abi.encodeCall(IPortal.finalizeWithdrawalTransaction, (wd)));
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 k; k < logs.length; k++) {
            if (logs[k].emitter == OP_PORTAL && logs[k].topics[0] == TOPIC_WD_FINALIZED) {
                emitted = true;
                success = abi.decode(logs[k].data, (bool));
            }
        }
    }

    function _wdStageRow(string memory stage, EraProve memory p) internal returns (string memory row, bool present) {
        (bool exists, address game, uint64 ts) = _proofOf(p.hash, FRESH);
        present = exists;
        row = string.concat("| ", stage, " | ", vm.toString(block.number), " | ", _version(OP_PORTAL), " | ");
        row = string.concat(row, exists ? string.concat("yes (ts ", vm.toString(uint256(ts)), ")") : "NO", " | ", _gameCell(game), " | ");
        row = string.concat(row, _checkCell(p.hash), " | ");
        uint256 snap = vm.snapshotState();
        (bool ok, bytes memory ret, bool success, bool emitted) = _finalizeFresh(p.wd);
        vm.revertToStateAndDelete(snap);
        assertFalse(_isFinalized(p.hash), "snapshot revert restored the carried state");
        (bool still,,) = _proofOf(p.hash, FRESH);
        assertEq(still, exists, "snapshot revert kept the carried proof");
        row = string.concat(row, _outcome(ok, ret), emitted ? (success ? " (success=true)" : " (success=false)") : "", " |\n");
    }

    function _finalWd(EraProve memory p) internal returns (string memory) {
        string memory out = string.concat("\n## Final finalization under v9 (", _version(OP_PORTAL), ")\n\n");
        uint256 lb0 = OP_LOCKBOX.balance;
        (bool fok, bytes memory fret, bool fsuccess, bool femitted) = _finalizeFresh(p.wd);
        out = string.concat(out, "- as-is at the U21 block (ts ", vm.toString(block.timestamp), "): ", _outcome(fok, fret));
        out = string.concat(out, femitted ? (fsuccess ? ", WithdrawalFinalized success=true\n" : ", WithdrawalFinalized success=false\n") : "\n");
        if (!fok) {
            (bool exists, address game,) = _proofOf(p.hash, FRESH);
            assertTrue(exists, "proof present before maturation");
            uint8 st = _matureProof(p.hash, FRESH);
            out = string.concat(out, "- after permissionless resolution/warp (game ", vm.toString(game), " status ", vm.toString(uint256(st)));
            (fok, fret, fsuccess, femitted) = _finalizeFresh(p.wd);
            out = string.concat(out, ", ts ", vm.toString(block.timestamp), "): ", _outcome(fok, fret));
            out = string.concat(out, femitted ? (fsuccess ? ", WithdrawalFinalized success=true\n" : ", WithdrawalFinalized success=false\n") : "\n");
        }
        out = string.concat(
            out, "- finalizedWithdrawals(hash) = ", _isFinalized(p.hash) ? "true" : "false", "; lockbox delta = -",
            vm.toString(lb0 - OP_LOCKBOX.balance), " wei (withdrawal value ", vm.toString(p.wd.value), ")\n"
        );
        if (fok && fsuccess) assertEq(lb0 - OP_LOCKBOX.balance, p.wd.value, "lockbox paid exactly the value");
        if (p.messenger && fok) {
            (bool succ, bool failed) = _msgStatus(keccak256(p.wd.data)); // L2CDM withdrawal data = relayMessage calldata (v1 hash)
            out = string.concat(out, "- messenger: successfulMessages=", succ ? "true" : "false", ", failedMessages=", failed ? "true" : "false", "\n");
        }
        return out;
    }

    function _wdHeader(string memory era, uint256 fixtureIndex, EraProve memory p) internal pure returns (string memory out) {
        out = string.concat(
            "# F6 carry-through: withdrawal ", vm.toString(p.hash), "\n\nfixture ", era, "/p", vm.toString(fixtureIndex),
            ".json; value ", vm.toString(p.wd.value), " wei; L2 sender ", vm.toString(p.wd.sender), "; real prove tx ",
            vm.toString(p.proveTx), " at block ", vm.toString(p.proveBlock), ".\n"
        );
        out = string.concat(
            out, "The same prove calldata is sent from fresh submitter ", vm.toString(FRESH),
            " (an object that never existed on mainnet). Persistent account: OptimismPortal only.\n",
            "Finalize attempts in the table run inside a snapshot (reverted).\n\n",
            "| stage | block | portal | proof (fresh submitter) | game | checkWithdrawal | finalize attempt |\n|---|---|---|---|---|---|---|\n"
        );
    }

    function _staleSection(address holder, bytes32[] memory touched, bytes32[] memory vals, bytes32[] memory objectSlots)
        internal
        returns (string memory)
    {
        uint256 realBlock = HFData.blockOf(HFData.U21_V9);
        (uint256 stale, uint256 objectDiff, string memory detail) = _staleReport(holder, touched, vals, objectSlots, realBlock);
        emit log_named_uint("stale carried slots (excluding object slots)", stale);
        return string.concat(
            "\n## Carried-slot staleness (", vm.toString(holder), " vs real end of block ", vm.toString(realBlock),
            "; values memorised BEFORE the final action)\n\n", vm.toString(touched.length), " distinct slots touched during the carry; ",
            vm.toString(objectDiff), " differ and were written when the local object was created; ", vm.toString(stale),
            " other slots differ (stale or changed by later mainnet traffic):\n", detail
        );
    }

    function _carryWithdrawal(string memory era, uint256 fixtureIndex) internal {
        uint256 eraPoint = _point(era);
        EraProve memory p = _loadEraProve(era, fixtureIndex);
        require(p.direct && p.faultProofModel, "pick a direct, fault-proof-era fixture");
        string memory out = _wdHeader(era, fixtureIndex, p);

        // ---- create the object ----
        _forkAt(p.proveBlock - 1);
        vm.makePersistent(OP_PORTAL);
        vm.roll(p.proveBlock);
        vm.warp(p.proveTimestamp);
        vm.record();
        (bool ok, bytes memory ret) = _proveAs(p, FRESH);
        assertTrue(ok, string.concat("fresh-submitter prove failed: ", _outcome(ok, ret)));
        (, bytes32[] memory objectSlots) = vm.accesses(OP_PORTAL);
        objectSlots = _uniq(objectSlots, new bytes32[](0));
        vm.record(); // reset: from here on collect every slot the carry touches
        (string memory row, bool present) = _wdStageRow(string.concat("proven (", era, ")"), p);
        out = string.concat(out, row);
        assertTrue(present, "proof stored");

        // ---- carry through every later official upgrade ----
        for (uint256 k = eraPoint + 1; k < HFData.POINTS; k++) {
            _carry(k - 1, k, ReplayMode.Prank);
            _assertPointersAt(k);
            (row, present) = _wdStageRow(string.concat("after ", HFData.label(k), " replay"), p);
            out = string.concat(out, row);
            assertTrue(present, string.concat("proof survived ", HFData.label(k)));
        }

        // ---- memorise touched slots before the final, real finalization ----
        (bytes32[] memory r, bytes32[] memory w) = vm.accesses(OP_PORTAL);
        bytes32[] memory touched = _uniq(r, w);
        bytes32[] memory vals = _readSlots(OP_PORTAL, touched);

        // ---- final: finalize under v9 for real ----
        out = string.concat(out, _finalWd(p));

        // ---- staleness of the carried portal slots ----
        out = string.concat(out, _staleSection(OP_PORTAL, touched, vals, objectSlots));
        vm.writeFile(string.concat("../evidence/F6-carry-withdrawal-", era, ".md"), out);
        emit log_string(out);
    }

    /// v4.1 (U16a) proof carried through U17, U18, U19, U20, U21 (5 replays) and finalized under v9.
    function test_carry_withdrawal_from_U16A_V4_1() public {
        _carryWithdrawal("U16A_V4_1", 1);
    }

    /// v5 (U17) proof carried through U18, U19, U20, U21 (4 replays) and finalized under v9.
    function test_carry_withdrawal_from_U17_V5() public {
        _carryWithdrawal("U17_V5", 1);
    }

    /// v3 (U14) proof carried through U16 (new ASR + ETHLockbox), U16a, U17 .. U21 (7 replays).
    function test_carry_withdrawal_from_U14_V3() public {
        _carryWithdrawal("U14_V3", 0);
    }

    // ==========================================================================================
    // (b) failed messenger message carry
    // ==========================================================================================

    function _relayAlice(EraFailedMsg memory m) internal returns (bool ok, bytes memory ret, bool relayed, bool failedEv) {
        vm.recordLogs();
        (ok, ret) = _replayFailed(m, ALICE, RELAY_GAS);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 k; k < logs.length; k++) {
            if (logs[k].emitter != OP_L1CDM) continue;
            if (logs[k].topics[0] == TOPIC_RELAYED) relayed = true;
            if (logs[k].topics[0] == TOPIC_FAILED_RELAYED) failedEv = true;
        }
    }

    function _msgStageRow(string memory stage, EraFailedMsg memory m) internal returns (string memory row, bool stillFailed) {
        (bool succ, bool failed) = _msgStatus(m.msgHash);
        stillFailed = failed && !succ;
        row = string.concat("| ", stage, " | ", vm.toString(block.number), " | ", _version(OP_L1CDM), " | ");
        row = string.concat(row, failed ? "true" : "false", " | ", succ ? "true" : "false", " | ");
        uint256 snap = vm.snapshotState();
        (bool ok, bytes memory ret, bool relayed, bool failedEv) = _relayAlice(m);
        vm.revertToStateAndDelete(snap);
        (bool succ2, bool failed2) = _msgStatus(m.msgHash);
        assertEq(succ2, succ, "snapshot revert restored successfulMessages");
        assertEq(failed2, failed, "snapshot revert restored failedMessages");
        row = string.concat(row, _outcome(ok, ret), relayed ? " RelayedMessage" : "", failedEv ? " FailedRelayedMessage" : "", " |\n");
    }

    function _finalFailed(EraFailedMsg memory m) internal returns (string memory) {
        address tgt = _relayTarget(m.relayCalldata);
        uint256 tb = tgt.balance;
        (bool ok, bytes memory ret, bool relayed, bool failedEv) = _relayAlice(m);
        (bool succ, bool failed) = _msgStatus(m.msgHash);
        string memory out = string.concat(
            "\n## Final permissionless replay under v9 (L1CDM ", _version(OP_L1CDM), ")\n\n- outcome: ", _outcome(ok, ret),
            relayed ? ", RelayedMessage" : "", failedEv ? ", FailedRelayedMessage" : ""
        );
        out = string.concat(
            out, "\n- after: successfulMessages=", succ ? "true" : "false", ", failedMessages=", failed ? "true" : "false",
            "; target ", vm.toString(tgt), " balance delta ", vm.toString(tgt.balance - tb), "\n"
        );
        return out;
    }

    function _carryFailed(string memory era, uint256 fixtureIndex) internal {
        uint256 eraPoint = _point(era);
        EraFailedMsg memory m = _loadEraFailed(era, fixtureIndex);
        require(m.hashIsV1, "version-1 message expected");
        string memory out = string.concat(
            "# F6 carry-through: failed messenger message ", vm.toString(m.msgHash), "\n\nfixture ", era, "/m", vm.toString(fixtureIndex),
            ".json; produced by real tx ", vm.toString(m.txHash), " (", m.producedByPortalFinalize ? "portal finalize" : "messenger replay",
            ") at block ", vm.toString(m.blockNumber), ".\n"
        );
        out = string.concat(
            out, "Persistent account: L1CrossDomainMessenger proxy only. Replay attempts by a fresh EOA (", vm.toString(ALICE),
            ", ", vm.toString(RELAY_GAS), " gas, no value) run inside a snapshot (reverted).\n\n",
            "| stage | block | L1CDM | failedMessages | successfulMessages | permissionless replay attempt |\n|---|---|---|---|---|---|\n"
        );
        _forkAt(m.blockNumber - 1);
        vm.makePersistent(OP_L1CDM);
        vm.record();
        (bool txOk, bool failedRecorded) = _produceFailedReal(m);
        assertTrue(txOk && failedRecorded, "real tx reproduces failedMessages[hash]");
        (, bytes32[] memory objectSlots) = vm.accesses(OP_L1CDM);
        objectSlots = _uniq(objectSlots, new bytes32[](0));
        vm.record();
        (string memory row, bool stillFailed) = _msgStageRow(string.concat("failed (", era, ")"), m);
        out = string.concat(out, row);
        assertTrue(stillFailed, "object created");
        for (uint256 k = eraPoint + 1; k < HFData.POINTS; k++) {
            _carry(k - 1, k, ReplayMode.Prank);
            _assertPointersAt(k);
            (row, stillFailed) = _msgStageRow(string.concat("after ", HFData.label(k), " replay"), m);
            out = string.concat(out, row);
            assertTrue(stillFailed, string.concat("failed message survived ", HFData.label(k)));
        }
        (bytes32[] memory r, bytes32[] memory w) = vm.accesses(OP_L1CDM);
        bytes32[] memory touched = _uniq(r, w);
        bytes32[] memory vals = _readSlots(OP_L1CDM, touched);

        // ---- final: replay under v9 for real ----
        out = string.concat(out, _finalFailed(m));
        out = string.concat(out, _staleSection(OP_L1CDM, touched, vals, objectSlots));
        vm.writeFile(string.concat("../evidence/F6-carry-failed-", era, ".md"), out);
        emit log_string(out);
    }

    function _relayTarget(bytes memory cd) internal pure returns (address t) {
        // relayMessage(uint256 nonce, address sender, address target, ...): target is the third word
        assembly {
            t := mload(add(cd, 100))
        }
    }

    /// failed under v6 (U18 era, target L1StandardBridge), carried through U19, U20, U21.
    function test_carry_failed_message_from_U18_V6() public {
        _carryFailed("U18_V6", 0);
    }

    /// failed under v3 (U14 era, target L1StandardBridge), carried through U16 .. U21 (7 replays).
    function test_carry_failed_message_from_U14_V3() public {
        _carryFailed("U14_V3", 3);
    }

    // ==========================================================================================
    // (c) differential runner
    // ==========================================================================================

    struct DiffCall {
        string name;
        address from;
        address to;
        uint256 value;
        uint256 gas;
        bytes data;
    }

    struct DiffSide {
        bool ok;
        string outcome;
        uint256 nLogs;
        bytes32 topicDigest; // emitters + topic0 sequence
        bytes32 fullDigest; // emitters + all topics + data
        int256[] deltas;
        bytes32[] logHashes; // per log: keccak(emitter, topics, data)
        bytes32[] logTopic0;
        address[] logEmitter;
    }

    function _watch() internal pure returns (address[] memory w) {
        w = new address[](5);
        w[0] = OP_PORTAL;
        w[1] = OP_LOCKBOX;
        w[2] = OP_L1CDM;
        w[3] = OP_L1_BRIDGE;
        w[4] = address(0); // replaced by the caller
    }

    /// @notice Runs `c` on fork `forkId` inside a snapshot (state is unchanged afterwards).
    function _runOn(uint256 forkId, DiffCall memory c) internal returns (DiffSide memory s) {
        vm.selectFork(forkId);
        uint256 snap = vm.snapshotState();
        address[] memory w = _watch();
        w[4] = c.from;
        vm.deal(c.from, c.from.balance + c.value);
        uint256[] memory b0 = new uint256[](w.length);
        for (uint256 k; k < w.length; k++) b0[k] = w[k].balance;
        vm.recordLogs();
        vm.prank(c.from, c.from);
        bytes memory ret;
        (s.ok, ret) = c.to.call{ value: c.value, gas: c.gas }(c.data);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        s.outcome = _outcome(s.ok, ret);
        s.nLogs = logs.length;
        s.logHashes = new bytes32[](logs.length);
        s.logTopic0 = new bytes32[](logs.length);
        s.logEmitter = new address[](logs.length);
        for (uint256 k; k < logs.length; k++) {
            s.logHashes[k] = keccak256(abi.encode(logs[k].emitter, logs[k].topics, logs[k].data));
            s.logTopic0[k] = logs[k].topics.length > 0 ? logs[k].topics[0] : bytes32(0);
            s.logEmitter[k] = logs[k].emitter;
            s.topicDigest = keccak256(abi.encode(s.topicDigest, logs[k].emitter, logs[k].topics.length > 0 ? logs[k].topics[0] : bytes32(0)));
            s.fullDigest = keccak256(abi.encode(s.fullDigest, logs[k].emitter, logs[k].topics, logs[k].data));
        }
        s.deltas = new int256[](w.length);
        for (uint256 k; k < w.length; k++) s.deltas[k] = int256(w[k].balance) - int256(b0[k]);
        vm.revertToStateAndDelete(snap);
    }

    function _deltaStr(int256[] memory d) internal pure returns (string memory s) {
        for (uint256 k; k < d.length; k++) s = string.concat(s, k == 0 ? "" : "/", vm.toString(d[k]));
    }

    function _sameDeltas(int256[] memory a, int256[] memory b) internal pure returns (bool) {
        for (uint256 k; k < a.length; k++) {
            if (a[k] != b[k]) return false;
        }
        return true;
    }

    /// @notice Differential row for one call on forks A and B.
    function _diffRow(uint256 fa, uint256 fb, DiffCall memory c) internal returns (string memory row, bool identical) {
        DiffSide memory a = _runOn(fa, c);
        DiffSide memory b = _runOn(fb, c);
        bool sameOutcome = keccak256(bytes(a.outcome)) == keccak256(bytes(b.outcome));
        bool sameEv = a.nLogs == b.nLogs && a.topicDigest == b.topicDigest;
        bool sameFull = a.fullDigest == b.fullDigest;
        bool sameBal = _sameDeltas(a.deltas, b.deltas);
        identical = sameOutcome && sameFull && sameBal;
        row = string.concat("| ", c.name, " | ", a.outcome, " | ", b.outcome, " | ", sameOutcome ? "same" : "DIFF", " | ");
        row = string.concat(row, vm.toString(a.nLogs), " / ", vm.toString(b.nLogs), " ", sameEv ? "same" : "DIFF", sameFull ? " (bytes same)" : _firstLogDiff(a, b), " | ");
        row = string.concat(row, _deltaStr(a.deltas), " | ", _deltaStr(b.deltas), " | ", sameBal ? "same" : "DIFF", " |\n");
    }

    /// @dev " (bytes differ at log i: emitter, topic0)"
    function _firstLogDiff(DiffSide memory a, DiffSide memory b) internal pure returns (string memory) {
        uint256 n = a.nLogs < b.nLogs ? a.nLogs : b.nLogs;
        for (uint256 k; k < n; k++) {
            if (a.logHashes[k] != b.logHashes[k]) {
                return string.concat(
                    " (bytes differ from log ", vm.toString(k), ": ", vm.toString(a.logEmitter[k]), " topic0 ", vm.toString(a.logTopic0[k]), ")"
                );
            }
        }
        return " (bytes differ: extra logs)";
    }

    function _diffCalls() internal view returns (DiffCall[] memory c) {
        c = new DiffCall[](5);
        c[0] = DiffCall(
            "portal.depositTransaction 1 ETH", ALICE, OP_PORTAL, 1 ether, 1_000_000,
            abi.encodeCall(IPortal.depositTransaction, (address(0xB0B), 1 ether, 100_000, false, hex""))
        );
        c[1] = DiffCall("L1StandardBridge.depositETH 1 ETH", ALICE, OP_L1_BRIDGE, 1 ether, 1_000_000, abi.encodeCall(IBridge.depositETH, (200_000, hex"")));
        c[2] = DiffCall(
            "L1CDM.sendMessage 0.5 ETH", ALICE, OP_L1CDM, 0.5 ether, 1_000_000,
            abi.encodeCall(IMessenger.sendMessage, (address(0xB0B), hex"c0ffee", 100_000))
        );
        EraFailedMsg memory m = _loadEraFailed("U20_V8", 0);
        c[3] = DiffCall("L1CDM.relayMessage (U20_V8/m0, failed on mainnet)", ALICE, OP_L1CDM, 0, RELAY_GAS, m.relayCalldata);
        EraProve memory p = _loadEraProve("U20_V8", 3);
        c[4] = DiffCall(
            "portal.finalizeWithdrawalTransaction (U20_V8/p3, 2000 ETH, by its prover)", p.proofSubmitter, OP_PORTAL, 0, FINALIZE_GAS,
            abi.encodeCall(IPortal.finalizeWithdrawalTransaction, (p.wd))
        );
    }

    /// Default pair: end of 26430858 (v8, the block before U21) vs end of 26430859 (v9, U21 block).
    /// Override with F6_DIFF_A / F6_DIFF_B (L1 block numbers).
    function test_differential_five_calls() public {
        uint256 ba = vm.envOr("F6_DIFF_A", uint256(26430858));
        uint256 bb = vm.envOr("F6_DIFF_B", uint256(26430859));
        uint256 fa = vm.createFork(L1_ARCHIVE, ba);
        uint256 fb = vm.createFork(L1_ARCHIVE, bb);
        DiffCall[] memory c = _diffCalls();
        string memory out = string.concat(
            "# F6 differential runner\n\nFork A = end of L1 block ", vm.toString(ba), ", fork B = end of L1 block ", vm.toString(bb),
            ". Each call runs once per fork inside a snapshot (no state carried between calls).\n",
            "Balance deltas (wei) are portal / ETHLockbox / L1CDM / L1StandardBridge / caller.\n\n"
        );
        out = string.concat(
            out, "| call | A outcome | B outcome | outcome | logs A / B | deltas A | deltas B | balances |\n|---|---|---|---|---|---|---|---|\n"
        );
        uint256 identical;
        for (uint256 k; k < c.length; k++) {
            (string memory row, bool same) = _diffRow(fa, fb, c[k]);
            if (same) identical++;
            out = string.concat(out, row);
        }
        out = string.concat(out, "\n", vm.toString(identical), " of ", vm.toString(c.length), " calls are byte-identical on both forks.\n");
        vm.writeFile(string.concat("../evidence/F6-differential-", vm.toString(ba), "-", vm.toString(bb), ".md"), out);
        emit log_string(out);
        // self-check of the runner: the same fork against itself must be identical for every call
        (, bool selfSame) = _diffRow(fa, fa, c[0]);
        assertTrue(selfSame, "runner is deterministic (A vs A)");
    }
}
