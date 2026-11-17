// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./U21Fixtures.sol";

/// @notice Differential suite: the SAME fixture + the SAME action on `l1pre` (v8 code, block
///         before the U21 tx) and `l1` (v9 code). Each test appends `key=value` lines to
///         evidence/diff-<fork>.txt; `data/diff.py` (see README) diffs the two files.
///           U21_FORK=l1pre forge test --match-path test/Differential.t.sol
///           U21_FORK=l1    forge test --match-path test/Differential.t.sol
contract DifferentialTest is U21FixtureBase {
    string internal fork;
    string internal out;
    bytes32 constant WITHDRAWAL_FINALIZED = keccak256("WithdrawalFinalized(bytes32,bool)");

    function setUp() public {
        fork = vm.envOr("U21_FORK", string("l1"));
        vm.createSelectFork(fork);
    }

    /// @dev Lines go straight to disk: file I/O survives vm.revertToState, contract storage does not.
    function _begin(string memory name) internal {
        out = string.concat("evidence/diff-", fork, "-", name, ".txt");
        vm.writeFile(out, "");
    }

    function _put(string memory k, string memory v) internal {
        vm.writeLine(out, string.concat(k, " := ", v));
    }

    function _res(bool ok, bytes memory ret) internal pure returns (string memory) {
        if (ok) return string.concat("ok:", vm.toString(keccak256(ret)));
        if (ret.length >= 4 && bytes4(ret) == 0x08c379a0) {
            bytes memory body = new bytes(ret.length - 4);
            for (uint256 i = 4; i < ret.length; i++) body[i - 4] = ret[i];
            return string.concat("revert:Error(", abi.decode(body, (string)), ")");
        }
        return string.concat("revert:", ret.length >= 4 ? vm.toString(bytes4(ret)) : "0x(empty)");
    }

    function _view(address a, string memory name, bytes memory cd) internal {
        (bool ok, bytes memory ret) = a.staticcall(cd);
        string memory v = ok ? (ret.length <= 96 ? vm.toString(ret) : vm.toString(keccak256(ret))) : _res(ok, ret);
        _put(name, v);
    }

    // ------------------------------------------------------------------------------------ D1
    function test_D1_view_getters() public {
        _begin("D1-getters");
        address p = address(PORTAL);
        _view(p, "portal.version", abi.encodeWithSignature("version()"));
        _view(p, "portal.paused", abi.encodeWithSignature("paused()"));
        _view(p, "portal.guardian", abi.encodeWithSignature("guardian()"));
        _view(p, "portal.superchainConfig", abi.encodeWithSignature("superchainConfig()"));
        _view(p, "portal.systemConfig", abi.encodeWithSignature("systemConfig()"));
        _view(p, "portal.ethLockbox", abi.encodeWithSignature("ethLockbox()"));
        _view(p, "portal.anchorStateRegistry", abi.encodeWithSignature("anchorStateRegistry()"));
        _view(p, "portal.disputeGameFactory", abi.encodeWithSignature("disputeGameFactory()"));
        _view(p, "portal.respectedGameType", abi.encodeWithSignature("respectedGameType()"));
        _view(p, "portal.respectedGameTypeUpdatedAt", abi.encodeWithSignature("respectedGameTypeUpdatedAt()"));
        _view(p, "portal.disputeGameFinalityDelaySeconds", abi.encodeWithSignature("disputeGameFinalityDelaySeconds()"));
        _view(p, "portal.proofMaturityDelaySeconds", abi.encodeWithSignature("proofMaturityDelaySeconds()"));
        _view(p, "portal.l2Sender", abi.encodeWithSignature("l2Sender()"));
        _view(p, "portal.initVersion", abi.encodeWithSignature("initVersion()"));
        _view(p, "portal.proxyAdmin", abi.encodeWithSignature("proxyAdmin()"));
        _view(p, "portal.proxyAdminOwner", abi.encodeWithSignature("proxyAdminOwner()"));
        _view(p, "portal.superRootsActive", abi.encodeWithSignature("superRootsActive()"));
        _view(p, "portal.minimumGasLimit(0)", abi.encodeWithSignature("minimumGasLimit(uint64)", uint64(0)));
        _view(p, "portal.minimumGasLimit(120000)", abi.encodeWithSignature("minimumGasLimit(uint64)", uint64(120000)));
        _view(p, "portal.minimumGasLimit(2^63)", abi.encodeWithSignature("minimumGasLimit(uint64)", uint64(1) << 63));
        _view(p, "portal.disputeGameBlacklist(anchor)", abi.encodeWithSignature("disputeGameBlacklist(address)", ASR.anchorGame()));
        _view(p, "portal.balance()", abi.encodeWithSignature("balance()"));
        _view(p, "portal.deleteProvenWithdrawal.exists", abi.encodeWithSignature("deleteProvenWithdrawal(bytes32,address)", bytes32(0), address(0)));
        address lb = address(LOCKBOX);
        _view(lb, "lockbox.version", abi.encodeWithSignature("version()"));
        _view(lb, "lockbox.paused", abi.encodeWithSignature("paused()"));
        _view(lb, "lockbox.systemConfig", abi.encodeWithSignature("systemConfig()"));
        _view(lb, "lockbox.superchainConfig", abi.encodeWithSignature("superchainConfig()"));
        _view(lb, "lockbox.guardian", abi.encodeWithSignature("guardian()"));
        _view(lb, "lockbox.authorizedPortals(portal)", abi.encodeWithSignature("authorizedPortals(address)", p));
        _view(lb, "lockbox.initVersion", abi.encodeWithSignature("initVersion()"));
        _view(lb, "lockbox.proxyAdminOwner", abi.encodeWithSignature("proxyAdminOwner()"));
        _put("lockbox.slot0", vm.toString(vm.load(lb, bytes32(uint256(0)))));
        _put("lockbox.slot3", vm.toString(vm.load(lb, bytes32(uint256(3)))));
        address m = address(L1CDM);
        _view(m, "cdm.version", abi.encodeWithSignature("version()"));
        _view(m, "cdm.paused", abi.encodeWithSignature("paused()"));
        _view(m, "cdm.portal", abi.encodeWithSignature("portal()"));
        _view(m, "cdm.PORTAL", abi.encodeWithSignature("PORTAL()"));
        _view(m, "cdm.systemConfig", abi.encodeWithSignature("systemConfig()"));
        _view(m, "cdm.superchainConfig", abi.encodeWithSignature("superchainConfig()"));
        _view(m, "cdm.otherMessenger", abi.encodeWithSignature("otherMessenger()"));
        _view(m, "cdm.RELAY_CONSTANT_OVERHEAD", abi.encodeWithSignature("RELAY_CONSTANT_OVERHEAD()"));
        _view(m, "cdm.RELAY_CALL_OVERHEAD", abi.encodeWithSignature("RELAY_CALL_OVERHEAD()"));
        _view(m, "cdm.RELAY_RESERVED_GAS", abi.encodeWithSignature("RELAY_RESERVED_GAS()"));
        _view(m, "cdm.RELAY_GAS_CHECK_BUFFER", abi.encodeWithSignature("RELAY_GAS_CHECK_BUFFER()"));
        _view(m, "cdm.MIN_GAS_CALLDATA_OVERHEAD", abi.encodeWithSignature("MIN_GAS_CALLDATA_OVERHEAD()"));
        _view(m, "cdm.TX_BASE_GAS", abi.encodeWithSignature("TX_BASE_GAS()"));
        _view(m, "cdm.FLOOR_CALLDATA_OVERHEAD", abi.encodeWithSignature("FLOOR_CALLDATA_OVERHEAD()"));
        _view(m, "cdm.ENCODING_OVERHEAD", abi.encodeWithSignature("ENCODING_OVERHEAD()"));
        _view(m, "cdm.baseGas(0,0)", abi.encodeWithSignature("baseGas(bytes,uint32)", bytes(""), uint32(0)));
        _view(m, "cdm.baseGas(1000,200000)", abi.encodeWithSignature("baseGas(bytes,uint32)", new bytes(1000), uint32(200000)));
        _view(m, "cdm.baseGas(120000,max)", abi.encodeWithSignature("baseGas(bytes,uint32)", new bytes(120000), type(uint32).max));
        _view(m, "cdm.xDomainMessageSender", abi.encodeWithSignature("xDomainMessageSender()"));
        address a = address(ASR);
        _view(a, "asr.version", abi.encodeWithSignature("version()"));
        _view(a, "asr.paused", abi.encodeWithSignature("paused()"));
        _view(a, "asr.respectedGameType", abi.encodeWithSignature("respectedGameType()"));
        _view(a, "asr.retirementTimestamp", abi.encodeWithSignature("retirementTimestamp()"));
        _view(a, "asr.anchorGame", abi.encodeWithSignature("anchorGame()"));
        _view(a, "asr.systemConfig", abi.encodeWithSignature("systemConfig()"));
        _view(a, "asr.disputeGameFactory", abi.encodeWithSignature("disputeGameFactory()"));
        _view(a, "asr.superchainConfig", abi.encodeWithSignature("superchainConfig()"));
        address sc = PORTAL.systemConfig();
        _view(sc, "sysconfig.version", abi.encodeWithSignature("version()"));
        _view(sc, "sysconfig.paused", abi.encodeWithSignature("paused()"));
        _view(sc, "sysconfig.superchainConfig", abi.encodeWithSignature("superchainConfig()"));
        _view(sc, "sysconfig.guardian", abi.encodeWithSignature("guardian()"));
        _view(sc, "sysconfig.optimismPortal", abi.encodeWithSignature("optimismPortal()"));
        _view(sc, "sysconfig.l2ChainId", abi.encodeWithSignature("l2ChainId()"));
        _view(sc, "sysconfig.feature.ETH_LOCKBOX", abi.encodeWithSignature("isFeatureEnabled(bytes32)", bytes32("ETH_LOCKBOX")));
        _view(sc, "sysconfig.feature.INTEROP", abi.encodeWithSignature("isFeatureEnabled(bytes32)", bytes32("INTEROP")));
        _view(sc, "sysconfig.feature.CUSTOM_GAS_TOKEN", abi.encodeWithSignature("isFeatureEnabled(bytes32)", bytes32("CUSTOM_GAS_TOKEN")));
        // per-fixture portal state that must be untouched by the upgrade
        uint256 n = _fixtureCount();
        for (uint256 i; i < n; i++) {
            Fixture memory f = _loadFixture(i);
            if (f.postU21) continue;
            string memory k = string.concat("fx", vm.toString(i));
            (address g, uint64 ts) = PORTAL.provenWithdrawals(f.hash, f.proofSubmitter);
            _put(string.concat(k, ".proven"), string.concat(vm.toString(g), ":", vm.toString(ts)));
            _put(string.concat(k, ".finalized"), PORTAL.finalizedWithdrawals(f.hash) ? "1" : "0");
            _put(string.concat(k, ".numSubmitters"), vm.toString(PORTAL.numProofSubmitters(f.hash)));
            (bool ok, bytes memory ret) =
                address(PORTAL).staticcall(abi.encodeCall(IPortal.checkWithdrawal, (f.hash, f.proofSubmitter)));
            // note: timing-dependent; the two pins are ~10h apart
            _put(string.concat(k, ".checkWithdrawal@pin"), _res(ok, ret));
        }
    }

    // ------------------------------------------------------------------------------------ D2
    function test_D2_reprove() public {
        _begin("D2-reprove");
        uint256 n = _fixtureCount();
        for (uint256 i; i < n; i++) {
            Fixture memory f = _loadFixture(i);
            if (f.postU21) continue;
            uint256 snap = vm.snapshotState();
            _reproveCase(f, string.concat("fx", vm.toString(i), "[", f.class_, "]"));
            vm.revertToStateAndDelete(snap);
        }
    }

    function _reproveCase(Fixture memory f, string memory k) internal {
        (, uint64 ts0) = PORTAL.provenWithdrawals(f.hash, f.proofSubmitter);
        uint256 n0 = PORTAL.numProofSubmitters(f.hash);
        // (a) a brand-new submitter replays the recorded proof
        address b = address(0xB0B);
        vm.recordLogs();
        (bool ok, bytes memory ret) = _reproveAs(f, b);
        _put(string.concat(k, ".reproveByB"), _res(ok, ret));
        _put(string.concat(k, ".reproveByB.logs"), vm.toString(vm.getRecordedLogs().length));
        {
            (address gB, uint64 tsB) = PORTAL.provenWithdrawals(f.hash, b);
            _put(
                string.concat(k, ".B.entry"),
                string.concat(gB == f.game ? "sameGame" : vm.toString(gB), ":", tsB == 0 ? "0" : (tsB == block.timestamp ? "now" : "other"))
            );
            (, uint64 ts1) = PORTAL.provenWithdrawals(f.hash, f.proofSubmitter);
            _put(string.concat(k, ".A.unchanged"), ts1 == ts0 ? "1" : "0");
        }
        _put(string.concat(k, ".numSubmittersDelta"), vm.toString(PORTAL.numProofSubmitters(f.hash) - n0));
        // (b) the original submitter re-proves: timer reset
        (ok, ret) = _reproveAs(f, f.proofSubmitter);
        _put(string.concat(k, ".reproveByA"), _res(ok, ret));
        {
            (, uint64 ts2) = PORTAL.provenWithdrawals(f.hash, f.proofSubmitter);
            _put(string.concat(k, ".A.timerReset"), ts2 == block.timestamp ? "1" : "0");
        }
        // (c) a corrupted proof (one bit flipped in the last trie node) must fail
        bytes memory bad = f.proveCalldata;
        bad[bad.length - 40] = bytes1(uint8(bad[bad.length - 40]) ^ 0x01);
        vm.prank(b, b);
        (ok, ret) = address(PORTAL).call(bad);
        _put(string.concat(k, ".corruptProof"), _res(ok, ret));
    }

    // ------------------------------------------------------------------------------------ D3
    function test_D3_deposits() public {
        _begin("D3-deposits");
        uint24[7] memory sizes = [uint24(0), 1, 1_000, 10_000, 60_000, 120_000, 120_001];
        address eoa = address(0xE0A1);
        vm.deal(eoa, 1000 ether);
        vm.deal(address(this), 1000 ether);
        for (uint256 s; s < sizes.length; s++) {
            for (uint256 x; x < 8; x++) {
                _depositCase(eoa, sizes[s], x & 1, (x >> 1) & 1, (x >> 2) & 1);
            }
        }
        // creation flag and receive()
        {
            vm.prank(eoa, eoa);
            (bool ok, bytes memory ret) = address(PORTAL).call(
                abi.encodeCall(IPortal.depositTransaction, (address(0xD00D), 0, uint64(100_000), true, bytes("")))
            );
            _put("deposit[creation,to!=0]", _res(ok, ret));
            uint256 lb = address(LOCKBOX).balance;
            vm.prank(eoa, eoa);
            (ok, ret) = address(PORTAL).call{ value: 2 ether }("");
            _put("deposit[receive,2eth]", _res(ok, ret));
            _put("deposit[receive,2eth].dLockbox", vm.toString(address(LOCKBOX).balance - lb));
            vm.prank(eoa, eoa);
            (ok, ret) = address(PORTAL).call{ value: 1 ether }(abi.encodeCall(IPortal.donateETH, ()));
            _put("donateETH[1eth]", _res(ok, ret));
            _put("donateETH[1eth].portalBal", vm.toString(address(PORTAL).balance));
            // ProxyAdmin-owner only liquidity migration: unprivileged caller
            vm.prank(eoa, eoa);
            (ok, ret) = address(PORTAL).call(abi.encodeCall(IPortal.migrateLiquidity, ()));
            _put("migrateLiquidity[eoa]", _res(ok, ret));
        }
    }

    function _depositCase(address eoa, uint256 size, uint256 v, uint256 g, uint256 c) internal {
        uint256 snap = vm.snapshotState();
        string memory k = string.concat(
            "deposit[len=", vm.toString(size), ",value=", vm.toString(v), ",gasLimit=min", g == 0 ? "" : "-1",
            c == 0 ? ",eoa]" : ",contract]"
        );
        uint256 lb = address(LOCKBOX).balance;
        vm.recordLogs();
        bytes memory cd = abi.encodeCall(
            IPortal.depositTransaction,
            (address(0xD00D), v * 1 ether, PORTAL.minimumGasLimit(uint64(size)) - uint64(g), false, new bytes(size))
        );
        if (c == 0) vm.prank(eoa, eoa);
        (bool ok, bytes memory ret) = address(PORTAL).call{ value: v * 1 ether }(cd);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        _put(k, _res(ok, ret));
        _put(string.concat(k, ".dLockbox"), vm.toString(address(LOCKBOX).balance - lb));
        _put(string.concat(k, ".portalBal"), vm.toString(address(PORTAL).balance));
        bytes32 lh;
        for (uint256 i; i < logs.length; i++) {
            if (logs[i].emitter == address(PORTAL)) lh = keccak256(abi.encode(lh, logs[i].topics, logs[i].data));
        }
        _put(string.concat(k, ".portalLogsHash"), vm.toString(lh));
        vm.revertToStateAndDelete(snap);
    }

    // ------------------------------------------------------------------------------------ D4
    /// @dev HARNESS (vm.store on the messenger) for (i) and (iii): the messenger call is made to
    ///      revert regardless of gas, modelling the two documented non-gas failure classes.
    function test_D4_finalize_with_failing_messenger() public {
        _begin("D4-failing-messenger");
        // (i) failedMessages[hash] pre-set => assert(!failedMessages) panics in relayMessage
        Fixture memory f = _findFixture("pre_mature_valid", true, true);
        _failingCase("presetFailedFlag", f, keccak256(abi.encode(messageHash(f.wd), uint256(206))));
        // (iii) legacy (version 0) message whose legacy hash is already in successfulMessages
        Inner memory m = decodeInner(f.wd);
        if (m.nonce >> 240 == 0) {
            bytes32 oldHash = keccak256(
                abi.encodeWithSignature("relayMessage(address,address,bytes,uint256)", m.target, m.sender, m.message, m.nonce)
            );
            _failingCase("legacyAlreadyRelayed", f, keccak256(abi.encode(oldHash, uint256(203))));
        } else {
            _put("legacyAlreadyRelayed", "skipped: fixture is not a v0 message");
        }
    }

    function _failingCase(string memory name, Fixture memory f, bytes32 slot) internal {
        uint256 snap = vm.snapshotState();
        PORTAL.checkWithdrawal(f.hash, f.proofSubmitter);
        vm.store(address(L1CDM), slot, bytes32(uint256(1)));
        uint256 lb = address(LOCKBOX).balance;
        vm.recordLogs();
        (bool ok, bytes memory ret) = _finalizeWithGas(f, 10_000_000);
        _put(string.concat(name, ".finalize"), _res(ok, ret));
        _put(string.concat(name, ".finalizedFlag"), PORTAL.finalizedWithdrawals(f.hash) ? "1" : "0");
        _put(string.concat(name, ".dLockbox"), vm.toString(lb - address(LOCKBOX).balance));
        _put(string.concat(name, ".portalBal"), vm.toString(address(PORTAL).balance));
        _put(string.concat(name, ".cdmBal"), vm.toString(address(L1CDM).balance));
        _put(string.concat(name, ".successfulMessages"), L1CDM.successfulMessages(messageHash(f.wd)) ? "1" : "0");
        Vm.Log[] memory logs = vm.getRecordedLogs();
        string memory ev = "none";
        for (uint256 k; k < logs.length; k++) {
            if (logs[k].emitter == address(PORTAL) && logs[k].topics[0] == WITHDRAWAL_FINALIZED) {
                ev = abi.decode(logs[k].data, (bool)) ? "WithdrawalFinalized(success=true)" : "WithdrawalFinalized(success=false)";
            }
        }
        _put(string.concat(name, ".event"), ev);
        // can it be retried / replayed afterwards?
        (ok, ret) = _finalizeWithGas(f, 10_000_000);
        _put(string.concat(name, ".secondFinalize"), _res(ok, ret));
        vm.revertToStateAndDelete(snap);
    }

    // ------------------------------------------------------------------------------------ D5
    /// @dev PRIVILEGED PRANK (production incident path): guardian pauses an identifier.
    function test_D5_pause_consistency() public {
        _begin("D5-pause");
        Fixture memory f = _findFixture("pre_mature_valid", true, true);
        address[5] memory ids = [address(LOCKBOX), address(0), address(PORTAL), PORTAL.systemConfig(), address(L1CDM)];
        string[5] memory names = ["lockbox", "global(0)", "portal", "systemConfig", "l1cdm"];
        address eoa = address(0xE0A1);
        vm.deal(eoa, 100 ether);
        for (uint256 i; i < ids.length; i++) {
            uint256 snap = vm.snapshotState();
            string memory k = string.concat("pause[", names[i], "]");
            vm.prank(GUARDIAN);
            (bool ok, bytes memory ret) = address(SUPERCHAIN_CONFIG).call(abi.encodeCall(ISuperchainConfig.pause, (ids[i])));
            _put(k, _res(ok, ret));
            _put(string.concat(k, ".portal.paused"), PORTAL.paused() ? "1" : "0");
            _put(string.concat(k, ".lockbox.paused"), LOCKBOX.paused() ? "1" : "0");
            _put(string.concat(k, ".cdm.paused"), L1CDM.paused() ? "1" : "0");
            _put(string.concat(k, ".asr.paused"), ASR.paused() ? "1" : "0");
            (ok, ret) = _finalizeWithGas(f, 5_000_000);
            _put(string.concat(k, ".finalize"), _res(ok, ret));
            (ok, ret) = _reproveAs(f, address(0xB0B));
            _put(string.concat(k, ".prove"), _res(ok, ret));
            Inner memory m = decodeInner(f.wd);
            vm.prank(eoa, eoa);
            (ok, ret) = address(L1CDM).call(
                abi.encodeCall(IMessenger.relayMessage, (m.nonce, m.sender, m.target, m.value, m.minGasLimit, m.message))
            );
            _put(string.concat(k, ".relayMessage(direct)"), _res(ok, ret));
            vm.prank(address(PORTAL));
            (ok, ret) = address(LOCKBOX).call(abi.encodeCall(ILockbox.unlockETH, (1 ether)));
            _put(string.concat(k, ".lockbox.unlockETH(as portal)"), _res(ok, ret));
            vm.prank(eoa, eoa);
            (ok, ret) = address(PORTAL).call{ value: 1 ether }(
                abi.encodeCall(IPortal.depositTransaction, (eoa, 1 ether, uint64(100_000), false, bytes("")))
            );
            _put(string.concat(k, ".deposit(1eth)"), _res(ok, ret));
            vm.prank(eoa, eoa);
            (ok, ret) = address(L1CDM).call{ value: 1 ether }(abi.encodeCall(IMessenger.sendMessage, (eoa, bytes(""), uint32(100_000))));
            _put(string.concat(k, ".cdm.sendMessage(1eth)"), _res(ok, ret));
            vm.prank(eoa, eoa);
            (ok, ret) = L1_STANDARD_BRIDGE.call{ value: 1 ether }(
                abi.encodeWithSignature("depositETH(uint32,bytes)", uint32(200_000), bytes(""))
            );
            _put(string.concat(k, ".bridge.depositETH(1eth)"), _res(ok, ret));
            vm.revertToStateAndDelete(snap);
        }
    }

    // ------------------------------------------------------------------------------------ D6
    function test_D6_delete_proven_withdrawal() public {
        _begin("D6-delete");
        uint256 n = _fixtureCount();
        for (uint256 i; i < n; i++) {
            Fixture memory f = _loadFixture(i);
            if (f.postU21) continue;
            if (keccak256(bytes(f.class_)) != keccak256("pre_challenger_wins") && i % 6 != 0) continue;
            string memory k = string.concat("fx", vm.toString(i), "[", f.class_, "]");
            uint256 snap = vm.snapshotState();
            vm.prank(address(0xB0B), address(0xB0B));
            (bool ok, bytes memory ret) =
                address(PORTAL).call(abi.encodeCall(IPortal.deleteProvenWithdrawal, (f.hash, f.proofSubmitter)));
            _put(string.concat(k, ".delete"), _res(ok, ret));
            (, uint64 ts) = PORTAL.provenWithdrawals(f.hash, f.proofSubmitter);
            _put(string.concat(k, ".entryAfter"), ts == 0 ? "deleted" : "present");
            _put(string.concat(k, ".numSubmittersAfter"), vm.toString(PORTAL.numProofSubmitters(f.hash)));
            // re-prove after delete (recorded calldata) and finalize attempt
            (ok, ret) = _reproveAs(f, f.proofSubmitter);
            _put(string.concat(k, ".reproveAfter"), _res(ok, ret));
            vm.warp(block.timestamp + 8 days);
            (ok, ret) = _finalizeWithGas(f, 5_000_000);
            _put(string.concat(k, ".finalize+8d(no game action)"), _res(ok, ret));
            vm.revertToStateAndDelete(snap);
        }
    }
}
