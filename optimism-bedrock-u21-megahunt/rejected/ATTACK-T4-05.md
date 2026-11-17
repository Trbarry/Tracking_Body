# ATTACK-T4-05 — Bedrock-version L1 fee scalar with non-zero padding (op-node MaxUint32 vs kona truncation)

Lane ATK-T4. Model: Opus 5.5 (`claude-opus-5-5`, user-approved exception; Mythos 5.2 quota exhausted until 2026-11-22). All runs are local pure computation or passive reads through :7545/:7546. Harness: `test/poc/attack-wave/T4/` (kona-client v1.7.0 = old type-9 prestate 0x031ac6f1, kona-client v1.9.0 = new prestate 0x03e5a548, each built with its own tag Cargo.lock — 0 package versions outside the tag lock; op-node = /home/user/ethereum-optimism/op-v9.0.0).

**Real divergence.** For a version-0 scalar with non-zero bytes 1..27, op-node sets baseFeeScalar = MaxUint32
(`op-service/eth/types.go:679-688`, spec rule), while kona takes bytes 28..32 (`info/variant.rs:76-86`).
Executed: `attr:priv` 143 of 600 cases across 3 seeds (54+39+50), every one this shape (classifier: 0 unexplained).

**Hypothesis.** The SystemConfig scalar takes this shape, so kona's L1-info tx (and L1 fee) differs from the chain.

**Barrier.** (1) Privileged: the scalar is written only by `SystemConfig.setGasConfigEcotone` (onlyOwner,
`SystemConfig.sol:379`), which encodes version 1. (2) Dead even for the owner: after Ecotone both update paths
ignore a scalar that fails the Ecotone check (kona `genesis/src/updates/gas_config.rs:60-64`, op-node
`derive/system_config.go:107-110`), so a padded version-0 value cannot enter derivation state. (3) The live scalars
are version 1 (all 1,023 real parents: `0x01…000f79c50000146b`, `evidence/attack-wave/T4/real-sysconfig-reconstruction.txt`).

**Verdict.** KILL (privileged-only and unreachable). Score −5.
