# Lane 30 verification

Harness: `/home/user/u21-work/codex-30/h`; `l1n = http://127.0.0.1:8547`; Solidity 0.8.25; Cancun execution (matching the current pinned fork, not future Amsterdam).

## Real in-flight game

Command: `forge test --match-path test/Lane30InFlight.t.sol -vv`

```text
[PASS] test_preUpgradeGameStillReferencesPreservedSingletons() (gas: 61661)
[PASS] test_realInFlightGameResolvesClosesAndPaysAfterU21() (gas: 332103)
2 passed; 0 failed; 0 skipped
```

This is not a mock game: DGF index 21377 / `0x675E956B1912Df79108408CA524fB37810500d10` was created before U21 and held 0.08 WETH at N.

## Resource metering / Lockbox ordering

Command: `forge test --match-path test/Lane30ResourceMetering.t.sol -vv`

```text
[PASS] test_directAttackerCannotEnterLockboxCallPath() (gas: 19959)
[PASS] test_invalidDepositRollsBackPreMeteringLockboxCall() (gas: 61366)
[PASS] test_validDepositLocksValueAndMetersAtomically() (gas: 124550)
3 passed; 0 failed; 0 skipped
```

Test sources in this directory are exact copies of the harness sources. No public-network transaction or state-changing RPC was used.
