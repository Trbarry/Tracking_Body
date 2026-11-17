# ATTACK-CATK-A-06 — non-consensus client changes

## Hypothesis

Bedrock deposit JSON decoding, native FPVM file-descriptor handling, or legacy simulation access
lists might alter the old fault-proof result.

## Exact sequence tried

Inspected `f07f3e0`, `b6541c7`, and `c9b441b` at file and call-site level.

## Barrier

`f07f3e0` changes host/RPC serde handling of `isSystemTx` for historical pre-Regolith system
deposits. Every fixed old game's anchor/claim window is post-Regolith and cannot reach such a block;
the guest's RLP consensus encoding is unchanged. `b6541c7` is compiled only for native
non-MIPS/non-RISC-V I/O and fixes descriptor ownership on test/error paths. `c9b441b` changes
transaction simulation setup, not canonical block execution.

## Verdict

Rejected as unreachable from the deployed fault-proof execution path. Exploitability: 0/10.

