# Lane 27 local-fork test results

Harness: `/home/user/u21-work/codex-27/h`; `l1n = http://127.0.0.1:8547`. No broadcast or shared-fork state mutation was used.

## Super-root primitives

```text
$ forge test --match-path test/SuperRootPrimitives.t.sol -vvv
[PASS] test_rootClaimBindsWholeSuperRootPreimage() (gas: 179862)
[PASS] test_type5CreationIsNotPermissionless() (gas: 130013)
[PASS] test_type9PermissionlessAndDuplicateChainIdsFirstWins() (gas: 613262)
3 passed; 0 failed
```

The type-9 test calls the real OP factory with the live bond and implementation. A `vm.store` writes only the expected zero value into the cryptographically fresh factory UUID slot to avoid the shared anvil lazily fetching an untouched archive slot; it does not bypass any nonzero state or contract check.

## Historical games

```text
$ forge test --match-path test/HistoricalGames.t.sol -vvv
[PASS] test_historicalRootMatchesCanonicalL2Header()
[PASS] test_latestType0AndType8GamesAreValidAndCanonical()
[PASS] test_oldUnsetTypeCanRemainClaimValid()
3 passed; 0 failed
```

In addition, eight evenly spaced claim-valid defender games at indices 10000, 12000, 14000, 16000, 17904, 18500, 20000 and 20094 were compared with passive `https://mainnet.optimism.io` block-header reads. Every on-chain root exactly equaled the locally computed canonical output root.

## Last 30 inventory

```text
$ forge test --match-path test/GameInventory.t.sol -vvv
[PASS] test_inventoryLast30() (gas: 914435)
1 passed; 0 failed
```

The complete decoded inventory is in `GAME_INVENTORY.md`.
