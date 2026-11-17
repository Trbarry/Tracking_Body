# PRIM-CF4-02 — Atomic initializer-reset critical section

## Primitive

OPCM upgrades temporarily install a public arbitrary `StorageSetter`, mask the layout-derived
`_initialized` byte, restore the real implementation with `upgradeAndCall`, verify that no OZ-v5
initializer namespace was written, and restore the implementation again.

## Locked facts

- Mechanism: `op-contracts/v9.0.0`, `src/L1/opcm/OPContractsManagerUtils.sol:352-386`.
- StorageSetter permits arbitrary slot writes and is explicitly unsafe for untrusted callers
  (`src/universal/StorageSetter.sol:10-41`).
- OP Mainnet U21 transaction `0x024770...2a99` shows setter/implementation/setter/implementation
  event and call sequences; post-block initializer values are non-zero and the OZ-v5 slot is zero.
- No public block state exposes StorageSetter or a zero initializer; EVM transaction atomicity
  prevents an unrelated caller from interleaving.

## Current reachability

Negative. The current OPCM path makes no untrusted external callback while StorageSetter is the
active implementation. This is not a candidate.

## Carry-forward edge

Re-audit if a future OPCM hook, validator callback, or initializer dispatch is introduced before
the implementation is restored, or if initializer metadata can be caller-selected without layout
validation.
