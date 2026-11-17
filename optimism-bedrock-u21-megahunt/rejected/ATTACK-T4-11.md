# ATTACK-T4-11 — Embedded rollup / L1 config differs (old kona registry vs new vs op-node)

Lane ATK-T4. Model: Opus 5.5 (`claude-opus-5-5`, user-approved exception; Mythos 5.2 quota exhausted until 2026-11-22). All runs are local pure computation or passive reads through :7545/:7546. Harness: `test/poc/attack-wave/T4/` (kona-client v1.7.0 = old type-9 prestate 0x031ac6f1, kona-client v1.9.0 = new prestate 0x03e5a548, each built with its own tag Cargo.lock — 0 package versions outside the tag lock; op-node = /home/user/ethereum-optimism/op-v9.0.0).

**Hypothesis.** The FPVM loads the rollup and L1 configs from its embedded registry (`proof/src/boot.rs:183-200`,
`proof-interop/src/boot.rs:131-163`). A fork time, deposit contract, system-config address, block time or blob
schedule different from op-node's would change derivation for every block.

**Result.** For chains 10, 57073, 130 and 1868, kona v1.7.0 = v1.9.0 = op-node v9 (superchain-registry 08d6a449,
op-geth MainnetChainConfig): identical fork times (canyon..karst; lagoon unset), `keep_karst_upgrade_gas` true,
deposit contract, system config, block time, L1 prague/osaka/bpo1/bpo2 times and blob params; BPO3-5 and Amsterdam
unset on both. Only cosmetic difference: regolith None (kona) vs 0 (op-node), equivalent because kona's
`is_regolith_active` is true whenever canyon is (`genesis/src/rollup.rs:161-163`).

**Verdict.** KILL. Score 0.
