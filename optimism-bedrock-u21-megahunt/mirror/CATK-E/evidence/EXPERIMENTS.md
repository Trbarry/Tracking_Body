# CATK-E experiment ledger

Fork: Ethereum `26433900`, block hash
`0xf5b501c77cfc14ad3f0ea6a0ba2a7b91b510bab4bc91de5da99b052aa257507e`.
Deployed consumer: OPCM `0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f`, version `9.0.3`.

Command:

```sh
cd /home/user/u21-work/codex-CATK-E/h
forge test -j 1 --match-contract CATKEMigrationTest -vv
```

Result: **11 passed, 0 failed, 0 skipped**. The separate sanity test also passed; full harness result
was 12/12.

| ID | Exact test | Attacker sequence | Result/disposition |
|---|---|---|---|
| E01 | `test_E01_moveBothGen2Anchors_migrationDoesNotReadThem` | Confirm current type-9 games appear claim-valid but fail the old selector; move both gen-2 anchors with finalized live type-8 games; run exact migration under `vm.record` | OP `138585637 -> 155450031`; UNI `22024228 -> 58101694`; zero gen-1/gen-2 ASR accesses; supplied root installed. Kill K01 |
| E02 | `test_E02_advanceLiveAnchor_anchorSlotNotReadByMigration` | Create attacker type-9 game, let it resolve unchallenged, wait finality, set live OP anchor, migrate | live ASR slot 2 neither read nor written; shared root unchanged; game unregistered in shared ASR. Kill K01 |
| E03 | `test_E03_mutateEveryLegacyWETH_allUnreadAndRedeemable` | On all 11 legacy WETH proxies: deposit, approve, transfer, transferFrom, unlock, withdraw; migrate under `vm.record` | all operations reachable only over attacker-owned state; all 11 have zero migration accesses and unchanged remaining balances. Kill K03 |
| E04 | `test_E04_currentWETHStateSurvivesRewire_andBothWithdraw` | Deposit/unlock in both live WETHs; migrate; withdraw from both | both proxies touched/reinitialized, storage preserved, both redeem; Unichain points to OP WETH. Kill K03 |
| E05 | `test_E05_gamesAndProofsOnBothChains_doNotSurviveAuthoritySwap` | Create type-9 games and record fabricated proofs on both current portals; migrate | records persist but games are unregistered under shared ASR; old type-9 implementations cleared; `checkWithdrawal` reverts. Kill K04 |
| E06 | `test_E06_depositDonateForceETH_conservedAndUnauthorized` | Deposit/donate/force ETH to both portals and lockboxes; migrate; attempt direct retired-lockbox calls; donate again | exactly `200810526200523469952700` wei pooled; old custody zero; EOA lock/receive/migrate calls fail; later donations only add assets. Kill K05 |
| E07 | `test_E07_gen1AndRetiredGameMutationGates` | Try gen-1 ASR updates, type-0 creation, type-5 creation as non-proposer, and factory owner setters | every call fails; types 0/1 unset and gen-1 gate requires a registered game/guardian. Kill K02 |
| E08 | `test_E08_prefundFutureProxyAddresses_noCollisionOrUnsafeRoot` | Dry-run to derive the three timestamp-specific proxy addresses; revert snapshot; pre-fund each; rerun migration | same proxies deploy; lockbox gains 101 wei surplus; ASR/DGF retain 103/107 attacker wei; supplied root unchanged. Kill K05 |
| E09 | `test_E09_lateFailureRollsBackAllState_thenRetrySucceeds` | Supply empty type-5 args: passes preflight, fails in final `_makeGameArgs` after per-chain work; then correct and retry | first transaction leaves all pointers, balances, feature bits and Safe nonce unchanged; retry succeeds. Kill K06 |
| E10 | `test_E10_repeatedMigrationRejected_stateUnchanged` | Attempt direct and rogue-delegate migration as attacker; then execute governance migration and repeat it | both attacker calls fail; repeat returns exact `OPContractsManagerMigrator_ChainAlreadyMigrated()` selector; shared pointers/custody unchanged. Kill K06 |
| E11 | `test_E11_postMigrationGameAndWithdrawal_payFromSharedPool` | Positive control: create shared game, prove OP withdrawal, resolve/wait/finalize | attacker receives exactly 1 ETH from shared lockbox; migrated withdrawal path is live. Control |

## Logged deterministic addresses at the pinned timestamp

- shared lockbox: `0x8cc1eE887517E6964Ae6C9258784ac74B7E73FCA`
- shared ASR: `0x8A8053d2ea2De277519b2d5C9684231e471B0C34`
- shared DGF: `0x52006e78ADE25f53fE21c5a04Cf6662cc8E5b16d`
- attacker-selected live anchor control game: `0x21a90d5c641d14c777F8B4dC466fF67E608F9C54`
- pre-positioned OP/Unichain proof games:
  `0xAed76fEff415C94e03f60A46E1d871A7DAaBbF8E`,
  `0xB73F90Dc45Def1A91D34e63771F65055F481a438`

No candidate met score 7. No candidate file was created.

