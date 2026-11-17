# ATTACK-CATK-T3-02 — Dual ERC165 interfaces select different remote token identities

Model: Codex, configured by the worker brief as `gpt-daybreak-blue-latest`.

Verdict: **KILLED — deterministic legacy precedence on both domains.**

## Hypothesis

A token advertises both `ILegacyMintableERC20` and `IOptimismMintableERC20` but returns address A from `l1Token()` and
address B from `remoteToken()`. If initiation and finalization choose different interfaces, one pair could burn while
another pair mints or releases.

## Exact sequence tried

Deploy a bridge-only-burn token with both ERC165 answers true and disagreeing getters. Against deployed
L1StandardBridge, attempt B (modern identity), then A (legacy identity). Repeat with legacy-only and modern-only tokens.
The L2 fake-token test repeats the dual case against deployed L2StandardBridge.

## Barrier

`_isOptimismMintableERC20` accepts either interface, but `_isCorrectTokenPair` checks legacy support again and, if
true, compares only `l1Token()`; `remoteToken()` is used only in the `else` branch
(`op-v9.0.0/.../StandardBridge.sol:391-407`). The universal source is identical from op-contracts v2 through v9, so
both domains use the same ordering. B reverts; A burns exactly once. Single-interface controls select their only getter.

## Evidence

- PASS: `test_interfaceMatrix_dualInterfaceUsesLegacyIdentity`.
- PASS: `test_interfaceMatrix_legacyOnlyAndModernOnlyAreDisjoint`.
- PASS: `test_fakeL2Tokens_allInterfaceShapesRemainPairIsolatedOnL1`.
- `mirror/CATK-T3/evidence/source-lineage.md`.
