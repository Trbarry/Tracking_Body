# Lane 29 fork-test result

Command:

```text
forge test --match-path test/LockboxLane29.t.sol -vvv
```

Result against the real block-N proxies and implementations:

```text
Ran 6 tests for test/LockboxLane29.t.sol:LockboxLane29Test
[PASS] test_liveAuthorizationMatricesAreDiagonalAndLockboxMatrixEmpty()
[PASS] test_realLockboxRejectsAuthorizedPortalDuringWithdrawalContext()
[PASS] test_realLockboxRejectsEOAButAuthorizedPortalCanChooseAmountWhenIdle()
[PASS] test_realOwnerAndAuthorizationGates()
[PASS] test_realPortalBlocksOnlyItselfAndItsCurrentLockbox()
[PASS] test_siblingPortalAcceptsSourcePortalAndIndependentL2Value()
Suite result: ok. 6 passed; 0 failed; 0 skipped
```

The authorized-portal impersonation tests establish trust primitives only. They do not assert
that an attacker can impersonate a portal. The withdrawal-context test changes only portal slot
50 on the ephemeral fork to the exact non-default state used during withdrawal execution.

