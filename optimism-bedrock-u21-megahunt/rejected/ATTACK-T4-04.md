# ATTACK-T4-04 — L1-info deposit differs across hardfork boundaries or the L1 blob-fee schedule (BPO1/BPO2)

Lane ATK-T4. Model: Opus 5.5 (`claude-opus-5-5`, user-approved exception; Mythos 5.2 quota exhausted until 2026-11-22). All runs are local pure computation or passive reads through :7545/:7546. Harness: `test/poc/attack-wave/T4/` (kona-client v1.7.0 = old type-9 prestate 0x031ac6f1, kona-client v1.9.0 = new prestate 0x03e5a548, each built with its own tag Cargo.lock — 0 package versions outside the tag lock; op-node = /home/user/ethereum-optimism/op-v9.0.0).

**Hypothesis.** kona's L1-info tx (format Bedrock/Ecotone/Isthmus/Jovian; blob base fee from the L1 blob schedule
`registry/src/l1/mod.rs` cancun..bpo2) differs from op-node's (`L1InfoDeposit`, op-geth `MainnetChainConfig`) on
some L1 block, so every old-prestate game spanning it disputes a non-canonical L2 block.

**Sequence tried.** (a) Real: 1,023 OP blocks in the windows of old games 21308/21377 (L1 info for 190 distinct
epochs, seq 0..5) — kona v1.7.0, v1.9.0, op-node vs the canonical L1-info tx hash. (b) Synthetic: for chains
10/57073/130 and forks ecotone..karst at activation −2..+2 blocks (105 cases per seed); 240 L1-header variants per
seed with timestamps on each side of Cancun/Prague/Osaka/BPO1/BPO2 and excess blob gas 0..2^28; 24 extreme cases.
(c) Embedded configs: kona v1.7.0 = v1.9.0 = op-node for 10/57073/130/1868 (fork times, blob schedule
cancun 3/6/3338477 … bpo2 14/21/11684671, BPO3+ unset on both).

**Result.** Real: 1,023/1,023 identical to the canonical chain. Synthetic divergences only in unreachable shapes:
blob base fee ≥ 2^128 (excess blob gas ≥ ~1e9: kona saturates u128 at variant.rs:117, op-node exact big.Int or a
>2^256 marshal error); a pre-Cancun header carrying blob fields (op-node panics in CalcBlobFee); and the Holocene
activation block, where kona emits zero EIP-1559 params (genesis system/config.rs:154-176) and op-node forwards the
SystemConfig value (zero on mainnet at activation; activation is history).

**Barrier.** L1 header fields are set by L1 consensus, not by a user; reaching blob base fee 2^128 wei needs roughly
1,100 consecutive max-blob L1 blocks at exponentially rising fees (economically impossible). Fork activations are
past for all three chains (Karst 1783526401 on OP).

**Verdict.** KILL. Score 0.
