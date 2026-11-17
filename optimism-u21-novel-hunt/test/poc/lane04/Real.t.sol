// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "./Base.sol";

contract RealTest is Base {
    address constant ATT = address(0xA77ACC);
    function setUp() public { _fork(); }

    function _reprove(Prove memory p, address who) internal {
        vm.prank(who);
        PORTAL.proveWithdrawalTransaction(p.wd, p.gameIndex, p.orp, p.proof);
    }

    // FeeVault (non-messenger, value) withdrawal finalised by a THIRD PARTY through the ExternalProof entry point.
    function test_feevault_thirdparty_external() public {
        Prove memory p = _load(5);
        assertEq(p.wd.sender, 0x4200000000000000000000000000000000000011);
        _mature(p.hash, p.submitter);
        uint256 tb = p.wd.target.balance; uint256 lb = LOCKBOX.balance;
        // plain finalize by third party with no own proof -> Unproven
        vm.prank(ATT);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_Unproven()")));
        PORTAL.finalizeWithdrawalTransaction(p.wd);
        // gas sweep through ExternalProof
        uint8 last = 255;
        for (uint256 g = 150_000; g <= 900_000; g += 1000) {
            uint256 snap = vm.snapshotState();
            vm.prank(ATT);
            (bool ok, bytes memory ret) = address(PORTAL).call{ gas: g }(abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (p.wd, p.submitter)));
            uint8 c;
            if (!ok) c = ret.length == 0 ? 0 : 1; else c = (p.wd.target.balance - tb == p.wd.value) ? 4 : 5;
            vm.revertToState(snap);
            if (c != last) { console.log("  gas >=", g, "outcome", c); last = c; }
        }
        vm.prank(ATT);
        PORTAL.finalizeWithdrawalTransactionExternalProof(p.wd, p.submitter);
        assertEq(p.wd.target.balance - tb, p.wd.value);
        assertEq(lb - LOCKBOX.balance, p.wd.value);
    }

    // Same FeeVault withdrawal, target behaviour SUBSTITUTED with vm.etch (reverting recipient): third party finalises,
    // 27.2 ETH is re-locked and the withdrawal is permanently consumed.
    function test_feevault_etched_reverting_target_thirdparty() public {
        Prove memory p = _load(5);
        _mature(p.hash, p.submitter);
        vm.etch(p.wd.target, hex"60006000fd");
        uint256 tb = p.wd.target.balance; uint256 lb = LOCKBOX.balance;
        vm.prank(ATT);
        PORTAL.finalizeWithdrawalTransactionExternalProof(p.wd, p.submitter);
        assertTrue(PORTAL.finalizedWithdrawals(p.hash));
        assertEq(p.wd.target.balance, tb);
        assertEq(LOCKBOX.balance, lb);
        vm.prank(p.submitter);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_AlreadyFinalized()")));
        PORTAL.finalizeWithdrawalTransaction(p.wd);
        // re-prove is still possible (prove does not check finalized) but can never finalize
        _reprove(p, p.submitter);
        vm.warp(block.timestamp + 8 days);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_AlreadyFinalized()")));
        PORTAL.checkWithdrawal(p.hash, p.submitter);
    }

    // Multiple proof submitters for one hash; only one execution.
    function test_multi_submitters_single_execution() public {
        Prove memory p = _load(0); // messenger ETH 119.59
        address s2 = address(0x5B2);
        uint256 n0 = PORTAL.numProofSubmitters(p.hash);
        _reprove(p, s2);         // second submitter, same real proof
        _reprove(p, s2);         // duplicate push
        assertEq(PORTAL.numProofSubmitters(p.hash), n0 + 2);
        _mature(p.hash, p.submitter);
        // s2's proof is younger -> not mature yet at this time?
        (, uint64 ts2) = PORTAL.provenWithdrawals(p.hash, s2);
        if (block.timestamp - ts2 <= 604800) {
            vm.expectRevert(bytes4(keccak256("OptimismPortal_ProofNotOldEnough()")));
            PORTAL.checkWithdrawal(p.hash, s2);
        }
        // third party uses the ORIGINAL submitter's mature proof
        uint256 lb = LOCKBOX.balance;
        vm.prank(ATT);
        PORTAL.finalizeWithdrawalTransactionExternalProof(p.wd, p.submitter);
        assertEq(lb - LOCKBOX.balance, p.wd.value);
        vm.warp(block.timestamp + 8 days);
        vm.prank(s2);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_AlreadyFinalized()")));
        PORTAL.finalizeWithdrawalTransaction(p.wd);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_AlreadyFinalized()")));
        PORTAL.finalizeWithdrawalTransactionExternalProof(p.wd, p.submitter);
        // direct replay in messenger impossible (not failed)
        (uint256 a, address b, address c, uint256 d, uint256 e, bytes memory f) = _dec(p.wd.data);
        vm.expectRevert();
        L1CDM.relayMessage(a, b, c, d, e, f);
        assertEq(lb - LOCKBOX.balance, p.wd.value);
    }

    function _dec(bytes memory data) internal pure returns (uint256, address, address, uint256, uint256, bytes memory) {
        bytes memory args = new bytes(data.length - 4);
        for (uint256 j = 0; j < args.length; j++) args[j] = data[j + 4];
        return abi.decode(args, (uint256, address, address, uint256, uint256, bytes));
    }

    // Re-prove while a mature proof exists: resets only the re-prover's own timer.
    function test_reprove_resets_own_timer_only() public {
        Prove memory p = _load(0);
        address s2 = address(0x5B2);
        _mature(p.hash, p.submitter);
        PORTAL.checkWithdrawal(p.hash, p.submitter); // mature
        _reprove(p, s2);
        PORTAL.checkWithdrawal(p.hash, p.submitter); // still mature for original submitter
        _reprove(p, p.submitter); // self re-prove resets
        vm.expectRevert(bytes4(keccak256("OptimismPortal_ProofNotOldEnough()")));
        PORTAL.checkWithdrawal(p.hash, p.submitter);
    }

    // deleteProvenWithdrawal: not possible for a live/valid game; possible after Guardian blacklist (privileged setup,
    // production-reachable only via Guardian action) by anyone; re-create against another game.
    function test_delete_paths() public {
        Prove memory p = _load(40); // proven post-U21 against game still IN_PROGRESS
        (address game,) = PORTAL.provenWithdrawals(p.hash, p.submitter);
        vm.prank(ATT);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_DisputeGameNotInvalidated()")));
        PORTAL.deleteProvenWithdrawal(p.hash, p.submitter);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_Unproven()")));
        PORTAL.deleteProvenWithdrawal(p.hash, ATT);
        _mature(p.hash, p.submitter);
        vm.prank(ATT);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_DisputeGameNotInvalidated()")));
        PORTAL.deleteProvenWithdrawal(p.hash, p.submitter);

        uint256 snap = vm.snapshotState();
        vm.prank(GUARDIAN); // PRIVILEGED setup: Guardian blacklists the game
        ASR.blacklistDisputeGame(game);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_InvalidRootClaim()")));
        PORTAL.checkWithdrawal(p.hash, p.submitter);
        uint256 n = PORTAL.numProofSubmitters(p.hash);
        vm.prank(ATT);
        PORTAL.deleteProvenWithdrawal(p.hash, p.submitter);
        assertEq(PORTAL.numProofSubmitters(p.hash), n); // array untouched
        vm.expectRevert(bytes4(keccak256("OptimismPortal_Unproven()")));
        PORTAL.checkWithdrawal(p.hash, p.submitter);
        // re-prove against the same (blacklisted) game fails
        vm.prank(p.submitter);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_ImproperDisputeGame()")));
        PORTAL.proveWithdrawalTransaction(p.wd, p.gameIndex, p.orp, p.proof);
        vm.revertToState(snap);

        // finalize then delete? delete requires invalid game -> cannot delete proofs of finalized withdrawals either
        vm.prank(ATT);
        PORTAL.finalizeWithdrawalTransactionExternalProof(p.wd, p.submitter);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_DisputeGameNotInvalidated()")));
        PORTAL.deleteProvenWithdrawal(p.hash, p.submitter);
    }
}
