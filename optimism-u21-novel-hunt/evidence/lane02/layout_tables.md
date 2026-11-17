
### OptimismPortal2

| slot | off | bytes | v7.0.0 | v8.0.0 | v9.0.0 | changed | OP Mainnet raw field @N-1 | @N |
|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 1 | `_initialized` uint8 | `_initialized` uint8 | `_initialized` uint8 |  | `0x03` | `=` |
| 0 | 1 | 1 | `_initializing` bool | `_initializing` bool | `_initializing` bool |  | `0` | `=` |
| 1 | 0 | 32 | `params` struct ResourceMetering.ResourceParams | `params` struct ResourceMetering.ResourceParams | `params` struct ResourceMetering.ResourceParams |  | `0x0000000001934d6e000000000007e3760000000000000000000000003b9aca00` | `0x0000000001934d8b000000000007df760000000000000000000000003b9aca00` |
| 2 | 0 | 1536 | `__gap` uint256[48] | `__gap` uint256[48] | `__gap` uint256[48] |  | `(multi-slot)` | `(multi-slot)` |
| 50 | 0 | 20 | `l2Sender` address | `l2Sender` address | `l2Sender` address |  | `0x000000000000000000000000000000000000dead` | `=` |
| 51 | 0 | 32 | `finalizedWithdrawals` mapping(bytes32 => bool) | `finalizedWithdrawals` mapping(bytes32 => bool) | `finalizedWithdrawals` mapping(bytes32 => bool) |  | `0` | `=` |
| 52 | 0 | 32 | `spacer_52_0_32` bytes32 | `spacer_52_0_32` bytes32 | `spacer_52_0_32` bytes32 |  | `0` | `=` |
| 53 | 0 | 1 | `spacer_53_0_1` bool | `spacer_53_0_1` bool | `spacer_53_0_1` bool |  | `0` | `=` |
| 53 | 1 | 20 | `spacer_53_1_20` address | `spacer_53_1_20` address | `spacer_53_1_20` address |  | `0x95703e0982140d16f8eba6d158fccede42f04a4c` | `=` |
| 54 | 0 | 20 | `spacer_54_0_20` address | `spacer_54_0_20` address | `spacer_54_0_20` address |  | `0xdfe97868233d1aa22e815a266982f2cf17685a27` | `=` |
| 55 | 0 | 20 | `systemConfig` contract ISystemConfig | `systemConfig` contract ISystemConfig | `systemConfig` contract ISystemConfig |  | `0x229047fed2591dbec1ef1118d64f7af3db9eb290` | `=` |
| 56 | 0 | 20 | `spacer_56_0_20` address | `spacer_56_0_20` address | `spacer_56_0_20` address |  | `0xe5965ab5962edc7477c8520243a95517cd252fa9` | `=` |
| 57 | 0 | 32 | `provenWithdrawals` mapping(bytes32 => mapping(address => struct OptimismPortal2.ProvenWithdrawal)) | `provenWithdrawals` mapping(bytes32 => mapping(address => struct OptimismPortal2.ProvenWithdrawal)) | `provenWithdrawals` mapping(bytes32 => mapping(address => struct OptimismPortal2.ProvenWithdrawal)) |  | `0` | `=` |
| 58 | 0 | 32 | `spacer_58_0_32` bytes32 | `spacer_58_0_32` bytes32 | `spacer_58_0_32` bytes32 |  | `0` | `=` |
| 59 | 0 | 4 | `spacer_59_0_4` GameType | `spacer_59_0_4` GameType | `spacer_59_0_4` GameType |  | `0` | `=` |
| 59 | 4 | 8 | `spacer_59_4_8` uint64 | `spacer_59_4_8` uint64 | `spacer_59_4_8` uint64 |  | `0x0000000066e1c083` | `=` |
| 60 | 0 | 32 | `proofSubmitters` mapping(bytes32 => address[]) | `proofSubmitters` mapping(bytes32 => address[]) | `proofSubmitters` mapping(bytes32 => address[]) |  | `0` | `=` |
| 61 | 0 | 32 | `spacer_61_0_32` uint256 | `spacer_61_0_32` uint256 | `spacer_61_0_32` uint256 |  | `0` | `=` |
| 62 | 0 | 20 | `anchorStateRegistry` contract IAnchorStateRegistry | `anchorStateRegistry` contract IAnchorStateRegistry | `anchorStateRegistry` contract IAnchorStateRegistry |  | `0x23b2c62946350f4246f9f9d027e071f0264fd113` | `=` |
| 63 | 0 | 20 | `ethLockbox` contract IETHLockbox | `ethLockbox` contract IETHLockbox | `ethLockbox` contract IETHLockbox |  | `0x322b47ff1fa8d5611f761e3e275c45b71b294d43` | `=` |
| 63 | 20 | 1 | `spacer_63_20_1` bool | `spacer_63_20_1` bool | `spacer_63_20_1` bool |  | `0` | `=` |

### SystemConfig

| slot | off | bytes | v7.0.0 | v8.0.0 | v9.0.0 | changed | OP Mainnet raw field @N-1 | @N |
|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 1 | `_initialized` uint8 | `_initialized` uint8 | `_initialized` uint8 |  | `0x03` | `=` |
| 0 | 1 | 1 | `_initializing` bool | `_initializing` bool | `_initializing` bool |  | `0` | `=` |
| 1 | 0 | 1600 | `__gap` uint256[50] | `__gap` uint256[50] | `__gap` uint256[50] |  | `(multi-slot)` | `(multi-slot)` |
| 51 | 0 | 20 | `_owner` address | `_owner` address | `_owner` address |  | `0x847b5c174615b1b7fdf770882256e2d3e95b9d92` | `=` |
| 52 | 0 | 1568 | `__gap` uint256[49] | `__gap` uint256[49] | `__gap` uint256[49] |  | `(multi-slot)` | `(multi-slot)` |
| 101 | 0 | 32 | `overhead` uint256 | `overhead` uint256 | `overhead` uint256 |  | `0` | `=` |
| 102 | 0 | 32 | `scalar` uint256 | `scalar` uint256 | `scalar` uint256 |  | `0x010000000000000000000000000000000000000000000000000f79c50000146b` | `=` |
| 103 | 0 | 32 | `batcherHash` bytes32 | `batcherHash` bytes32 | `batcherHash` bytes32 |  | `0x0000000000000000000000006887246668a3b87f54deb3b94ba47a6f63f32985` | `=` |
| 104 | 0 | 8 | `gasLimit` uint64 | `gasLimit` uint64 | `gasLimit` uint64 |  | `0x0000000002625a00` | `=` |
| 104 | 8 | 4 | `basefeeScalar` uint32 | `basefeeScalar` uint32 | `basefeeScalar` uint32 |  | `0x0000146b` | `=` |
| 104 | 12 | 4 | `blobbasefeeScalar` uint32 | `blobbasefeeScalar` uint32 | `blobbasefeeScalar` uint32 |  | `0x000f79c5` | `=` |
| 105 | 0 | 32 | `_resourceConfig` struct IResourceMetering.ResourceConfig | `_resourceConfig` struct IResourceMetering.ResourceConfig | `_resourceConfig` struct IResourceMetering.ResourceConfig |  | `0x0000ffffffffffffffffffffffffffffffff000f42403b9aca00080a01312d00` | `=` |
| 106 | 0 | 4 | `eip1559Denominator` uint32 | `eip1559Denominator` uint32 | `eip1559Denominator` uint32 |  | `0x000000fa` | `=` |
| 106 | 4 | 4 | `eip1559Elasticity` uint32 | `eip1559Elasticity` uint32 | `eip1559Elasticity` uint32 |  | `0x00000002` | `=` |
| 106 | 8 | 4 | `operatorFeeScalar` uint32 | `operatorFeeScalar` uint32 | `operatorFeeScalar` uint32 |  | `0` | `=` |
| 106 | 12 | 8 | `operatorFeeConstant` uint64 | `operatorFeeConstant` uint64 | `operatorFeeConstant` uint64 |  | `0` | `=` |
| 106 | 20 | 2 | `daFootprintGasScalar` uint16 | `daFootprintGasScalar` uint16 | `daFootprintGasScalar` uint16 |  | `0` | `=` |
| 107 | 0 | 32 | `l2ChainId` uint256 | `l2ChainId` uint256 | `l2ChainId` uint256 |  | `0x000000000000000000000000000000000000000000000000000000000000000a` | `=` |
| 108 | 0 | 20 | `superchainConfig` contract ISuperchainConfig | `superchainConfig` contract ISuperchainConfig | `superchainConfig` contract ISuperchainConfig |  | `0x95703e0982140d16f8eba6d158fccede42f04a4c` | `=` |
| 108 | 20 | 8 | `minBaseFee` uint64 | `minBaseFee` uint64 | `minBaseFee` uint64 |  | `0` | `=` |
| 109 | 0 | 32 | `isFeatureEnabled` mapping(bytes32 => bool) | `isFeatureEnabled` mapping(bytes32 => bool) | `isFeatureEnabled` mapping(bytes32 => bool) |  | `0` | `=` |

### ETHLockbox

| slot | off | bytes | v7.0.0 | v8.0.0 | v9.0.0 | changed | OP Mainnet raw field @N-1 | @N |
|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 1 | `_initialized` uint8 | `_initialized` uint8 | `_initialized` uint8 |  | `0x01` | `=` |
| 0 | 1 | 1 | `_initializing` bool | `_initializing` bool | `_initializing` bool |  | `0` | `=` |
| 0 | 2 | 20 | `systemConfig` contract ISystemConfig | `systemConfig` contract ISystemConfig | `spacer_0_2_20` address | **YES** | `0x229047fed2591dbec1ef1118d64f7af3db9eb290` | `=` |
| 1 | 0 | 32 | `authorizedPortals` mapping(contract IOptimismPortal2 => bool) | `authorizedPortals` mapping(contract IOptimismPortal2 => bool) | `authorizedPortals` mapping(contract IOptimismPortal2 => bool) |  | `0` | `=` |
| 2 | 0 | 32 | `authorizedLockboxes` mapping(contract IETHLockbox => bool) | `authorizedLockboxes` mapping(contract IETHLockbox => bool) | `authorizedLockboxes` mapping(contract IETHLockbox => bool) |  | `0` | `=` |
| 3 | 0 | 20 | — | — | `superchainConfig` contract ISuperchainConfig | **YES** | `0` | `0x95703e0982140d16f8eba6d158fccede42f04a4c` |

### AnchorStateRegistry

| slot | off | bytes | v7.0.0 | v8.0.0 | v9.0.0 | changed | OP Mainnet raw field @N-1 | @N |
|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 1 | `_initialized` uint8 | `_initialized` uint8 | `_initialized` uint8 |  | `0x01` | `=` |
| 0 | 1 | 1 | `_initializing` bool | `_initializing` bool | `_initializing` bool |  | `0` | `=` |
| 0 | 2 | 20 | `systemConfig` contract ISystemConfig | `systemConfig` contract ISystemConfig | `spacer_0_2_20` address | **YES** | `0x229047fed2591dbec1ef1118d64f7af3db9eb290` | `=` |
| 1 | 0 | 20 | `disputeGameFactory` contract IDisputeGameFactory | `disputeGameFactory` contract IDisputeGameFactory | `disputeGameFactory` contract IDisputeGameFactory |  | `0xe5965ab5962edc7477c8520243a95517cd252fa9` | `=` |
| 2 | 0 | 20 | `anchorGame` contract IDisputeGame | `anchorGame` contract IDisputeGame | `anchorGame` contract IDisputeGame |  | `0x51024a83c2f94c8e70014a732d3e2559cdceeb1d` | `=` |
| 3 | 0 | 64 | `startingAnchorRoot` struct Proposal | `startingAnchorRoot` struct Proposal | `startingAnchorRoot` struct Proposal |  | `(multi-slot)` | `(multi-slot)` |
| 5 | 0 | 32 | `disputeGameBlacklist` mapping(contract IDisputeGame => bool) | `disputeGameBlacklist` mapping(contract IDisputeGame => bool) | `disputeGameBlacklist` mapping(contract IDisputeGame => bool) |  | `0` | `=` |
| 6 | 0 | 4 | `respectedGameType` GameType | `respectedGameType` GameType | `respectedGameType` GameType |  | `0x00000009` | `=` |
| 6 | 4 | 8 | `retirementTimestamp` uint64 | `retirementTimestamp` uint64 | `retirementTimestamp` uint64 |  | `0x00000000688271ab` | `=` |
| 6 | 12 | 20 | — | — | `ethLockbox` contract IETHLockbox | **YES** | `0` | `0x322b47ff1fa8d5611f761e3e275c45b71b294d43` |

### DelayedWETH

| slot | off | bytes | v7.0.0 | v8.0.0 | v9.0.0 | changed | OP Mainnet raw field @N-1 | @N |
|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 1 | `_initialized` uint8 | `_initialized` uint8 | `_initialized` uint8 |  | `0x01` | `=` |
| 0 | 1 | 1 | `_initializing` bool | `_initializing` bool | `_initializing` bool |  | `0` | `=` |
| 1 | 0 | 32 | `_balanceOf` mapping(address => uint256) | `_balanceOf` mapping(address => uint256) | `_balanceOf` mapping(address => uint256) |  | `0` | `=` |
| 2 | 0 | 32 | `_allowance` mapping(address => mapping(address => uint256)) | `_allowance` mapping(address => mapping(address => uint256)) | `_allowance` mapping(address => mapping(address => uint256)) |  | `0` | `=` |
| 3 | 0 | 32 | `withdrawals` mapping(address => mapping(address => struct DelayedWETH.WithdrawalRequest)) | `withdrawals` mapping(address => mapping(address => struct DelayedWETH.WithdrawalRequest)) | `withdrawals` mapping(address => mapping(address => struct DelayedWETH.WithdrawalRequest)) |  | `0` | `=` |
| 4 | 0 | 20 | `systemConfig` contract ISystemConfig | `systemConfig` contract ISystemConfig | `spacer_4_0_20` address | **YES** | `0x229047fed2591dbec1ef1118d64f7af3db9eb290` | `=` |
| 5 | 0 | 20 | — | — | `ethLockbox` contract IETHLockbox | **YES** | `0` | `0x322b47ff1fa8d5611f761e3e275c45b71b294d43` |

### DisputeGameFactory

| slot | off | bytes | v7.0.0 | v8.0.0 | v9.0.0 | changed | OP Mainnet raw field @N-1 | @N |
|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 1 | `_initialized` uint8 | `_initialized` uint8 | `_initialized` uint8 |  | `0x01` | `=` |
| 0 | 1 | 1 | `_initializing` bool | `_initializing` bool | `_initializing` bool |  | `0` | `=` |
| 1 | 0 | 1600 | `__gap` uint256[50] | `__gap` uint256[50] | `__gap` uint256[50] |  | `(multi-slot)` | `(multi-slot)` |
| 51 | 0 | 20 | `_owner` address | `_owner` address | `_owner` address |  | `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a` | `=` |
| 52 | 0 | 1568 | `__gap` uint256[49] | `__gap` uint256[49] | `__gap` uint256[49] |  | `(multi-slot)` | `(multi-slot)` |
| 101 | 0 | 32 | `gameImpls` mapping(GameType => contract IDisputeGame) | `gameImpls` mapping(GameType => contract IDisputeGame) | `gameImpls` mapping(GameType => contract IDisputeGame) |  | `0` | `=` |
| 102 | 0 | 32 | `initBonds` mapping(GameType => uint256) | `initBonds` mapping(GameType => uint256) | `initBonds` mapping(GameType => uint256) |  | `0` | `=` |
| 103 | 0 | 32 | `_disputeGames` mapping(Hash => GameId) | `_disputeGames` mapping(Hash => GameId) | `_disputeGames` mapping(Hash => GameId) |  | `0` | `=` |
| 104 | 0 | 32 | `_disputeGameList` GameId[] | `_disputeGameList` GameId[] | `_disputeGameList` GameId[] |  | `0x0000000000000000000000000000000000000000000000000000000000005382` | `=` |
| 105 | 0 | 32 | `gameArgs` mapping(GameType => bytes) | `gameArgs` mapping(GameType => bytes) | `gameArgs` mapping(GameType => bytes) |  | `0` | `=` |

### SuperchainConfig

| slot | off | bytes | v7.0.0 | v8.0.0 | v9.0.0 | changed | OP Mainnet raw field @N-1 | @N |
|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 1 | `_initialized` uint8 | `_initialized` uint8 | `_initialized` uint8 |  | `0x02` | `=` |
| 0 | 1 | 1 | `_initializing` bool | `_initializing` bool | `_initializing` bool |  | `0` | `=` |
| 0 | 2 | 20 | `guardian` address | `guardian` address | `guardian` address |  | `0x09f7150d8c019bef34450d6920f6b3608cefdaf2` | `=` |
| 1 | 0 | 32 | `pauseTimestamps` mapping(address => uint256) | `pauseTimestamps` mapping(address => uint256) | `pauseTimestamps` mapping(address => uint256) |  | `0` | `=` |

### L1CrossDomainMessenger

| slot | off | bytes | v7.0.0 | v8.0.0 | v9.0.0 | changed | OP Mainnet raw field @N-1 | @N |
|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 20 | `spacer_0_0_20` address | `spacer_0_0_20` address | `spacer_0_0_20` address |  | `0` | `=` |
| 0 | 20 | 1 | `_initialized` uint8 | `_initialized` uint8 | `_initialized` uint8 |  | `0x03` | `=` |
| 0 | 21 | 1 | `_initializing` bool | `_initializing` bool | `_initializing` bool |  | `0` | `=` |
| 1 | 0 | 1600 | `spacer_1_0_1600` uint256[50] | `spacer_1_0_1600` uint256[50] | `spacer_1_0_1600` uint256[50] |  | `(multi-slot)` | `(multi-slot)` |
| 51 | 0 | 20 | `spacer_51_0_20` address | `spacer_51_0_20` address | `spacer_51_0_20` address |  | `0x9ba6e03d8b90de867373db8cf1a58d2f7f006b3a` | `=` |
| 52 | 0 | 1568 | `spacer_52_0_1568` uint256[49] | `spacer_52_0_1568` uint256[49] | `spacer_52_0_1568` uint256[49] |  | `(multi-slot)` | `(multi-slot)` |
| 101 | 0 | 1 | `spacer_101_0_1` bool | `spacer_101_0_1` bool | `spacer_101_0_1` bool |  | `0` | `=` |
| 102 | 0 | 1568 | `spacer_102_0_1568` uint256[49] | `spacer_102_0_1568` uint256[49] | `spacer_102_0_1568` uint256[49] |  | `(multi-slot)` | `(multi-slot)` |
| 151 | 0 | 32 | `spacer_151_0_32` uint256 | `spacer_151_0_32` uint256 | `spacer_151_0_32` uint256 |  | `0x0000000000000000000000000000000000000000000000000000000000000001` | `=` |
| 152 | 0 | 1568 | `spacer_152_0_1568` uint256[49] | `spacer_152_0_1568` uint256[49] | `spacer_152_0_1568` uint256[49] |  | `(multi-slot)` | `(multi-slot)` |
| 201 | 0 | 32 | `spacer_201_0_32` mapping(bytes32 => bool) | `spacer_201_0_32` mapping(bytes32 => bool) | `spacer_201_0_32` mapping(bytes32 => bool) |  | `0` | `=` |
| 202 | 0 | 32 | `spacer_202_0_32` mapping(bytes32 => bool) | `spacer_202_0_32` mapping(bytes32 => bool) | `spacer_202_0_32` mapping(bytes32 => bool) |  | `0` | `=` |
| 203 | 0 | 32 | `successfulMessages` mapping(bytes32 => bool) | `successfulMessages` mapping(bytes32 => bool) | `successfulMessages` mapping(bytes32 => bool) |  | `0` | `=` |
| 204 | 0 | 20 | `xDomainMsgSender` address | `xDomainMsgSender` address | `xDomainMsgSender` address |  | `0x000000000000000000000000000000000000dead` | `=` |
| 205 | 0 | 30 | `msgNonce` uint240 | `msgNonce` uint240 | `msgNonce` uint240 |  | `0x000000000000000000000000000000000000000000000000000000042a0e` | `0x000000000000000000000000000000000000000000000000000000042a0f` |
| 206 | 0 | 32 | `failedMessages` mapping(bytes32 => bool) | `failedMessages` mapping(bytes32 => bool) | `failedMessages` mapping(bytes32 => bool) |  | `0` | `=` |
| 207 | 0 | 20 | `otherMessenger` contract CrossDomainMessenger | `otherMessenger` contract CrossDomainMessenger | `otherMessenger` contract CrossDomainMessenger |  | `0x4200000000000000000000000000000000000007` | `=` |
| 208 | 0 | 1376 | `__gap` uint256[43] | `__gap` uint256[43] | `__gap` uint256[43] |  | `(multi-slot)` | `(multi-slot)` |
| 251 | 0 | 20 | `spacer_251_0_20` address | `spacer_251_0_20` address | `spacer_251_0_20` address |  | `0x95703e0982140d16f8eba6d158fccede42f04a4c` | `=` |
| 252 | 0 | 20 | `portal` contract IOptimismPortal2 | `portal` contract IOptimismPortal2 | `portal` contract IOptimismPortal2 |  | `0xbeb5fc579115071764c7423a4f12edde41f106ed` | `=` |
| 253 | 0 | 20 | `spacer_253_0_20` address | `spacer_253_0_20` address | `spacer_253_0_20` address |  | `0` | `=` |
| 254 | 0 | 20 | `systemConfig` contract ISystemConfig | `systemConfig` contract ISystemConfig | `systemConfig` contract ISystemConfig |  | `0x229047fed2591dbec1ef1118d64f7af3db9eb290` | `=` |

### L1StandardBridge

| slot | off | bytes | v7.0.0 | v8.0.0 | v9.0.0 | changed | OP Mainnet raw field @N-1 | @N |
|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 1 | `_initialized` uint8 | `_initialized` uint8 | `_initialized` uint8 |  | `0x03` | `=` |
| 0 | 1 | 1 | `_initializing` bool | `_initializing` bool | `_initializing` bool |  | `0` | `=` |
| 0 | 2 | 30 | `spacer_0_2_30` bytes30 | `spacer_0_2_30` bytes30 | `spacer_0_2_30` bytes30 |  | `0` | `=` |
| 1 | 0 | 20 | `spacer_1_0_20` address | `spacer_1_0_20` address | `spacer_1_0_20` address |  | `0x4200000000000000000000000000000000000010` | `=` |
| 2 | 0 | 32 | `deposits` mapping(address => mapping(address => uint256)) | `deposits` mapping(address => mapping(address => uint256)) | `deposits` mapping(address => mapping(address => uint256)) |  | `0` | `=` |
| 3 | 0 | 20 | `messenger` contract ICrossDomainMessenger | `messenger` contract ICrossDomainMessenger | `messenger` contract ICrossDomainMessenger |  | `0x25ace71c97b33cc4729cf772ae268934f7ab5fa1` | `=` |
| 4 | 0 | 20 | `otherBridge` contract StandardBridge | `otherBridge` contract StandardBridge | `otherBridge` contract StandardBridge |  | `0x4200000000000000000000000000000000000010` | `=` |
| 5 | 0 | 1440 | `__gap` uint256[45] | `__gap` uint256[45] | `__gap` uint256[45] |  | `(multi-slot)` | `(multi-slot)` |
| 50 | 0 | 20 | `spacer_50_0_20` address | `spacer_50_0_20` address | `spacer_50_0_20` address |  | `0x95703e0982140d16f8eba6d158fccede42f04a4c` | `=` |
| 51 | 0 | 20 | `spacer_51_0_20` address | `spacer_51_0_20` address | `spacer_51_0_20` address |  | `0` | `=` |
| 52 | 0 | 20 | `systemConfig` contract ISystemConfig | `systemConfig` contract ISystemConfig | `systemConfig` contract ISystemConfig |  | `0x229047fed2591dbec1ef1118d64f7af3db9eb290` | `=` |

### L1ERC721Bridge

| slot | off | bytes | v7.0.0 | v8.0.0 | v9.0.0 | changed | OP Mainnet raw field @N-1 | @N |
|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 1 | `_initialized` uint8 | `_initialized` uint8 | `_initialized` uint8 |  | `0x03` | `=` |
| 0 | 1 | 1 | `_initializing` bool | `_initializing` bool | `_initializing` bool |  | `0` | `=` |
| 0 | 2 | 30 | `spacer_0_2_30` bytes30 | `spacer_0_2_30` bytes30 | `spacer_0_2_30` bytes30 |  | `0` | `=` |
| 1 | 0 | 20 | `messenger` contract ICrossDomainMessenger | `messenger` contract ICrossDomainMessenger | `messenger` contract ICrossDomainMessenger |  | `0x25ace71c97b33cc4729cf772ae268934f7ab5fa1` | `=` |
| 2 | 0 | 20 | `otherBridge` contract ERC721Bridge | `otherBridge` contract ERC721Bridge | `otherBridge` contract ERC721Bridge |  | `0x4200000000000000000000000000000000000014` | `=` |
| 3 | 0 | 1472 | `__gap` uint256[46] | `__gap` uint256[46] | `__gap` uint256[46] |  | `(multi-slot)` | `(multi-slot)` |
| 49 | 0 | 32 | `deposits` mapping(address => mapping(address => mapping(uint256 => bool))) | `deposits` mapping(address => mapping(address => mapping(uint256 => bool))) | `deposits` mapping(address => mapping(address => mapping(uint256 => bool))) |  | `0` | `=` |
| 50 | 0 | 20 | `spacer_50_0_20` address | `spacer_50_0_20` address | `spacer_50_0_20` address |  | `0x95703e0982140d16f8eba6d158fccede42f04a4c` | `=` |
| 51 | 0 | 20 | `systemConfig` contract ISystemConfig | `systemConfig` contract ISystemConfig | `systemConfig` contract ISystemConfig |  | `0x229047fed2591dbec1ef1118d64f7af3db9eb290` | `=` |

### OptimismMintableERC20Factory

| slot | off | bytes | v7.0.0 | v8.0.0 | v9.0.0 | changed | OP Mainnet raw field @N-1 | @N |
|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 1 | `_initialized` uint8 | `_initialized` uint8 | `_initialized` uint8 |  | `0x01` | `=` |
| 0 | 1 | 1 | `_initializing` bool | `_initializing` bool | `_initializing` bool |  | `0` | `=` |
| 0 | 2 | 30 | `spacer_0_2_30` bytes30 | `spacer_0_2_30` bytes30 | `spacer_0_2_30` bytes30 |  | `0` | `=` |
| 1 | 0 | 20 | `bridge` address | `bridge` address | `bridge` address |  | `0x99c9fc46f92e8a1c0dec1b1747d010903e884be1` | `=` |
| 2 | 0 | 32 | `deployments` mapping(address => address) | `deployments` mapping(address => address) | `deployments` mapping(address => address) |  | `0` | `=` |
| 3 | 0 | 1536 | `__gap` uint256[48] | `__gap` uint256[48] | `__gap` uint256[48] |  | `(multi-slot)` | `(multi-slot)` |

### ProxyAdmin

| slot | off | bytes | v7.0.0 | v8.0.0 | v9.0.0 | changed | OP Mainnet raw field @N-1 | @N |
|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 20 | `_owner` address | `_owner` address | `_owner` address |  | `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a` | `=` |
| 1 | 0 | 32 | `proxyType` mapping(address => enum ProxyAdmin.ProxyType) | `proxyType` mapping(address => enum ProxyAdmin.ProxyType) | `proxyType` mapping(address => enum ProxyAdmin.ProxyType) |  | `0` | `=` |
| 2 | 0 | 32 | `implementationName` mapping(address => string) | `implementationName` mapping(address => string) | `implementationName` mapping(address => string) |  | `0` | `=` |
| 3 | 0 | 20 | `addressManager` contract IAddressManager | `addressManager` contract IAddressManager | `addressManager` contract IAddressManager |  | `0xde1fcfb0851916ca5101820a69b13a4e276bd81f` | `=` |
| 3 | 20 | 1 | `upgrading` bool | `upgrading` bool | `upgrading` bool |  | `0` | `=` |
