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

## Evidence binding the layouts to OP Mainnet

All chain reads in this section use the passive archive proxy `http://127.0.0.1:7545` and are
pinned at, or bounded by, Ethereum block `26433900`. No transaction was submitted. The machine-
readable evidence is split so that each claim can be reproduced without trusting this prose:

- `evidence/proxy-upgrade-events.json`: `170` `Upgraded` logs and `70` AddressManager
  `AddressSet` logs, scanned in ranges of at most 10,000 blocks.
- `evidence/op-mainnet-storage-history.json`: implementation history, every requested direct slot
  before and after every implementation change, EIP-1967/admin/OZ-v5 slots, ChugSplash binary
  searches, and ResolvedDelegateProxy special mappings.
- `evidence/direct-slot-liveness.json`: every numbered slot observed non-zero at those boundaries,
  its changes/clears, and its v9 field interpretation.
- `evidence/state-event-census.json` and `evidence/mapping-archaeology.json`: complete event coverage
  and exact hashed mapping entries.
- `evidence/implementation-initializer-locks.json`: direct storage, balance, bytecode and semver reads
  for all 102 distinct implementation/helper addresses observed in proxy history.
- `evidence/game-generation-samples.json` and `evidence/sibling-portal-births.json`: generation and
  sibling-chain checks.

“Ever non-zero” in `direct-slot-liveness.json` is exact at every requested pre/post implementation
boundary. A runtime write followed by a clear entirely between two upgrades cannot be recovered
from archive snapshots alone; mapping writes are therefore handled independently through their
emitting events. This distinction is preserved in the JSON rather than inferred away.

## Real implementation history

The following are the persistent implementation-change blocks. Each listed block has a full
`block-1`/`block` slot dump in `op-mainnet-storage-history.json`; the table is only an index.

| deployment | creation | persistent implementation-change blocks | final version; initializer |
|---|---:|---|---|
| OptimismPortal | 17365802 | 17423158, 19314493, 19634866, 20062696, 22182531, 22339996, 22990599, 23491328, 23877377, 24421512, 25397811, 26048619, 26430859 | 6.1.0; slot 0 off 0 = 3 |
| SystemConfig | 17365804 | 17422444, 19314493, 19634866, 20062696, 21695024, 22182531, 22339996, 22990599, 23491328, 23877377, 24421512, 25397811, 26048619, 26430859 | 4.3.0; slot 0 off 0 = 3 |
| L2OutputOracle | 17365801 | 17423158, 19314493, 19634866 | 1.8.0; slot 0 off 0 = 1 |
| L1CrossDomainMessenger | 12686757 | 12686756, 12706528, 13596294, 13596781, 17422444, 17423158, 19314493, 19634866, 22182531, 22339996, 22990599, 23491328, 23877377, 25397811, 26430859 | 2.13.0; slot 0 off 20 = 3 |
| L1StandardBridge | 12686786 | 12686787, 13596915, 17423158, 19314493, 19634866, 22182531, 22339996, 22990599, 23491328, 23877377, 25397811 | 2.8.2; slot 0 off 0 = 3 |
| L1ERC721Bridge | 15677422 | 15677648, 19314493, 19634866, 22182531, 22339996, 22990599, 23491328, 23877377, 25397811 | 2.9.1; slot 0 off 0 = 3 |
| OptimismMintableERC20Factory | 17365803 | 17423158, 19314493, 19634866, 22182531, 23877377, 25397811 | 1.11.0; slot 0 off 0 = 1 |
| SuperchainConfig | 19064589 | 19064589, 22182531, 22990599, 23877377, 25397811, 26048619, 26430859 | 2.5.0; slot 0 off 0 = 2 |
| ProtocolVersions | 18367300 | 18367320, 22182531 | 1.1.0; slot 0 off 0 = 3 |
| DisputeGameFactory | 19884569 | 19884570, 22182531, 22990599, 23877377, 24421512, 25397811 | 1.6.1; slot 0 off 0 = 1 |
| AnchorStateRegistry gen0 / gen1 / current | 19884569 / 22182531 / 22990599 | 19884570, 20723924 / 22182531 / 22990599, 24421512, 25397811, 26430859 | 2.0.0 / 2.2.2 / 4.0.0; each = 1 |
| DelayedWETH gen0 / gen1 / current | 19884569 / 21379271 / 25397811 | 19884570 / 21379272, 22182531 / 25397811, 26430859 | 1.0.0 / 1.3.0 / 2.0.0; each = 1 |
| ETHLockbox | 22990599 | 22990599, 25397811, 26430859 | 2.0.0; slot 0 off 0 = 1 |

The L1StandardBridge rows were found by coarse sampling followed by binary search of its
implementation slot because L1ChugSplashProxy does not give the EIP-1967 event history. The
messenger's EIP-1967 implementation slot is intentionally zero: its current target
`0x7d4ec7fb1a1b9e6d61c04d5e21e3d68cff639448` resolves through AddressManager. At block 26433900,
the two ResolvedDelegateProxy entries are the short-string word for
`OVM_L1CrossDomainMessenger` and AddressManager `0xde1fcf...bd81f`; this is the same derivation the
v9 fetch script uses (`scripts/FetchChainInfo.s.sol:559` and `:562`). AddressManager itself has only
slot 0 non-zero (owner `0x543ba4...6fb04`); ProxyAdmin has slots 0 and 3 non-zero (owner and
AddressManager). Their mappings are hashed, not direct numbered slots.

There were also same-block temporary implementation sequences. At blocks 26048619 and 26430859,
the common temporary implementation was `0x2476c9...c9bb` (StorageSetter); every affected proxy's
block-final implementation and initializer were restored. The exact event sequences and
transaction hashes are retained under `transient_same_block_event_sequences`.

## Non-zero legacy spacers at the cutoff

The mainnet history does contain stale values, but every production case is still a spacer rather
than a new live field. The most important cutoff values are:

| proxy / slot | historical value retained | v9 interpretation |
|---|---|---|
| Portal 53, offset 1 | SuperchainConfig `0x95703e...4c00` | `spacer_53_1_20` |
| Portal 54 | L2OutputOracle `0xdfe978...5a27` | `spacer_54_0_20` |
| Portal 56 | DisputeGameFactory `0xe5965a...52fa9` | `spacer_56_0_20` |
| Portal 59 | game type 0 + update time `0x66e1c083` | packed `spacer_59_0_4` / `spacer_59_4_8` |
| L1CDM 151 | legacy reentrancy status `1` | `spacer_151_0_32` |
| L1CDM 251 | SuperchainConfig `0x95703e...4c00` | `spacer_251_0_20` |
| L1StandardBridge 1 | L2 bridge `0x4200...0010` | `spacer_1_0_20` |
| L1StandardBridge 50 | SuperchainConfig `0x95703e...4c00` | `spacer_50_0_20` |
| L1ERC721Bridge 50 | SuperchainConfig `0x95703e...4c00` | `spacer_50_0_20` |
| current DelayedWETH 4 | SystemConfig `0x229047...b290` | `spacer_4_0_20` |

No v9 execution path was found that reads these stale words. Portal compatibility getters now
resolve through ETHLockbox or AnchorStateRegistry (`src/L1/OptimismPortal2.sol:306`, `:316`,
`:322`, and `:338`–`:358`). StandardValidator uses public getters and ProxyAdmin implementation
queries (`src/L1/OPContractsManagerStandardValidator.sol:246`–`:259`, `:323`–`:343`, and
`:356`–`:371`), not a stale spacer. The only relevant raw reads/writes found were:

- OPCM masks the requested `_initialized` byte and checks the OZ-v5 namespace
  (`src/L1/opcm/OPContractsManagerUtils.sol:352`–`:386`).
- deployment assertions read messenger slot 204 and require portal slot 61 to be zero
  (`scripts/deploy/ChainAssertions.sol:129`–`:136` and `:285`–`:287`).
- artifact helpers derive `_initialized` slot and offset rather than hard-code a data field
  (`scripts/libraries/ForgeArtifacts.sol:153`–`:185`, `:207`–`:222`).
- the fetch script reads only the ResolvedDelegateProxy AddressManager mapping described above.

StorageSetter itself is deliberately arbitrary (`src/universal/StorageSetter.sol:10`–`:41`), but
it is only an intermediate implementation in the observed transactions. This search found no
OPCM, validator, migrator, assertion or v9 contract reader for portal slots 52/53/54/56/58/59,
messenger slots 201/202/251, bridge slots 1/50, or DelayedWETH slot 4 except where the slot is
explicitly treated as initializer metadata.

## Mapping archaeology

### Portal withdrawals

Legacy OptimismPortal uses base slot 52 with shape
`bytes32 => { bytes32 outputRoot; uint128 timestamp; uint128 l2OutputIndex }`; the declaration and
field order are pinned at v1.8.0 `src/L1/OptimismPortal.sol:49`–`:57` and `:73`–`:77`. A proof
writes both struct words (`:323`–`:330`), while finalization marks the independent mapping at slot
51 and does not delete the proof (`:344`–`:392`).

Three independently sampled final pre-fault-proof entries were zero in the block before their
events, written in the event block, and unchanged at 26433900. The last is:

```text
WithdrawalProven block: 20061894
withdrawalHash: 0x90f452af6d735b015fafdb92a6f0d765ad14acdd229166bee485c852da78f89b
keccak256(hash, 52): 0xdc7252e035ad64946129667d8cdadc407bf932fc416e009b9306b9f8a06a2e9f
word 0/current: 0xcd32bd39ad8f68e8c60f8bff1885a6fe80107c8a287859ee08d5a31cbc9c2aa2
word 1/current: 0x000000000000000000000000000022ac0000000000000000000000006667073f
```

Therefore legacy-format `provenWithdrawals` entries **do still exist** in live OP Mainnet storage,
at hashed entries under base slot 52. They are not reachable through v9. V9 reserves only the base
as `spacer_52_0_32` and uses nested base slot 57 (`op-v9.0.0/src/L1/OptimismPortal2.sol:64`–`:67`
and `:94`–`:116`). `deleteProvenWithdrawal` first loads `[hash][submitter]` from slot 57 and reverts
when its timestamp is zero; it reaches `status()` only afterwards (`:711`–`:725`). The named fork
test `testLegacyPortalProofSlot52IsNonzeroButV9DeleteDoesNotReachIt` overwrites both exact legacy
hashed words with all-ones junk, observes a zero v9 getter, and gets
`OptimismPortal_Unproven()` before an external call.

The current nested shape is `[withdrawalHash][proofSubmitter] => { disputeGameProxy, uint64
timestamp }`, with `proofSubmitters[hash]` at base 60. For the first retained fault-proof sample at
block 20062997, hash `0x27f4cd...d3fd` and submitter `0x681089...8e4d` produced non-zero slot
`0xcfe3a1...c83d`; its submitter-array length grew from 1 then to 3 by the cutoff, showing ordinary
re-proving rather than a legacy alias. `finalizedWithdrawals` remains base slot 51 in every portal
release; three late samples changed zero to one in their finalization blocks and remained one.

Portal-local blacklist/respected state existed at bases 58/59 through v3.0.1 and became spacers at
v4.0.0. The full census found two portal `RespectedGameTypeSet` events (blocks 20543021 and
20728464), explaining the stale packed slot-59 value, but zero blacklist events. The current
AnchorStateRegistry holds blacklist at base 5 and packs game type / retirement timestamp /
ETHLockbox at slot 6; at the cutoff slot 6 is
`0x322b47ff1fa8d5611f761e3e275c45b71b294d4300000000688271ab00000009`.
Its declarations are `src/dispute/AnchorStateRegistry.sol:38`–`:59`, and every blacklist write emits
the scanned event (`:177`–`:185`). No blacklist entry was evidenced in any of the three registry
generations.

### Messenger and bridges

The messenger retains legacy base slots 201/202 as `blockedMessages`/`relayedMessages` spacers;
active receipt mappings have remained `successfulMessages` at 203 and `failedMessages` at 206 in
every op-contracts release. The v9 declarations are
`src/universal/CrossDomainMessenger.sol:70`–`:78` and `:119`–`:138`. An earliest production relay
sample from block 12739629 has hash `0xec7c23...ef69`; its slot-203 entry was one immediately after
the event and remains one, while its entries under 201/202/206 are zero. The fork test
`testLegacyMessengerNamespacesRemainDisjointUnderJunk` writes all-ones to the exact 201 and 202
hashed entries and confirms the public successful/failed getters are unchanged. A post-Bedrock
failure sample at block 17941194 and a late sample at 26385051 both set and retain slot 206.

There is no L1 `sentMessages` storage mapping in the v1–v9 lineage: `SentMessage` is an event and
slot 205 is the packed `msgNonce`. At the cutoff slot 204 is the default sender `0x...dead` and slot
205 is `0x42a6d` (273005), exactly the census count of `SentMessageExtension1` events. The complete
census counted 629621 `SentMessage`, 46254 `RelayedMessage`, and 137 `FailedRelayedMessage` logs.

L1StandardBridge `deposits[local][remote] => uint256` has stayed at base slot 2 in all 20 releases
(`src/universal/StandardBridge.sol:40`–`:54`). A pre-Bedrock USDT pair sample at block 17422409
resolved to `0x7b89e5...871d`, with cutoff value `0x9f8d718f0217`; a first post-Bedrock BAL pair
sample at 17423191 resolved to `0xcb7768...d936`, with cutoff value
`0x14059f25d2d23dc94c27`. These are the same current getter namespace, not stale layouts. The event
census counted 96776 legacy deposit, 20726 legacy withdrawal-finalized, 60130 bridge-initiated and
13992 bridge-finalized logs.

The log scan covers every block from 12600000 through 26433900 in 1,384 requests of at most 10,000
blocks. It matched 1,217,983 logs. There were no `WithdrawalProofDeleted`, portal blacklist, or ASR
blacklist events. This is complete coverage for the named addresses/topics, not a claim that every
possible mapping key can be enumerated without an event.

### Ink, Soneium and Unichain

Registry-pinned L1 genesis reads answer the sibling question directly:

| chain | registry L1 genesis | portal | `version()` at that block | implementation |
|---|---:|---|---|---|
| Ink | 21344310 | `0x5d66c1...d3e4f` | 3.10.0 | `0xe2f826...7832b` |
| Soneium | 21314185 | `0x88e529...fae92` | 3.10.0 | `0xe2f826...7832b` |
| Unichain | 21116363 | `0x0bd48f...6a7a2` | 3.10.0 | `0xe2f826...7832b` |

The source facts are in the registry files at `configs/mainnet/ink.toml:32`–`:36`, `:49`–`:52`,
the corresponding Soneium file `:32`–`:36`, `:49`–`:52`, and Unichain file `:32`–`:36`,
`:49`–`:52`. All three were born on fault-proof OptimismPortal2 with nested base slot 57; none had
an OP Mainnet-style legacy slot-52 proof era.

## Initializer archaeology

The `_initialized` byte is slot 0 offset 0 for every Initializable family except
L1CrossDomainMessenger, where legacy packing places it at slot 0 offset 20. The v9 deployment
assertion independently hard-codes that messenger offset (`scripts/deploy/ChainAssertions.sol:129`
–`:136`). ProtocolVersions correctly began at 3, not 1: its v1.1 initializer is
`reinitializer(Constants.INITIALIZER)` (`src/L1/ProtocolVersions.sol:54`–`:65`) and that tag defines
`INITIALIZER = 3` (`src/libraries/Constants.sol:49`).

The meaningful production version changes were:

- Portal, SystemConfig, L1CDM, L1StandardBridge and L1ERC721Bridge: 1 to 2 at block 22990599,
  then 2 to 3 at 23491328.
- SuperchainConfig: 1 to 2 at 22990599 and remains 2.
- ProtocolVersions: 3 from initial activation; factory, DGF, all ASRs, all DelayedWETH generations,
  ETHLockbox and retired L2OO remain 1.

Every block-final state with a live modern implementation is initialized. At U20/U21 the zeroing
exists only within the governance transaction: OPCM installs StorageSetter, masks precisely the
layout-derived byte, performs `upgradeAndCall`, checks that no OZ-v5 namespaced state appeared, and
restores the implementation (`OPContractsManagerUtils.sol:352`–`:386`). The U21 transaction
`0x024770...2a99` call trace and upgrade events show this sequence; the post-block bytes are the
versions above. The OZ-v5 initializer slot is zero for every proxy snapshot and all 102 observed
implementation/helper addresses.

Some proxies were staged with implementation zero before activation, and L1CDM had zero-target
windows 13596294–13596780 and 17422444–17423157. Those were unavailable proxies: fallback calls
had no delegate target, so there was no public initializer to seize. Once a real Initializable
implementation was installed, initialization was in the same transaction; no block boundary has
implementation != zero with a callable zero initializer byte. Early constructor/immutable bridge,
factory and ERC721 implementations do have zero in the byte later used by Initializable, but their
ABIs have constructors rather than initializers (for example v1.0 deployment artifacts
`L1StandardBridge.json:2`–`:14`, `OptimismMintableERC20Factory.json:2`–`:14`, and
`contracts/L1/L1ERC721Bridge.sol:15`–`:31`). Zero is therefore not itself evidence of an unlock.

Of 102 historical/current implementation/helper addresses, 64 have byte 255, 31 have another
non-zero value, and seven have zero; the latter are StorageSetter/helper or the constructor-only
contracts above. Only two implementation addresses hold ETH dust: an old constructor-only bridge
(0.00101 ETH) and locked Portal 5.2.0 (0.001 ETH). Current initializers also require ProxyAdmin or
its owner, resolving that authority from proxy-only storage
(`src/universal/ProxyAdminOwnedBase.sol:45`–`:76`, `:88`–`:105`). Initializing any older bare
implementation that still exposes a higher reinitializer would alter only that implementation's
isolated storage; no proxy authority or material balance was found. No implementation takeover
with programme impact was reproduced.

## Generation isolation and layout-reorder stress

The largest source-layout changes are AnchorStateRegistry and DelayedWETH around v4. They were not
applied as an unsafe in-place reinterpretation of the old proxy. Four live-game samples at block
26433900 prove generation pinning:

| game index / version | AnchorStateRegistry | DelayedWETH |
|---|---|---|
| 0 / 1.2.0 | gen0 `0x18dac7...5e443` | gen0 `0xe497b0...88d14` |
| 9759 / 1.4.1 | gen1 `0x1c68ec...04305b` | gen1 `0x323dfc...cbdf0` |
| 20000 / 2.4.2 | current `0x23b2c6...fd113` | current `0x1b6dbf...b3162` |
| 21388 / 0.8.0 | current `0x23b2c6...fd113` | current `0x1b6dbf...b3162` |

Old games therefore keep calling old-layout proxies through immutable generation references; the
current contracts use the new layout. V9 explicitly leaves the old SystemConfig position as a
spacer and puts ETHLockbox in the next position (`src/dispute/DelayedWETH.sol:42`–`:63`); ASR packs
the new ETHLockbox neighbour only after game type and retirement timestamp
(`src/dispute/AnchorStateRegistry.sol:47`–`:59`).

The PASS-A closure stress was extended to hashed entries that its direct-slot junk test did not
cover. Both named tests in `/home/user/u21-work/codex-CF4/h/test/CF4StorageArchaeology.t.sol` pass
with `forge test -j 1` on the pinned fork:

```text
[PASS] testLegacyPortalProofSlot52IsNonzeroButV9DeleteDoesNotReachIt()
[PASS] testLegacyMessengerNamespacesRemainDisjointUnderJunk()
2 passed; 0 failed
```

## Security conclusion

No P0 collision primitive and no reportable candidate survived falsification. Mainnet does retain
many historical words and mapping entries, but v9 either preserves their original namespace
(finalized withdrawals, successful/failed messages, deposits), reserves them as spacers, or moved
state to a disjoint mapping/new proxy. The strongest apparently dangerous case—the live legacy
slot-52 proof whose first word can decode as a non-zero address—cannot reach v9's `status()` call.

Three compositional primitives remain worth carrying forward:

1. `PRIM-CF4-01`: immutable legacy portal proof tombstones persist under base 52, disjoint from the
   active base-57 namespace.
2. `PRIM-CF4-02`: initializer reset is an atomic privileged critical section mediated by a public
   arbitrary StorageSetter implementation.
3. `PRIM-CF4-03`: old dispute games permanently pin distinct ASR/DelayedWETH generations, so future
   compatibility must be checked across the full live generation graph, not only current proxies.

Limits: event-derived mapping enumeration cannot prove absence of keys written without the named
events; runtime direct-slot writes wholly between two upgrade checkpoints are not visible in the
boundary history; token balances of every historical implementation were not enumerable without a
token universe. These limits do not affect the two tested namespace negatives or the initializer
block-boundary result.
