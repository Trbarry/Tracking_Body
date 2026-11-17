# ATTACK-T4-09 — Deposit-only fallback keeps a different transaction set

Lane ATK-T4. Model: Opus 5.5 (`claude-opus-5-5`, user-approved exception; Mythos 5.2 quota exhausted until 2026-11-22). All runs are local pure computation or passive reads through :7545/:7546. Harness: `test/poc/attack-wave/T4/` (kona-client v1.7.0 = old type-9 prestate 0x031ac6f1, kona-client v1.9.0 = new prestate 0x03e5a548, each built with its own tag Cargo.lock — 0 package versions outside the tag lock; op-node = /home/user/ethereum-optimism/op-v9.0.0).

**Hypothesis.** When a block is replaced by its deposits-only version, kona (`OpAttributesWithParent::as_deposits_only`,
`protocol/src/attributes.rs:73-79`) keeps a different set from op-node (`PayloadAttributes.WithDepositsOnly`,
`op-service/eth/types.go:547-556`).

**Sequence tried.** 1,200 synthetic transaction lists (deposits, legacy, types 1-4, empty bytes, a lone 0x7e byte,
0x7d post-exec).

**Result.** 0 divergences (both keep exactly the elements whose first byte is 0x7E). Whether the fallback fires
differently is ATTACK-A-02 (no unprivileged producer of a non-payload error).

**Verdict.** KILL. Score 0.
