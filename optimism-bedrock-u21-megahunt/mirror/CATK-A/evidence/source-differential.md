# CATK-A: Kona v1.7.0 to v1.9.0 source differential

## Provenance

- Old absolute prestate: `0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df`.
  The U20 deployment notice maps it to `kona-client/v1.7.0`.
- New absolute prestate: `0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9`.
  The U21 deployment notice maps it to `kona-client/v1.9.0`.
- `git ls-remote` independently pinned annotated tag/peeled commit pairs:
  `32e5628712eae2e1800c2a8646b58e3bbd3e9a23` / `64b043ea5bbca9bc6e57e0f1c8df0404b4cf5f68`
  and `561190400f6f6bb1352e49dc88c1930603313d35` /
  `1286a886f0853e07503b46c2d6233b6a2f623286`.
- The old commit is the merge base of the tags; the range contains 293 commits. Review used direct
  tree diffs, not commit titles alone.

## Material semantic deltas

### 1. Singular-batch parent hash (`777fc39`, PR 23071)

In v1.7.0, `rust/kona/crates/protocol/derive/src/stages/batch/batch_validator.rs:242-252`
destructures a supplied singular batch and then overwrites `next_batch.parent_hash` with the safe
parent immediately before `check_batch`. A supplied `0xaa…aa` parent and actual `0xbb…bb` parent
therefore reaches validation as `0xbb…bb`.

In v1.9.0, the overwrite is absent at `batch_validator.rs:242-251`; the supplied singular-batch
parent is checked and the mismatch is dropped. The assignment moved to
`batch_stream.rs:72-86`, where it applies only to singles synthesized from a span batch (which has
no per-block parent field). The new regression test is
`test_batch_validator_next_batch_parent_hash_mismatch`.

Kill: this is already blacklisted Kona finding 3.4.30, “Batch parent hash check will always fail”.
It also requires an L1 batch accepted from the configured batcher; an ordinary L1/L2 user cannot
supply this header field. No such trigger was established in any fixed live game input.

### 2. Execution-error classification (`c368ce9`, PR 23012)

At v1.7.0 `rust/kona/crates/proof/driver/src/core.rs:285-323`, every execution error after Holocene
flushes the channel and retries a deposit-only block. At v1.9.0 `core.rs:286-328`, only an error
that proves the payload invalid may do so. `rust/kona/crates/proof/executor/src/errors.rs:202-223`
classifies missing witnesses, trie/provider failures, database/internal errors, and a missing
executor as non-payload errors.

Concrete discriminator: a `TrieDBError::Provider("missing witness")` makes v1.7 attempt a
deposit-only replacement but makes v1.9 return the executor error. Kill: with an honest complete
oracle, canonical trie reads do not produce this error; oracle values are hash-bound, and
withholding a preimage stalls rather than authenticating a different root. No permissionless,
deterministic canonical-input path to such a provider/internal error was found.

### 3. Inactive semantics

- `3db3be3` replaces only strongly connected interop-cycle members instead of acyclic
  prerequisites; `d2646b0` rejects stale initiating block numbers before history walking;
  `de34293` caches/deduplicates the same interop validation. Current chain state has interop
  disabled and no dependency set.
- `9a67c34`, `ec1e5f2`, `4958790`, `187bb64`, `59cdf77`, `c3b34f1`, and `056afb5` alter Lagoon
  PostExec/SDM validation or refund accounting. OP, Ink, and Unichain configure Lagoon at
  `1799683201` (`2027-01-11T16:00:01Z`), later than every pinned game input and the census block.
- `482a109` caps an optional interop message-expiry override; the deployed configurations use no
  active interop dependency set.

### 4. Ruled-out apparent deltas

- `bf4fc51` relocates the deposit EIP-7825 exemption. v1.7.0 already lifts the cap in
  `rust/alloy-op-evm/src/lib.rs:344-369`; v1.9.0 performs the same exemption in
  `rust/op-revm/src/handler.rs:202-221`. This is not an old-prestate bug.
- `f07f3e0` changes host/RPC serde decoding of the JSON `isSystemTx` field. It matters to historical
  pre-Regolith system deposits, but every fixed game window is post-Regolith and cannot reach that
  historical input; the guest's RLP consensus encoding itself is unchanged.
- `b6541c7` fixes file-descriptor ownership only in native (non-MIPS/non-RISC-V) test I/O.
- `c9b441b` affects legacy-transaction simulations, not block-proof execution.
- Reth/revm bumps adapt APIs. The OP-specific active rules above are semantically retained; the
  intentional consensus changes in the direct range are the separately gated PostExec/SDM rules.

## Previously critical Kona findings

The trace-extension and zero-root fixes predate both tags. There is no v1.7.0→v1.9.0 diff in
`rust/kona/bin/client/src/single.rs` or `rust/kona/crates/proof/proof/src/sync.rs`. In the old tag,
`single.rs:58-93` calls `prepare_derivation`, rejects a claimed block before the safe head or a root
mismatch, and trace-extends only when the claim equals the real agreed root; `sync.rs:46-49` seeds
`TipCursor` with `agreed_l2_output_root`, not zero. Thus blacklist findings 3.1.1/3.1.2 are absent
from the old deployed tree.

## Runtime cross-checks

- Upstream Kona v1.9.0 regression: 1/1 passing
  (`test_batch_validator_next_batch_parent_hash_mismatch`, one-core Cargo run from the exact tag).
- Fork harness: 2/2 passing tests pin old factory arguments before U21, new arguments after U21,
  and immutable live old-prestate game clones after rotation.
- Passive census at L1 block 26435245: 147 type-9 old-prestate games remained `IN_PROGRESS` across
  OP/Ink/Unichain; the complete ledger and machine-readable calls accompany this file.
- Passive deposit scan over the two countered third-party old-game ranges: 379 Ink deposits (max
  gas 516,470) and 403 Unichain deposits (max 3,395,155), with zero above `2^24`. This is additional
  negative evidence only; both source trees already implement the exemption.

