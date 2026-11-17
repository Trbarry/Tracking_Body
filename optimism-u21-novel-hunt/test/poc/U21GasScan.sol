// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./U21Fixtures.sol";

/// @notice Shared gas-probe machinery: classify the outcome of
///         `finalizeWithdrawalTransactionExternalProof{gas: g}` for one withdrawal, from a
///         snapshot (cold access list, state restored after every probe).
abstract contract U21GasScan is U21FixtureBase {
    enum Class {
        REVERTED, // 0
        FINALIZED_RELAYED, // 1  messenger: successfulMessages set
        FINALIZED_FAILEDMSG, // 2  messenger: failedMessages set (replayable)
        FINALIZED_NEITHER, // 3  messenger: finalized but recorded in NEITHER mapping (unreplayable)
        FINALIZED_PLAIN_OK, // 4  non-messenger, success=true
        FINALIZED_PLAIN_FAIL // 5  non-messenger, success=false (value re-locked; unreplayable by design)

    }

    bytes32 internal constant WITHDRAWAL_FINALIZED = keccak256("WithdrawalFinalized(bytes32,bool)");

    struct Probe {
        WithdrawalTransaction wd;
        bytes32 hash;
        address submitter;
        bool messenger;
    }

    struct Scan {
        uint256[6] count;
        uint256 firstNeither;
        uint256 lastNeither;
        uint256 firstFailed;
        uint256 lastFailed;
        uint256 nonMonotone;
        uint256 gNoRevert;
        uint256 gTop;
        Class cTop;
        uint256 usedTop;
        bytes4 selBelow;
    }

    uint256 internal probeGas; // gas of the probe currently being classified

    /// @dev Hook: extra per-probe assertions while the post-state is still live.
    function _afterProbe(Probe memory p, Class c) internal virtual { }

    function _classify(Probe memory p, uint256 gas_) internal returns (Class c, bytes4 sel, uint256 used) {
        // Probes only return value types: release their memory so thousands of probes do not
        // blow up the test's own memory-expansion cost.
        uint256 fmp;
        assembly {
            fmp := mload(0x40)
        }
        probeGas = gas_;
        (c, sel, used) = _classify0(p, gas_);
        assembly {
            mstore(0x40, fmp)
        }
    }

    function _classify0(Probe memory p, uint256 gas_) private returns (Class c, bytes4 sel, uint256 used) {
        uint256 snap = vm.snapshotState();
        uint256 lb = address(LOCKBOX).balance;
        vm.recordLogs();
        uint256 g0 = gasleft();
        (bool ok, bytes memory ret) = address(PORTAL).call{ gas: gas_ }(
            abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (p.wd, p.submitter))
        );
        used = g0 - gasleft();
        if (!ok) {
            sel = _sel(ret);
            require(address(LOCKBOX).balance == lb, "revert moved lockbox ETH");
            require(!PORTAL.finalizedWithdrawals(p.hash), "revert left finalized flag");
        } else {
            c = _classOf(p, lb);
        }
        _afterProbe(p, c);
        vm.revertToStateAndDelete(snap);
    }

    function _classOf(Probe memory p, uint256 lb) private returns (Class c) {
        require(PORTAL.finalizedWithdrawals(p.hash), "ok but not finalized");
        require(address(PORTAL).balance == 0, "portal retained ETH");
        require(PORTAL.l2Sender() == DEFAULT_L2_SENDER, "l2Sender not reset");
        uint256 paid = lb - address(LOCKBOX).balance;
        if (p.messenger) {
            bytes32 mh = keccak256(p.wd.data);
            bool s = L1CDM.successfulMessages(mh);
            bool f = L1CDM.failedMessages(mh);
            if (s) c = Class.FINALIZED_RELAYED;
            else if (f) c = Class.FINALIZED_FAILEDMSG;
            else c = Class.FINALIZED_NEITHER;
            // ETH accounting on every probe: recorded => lockbox paid exactly value.
            require(paid == (c == Class.FINALIZED_NEITHER ? 0 : p.wd.value), "messenger: lockbox delta");
        } else {
            bool success;
            Vm.Log[] memory logs = vm.getRecordedLogs();
            for (uint256 k; k < logs.length; k++) {
                if (logs[k].emitter == address(PORTAL) && logs[k].topics[0] == WITHDRAWAL_FINALIZED) {
                    success = abi.decode(logs[k].data, (bool));
                }
            }
            c = success ? Class.FINALIZED_PLAIN_OK : Class.FINALIZED_PLAIN_FAIL;
            require(paid == (success ? p.wd.value : 0), "plain: lockbox delta");
        }
    }

    function _minNonRevert(Probe memory p, uint256 lo, uint256 hi) internal returns (uint256) {
        while (lo < hi) {
            uint256 mid = (lo + hi) / 2;
            (Class c,,) = _classify(p, mid);
            if (c == Class.REVERTED) lo = mid + 1;
            else hi = mid;
        }
        return lo;
    }

    function _minClass(Probe memory p, Class want, uint256 lo, uint256 hi) internal returns (uint256) {
        while (lo < hi) {
            uint256 mid = (lo + hi) / 2;
            (Class c,,) = _classify(p, mid);
            if (c != want) lo = mid + 1;
            else hi = mid;
        }
        return lo;
    }

    function _note(Scan memory s, Class c, uint256 g) internal pure {
        s.count[uint256(c)]++;
        if (c == Class.FINALIZED_NEITHER) {
            if (s.firstNeither == 0 || g < s.firstNeither) s.firstNeither = g;
            if (g > s.lastNeither) s.lastNeither = g;
        }
        if (c == Class.FINALIZED_FAILEDMSG) {
            if (s.firstFailed == 0 || g < s.firstFailed) s.firstFailed = g;
            if (g > s.lastFailed) s.lastFailed = g;
        }
    }

    /// @notice Binary search for the two boundaries, then EVERY gas value within `dense` of them,
    ///         then a coarse sweep from 0 to `maxGas` in `coarse` steps.
    function _scan(Probe memory p, uint256 dense, uint256 coarse, uint256 maxGas) internal returns (Scan memory s) {
        Class top = p.messenger ? Class.FINALIZED_RELAYED : Class.FINALIZED_PLAIN_OK;
        (s.cTop,, s.usedTop) = _classify(p, maxGas);
        s.gNoRevert = _minNonRevert(p, 0, maxGas);
        s.gTop = s.cTop == top ? _minClass(p, top, 0, maxGas) : 0;
        uint256 lo = s.gNoRevert > dense ? s.gNoRevert - dense : 0;
        uint256 hi = (s.gTop > s.gNoRevert ? s.gTop : s.gNoRevert) + dense;
        if (hi - lo > 6 * dense) hi = lo + 6 * dense; // cap run time when the gap is wide
        if (hi > maxGas) hi = maxGas;
        Class prev = Class.REVERTED;
        for (uint256 g = lo; g <= hi; g++) {
            (Class c,,) = _classify(p, g);
            _note(s, c, g);
            if (uint256(c) == 0 && uint256(prev) != 0) s.nonMonotone++;
            prev = c;
        }
        if (s.gTop > s.gNoRevert + 6 * dense) {
            // also every gas value just below the top boundary
            for (uint256 g = s.gTop - dense; g <= s.gTop + dense && g <= maxGas; g++) {
                (Class c,,) = _classify(p, g);
                _note(s, c, g);
            }
        }
        uint256 top_ = (s.gTop > s.gNoRevert ? s.gTop : s.gNoRevert) + 400_000;
        if (top_ > maxGas) top_ = maxGas;
        if (s.cTop != top) {
            // the top class is never reached: sweep the whole range so that a class that only
            // exists in a gas WINDOW (e.g. NEITHER below, FAILEDMSG above) is bracketed.
            top_ = maxGas;
            if (coarse < maxGas / 400) coarse = maxGas / 400;
        }
        for (uint256 g = 0; g <= top_; g += coarse) {
            (Class c,,) = _classify(p, g);
            _note(s, c, g);
        }
        (, s.selBelow,) = _classify(p, s.gNoRevert == 0 ? 0 : s.gNoRevert - 1);
    }

    function _scanJson(Scan memory s) internal pure returns (string memory r) {
        r = string.concat(
            '"classAtMax":', vm.toString(uint256(s.cTop)), ',"usedAtMax":', vm.toString(s.usedTop),
            ',"minGasNoRevert":', vm.toString(s.gNoRevert), ',"minGasTopClass":', vm.toString(s.gTop),
            ',"revertSelBelow":"', vm.toString(bytes32(s.selBelow)),
            '","nonMonotone":', vm.toString(s.nonMonotone)
        );
        r = string.concat(
            r,
            ',"probes":{"reverted":', vm.toString(s.count[0]), ',"relayed":', vm.toString(s.count[1]),
            ',"failedMsg":', vm.toString(s.count[2]), ',"neither":', vm.toString(s.count[3]),
            ',"plainOk":', vm.toString(s.count[4]), ',"plainFail":', vm.toString(s.count[5]), "}"
        );
        r = string.concat(
            r,
            ',"firstNeither":', vm.toString(s.firstNeither), ',"lastNeither":', vm.toString(s.lastNeither),
            ',"firstFailed":', vm.toString(s.firstFailed), ',"lastFailed":', vm.toString(s.lastFailed)
        );
    }
}
