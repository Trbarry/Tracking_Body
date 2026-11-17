# PRIM-CF4-01 — Live legacy portal-proof tombstones

## Primitive

OP Mainnet retains immutable, non-zero legacy `ProvenWithdrawal` structs at
`keccak256(abi.encode(withdrawalHash, 52))`, while v9 proof state is a disjoint nested mapping rooted
at slot 57.

## Locked facts

- Legacy shape: `{bytes32 outputRoot; uint128 timestamp; uint128 l2OutputIndex}` at base 52
  (`op-contracts/v1.8.0`, `src/L1/OptimismPortal.sol:49-57,73-77`).
- Sample `0x90f452...f89b`, written at block 20061894, retains both original words at block 26433900;
  exact derivation and values are in `mirror/CF4/evidence/mapping-archaeology.json`.
- V9 makes slot 52 a spacer and reads `[hash][submitter]` at base 57
  (`op-contracts/v9.0.0`, `src/L1/OptimismPortal2.sol:64-67,94-116`).

## Current reachability

Negative. `deleteProvenWithdrawal` checks the nested timestamp before calling the stored game's
`status()` (`OptimismPortal2.sol:711-725`). Named fork test
`testLegacyPortalProofSlot52IsNonzeroButV9DeleteDoesNotReachIt` passes even after both exact legacy
words are overwritten with all-ones junk.

## Carry-forward edge

Any future migrator, raw-slot helper, compatibility getter, or proof-import path that reactivates
base 52 must treat its first word as an output root, never as a game address. This is a live-state
composition primitive, not a current vulnerability.
