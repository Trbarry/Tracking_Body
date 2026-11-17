# CATK-C final test results

Command:

```bash
cd /home/user/u21-work/codex-CATK-C/h
forge test -j 1 --match-path test/GasCapCATKC.t.sol -vv
```

Result: **9 passed, 0 failed, 0 skipped**. Solidity 0.8.25; optimizer enabled; Cancun EVM. Final runtime was 4.15 seconds after compilation/cache warm-up. `forge fmt --check test/GasCapCATKC.t.sol` also passed.

| Test | Deterministic observation |
|---|---|
| `test_liveConstantsAndL2AcceptsExtremeMetadata` | Live versions/constants match; uint32-max metadata accepted; withdrawal gas limit `4,363,451,539` |
| `test_largeZeroPayloadRejectedByL2TransactionCap` | 400,000-byte zero message fails within capped L2 entry gas; calldata floor only `4,023,160`; `B=16,031,400` |
| `test_largeCalldataBracketsL2LimitAndStillFitsDirectReplay` | 379,200-byte word edge fits L2; 379,232 fails; 379,200 direct replay is gas-feasible; L1 replay floor `3,816,390` |
| `test_capEdges_MinGas_ForcedFailureAlwaysHasCheaperReplay` | portal deliver max `15,382,429`; portal finalize max `15,510,449`; direct max `15,981,628`; actual portal-created failure at `15,382,430` replayed next tx |
| `test_largePayloadPortalBarrierIsBeforeDirectReplayBarrier` | 379,200-byte withdrawal cannot finalize; replay gas fits if failed state exists |
| `test_portalPayloadEdgeIsExecutionBoundAndBelowL2Edge` | word-aligned portal delivery edge `323,168`; `323,200` unfinalized with floor `3,260,880`; direct gas fits |
| `test_emptyValueNewAccountAndDeployedBridgeTargets` | empty EOA, existing-account value, new-account value, and deployed L1StandardBridge ETH finalization all deliver on direct replay |
| `test_newAccountReserveOnlyShrinksSelfChosenDirectWithdrawalBand` | existing-target direct-withdrawal max `16,053,187`; new-account max `15,870,005`; measured penalty `183,182` |
| `test_gasBurningTargetRecordsReplayableFailureNotLostState` | portal records failure and direct retry records failure again; no neither-mapping/lost state |

`vm.store` proof fabrication is only a reachability vehicle; portal, messenger, and bridge gas behavior is deployed bytecode. In the core forced-failure/replay sequence, the portal creates `failedMessages` naturally before the direct replay.
