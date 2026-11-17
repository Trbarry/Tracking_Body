# ATTACK-T4-02 — kona (both prestates) vs op-node disagree on a portal deposit an L1 user can emit

Lane ATK-T4. Model: Opus 5.5 (`claude-opus-5-5`, user-approved exception; Mythos 5.2 quota exhausted until 2026-11-22). All runs are local pure computation or passive reads through :7545/:7546. Harness: `test/poc/attack-wave/T4/` (kona-client v1.7.0 = old type-9 prestate 0x031ac6f1, kona-client v1.9.0 = new prestate 0x03e5a548, each built with its own tag Cargo.lock — 0 package versions outside the tag lock; op-node = /home/user/ethereum-optimism/op-v9.0.0).

**Hypothesis.** A deposit an L1 user creates through `OptimismPortal2.depositTransaction` is decoded by kona into
different L2 transaction bytes (or rejected) than op-node/op-geth, so the FPVM block differs from the canonical one.

**Input space (user-controlled, v9 portal `OptimismPortal2.sol:741-794`).** `_to` (any, 0 when creating),
`_value` (any uint256, including 2^256-1), `_gasLimit` (minimum 21000+40·len up to the 20M metering bound),
`_isCreation`, `_data` (0..120,000 bytes, zero/0xff/random), `msg.value` → mint (0..1e24 and 2^64..2^128-1),
from = sender or its alias, arbitrary L1 block hash and log index (0..2^32-1); plus attributes-level cases with
0, 1, 2, 17, 100, 400, 1500 deposits per L1 block, interleaved with the same event from non-portal addresses,
other portal events, and reverted L1 txs.

**Sequence tried.** `scripts/gen_synth.py` seeds 1-3 → `t4-diff` (v1.7.0, v1.9.0) and `t4go`
(`derive.UnmarshalDepositLogEvent`, `derive.NewFetchingAttributesBuilder(...).PreparePayloadAttributes`) →
`scripts/compare.py`. Real: 1,023 OP blocks including 190 epoch-first blocks (167 in the game windows + the 23 heaviest-deposit epochs; 53 real user deposits, all from one aliased L1 sender 0x36bde71c97b33cc4729cf772ae268934f7ab70b2 (= alias of L1 contract 0x25ace71c97b33cc4729cf772ae268934f7ab5fa1, `version()` "2.13.0", the messenger path), 3 with mint/value > 0, max 516 data bytes) compared with
the canonical block (deposit tx hashes = keccak of the derived bytes).

**Result.** `dep:user` 12,072 cases and `attr:user` 480 cases: 0 kona≠op-node (status or bytes). Real: 1,023/1,023
blocks match the canonical block in every field, all 53 user deposits hash-identical
(`evidence/attack-wave/T4/real-attributes-compare.txt`).

**Barrier.** Executed equivalence over the full user-reachable field domain.

**Verdict.** KILL. Score 0.
