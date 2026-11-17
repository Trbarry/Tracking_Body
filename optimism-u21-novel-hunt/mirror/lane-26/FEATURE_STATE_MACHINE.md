# Lane 26 — SystemConfig feature-state machine

Scope is `op-contracts/v9.0.0` at pinned commit `ba6f...`; source references below are relative to `/home/user/ethereum-optimism/op-v9.0.0`. Historical references name the v8/v7 roots explicitly. Live state was read passively at L1 blocks 26,430,858 (N-1), 26,430,859 (N), and 26,433,900; mutations were only in `forge test` forks.

## Setter and consumer matrix

`SystemConfig.setFeature` accepts any `bytes32`, but only the chain's ProxyAdmin or its owner may call it (`src/L1/SystemConfig.sol:528-568`; `src/universal/ProxyAdminOwnedBase.sol:102-105`). The SystemConfig owner is not sufficient. Every write is an execution-time change; no feature value is copied into a dependent L1 contract.

| Feature | Standard setter / time | Can be unset? | Validation at the write | Execution-time readers |
|---|---|---|---|---|
| `ETH_LOCKBOX` | OPCMv2 deploy/upgrade enables it before Portal initialization (`src/L1/opcm/OPContractsManagerV2.sol:860-879`), or PA/PA-owner calls `setFeature` | No in v9 (`SystemConfig.sol:543-547`) | Enabling refuses an active old Portal-identifier pause (`:549-554`). The setter itself does not validate a lockbox address; Portal initialization requires enabled flag plus nonzero lockbox (`src/L1/OptimismPortal2.sol:831-842`). | Portal deposit/finalize query the flag and current cached lockbox (`OptimismPortal2.sol:612-615,741-759,804-808`). OPCM/migrator/validator read it during management actions. Pause resolution no longer depends on this flag. |
| `CUSTOM_GAS_TOKEN` | OPCM permits initial deployment only (`OPContractsManagerV2.sol:998-1008`); the generic PA/PA-owner setter remains callable later | Yes; no feature-specific one-way rule | No combination, liquidity, or object-age validation. The Portal source explicitly warns against post-deployment enablement (`OptimismPortal2.sol:816-821`). | Portal checks it on each prove, finalize, and deposit (`:406-409,586-589,752-754`). Migrator refuses CGT (`src/L1/opcm/OPContractsManagerMigrator.sol:483-486`). L2 uses a separate L1Block flag, not this mapping. |
| `INTEROP` | Intended path is OPCM migrator after validating all chains, then setting it immediately before rewiring (`OPContractsManagerMigrator.sol:287-327,494-543`) | No (`SystemConfig.sol:557-560`) | Generic setter checks no ETH-lockbox/shared-ASR/shared-DGF prerequisite. Migrator checks common PA owner and SuperchainConfig, flag off, unique nonzero ordered chain IDs, no CGT, and no active current pause (`OPContractsManagerMigrator.sol:287-327,483-513`). | Portal combines it with `ETH_LOCKBOX` at execution and uses that only to permit `migrateToSharedDisputeGame` (`OptimismPortal2.sol:528-571,810-814`). Migrator uses it as the permanent re-migration guard. |
| Unknown `bytes32` | PA/PA owner | Yes | Only no-op writes are rejected | No v9 consumer found. Fork test toggled `LANE_26_UNKNOWN` both ways. |

## All named-feature combinations

Bits are `(E,C,I) = (ETH_LOCKBOX, CUSTOM_GAS_TOKEN, INTEROP)`.

| Bits | Stable interpretation in v9 | Reachability from the four post-U21 chains |
|---|---|---|
| `000` | Not a valid initialized v9 Portal: Portal initialization requires E and a lockbox. | Not reachable through a standard v9 upgrade; only transient/uninitialized or arbitrary trusted upgrade state. |
| `001` | Invalid: I is permanently set but `_isUsingInterop` is false because E is false; Portal reinitialization rejects it. | Not reachable from live state because E cannot be disabled. A PA could construct it only around malformed/pre-init state. |
| `010` | CGT without the mandatory v9 lockbox/pause resolver; invalid Portal initialization. | Not reachable from live state. |
| `011` | Both preceding defects; invalid. | Not reachable from live state. |
| `100` | Normal non-CGT, non-interop chain. | Actual state of OP, Ink, Soneium, and Unichain at N. |
| `101` | Intended migrated interop member only if shared contracts were installed atomically. | Migrator reaches it safely. A direct PA-owner I write reaches the same bits without shared contracts and permanently makes the real migrator reject the chain. Privileged/configuration-only. |
| `110` | Supported CGT deployment: a lockbox is still the pause identifier, while native ETH custody stays in Portal (`OPContractsManagerV2.sol:884-896`). | None of the four chains is CGT. A PA-owner can force this after deployment; fork test showed an existing native-ETH deposit immediately becomes disallowed while >182k ETH remains in the lockbox. Privileged-only. |
| `111` | Not supported by standard interop migration, which rejects CGT. | Only a direct PA-owner sequence can create it; no permissionless/semi-privileged route found. |

From actual `100`, E is invariantly 1; C can toggle `100 <-> 110` (or `101 <-> 111`), and I can move once `100 -> 101` or `110 -> 111`. Thus all transition hazards require the PA/PA-owner, which is already able to upgrade the proxies.

## Cached versus live assumptions

* Portal caches SystemConfig, ASR and lockbox addresses at initialization, but reads all three features and `resourceConfig()` at execution (`OptimismPortal2.sol:273-303,804-855`).
* ASR and DelayedWETH cache a lockbox (`src/dispute/AnchorStateRegistry.sol:58-59,94-108`; `src/dispute/DelayedWETH.sol:47-64`). Legacy games cache ASR/WETH. Migration reinitializes every legacy WETH before the Portal, then rewires the old ASR, so those games inherit the shared lockbox pause (`OPContractsManagerMigrator.sol:265-272,412-430,545-555`).
* L1 messenger and bridges cache SystemConfig, but call its current `paused()` at execution (`src/L1/L1CrossDomainMessenger.sol:98-105`; `src/L1/L1StandardBridge.sol:122-129`; `src/L1/L1ERC721Bridge.sol:68-75`).
* A proof against a super game reads the current `SystemConfig.l2ChainId()` (`OptimismPortal2.sol:437-445`). No public setter exists. Current v9 initialization is already consumed; standard upgrades load the existing ID and reject an `overrides.cfg.l2ChainId` instruction (`OPContractsManagerV2.sol:244-275,347-375,636-644`). Migration also preserves it (`OPContractsManagerMigrator.sol:432-466`).

## L1/L2 split and activation ordering

L1 SystemConfig flags are not mirrored to L2. L2 `L1Block` has a separate one-way map and authorizes only the depositor, L2 ProxyAdmin, or its owner (`src/L2/L1Block.sol:69-76,230-258`). At Lagoon activation, derivation injects an L2 `setFeature(INTEROP)` deposit before the NUT bundle so L2ContractsManager observes it (`op-node/rollup/derive/lagoon_activation_transactions.go:14-22,80-101`; `src/L2/L2ContractsManager.sol:170-195`). The wrappers run only when interop is active and the dependency set has more than one chain (`op-node/rollup/derive/attributes.go:171-182`). OP Mainnet L2 currently reports L1Block `1.9.0`, C=false, I=false; MessagePasser `1.2.0`.

This creates an operational ordering dependency between the privileged L1 shared-contract migration and consensus-scheduled L2 activation, but no permissionless flag path.

## v7/v8/v9 delta

v7 and v8 used E to select Portal versus lockbox as pause identifier and allowed a generic I disable; their E-disable guard depended on whether Portal still held a configured lockbox (`op-v7.0.0/src/L1/SystemConfig.sol:551-611`; `op-v8.0.0/src/L1/SystemConfig.sol:528-588`). v9 makes E and I one-way and pause resolution unconditional through the current Portal lockbox (`SystemConfig.sol:543-575`). DevFeatures changed materially from v7 to v8 by retiring forced CANNON_KONA/L2CM bits and forcing SUPER_ROOT migration instead (`op-v7.0.0/src/libraries/DevFeatures.sol:13-49`; `op-v8.0.0/src/libraries/DevFeatures.sol:31-60`); v8-to-v9 changes only the interop-bit description, not bitmap behavior (`src/libraries/DevFeatures.sol:30-61`).
