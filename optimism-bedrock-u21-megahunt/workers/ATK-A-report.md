# ATK-A report — old-prestate soundness -> arbitrary withdrawal

Model: **Opus 5.5** (`claude-opus-5-5`), per the user-approved exception in CLAUDE.md (Mythos 5.2 quota exhausted
until 2026-11-22 00:00 UTC).

Prestate mapping (superchain-registry `validation/standard/standard-prestates.toml`): old `0x031ac6f1…` =
kona-client **1.7.0** (and 1.7.0-rc.2) `cannon64-kona-interop`, tag commit 64b043ea (2026-09-05); new `0x03e5a548…`
= kona-client **1.9.0** (= 1.9.0-rc.1), commit 1286a886 (2026-10-21). The 1.8.x interop prestate was never deployed.
Active L2 config on OP/Ink/Unichain: Karst (Osaka EVM), no Lagoon/SDM, no interop, singleton depsets.

| id | hypothesis | command / test | result | outcome |
|---|---|---|---|---|
| A-E1 | old-prestate games still decide outcomes after U21 | `census_old_prestate.py` @26435056; forge `test_oldPrestateGamesStillLiveAndRespected` | OP 70 / Ink 7 / Unichain 71 IN_PROGRESS on prestate 0x031ac6f1; window closes 1795474955 (2026-11-23 23:02 UTC) | precondition holds (LIVE-OBJECTS-A) |
| A-E2 | an EOA can still enter an old game | forge `test_unprivilegedAttackMoveOnOldGame` | attack move on OP 21377 accepted | surface live; needs program unsoundness |
| A-E3 | full program diff v1.7.0..v1.9.0 (consensus-relevant) | `git log/diff` over proof crates + Cargo.lock | 8 delta classes (see A-01..05) | — |
| A-E4 | singular batch with a wrong parent hash accepted by old (#23071) | code diff + `batch_types.py` over L1 26429059-26430859 and 26400000-26400900 | real delta, but batcher-only input; 6,754 batches decoded, all span, 0 singular | KILL ATTACK-A-01 |
| A-E5 | deposit-only fallback on any executor error (#23012) | producer search (revm-precompile 41, FPVM provider, TrieDB/oracle) | no unprivileged producer of a non-payload error | KILL ATTACK-A-02 |
| A-E6 | revm 41->43 / op-revm handler / cap-exemption move / FpvmOpTx | `revm-diff` 200,000 KARST cases | 0 divergences; negative control finds 3/3000 (exemption bypass) | KILL ATTACK-A-03 |
| A-E7 | interop graph/rules/provider deltas | message.rs address gate + `cast storage` on 0x4200..22 (OP/Ink/Unichain) | uninitialised proxy on all three; no executing message possible | KILL ATTACK-A-04 |
| A-E8 | SDM/Lagoon, serde deposit, std-fpvm I/O | code reads (`rollup.rs:271`, `single.rs:183`, io.rs cfg) | inactive or off-path | KILL ATTACK-A-05 |

Candidates: none. Not executed: the MIPS program itself (no beacon-backed kona-host plus L2 execution witness here),
so the program-level equivalence is shown per delta (code reading plus the EVM differential), not by running cannon.

Highest-value next experiment: run kona-host v1.7.0 natively (`--native`) against the 148 LIVE-OBJECTS game ranges
using an L1 beacon (publicnode works) and an L2 archive with `debug_executionWitness`, comparing each claimed super root.
That is the only remaining way the old program could diverge: a kona bug common to both versions. It would be a
current-program finding, since v1.9.0 shares kona-mpt, derivation and executor code.
