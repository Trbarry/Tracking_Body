# PRIM-CF2-01 — Path-conditioned ETH custody survives maintenance

## Primitive

An OPCM maintenance release can converge code versions while preserving a branch bit with security-critical state semantics. Here the branch is whether `ETH_LOCKBOX` was created/enabled and Portal liquidity migrated before U16a.

## Three-hop edge

- Create at U16: `op-contracts/v4.0.0` creates an ETHLockbox, initializes it with the Portal, points the Portal at it, and calls `migrateLiquidity()` (`OPContractsManager.sol:711-736` at commit `54c19f6acb7a6d3505f884bae601733d3d54a3a6`).
- Transform at U16a: U16→U16a retains/wires the lockbox; direct U15→U16a intentionally does not adopt it (`docs/public-docs/notices/archive/upgrade-16a.mdx:23-44` at develop commit `e5423ae69b154100a77361d74eb6d7170b2c34aa`).
- Consume at U21: standard upgrade forces the feature, requires a nonzero lockbox, and migrates liquidity only if the old Portal was not already using it (`OPContractsManagerV2.sol:860-897` at `op-contracts/v9.0.0`).

## Locked target facts

OP, Ink, Soneium and Unichain all executed U16 before U16a, then U21. U21's executed task states all four already had lockboxes and no ETH moved (`superchain-ops/src/tasks/eth/084-U21-op-ink-soneium-uni/README.md:33-35` at `903cefaa0f07738a81f6473a9adc5c3d7161e5a8`). Exact receipts are validated by `CF2-DAG-INTEGRITY`; proxy paths are in the four `impl-history-*.json` files.

## Audit use

For every future OPCM transition, classify the incoming path by feature/custody state—not only by implementation version. Verify Portal balance, lockbox authorization, feature bit, pause identifier, and initializer arguments for every allowed predecessor. A version-only upgrade gate is insufficient when same-version chains can have different custody history.

## Outcome

Mechanism established; no target-chain exploit found. The target set was homogeneous on the lockbox-backed branch at U21.
