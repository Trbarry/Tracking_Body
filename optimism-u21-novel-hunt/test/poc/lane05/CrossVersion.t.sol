// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "forge-std/Test.sol";
import "./Ifaces.sol";
import { LifecycleBase } from "./Lifecycle.t.sol";

contract CrossVersionTest is LifecycleBase {
    struct RealProof {
        WithdrawalTransaction wtx;
        uint256 gameIndex;
        OutputRootProof orp;
        bytes[] proof;
        bytes32 wh;
        address submitter;
    }

    /// Drives the real (honest, unchallenged) game to DEFENDER_WINS + finalized, as time passing would.
    function _makeValid(address g) internal {
        IGame game = IGame(g);
        if (game.status() == 0) {
            assertEq(game.claimDataLen(), 1, "unchallenged");
            uint256 t = uint256(game.createdAt()) + game.maxClockDuration() + 1;
            if (block.timestamp < t) vm.warp(t);
            game.resolveClaim(0, 0);
            game.resolve();
        }
        uint256 f = uint256(game.resolvedAt()) + ASR.disputeGameFinalityDelaySeconds() + 1;
        if (block.timestamp < f) vm.warp(f);
        assertTrue(ASR.isGameClaimValid(g), "valid");
    }

    function _load(string memory idx) internal view returns (RealProof memory p) {
        string memory j = vm.readFile("provetxs.json");
        bytes memory input = vm.parseJsonBytes(j, string.concat(".", idx, ".input"));
        bytes memory body = new bytes(input.length - 4);
        for (uint256 i; i < body.length; i++) body[i] = input[i + 4];
        (p.wtx, p.gameIndex, p.orp, p.proof) = abi.decode(body, (WithdrawalTransaction, uint256, OutputRootProof, bytes[]));
        p.wh = vm.parseJsonBytes32(j, string.concat(".", idx, ".hash"));
        p.submitter = vm.parseJsonAddress(j, string.concat(".", idx, ".submitter"));
        require(_hashWithdrawal(p.wtx) == p.wh, "hash mismatch");
    }

    /// A proof stored under v8 (portal 5.8.0, ASR 3.9.0) finalizes under v9 with identical semantics,
    /// by an arbitrary caller using the external-proof path.
    function test_v8_proof_finalizes_under_v9() public {
        RealProof memory p = _load("0");
        (address g, uint64 ts) = PORTAL.provenWithdrawals(p.wh, p.submitter);
        console.log("game/ts", g, ts);
        console.log("target/value", p.wtx.target, p.wtx.value);
        console.log("sender", p.wtx.sender);
        assertEq(IGame(g).status(), 0);
        assertFalse(ASR.isGameClaimValid(g));

        // not yet mature
        vm.expectRevert(E_NOT_OLD);
        PORTAL.checkWithdrawal(p.wh, p.submitter);
        // not deletable (valid game), by anyone
        vm.expectRevert(E_NOT_INVALIDATED);
        vm.prank(rando);
        PORTAL.deleteProvenWithdrawal(p.wh, p.submitter);

        _makeValid(g);
        if (block.timestamp < uint256(ts) + PORTAL.proofMaturityDelaySeconds() + 1) vm.warp(uint256(ts) + PORTAL.proofMaturityDelaySeconds() + 1);
        PORTAL.checkWithdrawal(p.wh, p.submitter);

        // delete still impossible at the instant the withdrawal is finalizable
        vm.expectRevert(E_NOT_INVALIDATED);
        vm.prank(rando);
        PORTAL.deleteProvenWithdrawal(p.wh, p.submitter);

        uint256 lbBefore = LOCKBOX.balance;
        vm.prank(rando);
        PORTAL.finalizeWithdrawalTransactionExternalProof(p.wtx, p.submitter);
        assertTrue(PORTAL.finalizedWithdrawals(p.wh));
        console.log("lockbox delta", lbBefore - LOCKBOX.balance);
        assertEq(lbBefore - LOCKBOX.balance, p.wtx.value);

        // proof entry survives finalization
        (g, ts) = PORTAL.provenWithdrawals(p.wh, p.submitter);
        assertTrue(ts != 0);

        // Post-finalization blacklist (guardian, documented incident response) => proof of an
        // ALREADY FINALIZED withdrawal becomes deletable; no state other than the proof slot changes.
        vm.prank(GUARDIAN);
        ASR.blacklistDisputeGame(g);
        vm.prank(rando);
        PORTAL.deleteProvenWithdrawal(p.wh, p.submitter);
        assertTrue(PORTAL.finalizedWithdrawals(p.wh));
        vm.expectRevert(E_ALREADY_FINALIZED);
        PORTAL.finalizeWithdrawalTransactionExternalProof(p.wtx, p.submitter);
    }

    /// Attacker "shadow-proves" a victim's real in-flight withdrawal against an attacker-created
    /// invalid game. Victim's entry is untouched; attacker entry is selected only if named.
    function test_shadow_proof_does_not_affect_victim() public {
        RealProof memory p = _load("0");
        (address gV, uint64 tsV) = PORTAL.provenWithdrawals(p.wh, p.submitter);

        (IGame bad, uint256 idx, OutputRootProof memory orp, bytes[] memory proof) = _createGameFor(attacker, p.wh, _nextSeq());
        vm.warp(block.timestamp + 12);
        vm.prank(attacker);
        PORTAL.proveWithdrawalTransaction(p.wtx, idx, orp, proof);

        // state delta: only attacker's slot + array push
        (address g2, uint64 ts2) = PORTAL.provenWithdrawals(p.wh, p.submitter);
        assertEq(g2, gV);
        assertEq(ts2, tsV);
        assertEq(PORTAL.numProofSubmitters(p.wh), 2);
        assertEq(PORTAL.proofSubmitters(p.wh, 0), p.submitter);
        assertEq(PORTAL.proofSubmitters(p.wh, 1), attacker);

        // attacker cannot delete the victim's proof
        vm.expectRevert(E_NOT_INVALIDATED);
        vm.prank(attacker);
        PORTAL.deleteProvenWithdrawal(p.wh, p.submitter);

        // honest challenger wins -> attacker's proof deletable by anyone; victim unaffected
        _resolveChallengerWins(bad);
        vm.prank(rando);
        PORTAL.deleteProvenWithdrawal(p.wh, attacker);
        // stale array entry remains, pointing at an empty mapping slot
        assertEq(PORTAL.numProofSubmitters(p.wh), 2);
        (address g3, uint64 ts3) = PORTAL.provenWithdrawals(p.wh, PORTAL.proofSubmitters(p.wh, 1));
        assertEq(g3, address(0));
        assertEq(ts3, 0);
        vm.expectRevert(E_UNPROVEN);
        PORTAL.checkWithdrawal(p.wh, attacker);

        _makeValid(gV);
        if (block.timestamp < uint256(tsV) + PORTAL.proofMaturityDelaySeconds() + 1) vm.warp(uint256(tsV) + PORTAL.proofMaturityDelaySeconds() + 1);
        vm.prank(rando);
        PORTAL.finalizeWithdrawalTransactionExternalProof(p.wtx, p.submitter);
        assertTrue(PORTAL.finalizedWithdrawals(p.wh));
    }

    /// Same-submitter re-prove overwrites + resets timer + pushes a duplicate array entry.
    /// Only the submitter himself can do that to his own slot.
    function test_reprove_overwrites_and_duplicates() public {
        RealProof memory p = _load("0");
        (address gV, uint64 tsV) = PORTAL.provenWithdrawals(p.wh, p.submitter);
        _makeValid(gV); // game DEFENDER_WINS + finalized
        if (block.timestamp < uint256(tsV) + 7 days - 60) vm.warp(uint256(tsV) + 7 days - 60);
        uint256 t0 = block.timestamp;
        uint256 g0 = gasleft();
        vm.prank(p.submitter);
        PORTAL.proveWithdrawalTransaction(p.wtx, p.gameIndex, p.orp, p.proof);
        console.log("re-prove gas", g0 - gasleft());
        (address g2, uint64 ts2) = PORTAL.provenWithdrawals(p.wh, p.submitter);
        assertEq(g2, gV);
        assertEq(ts2, t0);
        assertEq(PORTAL.numProofSubmitters(p.wh), 2);
        assertEq(PORTAL.proofSubmitters(p.wh, 0), PORTAL.proofSubmitters(p.wh, 1));
        vm.warp(uint256(tsV) + 7 days + 1); // original proof would have been mature now
        vm.expectRevert(E_NOT_OLD);
        PORTAL.checkWithdrawal(p.wh, p.submitter);

        // third party proving the same withdrawal against the same real game (permissionless)
        vm.prank(attacker);
        PORTAL.proveWithdrawalTransaction(p.wtx, p.gameIndex, p.orp, p.proof);
        vm.warp(t0 + 7 days + 1); // victim's re-proof is now mature, attacker's is not
        PORTAL.checkWithdrawal(p.wh, p.submitter);
        vm.expectRevert(E_NOT_OLD);
        PORTAL.checkWithdrawal(p.wh, attacker);

        // array growth: 40 more pushes; finalize gas independent of array length
        for (uint256 i; i < 40; i++) {
            vm.prank(attacker);
            PORTAL.proveWithdrawalTransaction(p.wtx, p.gameIndex, p.orp, p.proof);
        }
        assertEq(PORTAL.numProofSubmitters(p.wh), 43);
        g0 = gasleft();
        vm.prank(rando);
        PORTAL.finalizeWithdrawalTransactionExternalProof(p.wtx, p.submitter);
        console.log("finalize gas with 43 submitters", g0 - gasleft());
        assertTrue(PORTAL.finalizedWithdrawals(p.wh));
    }

    /// Contract-submitted proof (#4: submitter is a contract 0xd445...) behaves the same.
    function test_contract_submitter_real() public {
        string memory j = vm.readFile("provetxs.json");
        bytes32 wh = vm.parseJsonBytes32(j, ".4.hash");
        address sub = vm.parseJsonAddress(j, ".4.submitter");
        (address g, uint64 ts) = PORTAL.provenWithdrawals(wh, sub);
        console.log("contract submitter code size", sub.code.length, g, ts);
        vm.expectRevert(E_NOT_INVALIDATED);
        PORTAL.deleteProvenWithdrawal(wh, sub);
    }
}
