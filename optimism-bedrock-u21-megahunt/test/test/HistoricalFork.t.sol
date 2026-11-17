// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../src/HistoricalFork.sol";

/// Verifies the fork-point table against the chain: at every point, the pointers of all 14
/// tracked contracts at END(block-1) and END(block) equal the table, and every listed change is
/// a real change. One fork, re-pinned 38 times with vm.rollFork (no fork leak).
contract HistoricalForkTest is HistoricalFork {
    function test_table_matches_chain_at_every_point() public {
        _forkAt(HFData.blockOf(0) - 1);
        string memory out = "| # | label | block | UTC ts | portal | SystemConfig | L1CDM | L1StandardBridge | DGF | ASR | ETHLockbox |\n|---|---|---|---|---|---|---|---|---|---|---|\n";
        for (uint256 i; i < HFData.POINTS; i++) {
            _rollBefore(i);
            assertEq(block.number, HFData.blockOf(i) - 1, "roll before");
            _assertImpls(i, false);
            _rollAfter(i);
            assertEq(block.number, HFData.blockOf(i), "roll after");
            assertEq(block.timestamp, HFData.timestampOf(i), "timestamp of upgrade block");
            _assertImpls(i, true);
            uint256 changed;
            for (uint256 c; c < HFData.CONTRACTS; c++) {
                bool ch = HFData.implAfter(c, i) != HFData.implBefore(c, i);
                assertEq(ch, HFData.changedAt(c, i), "changedAt consistent");
                if (ch) changed++;
            }
            assertGt(changed, 0, "every fork point changes at least one pointer");
            out = string.concat(
                out, "| ", vm.toString(i), " | ", HFData.label(i), " | ", vm.toString(HFData.blockOf(i)), " | ",
                vm.toString(uint256(HFData.timestampOf(i))), " | "
            );
            out = string.concat(
                out, _version(OP_PORTAL), " | ", _version(OP_SYSTEM_CONFIG), " | ", _version(OP_L1CDM), " | ",
                _version(OP_L1_BRIDGE), " | "
            );
            out = string.concat(out, _version(OP_DGF), " | ", _version(OP_ASR), " | ", _version(OP_LOCKBOX), " |\n");
        }
        vm.writeFile("../evidence/F6-fork-point-versions.md", out);
    }

    function test_named_points_and_era_lookup() public {
        assertEq(_point("U21_V9"), HFData.U21_V9);
        assertEq(HFData.blockOf(_point("U21_V9")), 26430859);
        assertEq(_eraOf(26430858), HFData.U20_V8);
        assertEq(_eraOf(26430859), HFData.U21_V9);
        assertEq(_eraOf(20062696), HFData.V1_4_0_FP);
        _forkBefore(HFData.U21_V9);
        assertEq(_version(OP_PORTAL), "5.8.0");
        _rollAfter(HFData.U21_V9);
        assertEq(_version(OP_PORTAL), "6.1.0");
        assertEq(_impl(HFData.L1CDM), 0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448);
    }
}
