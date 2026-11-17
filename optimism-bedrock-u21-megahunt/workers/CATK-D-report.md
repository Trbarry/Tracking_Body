# CATK-D report

Model: Codex (GPT-5). Lane: independent mirror of ATK-D. Result: no candidate; three deterministic rejections.

## Experiment matrix

| ID | Hypothesis / question | Command or test | Result | Disposition |
|---|---|---|---|---|
| E01 | Deployed type-9 accepts duplicate-chain trojan and real withdrawal | `test_createTrojanAndProveRealWithdrawal_deployedBytecode` | Pass | Primitive confirmed |
| E02 | Trojan can match current tooling's timestamp-recomputed output root | `test_toolingCompatibleRecentRoot_provesPersistentRealWithdrawal` | Pass at OP block 159,654,093 | Primitive confirmed |
| E03 | Attacker can overwrite unrelated submitter proof | `test_attackerProofCannotOverwriteExistingSubmitterProof` | Pass: victim slot unchanged | Kill CATK-D-02 |
| E04 | Submitter is trapped until challenger win/deletion | `test_sameSubmitterCanImmediatelyReplaceTrojanProofWithHonestGame` | Pass: immediate honest overwrite | Impact kill CATK-D-01 |
| E05 | Challenger-win deletion and re-proof lifecycle | `test_harnessStatusFlip_deleteAndReproveAgainstHonestGame` | Pass; status transition explicitly harness-only | Lifecycle model, not claimed proof execution |
| E06 | Real challenger-win proof is permissionlessly deletable | `test_liveChallengerWinsProofIsPermissionlesslyDeletable` | Pass on game 21288/f9 | Deployed lifecycle confirmed |
| E07 | Losing creator recovers/profits from root bond | `test_liveChallengerWinsRootBondIsCreditedToCounterer` | Pass: counterer credit >= 0.08 ETH | Economic kill |
| E08 | Future multi-chain shape changes portal behavior | `test_futureSharedShape_unsortedExtraChainAndDuplicateOpStillProves` | Pass, but OP-only/current impact unchanged | Kill CATK-D-03 |
| E09 | op-node rejects the full noncanonical root | `git show op-contracts/v9.0.0:op-node/withdrawals/utils.go` | Latest selection + first matching chain; only per-chain recomputation checked | Tooling exposure confirmed |
| E10 | Recommended viem flow rejects or deterministically selects | viem `2.51.0` pinned source audit | `waitToProve` random among up to 100; builder omits full-root validation | Probabilistic exposure quantified |
| E11 | Named production relayer automatically proves for users | public relayer repo + deployed Console bundle audit | Console explicitly manual/wallet-signed; no attributable automatic service | Reach claim not established |
| E12 | Real cadence, victim population, and attacker cost | passive `findLatestGames` and `eth_getLogs` scans | 1-hour median games; 487 proofs/355 hashes/9.75 d; 0.08 ETH/game | Maximum realistic reach bounded |

Aggregate fork command: `forge test -j 1 --match-path test/TrojanSuperRoot.t.sol -vvv` — 8/8 pass.

## Scoring and conclusion

Top lead CATK-D-01 scores `-5`: the strong permissionless/deployed/tooling PoC positives are outweighed by voluntary object selection, an exact known root cause, retry-only inconvenience, and no eligible impact. No `CAND-CATK-D-*` file was created.

The root mechanic is a valid hardening opportunity: clients should require a canonical chain list/full root or a claim-valid game. Under the current bounty rules, however, a genuine withdrawal bound to a losing game is not an incorrectly proven withdrawal, the submitter can escape immediately, and the attacker cannot touch another submitter's slot.

Highest-value next experiment: run the current production relayer implementation (if privately supplied) against a local fork containing one latest trojan game, and determine whether it automatically signs/submits without full-root or game-status validation. That single fact could replace the unproven production-reach assumption; absent it, further contract fuzzing does not overcome the impact barrier.
