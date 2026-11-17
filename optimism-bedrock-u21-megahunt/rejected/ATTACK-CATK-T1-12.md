# ATTACK-CATK-T1-12 — proof deletion after finality/invalidation

## Hypothesis

Permissionless `deleteProvenWithdrawal` removes a mature valid proof—or a later guardian transition
makes it removable—causing incorrect/frozen withdrawal or allowing re-execution.

## Original condition and changed precondition

The former condition “finalized outputs cannot be deleted” became a timeless predicate: only
`CHALLENGER_WINS` or blacklisted records can be deleted (`OptimismPortal2.sol:707-727`). C4 examined
proofs generally; this mutation pairs a real mature valid proof with the real countered 90,000 ETH
forged proof and tests both sides of the deployed predicate.

## Exact sequence and result

From the attacker, delete f1's valid mature record: it reverts and the record remains. Then delete
f9 (game index 21,288, `CHALLENGER_WINS`): it succeeds and clears only that unusable record;
`finalizedWithdrawals[f9]` remains false. No value call is made.

## Barrier and evidence

Game status `CHALLENGER_WINS` is terminal; a valid record cannot satisfy the deletion predicate.
Regardless of proof records, the hash-global finalized bit prevents double execution
(`OptimismPortal2.sol:603-610,671-679`). Test
`test_T12_deleteProofPredicateSeparatesValidAndInvalidGames` passes at
`mirror/CATK-T1/test/FixRegressionCATKT1.t.sol:523`. Guardian-only blacklist timing and post-finalize
prove behavior are known; no current permissionless impact. No candidate.

