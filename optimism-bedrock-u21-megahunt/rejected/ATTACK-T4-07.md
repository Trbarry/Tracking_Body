# ATTACK-T4-07 — Deposit receipts (nonce, receipt version, failed deposits) give a different receipts root

Lane ATK-T4. Model: Opus 5.5 (`claude-opus-5-5`, user-approved exception; Mythos 5.2 quota exhausted until 2026-11-22). All runs are local pure computation or passive reads through :7545/:7546. Harness: `test/poc/attack-wave/T4/` (kona-client v1.7.0 = old type-9 prestate 0x031ac6f1, kona-client v1.9.0 = new prestate 0x03e5a548, each built with its own tag Cargo.lock — 0 package versions outside the tag lock; op-node = /home/user/ethereum-optimism/op-v9.0.0).

**Hypothesis.** The receipts root kona computes (`OpReceiptEnvelope::from_parts` + `kona_mpt::ordered_trie_with_encoder`,
as `executor/src/builder/assemble.rs:185`) for user deposits differs from op-geth's, so the FPVM block hash and
output root diverge.

**Sequence tried.** Real: 277 OP blocks (9,607 receipts: 330 deposit, 1,305 legacy, 7,970 EIP-1559, 2 EIP-7702) vs the
header receiptsRoot. Synthetic: 1,200 receipt lists (deposit nonce up to 2^64-1, version 1, status 0/1, logs).

**Result.** 277/277 roots equal the header for kona v1.7.0, v1.9.0 and op-node; 1,200/1,200 synthetic equal
(`evidence/attack-wave/T4/real-receipts-and-roots.txt`). No failed deposit exists in the real sample; failed-deposit receipts are covered
synthetically.

**Verdict.** KILL. Score 0.
