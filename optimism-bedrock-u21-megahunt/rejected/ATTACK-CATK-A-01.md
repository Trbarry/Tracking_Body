# ATTACK-CATK-A-01 — singular-batch parent-hash overwrite

## Hypothesis

The old `kona-client/v1.7.0` prestate may accept a singular batch whose parent hash the correct
derivation rejects, permitting an invalid output root to win an old-prestate type-9 game.

## Exact sequence tried

1. Pinned old/new tags to commits `64b043ea5bbc…` and `1286a886f085…`.
2. Direct-diffed the batch stream and validator.
3. Used the concrete predicate witness: supplied parent `0xaa…aa`, actual safe parent `0xbb…bb`.
   v1.7 overwrites the supplied field before validation; v1.9 preserves it and drops the batch.
4. Checked reachability from an unprivileged L1/L2 transaction and against the engagement audit
   blacklist.

## Barrier

The differing field is in batch data accepted only from the configured batcher. An ordinary user
cannot choose it. No fixed live-game input containing the malformed authorized batch was
established. Independently decisive, the root cause is already disclosed as Kona finding 3.4.30,
“Batch parent hash check will always fail”, and is blacklisted for duplicate reporting.

## Verdict

Rejected as a known, privileged-batcher-conditioned differential. No candidate and no arbitrary
withdrawal path. Technical differential confidence: 10/10; permissionless exploitability: 0/10.

