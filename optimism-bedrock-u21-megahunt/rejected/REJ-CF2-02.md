# REJ-CF2-02 — Upgrade 21 blanket-invalidated existing withdrawal proofs

## Hypothesis

`op-contracts/v9.0.0` contains a one-way `OPContractsManagerV2.migrate()` that explicitly invalidates all earlier withdrawal proofs. The U21 transaction might have invoked that path while being described generically as an interop-readiness upgrade.

## Falsification

- Source distinguishes ordinary `upgrade()` from one-off migration: `OPContractsManagerV2.sol:239-307` at `op-contracts/v9.0.0`.
- The executed task calls one `upgradeSuperchain` and one ordinary `upgrade` per chain, not `migrate` (`superchain-ops/src/tasks/eth/084-U21-op-ink-soneium-uni/README.md:7-14`).
- The U21 notice states migration is not called and valid-game proofs are unaffected (`docs/public-docs/notices/upgrade-21.mdx:57-75`).
- `deleteProvenWithdrawal` can delete only proofs whose game is challenger-won or blacklisted (`OptimismPortal2.sol:707-727` at v9.0.0).
- The exact all-target receipt is block 26,430,859, tx `0x024770b5fba87683ee1466562eefb1bcb408c29c764e24abd07c7d4050a82a99`, validated by `CF2-DAG-INTEGRITY`.

## Disposition

Rejected. U21 rotates implementations/prestate while preserving existing valid proofs. A future governance call to `migrate()` remains a distinct proof-invalidating boundary.
