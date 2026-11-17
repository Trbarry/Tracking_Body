# CATK-E migration-poisoning mirror

Independent fork harness for ATK-E. No public transaction is sent by this suite. The only privileged
state transition is the documented future OP + Unichain Safe delegatecall into deployed OPCM 9.0.3.

## Run

From `/home/user/u21-work/codex-CATK-E/h`:

```sh
forge test -j 1 --match-contract CATKEMigrationTest -vv
```

RPC alias `l1` must point to the read-only pinned fork at Ethereum block `26433900`. The complete
self-contained test is `test/CATKEMigration.t.sol`; a byte-identical evidence copy is under this
directory's `test/` subdirectory. SHA-256:
`9e32d8c2da6e4e3092d8f5ff9b97740926e88117f2b0d4639ed7260d0064e577`.

For a call trace of an individual barrier:

```sh
forge test -j 1 --match-test test_E01_moveBothGen2Anchors_migrationDoesNotReadThem -vvvv
forge test -j 1 --match-test test_E09_lateFailureRollsBackAllState_thenRetrySucceeds -vvvv
```

Toolchain used: Foundry 1.5.1-stable (`b0a9dd9c`), solc 0.8.25, Cancun EVM.

