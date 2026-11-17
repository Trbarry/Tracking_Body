# ATTACK-CATK-E-04 — pre-position games and withdrawal proofs before migration

## Hypothesis

An attacker can create a current type-9 game and record a withdrawal proof today so that the proof
retains authority after the planned OP+Unichain migration and drains pooled ETH.

## Exact sequence tried

- Create attacker-funded type-9 games on both deployed factories.
- Build real MPT leaf proofs for fabricated OP and Unichain withdrawals and call each production
  portal's `proveWithdrawalTransaction`; confirm `provenWithdrawals` stores the game address.
- Execute the planned migration, then query shared-ASR registration and `checkWithdrawal`.

## Deterministic barrier

The proof records remain, but authority is evaluated through the portal's new shared ASR/DGF. Both
old game addresses are unregistered; `checkWithdrawal` reverts. The old factories' type-9
implementations are zeroed by `OPContractsManagerMigrator.sol:536-543`, while the fresh DGF starts at
game count zero.

The control E11 creates a new shared-DGF game, proves a withdrawal, resolves/waits, and receives
exactly 1 ETH from the pooled lockbox. Thus the kill is the old-game registration boundary, not a
generically broken migrated system.

Evidence: `test_E05_gamesAndProofsOnBothChains_doNotSurviveAuthoritySwap` and
`test_E11_postMigrationGameAndWithdrawal_payFromSharedPool`.

## Disposition and honest score

Rejected. Expected proof invalidation is explicit in the migrator documentation and produces no
eligible impact. Score: `+7 -5 future-only -4 known/documented -3 no eligible impact = -5`.

