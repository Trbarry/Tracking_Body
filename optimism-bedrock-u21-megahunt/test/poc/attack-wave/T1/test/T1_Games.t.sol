// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./T1Base.sol";

/// Targets 3 (row 3) and 7 (row 16) on a REAL OP Mainnet type-9 game and a REAL user withdrawal proven on it.
/// Run with --isolate so every attacker call is its own transaction (cold access lists, real 63/64 behaviour).
contract T1_Games is T1Base {
    address attacker2 = makeAddr("t1-attacker-2");

    struct Pick {
        WT w;
        uint256 idx;
        ORP orp;
        bytes[] proof;
        address prover;
        address game;
    }

    function setUp() public {
        vm.createSelectFork("l1");
        assertEq(block.number, 26433900);
        _load();
    }

    function _slice4(bytes memory b) internal pure returns (bytes memory o) {
        o = new bytes(b.length - 4);
        for (uint256 i; i < o.length; i++) o[i] = b[i + 4];
    }

    /// First real prove (PASS A lane04 proves.json, 43 real OP Mainnet prove txs) whose game is still an
    /// unchallenged IN_PROGRESS type-9 game newer than the anchor and whose withdrawal is not finalized.
    function _pick() internal view returns (Pick memory pk) {
        string memory js = vm.readFile("fixtures/proves.json");
        (, uint256 anchorSeq) = IASR(asr[0]).getAnchorRoot();
        for (uint256 i; i < 43; i++) {
            bytes memory input = vm.parseJsonBytes(js, string.concat(".txs[", vm.toString(i), "].input"));
            (WT memory w, uint256 idx, ORP memory orp, bytes[] memory proof) = abi.decode(_slice4(input), (WT, uint256, ORP, bytes[]));
            (,, address g) = IDGF(dgf[0]).gameAtIndex(idx);
            if (IGame(g).status() != 0 || IGame(g).claimDataLen() != 1) continue;
            if (IGame(g).gameType() != 9 || IGame(g).l2SequenceNumber() <= anchorSeq) continue;
            if (IPortal(portal[0]).finalizedWithdrawals(_hash(w))) continue;
            pk = Pick(w, idx, orp, proof, vm.parseJsonAddress(js, string.concat(".txs[", vm.toString(i), "].from")), g);
            return pk;
        }
        revert("no suitable real prove");
    }

    function _resolve(IGame g) internal {
        vm.warp(uint256(g.createdAt()) + uint256(g.maxClockDuration()) + 1);
        vm.prank(attacker, attacker);
        g.resolveClaim(0, 0);
        vm.prank(attacker, attacker);
        assertEq(g.resolve(), 2, "DEFENDER_WINS");
    }

    /// T1-09 (target 7): closeGame's try/catch around setAnchorState cannot be starved on deployed bytecode:
    /// at every outer gas value where closeGame does not revert, the anchor moved to this game.
    function test_T1_09_closeGameAnchorStarvation() public {
        Pick memory pk = _pick();
        IGame g = IGame(pk.game);
        IASR A = IASR(asr[0]);
        console.log("game idx", pk.idx, pk.game);
        _resolve(g);
        vm.warp(uint256(g.resolvedAt()) + A.disputeGameFinalityDelaySeconds() + 1);
        assertTrue(A.isGameFinalized(address(g)));
        assertTrue(A.isGameClaimValid(address(g)));
        address oldAnchor = A.anchorGame();

        uint256 lo = 20_000;
        uint256 hi = 3_000_000;
        uint256 snap = vm.snapshotState();
        while (lo + 1 < hi) {
            uint256 mid = (lo + hi) / 2;
            vm.prank(attacker, attacker);
            (bool ok,) = address(g).call{ gas: mid }(abi.encodeCall(IGame.closeGame, ()));
            vm.revertToState(snap);
            snap = vm.snapshotState();
            if (ok) hi = mid;
            else lo = mid;
        }
        console.log("min non-reverting closeGame gas", hi);
        uint256 starved;
        for (uint256 gas = hi; gas < hi + 60_000; gas += 100) {
            vm.prank(attacker, attacker);
            (bool ok,) = address(g).call{ gas: gas }(abi.encodeCall(IGame.closeGame, ()));
            if (ok) {
                if (A.anchorGame() != address(g)) starved++;
                assertEq(g.bondDistributionMode(), 1, "NORMAL");
            }
            vm.revertToState(snap);
            snap = vm.snapshotState();
        }
        console.log("starved (closed, anchor not moved) outcomes in band:", starved);
        // recoverability regardless: anyone can move the anchor directly afterwards
        vm.prank(attacker, attacker);
        g.closeGame();
        assertEq(A.anchorGame(), address(g));
        assertTrue(A.anchorGame() != oldAnchor);
        assertEq(starved, 0, "no starvation window");
    }

    /// T1-10 (target 3): per-submitter re-prove by a third party on a REAL user withdrawal, finalize via the
    /// third party's record, re-prove after finalization, delete attempts. Value reaches only the committed target.
    function test_T1_10_reproveAfterFinalizeAndDelete() public {
        Pick memory pk = _pick();
        IPortal p = IPortal(portal[0]);
        bytes32 h = _hash(pk.w);
        console.log("real withdrawal hash / prover / value");
        console.logBytes32(h);
        console.log(pk.prover, pk.w.value);
        (address vg, uint64 vts) = p.provenWithdrawals(h, pk.prover);
        assertEq(vg, pk.game, "victim proof on chain");
        uint256 n0 = p.numProofSubmitters(h);

        // third party re-proves the same withdrawal against the same game: own record only
        vm.warp(block.timestamp + 1);
        vm.prank(attacker, attacker);
        p.proveWithdrawalTransaction(pk.w, pk.idx, pk.orp, pk.proof);
        (address ag, uint64 ats) = p.provenWithdrawals(h, attacker);
        assertEq(ag, pk.game);
        (address vg2, uint64 vts2) = p.provenWithdrawals(h, pk.prover);
        assertEq(vg2, vg);
        assertEq(vts2, vts, "victim timer untouched");
        assertEq(p.numProofSubmitters(h), n0 + 1);

        IGame g = IGame(pk.game);
        _resolve(g);
        uint256 t = uint256(ats) + p.proofMaturityDelaySeconds() + 1;
        uint256 t2 = uint256(g.resolvedAt()) + IASR(asr[0]).disputeGameFinalityDelaySeconds() + 1;
        vm.warp(t > t2 ? t : t2);

        uint256 attBal = attacker.balance;
        uint256 lbBal = lockbox[0].balance;
        vm.prank(attacker, attacker);
        p.finalizeWithdrawalTransactionExternalProof(pk.w, attacker);
        assertTrue(p.finalizedWithdrawals(h));
        assertEq(attacker.balance, attBal, "finalizer gains nothing");
        assertEq(lbBal - lockbox[0].balance, pk.w.value, "exactly the committed value left the lockbox");

        // re-prove after finalization is accepted (known, CC25 3.1.5) but cannot finalize again
        vm.prank(attacker2, attacker2);
        p.proveWithdrawalTransaction(pk.w, pk.idx, pk.orp, pk.proof);
        vm.warp(block.timestamp + p.proofMaturityDelaySeconds() + 1);
        vm.prank(attacker2, attacker2);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_AlreadyFinalized()")));
        p.finalizeWithdrawalTransactionExternalProof(pk.w, attacker2);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_AlreadyFinalized()")));
        p.checkWithdrawal(h, pk.prover);
        // permissionless delete of any record of this hash: refused (game not invalidated)
        vm.prank(attacker, attacker);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_DisputeGameNotInvalidated()")));
        p.deleteProvenWithdrawal(h, pk.prover);
        vm.prank(attacker, attacker);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_DisputeGameNotInvalidated()")));
        p.deleteProvenWithdrawal(h, attacker2);
        console.log("finalized once; re-prove accepted; second finalize AlreadyFinalized; deletes refused");
    }
}
