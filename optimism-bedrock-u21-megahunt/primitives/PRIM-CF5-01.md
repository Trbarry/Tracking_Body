# PRIM-CF5-01 — historical game registration changes permissionless reachability under identical v9 code

## Primitive

The four chains run the same `DisputeGameFactory` v1.6.1 implementation, but DGF storage retains different registered game types. At L1 block 26,433,900, OP/Ink/Unichain have type 9 at `0x19AF…` with an 0.08 ETH bond; Soneium has `gameImpls(9) == address(0)` and only bondless proposer-restricted type 5 (`mirror/CF5/evidence/pinned-cast-reads.txt:27-32,55-60,83-88,111-116`).

The v9 reader is `DisputeGameFactory.create`: implementation lookup precedes bond validation (`op-contracts/v9.0.0`, `DisputeGameFactory.sol:147-172`). Any address reaches it.

## Demonstration

Named test `ChainHistoryDifferentialTest.test_sameType9CreationCallDiffersBecauseRegistrationHistoryDiffers` sends identical valid type-9 calldata and value against both factories at block 26,433,900. OP deploys a game; Soneium reverts `NoImplementation(uint32)` (`h/test/ChainHistoryDifferential.t.sol:14-40`; `mirror/CF5/evidence/chain-history-differential-test.txt`).

## Disposition

Real behavioral differential, but intended. U20 deliberately installed type 9 on OP/Ink/Unichain and type 5 only on Soneium (`superchain-ops/src/tasks/eth/071-U20-op-ink-soneium-uni/README.md:16-30`); U21 preserved it (`eth/084-U21-op-ink-soneium-uni/README.md:16-29`). No candidate.
