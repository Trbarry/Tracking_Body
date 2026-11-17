# CF2 — Release-DAG archaeologist mirror report

## Outcome

Independent Track-A reconstruction completed through Upgrade 21 at Ethereum block 26,430,859 (`2026-11-16T23:23:59Z`). No candidate was promoted: the strongest apparent inconsistencies were path/history misunderstandings and were falsified against exact receipts and source.

## Deliverables

- `mirror/CF2/RELEASE-DAG.md` — human release/state DAG, evidence map, execution matrix, per-node state ledger, audit-title index, corrections, edges and limits.
- `mirror/CF2/RELEASE-DAG.json` — 29 nodes, 30 edges, full releases/commits, chain sets, initializers, storage/role/proof changes, prestates, audit metadata and transitive edges.
- `mirror/CF2/impl-history-op-mainnet.json` — Portal, SystemConfig, AddressManager-resolved L1CDM, ChugSplash L1StandardBridge, DGF, three ASR objects, ETHLockbox and SuperchainConfig.
- `mirror/CF2/impl-history-{ink,soneium,unichain}.json` — Portal/SystemConfig block→implementation→version→transaction histories.
- `mirror/CF2/verify-release-dag.sh` — named read-only test `CF2-DAG-INTEGRITY`; PASS.

## Facts locked

- Canyon/Ecotone/Fjord use `op-contracts/v1.1.0`/`v1.2.0`/`v1.5.0` L2 code lineages but are not distinct L1 proxy transitions; Delta has no contract tag.
- OVM proxy dialect survives: current L1CDM still resolves `OVM_L1CrossDomainMessenger`; L1StandardBridge remains the original ChugSplash proxy.
- U8 is state/authority-only at end of block: SuperchainConfig remains v1.1.0 while guardian changes to `0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2`; Security Council threshold becomes 10 and L2 PAO ownership changes.
- ASR is three objects, not one continuous proxy. Granite upgrades only the U7 object; U13 and U16 replace it.
- U16a is a genuine path fork. All four targets executed U16 first, retained ETHLockbox and did not suffer a second proof invalidation.
- U18 type 8 is introduced but not respected; U19 makes it respected; U20 moves to type 9 super roots; U21 rotates type-9 prestate.
- U20 neither enables interop nor uses shared dispute infrastructure. U21 calls standard upgrades, not `migrate()`; existing valid proofs survive and all four target lockboxes already held custody, so U21 moved no ETH.
- Late tags `v2.1.0`, `v2.2.0`, `v3.0.1` are branch/tooling nodes, not chronological target-production steps.

## Primitives

- `PRIM-CF2-01`: path-conditioned ETH custody survives code-version convergence and is consumed by U21.
- `PRIM-CF2-02`: legacy proxy dialect is persistent authorization/layout state through current OPCMv2 upgrades.
- `PRIM-CF2-03`: game type + prestate + root format + creation-time respect + ASR/DGF object form a versioned proof tuple.

## Rejections / strongest negatives

- `REJ-CF2-01`: no tracked target took direct U15→U16a; exact U16 receipts precede U16a on all four.
- `REJ-CF2-02`: U21 did not blanket-invalidate proofs; `migrate()` was not called and proof deletion is validity-gated.
- `REJ-CF2-03`: Granite/U7 ASR storage is not current U21 ASR state; two later replacement proxies break that alias.

## Limits

No distinct U12 target core-proxy transaction was established. Sibling-chain histories intentionally cover only Portal/SystemConfig. Arena-Z U18a execution hashes were not reconstructed because its chain/authority/state path is disjoint. Audit report bodies and all other-worker outputs were not read.

## Next-wave edges

1. U16 lockbox create → U16a branch-preserve → U21 forced-enable/pause-identifier consume, especially on non-target direct-U15 chains.
2. U18 type-8 create → U19 respect/disable-type-0 transform → U20/U21 type-9 root/prestate transforms, with old-game finalization across Portal/ASR generations.
3. OVM proxy dialect → Bedrock ProxyAdmin adoption → OPCMv2 StorageSetter/reinitializer routing, testing every initializer offset/admin resolution branch rather than only final versions.
