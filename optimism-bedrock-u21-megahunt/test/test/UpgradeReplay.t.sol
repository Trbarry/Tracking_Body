// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../src/UpgradeReplay.sol";

/// Ready-made replays of every identified historical OP Mainnet upgrade transaction (19 fork
/// points, Bedrock .. U21). For each point:
///   test_prank_<LABEL>     fork block-1, prank the recorded sender with the recorded calldata while
///                          recording the state diff; assert (1) all 14 tracked implementation
///                          pointers equal the real post-block table, (2) EVERY slot written by the
///                          replay equals the real chain state at the end of the upgrade block
///                          (mismatches are listed in ../evidence/F6-replay/<LABEL>.txt and must be 0
///                          unless the slot is in the per-point allowlist, see _allowed).
///   test_transact_<LABEL>  fork block-1, vm.transact(txHash); assert the 14 pointers.
/// Run one:  forge test -j 1 --match-test 'test_prank_U19_V7' -vv
contract UpgradeReplayTest is UpgradeReplay {
    /// @dev Slots that the replay writes but another transaction of the SAME block also writes
    ///      (so END-of-block state legitimately differs). Empty for every point so far except the
    ///      ones listed here; each entry was checked by hand.
    function _allowed(uint256, address, bytes32) internal pure returns (bool) {
        return false;
    }

    function _prank(uint256 i) internal {
        _forkBefore(i);
        assertEq(_implMismatches(i, false), 0, "pre-state pointers");
        (SlotWrite[] memory w, uint256 raw) = _replayUpgradeRecording(i);
        assertEq(_implMismatches(i, true), 0, "post-replay pointers == real post-block pointers");
        uint256 accounts = _distinctAccounts(w);
        (uint256 mism, string memory detail) = _compareWithRealPostState(i, w);
        string memory rep = string.concat(
            "label=", HFData.label(i), " block=", vm.toString(HFData.blockOf(i)), " mode=prank txs=", vm.toString(HFData.txCount(i)),
            " rawWrites=", vm.toString(raw), " distinctSlots=", vm.toString(w.length), " accounts=", vm.toString(accounts),
            " mismatchesVsRealEndOfBlock=", vm.toString(mism), "\n", detail
        );
        vm.writeFile(string.concat("../evidence/F6-replay/", HFData.label(i), ".txt"), rep);
        emit log_string(rep);
        assertEq(mism, 0, "every slot written by the replay equals the real end-of-block state");
    }

    function _transact(uint256 i) internal {
        _forkBefore(i);
        _replayUpgrade(i, ReplayMode.Transact);
        assertEq(_implMismatches(i, true), 0, "post-transact pointers == real post-block pointers");
    }

    function test_prank_BEDROCK_STEP1() public { _prank(HFData.BEDROCK_STEP1); }
    function test_prank_BEDROCK() public { _prank(HFData.BEDROCK); }
    function test_prank_PROTOCOL_VERSIONS_INIT() public { _prank(HFData.PROTOCOL_VERSIONS_INIT); }
    function test_prank_SUPERCHAIN_CONFIG_INIT() public { _prank(HFData.SUPERCHAIN_CONFIG_INIT); }
    function test_prank_V1_2_0() public { _prank(HFData.V1_2_0); }
    function test_prank_V1_3_0() public { _prank(HFData.V1_3_0); }
    function test_prank_FP_PROXIES_INIT() public { _prank(HFData.FP_PROXIES_INIT); }
    function test_prank_V1_4_0_FP() public { _prank(HFData.V1_4_0_FP); }
    function test_prank_V1_6_0_ASR() public { _prank(HFData.V1_6_0_ASR); }
    function test_prank_V1_8_0() public { _prank(HFData.V1_8_0); }
    function test_prank_U13_V2() public { _prank(HFData.U13_V2); }
    function test_prank_U14_V3() public { _prank(HFData.U14_V3); }
    function test_prank_U16_V4() public { _prank(HFData.U16_V4); }
    function test_prank_U16A_V4_1() public { _prank(HFData.U16A_V4_1); }
    function test_prank_U17_V5() public { _prank(HFData.U17_V5); }
    function test_prank_U18_V6() public { _prank(HFData.U18_V6); }
    function test_prank_U19_V7() public { _prank(HFData.U19_V7); }
    function test_prank_U20_V8() public { _prank(HFData.U20_V8); }
    function test_prank_U21_V9() public { _prank(HFData.U21_V9); }

    function test_transact_BEDROCK_STEP1() public { _transact(HFData.BEDROCK_STEP1); }
    function test_transact_BEDROCK() public { _transact(HFData.BEDROCK); }
    function test_transact_PROTOCOL_VERSIONS_INIT() public { _transact(HFData.PROTOCOL_VERSIONS_INIT); }
    function test_transact_SUPERCHAIN_CONFIG_INIT() public { _transact(HFData.SUPERCHAIN_CONFIG_INIT); }
    function test_transact_V1_2_0() public { _transact(HFData.V1_2_0); }
    function test_transact_V1_3_0() public { _transact(HFData.V1_3_0); }
    function test_transact_FP_PROXIES_INIT() public { _transact(HFData.FP_PROXIES_INIT); }
    function test_transact_V1_4_0_FP() public { _transact(HFData.V1_4_0_FP); }
    function test_transact_V1_6_0_ASR() public { _transact(HFData.V1_6_0_ASR); }
    function test_transact_V1_8_0() public { _transact(HFData.V1_8_0); }
    function test_transact_U13_V2() public { _transact(HFData.U13_V2); }
    function test_transact_U14_V3() public { _transact(HFData.U14_V3); }
    function test_transact_U16_V4() public { _transact(HFData.U16_V4); }
    function test_transact_U16A_V4_1() public { _transact(HFData.U16A_V4_1); }
    function test_transact_U17_V5() public { _transact(HFData.U17_V5); }
    function test_transact_U18_V6() public { _transact(HFData.U18_V6); }
    function test_transact_U19_V7() public { _transact(HFData.U19_V7); }
    function test_transact_U20_V8() public { _transact(HFData.U20_V8); }
    function test_transact_U21_V9() public { _transact(HFData.U21_V9); }
}
