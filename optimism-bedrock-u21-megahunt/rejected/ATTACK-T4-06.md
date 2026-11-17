# ATTACK-T4-06 — FPVM system-config reconstruction from the parent L2 block differs from op-node

Lane ATK-T4. Model: Opus 5.5 (`claude-opus-5-5`, user-approved exception; Mythos 5.2 quota exhausted until 2026-11-22). All runs are local pure computation or passive reads through :7545/:7546. Harness: `test/poc/attack-wave/T4/` (kona-client v1.7.0 = old type-9 prestate 0x031ac6f1, kona-client v1.9.0 = new prestate 0x03e5a548, each built with its own tag Cargo.lock — 0 package versions outside the tag lock; op-node = /home/user/ethereum-optimism/op-v9.0.0).

**Hypothesis.** kona's `to_system_config` (`protocol/src/utils.rs:16`, used by the FPVM L2 provider
`proof/src/l2/chain_provider.rs:235`) rebuilds a different SystemConfig (scalar, operator fee, DA footprint,
gas limit with Karst upgrade-gas strip, Jovian extraData) than op-node `PayloadToSystemConfig`
(`derive/payload_util.go:85`), changing the next block's attributes.

**Sequence tried.** 1,023 real parent blocks (header re-hashed, tx0 deposit re-encoded and hash-checked) → both kona
versions and op-node; result also compared with the config that produced canonical-identical attributes (T4-02).

**Result.** 1,023/1,023 kona7 = kona9 = op-node = canonical-validated config (`evidence/attack-wave/T4/real-sysconfig-reconstruction.txt`).
`keep_karst_upgrade_gas = true` for OP/Ink/Unichain in kona registry and superchain-registry 08d6a449.

**Verdict.** KILL. Score 0.
