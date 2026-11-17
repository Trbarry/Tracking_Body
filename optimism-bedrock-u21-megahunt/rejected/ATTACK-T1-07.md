# ATTACK-T1-07 — try/catch around setAnchorState in closeGame starved of gas (never fixed in code)

Lane ATK-T1, Opus 5.5. Target 7 (row 16). Kill type: failing experiment on a REAL OP game, deployed bytecode, `--isolate`.

**Original condition.** IRI L-01 / U13 5.2.6: no code change; safety holds only while the callee (`setAnchorState`) is cheap
relative to the caller's tail. v9 `SuperFaultDisputeGame.sol:1022` (`FaultDisputeGame.sol:1057`): `try setAnchorState {} catch {}`
followed by `isGameProper` + SSTORE + event. Starvation needs callee cost > 63 x tail cost (63/64 rule).

**Sequence executed** (`T1_Games.t.sol::test_T1_09_closeGameAnchorStarvation`): real OP type-9 game #21359 (0xdABd…7e70, newer than
the anchor), resolved permissionlessly (DEFENDER_WINS), warped past the finality delay; binary search of the outer gas of
`closeGame()` from an unprivileged EOA (minimum non-reverting gas 128,411), then sweep [128,411, 188,411] step 100 (600 runs, each a
separate transaction with cold access lists).

**Result.** 0 outcomes where `closeGame` succeeded and the anchor did not move; bond mode NORMAL in all. The tail
(`isGameProper`: 5 external reads + SSTORE + log) is the same order of cost as the callee, so the 1/64 left after an OOG callee
can never pay it. Even if it could: `setAnchorState` is permissionless (`AnchorStateRegistry.sol:357`), so anyone re-moves the
anchor; impact = anchor liveness only (no eligible SCOPE 1.4 impact). Amsterdam constants: not active (future-only).
Output: `evidence/attack-wave/T1/T1_Games_09_10.out.txt`. Known: IRI L-01 / U13 5.2.6. Score <= 0.
