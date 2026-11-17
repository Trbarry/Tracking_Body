// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./T1Base.sol";

interface IL1CDM {
    function systemConfig() external view returns (address);
    function portal() external view returns (address);
    function paused() external view returns (bool);
    function superchainConfig() external view returns (address);
    function successfulMessages(bytes32) external view returns (bool);
}

interface ISC {
    function pauseTimestamps(address) external view returns (uint256);
    function paused(address) external view returns (bool);
    function paused() external view returns (bool);
    function guardian() external view returns (address);
}

/// Callee that reverts unless it was given at least `need` gas.
contract GasProbe {
    uint256 public immutable need;
    uint256 public hits;

    constructor(uint256 n) {
        need = n;
    }

    fallback() external payable {
        uint256 g = gasleft();
        if (g < need) revert("probe: starved");
        hits += 1;
    }
}

/// Rows 4, 6, 9/17, 10/5/15, 28 of audit/FIX-CLOSURE-MATRIX.md section B (targets 4, 5, 8, 9, 10).
contract T1_Portal is T1Base {
    address submitter = makeAddr("t1-submitter");

    function setUp() public {
        vm.createSelectFork("l1");
        assertEq(block.number, 26433900);
        _load();
    }

    // ------------------------------------------------------------------ T1-04 (targets 4 and 5)
    /// Every value-exit consumer of every chain resolves `paused()` through the same identifier as the portal,
    /// and no pause is recorded (or expired-but-latched) under any identifier of the lineage.
    function test_T1_04_pausePointerGraph() public view {
        for (uint256 i; i < 4; i++) {
            IPortal p = IPortal(portal[i]);
            address lb = p.ethLockbox();
            assertEq(lb, lockbox[i], "portal lockbox");
            ISysCfg sc = ISysCfg(p.systemConfig());
            assertEq(address(sc), sysCfg[i], "portal systemConfig");
            assertEq(sc.optimismPortal(), address(p), "SystemConfig.optimismPortal == portal");
            assertEq(IASR(asr[i]).ethLockbox(), lb, "ASR pause id == portal lockbox");
            address cdm = sc.l1CrossDomainMessenger();
            assertEq(cdm, l1cdm[i]);
            assertEq(IL1CDM(cdm).systemConfig(), address(sc), "L1CDM systemConfig");
            assertEq(IL1CDM(cdm).portal(), address(p), "L1CDM portal");
            assertEq(IHasSysCfg(sc.l1StandardBridge()).systemConfig(), address(sc), "L1SB systemConfig");
            assertEq(IHasSysCfg(sc.l1ERC721Bridge()).systemConfig(), address(sc), "L1ERC721 systemConfig");
            address weth = sc.delayedWETH();
            (bool ok, bytes memory o) = weth.staticcall(abi.encodeWithSignature("ethLockbox()"));
            assertTrue(ok, "DelayedWETH v2 ethLockbox()");
            assertEq(abi.decode(o, (address)), lb, "DelayedWETH pause id == lockbox");
            // the anchor game's WETH and registry resolve through the same lockbox
            IGame ag = IGame(IASR(asr[i]).anchorGame());
            if (ag.gameType() == 9) {
                assertEq(ag.weth(), weth, "anchor game WETH is the SystemConfig WETH");
            }
            ISC scfg = ISC(ILockbox(lb).superchainConfig());
            assertEq(sc.superchainConfig(), address(scfg), "same SuperchainConfig");
            assertEq(IL1CDM(cdm).superchainConfig(), address(scfg));
            // no live or latched pause under any identifier of the lineage
            assertEq(scfg.pauseTimestamps(address(0)), 0, "global");
            assertEq(scfg.pauseTimestamps(lb), 0, "lockbox id");
            assertEq(scfg.pauseTimestamps(address(p)), 0, "retired portal id");
            assertFalse(p.paused());
            assertFalse(IL1CDM(cdm).paused());
            console.log(names[i], "pause graph: portal/ASR/L1CDM/L1SB/L1ERC721/WETH -> lockbox", lb);
        }
    }

    // ------------------------------------------------------------------ T1-05 (target 9, row 17)
    /// Non-default residue in the never-cleared legacy portal slots is never read by any v9 entry point.
    function test_T1_05_legacySlotResidueNeverRead() public {
        uint256[6] memory legacyFixed = [uint256(53), 54, 56, 59, 61, 63];
        for (uint256 i; i < 4; i++) {
            address p = portal[i];
            console.log("==", names[i]);
            for (uint256 k; k < legacyFixed.length; k++) {
                bytes32 v = vm.load(p, bytes32(legacyFixed[k]));
                console.log("  slot", legacyFixed[k]);
                console.logBytes32(v);
            }
            // build an attacker-owned withdrawal proven through the vehicle (proof cell at slot 57)
            WT memory w = WT(uint256(keccak256(abi.encode("t1-05", i))), attacker, attacker, 0, 50_000, hex"");
            bytes32 h = _hash(w);
            address game = IASR(asr[i]).anchorGame();
            uint64 ts = IGame(game).createdAt() + 1;
            bytes32 slot = keccak256(abi.encode(submitter, keccak256(abi.encode(h, uint256(57)))));
            vm.store(p, slot, bytes32(uint256(uint160(game)) | (uint256(ts) << 160)));
            vm.warp(block.timestamp + 8 days);
            vm.deal(attacker, 1 ether);

            vm.record();
            vm.prank(attacker, attacker);
            IPortal(p).depositTransaction{ value: 1 wei }(attacker, 1 wei, 100_000, false, hex"");
            IPortal(p).checkWithdrawal(h, submitter);
            (bool okDel,) = p.call(abi.encodeCall(IPortal.deleteProvenWithdrawal, (h, submitter)));
            assertFalse(okDel, "delete of a valid-game proof reverts");
            vm.prank(attacker, attacker);
            IPortal(p).finalizeWithdrawalTransactionExternalProof(w, submitter);
            (bytes32[] memory reads,) = vm.accesses(p);
            bytes32 legacyProofSlot = keccak256(abi.encode(h, uint256(52)));
            bytes32 legacyBlacklist = keccak256(abi.encode(game, uint256(58)));
            for (uint256 r; r < reads.length; r++) {
                uint256 s = uint256(reads[r]);
                assertTrue(s != 52 && s != 53 && s != 54 && s != 56 && s != 58 && s != 59 && s != 61, "legacy fixed slot read");
                assertTrue(reads[r] != legacyProofSlot && reads[r] != legacyBlacklist, "legacy mapping read");
            }
            assertTrue(IPortal(p).finalizedWithdrawals(h));
            console.log("  portal slot reads during deposit/check/delete/finalize:", reads.length, "none legacy");
            vm.warp(block.timestamp - 8 days);
        }
    }

    // ------------------------------------------------------------------ T1-06 (target 10, rows 5/15)
    /// The two guarded fields are intact on every chain and every initializer refuses an unprivileged caller.
    function test_T1_06_initializerSentinelsAndGuards() public {
        for (uint256 i; i < 4; i++) {
            IPortal p = IPortal(portal[i]);
            // ResourceMetering params (slot 1): prevBaseFee | prevBoughtGas | prevBlockNum, never reset
            bytes32 params = vm.load(address(p), bytes32(uint256(1)));
            uint64 prevBlockNum = uint64(uint256(params) >> 192);
            uint128 prevBaseFee = uint128(uint256(params));
            assertGt(prevBaseFee, 0, "metering base fee not reset");
            assertGt(prevBlockNum, 20_000_000, "metering block number live");
            // xDomainMsgSender sentinel (slot 204) == DEFAULT_L2_SENDER on every L1CDM
            assertEq(address(uint160(uint256(vm.load(l1cdm[i], bytes32(uint256(204)))))), 0x000000000000000000000000000000000000dEaD);
            assertEq(p.l2Sender(), 0x000000000000000000000000000000000000dEaD);
            assertGt(IASR(asr[i]).retirementTimestamp(), 0);
            console.log(names[i], "params.prevBlockNum", prevBlockNum, prevBaseFee);

            // unprivileged initialize on every proxy of the chain reverts
            ISysCfg sc = ISysCfg(p.systemConfig());
            address[8] memory targets = [address(p), l1cdm[i], asr[i], address(sc), sc.l1StandardBridge(), sc.l1ERC721Bridge(), dgf[i], sc.delayedWETH()];
            bytes[8] memory calls = [
                abi.encodeWithSignature("initialize(address,address,address)", attacker, attacker, attacker),
                abi.encodeWithSignature("initialize(address,address)", attacker, attacker),
                bytes.concat(bytes4(keccak256("initialize(address,address,(bytes32,uint256),uint32)")), abi.encode(attacker, attacker, bytes32(0), uint256(0), uint32(9))),
                bytes.concat(
                    bytes4(keccak256("initialize(address,uint32,uint32,bytes32,uint64,address,(uint32,uint8,uint8,uint32,uint32,uint128),(address,address,address,address,address,address,address),uint256,address)")),
                    abi.encode(attacker, uint32(0), uint32(0), bytes32(0), uint64(0), attacker),
                    abi.encode(uint32(0), uint8(0), uint8(0), uint32(0), uint32(0), uint128(0)),
                    abi.encode(attacker, attacker, attacker, attacker, attacker, attacker, attacker),
                    abi.encode(uint256(0), attacker)
                ),
                abi.encodeWithSignature("initialize(address,address)", attacker, attacker),
                abi.encodeWithSignature("initialize(address,address)", attacker, attacker),
                abi.encodeWithSignature("initialize(address)", attacker),
                abi.encodeWithSignature("initialize(address)", attacker)
            ];
            for (uint256 k; k < 8; k++) {
                vm.prank(attacker, attacker);
                (bool ok, bytes memory rd) = targets[k].call(calls[k]);
                assertFalse(ok, "unprivileged initialize must revert");
                assertGe(rd.length, 4, "reverts with a reason (not a missing selector)");
                console.log("   initialize revert", targets[k]);
                console.logBytes(rd);
            }
            // ETHLockbox initialize
            vm.prank(attacker, attacker);
            (bool okL,) = lockbox[i].call(abi.encodeWithSignature("initialize(address,address[])", attacker, new address[](0)));
            assertFalse(okL);
        }
    }

    // ------------------------------------------------------------------ T1-08 (target 8, row 28)
    struct GasCase {
        string name;
        address target;
        uint256 value;
        uint256 gasLimit;
        bool measures; // target is a GasProbe (direct or via EIP-7702 delegation)
    }

    function _proveVehicle(address p, WT memory w) internal {
        address game = IASR(IPortal(p).anchorStateRegistry()).anchorGame();
        uint64 ts = IGame(game).createdAt() + 1;
        bytes32 slot = keccak256(abi.encode(submitter, keccak256(abi.encode(_hash(w), uint256(57)))));
        vm.store(p, slot, bytes32(uint256(uint160(game)) | (uint256(ts) << 160)));
    }

    /// returns (reverted, success flag)
    function _finalizeWithGas(address p, WT memory w, uint256 g) internal returns (bool reverted, bool success) {
        uint256 snap = vm.snapshotState();
        vm.recordLogs();
        vm.prank(attacker, attacker);
        (bool ok,) = p.call{ gas: g }(abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (w, submitter)));
        reverted = !ok;
        if (ok) {
            Vm.Log[] memory logs = vm.getRecordedLogs();
            for (uint256 k; k < logs.length; k++) {
                if (logs[k].emitter == p && logs[k].topics[0] == keccak256("WithdrawalFinalized(bytes32,bool)")) {
                    success = abi.decode(logs[k].data, (bool));
                }
            }
        }
        vm.revertToState(snap);
    }

    /// For direct (non-messenger) withdrawals a failed target call is final (no replay). The fix of row 28
    /// guarantees: whenever finalize does not revert, the target received >= gasLimit. Third-party finalizer
    /// searches the smallest non-reverting gas and the band above it for a `success=false` finalization.
    function test_T1_08_minGasGuaranteeDirectWithdrawals() public {
        address p = portal[0];
        vm.warp(block.timestamp + 8 days);
        uint256[5] memory limits = [uint256(0), 21_000, 100_000, 1_000_000, 10_000_000];
        uint256 violations;
        for (uint256 li; li < limits.length; li++) {
            uint256 L = limits[li];
            GasProbe probe = new GasProbe(L > 300 ? L - 300 : 0);
            address delegated = makeAddr(string(abi.encode("t1-7702", li)));
            vm.etch(delegated, abi.encodePacked(hex"ef0100", address(probe)));
            GasCase[5] memory cases = [
                GasCase("fresh account, value", makeAddr(string(abi.encode("t1-fresh", li))), 1 ether, L, false),
                GasCase("probe, no value", address(probe), 0, L, true),
                GasCase("probe, value", address(probe), 1 ether, L, true),
                GasCase("7702-delegated EOA -> probe, value", delegated, 1 ether, L, true),
                GasCase("precompile 0x0a (point eval), value", address(0x0a), 1 wei, L, false)
            ];
            for (uint256 c; c < cases.length; c++) {
                if (L == 0 && cases[c].measures) continue; // a probe needs gas to record
                WT memory w = WT(uint256(keccak256(abi.encode("t1-08", li, c))), attacker, cases[c].target, cases[c].value, L, hex"");
                _proveVehicle(p, w);
                uint256 lo = 50_000;
                uint256 hi = 16_000_000;
                (bool rHi, bool sHi) = _finalizeWithGas(p, w, hi);
                assertFalse(rHi, "finalizes with ample gas");
                if (cases[c].target != address(0x0a)) assertTrue(sHi, "succeeds with ample gas");
                while (lo + 1 < hi) {
                    uint256 mid = (lo + hi) / 2;
                    (bool r,) = _finalizeWithGas(p, w, mid);
                    if (r) lo = mid;
                    else hi = mid;
                }
                // sweep the band [hi, hi + 4096] for a non-reverting failed call
                uint256 bad;
                for (uint256 g = hi; g < hi + 4096; g += 64) {
                    (bool r, bool s) = _finalizeWithGas(p, w, g);
                    if (!r && !s && cases[c].target != address(0x0a)) bad++;
                }
                (, bool sMin) = _finalizeWithGas(p, w, hi);
                console.log(cases[c].name, L);
                console.log("    min non-reverting outer gas", hi, "success at min", sMin);
                if (cases[c].target != address(0x0a)) {
                    assertTrue(sMin, "target call succeeds at the minimum non-reverting gas");
                } else {
                    console.log("    precompile 0x0a with empty input: call fails by input validation (sender's choice)");
                }
                violations += bad;
            }
        }
        assertEq(violations, 0, "no non-reverting finalization with a starved target");
    }
}
