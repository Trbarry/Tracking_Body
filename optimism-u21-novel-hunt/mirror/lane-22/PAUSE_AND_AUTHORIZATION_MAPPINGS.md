# Pause and authorization mapping state (lane 22)

All reads below were made at N-1 (26430858 / `:8546`), N (26430859 / `:8547`), and later (26433900 / `:8545`). Each listed raw value and getter result was identical at all three checkpoints.

## ETHLockbox portal authorization

`authorizedPortals` is mapping base slot 1 (`op-v9.0.0/packages/contracts-bedrock/snapshots/storageLayout/ETHLockbox.json:23-29`). Each per-chain portal entry is raw `0x…01` and `authorizedPortals(portal) == true`:

| Chain | Lockbox | Portal | Derived slot |
|---|---|---|---|
| OP Mainnet | `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43` | `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` | `0xe94ce3e921cb2e9e760f8bafe43e7e1899b19b06eaa1979629b096fe61892398` |
| Ink | `0xbd4AbB321138e8Eddc399cE64E66451294325a14` | `0x5d66C1782664115999C47c9fA5cd031f495D3e4F` | `0xca399a74a2e45bc1100aefaa1dae30d0ae51000e349d60206e57bc5c12355f1e` |
| Soneium | `0x67B4de6FfA66EF201Ea6099A89cA397D56622E31` | `0x88e529A6ccd302c948689Cd5156C83D4614FAE92` | `0x58321ae9f41f6a103febd5c3a9a0fcce07f40d75e877fda01183207281661d60` |
| Unichain | `0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5` | `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` | `0xf451b09ed076ace1a495b612661a3fe9904e13e88b2967fba804b5553eea6895` |

The lockbox enforces this entry before accepting deposits (`op-v9.0.0/packages/contracts-bedrock/src/L1/ETHLockbox.sol:142-150`).

## SuperchainConfig pause identifiers

`pauseTimestamps` is mapping base slot 1 (`op-v9.0.0/packages/contracts-bedrock/snapshots/storageLayout/SuperchainConfig.json:23-29`). v9 defines active local/global pause as global identifier zero OR the requested identifier (`op-v9.0.0/packages/contracts-bedrock/src/L1/SuperchainConfig.sol:130-154`).

The following derived entries were raw zero and their `paused(address)` getters returned false at all checkpoints:

| Identifier | Derived slot |
|---|---|
| global `address(0)` | `0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49` |
| OP portal | `0xe94ce3e921cb2e9e760f8bafe43e7e1899b19b06eaa1979629b096fe61892398` |
| OP lockbox | `0x9dcdb58f4e61e1444b6a5300bf9cf5654428b4d4ce033802322aff38dab3a24a` |
| Ink portal | `0xca399a74a2e45bc1100aefaa1dae30d0ae51000e349d60206e57bc5c12355f1e` |
| Ink lockbox | `0x2eac661f32f02328bdf63dec1240ea38835878691ee52caf1aef637406d73478` |
| Soneium portal | `0x58321ae9f41f6a103febd5c3a9a0fcce07f40d75e877fda01183207281661d60` |
| Soneium lockbox | `0x184f1f5db7be287cacc25d279416aa3cb95cfbaa3c4c529437ec2fb6714183ba` |
| Unichain portal | `0xf451b09ed076ace1a495b612661a3fe9904e13e88b2967fba804b5553eea6895` |
| Unichain lockbox | `0x1a7ea66931b9f3139f6ae9f705f79936fc508982cd104767e34b27278c60d628` |

SystemConfig v9 resolves its pause through the portal's lockbox (`op-v9.0.0/packages/contracts-bedrock/src/L1/SystemConfig.sol:570-576`); the portal and ASR delegate to `ethLockbox.paused()` (`.../L1/OptimismPortal2.sol:305-308`; `.../dispute/AnchorStateRegistry.sol:135-143`), and DelayedWETH checks the same dependency before withdrawal (`.../dispute/DelayedWETH.sol:98-108`). The pointer pivot therefore did not erase an active pause on these deployed chains.

For the planned shared-lockbox migration, the migrator checks the current pause before changing the identifier and then repoints legacy WETH/ASR (`op-v9.0.0/packages/contracts-bedrock/src/L1/opcm/OPContractsManagerMigrator.sol:488-555`). The validator requires both legacy contracts to resolve to the shared lockbox (`.../OPContractsManagerMigrationValidator.sol:612-660`).

## SystemConfig feature mapping

At all four SystemConfigs and all three checkpoints:

- `ETH_LOCKBOX = true` at slot `0x58e88e949bd180ff86d6c072735c3d8d5a05a543c16130176ec0bc0adf3fd806`.
- `INTEROP = false` at slot `0x252630ff969d59d68f549a020f5a95de1229566c4ecda0b4de628fdba9eecdc7`.
- `CUSTOM_GAS_TOKEN = false` at slot `0x3ec9a18bd22a834e2a13465cc2aa2a9aebb161ffdebf39cdb0028dbb1b5394b4`.

The mapping declaration is at `op-v9.0.0/packages/contracts-bedrock/src/L1/SystemConfig.sol:159-160`; the ETH-lockbox feature's pause-preservation guard is at lines 528-567.
