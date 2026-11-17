# Lane 24 fork-test results

Command:

```sh
forge test --match-path test/WithdrawalFinalization24.t.sol -vv -j 1
```

Result: **17 passed, 0 failed, 0 skipped** against the deployed post-U21 proxies on a lane-private Anvil fork of block 26,433,900. Full test: `tests/WithdrawalFinalization24.t.sol`.

## Methodology boundary

Portal, Messenger, Lockbox, SystemConfig, ASR, games, and target calls use deployed bytecode/state. For arbitrary synthetic withdrawals, only the per-submitter Portal proof storage slot is installed with `vm.store`; the selected games are real finalized, registered, respected type-9 games, and deployed `checkWithdrawal` validates them. No test asserts production reachability from a mocked Merkle proof. The delete test mocks only a future game status to reach the deployed deletion branch. Real cross-version tests use untouched historical proof/message state.

The private Anvil was used solely because uncached random mapping-slot reads on the archive upstream intermittently returned HTTP 429. Zero values were preseeded at those synthetic mapping slots; no contract logic/configuration was replaced.

## Matrix

| Case | Result |
|---|---|
| Truly nonexistent EOA, 1 ETH | Delivered; finalized |
| Existing funded/code-empty account, 1 ETH | Delivered; finalized |
| Contract, zero and nonzero value | Delivered; finalized |
| Reverting direct target, 3 ETH | Target got 0; value re-locked; globally finalized; replay blocked |
| Direct target needing 260k, encoded 30k, third-party external proof | At 350k outer cap: outer success, inner failure, globally finalized |
| Same target shape, adequate outer gas | 1 ETH delivered |
| Return bomb (64 KiB) | Portal unaffected; finalized |
| L2 messenger sender → reverting non-messenger target | Whole Portal finalization reverted (sender-only rule) |
| Non-messenger sender → L1 messenger | Failed call globally finalized |
| Messenger application failure | Portal finalized; `failed=true`; later replay succeeds once |
| Messenger pre-record revert | Portal rollback; outer unfinalized; both messenger bits false |
| Two proof submitters / two games | One target execution; alternate proof blocked globally |
| Delete then recreate proof | Recreated valid record can finalize before global finalization |
| Real v8 proof at N | Same game/timestamp, unfinalized |
| Synthetic v8 failed bit → v9 successful replay | `failed=true,successful=true`; next replay blocked |
| Real v8 failed message → v9 replay | Target still rejects; failure re-recorded; replay remains available |

## Exact gas-window output

```
harmful outer gas cap: 350000
target recorded entry gas (zero means reverted): 0
```

This is PRIM-2401/REJ-2401: reproducible but explicitly documented direct-withdrawal semantics, not promoted.
