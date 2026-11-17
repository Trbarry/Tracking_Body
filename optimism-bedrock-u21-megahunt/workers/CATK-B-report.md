# CATK-B report — historical messenger / forced failure mirror

Model: **Codex (GPT-5), CATK-B independent mirror**. Cutoff: Ethereum block 26,433,900. Result: **deterministic kill; no bounty candidate**.

Safety: no public transaction, raw transaction, state-changing public RPC, shared-fork mutation, privileged exploit caller, or leaked key was used. Network activity was passive against `:7545`; mutations occurred only inside `forge test` forks. Builds/tests ran only in `/home/user/u21-work/codex-CATK-B/h` with `-j 1`.

## Experiments (16)

| ID | Hypothesis / operation | Exact execution | Result | Decision |
|---|---|---|---|---|
| 01 | Four-chain portal failure population | `scan_logs.py withdrawal_finalized` | 907/907 ranges, 32,007 logs, 0 errors; 4 false, all OP | feed 03 |
| 02 | Four-chain messenger failure population | `scan_logs.py failed_relayed_message` | 907/907, 30 events / 22 hashes, 0 errors | feed 04 |
| 03 | False finalization leaves neither mapping | `enrich_census.py` + traces/block-1 reads | all 4 are nonce-v0 duplicates; old hash already successful | kill 01 |
| 04 | Live failed value remains in L1CDM | same enrichment at block 26,433,900 | 4 nonzero cases; all later successful; all four L1CDM balances 0 | kill 02 |
| 05 | Historical successful replay is inferred, not real | `find_value_replays.py` | exact success tx/caller for all 4; 328.23639966839066 ETH total | kill 02 |
| 06 | Real proof targets include noncommutative consumers | `classify_proves.py` over 43 PASS-A proofs | StandardBridge ETH/ERC20, app, fee vault; no ERC721 fixture | compose 13–15 |
| 07 | Replay changes auth/deadline context | `scan_target_bytecode.py` | 10 observed targets; zero `l2Sender`/portal literals; value apps use xDomain auth and no block-context opcodes | kill 04 |
| 08 | Active failures share attack-created target state | `trace_active_replays.py` | target-local legacy errors: blocked transfer, invalid token, underflow, duplicate root, proxy misuse | kill 06 |
| 09 | False portal events are new unmapped messages | `test_falsePortalFinalizationsAreLegacyV0Duplicates` | PASS | kill 01 |
| 10 | Value failures still hold/can lose ETH | `test_liveValueBearingFailuresAllSettledAndNoMessengerCustody` | PASS | kill 02 |
| 11 | Active messages depend on chronological ordering | `test_liveZeroValueFailuresChronologicalReplayOrder` | PASS; exactly 3/15 recover | kill 06 |
| 12 | Reverse ordering changes recoverability | `test_liveZeroValueFailuresReverseReplayOrder` | PASS; identical 3/15 | kill 06 |
| 13 | Forced victim failure corrupts 2,000 ETH bridge settlement | `test_realStandardBridgeVictimForcedFailedThenSettlesExactly` | primitive reproduced; arbitrary replay pays exact recipient once; attacker +0 | kill 03 |
| 14 | Forced victim failure corrupts ERC20 deposit accounting | `test_realERC20BridgeVictimForcedFailedThenSettlesExactly` | exact recipient token delta; no caller capture; atomic replay | kill 03 |
| 15 | Production app becomes irrecoverable after forced delay | `test_realApplicationVictimForcedFailedThenSettlesExactly` (363.438235322873695226 ETH) | replay succeeds, messenger custody drains, attacker +0 | kill 04 |
| 16 | ERC721 escrow is directly consumable/raceable | `test_deployedERC721BridgeRequiresMessengerAndCommittedL2Bridge` + v9 transition | attacker call reverts; unique escrow clear/transfer atomic | kill 05 |

Final fork command: `forge test -j 1 --match-path test/CATK_B.t.sol -vv` — **8 passed, 0 failed**.

## Findings and score

No candidate file was created. The closest object is the known permissionless nested-finalization primitive. Honest score: **-1**: +2 permissionless, +2 current reachability, +2 deployed-bytecode fork PoC, +1 unrelated victim, +1 repeatable, +1 cross-contract; -4 already-known same mechanic/impact, -3 retryable inconvenience, -3 no eligible impact. It deterministically moves a victim into replay state, but commits the original sender/target/value/calldata and produced no theft, freeze, miscredit, or permanent separation in ETH, ERC20, app, or ERC721 compositions.

Rejected hypotheses: `ATTACK-CATK-B-01.md` through `-06.md`. Full census: `mirror/CATK-B/LIVE-OBJECTS-CATK-B.md`.

## Highest-value next experiment

Passively decode/trace all 32,007 finalized withdrawal transactions (checkpointed, bounded concurrency) to enumerate every historical inner relay target, then scan resolved implementations for `portal.l2Sender()` or block-time gates. If any hit exists, replay an unchanged real mature fixture through the all-real carrier composition. This is the remaining population gap beyond the 43 live proofs and 22 failed-message objects.
