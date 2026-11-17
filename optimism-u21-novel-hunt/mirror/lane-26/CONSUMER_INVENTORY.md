# Lane 26 — production consumer inventory

Pinned v9 root: `/home/user/ethereum-optimism/op-v9.0.0` at `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`. Interfaces, tests, deployment scripts, and pure library declarations are omitted; validators and operational modules are included. “Runtime” means a user/Guardian execution path; “management” means deploy/upgrade/migrate/validation.

## `isFeatureEnabled` / `isCustomGasToken`

| Reader | Time | Use and transition consequence |
|---|---|---|
| OptimismPortal2 (`src/L1/OptimismPortal2.sol:406-409,586-589,752-759,804-842`) | Runtime | E selects lock/unlock use; C rejects native-value prove/finalize/deposit; I+E gates Portal shared migration. Values are live, not snapshotted per deposit/proof. |
| SystemConfig (`src/L1/SystemConfig.sol:528-568,584-588`) | Runtime setter/getter | Enforces E/I one-way rules and exposes C. |
| OPContractsManagerV2 (`src/L1/opcm/OPContractsManagerV2.sol:860-896,998-1008`) | Management | Detects old E/custody, enables E, skips liquidity migration for C, and permits initial C only. |
| OPContractsManagerMigrator (`src/L1/opcm/OPContractsManagerMigrator.sol:287-327,483-513`) | Management | I is the re-migration guard; C is rejected; E is enabled if necessary. |
| OPContractsManagerMigrationValidator (`src/L1/opcm/OPContractsManagerMigrationValidator.sol:480-525`) | Validation | Requires migrated I/E and consistent shared configuration. |
| OPContractsManagerStandardValidator (`src/L1/OPContractsManagerStandardValidator.sol:441-457,948-959`) | Validation | Requires E and selects interop/shared validation shape from I. |
| L2ContractsManager (`src/L2/L2ContractsManager.sol:170-195,403-428`) | L2 management | Reads separate L2 C/I state when choosing implementations/predeploys. |
| L1BlockCGT (`src/L2/L1BlockCGT.sol:25-28`) | L2 runtime | Exposes separate L2 C flag. |
| L2ToL1MessagePasserCGT (`src/L2/L2ToL1MessagePasserCGT.sol:26-35`) | L2 runtime | Rejects native-value withdrawal using current L2 C flag. |

## `paused()` / Superchain pause reads

| Reader | Time | Resolver or effect |
|---|---|---|
| ETHLockbox (`src/L1/ETHLockbox.sol:111-114,153-175`) | Runtime | Local-or-global pause keyed by current lockbox; blocks unlock only. |
| OptimismPortal2 (`src/L1/OptimismPortal2.sol:305-307,390-409,577-589,824-828`) | Runtime | Reads cached lockbox; blocks prove/finalize. |
| SystemConfig (`src/L1/SystemConfig.sol:570-576`) | Runtime | Follows configured Portal's current lockbox. |
| AnchorStateRegistry (`src/dispute/AnchorStateRegistry.sol:135-143,286-305`) | Runtime | Reads cached lockbox and makes games improper while paused. |
| DelayedWETH (`src/dispute/DelayedWETH.sol:72-75,98-108`) | Runtime | Reads cached lockbox and blocks underlying withdrawal. |
| L1CrossDomainMessenger (`src/L1/L1CrossDomainMessenger.sol:98-105`; `src/universal/CrossDomainMessenger.sol:209-223`) | Runtime | Delegates to cached SystemConfig; blocks relay. |
| L1StandardBridge (`src/L1/L1StandardBridge.sol:122-129,239-299`) | Runtime | Delegates to SystemConfig; blocks finalization. |
| L1ERC721Bridge (`src/L1/L1ERC721Bridge.sol:68-75,90-105`) | Runtime | Delegates to SystemConfig; blocks finalization. |
| FaultDisputeGame (`src/dispute/FaultDisputeGame.sol:974-1040`) | Runtime | Blocks closing an open game; closed-mode return precedes pause. Value claim still terminates at paused WETH. |
| SuperFaultDisputeGame (`src/dispute/SuperFaultDisputeGame.sol:940-1005`) | Runtime | Pause precedes even the closed-mode return. |
| ZKDisputeGame (`src/dispute/zk/ZKDisputeGame.sol:642-716`) | Runtime | Same closed-game bookkeeping nuance as legacy Fault; WETH blocks value. |
| OPContractsManagerMigrator (`src/L1/opcm/OPContractsManagerMigrator.sol:494-500`) | Management | Refuses current chain pause before switching lockbox. |
| MigrationValidator (`src/L1/opcm/OPContractsManagerMigrationValidator.sol:556-575`) | Validation | Confirms old Portal/lockbox identifiers are not paused. |
| StandardValidatorUtils (`src/L1/opcm/StandardValidatorUtils.sol:131-145`) | Validation | Checks global Superchain pause and Portal configuration. |
| DeputyPauseModule (`src/safe/DeputyPauseModule.sol:120-181`) | Operations | Reads SuperchainConfig and ensures a requested identifier actually became paused. |

## `superchainConfig()`

| Reader | Time | Assumption |
|---|---|---|
| Portal / ASR / DelayedWETH (`src/L1/OptimismPortal2.sol:320-329`; `src/dispute/AnchorStateRegistry.sol:140-143`; `src/dispute/DelayedWETH.sol:72-75`) | Runtime getter | Resolve through cached lockbox, not a separately cached SuperchainConfig. |
| L1CDM / both bridges (`src/L1/L1CrossDomainMessenger.sol:98-105`; `src/L1/L1StandardBridge.sol:122-129`; `src/L1/L1ERC721Bridge.sol:68-75`) | Runtime getter | Return cached SystemConfig's value. Pause itself follows SystemConfig -> Portal -> lockbox. |
| ETHLockbox authorization (`src/L1/ETHLockbox.sol:218-234`) | Management | Requires a Portal's SystemConfig to name the same SuperchainConfig. |
| OPCMv2 (`src/L1/opcm/OPContractsManagerV2.sol:817-820,884-896`) | Management | Requires current SuperchainConfig implementation version and initializes lockbox from SystemConfig. |
| Migrator (`src/L1/opcm/OPContractsManagerMigrator.sol:287-327,432-466`) | Management | Requires one SuperchainConfig across the set and preserves it during SystemConfig reinit. |
| Migration/standard validators (`src/L1/opcm/OPContractsManagerMigrationValidator.sol:454-525`; `src/L1/OPContractsManagerStandardValidator.sol:297-309,441-457`) | Validation | Assert shared and per-chain wiring. |

## `l2ChainId()`

| Reader | Time | Assumption |
|---|---|---|
| OptimismPortal2 (`src/L1/OptimismPortal2.sol:437-445`) | Proof execution | Selects a chain-specific root from a super game using the current SystemConfig ID. |
| OPCMv2 (`src/L1/opcm/OPContractsManagerV2.sol:233-275,636-644,970-978`) | Management/object creation | Uses ID for deterministic proxy loading, preserves it into SystemConfig, and embeds it in legacy game args. |
| OPCM utilities (`src/L1/opcm/OPContractsManagerUtils.sol:87-110,440-460`) | Management/object creation | Derives salts/batch inbox and writes zero instead for super-game args. |
| Migrator (`src/L1/opcm/OPContractsManagerMigrator.sol:287-327,432-466`) | Management | Enforces nonzero/unique/ascending IDs and preserves each ID. |
| Standard validators (`src/L1/OPContractsManagerStandardValidator.sol:297-309,1223`; `src/L1/opcm/StandardValidatorUtils.sol:458`) | Validation | Compare configured/game-argument IDs with expected chain ID. |
| FaultDisputeGame (`src/dispute/FaultDisputeGame.sol:907-920`) | Runtime getter | Returns immutable game argument; not SystemConfig-live. |

## `optimismPortal()`

| Reader | Time | Assumption |
|---|---|---|
| SystemConfig (`src/L1/SystemConfig.sol:298-332,549-575`) | Runtime/management | Deterministic slot supplies pause resolver and old-identifier safety check. |
| OPCMv2 (`src/L1/opcm/OPContractsManagerV2.sol:444-452,831-896`) | Management | Loads/configures the existing Portal and writes the same address into SystemConfig. |
| Migrator (`src/L1/opcm/OPContractsManagerMigrator.sol:432-490`) | Management | Preserves address tuple and obtains the Portal to rewire. |
| Migration/standard validators (`src/L1/opcm/OPContractsManagerMigrationValidator.sol:200,480-570`; `src/L1/opcm/StandardValidatorUtils.sol:131-144,297-413`; `src/L1/OPContractsManagerStandardValidator.sol:331,441-457`) | Validation | Resolve and validate Portal/lockbox/ASR wiring and pause state. |

## `resourceConfig()`

| Reader | Time | Assumption |
|---|---|---|
| OptimismPortal2 (`src/L1/OptimismPortal2.sol:851-859`) | Every metered deposit | Reads current config; no per-deposit snapshot. |
| OPCMv2 (`src/L1/opcm/OPContractsManagerV2.sol:627-652,831-858`) | Management | Loads existing config and feeds it through SystemConfig initializer validation. |
| Migrator (`src/L1/opcm/OPContractsManagerMigrator.sol:432-466`) | Management | Preserves config during shared-WETH SystemConfig reinit. |
| OPContractsManagerStandardValidator (`src/L1/OPContractsManagerStandardValidator.sol:297-309`) | Validation | Compares deployed config with expected standard values. |

## `lastUsedOPCM()` / `lastUsedOPCMVersion()`

| Reader | Time | Assumption |
|---|---|---|
| OPCMv2 upgrade/migrate (`src/L1/opcm/OPContractsManagerV2.sol:278-313,822-829`) | Management | Enforces permitted release sequence using the last OPCM version. |
| OPCM utilities (`src/L1/opcm/OPContractsManagerUtils.sol:526-535`) | Management | Reads the last OPCM as `ISemver` for sequence/version checks. |
| Migrator (`src/L1/opcm/OPContractsManagerMigrator.sol:432-466`) | Management | Preserves the last OPCM address when reinitializing SystemConfig. |

At N all four report last OPCM `0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f`, version `9.0.3`; no user execution path consumes it.
