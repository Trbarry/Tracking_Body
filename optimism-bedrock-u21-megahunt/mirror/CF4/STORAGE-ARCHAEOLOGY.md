# CF4 storage archaeology: Bedrock through op-contracts/v9.0.0

Worker: CF4 (independent Track A mirror). Chain-state cutoff: Ethereum block `26433900`.
The companion `storage-lineage.json` is canonical for every per-release field. This document
groups consecutive releases with byte-identical layouts; therefore every named release is still
covered field-by-field. Commits and source paths are embedded in the JSON.

## Method and coverage

- v1.0.0/v1.1.0: compiler table `.storage-layout`; six early omissions reconstructed from
  inheritance and declarations and marked `manual inheritance reconstruction` in JSON.
- v1.2.0–v9.0.0: `snapshots/storageLayout/<Contract>.json`; inheritance chains checked by hand
  at every layout-changing epoch.
- A field position is `(slot, byte offset)`. `bytes` is compiler width; arrays/gaps occupy the
  stated number of bytes from their starting slot. Mappings list their base slot only.
- Hashed/unstructured slots and production values are catalogued separately below.

## OptimismPortal

Exists in snapshots `v1.0.0` through `v1.8.0`; `_initialized` position(s): slot 0 offset 0.

### Layout epoch `v1.0.0` (`c21f9b9d2a`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 32 | `params` | `struct ResourceMetering.ResourceParams` |
| 2 | 0 | 1536 | `__gap` | `uint256[48]` |
| 50 | 0 | 20 | `l2Sender` | `address` |
| 51 | 0 | 32 | `finalizedWithdrawals` | `mapping(bytes32 => bool)` |
| 52 | 0 | 32 | `provenWithdrawals` | `mapping(bytes32 => struct OptimismPortal.ProvenWithdrawal)` |
| 53 | 0 | 1 | `paused` | `bool` |

### Layout epoch `v1.1.0` (`dccd044a7c`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 32 | `params` | `struct ResourceMetering.ResourceParams` |
| 2 | 0 | 1536 | `__gap` | `uint256[48]` |
| 50 | 0 | 20 | `l2Sender` | `address` |
| 51 | 0 | 32 | `finalizedWithdrawals` | `mapping(bytes32 => bool)` |
| 52 | 0 | 32 | `provenWithdrawals` | `mapping(bytes32 => struct OptimismPortal.ProvenWithdrawal)` |
| 53 | 0 | 1 | `paused` | `bool` |
| 53 | 1 | 20 | `l2Oracle` | `contract L2OutputOracle` |
| 54 | 0 | 20 | `systemConfig` | `contract SystemConfig` |
| 55 | 0 | 20 | `guardian` | `address` |

### Layout epoch `v1.2.0` (`aca18b8c85`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 32 | `params` | `struct ResourceMetering.ResourceParams` |
| 2 | 0 | 1536 | `__gap` | `uint256[48]` |
| 50 | 0 | 20 | `l2Sender` | `address` |
| 51 | 0 | 32 | `finalizedWithdrawals` | `mapping(bytes32 => bool)` |
| 52 | 0 | 32 | `provenWithdrawals` | `mapping(bytes32 => struct OptimismPortal.ProvenWithdrawal)` |
| 53 | 0 | 1 | `spacer_53_0_1` | `bool` |
| 53 | 1 | 20 | `superchainConfig` | `contract SuperchainConfig` |

### Layout epoch `v1.3.0–v1.4.0` (`42789d5a48`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 32 | `params` | `struct ResourceMetering.ResourceParams` |
| 2 | 0 | 1536 | `__gap` | `uint256[48]` |
| 50 | 0 | 20 | `l2Sender` | `address` |
| 51 | 0 | 32 | `finalizedWithdrawals` | `mapping(bytes32 => bool)` |
| 52 | 0 | 32 | `provenWithdrawals` | `mapping(bytes32 => struct OptimismPortal.ProvenWithdrawal)` |
| 53 | 0 | 1 | `spacer_53_0_1` | `bool` |
| 53 | 1 | 20 | `superchainConfig` | `contract SuperchainConfig` |
| 54 | 0 | 20 | `l2Oracle` | `contract L2OutputOracle` |
| 55 | 0 | 20 | `systemConfig` | `contract SystemConfig` |

### Layout epoch `v1.5.0–v1.6.0` (`4414e65db1`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 32 | `params` | `struct ResourceMetering.ResourceParams` |
| 2 | 0 | 1536 | `__gap` | `uint256[48]` |
| 50 | 0 | 20 | `l2Sender` | `address` |
| 51 | 0 | 32 | `finalizedWithdrawals` | `mapping(bytes32 => bool)` |
| 52 | 0 | 32 | `provenWithdrawals` | `mapping(bytes32 => struct OptimismPortal.ProvenWithdrawal)` |
| 53 | 0 | 1 | `spacer_53_0_1` | `bool` |
| 53 | 1 | 20 | `superchainConfig` | `contract SuperchainConfig` |
| 54 | 0 | 20 | `l2Oracle` | `contract L2OutputOracle` |
| 55 | 0 | 20 | `systemConfig` | `contract SystemConfig` |
| 56 | 0 | 20 | `spacer_56_0_20` | `address` |
| 57 | 0 | 32 | `spacer_57_0_32` | `bytes32` |
| 58 | 0 | 32 | `spacer_58_0_32` | `bytes32` |
| 59 | 0 | 32 | `spacer_59_0_32` | `bytes32` |
| 60 | 0 | 32 | `spacer_60_0_32` | `bytes32` |
| 61 | 0 | 32 | `_balance` | `uint256` |

### Layout epoch `v1.8.0` (`2e6b68d9a1`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 32 | `params` | `struct ResourceMetering.ResourceParams` |
| 2 | 0 | 1536 | `__gap` | `uint256[48]` |
| 50 | 0 | 20 | `l2Sender` | `address` |
| 51 | 0 | 32 | `finalizedWithdrawals` | `mapping(bytes32 => bool)` |
| 52 | 0 | 32 | `provenWithdrawals` | `mapping(bytes32 => struct OptimismPortal.ProvenWithdrawal)` |
| 53 | 0 | 1 | `spacer_53_0_1` | `bool` |
| 53 | 1 | 20 | `superchainConfig` | `contract ISuperchainConfig` |
| 54 | 0 | 20 | `l2Oracle` | `contract IL2OutputOracle` |
| 55 | 0 | 20 | `systemConfig` | `contract ISystemConfig` |
| 56 | 0 | 20 | `spacer_56_0_20` | `address` |
| 57 | 0 | 32 | `spacer_57_0_32` | `bytes32` |
| 58 | 0 | 32 | `spacer_58_0_32` | `bytes32` |
| 59 | 0 | 32 | `spacer_59_0_32` | `bytes32` |
| 60 | 0 | 32 | `spacer_60_0_32` | `bytes32` |
| 61 | 0 | 32 | `_balance` | `uint256` |

### Position transitions

| release edge | position | classification | before | after |
|---|---:|---|---|---|
| `v1.0.0→v1.1.0` | `53:1` | added | — | `l2Oracle: contract L2OutputOracle` |
| `v1.0.0→v1.1.0` | `54:0` | added | — | `systemConfig: contract SystemConfig` |
| `v1.0.0→v1.1.0` | `55:0` | added | — | `guardian: address` |
| `v1.1.0→v1.2.0` | `53:0` | deleted_to_spacer | `paused: bool` | `spacer_53_0_1: bool` |
| `v1.1.0→v1.2.0` | `53:1` | renamed_and_retyped | `l2Oracle: contract L2OutputOracle` | `superchainConfig: contract SuperchainConfig` |
| `v1.1.0→v1.2.0` | `54:0` | deleted | `systemConfig: contract SystemConfig` | — |
| `v1.1.0→v1.2.0` | `55:0` | deleted | `guardian: address` | — |
| `v1.2.0→v1.3.0` | `54:0` | added | — | `l2Oracle: contract L2OutputOracle` |
| `v1.2.0→v1.3.0` | `55:0` | added | — | `systemConfig: contract SystemConfig` |
| `v1.4.0→v1.5.0` | `56:0` | added | — | `spacer_56_0_20: address` |
| `v1.4.0→v1.5.0` | `57:0` | added | — | `spacer_57_0_32: bytes32` |
| `v1.4.0→v1.5.0` | `58:0` | added | — | `spacer_58_0_32: bytes32` |
| `v1.4.0→v1.5.0` | `59:0` | added | — | `spacer_59_0_32: bytes32` |
| `v1.4.0→v1.5.0` | `60:0` | added | — | `spacer_60_0_32: bytes32` |
| `v1.4.0→v1.5.0` | `61:0` | added | — | `_balance: uint256` |
| `v1.6.0→v1.8.0` | `53:1` | retyped | `superchainConfig: contract SuperchainConfig` | `superchainConfig: contract ISuperchainConfig` |
| `v1.6.0→v1.8.0` | `54:0` | retyped | `l2Oracle: contract L2OutputOracle` | `l2Oracle: contract IL2OutputOracle` |
| `v1.6.0→v1.8.0` | `55:0` | retyped | `systemConfig: contract SystemConfig` | `systemConfig: contract ISystemConfig` |

## OptimismPortal2

Exists in snapshots `v1.4.0` through `v9.0.0`; `_initialized` position(s): slot 0 offset 0.

### Layout epoch `v1.4.0–v1.5.0` (`d84f0a9b30`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 32 | `params` | `struct ResourceMetering.ResourceParams` |
| 2 | 0 | 1536 | `__gap` | `uint256[48]` |
| 50 | 0 | 20 | `l2Sender` | `address` |
| 51 | 0 | 32 | `finalizedWithdrawals` | `mapping(bytes32 => bool)` |
| 52 | 0 | 32 | `spacer_52_0_32` | `bytes32` |
| 53 | 0 | 1 | `spacer_53_0_1` | `bool` |
| 53 | 1 | 20 | `superchainConfig` | `contract SuperchainConfig` |
| 54 | 0 | 20 | `spacer_54_0_20` | `address` |
| 55 | 0 | 20 | `systemConfig` | `contract SystemConfig` |
| 56 | 0 | 20 | `disputeGameFactory` | `contract DisputeGameFactory` |
| 57 | 0 | 32 | `provenWithdrawals` | `mapping(bytes32 => mapping(address => struct OptimismPortal2.ProvenWithdrawal))` |
| 58 | 0 | 32 | `disputeGameBlacklist` | `mapping(contract IDisputeGame => bool)` |
| 59 | 0 | 4 | `respectedGameType` | `GameType` |
| 59 | 4 | 8 | `respectedGameTypeUpdatedAt` | `uint64` |
| 60 | 0 | 32 | `proofSubmitters` | `mapping(bytes32 => address[])` |
| 61 | 0 | 32 | `spacer_61_0_32` | `bytes32` |

### Layout epoch `v1.6.0` (`ea99afdabf`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 32 | `params` | `struct ResourceMetering.ResourceParams` |
| 2 | 0 | 1536 | `__gap` | `uint256[48]` |
| 50 | 0 | 20 | `l2Sender` | `address` |
| 51 | 0 | 32 | `finalizedWithdrawals` | `mapping(bytes32 => bool)` |
| 52 | 0 | 32 | `spacer_52_0_32` | `bytes32` |
| 53 | 0 | 1 | `spacer_53_0_1` | `bool` |
| 53 | 1 | 20 | `superchainConfig` | `contract SuperchainConfig` |
| 54 | 0 | 20 | `spacer_54_0_20` | `address` |
| 55 | 0 | 20 | `systemConfig` | `contract SystemConfig` |
| 56 | 0 | 20 | `disputeGameFactory` | `contract DisputeGameFactory` |
| 57 | 0 | 32 | `provenWithdrawals` | `mapping(bytes32 => mapping(address => struct OptimismPortal2.ProvenWithdrawal))` |
| 58 | 0 | 32 | `disputeGameBlacklist` | `mapping(contract IDisputeGame => bool)` |
| 59 | 0 | 4 | `respectedGameType` | `GameType` |
| 59 | 4 | 8 | `respectedGameTypeUpdatedAt` | `uint64` |
| 60 | 0 | 32 | `proofSubmitters` | `mapping(bytes32 => address[])` |
| 61 | 0 | 32 | `_balance` | `uint256` |

### Layout epoch `v1.8.0` (`09ceeb5123`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 32 | `params` | `struct ResourceMetering.ResourceParams` |
| 2 | 0 | 1536 | `__gap` | `uint256[48]` |
| 50 | 0 | 20 | `l2Sender` | `address` |
| 51 | 0 | 32 | `finalizedWithdrawals` | `mapping(bytes32 => bool)` |
| 52 | 0 | 32 | `spacer_52_0_32` | `bytes32` |
| 53 | 0 | 1 | `spacer_53_0_1` | `bool` |
| 53 | 1 | 20 | `superchainConfig` | `contract ISuperchainConfig` |
| 54 | 0 | 20 | `spacer_54_0_20` | `address` |
| 55 | 0 | 20 | `systemConfig` | `contract ISystemConfig` |
| 56 | 0 | 20 | `disputeGameFactory` | `contract IDisputeGameFactory` |
| 57 | 0 | 32 | `provenWithdrawals` | `mapping(bytes32 => mapping(address => struct OptimismPortal2.ProvenWithdrawal))` |
| 58 | 0 | 32 | `disputeGameBlacklist` | `mapping(contract IDisputeGame => bool)` |
| 59 | 0 | 4 | `respectedGameType` | `GameType` |
| 59 | 4 | 8 | `respectedGameTypeUpdatedAt` | `uint64` |
| 60 | 0 | 32 | `proofSubmitters` | `mapping(bytes32 => address[])` |
| 61 | 0 | 32 | `_balance` | `uint256` |

### Layout epoch `v2.0.0–v3.0.1` (`4e9eb6f708`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 32 | `params` | `struct ResourceMetering.ResourceParams` |
| 2 | 0 | 1536 | `__gap` | `uint256[48]` |
| 50 | 0 | 20 | `l2Sender` | `address` |
| 51 | 0 | 32 | `finalizedWithdrawals` | `mapping(bytes32 => bool)` |
| 52 | 0 | 32 | `spacer_52_0_32` | `bytes32` |
| 53 | 0 | 1 | `spacer_53_0_1` | `bool` |
| 53 | 1 | 20 | `superchainConfig` | `contract ISuperchainConfig` |
| 54 | 0 | 20 | `spacer_54_0_20` | `address` |
| 55 | 0 | 20 | `systemConfig` | `contract ISystemConfig` |
| 56 | 0 | 20 | `disputeGameFactory` | `contract IDisputeGameFactory` |
| 57 | 0 | 32 | `provenWithdrawals` | `mapping(bytes32 => mapping(address => struct OptimismPortal2.ProvenWithdrawal))` |
| 58 | 0 | 32 | `disputeGameBlacklist` | `mapping(contract IDisputeGame => bool)` |
| 59 | 0 | 4 | `respectedGameType` | `GameType` |
| 59 | 4 | 8 | `respectedGameTypeUpdatedAt` | `uint64` |
| 60 | 0 | 32 | `proofSubmitters` | `mapping(bytes32 => address[])` |
| 61 | 0 | 32 | `spacer_61_0_32` | `uint256` |

### Layout epoch `v4.0.0` (`f1f48fab40`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 32 | `params` | `struct ResourceMetering.ResourceParams` |
| 2 | 0 | 1536 | `__gap` | `uint256[48]` |
| 50 | 0 | 20 | `l2Sender` | `address` |
| 51 | 0 | 32 | `finalizedWithdrawals` | `mapping(bytes32 => bool)` |
| 52 | 0 | 32 | `spacer_52_0_32` | `bytes32` |
| 53 | 0 | 1 | `spacer_53_0_1` | `bool` |
| 53 | 1 | 20 | `spacer_53_1_20` | `address` |
| 54 | 0 | 20 | `spacer_54_0_20` | `address` |
| 55 | 0 | 20 | `systemConfig` | `contract ISystemConfig` |
| 56 | 0 | 20 | `spacer_56_0_20` | `address` |
| 57 | 0 | 32 | `provenWithdrawals` | `mapping(bytes32 => mapping(address => struct OptimismPortal2.ProvenWithdrawal))` |
| 58 | 0 | 32 | `spacer_58_0_32` | `bytes32` |
| 59 | 0 | 4 | `spacer_59_0_4` | `GameType` |
| 59 | 4 | 8 | `spacer_59_4_8` | `uint64` |
| 60 | 0 | 32 | `proofSubmitters` | `mapping(bytes32 => address[])` |
| 61 | 0 | 32 | `spacer_61_0_32` | `uint256` |
| 62 | 0 | 20 | `anchorStateRegistry` | `contract IAnchorStateRegistry` |
| 63 | 0 | 20 | `ethLockbox` | `contract IETHLockbox` |
| 63 | 20 | 1 | `superRootsActive` | `bool` |

### Layout epoch `v4.1.0–v9.0.0` (`139791082f`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 32 | `params` | `struct ResourceMetering.ResourceParams` |
| 2 | 0 | 1536 | `__gap` | `uint256[48]` |
| 50 | 0 | 20 | `l2Sender` | `address` |
| 51 | 0 | 32 | `finalizedWithdrawals` | `mapping(bytes32 => bool)` |
| 52 | 0 | 32 | `spacer_52_0_32` | `bytes32` |
| 53 | 0 | 1 | `spacer_53_0_1` | `bool` |
| 53 | 1 | 20 | `spacer_53_1_20` | `address` |
| 54 | 0 | 20 | `spacer_54_0_20` | `address` |
| 55 | 0 | 20 | `systemConfig` | `contract ISystemConfig` |
| 56 | 0 | 20 | `spacer_56_0_20` | `address` |
| 57 | 0 | 32 | `provenWithdrawals` | `mapping(bytes32 => mapping(address => struct OptimismPortal2.ProvenWithdrawal))` |
| 58 | 0 | 32 | `spacer_58_0_32` | `bytes32` |
| 59 | 0 | 4 | `spacer_59_0_4` | `GameType` |
| 59 | 4 | 8 | `spacer_59_4_8` | `uint64` |
| 60 | 0 | 32 | `proofSubmitters` | `mapping(bytes32 => address[])` |
| 61 | 0 | 32 | `spacer_61_0_32` | `uint256` |
| 62 | 0 | 20 | `anchorStateRegistry` | `contract IAnchorStateRegistry` |
| 63 | 0 | 20 | `ethLockbox` | `contract IETHLockbox` |
| 63 | 20 | 1 | `spacer_63_20_1` | `bool` |

### Position transitions

| release edge | position | classification | before | after |
|---|---:|---|---|---|
| `v1.5.0→v1.6.0` | `61:0` | spacer_consumed | `spacer_61_0_32: bytes32` | `_balance: uint256` |
| `v1.6.0→v1.8.0` | `53:1` | retyped | `superchainConfig: contract SuperchainConfig` | `superchainConfig: contract ISuperchainConfig` |
| `v1.6.0→v1.8.0` | `55:0` | retyped | `systemConfig: contract SystemConfig` | `systemConfig: contract ISystemConfig` |
| `v1.6.0→v1.8.0` | `56:0` | retyped | `disputeGameFactory: contract DisputeGameFactory` | `disputeGameFactory: contract IDisputeGameFactory` |
| `v1.8.0→v2.0.0` | `61:0` | deleted_to_spacer | `_balance: uint256` | `spacer_61_0_32: uint256` |
| `v3.0.1→v4.0.0` | `53:1` | deleted_to_spacer | `superchainConfig: contract ISuperchainConfig` | `spacer_53_1_20: address` |
| `v3.0.1→v4.0.0` | `56:0` | deleted_to_spacer | `disputeGameFactory: contract IDisputeGameFactory` | `spacer_56_0_20: address` |
| `v3.0.1→v4.0.0` | `58:0` | deleted_to_spacer | `disputeGameBlacklist: mapping(contract IDisputeGame => bool)` | `spacer_58_0_32: bytes32` |
| `v3.0.1→v4.0.0` | `59:0` | deleted_to_spacer | `respectedGameType: GameType` | `spacer_59_0_4: GameType` |
| `v3.0.1→v4.0.0` | `59:4` | deleted_to_spacer | `respectedGameTypeUpdatedAt: uint64` | `spacer_59_4_8: uint64` |
| `v3.0.1→v4.0.0` | `62:0` | added | — | `anchorStateRegistry: contract IAnchorStateRegistry` |
| `v3.0.1→v4.0.0` | `63:0` | added | — | `ethLockbox: contract IETHLockbox` |
| `v3.0.1→v4.0.0` | `63:20` | added | — | `superRootsActive: bool` |
| `v4.0.0→v4.1.0` | `63:20` | deleted_to_spacer | `superRootsActive: bool` | `spacer_63_20_1: bool` |

## L2OutputOracle

Exists in snapshots `v1.0.0` through `v1.8.0`; `_initialized` position(s): slot 0 offset 0.

### Layout epoch `v1.0.0` (`805a6475d5`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 32 | `startingBlockNumber` | `uint256` |
| 2 | 0 | 32 | `startingTimestamp` | `uint256` |
| 3 | 0 | 32 | `l2Outputs` | `struct Types.OutputProposal[]` |

### Layout epoch `v1.1.0` (`5ed6b9a81c`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 32 | `startingBlockNumber` | `uint256` |
| 2 | 0 | 32 | `startingTimestamp` | `uint256` |
| 3 | 0 | 32 | `l2Outputs` | `struct Types.OutputProposal[]` |
| 4 | 0 | 20 | `challenger` | `address` |
| 5 | 0 | 20 | `proposer` | `address` |

### Layout epoch `v1.2.0` (`805a6475d5`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 32 | `startingBlockNumber` | `uint256` |
| 2 | 0 | 32 | `startingTimestamp` | `uint256` |
| 3 | 0 | 32 | `l2Outputs` | `struct Types.OutputProposal[]` |

### Layout epoch `v1.3.0–v1.8.0` (`131088b469`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 32 | `startingBlockNumber` | `uint256` |
| 2 | 0 | 32 | `startingTimestamp` | `uint256` |
| 3 | 0 | 32 | `l2Outputs` | `struct Types.OutputProposal[]` |
| 4 | 0 | 32 | `submissionInterval` | `uint256` |
| 5 | 0 | 32 | `l2BlockTime` | `uint256` |
| 6 | 0 | 20 | `challenger` | `address` |
| 7 | 0 | 20 | `proposer` | `address` |
| 8 | 0 | 32 | `finalizationPeriodSeconds` | `uint256` |

### Position transitions

| release edge | position | classification | before | after |
|---|---:|---|---|---|
| `v1.0.0→v1.1.0` | `4:0` | added | — | `challenger: address` |
| `v1.0.0→v1.1.0` | `5:0` | added | — | `proposer: address` |
| `v1.1.0→v1.2.0` | `4:0` | deleted | `challenger: address` | — |
| `v1.1.0→v1.2.0` | `5:0` | deleted | `proposer: address` | — |
| `v1.2.0→v1.3.0` | `4:0` | added | — | `submissionInterval: uint256` |
| `v1.2.0→v1.3.0` | `5:0` | added | — | `l2BlockTime: uint256` |
| `v1.2.0→v1.3.0` | `6:0` | added | — | `challenger: address` |
| `v1.2.0→v1.3.0` | `7:0` | added | — | `proposer: address` |
| `v1.2.0→v1.3.0` | `8:0` | added | — | `finalizationPeriodSeconds: uint256` |

## SystemConfig

Exists in snapshots `v1.0.0` through `v9.0.0`; `_initialized` position(s): slot 0 offset 0.

### Layout epoch `v1.0.0` (`f7e2e12eb5`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1600 | `__gap` | `uint256[50]` |
| 51 | 0 | 20 | `_owner` | `address` |
| 52 | 0 | 1568 | `__gap` | `uint256[49]` |
| 101 | 0 | 32 | `overhead` | `uint256` |
| 102 | 0 | 32 | `scalar` | `uint256` |
| 103 | 0 | 32 | `batcherHash` | `bytes32` |
| 104 | 0 | 8 | `gasLimit` | `uint64` |
| 105 | 0 | 32 | `_resourceConfig` | `struct ResourceMetering.ResourceConfig` |

### Layout epoch `v1.1.0` (`de07d57590`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1600 | `__gap` | `uint256[50]` |
| 51 | 0 | 20 | `_owner` | `address` |
| 52 | 0 | 1568 | `__gap` | `uint256[49]` |
| 101 | 0 | 32 | `overhead` | `uint256` |
| 102 | 0 | 32 | `scalar` | `uint256` |
| 103 | 0 | 32 | `batcherHash` | `bytes32` |
| 104 | 0 | 8 | `gasLimit` | `uint64` |
| 105 | 0 | 32 | `_resourceConfig` | `struct ResourceMetering.ResourceConfig` |
| 106 | 0 | 32 | `startBlock` | `uint256` |

### Layout epoch `v1.2.0–v1.5.0` (`f7e2e12eb5`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1600 | `__gap` | `uint256[50]` |
| 51 | 0 | 20 | `_owner` | `address` |
| 52 | 0 | 1568 | `__gap` | `uint256[49]` |
| 101 | 0 | 32 | `overhead` | `uint256` |
| 102 | 0 | 32 | `scalar` | `uint256` |
| 103 | 0 | 32 | `batcherHash` | `bytes32` |
| 104 | 0 | 8 | `gasLimit` | `uint64` |
| 105 | 0 | 32 | `_resourceConfig` | `struct ResourceMetering.ResourceConfig` |

### Layout epoch `v1.6.0` (`c4fe58c838`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1600 | `__gap` | `uint256[50]` |
| 51 | 0 | 20 | `_owner` | `address` |
| 52 | 0 | 1568 | `__gap` | `uint256[49]` |
| 101 | 0 | 32 | `overhead` | `uint256` |
| 102 | 0 | 32 | `scalar` | `uint256` |
| 103 | 0 | 32 | `batcherHash` | `bytes32` |
| 104 | 0 | 8 | `gasLimit` | `uint64` |
| 104 | 8 | 4 | `basefeeScalar` | `uint32` |
| 104 | 12 | 4 | `blobbasefeeScalar` | `uint32` |
| 105 | 0 | 32 | `_resourceConfig` | `struct ResourceMetering.ResourceConfig` |

### Layout epoch `v1.8.0–v2.2.0` (`dda0a3c92f`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1600 | `__gap` | `uint256[50]` |
| 51 | 0 | 20 | `_owner` | `address` |
| 52 | 0 | 1568 | `__gap` | `uint256[49]` |
| 101 | 0 | 32 | `overhead` | `uint256` |
| 102 | 0 | 32 | `scalar` | `uint256` |
| 103 | 0 | 32 | `batcherHash` | `bytes32` |
| 104 | 0 | 8 | `gasLimit` | `uint64` |
| 104 | 8 | 4 | `basefeeScalar` | `uint32` |
| 104 | 12 | 4 | `blobbasefeeScalar` | `uint32` |
| 105 | 0 | 32 | `_resourceConfig` | `struct IResourceMetering.ResourceConfig` |
| 106 | 0 | 4 | `eip1559Denominator` | `uint32` |
| 106 | 4 | 4 | `eip1559Elasticity` | `uint32` |

### Layout epoch `v3.0.0–v3.0.1` (`23086d3c38`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1600 | `__gap` | `uint256[50]` |
| 51 | 0 | 20 | `_owner` | `address` |
| 52 | 0 | 1568 | `__gap` | `uint256[49]` |
| 101 | 0 | 32 | `overhead` | `uint256` |
| 102 | 0 | 32 | `scalar` | `uint256` |
| 103 | 0 | 32 | `batcherHash` | `bytes32` |
| 104 | 0 | 8 | `gasLimit` | `uint64` |
| 104 | 8 | 4 | `basefeeScalar` | `uint32` |
| 104 | 12 | 4 | `blobbasefeeScalar` | `uint32` |
| 105 | 0 | 32 | `_resourceConfig` | `struct IResourceMetering.ResourceConfig` |
| 106 | 0 | 4 | `eip1559Denominator` | `uint32` |
| 106 | 4 | 4 | `eip1559Elasticity` | `uint32` |
| 106 | 8 | 4 | `operatorFeeScalar` | `uint32` |
| 106 | 12 | 8 | `operatorFeeConstant` | `uint64` |

### Layout epoch `v4.0.0` (`a514c25395`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1600 | `__gap` | `uint256[50]` |
| 51 | 0 | 20 | `_owner` | `address` |
| 52 | 0 | 1568 | `__gap` | `uint256[49]` |
| 101 | 0 | 32 | `overhead` | `uint256` |
| 102 | 0 | 32 | `scalar` | `uint256` |
| 103 | 0 | 32 | `batcherHash` | `bytes32` |
| 104 | 0 | 8 | `gasLimit` | `uint64` |
| 104 | 8 | 4 | `basefeeScalar` | `uint32` |
| 104 | 12 | 4 | `blobbasefeeScalar` | `uint32` |
| 105 | 0 | 32 | `_resourceConfig` | `struct IResourceMetering.ResourceConfig` |
| 106 | 0 | 4 | `eip1559Denominator` | `uint32` |
| 106 | 4 | 4 | `eip1559Elasticity` | `uint32` |
| 106 | 8 | 4 | `operatorFeeScalar` | `uint32` |
| 106 | 12 | 8 | `operatorFeeConstant` | `uint64` |
| 107 | 0 | 32 | `l2ChainId` | `uint256` |
| 108 | 0 | 20 | `superchainConfig` | `contract ISuperchainConfig` |

### Layout epoch `v4.1.0` (`4f497cae8f`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1600 | `__gap` | `uint256[50]` |
| 51 | 0 | 20 | `_owner` | `address` |
| 52 | 0 | 1568 | `__gap` | `uint256[49]` |
| 101 | 0 | 32 | `overhead` | `uint256` |
| 102 | 0 | 32 | `scalar` | `uint256` |
| 103 | 0 | 32 | `batcherHash` | `bytes32` |
| 104 | 0 | 8 | `gasLimit` | `uint64` |
| 104 | 8 | 4 | `basefeeScalar` | `uint32` |
| 104 | 12 | 4 | `blobbasefeeScalar` | `uint32` |
| 105 | 0 | 32 | `_resourceConfig` | `struct IResourceMetering.ResourceConfig` |
| 106 | 0 | 4 | `eip1559Denominator` | `uint32` |
| 106 | 4 | 4 | `eip1559Elasticity` | `uint32` |
| 106 | 8 | 4 | `operatorFeeScalar` | `uint32` |
| 106 | 12 | 8 | `operatorFeeConstant` | `uint64` |
| 107 | 0 | 32 | `l2ChainId` | `uint256` |
| 108 | 0 | 20 | `superchainConfig` | `contract ISuperchainConfig` |
| 109 | 0 | 32 | `isFeatureEnabled` | `mapping(bytes32 => bool)` |

### Layout epoch `v5.0.0–v9.0.0` (`7a3c985eae`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1600 | `__gap` | `uint256[50]` |
| 51 | 0 | 20 | `_owner` | `address` |
| 52 | 0 | 1568 | `__gap` | `uint256[49]` |
| 101 | 0 | 32 | `overhead` | `uint256` |
| 102 | 0 | 32 | `scalar` | `uint256` |
| 103 | 0 | 32 | `batcherHash` | `bytes32` |
| 104 | 0 | 8 | `gasLimit` | `uint64` |
| 104 | 8 | 4 | `basefeeScalar` | `uint32` |
| 104 | 12 | 4 | `blobbasefeeScalar` | `uint32` |
| 105 | 0 | 32 | `_resourceConfig` | `struct IResourceMetering.ResourceConfig` |
| 106 | 0 | 4 | `eip1559Denominator` | `uint32` |
| 106 | 4 | 4 | `eip1559Elasticity` | `uint32` |
| 106 | 8 | 4 | `operatorFeeScalar` | `uint32` |
| 106 | 12 | 8 | `operatorFeeConstant` | `uint64` |
| 106 | 20 | 2 | `daFootprintGasScalar` | `uint16` |
| 107 | 0 | 32 | `l2ChainId` | `uint256` |
| 108 | 0 | 20 | `superchainConfig` | `contract ISuperchainConfig` |
| 108 | 20 | 8 | `minBaseFee` | `uint64` |
| 109 | 0 | 32 | `isFeatureEnabled` | `mapping(bytes32 => bool)` |

### Position transitions

| release edge | position | classification | before | after |
|---|---:|---|---|---|
| `v1.0.0→v1.1.0` | `106:0` | added | — | `startBlock: uint256` |
| `v1.1.0→v1.2.0` | `106:0` | deleted | `startBlock: uint256` | — |
| `v1.5.0→v1.6.0` | `104:8` | added | — | `basefeeScalar: uint32` |
| `v1.5.0→v1.6.0` | `104:12` | added | — | `blobbasefeeScalar: uint32` |
| `v1.6.0→v1.8.0` | `105:0` | retyped | `_resourceConfig: struct ResourceMetering.ResourceConfig` | `_resourceConfig: struct IResourceMetering.ResourceConfig` |
| `v1.6.0→v1.8.0` | `106:0` | added | — | `eip1559Denominator: uint32` |
| `v1.6.0→v1.8.0` | `106:4` | added | — | `eip1559Elasticity: uint32` |
| `v2.2.0→v3.0.0` | `106:8` | added | — | `operatorFeeScalar: uint32` |
| `v2.2.0→v3.0.0` | `106:12` | added | — | `operatorFeeConstant: uint64` |
| `v3.0.1→v4.0.0` | `107:0` | added | — | `l2ChainId: uint256` |
| `v3.0.1→v4.0.0` | `108:0` | added | — | `superchainConfig: contract ISuperchainConfig` |
| `v4.0.0→v4.1.0` | `109:0` | added | — | `isFeatureEnabled: mapping(bytes32 => bool)` |
| `v4.1.0→v5.0.0` | `106:20` | added | — | `daFootprintGasScalar: uint16` |
| `v4.1.0→v5.0.0` | `108:20` | added | — | `minBaseFee: uint64` |

## L1CrossDomainMessenger

Exists in snapshots `v1.0.0` through `v9.0.0`; `_initialized` position(s): slot 0 offset 20.

### Layout epoch `v1.0.0` (`452c2f92d1`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 20 | `spacer_0_0_20` | `address` |
| 0 | 20 | 1 | `_initialized` | `uint8` |
| 0 | 21 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1600 | `spacer_1_0_1600` | `uint256[50]` |
| 51 | 0 | 20 | `spacer_51_0_20` | `address` |
| 52 | 0 | 1568 | `spacer_52_0_1568` | `uint256[49]` |
| 101 | 0 | 1 | `spacer_101_0_1` | `bool` |
| 102 | 0 | 1568 | `spacer_102_0_1568` | `uint256[49]` |
| 151 | 0 | 32 | `spacer_151_0_32` | `uint256` |
| 152 | 0 | 1568 | `spacer_152_0_1568` | `uint256[49]` |
| 201 | 0 | 32 | `spacer_201_0_32` | `mapping(bytes32 => bool)` |
| 202 | 0 | 32 | `spacer_202_0_32` | `mapping(bytes32 => bool)` |
| 203 | 0 | 32 | `successfulMessages` | `mapping(bytes32 => bool)` |
| 204 | 0 | 20 | `xDomainMsgSender` | `address` |
| 205 | 0 | 30 | `msgNonce` | `uint240` |
| 206 | 0 | 32 | `failedMessages` | `mapping(bytes32 => bool)` |
| 207 | 0 | 1344 | `__gap` | `uint256[42]` |

### Layout epoch `v1.1.0` (`3ea5b0fd2f`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 20 | `spacer_0_0_20` | `address` |
| 0 | 20 | 1 | `_initialized` | `uint8` |
| 0 | 21 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1600 | `spacer_1_0_1600` | `uint256[50]` |
| 51 | 0 | 20 | `spacer_51_0_20` | `address` |
| 52 | 0 | 1568 | `spacer_52_0_1568` | `uint256[49]` |
| 101 | 0 | 1 | `spacer_101_0_1` | `bool` |
| 102 | 0 | 1568 | `spacer_102_0_1568` | `uint256[49]` |
| 151 | 0 | 32 | `spacer_151_0_32` | `uint256` |
| 152 | 0 | 1568 | `spacer_152_0_1568` | `uint256[49]` |
| 201 | 0 | 32 | `spacer_201_0_32` | `mapping(bytes32 => bool)` |
| 202 | 0 | 32 | `spacer_202_0_32` | `mapping(bytes32 => bool)` |
| 203 | 0 | 32 | `successfulMessages` | `mapping(bytes32 => bool)` |
| 204 | 0 | 20 | `xDomainMsgSender` | `address` |
| 205 | 0 | 30 | `msgNonce` | `uint240` |
| 206 | 0 | 32 | `failedMessages` | `mapping(bytes32 => bool)` |
| 207 | 0 | 1344 | `__gap` | `uint256[42]` |
| 249 | 0 | 20 | `PORTAL` | `contract OptimismPortal` |

### Layout epoch `v1.2.0` (`79254ea911`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 20 | `spacer_0_0_20` | `address` |
| 0 | 20 | 1 | `_initialized` | `uint8` |
| 0 | 21 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1600 | `spacer_1_0_1600` | `uint256[50]` |
| 51 | 0 | 20 | `spacer_51_0_20` | `address` |
| 52 | 0 | 1568 | `spacer_52_0_1568` | `uint256[49]` |
| 101 | 0 | 1 | `spacer_101_0_1` | `bool` |
| 102 | 0 | 1568 | `spacer_102_0_1568` | `uint256[49]` |
| 151 | 0 | 32 | `spacer_151_0_32` | `uint256` |
| 152 | 0 | 1568 | `spacer_152_0_1568` | `uint256[49]` |
| 201 | 0 | 32 | `spacer_201_0_32` | `mapping(bytes32 => bool)` |
| 202 | 0 | 32 | `spacer_202_0_32` | `mapping(bytes32 => bool)` |
| 203 | 0 | 32 | `successfulMessages` | `mapping(bytes32 => bool)` |
| 204 | 0 | 20 | `xDomainMsgSender` | `address` |
| 205 | 0 | 30 | `msgNonce` | `uint240` |
| 206 | 0 | 32 | `failedMessages` | `mapping(bytes32 => bool)` |
| 207 | 0 | 1408 | `__gap` | `uint256[44]` |
| 251 | 0 | 20 | `superchainConfig` | `contract SuperchainConfig` |

### Layout epoch `v1.3.0–v1.4.0` (`8fa2624ec8`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 20 | `spacer_0_0_20` | `address` |
| 0 | 20 | 1 | `_initialized` | `uint8` |
| 0 | 21 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1600 | `spacer_1_0_1600` | `uint256[50]` |
| 51 | 0 | 20 | `spacer_51_0_20` | `address` |
| 52 | 0 | 1568 | `spacer_52_0_1568` | `uint256[49]` |
| 101 | 0 | 1 | `spacer_101_0_1` | `bool` |
| 102 | 0 | 1568 | `spacer_102_0_1568` | `uint256[49]` |
| 151 | 0 | 32 | `spacer_151_0_32` | `uint256` |
| 152 | 0 | 1568 | `spacer_152_0_1568` | `uint256[49]` |
| 201 | 0 | 32 | `spacer_201_0_32` | `mapping(bytes32 => bool)` |
| 202 | 0 | 32 | `spacer_202_0_32` | `mapping(bytes32 => bool)` |
| 203 | 0 | 32 | `successfulMessages` | `mapping(bytes32 => bool)` |
| 204 | 0 | 20 | `xDomainMsgSender` | `address` |
| 205 | 0 | 30 | `msgNonce` | `uint240` |
| 206 | 0 | 32 | `failedMessages` | `mapping(bytes32 => bool)` |
| 207 | 0 | 20 | `otherMessenger` | `contract CrossDomainMessenger` |
| 208 | 0 | 1376 | `__gap` | `uint256[43]` |
| 251 | 0 | 20 | `superchainConfig` | `contract SuperchainConfig` |
| 252 | 0 | 20 | `portal` | `contract OptimismPortal` |

### Layout epoch `v1.5.0–v1.6.0` (`a0cb6373d2`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 20 | `spacer_0_0_20` | `address` |
| 0 | 20 | 1 | `_initialized` | `uint8` |
| 0 | 21 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1600 | `spacer_1_0_1600` | `uint256[50]` |
| 51 | 0 | 20 | `spacer_51_0_20` | `address` |
| 52 | 0 | 1568 | `spacer_52_0_1568` | `uint256[49]` |
| 101 | 0 | 1 | `spacer_101_0_1` | `bool` |
| 102 | 0 | 1568 | `spacer_102_0_1568` | `uint256[49]` |
| 151 | 0 | 32 | `spacer_151_0_32` | `uint256` |
| 152 | 0 | 1568 | `spacer_152_0_1568` | `uint256[49]` |
| 201 | 0 | 32 | `spacer_201_0_32` | `mapping(bytes32 => bool)` |
| 202 | 0 | 32 | `spacer_202_0_32` | `mapping(bytes32 => bool)` |
| 203 | 0 | 32 | `successfulMessages` | `mapping(bytes32 => bool)` |
| 204 | 0 | 20 | `xDomainMsgSender` | `address` |
| 205 | 0 | 30 | `msgNonce` | `uint240` |
| 206 | 0 | 32 | `failedMessages` | `mapping(bytes32 => bool)` |
| 207 | 0 | 20 | `otherMessenger` | `contract CrossDomainMessenger` |
| 208 | 0 | 1376 | `__gap` | `uint256[43]` |
| 251 | 0 | 20 | `superchainConfig` | `contract SuperchainConfig` |
| 252 | 0 | 20 | `portal` | `contract OptimismPortal` |
| 253 | 0 | 20 | `systemConfig` | `contract SystemConfig` |

### Layout epoch `v1.8.0` (`d2885248b4`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 20 | `spacer_0_0_20` | `address` |
| 0 | 20 | 1 | `_initialized` | `uint8` |
| 0 | 21 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1600 | `spacer_1_0_1600` | `uint256[50]` |
| 51 | 0 | 20 | `spacer_51_0_20` | `address` |
| 52 | 0 | 1568 | `spacer_52_0_1568` | `uint256[49]` |
| 101 | 0 | 1 | `spacer_101_0_1` | `bool` |
| 102 | 0 | 1568 | `spacer_102_0_1568` | `uint256[49]` |
| 151 | 0 | 32 | `spacer_151_0_32` | `uint256` |
| 152 | 0 | 1568 | `spacer_152_0_1568` | `uint256[49]` |
| 201 | 0 | 32 | `spacer_201_0_32` | `mapping(bytes32 => bool)` |
| 202 | 0 | 32 | `spacer_202_0_32` | `mapping(bytes32 => bool)` |
| 203 | 0 | 32 | `successfulMessages` | `mapping(bytes32 => bool)` |
| 204 | 0 | 20 | `xDomainMsgSender` | `address` |
| 205 | 0 | 30 | `msgNonce` | `uint240` |
| 206 | 0 | 32 | `failedMessages` | `mapping(bytes32 => bool)` |
| 207 | 0 | 20 | `otherMessenger` | `contract CrossDomainMessenger` |
| 208 | 0 | 1376 | `__gap` | `uint256[43]` |
| 251 | 0 | 20 | `superchainConfig` | `contract ISuperchainConfig` |
| 252 | 0 | 20 | `portal` | `contract IOptimismPortal` |
| 253 | 0 | 20 | `systemConfig` | `contract ISystemConfig` |

### Layout epoch `v2.0.0–v3.0.1` (`68d4b520c3`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 20 | `spacer_0_0_20` | `address` |
| 0 | 20 | 1 | `_initialized` | `uint8` |
| 0 | 21 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1600 | `spacer_1_0_1600` | `uint256[50]` |
| 51 | 0 | 20 | `spacer_51_0_20` | `address` |
| 52 | 0 | 1568 | `spacer_52_0_1568` | `uint256[49]` |
| 101 | 0 | 1 | `spacer_101_0_1` | `bool` |
| 102 | 0 | 1568 | `spacer_102_0_1568` | `uint256[49]` |
| 151 | 0 | 32 | `spacer_151_0_32` | `uint256` |
| 152 | 0 | 1568 | `spacer_152_0_1568` | `uint256[49]` |
| 201 | 0 | 32 | `spacer_201_0_32` | `mapping(bytes32 => bool)` |
| 202 | 0 | 32 | `spacer_202_0_32` | `mapping(bytes32 => bool)` |
| 203 | 0 | 32 | `successfulMessages` | `mapping(bytes32 => bool)` |
| 204 | 0 | 20 | `xDomainMsgSender` | `address` |
| 205 | 0 | 30 | `msgNonce` | `uint240` |
| 206 | 0 | 32 | `failedMessages` | `mapping(bytes32 => bool)` |
| 207 | 0 | 20 | `otherMessenger` | `contract CrossDomainMessenger` |
| 208 | 0 | 1376 | `__gap` | `uint256[43]` |
| 251 | 0 | 20 | `superchainConfig` | `contract ISuperchainConfig` |
| 252 | 0 | 20 | `portal` | `contract IOptimismPortal2` |
| 253 | 0 | 20 | `spacer_253_0_20` | `address` |

### Layout epoch `v4.0.0–v9.0.0` (`872a0178da`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 20 | `spacer_0_0_20` | `address` |
| 0 | 20 | 1 | `_initialized` | `uint8` |
| 0 | 21 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1600 | `spacer_1_0_1600` | `uint256[50]` |
| 51 | 0 | 20 | `spacer_51_0_20` | `address` |
| 52 | 0 | 1568 | `spacer_52_0_1568` | `uint256[49]` |
| 101 | 0 | 1 | `spacer_101_0_1` | `bool` |
| 102 | 0 | 1568 | `spacer_102_0_1568` | `uint256[49]` |
| 151 | 0 | 32 | `spacer_151_0_32` | `uint256` |
| 152 | 0 | 1568 | `spacer_152_0_1568` | `uint256[49]` |
| 201 | 0 | 32 | `spacer_201_0_32` | `mapping(bytes32 => bool)` |
| 202 | 0 | 32 | `spacer_202_0_32` | `mapping(bytes32 => bool)` |
| 203 | 0 | 32 | `successfulMessages` | `mapping(bytes32 => bool)` |
| 204 | 0 | 20 | `xDomainMsgSender` | `address` |
| 205 | 0 | 30 | `msgNonce` | `uint240` |
| 206 | 0 | 32 | `failedMessages` | `mapping(bytes32 => bool)` |
| 207 | 0 | 20 | `otherMessenger` | `contract CrossDomainMessenger` |
| 208 | 0 | 1376 | `__gap` | `uint256[43]` |
| 251 | 0 | 20 | `spacer_251_0_20` | `address` |
| 252 | 0 | 20 | `portal` | `contract IOptimismPortal2` |
| 253 | 0 | 20 | `spacer_253_0_20` | `address` |
| 254 | 0 | 20 | `systemConfig` | `contract ISystemConfig` |

### Position transitions

| release edge | position | classification | before | after |
|---|---:|---|---|---|
| `v1.0.0→v1.1.0` | `249:0` | added | — | `PORTAL: contract OptimismPortal` |
| `v1.1.0→v1.2.0` | `207:0` | retyped | `__gap: uint256[42]` | `__gap: uint256[44]` |
| `v1.1.0→v1.2.0` | `249:0` | deleted | `PORTAL: contract OptimismPortal` | — |
| `v1.1.0→v1.2.0` | `251:0` | added | — | `superchainConfig: contract SuperchainConfig` |
| `v1.2.0→v1.3.0` | `207:0` | renamed_and_retyped | `__gap: uint256[44]` | `otherMessenger: contract CrossDomainMessenger` |
| `v1.2.0→v1.3.0` | `208:0` | added | — | `__gap: uint256[43]` |
| `v1.2.0→v1.3.0` | `252:0` | added | — | `portal: contract OptimismPortal` |
| `v1.4.0→v1.5.0` | `253:0` | added | — | `systemConfig: contract SystemConfig` |
| `v1.6.0→v1.8.0` | `251:0` | retyped | `superchainConfig: contract SuperchainConfig` | `superchainConfig: contract ISuperchainConfig` |
| `v1.6.0→v1.8.0` | `252:0` | retyped | `portal: contract OptimismPortal` | `portal: contract IOptimismPortal` |
| `v1.6.0→v1.8.0` | `253:0` | retyped | `systemConfig: contract SystemConfig` | `systemConfig: contract ISystemConfig` |
| `v1.8.0→v2.0.0` | `252:0` | retyped | `portal: contract IOptimismPortal` | `portal: contract IOptimismPortal2` |
| `v1.8.0→v2.0.0` | `253:0` | deleted_to_spacer | `systemConfig: contract ISystemConfig` | `spacer_253_0_20: address` |
| `v3.0.1→v4.0.0` | `251:0` | deleted_to_spacer | `superchainConfig: contract ISuperchainConfig` | `spacer_251_0_20: address` |
| `v3.0.1→v4.0.0` | `254:0` | added | — | `systemConfig: contract ISystemConfig` |

## L1StandardBridge

Exists in snapshots `v1.0.0` through `v9.0.0`; `_initialized` position(s): slot 0 offset 0.

### Layout epoch `v1.0.0` (`306832cdde`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 20 | `spacer_0_0_20` | `address` |
| 1 | 0 | 20 | `spacer_1_0_20` | `address` |
| 2 | 0 | 32 | `deposits` | `mapping(address => mapping(address => uint256))` |
| 3 | 0 | 1504 | `__gap` | `uint256[47]` |

### Layout epoch `v1.1.0` (`e01af5b277`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 0 | 2 | 20 | `spacer_0_2_20` | `address` |
| 1 | 0 | 20 | `spacer_1_0_20` | `address` |
| 2 | 0 | 32 | `deposits` | `mapping(address => mapping(address => uint256))` |
| 3 | 0 | 20 | `messenger` | `contract CrossDomainMessenger` |
| 4 | 0 | 1472 | `__gap` | `uint256[46]` |

### Layout epoch `v1.2.0` (`18b40b16f3`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 0 | 2 | 20 | `spacer_0_2_20` | `address` |
| 1 | 0 | 20 | `spacer_1_0_20` | `address` |
| 2 | 0 | 32 | `deposits` | `mapping(address => mapping(address => uint256))` |
| 3 | 0 | 1504 | `__gap` | `uint256[47]` |
| 50 | 0 | 20 | `superchainConfig` | `contract SuperchainConfig` |

### Layout epoch `v1.3.0–v1.4.0` (`9117a7fa87`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 0 | 2 | 30 | `spacer_0_2_30` | `bytes30` |
| 1 | 0 | 20 | `spacer_1_0_20` | `address` |
| 2 | 0 | 32 | `deposits` | `mapping(address => mapping(address => uint256))` |
| 3 | 0 | 20 | `messenger` | `contract CrossDomainMessenger` |
| 4 | 0 | 20 | `otherBridge` | `contract StandardBridge` |
| 5 | 0 | 1440 | `__gap` | `uint256[45]` |
| 50 | 0 | 20 | `superchainConfig` | `contract SuperchainConfig` |

### Layout epoch `v1.5.0–v1.6.0` (`79041979c8`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 0 | 2 | 30 | `spacer_0_2_30` | `bytes30` |
| 1 | 0 | 20 | `spacer_1_0_20` | `address` |
| 2 | 0 | 32 | `deposits` | `mapping(address => mapping(address => uint256))` |
| 3 | 0 | 20 | `messenger` | `contract CrossDomainMessenger` |
| 4 | 0 | 20 | `otherBridge` | `contract StandardBridge` |
| 5 | 0 | 1440 | `__gap` | `uint256[45]` |
| 50 | 0 | 20 | `superchainConfig` | `contract SuperchainConfig` |
| 51 | 0 | 20 | `systemConfig` | `contract SystemConfig` |

### Layout epoch `v1.8.0` (`4e8bdf6aa8`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 0 | 2 | 30 | `spacer_0_2_30` | `bytes30` |
| 1 | 0 | 20 | `spacer_1_0_20` | `address` |
| 2 | 0 | 32 | `deposits` | `mapping(address => mapping(address => uint256))` |
| 3 | 0 | 20 | `messenger` | `contract ICrossDomainMessenger` |
| 4 | 0 | 20 | `otherBridge` | `contract StandardBridge` |
| 5 | 0 | 1440 | `__gap` | `uint256[45]` |
| 50 | 0 | 20 | `superchainConfig` | `contract ISuperchainConfig` |
| 51 | 0 | 20 | `systemConfig` | `contract ISystemConfig` |

### Layout epoch `v2.0.0–v3.0.1` (`279da8d9f6`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 0 | 2 | 30 | `spacer_0_2_30` | `bytes30` |
| 1 | 0 | 20 | `spacer_1_0_20` | `address` |
| 2 | 0 | 32 | `deposits` | `mapping(address => mapping(address => uint256))` |
| 3 | 0 | 20 | `messenger` | `contract ICrossDomainMessenger` |
| 4 | 0 | 20 | `otherBridge` | `contract StandardBridge` |
| 5 | 0 | 1440 | `__gap` | `uint256[45]` |
| 50 | 0 | 20 | `superchainConfig` | `contract ISuperchainConfig` |
| 51 | 0 | 20 | `spacer_51_0_20` | `address` |

### Layout epoch `v4.0.0–v9.0.0` (`cd426c5eda`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 0 | 2 | 30 | `spacer_0_2_30` | `bytes30` |
| 1 | 0 | 20 | `spacer_1_0_20` | `address` |
| 2 | 0 | 32 | `deposits` | `mapping(address => mapping(address => uint256))` |
| 3 | 0 | 20 | `messenger` | `contract ICrossDomainMessenger` |
| 4 | 0 | 20 | `otherBridge` | `contract StandardBridge` |
| 5 | 0 | 1440 | `__gap` | `uint256[45]` |
| 50 | 0 | 20 | `spacer_50_0_20` | `address` |
| 51 | 0 | 20 | `spacer_51_0_20` | `address` |
| 52 | 0 | 20 | `systemConfig` | `contract ISystemConfig` |

### Position transitions

| release edge | position | classification | before | after |
|---|---:|---|---|---|
| `v1.0.0→v1.1.0` | `0:0` | spacer_consumed | `spacer_0_0_20: address` | `_initialized: uint8` |
| `v1.0.0→v1.1.0` | `0:1` | added | — | `_initializing: bool` |
| `v1.0.0→v1.1.0` | `0:2` | added | — | `spacer_0_2_20: address` |
| `v1.0.0→v1.1.0` | `3:0` | renamed_and_retyped | `__gap: uint256[47]` | `messenger: contract CrossDomainMessenger` |
| `v1.0.0→v1.1.0` | `4:0` | added | — | `__gap: uint256[46]` |
| `v1.1.0→v1.2.0` | `3:0` | renamed_and_retyped | `messenger: contract CrossDomainMessenger` | `__gap: uint256[47]` |
| `v1.1.0→v1.2.0` | `4:0` | deleted | `__gap: uint256[46]` | — |
| `v1.1.0→v1.2.0` | `50:0` | added | — | `superchainConfig: contract SuperchainConfig` |
| `v1.2.0→v1.3.0` | `0:2` | renamed_and_retyped | `spacer_0_2_20: address` | `spacer_0_2_30: bytes30` |
| `v1.2.0→v1.3.0` | `3:0` | renamed_and_retyped | `__gap: uint256[47]` | `messenger: contract CrossDomainMessenger` |
| `v1.2.0→v1.3.0` | `4:0` | added | — | `otherBridge: contract StandardBridge` |
| `v1.2.0→v1.3.0` | `5:0` | added | — | `__gap: uint256[45]` |
| `v1.4.0→v1.5.0` | `51:0` | added | — | `systemConfig: contract SystemConfig` |
| `v1.6.0→v1.8.0` | `3:0` | retyped | `messenger: contract CrossDomainMessenger` | `messenger: contract ICrossDomainMessenger` |
| `v1.6.0→v1.8.0` | `50:0` | retyped | `superchainConfig: contract SuperchainConfig` | `superchainConfig: contract ISuperchainConfig` |
| `v1.6.0→v1.8.0` | `51:0` | retyped | `systemConfig: contract SystemConfig` | `systemConfig: contract ISystemConfig` |
| `v1.8.0→v2.0.0` | `51:0` | deleted_to_spacer | `systemConfig: contract ISystemConfig` | `spacer_51_0_20: address` |
| `v3.0.1→v4.0.0` | `50:0` | deleted_to_spacer | `superchainConfig: contract ISuperchainConfig` | `spacer_50_0_20: address` |
| `v3.0.1→v4.0.0` | `52:0` | added | — | `systemConfig: contract ISystemConfig` |

## L1ERC721Bridge

Exists in snapshots `v1.0.0` through `v9.0.0`; `_initialized` position(s): slot 0 offset 0.

### Layout epoch `v1.0.0` (`c606f5daf3`, manual inheritance reconstruction)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1568 | `__gap` | `uint256[49]` |
| 49 | 0 | 32 | `deposits` | `mapping(address => mapping(address => mapping(uint256 => bool)))` |

### Layout epoch `v1.1.0` (`564a212292`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 0 | 2 | 20 | `messenger` | `contract CrossDomainMessenger` |
| 1 | 0 | 1536 | `__gap` | `uint256[48]` |
| 49 | 0 | 32 | `deposits` | `mapping(address => mapping(address => mapping(uint256 => bool)))` |

### Layout epoch `v1.2.0` (`7772913453`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1536 | `__gap` | `uint256[48]` |
| 49 | 0 | 32 | `deposits` | `mapping(address => mapping(address => mapping(uint256 => bool)))` |
| 50 | 0 | 20 | `superchainConfig` | `contract SuperchainConfig` |

### Layout epoch `v1.3.0–v1.5.0` (`1585cc2af9`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 0 | 2 | 30 | `spacer_0_2_30` | `bytes30` |
| 1 | 0 | 20 | `messenger` | `contract CrossDomainMessenger` |
| 2 | 0 | 20 | `otherBridge` | `contract StandardBridge` |
| 3 | 0 | 1472 | `__gap` | `uint256[46]` |
| 49 | 0 | 32 | `deposits` | `mapping(address => mapping(address => mapping(uint256 => bool)))` |
| 50 | 0 | 20 | `superchainConfig` | `contract SuperchainConfig` |

### Layout epoch `v1.6.0` (`aad9263fbe`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 0 | 2 | 30 | `spacer_0_2_30` | `bytes30` |
| 1 | 0 | 20 | `messenger` | `contract CrossDomainMessenger` |
| 2 | 0 | 20 | `otherBridge` | `contract ERC721Bridge` |
| 3 | 0 | 1472 | `__gap` | `uint256[46]` |
| 49 | 0 | 32 | `deposits` | `mapping(address => mapping(address => mapping(uint256 => bool)))` |
| 50 | 0 | 20 | `superchainConfig` | `contract SuperchainConfig` |

### Layout epoch `v1.8.0–v3.0.1` (`3d135f2e99`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 0 | 2 | 30 | `spacer_0_2_30` | `bytes30` |
| 1 | 0 | 20 | `messenger` | `contract ICrossDomainMessenger` |
| 2 | 0 | 20 | `otherBridge` | `contract ERC721Bridge` |
| 3 | 0 | 1472 | `__gap` | `uint256[46]` |
| 49 | 0 | 32 | `deposits` | `mapping(address => mapping(address => mapping(uint256 => bool)))` |
| 50 | 0 | 20 | `superchainConfig` | `contract ISuperchainConfig` |

### Layout epoch `v4.0.0–v9.0.0` (`070456e8ff`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 0 | 2 | 30 | `spacer_0_2_30` | `bytes30` |
| 1 | 0 | 20 | `messenger` | `contract ICrossDomainMessenger` |
| 2 | 0 | 20 | `otherBridge` | `contract ERC721Bridge` |
| 3 | 0 | 1472 | `__gap` | `uint256[46]` |
| 49 | 0 | 32 | `deposits` | `mapping(address => mapping(address => mapping(uint256 => bool)))` |
| 50 | 0 | 20 | `spacer_50_0_20` | `address` |
| 51 | 0 | 20 | `systemConfig` | `contract ISystemConfig` |

### Position transitions

| release edge | position | classification | before | after |
|---|---:|---|---|---|
| `v1.0.0→v1.1.0` | `0:0` | renamed_and_retyped | `__gap: uint256[49]` | `_initialized: uint8` |
| `v1.0.0→v1.1.0` | `0:1` | added | — | `_initializing: bool` |
| `v1.0.0→v1.1.0` | `0:2` | added | — | `messenger: contract CrossDomainMessenger` |
| `v1.0.0→v1.1.0` | `1:0` | added | — | `__gap: uint256[48]` |
| `v1.1.0→v1.2.0` | `0:2` | deleted | `messenger: contract CrossDomainMessenger` | — |
| `v1.1.0→v1.2.0` | `50:0` | added | — | `superchainConfig: contract SuperchainConfig` |
| `v1.2.0→v1.3.0` | `0:2` | added | — | `spacer_0_2_30: bytes30` |
| `v1.2.0→v1.3.0` | `1:0` | renamed_and_retyped | `__gap: uint256[48]` | `messenger: contract CrossDomainMessenger` |
| `v1.2.0→v1.3.0` | `2:0` | added | — | `otherBridge: contract StandardBridge` |
| `v1.2.0→v1.3.0` | `3:0` | added | — | `__gap: uint256[46]` |
| `v1.5.0→v1.6.0` | `2:0` | retyped | `otherBridge: contract StandardBridge` | `otherBridge: contract ERC721Bridge` |
| `v1.6.0→v1.8.0` | `1:0` | retyped | `messenger: contract CrossDomainMessenger` | `messenger: contract ICrossDomainMessenger` |
| `v1.6.0→v1.8.0` | `50:0` | retyped | `superchainConfig: contract SuperchainConfig` | `superchainConfig: contract ISuperchainConfig` |
| `v3.0.1→v4.0.0` | `50:0` | deleted_to_spacer | `superchainConfig: contract ISuperchainConfig` | `spacer_50_0_20: address` |
| `v3.0.1→v4.0.0` | `51:0` | added | — | `systemConfig: contract ISystemConfig` |

## OptimismMintableERC20Factory

Exists in snapshots `v1.0.0` through `v9.0.0`; `_initialized` position(s): slot 0 offset 0.

### Layout epoch `v1.0.0` (`4f53cda18c`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| — | — | — | *(no compiler-managed storage)* | — |

### Layout epoch `v1.1.0` (`aebd9415c4`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 0 | 2 | 20 | `bridge` | `address` |

### Layout epoch `v1.2.0` (`4f53cda18c`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| — | — | — | *(no compiler-managed storage)* | — |

### Layout epoch `v1.3.0–v1.6.0` (`fcae6dbce7`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 0 | 2 | 30 | `spacer_0_2_30` | `bytes30` |
| 1 | 0 | 20 | `bridge` | `address` |
| 2 | 0 | 1568 | `__gap` | `uint256[49]` |

### Layout epoch `v1.8.0–v9.0.0` (`7d918d4dde`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 0 | 2 | 30 | `spacer_0_2_30` | `bytes30` |
| 1 | 0 | 20 | `bridge` | `address` |
| 2 | 0 | 32 | `deployments` | `mapping(address => address)` |
| 3 | 0 | 1536 | `__gap` | `uint256[48]` |

### Position transitions

| release edge | position | classification | before | after |
|---|---:|---|---|---|
| `v1.0.0→v1.1.0` | `0:0` | added | — | `_initialized: uint8` |
| `v1.0.0→v1.1.0` | `0:1` | added | — | `_initializing: bool` |
| `v1.0.0→v1.1.0` | `0:2` | added | — | `bridge: address` |
| `v1.1.0→v1.2.0` | `0:0` | deleted | `_initialized: uint8` | — |
| `v1.1.0→v1.2.0` | `0:1` | deleted | `_initializing: bool` | — |
| `v1.1.0→v1.2.0` | `0:2` | deleted | `bridge: address` | — |
| `v1.2.0→v1.3.0` | `0:0` | added | — | `_initialized: uint8` |
| `v1.2.0→v1.3.0` | `0:1` | added | — | `_initializing: bool` |
| `v1.2.0→v1.3.0` | `0:2` | added | — | `spacer_0_2_30: bytes30` |
| `v1.2.0→v1.3.0` | `1:0` | added | — | `bridge: address` |
| `v1.2.0→v1.3.0` | `2:0` | added | — | `__gap: uint256[49]` |
| `v1.6.0→v1.8.0` | `2:0` | renamed_and_retyped | `__gap: uint256[49]` | `deployments: mapping(address => address)` |
| `v1.6.0→v1.8.0` | `3:0` | added | — | `__gap: uint256[48]` |

## SuperchainConfig

Exists in snapshots `v1.2.0` through `v9.0.0`; `_initialized` position(s): slot 0 offset 0.

### Layout epoch `v1.2.0–v3.0.1` (`ebfb8de3d9`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |

### Layout epoch `v4.0.0–v9.0.0` (`e355567118`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 0 | 2 | 20 | `guardian` | `address` |
| 1 | 0 | 32 | `pauseTimestamps` | `mapping(address => uint256)` |

### Position transitions

| release edge | position | classification | before | after |
|---|---:|---|---|---|
| `v3.0.1→v4.0.0` | `0:2` | added | — | `guardian: address` |
| `v3.0.1→v4.0.0` | `1:0` | added | — | `pauseTimestamps: mapping(address => uint256)` |

## ProtocolVersions

Exists in snapshots `v1.1.0` through `v7.0.0`; `_initialized` position(s): slot 0 offset 0.

### Layout epoch `v1.1.0` (`614a803a42`, manual inheritance reconstruction)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1600 | `__gap` | `uint256[50]` |
| 51 | 0 | 20 | `_owner` | `address` |
| 52 | 0 | 1568 | `__gap` | `uint256[49]` |

### Layout epoch `v1.2.0–v7.0.0` (`614a803a42`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1600 | `__gap` | `uint256[50]` |
| 51 | 0 | 20 | `_owner` | `address` |
| 52 | 0 | 1568 | `__gap` | `uint256[49]` |

## DisputeGameFactory

Exists in snapshots `v1.0.0` through `v9.0.0`; `_initialized` position(s): slot 0 offset 0.

### Layout epoch `v1.0.0` (`9df5212a5a`, manual inheritance reconstruction)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 20 | `_owner` | `address` |
| 1 | 0 | 32 | `gameImpls` | `mapping(GameType => contract IDisputeGame)` |
| 2 | 0 | 32 | `disputeGames` | `mapping(Hash => contract IDisputeGame)` |

### Layout epoch `v1.1.0` (`7be3b56e99`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1600 | `__gap` | `uint256[50]` |
| 51 | 0 | 20 | `_owner` | `address` |
| 52 | 0 | 1568 | `__gap` | `uint256[49]` |
| 101 | 0 | 32 | `gameImpls` | `mapping(GameType => contract IDisputeGame)` |
| 102 | 0 | 32 | `_disputeGames` | `mapping(Hash => GameId)` |
| 103 | 0 | 32 | `_disputeGameList` | `GameId[]` |

### Layout epoch `v1.2.0–v4.1.0` (`e6df2ad51c`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1600 | `__gap` | `uint256[50]` |
| 51 | 0 | 20 | `_owner` | `address` |
| 52 | 0 | 1568 | `__gap` | `uint256[49]` |
| 101 | 0 | 32 | `gameImpls` | `mapping(GameType => contract IDisputeGame)` |
| 102 | 0 | 32 | `initBonds` | `mapping(GameType => uint256)` |
| 103 | 0 | 32 | `_disputeGames` | `mapping(Hash => GameId)` |
| 104 | 0 | 32 | `_disputeGameList` | `GameId[]` |

### Layout epoch `v5.0.0–v9.0.0` (`2226ada8da`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1600 | `__gap` | `uint256[50]` |
| 51 | 0 | 20 | `_owner` | `address` |
| 52 | 0 | 1568 | `__gap` | `uint256[49]` |
| 101 | 0 | 32 | `gameImpls` | `mapping(GameType => contract IDisputeGame)` |
| 102 | 0 | 32 | `initBonds` | `mapping(GameType => uint256)` |
| 103 | 0 | 32 | `_disputeGames` | `mapping(Hash => GameId)` |
| 104 | 0 | 32 | `_disputeGameList` | `GameId[]` |
| 105 | 0 | 32 | `gameArgs` | `mapping(GameType => bytes)` |

### Position transitions

| release edge | position | classification | before | after |
|---|---:|---|---|---|
| `v1.0.0→v1.1.0` | `0:0` | renamed_and_retyped | `_owner: address` | `_initialized: uint8` |
| `v1.0.0→v1.1.0` | `0:1` | added | — | `_initializing: bool` |
| `v1.0.0→v1.1.0` | `1:0` | renamed_and_retyped | `gameImpls: mapping(GameType => contract IDisputeGame)` | `__gap: uint256[50]` |
| `v1.0.0→v1.1.0` | `2:0` | deleted | `disputeGames: mapping(Hash => contract IDisputeGame)` | — |
| `v1.0.0→v1.1.0` | `51:0` | added | — | `_owner: address` |
| `v1.0.0→v1.1.0` | `52:0` | added | — | `__gap: uint256[49]` |
| `v1.0.0→v1.1.0` | `101:0` | added | — | `gameImpls: mapping(GameType => contract IDisputeGame)` |
| `v1.0.0→v1.1.0` | `102:0` | added | — | `_disputeGames: mapping(Hash => GameId)` |
| `v1.0.0→v1.1.0` | `103:0` | added | — | `_disputeGameList: GameId[]` |
| `v1.1.0→v1.2.0` | `102:0` | renamed_and_retyped | `_disputeGames: mapping(Hash => GameId)` | `initBonds: mapping(GameType => uint256)` |
| `v1.1.0→v1.2.0` | `103:0` | renamed_and_retyped | `_disputeGameList: GameId[]` | `_disputeGames: mapping(Hash => GameId)` |
| `v1.1.0→v1.2.0` | `104:0` | added | — | `_disputeGameList: GameId[]` |
| `v4.1.0→v5.0.0` | `105:0` | added | — | `gameArgs: mapping(GameType => bytes)` |

## AnchorStateRegistry

Exists in snapshots `v1.4.0` through `v9.0.0`; `_initialized` position(s): slot 0 offset 0.

### Layout epoch `v1.4.0–v1.5.0` (`219eb22aaa`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 32 | `anchors` | `mapping(GameType => struct OutputRoot)` |

### Layout epoch `v1.6.0` (`94e8350f0a`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 32 | `anchors` | `mapping(GameType => struct OutputRoot)` |
| 2 | 0 | 20 | `superchainConfig` | `contract SuperchainConfig` |

### Layout epoch `v1.8.0` (`cf67572e45`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 32 | `anchors` | `mapping(GameType => struct OutputRoot)` |
| 2 | 0 | 20 | `superchainConfig` | `contract ISuperchainConfig` |

### Layout epoch `v2.0.0–v3.0.1` (`60fa170646`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 0 | 2 | 20 | `superchainConfig` | `contract ISuperchainConfig` |
| 1 | 0 | 20 | `disputeGameFactory` | `contract IDisputeGameFactory` |
| 2 | 0 | 20 | `portal` | `contract IOptimismPortal2` |
| 3 | 0 | 20 | `anchorGame` | `contract IFaultDisputeGame` |
| 4 | 0 | 64 | `startingAnchorRoot` | `struct OutputRoot` |

### Layout epoch `v4.0.0–v6.0.0` (`c3a8020f9d`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 0 | 2 | 20 | `systemConfig` | `contract ISystemConfig` |
| 1 | 0 | 20 | `disputeGameFactory` | `contract IDisputeGameFactory` |
| 2 | 0 | 20 | `anchorGame` | `contract IFaultDisputeGame` |
| 3 | 0 | 64 | `startingAnchorRoot` | `struct Proposal` |
| 5 | 0 | 32 | `disputeGameBlacklist` | `mapping(contract IDisputeGame => bool)` |
| 6 | 0 | 4 | `respectedGameType` | `GameType` |
| 6 | 4 | 8 | `retirementTimestamp` | `uint64` |

### Layout epoch `v7.0.0–v8.0.0` (`fde3a5fbfc`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 0 | 2 | 20 | `systemConfig` | `contract ISystemConfig` |
| 1 | 0 | 20 | `disputeGameFactory` | `contract IDisputeGameFactory` |
| 2 | 0 | 20 | `anchorGame` | `contract IDisputeGame` |
| 3 | 0 | 64 | `startingAnchorRoot` | `struct Proposal` |
| 5 | 0 | 32 | `disputeGameBlacklist` | `mapping(contract IDisputeGame => bool)` |
| 6 | 0 | 4 | `respectedGameType` | `GameType` |
| 6 | 4 | 8 | `retirementTimestamp` | `uint64` |

### Layout epoch `v9.0.0` (`e1faffb65f`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 0 | 2 | 20 | `spacer_0_2_20` | `address` |
| 1 | 0 | 20 | `disputeGameFactory` | `contract IDisputeGameFactory` |
| 2 | 0 | 20 | `anchorGame` | `contract IDisputeGame` |
| 3 | 0 | 64 | `startingAnchorRoot` | `struct Proposal` |
| 5 | 0 | 32 | `disputeGameBlacklist` | `mapping(contract IDisputeGame => bool)` |
| 6 | 0 | 4 | `respectedGameType` | `GameType` |
| 6 | 4 | 8 | `retirementTimestamp` | `uint64` |
| 6 | 12 | 20 | `ethLockbox` | `contract IETHLockbox` |

### Position transitions

| release edge | position | classification | before | after |
|---|---:|---|---|---|
| `v1.5.0→v1.6.0` | `2:0` | added | — | `superchainConfig: contract SuperchainConfig` |
| `v1.6.0→v1.8.0` | `2:0` | retyped | `superchainConfig: contract SuperchainConfig` | `superchainConfig: contract ISuperchainConfig` |
| `v1.8.0→v2.0.0` | `0:2` | added | — | `superchainConfig: contract ISuperchainConfig` |
| `v1.8.0→v2.0.0` | `1:0` | renamed_and_retyped | `anchors: mapping(GameType => struct OutputRoot)` | `disputeGameFactory: contract IDisputeGameFactory` |
| `v1.8.0→v2.0.0` | `2:0` | renamed_and_retyped | `superchainConfig: contract ISuperchainConfig` | `portal: contract IOptimismPortal2` |
| `v1.8.0→v2.0.0` | `3:0` | added | — | `anchorGame: contract IFaultDisputeGame` |
| `v1.8.0→v2.0.0` | `4:0` | added | — | `startingAnchorRoot: struct OutputRoot` |
| `v3.0.1→v4.0.0` | `0:2` | renamed_and_retyped | `superchainConfig: contract ISuperchainConfig` | `systemConfig: contract ISystemConfig` |
| `v3.0.1→v4.0.0` | `2:0` | renamed_and_retyped | `portal: contract IOptimismPortal2` | `anchorGame: contract IFaultDisputeGame` |
| `v3.0.1→v4.0.0` | `3:0` | renamed_and_retyped | `anchorGame: contract IFaultDisputeGame` | `startingAnchorRoot: struct Proposal` |
| `v3.0.1→v4.0.0` | `4:0` | deleted | `startingAnchorRoot: struct OutputRoot` | — |
| `v3.0.1→v4.0.0` | `5:0` | added | — | `disputeGameBlacklist: mapping(contract IDisputeGame => bool)` |
| `v3.0.1→v4.0.0` | `6:0` | added | — | `respectedGameType: GameType` |
| `v3.0.1→v4.0.0` | `6:4` | added | — | `retirementTimestamp: uint64` |
| `v6.0.0→v7.0.0` | `2:0` | retyped | `anchorGame: contract IFaultDisputeGame` | `anchorGame: contract IDisputeGame` |
| `v8.0.0→v9.0.0` | `0:2` | deleted_to_spacer | `systemConfig: contract ISystemConfig` | `spacer_0_2_20: address` |
| `v8.0.0→v9.0.0` | `6:12` | added | — | `ethLockbox: contract IETHLockbox` |

## DelayedWETH

Exists in snapshots `v1.4.0` through `v9.0.0`; `_initialized` position(s): slot 0 offset 0.

### Layout epoch `v1.4.0–v1.6.0` (`c7abf90ff4`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1600 | `__gap` | `uint256[50]` |
| 51 | 0 | 20 | `_owner` | `address` |
| 52 | 0 | 1568 | `__gap` | `uint256[49]` |
| 101 | 0 | 32 | `balanceOf` | `mapping(address => uint256)` |
| 102 | 0 | 32 | `allowance` | `mapping(address => mapping(address => uint256))` |
| 103 | 0 | 32 | `withdrawals` | `mapping(address => mapping(address => struct IDelayedWETH.WithdrawalRequest))` |
| 104 | 0 | 20 | `config` | `contract SuperchainConfig` |

### Layout epoch `v1.8.0–v3.0.1` (`d7113a1c07`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 1600 | `__gap` | `uint256[50]` |
| 51 | 0 | 20 | `_owner` | `address` |
| 52 | 0 | 1568 | `__gap` | `uint256[49]` |
| 101 | 0 | 32 | `_balanceOf` | `mapping(address => uint256)` |
| 102 | 0 | 32 | `_allowance` | `mapping(address => mapping(address => uint256))` |
| 103 | 0 | 32 | `withdrawals` | `mapping(address => mapping(address => struct DelayedWETH.WithdrawalRequest))` |
| 104 | 0 | 20 | `config` | `contract ISuperchainConfig` |

### Layout epoch `v4.0.0–v8.0.0` (`f2cb2af09b`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 32 | `_balanceOf` | `mapping(address => uint256)` |
| 2 | 0 | 32 | `_allowance` | `mapping(address => mapping(address => uint256))` |
| 3 | 0 | 32 | `withdrawals` | `mapping(address => mapping(address => struct DelayedWETH.WithdrawalRequest))` |
| 4 | 0 | 20 | `systemConfig` | `contract ISystemConfig` |

### Layout epoch `v9.0.0` (`c4f9c671b8`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 1 | 0 | 32 | `_balanceOf` | `mapping(address => uint256)` |
| 2 | 0 | 32 | `_allowance` | `mapping(address => mapping(address => uint256))` |
| 3 | 0 | 32 | `withdrawals` | `mapping(address => mapping(address => struct DelayedWETH.WithdrawalRequest))` |
| 4 | 0 | 20 | `spacer_4_0_20` | `address` |
| 5 | 0 | 20 | `ethLockbox` | `contract IETHLockbox` |

### Position transitions

| release edge | position | classification | before | after |
|---|---:|---|---|---|
| `v1.6.0→v1.8.0` | `101:0` | renamed | `balanceOf: mapping(address => uint256)` | `_balanceOf: mapping(address => uint256)` |
| `v1.6.0→v1.8.0` | `102:0` | renamed | `allowance: mapping(address => mapping(address => uint256))` | `_allowance: mapping(address => mapping(address => uint256))` |
| `v1.6.0→v1.8.0` | `103:0` | retyped | `withdrawals: mapping(address => mapping(address => struct IDelayedWETH.WithdrawalRequest))` | `withdrawals: mapping(address => mapping(address => struct DelayedWETH.WithdrawalRequest))` |
| `v1.6.0→v1.8.0` | `104:0` | retyped | `config: contract SuperchainConfig` | `config: contract ISuperchainConfig` |
| `v3.0.1→v4.0.0` | `1:0` | renamed_and_retyped | `__gap: uint256[50]` | `_balanceOf: mapping(address => uint256)` |
| `v3.0.1→v4.0.0` | `2:0` | added | — | `_allowance: mapping(address => mapping(address => uint256))` |
| `v3.0.1→v4.0.0` | `3:0` | added | — | `withdrawals: mapping(address => mapping(address => struct DelayedWETH.WithdrawalRequest))` |
| `v3.0.1→v4.0.0` | `4:0` | added | — | `systemConfig: contract ISystemConfig` |
| `v3.0.1→v4.0.0` | `51:0` | deleted | `_owner: address` | — |
| `v3.0.1→v4.0.0` | `52:0` | deleted | `__gap: uint256[49]` | — |
| `v3.0.1→v4.0.0` | `101:0` | deleted | `_balanceOf: mapping(address => uint256)` | — |
| `v3.0.1→v4.0.0` | `102:0` | deleted | `_allowance: mapping(address => mapping(address => uint256))` | — |
| `v3.0.1→v4.0.0` | `103:0` | deleted | `withdrawals: mapping(address => mapping(address => struct DelayedWETH.WithdrawalRequest))` | — |
| `v3.0.1→v4.0.0` | `104:0` | deleted | `config: contract ISuperchainConfig` | — |
| `v8.0.0→v9.0.0` | `4:0` | deleted_to_spacer | `systemConfig: contract ISystemConfig` | `spacer_4_0_20: address` |
| `v8.0.0→v9.0.0` | `5:0` | added | — | `ethLockbox: contract IETHLockbox` |

## ETHLockbox

Exists in snapshots `v4.0.0` through `v9.0.0`; `_initialized` position(s): slot 0 offset 0.

### Layout epoch `v4.0.0–v8.0.0` (`55f4cdbae7`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 0 | 2 | 20 | `systemConfig` | `contract ISystemConfig` |
| 1 | 0 | 32 | `authorizedPortals` | `mapping(contract IOptimismPortal2 => bool)` |
| 2 | 0 | 32 | `authorizedLockboxes` | `mapping(contract IETHLockbox => bool)` |

### Layout epoch `v9.0.0` (`f96ce50203`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 1 | `_initialized` | `uint8` |
| 0 | 1 | 1 | `_initializing` | `bool` |
| 0 | 2 | 20 | `spacer_0_2_20` | `address` |
| 1 | 0 | 32 | `authorizedPortals` | `mapping(contract IOptimismPortal2 => bool)` |
| 2 | 0 | 32 | `authorizedLockboxes` | `mapping(contract IETHLockbox => bool)` |
| 3 | 0 | 20 | `superchainConfig` | `contract ISuperchainConfig` |

### Position transitions

| release edge | position | classification | before | after |
|---|---:|---|---|---|
| `v8.0.0→v9.0.0` | `0:2` | deleted_to_spacer | `systemConfig: contract ISystemConfig` | `spacer_0_2_20: address` |
| `v8.0.0→v9.0.0` | `3:0` | added | — | `superchainConfig: contract ISuperchainConfig` |

## AddressManager

Exists in snapshots `v1.0.0` through `v9.0.0`; no `_initialized` field.

### Layout epoch `v1.0.0–v1.1.0` (`973240048d`, manual inheritance reconstruction)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 20 | `_owner` | `address` |
| 1 | 0 | 32 | `addresses` | `mapping(bytes32 => address)` |

### Layout epoch `v1.2.0–v9.0.0` (`973240048d`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 20 | `_owner` | `address` |
| 1 | 0 | 32 | `addresses` | `mapping(bytes32 => address)` |

## ProxyAdmin

Exists in snapshots `v1.0.0` through `v9.0.0`; no `_initialized` field.

### Layout epoch `v1.0.0–v1.6.0` (`a50d967ea3`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 20 | `_owner` | `address` |
| 1 | 0 | 32 | `proxyType` | `mapping(address => enum ProxyAdmin.ProxyType)` |
| 2 | 0 | 32 | `implementationName` | `mapping(address => string)` |
| 3 | 0 | 20 | `addressManager` | `contract AddressManager` |
| 3 | 20 | 1 | `upgrading` | `bool` |

### Layout epoch `v1.8.0–v9.0.0` (`d3589151fe`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 20 | `_owner` | `address` |
| 1 | 0 | 32 | `proxyType` | `mapping(address => enum ProxyAdmin.ProxyType)` |
| 2 | 0 | 32 | `implementationName` | `mapping(address => string)` |
| 3 | 0 | 20 | `addressManager` | `contract IAddressManager` |
| 3 | 20 | 1 | `upgrading` | `bool` |

### Position transitions

| release edge | position | classification | before | after |
|---|---:|---|---|---|
| `v1.6.0→v1.8.0` | `3:0` | retyped | `addressManager: contract AddressManager` | `addressManager: contract IAddressManager` |

## ResolvedDelegateProxy

Exists in snapshots `v1.0.0` through `v9.0.0`; no `_initialized` field.

### Layout epoch `v1.0.0–v1.1.0` (`0189fb0491`, manual inheritance reconstruction)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 32 | `implementationName` | `mapping(address => string)` |
| 1 | 0 | 32 | `addressManager` | `mapping(address => contract AddressManager)` |

### Layout epoch `v1.2.0–v9.0.0` (`0189fb0491`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| 0 | 0 | 32 | `implementationName` | `mapping(address => string)` |
| 1 | 0 | 32 | `addressManager` | `mapping(address => contract AddressManager)` |

## L1ChugSplashProxy

Exists in snapshots `v1.0.0` through `v9.0.0`; no `_initialized` field.

### Layout epoch `v1.0.0–v9.0.0` (`4f53cda18c`, compiler snapshot)

| slot | off | bytes | label | type |
|---:|---:|---:|---|---|
| — | — | — | *(no compiler-managed storage)* | — |

## Analytical production history

The source tables above are complete. The remainder of this report binds them to deployed
OP Mainnet state, mapping entries, initializer transitions, raw-slot consumers and fork tests.

<!-- CF4_ANALYSIS_APPEND -->
