# ATTACK-T4-10 — Span-batch transaction codec disagrees on a user-signed transaction

Lane ATK-T4. Model: Opus 5.5 (`claude-opus-5-5`, user-approved exception; Mythos 5.2 quota exhausted until 2026-11-22). All runs are local pure computation or passive reads through :7545/:7546. Harness: `test/poc/attack-wave/T4/` (kona-client v1.7.0 = old type-9 prestate 0x031ac6f1, kona-client v1.9.0 = new prestate 0x03e5a548, each built with its own tag Cargo.lock — 0 package versions outside the tag lock; op-node = /home/user/ethereum-optimism/op-v9.0.0).

**Hypothesis.** Users choose every field of their L2 transaction; the batcher transposes it into a span batch.
If kona (either version) rebuilds different bytes from that encoding than op-node, the FPVM executes a different
transaction (or rejects the batch) than the canonical chain.

**Sequence tried.** Per block: RPC JSON → EIP-2718 bytes (hash-checked against the node), kona
`SpanBatchTransactions::add_txs/encode/decode/full_txs`, op-node's own codec (verbatim copy of v9
`op-node/rollup/derive` + exported wrappers `go/derivecopy/zz_t4_export.go`): op-node encoding = kona encoding,
op-node decodes kona's, kona decodes op-node's, each round trip equals the input.
Real: 33,754 txs in 1,023 OP blocks (29,186 type 2, 4,558 legacy, 10 EIP-7702). Synthetic: 26,595 txs (legacy
EIP-155 and pre-EIP-155, EIP-2930, EIP-1559, EIP-7702 with 1-8 authorizations, creations, access lists, data up to
100 kB, 256-bit values).

**Result.** 1,023/1,023 and 1,500/1,500 cases pass every check, in both kona versions (`evidence/attack-wave/T4/span-real.txt`,
`evidence/attack-wave/T4/span-synthetic-seed1.txt`).

**Verdict.** KILL. Score 0.
