# ATTACK-CATK-E-06 — partial migration, retry corruption, or repeat migration

## Hypothesis

A late migration failure can leave OP and Unichain partially wired or consume deterministic proxy
addresses, and a retry/repeat can then drain or corrupt shared custody.

## Exact sequence tried

1. Supply a valid type-9 config followed by type-5 with empty `gameArgs`. Empty type-5 args pass
   preflight but fail `_makeGameArgs` in the final factory-registration loop, after the trace shows
   both per-chain migration loops.
2. Check both portals, lockboxes, INTEROP bits, balances, and Safe nonce.
3. Correct the args and retry.
4. Independently try both a direct OPCM call and a delegatecall through an attacker contract.
5. After success, call the valid migration again and compare the custom error and all shared state.

## Deterministic barrier

The late revert rolls back the entire EVM transaction: every pointer, feature bit, balance, and Safe
nonce remains at pre-call values. The corrected retry succeeds at once. After success, the permanent
INTEROP bit causes `OPContractsManagerMigrator_ChainAlreadyMigrated()` in preflight
(`OPContractsManagerMigrator.sol:305-311`), with no custody/pointer delta.
Before success, direct invocation fails the OPCM delegatecall-context check and an attacker-controlled
delegate context fails the downstream ProxyAdmin-owner checks.

Evidence: `test_E09_lateFailureRollsBackAllState_thenRetrySucceeds` and
`test_E10_repeatedMigrationRejected_stateUnchanged`.

## Disposition and honest score

Rejected. The induced bad config is privileged, the failure is atomic/retryable, and no attacker
state reaches it. Score: `+2 deterministic PoC -5 privileged-only -5 future-only -3 retryable
inconvenience -3 no eligible impact = -14`.
