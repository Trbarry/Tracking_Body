// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "./Base.sol";

contract BasicTest is Base {
    function setUp() public { _fork(); }

    function test_dump() public view {
        for (uint256 i = 0; i < 43; i++) {
            Prove memory p = _load(i);
            (address game, uint64 ts) = PORTAL.provenWithdrawals(p.hash, p.submitter);
            console.log(i, p.blockNumber, p.wd.sender, p.wd.target);
            console.log("   value/gasLimit/datalen", p.wd.value, p.wd.gasLimit, p.wd.data.length);
            console.log("   game/ts/finalized", game, ts, PORTAL.finalizedWithdrawals(p.hash));
            console.log("   gameStatus/claims/nsub", IGame(game).status(), IGame(game).claimDataLen(), PORTAL.numProofSubmitters(p.hash));
        }
    }

    function test_finalize_messenger_v8proof() public {
        Prove memory p = _load(0);
        _mature(p.hash, p.submitter);
        uint256 lb = LOCKBOX.balance;
        vm.prank(p.submitter);
        PORTAL.finalizeWithdrawalTransaction(p.wd);
        assertTrue(PORTAL.finalizedWithdrawals(p.hash));
        assertTrue(L1CDM.successfulMessages(_msgHash(p.wd.data)));
        assertEq(lb - LOCKBOX.balance, p.wd.value);
    }
}
