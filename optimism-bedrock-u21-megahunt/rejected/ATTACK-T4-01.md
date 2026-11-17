# ATTACK-T4-01 — Old vs new kona derive a different payload from the same user deposits / L1 data

Lane ATK-T4. Model: Opus 5.5 (`claude-opus-5-5`, user-approved exception; Mythos 5.2 quota exhausted until 2026-11-22). All runs are local pure computation or passive reads through :7545/:7546. Harness: `test/poc/attack-wave/T4/` (kona-client v1.7.0 = old type-9 prestate 0x031ac6f1, kona-client v1.9.0 = new prestate 0x03e5a548, each built with its own tag Cargo.lock — 0 package versions outside the tag lock; op-node = /home/user/ethereum-optimism/op-v9.0.0).

**Hypothesis.** kona-client v1.7.0 (old prestate, 148 IN_PROGRESS games at the census) and v1.9.0 produce different
payload attributes (L1-info tx, user deposit txs, upgrade txs, gas limit, EIP-1559 params, min base fee, randao,
beacon root) for an input an L1 user can create, so an old-prestate game could be won against the canonical root.

**Sequence tried.** Same JSONL corpus into `target7/t4-diff` and `target9/t4-diff` (crate-level:
`kona_protocol::decode_deposit`, `kona_derive::StatefulAttributesBuilder::prepare_payload_attributes`,
`L1BlockInfoTx::try_new_with_deposit_tx`, `to_system_config`, `as_deposits_only`, span-batch codec, receipts
root, output/super root). Full output compared byte-for-byte.
- Real OP Mainnet: 1,023 L2 blocks (600 ending at the claim of IN_PROGRESS old game 21377, 400 at its starting
  point, 23 epoch-first blocks of the heaviest-deposit L1 blocks in L1 26,380,000–26,430,700), 1,023 parent
  system-config reconstructions, 33,754 user txs, 277 receipt sets, 4 game claims.
- Synthetic (3 seeds, deterministic): 21,615 cases + 1,500 span cases (26,595 txs).

**Result.** 0 old≠new outputs in every case of every kind (`evidence/attack-wave/T4/synthetic-compare-seed{1,2,3}.txt`: no
`old!=new` row; `evidence/attack-wave/T4/real-*.txt`; `evidence/attack-wave/T4/span-*.txt` "kona7==kona9" = all).

**Barrier.** The consensus source on this path is byte-identical at both tags (sha256 prefixes identical:
`protocol/src/deposits.rs` a0c7f4ce, `info/variant.rs` e953dbf5, `derive/src/attributes/stateful.rs` 8d7447eb,
`protocol/src/utils.rs` 296f750a, `output_root.rs` 2a024533, `interop/src/root.rs` 1838f7b2;
`git diff --stat kona-client/v1.7.0 kona-client/v1.9.0` lists none of deposits.rs, info/*, attributes/*,
output_root.rs, hardforks, mpt). The only delta that reaches it is the dependency set (alloy 2.1.1 → 2.4.2/2.5.0,
alloy-primitives 1.6.0 → 1.7.3, alloy-eips 2.1.1 → 2.5.0), and the executed differential shows no behavioural
change on this input space. Batch-stage deltas (777fc39a, 9a67c34d) are batcher-only (ATTACK-A-01) and the
post-exec slot rule is Lagoon/post-exec-type only.

**Verdict.** KILL (executed equivalence). Score 0.
