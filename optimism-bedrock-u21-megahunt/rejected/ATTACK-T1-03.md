# ATTACK-T1-03 — Re-prove gate removed at v1.4.0: per-submitter records after finalization / across registries / via delete

Lane ATK-T1, Opus 5.5. Target 3 (row 3). Kill type: failing experiment on a REAL withdrawal + invariant barrier + known.

**Original safety condition.** ToB 2023-01 TOB-OPTCW-1: re-prove only if the output root changed (v1.0.0 `OptimismPortal.sol:277-280`).
Gone since v1.4.0; v9 `OptimismPortal2.sol:483-484` stores `provenWithdrawals[hash][msg.sender]`, prove never checks
`finalizedWithdrawals`. Replacement condition: per-submitter records + hash-global `finalizedWithdrawals` (:610, checked first :677).

**Sequence executed** (`T1_Games.t.sol::test_T1_10_reproveAfterFinalizeAndDelete`, `--isolate`, L1 @ 26433900): real OP Mainnet
withdrawal 0x38479d42…9218 (L2CDM -> L1CDM, 119.592959152653799482 ETH, proven by 0xb9B3…F35B against game #21359 in real tx
0x1214545b…5c0a):
1. Unprivileged attacker replays the real prove calldata: own record written, victim record and timer unchanged, submitters +1.
2. Game resolved permissionlessly (DEFENDER_WINS), warped past finality + maturity; attacker finalizes via its own record:
   finalized, lockbox delta == exactly `_tx.value`, attacker balance unchanged (funds go to the committed target).
3. Second attacker re-proves AFTER finalization (accepted: known CC25 3.1.5) -> finalize `OptimismPortal_AlreadyFinalized`;
   `checkWithdrawal(victim)` `AlreadyFinalized`; `deleteProvenWithdrawal` on both records `DisputeGameNotInvalidated`.
Records surviving registry replacement: carried through every real upgrade by F6 (`evidence/F6-carry-withdrawal-U14_V3.md`:
v1.x-era proof cell -> v9 `OptimismPortal_InvalidRootClaim`, re-prove path intact) and across the planned migrate by CATK-E-04.

**Barrier.** `finalizedWithdrawals[hash]` is hash-global and set before the call; records are keyed by submitter, so no third party
can alter or reset another's record; delete requires CHALLENGER_WINS or blacklisted (:711-723). Residual (prove after finalize,
stale `proofSubmitters`) is KNOWN Part 2 #4 -> -4. Output: `evidence/attack-wave/T1/T1_Games_09_10.out.txt`.
