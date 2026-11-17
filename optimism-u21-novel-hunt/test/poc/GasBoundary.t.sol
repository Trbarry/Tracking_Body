// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./U21Fixtures.sol";

/// @notice Gas-boundary classification of `finalizeWithdrawalTransactionExternalProof` on REAL
///         fixtures against the REAL deployed bytecode. Run on both forks:
///           U21_FORK=l1pre forge test --match-path test/GasBoundary.t.sol   (v8: portal 5.8.0 / L1CDM 2.11.1)
///           U21_FORK=l1    forge test --match-path test/GasBoundary.t.sol   (v9: portal 6.1.0 / L1CDM 2.13.0)
///         All state preparation (warps + honest game resolution) happens in setUp(), so the test
///         body starts from a COLD access list, like a real transaction; every probe is taken from
///         the same snapshot (vm.revertToState restores coldness - verified).
///         `gas` below is the gas given to the portal proxy call frame (a real tx needs
///         21000 + calldata intrinsic on top).
contract GasBoundaryTest is U21FixtureBase {
    enum Class {
        REVERTED, // 0
        FINALIZED_RELAYED, // 1  messenger: successfulMessages set
        FINALIZED_FAILEDMSG, // 2  messenger: failedMessages set (replayable)
        FINALIZED_NEITHER, // 3  messenger: finalized, NOT recorded anywhere (unreplayable)
        FINALIZED_PLAIN_OK, // 4  non-messenger, success=true
        FINALIZED_PLAIN_FAIL // 5  non-messenger, success=false (value re-locked, unreplayable by design)

    }

    bytes32 constant WITHDRAWAL_FINALIZED = keccak256("WithdrawalFinalized(bytes32,bool)");

    Fixture[] internal fx;
    string internal fork;

    function setUp() public {
        fork = vm.envOr("U21_FORK", string("l1"));
        vm.createSelectFork(fork);
        uint256 n = _fixtureCount();
        // Pass 1: resolve every in-progress game honestly (public functions only).
        for (uint256 i; i < n; i++) {
            Fixture memory f = _loadFixture(i);
            (address game, uint64 ts) = PORTAL.provenWithdrawals(f.hash, f.proofSubmitter);
            if (ts == 0) continue; // not proven on this fork (post-U21 fixture on l1pre)
            if (_resolveGameHonestly(game) != 2) continue;
            fx.push(f);
        }
        // Pass 2: one warp past every maturity / finality air-gap.
        uint256 t = block.timestamp;
        for (uint256 i; i < fx.length; i++) {
            (address game, uint64 ts) = PORTAL.provenWithdrawals(fx[i].hash, fx[i].proofSubmitter);
            uint256 t1 = uint256(ts) + PORTAL.proofMaturityDelaySeconds() + 1;
            uint256 t2 = uint256(IGame(game).resolvedAt()) + PORTAL.disputeGameFinalityDelaySeconds() + 1;
            if (t1 > t) t = t1;
            if (t2 > t) t = t2;
        }
        vm.warp(t);
    }

    function _classify(Fixture memory f, uint256 gas_) internal returns (Class c, bytes4 sel, uint256 used) {
        // Probes only return value types: release the memory they allocate so that thousands of
        // probes do not blow up memory-expansion cost of the test itself.
        uint256 fmp;
        assembly {
            fmp := mload(0x40)
        }
        (c, sel, used) = _classify0(f, gas_);
        assembly {
            mstore(0x40, fmp)
        }
    }

    function _classify0(Fixture memory f, uint256 gas_) internal returns (Class c, bytes4 sel, uint256 used) {
        uint256 snap = vm.snapshotState();
        uint256 lb = address(LOCKBOX).balance;
        vm.recordLogs();
        uint256 g0 = gasleft();
        (bool ok, bytes memory ret) = _finalizeWithGas(f, gas_);
        used = g0 - gasleft();
        if (!ok) {
            sel = _sel(ret);
            require(address(LOCKBOX).balance == lb, "revert moved lockbox ETH");
        } else {
            c = _classOf(f, lb);
        }
        vm.revertToStateAndDelete(snap);
    }

    function _classOf(Fixture memory f, uint256 lb) internal returns (Class c) {
        require(PORTAL.finalizedWithdrawals(f.hash), "ok but not finalized");
        require(address(PORTAL).balance == 0, "portal retained ETH");
        uint256 paid = lb - address(LOCKBOX).balance;
        if (f.messenger) {
            bytes32 mh = messageHash(f.wd);
            if (L1CDM.successfulMessages(mh)) c = Class.FINALIZED_RELAYED;
            else if (L1CDM.failedMessages(mh)) c = Class.FINALIZED_FAILEDMSG;
            else c = Class.FINALIZED_NEITHER;
            // ETH accounting on every probe.
            require(paid == (c == Class.FINALIZED_NEITHER ? 0 : f.wd.value), "messenger: lockbox delta");
        } else {
            bool success;
            Vm.Log[] memory logs = vm.getRecordedLogs();
            for (uint256 k; k < logs.length; k++) {
                if (logs[k].emitter == address(PORTAL) && logs[k].topics[0] == WITHDRAWAL_FINALIZED) {
                    success = abi.decode(logs[k].data, (bool));
                }
            }
            c = success ? Class.FINALIZED_PLAIN_OK : Class.FINALIZED_PLAIN_FAIL;
            require(paid == (success ? f.wd.value : 0), "plain: lockbox delta");
        }
    }

    /// @dev Smallest gas in [lo, hi] whose class is not REVERTED (assumes monotone; the dense
    ///      scan afterwards checks the assumption).
    function _minNonRevert(Fixture memory f, uint256 lo, uint256 hi) internal returns (uint256) {
        while (lo < hi) {
            uint256 mid = (lo + hi) / 2;
            (Class c,,) = _classify(f, mid);
            if (c == Class.REVERTED) lo = mid + 1;
            else hi = mid;
        }
        return lo;
    }

    function _minClass(Fixture memory f, Class want, uint256 lo, uint256 hi) internal returns (uint256) {
        while (lo < hi) {
            uint256 mid = (lo + hi) / 2;
            (Class c,,) = _classify(f, mid);
            if (c != want) lo = mid + 1;
            else hi = mid;
        }
        return lo;
    }

    struct Scan {
        uint256[6] count;
        uint256 firstNeither;
        uint256 lastNeither;
        uint256 nonMonotone;
        uint256 gNoRevert;
        uint256 gTop;
        Class cTop;
        uint256 usedTop;
        bytes4 selBelow;
    }

    function _note(Scan memory s, Class c, uint256 g) internal pure {
        s.count[uint256(c)]++;
        if (c == Class.FINALIZED_NEITHER) {
            if (s.firstNeither == 0 || g < s.firstNeither) s.firstNeither = g;
            if (g > s.lastNeither) s.lastNeither = g;
        }
    }

    function _scan(Fixture memory f, uint256 dense) internal returns (Scan memory s) {
        Class top = f.messenger ? Class.FINALIZED_RELAYED : Class.FINALIZED_PLAIN_OK;
        (s.cTop,, s.usedTop) = _classify(f, 12_000_000);
        s.gNoRevert = _minNonRevert(f, 0, 12_000_000);
        s.gTop = s.cTop == top ? _minClass(f, top, 0, 12_000_000) : 0;
        // Dense scan: EVERY gas value around both boundaries, plus a coarse sweep from 0.
        uint256 lo = s.gNoRevert > dense ? s.gNoRevert - dense : 0;
        uint256 hi = (s.gTop > s.gNoRevert ? s.gTop : s.gNoRevert) + dense;
        if (hi - lo > 6 * dense) hi = lo + 6 * dense; // cap run time when the gap is wide
        Class prev = Class.REVERTED;
        for (uint256 g = lo; g <= hi; g++) {
            (Class c,,) = _classify(f, g);
            _note(s, c, g);
            if (uint256(c) == 0 && uint256(prev) != 0) s.nonMonotone++;
            prev = c;
        }
        for (uint256 g = 0; g <= s.gTop + 400_000; g += 4099) {
            (Class c,,) = _classify(f, g);
            _note(s, c, g);
        }
        (, s.selBelow,) = _classify(f, s.gNoRevert == 0 ? 0 : s.gNoRevert - 1);
    }

    function _row(Fixture memory f, Scan memory s) internal pure returns (string memory r) {
        r = string.concat(
            '{"i":', vm.toString(f.index), ',"hash":"', vm.toString(f.hash), '","class":"', f.class_,
            '","messenger":', f.messenger ? "true" : "false",
            ',"value":"', vm.toString(f.wd.value), '","gasLimit":', vm.toString(f.wd.gasLimit),
            ',"dataLen":', vm.toString(f.wd.data.length)
        );
        r = string.concat(
            r,
            ',"classAt12M":', vm.toString(uint256(s.cTop)), ',"usedAt12M":', vm.toString(s.usedTop),
            ',"minGasNoRevert":', vm.toString(s.gNoRevert), ',"minGasTopClass":', vm.toString(s.gTop),
            ',"revertSelBelow":"', vm.toString(bytes32(s.selBelow)),
            '","nonMonotone":', vm.toString(s.nonMonotone)
        );
        r = string.concat(
            r,
            ',"probes":{"reverted":', vm.toString(s.count[0]), ',"relayed":', vm.toString(s.count[1]),
            ',"failedMsg":', vm.toString(s.count[2]), ',"neither":', vm.toString(s.count[3]),
            ',"plainOk":', vm.toString(s.count[4]), ',"plainFail":', vm.toString(s.count[5]),
            '},"firstNeither":', vm.toString(s.firstNeither), ',"lastNeither":', vm.toString(s.lastNeither), "}"
        );
    }

    /// @notice Binary-search + dense scan for every fixture; writes evidence/gas-boundary-<fork>.json
    function test_gas_boundary_real_fixtures() public {
        string memory rows = "";
        uint256 neither;
        uint256 dense = vm.envOr("U21_DENSE", uint256(1500));
        uint256 from = vm.envOr("U21_FROM", uint256(0));
        uint256 to = vm.envOr("U21_TO", fx.length);
        if (to > fx.length) to = fx.length;
        for (uint256 i = from; i < to; i++) {
            Fixture memory f = fx[i];
            bool dup; // multi-submitter fixtures share the hash
            for (uint256 j; j < i; j++) {
                if (fx[j].hash == f.hash) dup = true;
            }
            if (dup) continue;
            Scan memory s = _scan(f, dense);
            if (s.count[3] > 0) neither++;
            rows = string.concat(rows, bytes(rows).length == 0 ? "" : ",\n", _row(f, s));
        }
        vm.writeFile(string.concat("evidence/gas-boundary-", fork, vm.envOr("U21_TAG", string("")), ".json"), string.concat("[\n", rows, "\n]\n"));
        emit log_named_uint("fixtures measured", fx.length);
        emit log_named_uint("fixtures with FINALIZED_NEITHER reachable", neither);
        if (keccak256(bytes(fork)) == keccak256("l1")) {
            assertEq(neither, 0, "v9: finalized-with-neither-recorded must be unreachable");
        }
    }

    /// @notice Random gas on a random fixture. Under v9 the NEITHER class must never appear.
    function testFuzz_gas_class(uint256 seed, uint256 gas_) public {
        Fixture memory f = fx[seed % fx.length];
        gas_ = bound(gas_, 0, f.wd.gasLimit * 2 + 600_000);
        (Class c,,) = _classify(f, gas_);
        if (keccak256(bytes(fork)) == keccak256("l1")) {
            assertTrue(c != Class.FINALIZED_NEITHER, "v9: finalized with neither mapping recorded");
        }
    }
}
