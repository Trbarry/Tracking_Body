# CATK-A report — old-prestate soundness

Model: Codex (GPT-5 family). Research mode: independent mirror, passive public/shared-fork reads
only; no transaction was signed or broadcast.

## Result

No promotable candidate. The exact v1.7.0→v1.9.0 differential contains two active semantic changes:
(1) the old validator overwrites a singular batch's supplied parent hash, and (2) the old driver
treats node/provider/internal execution errors as reasons to flush and derive a deposit-only block.
The first is blacklisted Kona finding 3.4.30 and requires configured-batcher data. The second has no
permissionless deterministic trigger with canonical state and a complete hash-bound oracle. All
other acceptance changes are inactive interop/Lagoon/SDM rules or non-consensus plumbing.

Candidate count: **0**. Honest candidate score: **0/12** (no passing invalid-root-to-withdrawal fork
path; no candidate file created).

## Production snapshot

At passive L1 block **26435245** (`2026-11-17T14:04:59Z`), exhaustive clock-window coverage found
**147** old-prestate type-9 games still `IN_PROGRESS`: OP **70** (remaining 144–248,256 s), Ink **7**
(13,380–235,704 s), Unichain **70** (0–248,112 s). Every one reports
`wasRespectedGameTypeWhenCreated=true`.

This corrects the lane brief's stale “no third-party old game in progress” wording. Locked-fact
wrong-root games Ink 2638 (`0x40be…42cc`) and Unichain 17586 (`0xa412…6f0e`) both still returned
status 0; they are **countered**, not claim-valid. Unichain 17586's root clock was already exhausted;
Ink 2638 retained 235,704 s. The complete 147-row ledger is in `mirror/CATK-A/LIVE-OBJECTS-CATK-A.md`.

## Experiments executed (9)

| ID | Hypothesis / command or test | Result | Disposition |
|---|---|---|---|
| E01 | Pin prestate tags with `git ls-remote`; verify merge base/range | v1.7=`64b043e…`, v1.9=`1286a88…`; old is merge base; 293 commits | basis |
| E02 | Direct tree diff of client, driver, executor, derive, interop, protocol, precompiles, OP EVM | Two active semantic deltas; grouped inactive/non-semantic changes documented | 2 killed |
| E03 | Exact-tag `cargo test -j 1 -p kona-derive test_batch_validator_next_batch_parent_hash_mismatch -- --nocapture` | 1 passed | known/batcher-only kill |
| E04 | `forge test -j 1 --match-contract CATKAOldPrestateForkTest -vvv` | 2 passed: pre-U21 old args; post-U21 new args plus immutable/respected live old clones | exposure proven, not exploit |
| E05 | `python3 scripts/scan_old_prestate.py` at block 26435245 | 147 live old games; full clocks/creators/roots/L1 heads pinned | production census |
| E06 | Independent pinned `cast call` set for Ink 2638 / Unichain 17586 | Both status 0, old prestate, respected; exact anchors/claims/roots pinned | countered wrong roots, no candidate |
| E07 | `python3 scripts/scan_deposit_gas.py` | 782 deposits decoded; zero over `2^24` | gas-cap hypothesis killed |
| E08 | Direct old/new regression check of `single.rs`, `sync.rs`, boot invariants | Known trace-extension/zero-root fixes already present and unchanged in v1.7 | known-critical hypothesis killed |
| E09 | Deployed hardfork/feature gating against each source delta | Interop off; Lagoon `1799683201`, after every game input | future/inactive hypotheses killed |

## Rejections and scores

| Rejection | Technical signal | Decisive barrier | Exploit score |
|---|---:|---|---:|
| CATK-A-01 parent overwrite | 10/10 | known finding 3.4.30; configured batcher only; no fixed-input trigger | 0/10 |
| CATK-A-02 broad error fallback | 9/10 | missing witness/provider failure is not attacker-authenticated state | 0/10 |
| CATK-A-03 interop/PostExec/SDM | 9/10 | feature/fork inactive for fixed inputs | 0/10 |
| CATK-A-04 trace/zero-root | 10/10 | fix predates old tag | 0/10 |
| CATK-A-05 deposit cap | 10/10 | both trees exempt deposits; no over-cap deposit | 0/10 |
| CATK-A-06 RPC/native/simulation | 9/10 | outside deployed consensus path or historical window | 0/10 |

## Highest-value next experiment

Run a complete, exact `kona-client/v1.7.0` FPVM replay for official OP game **21377**
(`0x675e956b1912df79108408ca524fb37810500d10`, claim timestamp 1794868743, start 1794262423,
L1 head `0x3279c570…0b82f`) with a complete oracle, and compare its terminal root/error trace against the
L2-header root and v1.9. It had the largest remaining clock (248,256 s) in the latest snapshot and
would exercise all active old-client semantics on a claim-valid fixed input.

## Evidence index

- `mirror/CATK-A/evidence/source-differential.md`
- `mirror/CATK-A/evidence/material-source.diff`
- `mirror/CATK-A/evidence/relevant-commit-range.txt`
- `mirror/CATK-A/evidence/kona-parent-hash-regression-test.txt`
- `mirror/CATK-A/evidence/forge-test.txt`
- `mirror/CATK-A/evidence/live-old-prestate-census-block-26435245.json`
- `mirror/CATK-A/evidence/deposit-gas-scan.json`

