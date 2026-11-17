# Lane 32 fork-test results

Run from `/home/user/u21-work/codex-32/h` against the pinned local forks. No transaction was broadcast.

Final aggregate run: `forge test --match-path 'test/*.t.sol' -vv` — 10 passed, 0 failed (eight NegativeSpace tests, one StateDiff test, and the template sanity test).

Command: `forge test --match-path test/NegativeSpace.t.sol -vv`

Result: 8 passed, 0 failed.

- `test_allFourChains_bindPauseAndGamesToExactLiveLockbox`
- `test_configurationValidatorsCannotBeViolatedPermissionlessly`
- `test_deleteProvenWithdrawal_rejectsLiveNonInvalidatedHistoricalObject`
- `test_liveL1AndL2MessengerGasBudgetsExposeAsymmetricUpgrade`
- `test_lockboxAdministrativeSiblingsRemainProxyAdminOwnerOnly`
- `test_migrateToSharedDisputeGame_featureGateRunsBeforeAuthorization`
- `test_siblingValuePaths_unauthorizedLockAndReceiveRevert_butDonateSucceeds`
- `test_validatorZeroBalanceCanBeInvalidatedAfterValidationByForceSend`

Command: `forge test --match-path test/StateDiff.t.sol -vv`

Result: 1 passed, 0 failed. `test_exactNMinus1ToNLinearStorageDiff` compared the 33 receipt-touched proxies at blocks 26430858 and 26430859, asserted all EIP-1967 admin slots unchanged, and logged every selected implementation/linear-storage delta. The later-block broad storage scanner is deliberately a non-test helper because the shared RPC intermittently rate-limits uncached Soneium slots; later-state conclusions use bounded getter reads instead.
