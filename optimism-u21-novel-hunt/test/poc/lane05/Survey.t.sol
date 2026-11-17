// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "forge-std/Test.sol";
import "./Ifaces.sol";

contract SurveyTest is Test {
    IPortal constant PORTAL = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    IASR constant ASR = IASR(0x23B2C62946350F4246f9f9D027e071f0264FD113);
    IDGF constant DGF = IDGF(0xe5965Ab5962eDc7477C8520243A95517CD252fA9);

    function test_survey() public {
        vm.createSelectFork("l1");
        string memory j = vm.readFile("proofs.json");
        bytes32[] memory hs = vm.parseJsonBytes32Array(j, ".hashes");
        address[] memory ss = vm.parseJsonAddressArray(j, ".submitters");
        uint256[] memory bs = vm.parseJsonUintArray(j, ".blocks");
        emit log_named_uint("now", block.timestamp);
        for (uint256 i; i < hs.length; i++) {
            (address g, uint64 ts) = PORTAL.provenWithdrawals(hs[i], ss[i]);
            IGame game = IGame(g);
            console.log("---", i, bs[i]);
            console.logBytes32(hs[i]);
            console.log(" submitter/game", ss[i], g);
            console.log(" ts/nSub/finalized", ts, PORTAL.numProofSubmitters(hs[i]), PORTAL.finalizedWithdrawals(hs[i]));
            if (g == address(0)) continue;
            console.log(" type/status/created", game.gameType(), game.status(), game.createdAt());
            console.log(" proper/respected/valid", ASR.isGameProper(g), ASR.isGameRespected(g), ASR.isGameClaimValid(g));
            vm.expectRevert();
            PORTAL.deleteProvenWithdrawal(hs[i], ss[i]);
        }
    }
}
