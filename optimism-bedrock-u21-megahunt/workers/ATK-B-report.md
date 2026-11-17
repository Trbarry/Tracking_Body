# ATK-B report — historical messenger failure / third-party forced failure
Model: Opus 5.5 (`claude-opus-5-5`), per the user-approved CLAUDE.md exception (Mythos 5.2 quota exhausted until 2026-11-22).
Result: **0 candidates, 6 deterministic kills.** Tests: `test/poc/attack-wave/B/` (5/5 PASS, `evidence/attack-wave/B/forge-ATKB-output.txt`).

| id | hypothesis | command / test | result | kill / candidate |
|---|---|---|---|---|
| X1 | population census, 4 chains, Bedrock..26,433,900 (WF false + FRM) | `evidence/attack-wave/B/scan.py` + `decode.py` | 34 logs: 30 FRM (22 hashes: OP 18, Ink 3), 4 WF(false) (OP); Soneium/Unichain none | census -> LIVE-OBJECTS-B.md |
| X2 | pending value-bearing failed messages unbacked (L1CDM pool 0) | census + balances + `test_E1_census_replay_stillFailed_underV9` | 4 value failures (128.2 ETH total) all delivered; 15 pending all value 0; v9 replay: 3 deliver, 12 fail target-side | KILL ATTACK-B-01 |
| X3 | historical finalized-unknown-to-messenger with value (A-068) | trace + v0/v1 hash reads | 4 = already-relayed legacy v0 withdrawals, ETH relocked | KILL ATTACK-B-02 |
| X4 | forced fail + same-pair reorder breaks ERC20 accounting | `test_E2_forcedFail_ERC20_ordering_and_replay_blocking` | exact payout, deposits exact | KILL ATTACK-B-03 |
| X5 | third party blocks replay forever (low gas, nested replay, re-finalize) | `test_E2` (attempts 1-3) | always still failed + replayable | KILL ATTACK-B-04 |
| X6 | starvation band gate-pass/target-fail | `test_E3_replay_gas_sweep_no_starvation_band` (501 gas values) | monotone, threshold 412k, 0 failures above | KILL ATTACK-B-04 |
| X7 | capture parked ETH (value replay, re-encoded value, redirect) | `test_E4_parked_ETH_not_capturable` | 3 reverts, victim paid exactly | KILL ATTACK-B-05 |
| X8 | planned migrate between fail and replay strands value | `test_E5_forcedFail_then_migrate_then_replay` | both replays deliver post-migrate | KILL ATTACK-B-06 |
| X9 | real targets depend on portal.l2Sender() in the delivery tx | bytecode PUSH4 scan of 7 real targets + impls | none; all use xDomainMessageSender | KILL (in ATTACK-B-06) |

Base mechanic (nested finalize inside an own replay => victim failed, value parked in L1CDM) re-proven on v9 in
every test; it is KNOWN (Trust M-1, KNOWN-FINDINGS Part 2 item 1) and only a retryable delay within OP contracts.

Highest-value next experiment: price the delay itself against third-party L1 targets that are deadline/round-bound
(e.g. Hop `confirmTransferRoot`, Synthetix bridge, 0x23CA5E53 router carrying 638 ETH in flight): force-fail one of
their real mature messages on a fork and replay after their deadline. Impact would land on third-party contracts,
so check SCOPE.md 1.4 eligibility before spending on it.
