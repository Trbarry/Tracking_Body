# ATTACK-A-01 — Holocene singular-batch parent-hash check missing in the OLD prestate (kona-client v1.7.0)

Lane ATK-A. Model: Opus 5.5 (user-approved exception, Mythos 5.2 quota exhausted until 2026-11-22).

**Hypothesis.** Old program (prestate `0x031ac6f1…`, kona-client/v1.7.0, commit 64b043ea) derives a different L2
chain than op-node, so an IN_PROGRESS old-prestate game can be won against the canonical root.

**Real semantic delta (unambiguous).** PR #23071 / commit `777fc39a` "kona-derive: Set the span batch parent hash in
BatchStream". At v1.7.0 `rust/kona/crates/protocol/derive/src/stages/batch/batch_validator.rs` did
`next_batch.parent_hash = parent.block_info.hash;` on EVERY batch before `check_batch`, so for a genuine singular
(type 0) batch the Holocene `parent_hash != safe head` drop never fires (op-node drops it). v1.9.0 sets the hash only
for span-derived batches, in `batch_stream.rs::get_single_batch`. Span-derived batches get the same hash in both
versions (same `parent` object), and the span `parent_check` is checked in `check_batch_holocene` in both.

**Sequence that would be needed.** (1) a type-0 batch for timestamp T, with a wrong parent hash and an otherwise valid
epoch and timestamp, framed in a channel sent to the batch inbox by the authorised batcher; (2) its L2 block inside the
range of an IN_PROGRESS old-prestate game; (3) attacker bisects to that block, and the old VM step accepts the
non-canonical block.

**Barrier.**
1. Privileged-only input: derivation accepts frames only from `SystemConfig.batcherHash` (OP `0x6887…2985`, Ink
   `0x6db6…6b98`, Unichain `0x9ef6…00d1` at 26435056, `cast call batcherHash()`). An unprivileged attacker cannot
   introduce a batch. The scenario needs an operator mistake, which SCOPE excludes.
2. No production object: all three batchers post span batches only. Decoded, executed:
   `test/poc/attack-wave/A/batch_types.py` (blobs from a public beacon API, then frames, channels, brotli/zlib, RLP):
   - L1 26429059–26430859 (6 h before U21): 186 + 94 + 43 channels, **4,574 batches, all type 1, 0 type 0, 0
     non-batcher senders, 0 decode errors** (`evidence/attack-wave/A/batch-types-26429059-26430859.json`).
   - L1 26400000–26400900 (inside the ranges of the oldest IN_PROGRESS games): **2,180 batches, all type 1**
     (`batch-types-26400000-26400900.json`).
   Under span-only batching, v1.7.0 and v1.9.0 derive identically.

**Verdict.** KILL (privileged precondition, no live object). Reopen only if a type-0 batch from the batcher is found
inside the L2 range of an IN_PROGRESS old-prestate game before 1795474955.
