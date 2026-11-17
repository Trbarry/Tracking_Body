# ATTACK-A-04 — Interop consolidation / message-graph deltas in the super-root program

Lane ATK-A. Model: Opus 5.5 (user-approved exception).

**Hypothesis.** The largest semantic diff between the prestates is interop: `kona/crates/protocol/interop/src/graph.rs`
(+1363), `rules.rs`, `proof-interop/src/provider.rs` (+836), `consolidation.rs` (PRs #22827 acyclic cycle
replacement, #23276 expiry override <= 7 days, #23275 stale initiating block numbers, #23251 cache). If an L2 user can
create an executing message the old program mis-judges, the old program replaces a canonical block by a deposit-only
block (or keeps an invalid one).

**Barrier (both tags).**
- `parse_log_to_executing_message` requires `log.address == Predeploys::CROSS_L2_INBOX && topics.len()==2`
  (`kona/crates/protocol/interop/src/message.rs:158-162` at v1.7.0 and at v1.9.0).
- `0x4200…0022` is a Proxy with EIP-1967 implementation slot = 0 on OP Mainnet (`cast storage … --rpc-url :7546`),
  Ink (`rpc-gel.inkonchain.com`, block 61424742) and Unichain (`mainnet.unichain.org`, block 64174795). Calls to it
  revert, and Proxy events have other topics. No ExecutingMessage log can exist, so the message graph is empty in both
  programs.
- Registry: `interop_time` unset for chains 10/57073/130 at both tags. Each depset is a singleton
  (`registry/etc/depsets.json`); the depset diff only adds chains 91342 and 420130018.

**Verdict.** KILL (unreachable precondition: the predeploy is not deployed; only a privileged ProxyAdmin upgrade or an
interop hardfork could change it).
