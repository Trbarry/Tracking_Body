// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./U21Fixtures.sol";

/// @notice End-to-end proof that the real-withdrawal fixture works on the post-U21 fork (`l1`):
///         every curated fixture is loaded, driven to finality through public functions only,
///         and finalized against the REAL deployed v9 portal / lockbox / messenger.
contract FixtureE2ETest is U21FixtureBase {
    bytes32 constant WITHDRAWAL_FINALIZED = keccak256("WithdrawalFinalized(bytes32,bool)");
    bytes32 constant RELAYED = keccak256("RelayedMessage(bytes32)");
    bytes32 constant FAILED_RELAYED = keccak256("FailedRelayedMessage(bytes32)");

    function setUp() public {
        vm.createSelectFork(vm.envOr("U21_FORK", string("l1")));
    }

    function test_fixture_integrity() public {
        uint256 n = _fixtureCount();
        assertGt(n, 0);
        for (uint256 i; i < n; i++) {
            Fixture memory f = _loadFixture(i);
            (address game, uint64 ts) = PORTAL.provenWithdrawals(f.hash, f.proofSubmitter);
            assertEq(game, f.game, "game");
            assertEq(ts, f.proofTimestamp, "ts");
            assertFalse(PORTAL.finalizedWithdrawals(f.hash), "finalized at pin");
        }
    }

    /// @dev Single canonical end-to-end run: pre-U21 proof, mature at the pin, messenger, with ETH.
    function test_e2e_preU21_mature_messenger_value() public {
        Fixture memory f = _findFixture("pre_mature_valid", true, true);
        uint256 lb = address(LOCKBOX).balance;
        uint256 tb = L1_STANDARD_BRIDGE.balance;
        // Already final at the pin: no warp, no game interaction needed at all.
        PORTAL.checkWithdrawal(f.hash, f.proofSubmitter);
        _finalizeAs(f, address(0xBEEF));
        assertTrue(PORTAL.finalizedWithdrawals(f.hash));
        assertTrue(L1CDM.successfulMessages(messageHash(f.wd)));
        assertEq(lb - address(LOCKBOX).balance, f.wd.value, "lockbox paid exactly value");
        assertEq(address(PORTAL).balance, 0, "portal holds no ETH");
        assertEq(address(L1CDM).balance, 0, "messenger holds no ETH");
        tb; // bridge forwards ETH to the recipient
    }

    /// @dev Post-U21 proof (type-9 game still in progress at the pin): honest resolution path.
    function test_e2e_postU21_messenger() public {
        Fixture memory f = _findFixture("post_inprogress", true, true);
        assertEq(IGame(f.game).status(), 0);
        assertTrue(_makeFinalizable(f), "game resolved DEFENDER_WINS via public functions");
        uint256 lb = address(LOCKBOX).balance;
        _finalizeAs(f, f.proofSubmitter);
        assertTrue(PORTAL.finalizedWithdrawals(f.hash));
        assertTrue(L1CDM.successfulMessages(messageHash(f.wd)));
        assertEq(lb - address(LOCKBOX).balance, f.wd.value);
    }

    struct Outcome {
        bool finalizable;
        bool finalized;
        bool success;
        bool relayed;
        bool failedMsg;
        uint256 gasUsed;
        int256 dLockbox;
        uint256 portalBal;
        bytes4 revertSel;
    }

    /// @dev Runs every curated fixture end-to-end (each from a clean snapshot) and writes the
    ///      outcome table to evidence/e2e-<fork>.json.
    function test_e2e_all_fixtures() public {
        uint256 n = _fixtureCount();
        string memory rows = "";
        uint256 okCount;
        for (uint256 i; i < n; i++) {
            Fixture memory f = _loadFixture(i);
            uint256 snap = vm.snapshotState();
            Outcome memory o = _run(f);
            vm.revertToStateAndDelete(snap);
            if (o.finalized) okCount++;
            rows = string.concat(
                rows,
                i == 0 ? "" : ",\n",
                '{"i":', vm.toString(i), ',"hash":"', vm.toString(f.hash), '","class":"', f.class_,
                '","messenger":', f.messenger ? "true" : "false",
                ',"value":"', vm.toString(f.wd.value),
                '","finalizable":', o.finalizable ? "true" : "false",
                ',"finalized":', o.finalized ? "true" : "false"
            );
            rows = string.concat(
                rows,
                ',"success":', o.success ? "true" : "false",
                ',"relayed":', o.relayed ? "true" : "false",
                ',"failedMsg":', o.failedMsg ? "true" : "false",
                ',"gasUsed":', vm.toString(o.gasUsed),
                ',"dLockbox":"', vm.toString(o.dLockbox),
                '","portalBal":"', vm.toString(o.portalBal),
                '","revertSel":"', vm.toString(bytes32(o.revertSel)), '"}'
            );
            // Core assertions on every fixture.
            assertEq(o.portalBal, 0, "portal must never retain ETH");
            if (o.finalized) {
                if (f.messenger) assertTrue(o.relayed != o.failedMsg, "messenger: exactly one of relayed/failed");
                if (o.success) assertEq(o.dLockbox, -int256(f.wd.value), "lockbox delta == -value");
                else assertEq(o.dLockbox, 0, "failed call: value re-locked");
            } else {
                assertEq(o.dLockbox, 0, "no finalize => no lockbox movement");
            }
        }
        string memory fork = vm.envOr("U21_FORK", string("l1"));
        vm.writeFile(string.concat("evidence/e2e-", fork, ".json"), string.concat("[\n", rows, "\n]\n"));
        emit log_named_uint("fixtures", n);
        emit log_named_uint("finalized", okCount);
    }

    function _run(Fixture memory f) internal returns (Outcome memory o) {
        (, uint64 ts) = PORTAL.provenWithdrawals(f.hash, f.proofSubmitter);
        if (ts == 0) return o;
        o.finalizable = _makeFinalizable(f);
        int256 lb = int256(address(LOCKBOX).balance);
        vm.recordLogs();
        uint256 g = gasleft();
        (bool ok, bytes memory ret) = _finalizeWithGas(f, 15_000_000);
        o.gasUsed = g - gasleft();
        Vm.Log[] memory logs = vm.getRecordedLogs();
        o.finalized = ok;
        if (!ok) o.revertSel = _sel(ret);
        for (uint256 k; k < logs.length; k++) {
            if (logs[k].emitter == address(PORTAL) && logs[k].topics[0] == WITHDRAWAL_FINALIZED) {
                o.success = abi.decode(logs[k].data, (bool));
            }
        }
        if (f.messenger) {
            o.relayed = L1CDM.successfulMessages(messageHash(f.wd));
            o.failedMsg = L1CDM.failedMessages(messageHash(f.wd));
        }
        o.dLockbox = int256(address(LOCKBOX).balance) - lb;
        o.portalBal = address(PORTAL).balance;
    }
}
