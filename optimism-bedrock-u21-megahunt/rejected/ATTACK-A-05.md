# ATTACK-A-05 — Remaining v1.7.0 -> v1.9.0 deltas: SDM/post-exec (Lagoon), Bedrock deposit "decoding", std-fpvm I/O

Lane ATK-A. Model: Opus 5.5 (user-approved exception).

Commit list: `git log kona-client/v1.7.0..kona-client/v1.9.0` over `rust/kona/{bin/client,crates/proof,crates/protocol}`,
`rust/op-revm`, `rust/alloy-op-evm`, `rust/op-alloy/crates/consensus`, Cargo.lock. The shallow-history boundary commit
6c872da6 has a `rust/` tree identical to v1.7.0 (`git diff --stat kona-client/v1.7.0 6c872da6 -- rust/` is empty), so
the list is complete.

| delta | commits | barrier |
|---|---|---|
| SDM post-exec refunds, canonical PostExec entries, entry-count check, checkpointed refund policy, span-batch PostExec slots | ec1e5f23, 187bb648, 59cdf773, c3b34f1c, 49587901, 056afb5f, 9a67c34d, 378f1fe7 | Gated by `is_sdm_active` (`executor/src/builder/core.rs:179-185,292-318` @v1.7.0). No Lagoon/SDM time for chains 10/57073/130 in `registry/etc/configs.json` at either tag. A pre-SDM batch carrying a PostExec tx is dropped (`protocol/src/batch/single.rs:183` @v1.7.0). Batch content is batcher-gated anyway. |
| "fix Bedrock deposit decoding" | f07f3e06 (#22946) | Changes only the serde attribute of `TxDeposit.is_system_transaction` (JSON/RPC). The FPVM reads RLP preimages; serde is not on the proof path. Pre-Regolith is irrelevant to current games. |
| std-fpvm I/O fd handling | b6541c78 | `std-fpvm/src/io.rs` native (non-MIPS) branch only. |
| deposit gas-cap exemption relocation, FpvmOpTx `effective_gas_price` | bf4fc514, 1e5b69c7 | Executed equivalent (ATTACK-A-03). |
| driver deposit-only retry classification | c368ce97 | ATTACK-A-02. |
| span-batch parent hash | 777fc39a | ATTACK-A-01. |
| interop | 3db3be3b, 482a1099, d2646b0b, de342932, 8cf33717 | ATTACK-A-04. |
| kona-sp1, op-reth, kona-node, rpc, metrics | many | not in the cannon64-kona-interop program. |

**Verdict.** KILL (each delta is unreachable on the four chains' active configuration, or not in the program).
