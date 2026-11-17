# ATTACK-CATK-E-03 — poison migration through legacy or live DelayedWETH storage

## Hypothesis

Attacker balances, approvals, unlock cells, or residual ETH in a historical/current DelayedWETH can
alter the selected shared WETH, make migration fail, strand unrelated user funds, or break pause
coverage.

## Exact sequence tried

1. On every one of the eleven legacy OP/Unichain WETH proxies, execute deposit, approve, transfer,
   transferFrom, unlock, wait, and withdraw using only ordinary accounts.
2. Run migration under `vm.record` and inspect every legacy proxy.
3. On the two SystemConfig-live v2 proxies, deposit and unlock before migration; migrate; then wait
   and withdraw from both, including the Unichain proxy that becomes orphaned.

## Deterministic barrier

All eleven legacy proxies have zero reads and zero writes during migration. The migrator deliberately
reuses chain[0]'s live WETH and reinitializes both live proxies. User-owned mappings survive; both
proxies point at the shared lockbox and remain redeemable. Unichain's SystemConfig is then repointed
to OP's WETH without confiscating balances in its old proxy.

`DelayedWETH.sol:81-108` keys unlocks by `withdrawals[msg.sender][subAccount]` and burns only the
caller's WETH. `hold`, `recover`, and initialization remain privileged.

Evidence: `test_E03_mutateEveryLegacyWETH_allUnreadAndRedeemable` and
`test_E04_currentWETHStateSurvivesRewire_andBothWithdraw`.

## Disposition and honest score

Rejected. All reachable state is caller-owned and cannot poison migration. Score:
`+8 -5 future-only -3 no eligible impact -4 documented/caller-owned behavior = -4`.

