# ATK-T4 report — proof-program differential (kona old vs new prestate, kona vs op-node)

Model: **Opus 5.5** (`claude-opus-5-5`), per the user-approved exception in CLAUDE.md (Mythos 5.2 quota exhausted
until 2026-11-22 00:00 UTC).

Programs compared at crate level, same inputs: kona-client **v1.7.0** (old type-9 prestate `0x031ac6f1…`) and
**v1.9.0** (new prestate `0x03e5a548…`), each built with its own tag `Cargo.lock` (0 package versions outside the tag
lock; alloy 2.1.1 vs 2.4.2/2.5.0), against **op-node** from `/home/user/ethereum-optimism/op-v9.0.0` (Go, its own
functions). Real data comes from passive, rate-limited reads through :7545/:7546 (about 1,900 calls, cached). Harness:
`test/poc/attack-wave/T4/` (README has the exact commands). Evidence: `evidence/attack-wave/T4/`.

Result: **0 candidates. 11 kills.** No old≠new divergence anywhere. No kona≠op-node divergence on any input a user
can produce. Every kona≠op-node divergence on unreachable inputs is classified: 0 unexplained over 3 seeds.

| id | hypothesis | command / test | result | outcome |
|---|---|---|---|---|
| T4-E1 | consensus source differs between the tags on the derivation path | `git diff --stat` + sha256 of deposits.rs, info/variant.rs, attributes/stateful.rs, utils.rs, output_root.rs, interop/root.rs | byte-identical; only deps differ | input to T4-01 |
| T4-E2 | real OP blocks: payload attributes old vs new vs op-node vs canonical | `fetch_real.py` (1,023 blocks: game 21377 end, start, 23 heaviest-deposit epochs) → `t4-diff`×2, `t4go`, `compare.py` | 1,023/1,023 identical and equal to the canonical block (L1 info, 53 user deposits, gas limit, EIP-1559, min base fee, randao, beacon root) | KILL ATTACK-T4-01/02/04 |
| T4-E3 | user-shaped deposits (value, mint, gasLimit, isCreation, data 0..120 kB, alias, index) | `gen_synth.py` seeds 1-3, `dep:user` | 12,072 cases, 0 divergences | KILL ATTACK-T4-02 |
| T4-E4 | many deposits per epoch, interleaved non-portal/other-event logs, reverted txs | `attr:user` (0..1,500 deposits per L1 block) | 480 cases, 0 divergences | KILL ATTACK-T4-02 |
| T4-E5 | malformed deposit logs (padding, trailing words, topic high bytes, mint ≥ 2^128, offset, length, version) | `dep:none` 2,016 cases + `classify.py` | 4 real kona/op-node acceptance/value differences, all with no producer (portal emit `OptimismPortal2.sol:790-794`) | KILL ATTACK-T4-03 |
| T4-E6 | L1-info across forks (ecotone..karst ±2 blocks, 3 chains) and blob schedule (Cancun..BPO2) | `attr:none` 1,035 cases + real L1 info of 190 epochs | real all equal; divergences only on blob fee ≥ 2^128, pre-Cancun header with blob fields, Holocene activation EIP-1559 (history) | KILL ATTACK-T4-04 |
| T4-E7 | SystemConfig value space (scalar versions, operator fee, DA footprint, min base fee, gas limit) | `attr:priv` 600 cases | 143 divergences, all a padded version-0 scalar (op-node MaxUint32, kona truncation): privileged and dead post-Ecotone | KILL ATTACK-T4-05 |
| T4-E8 | FPVM system-config reconstruction from the parent block | `build_sysfrom.py`, `sysfrom` 1,023 real parents | kona7 = kona9 = op-node `PayloadToSystemConfig` = canonical-validated | KILL ATTACK-T4-06 |
| T4-E9 | receipts root of deposit and user receipts | `fetch_rcpt.py` 277 OP blocks (9,607 receipts) + 1,200 synthetic | 277/277 equal to header receiptsRoot on all three; synthetic 0 divergences | KILL ATTACK-T4-07 |
| T4-E10 | output root / super root encoding; live claims | 3,000 synthetic + 4 OP type-9 claims (incl. IN_PROGRESS old game 21377) | all equal; 4/4 recomputed claims = `rootClaim()` | KILL ATTACK-T4-08 |
| T4-E11 | deposit-only fallback filter | `donly` 1,200 cases | 0 divergences | KILL ATTACK-T4-09 |
| T4-E12 | span-batch codec on user-signed txs (derived payload txs) | `run_span.sh`: 33,754 real + 26,595 synthetic txs (legacy/155/pre-155, 2930, 1559, 7702, creates) | encodings byte-identical Go vs kona, cross-decode ok in both kona versions | KILL ATTACK-T4-10 |
| T4-E13 | embedded rollup/L1 configs for 10/57073/130/1868 | `cfg` kind | identical (regolith None ≡ 0) | KILL ATTACK-T4-11 |

Notes:
- Synthetic totals: 21,615 cases (3 seeds × 7,205) + 1,500 span cases. Corpora are deterministic from
  `real/real-cases.jsonl` + seed; the large intermediates were deleted for disk space and only the summaries were kept.
- Latent robustness differences found (not reportable, no producer): kona accepts trailing words after the opaqueData
  and op-node rejects them; op-node accepts non-zero padding and kona rejects it; kona rejects non-zero high bytes in
  the from/to topic and op-node truncates them; kona keeps only the low 128 bits of mint. kona saturates the L1 blob
  base fee at u128 while op-node computes it exactly. A padded version-0 scalar gives MaxUint32 in op-node and a
  truncated value in kona.
- Side effect outside this repository: the gitignored `op-core/superchain/superchain-configs.zip` was added to
  `/home/user/ethereum-optimism/op-v9.0.0` so op-node builds. It was rebuilt from superchain-registry 08d6a449, and
  its sha256 equals the committed pin `a94b0232…`.
- Not covered: Ink and Unichain real data (only the OP proxy is available; their configs are covered synthetically);
  interop TransitionState encoding (`proof-interop/src/pre_state.rs`), which is identical at both tags but is not a
  user input; MIPS-level execution (no L2 execution witness is served, R6).

Highest-value next experiment: none remains on the T4 surface. If the lane continues, it should run the MIPS program
itself, kona-host v1.7.0 `--native` over one old-game window with an L2 execution-witness source, because the
crate-level paths are shown equivalent and only executor-level state-transition bugs shared by both versions remain.
