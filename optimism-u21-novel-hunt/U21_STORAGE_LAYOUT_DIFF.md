# U21 storage-layout and re-initialisation diff (LANE 02)

Scope: every upgradeable L1 proxy touched by the U21 transaction
`0x024770b5fba87683ee1466562eefb1bcb408c29c764e24abd07c7d4050a82a99` (block N = 26430859, tx index 358)
on OP Mainnet (10), Ink (57073), Soneium (1868) and Unichain (130).

Two baselines are used together:

* (a) source `op-contracts/v7.0.0 -> v8.0.0 -> v9.0.0` (snapshots **and** the inheritance chains read by hand), and
* (b) real mainnet storage at N-1 = 26430858 (`l1pre`, :8546) vs N = 26430859 (:8547), plus N -> 26433900 (`l1`, :8545).

Raw material (all reproducible, read-only):

| File | Content |
|---|---|
| `PRE_UPGRADE_STATE.json` | block 26430858, v8 labels. 4 chains x 12 contracts: proxy, implementation (+ impl slot 0, code hash), version, `_initialized`, slots 0..N (70-258 per contract), hashed/named slots, ~230 getters per chain, ETH balance |
| `POST_UPGRADE_STATE.json` | same schema, block 26430859, v9 labels |
| `POST_UPGRADE_STATE_26433900.json` | same schema, block 26433900 |
| `evidence/lane02/u21-tx-prestate-diff.json` | `debug_traceTransaction` `prestateTracer{diffMode:true}` of the upgrade tx = exact net storage delta of the tx |
| `evidence/lane02/u21-tx-calltrace.json`, `u21-tx-calltrace-summary.txt` | `callTracer` of the upgrade tx (every `upgrade` / `setBytes32` / `initialize` / `setImplementation`) |
| `evidence/lane02/delta_N-1_to_N.txt`, `delta_N_to_26433900.txt` | slot/getter deltas computed from the dumps |
| `evidence/lane02/bytecode_check.txt` | deployed implementation bytecode vs local v9 `forge-artifacts` (immutables masked) |
| `evidence/lane02/withdrawal_mapping_check.json` | 21 real proven/finalized withdrawal entries read at N-1 / N / 26433900 |
| `evidence/lane02/dump_state.py` etc. | the scripts |
| `test/poc/lane02/*.t.sol` | 7 fork tests against the real bytecode (all pass, `evidence/lane02/forge_test_output.txt`) |

## 0. Result in one paragraph

On all four chains U21 is, storage-wise, a **pointer-only upgrade**. The upgrade tx changed exactly **47 storage slots**
(net): 33 EIP-1967 implementation slots... (see §3 for the exact list), 4 `OPCM_SLOT`s, 4 AddressManager entries, and
**12 new v9 pointers** (`ETHLockbox.superchainConfig`, `AnchorStateRegistry.ethLockbox`, `DelayedWETH.ethLockbox`, x4 chains),
plus 5 DisputeGameFactory `gameArgs` words (new prestate for type 9 on OP/Ink/Unichain; new SUPER_PERMISSIONED proposer on
OP Mainnet only) and the Safe nonce. No ETH moved, no feature flag changed, no `_initialized` byte changed (net), no legacy
slot was cleared, no mapping was touched. Every value that v9 reads is either unchanged-in-place with unchanged type, or was
zero before and is written by the v9 initializer. **No slot holding a pre-upgrade value is read by v9 under a different
meaning** (source review + differential fork test `test_legacySpacerSlotsAreDeadStorage`). No candidate vulnerability.

## 1. Source-level layout diff v7 -> v8 -> v9

`snapshots/storageLayout/*.json` differ between tags only for:

| Contract | v7 -> v8 | v8 -> v9 |
|---|---|---|
| AnchorStateRegistry | identical | slot 0 off 2 `systemConfig` (ISystemConfig) -> `spacer_0_2_20` (address, private); **new** slot 6 off 12 `ethLockbox` (IETHLockbox, 20 bytes) |
| DelayedWETH | identical | slot 4 `systemConfig` -> `spacer_4_0_20`; **new** slot 5 `ethLockbox` |
| ETHLockbox | identical | slot 0 off 2 `systemConfig` -> `spacer_0_2_20`; **new** slot 3 `superchainConfig` (ISuperchainConfig) |
| OptimismPortal2, SystemConfig, SuperchainConfig, DisputeGameFactory, L1CrossDomainMessenger, L1StandardBridge, L1ERC721Bridge, OptimismMintableERC20Factory, ProxyAdmin, Proxy, L1ChugSplashProxy, ResolvedDelegateProxy, AddressManager, StorageSetter | identical | identical |

(`OPContractsManagerStandardValidator` and `SuperPermissionedDisputeGame` snapshots changed v7 -> v8 only; neither is a proxy.)

Hand check of the inheritance chains at v9 (file:line at `ba6fcadb`), to make sure the snapshot tool is not hiding a
re-ordering:

* `OptimismPortal2 is Initializable, ResourceMetering, ReinitializableBase, ProxyAdminOwnedBase, ISemver`
  (src/L1/OptimismPortal2.sol:38). `Initializable` = slot 0 bytes 0-1; `ResourceMetering` = `params` slot 1 + `__gap[48]`
  slots 2-49 (src/L1/ResourceMetering.sol:59-62); `ReinitializableBase` has only an immutable
  (src/universal/ReinitializableBase.sol:11); `ProxyAdminOwnedBase` has no state. Own variables start at slot 50
  (`l2Sender`, :59) and run to slot 63 (`ethLockbox` :128 + `spacer_63_20_1` :132). Base list and order are byte-identical
  in v7 and v8.
* `SystemConfig is ProxyAdminOwnedBase, OwnableUpgradeable, ReinitializableBase, ISemver` (src/L1/SystemConfig.sol:24):
  OZ-upgradeable v4 = slot 0, `__gap[50]` 1-50, `_owner` 51, `__gap[49]` 52-100, own state 101-109. Plus ten hashed
  slots (`UNSAFE_BLOCK_SIGNER_SLOT` ... `START_BLOCK_SLOT`, :70-99). v7 -> v8 removed the *getter* and writer for
  `BATCH_INBOX_SLOT` (kept as `LEGACY_BATCH_INBOX_SLOT`, zeroed in `initialize` :242) and `setGasConfig`; layout unchanged.
* `ETHLockbox is ProxyAdminOwnedBase, Initializable, ReinitializableBase, ISemver` (src/L1/ETHLockbox.sol:23): the 20-byte
  spacer packs into slot 0 at offset 2 behind `_initialized/_initializing`, mappings at 1 and 2, new address at 3.
* `AnchorStateRegistry is ProxyAdminOwnedBase, Initializable, ReinitializableBase, ISemver`
  (src/dispute/AnchorStateRegistry.sol:25): slot 6 is now exactly full: `GameType`(4) + `uint64`(8) + `address`(20) = 32 bytes.
* `DelayedWETH is Initializable, ProxyAdminOwnedBase, ReinitializableBase, WETH98, ISemver` (src/dispute/DelayedWETH.sol:25):
  `_balanceOf` 1, `_allowance` 2 (src/universal/WETH98.sol:30-31), `withdrawals` 3, spacer 4, `ethLockbox` 5.
* `DisputeGameFactory is ProxyAdminOwnedBase, ReinitializableBase, OwnableUpgradeable, ISemver`: OZ 0-100, own 101-105.
* `SuperchainConfig is ProxyAdminOwnedBase, Initializable, ReinitializableBase, ISemver`: `guardian` packs in slot 0 off 2,
  `pauseTimestamps` slot 1.
* `L1CrossDomainMessenger`: `CrossDomainMessengerLegacySpacer0` (slot 0 bytes 0-19), `Initializable` (slot 0 **bytes 20-21**),
  `CrossDomainMessengerLegacySpacer1` (1-202), `CrossDomainMessenger` state 203-207 + `__gap[43]`, then 251-254. The v8 -> v9
  diff of `CrossDomainMessenger.sol`/`L1CrossDomainMessenger.sol` only touches constants and `pure`/`view` functions.

Initializer versions (`ReinitializableBase(N)` constructor argument) are **identical in v7, v8 and v9**:
Portal 3, SystemConfig 3, L1CDM 3, L1StandardBridge 3, L1ERC721Bridge 3, SuperchainConfig 2, ETHLockbox 1, ASR 1,
DelayedWETH 1, DGF 1; `OptimismMintableERC20Factory` uses plain `initializer` (=1). So U21 could not re-run any initializer
through the normal `reinitializer(initVersion())` path; it relies entirely on OPCM zeroing the `_initialized` byte through
the `StorageSetter` implementation (OPContractsManagerUtils.sol:352-386) and re-running `initialize` in the same call.

Per-field tables (all three tags, with the OP Mainnet raw field value at N-1 and N; `=` means unchanged):

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

## 2. Every changed / renamed / retyped / deleted field: what the slot holds on mainnet and how v9 reads it

| Contract.slot | v8 meaning | v9 meaning | Value now (all four chains, block N and 26433900) | How v9 code interprets it |
|---|---|---|---|---|
| ETHLockbox 0[2:22] | `systemConfig` (read by `paused()`, `superchainConfig()`) | `spacer_0_2_20` (private) | still the chain's SystemConfig: OP `0x229047fe..`, Ink `0x62c0a111..`, Soneium `0x7a8ed66b..`, Unichain `0xc407398d..` | never read. Only side effect: it shares slot 0 with `_initialized`; OPCM's reset mask (`~(0xff << 8*offset)`) preserves it (trace: `setBytes32(0, 0x..229047fe..0000)`) |
| ETHLockbox 3 | (unused, 0) | `superchainConfig` | `0x95703e0982140D16f8ebA6d158FccEde42f04a4C` | `paused()` = `superchainConfig.isLocalOrGlobalPaused(address(this))` (ETHLockbox.sol:112-114); `guardian()`; `_authorizePortal` equality check (:227-228) |
| ASR 0[2:22] | `systemConfig` (read by `paused()`, `superchainConfig()`, `_assertOnlyGuardian`) | `spacer_0_2_20` | still the chain's SystemConfig | never read |
| ASR 6[12:32] | (unused, 0) | `ethLockbox` | OP `0x322b47Ff..`, Ink `0xbd4AbB32..`, Soneium `0x67B4de6F..`, Unichain `0x08bA0023..` (== `portal.ethLockbox()` on each chain) | pause / guardian / superchainConfig resolver (AnchorStateRegistry.sol:136-144, 375-379) |
| ASR 6[0:12] | `respectedGameType`, `retirementTimestamp` | same | OP/Ink `9`, `1753379243`; Soneium `5`, `1753380095`; Unichain `9`, `1753380731` | unchanged; `initialize` re-wrote `respectedGameType` with the value read from the proxy before the upgrade (OPContractsManagerV2.sol:663-671), `retirementTimestamp` untouched because non-zero (:130-132) |
| DelayedWETH 4 | `systemConfig` (read by `config()`, `withdraw`) | `spacer_4_0_20` | still the chain's SystemConfig | never read |
| DelayedWETH 5 | (unused, 0) | `ethLockbox` | the chain's lockbox | `withdraw` pause check (DelayedWETH.sol:102), `config()` (:74-76) |
| SystemConfig `OPCM_SLOT` | lastUsedOPCM = `0x1951828C..` (8.0.1) | same meaning | `0x2d91e6F2..` (9.0.3) | `isPermittedUpgradeSequence` / `isPermittedMigrateSequence` |
| DGF `gameArgs[9]` word 0 | absolutePrestate | same | `0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9` (OP, Ink, Unichain; Soneium has no type 9) | CWIA arg of every *new* type-9 clone; games created before N keep `0x031ac6f1..` in their own bytecode |
| DGF `gameArgs[5]` (OP only) | ASR ++ proposer `0x473300df..` | same | ASR ++ proposer `0xc27BA3e0fc01567a5E57ae0c391aa98cecba5be0` (EOA, nonce 11, 5.1 ETH at 26433900) | who may create SUPER_PERMISSIONED games on OP Mainnet (type 5 is not the respected type there) |

Removed external getters (ABI-level deletions, same storage): `ETHLockbox.systemConfig()`, `AnchorStateRegistry.systemConfig()`,
`DelayedWETH.systemConfig()` now revert (`delta_N-1_to_N.txt`). No contract in `src/` at v8 or v9 calls any of them
(`grep '\.systemConfig()'` only hits OPCM/validator and the new `ETHLockbox._authorizePortal`, which calls
`portal.systemConfig()`); the deployed game implementations (unchanged by U21) only call
`getAnchorRoot/respectedGameType/paused/isGameFinalized/setAnchorState/isGameProper` on the ASR and
`deposit/unlock/withdraw` on DelayedWETH.

Semantics that changed **without** a layout change:

| Function | v8 | v9 | Effect on the four chains |
|---|---|---|---|
| `OptimismPortal2.paused()/superchainConfig()/guardian()` | via `systemConfig` | via `ethLockbox` (OptimismPortal2.sol:306-330) | same answers (lockbox was already the identifier; same SuperchainConfig) |
| `SystemConfig.paused()` | `superchainConfig.paused(0) \|\| paused(feature ? lockbox : portal)` | `portal.ethLockbox().paused()` (SystemConfig.sol:574-576) | same answers; reverts if a portal has no lockbox (none of the four) |
| `SystemConfig.setFeature` | ETH_LOCKBOX could be disabled if portal had no lockbox | ETH_LOCKBOX and INTEROP can never be disabled (:543-561) | `test_featureFlagsAreOneWay` |
| `OptimismPortal2._assertValidLockboxState` | flag XOR lockbox mismatch | flag **and** lockbox required (:839-843) | satisfied on all four |
| `OptimismPortal2.migrateLiquidity` | interop only | lockbox required, CGT rejected (:502-513) | not called by U21 (portal balances were 0) |
| `ETHLockbox._authorizePortal` | `_portal.superchainConfig() == superchainConfig()` | `ISystemConfig(_portal.systemConfig()).superchainConfig() == superchainConfig` (:227-228) | re-run in `initialize`, same mapping value (`true`) |

## 3. Real slot-by-slot delta N-1 -> N

### 3.1 Net storage delta of the upgrade transaction (exhaustive: 47 slots, prestate diff)

Balance/nonce only: sender EOA `0xe10a25d4..` (nonce 45 -> 46, gas) and the block builder `0x39634336..`. No contract
balance changed in the tx. No code was created or destroyed.
| chain | contract (proxy) | slot | value @N-1 | value @N | cause |
|---|---|---|---|---|---|
| shared | ProxyAdminOwner Safe `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a` | 5 | `0x0000000000000000000000000000000000000000000000000000000000000030` | `0x0000000000000000000000000000000000000000000000000000000000000031` | Safe nonce 48 -> 49 (the `execTransaction`). |
| op-mainnet-10 | AddressManager `0xde1fcfb0851916ca5101820a69b13a4e276bd81f` | 0x51521693..c9385e | `0x00000000000000000000000059d497530b00062f40950ba8eab88868bf7f86f0` | `0x0000000000000000000000007d4ec7fb1a1b9e6d61c04d5e21e3d68cff639448` | `addresses[keccak('OVM_L1CrossDomainMessenger')]`: L1CDM implementation 2.11.1 -> 2.13.0 (ResolvedDelegateProxy path of `ProxyAdmin.upgrade`, src/universal/ProxyAdmin.sol:159-161). |
| op-mainnet-10 | AnchorStateRegistry `0x23b2c62946350f4246f9f9d027e071f0264fd113` | 6 | `0x000000000000000000000000000000000000000000000000688271ab00000009` | `0x322b47ff1fa8d5611f761e3e275c45b71b294d4300000000688271ab00000009` | NEW v9 field `ethLockbox` packed into slot 6 bytes 12..31 (zero before). `AnchorStateRegistry.initialize` (src/dispute/AnchorStateRegistry.sol:107). Low 12 bytes (`respectedGameType`, `retirementTimestamp`) rewritten with identical values. |
| op-mainnet-10 | AnchorStateRegistry `0x23b2c62946350f4246f9f9d027e071f0264fd113` | 0x360894a1..382bbc | `0x0000000000000000000000008f40cc98d694ab986f026c5383a181fcc9b6b281` | `0x0000000000000000000000002b27299c577d4720100e2735b652444dcea652d0` | EIP-1967 implementation. Written 4x in the tx (StorageSetter -> impl -> StorageSetter -> impl) by `OPContractsManagerUtils.upgrade` (src/L1/opcm/OPContractsManagerUtils.sol:354,372,379,386); net = new v9 implementation. |
| op-mainnet-10 | DelayedWETH `0x1b6dbf05eaf22d4e70dc993e8a19dd9f3dcb3162` | 5 | `0x0000000000000000000000000000000000000000000000000000000000000000` | `0x000000000000000000000000322b47ff1fa8d5611f761e3e275c45b71b294d43` | NEW v9 field `ethLockbox` (slot 5, was unused/zero). `DelayedWETH.initialize` (src/dispute/DelayedWETH.sol:62). |
| op-mainnet-10 | DelayedWETH `0x1b6dbf05eaf22d4e70dc993e8a19dd9f3dcb3162` | 0x360894a1..382bbc | `0x000000000000000000000000e440cc08a71694c8229323803f59024e3144630e` | `0x000000000000000000000000f024e96317907c3b8d8cb346b9fd9034c8640e15` | EIP-1967 implementation. Written 4x in the tx (StorageSetter -> impl -> StorageSetter -> impl) by `OPContractsManagerUtils.upgrade` (src/L1/opcm/OPContractsManagerUtils.sol:354,372,379,386); net = new v9 implementation. |
| op-mainnet-10 | DisputeGameFactory `0xe5965ab5962edc7477c8520243a95517cd252fa9` | 0x42faa456..aaa794 | `0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df` | `0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9` | `gameArgs[9]` data word 0 (keccak(keccak(9 . 105))) = absolutePrestate of SUPER_CANNON_KONA: 0x031ac6f1.. -> 0x03e5a548..37c9 (kona-client v1.9.0). `DisputeGameFactory.setImplementation` from `_apply` (OPContractsManagerV2.sol:984). |
| op-mainnet-10 | DisputeGameFactory `0xe5965ab5962edc7477c8520243a95517cd252fa9` | 0x7879f54b..a5acf7 | `0x23b2c62946350f4246f9f9d027e071f0264fd113473300df21d047806a082244` | `0x23b2c62946350f4246f9f9d027e071f0264fd113c27ba3e0fc01567a5e57ae0c` | `gameArgs[5]` (SUPER_PERMISSIONED, 40 bytes = ASR ++ proposer) data words: proposer 0x473300df21D047806A082244b417f96b32f13A33 -> 0xc27BA3e0fc01567a5E57ae0c391aa98cecba5be0 (upgrade INPUT; OP Mainnet only). `setImplementation` (OPContractsManagerV2.sol:984). |
| op-mainnet-10 | DisputeGameFactory `0xe5965ab5962edc7477c8520243a95517cd252fa9` | 0x7879f54b..a5acf8 | `0xb417f96b32f13a33000000000000000000000000000000000000000000000000` | `0x391aa98cecba5be0000000000000000000000000000000000000000000000000` | `gameArgs[5]` (SUPER_PERMISSIONED, 40 bytes = ASR ++ proposer) data words: proposer 0x473300df21D047806A082244b417f96b32f13A33 -> 0xc27BA3e0fc01567a5E57ae0c391aa98cecba5be0 (upgrade INPUT; OP Mainnet only). `setImplementation` (OPContractsManagerV2.sol:984). |
| op-mainnet-10 | ETHLockbox `0x322b47ff1fa8d5611f761e3e275c45b71b294d43` | 3 | `0x0000000000000000000000000000000000000000000000000000000000000000` | `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c` | NEW v9 field `superchainConfig` (slot 3, was unused/zero). `ETHLockbox.initialize` (src/L1/ETHLockbox.sol:105) with `_cts.systemConfig.superchainConfig()` (OPContractsManagerV2.sol:891). |
| op-mainnet-10 | ETHLockbox `0x322b47ff1fa8d5611f761e3e275c45b71b294d43` | 0x360894a1..382bbc | `0x000000000000000000000000b3a24db07038b51962026329b62e7a965d56a6ad` | `0x000000000000000000000000df75e6b07e98873e36ba5c05508f80c1454e0afe` | EIP-1967 implementation. Written 4x in the tx (StorageSetter -> impl -> StorageSetter -> impl) by `OPContractsManagerUtils.upgrade` (src/L1/opcm/OPContractsManagerUtils.sol:354,372,379,386); net = new v9 implementation. |
| op-mainnet-10 | OptimismPortal2 `0xbeb5fc579115071764c7423a4f12edde41f106ed` | 0x360894a1..382bbc | `0x0000000000000000000000001005217ad392dc64cef501fa1777a27d42166748` | `0x000000000000000000000000b20b23af6071405c37ddda0c0640e8ebb7899645` | EIP-1967 implementation. Written 4x in the tx (StorageSetter -> impl -> StorageSetter -> impl) by `OPContractsManagerUtils.upgrade` (src/L1/opcm/OPContractsManagerUtils.sol:354,372,379,386); net = new v9 implementation. |
| shared | SuperchainConfig `0x95703e0982140d16f8eba6d158fccede42f04a4c` | 0x360894a1..382bbc | `0x0000000000000000000000005570b1f2b97b1e35b5c6f9ee76f6cf02c9917504` | `0x000000000000000000000000a303a644cfbc0c34f6a9dbeafdeba4c967ea01e7` | EIP-1967 implementation. Written 4x in the tx (StorageSetter -> impl -> StorageSetter -> impl) by `OPContractsManagerUtils.upgrade` (src/L1/opcm/OPContractsManagerUtils.sol:354,372,379,386); net = new v9 implementation. |
| op-mainnet-10 | SystemConfig `0x229047fed2591dbec1ef1118d64f7af3db9eb290` | 0x360894a1..382bbc | `0x000000000000000000000000670b850a235a6fa98cd7a195eb139d0277e471fa` | `0x000000000000000000000000ade27248542c0f3e89b49e4eb76155e267f14377` | EIP-1967 implementation. Written 4x in the tx (StorageSetter -> impl -> StorageSetter -> impl) by `OPContractsManagerUtils.upgrade` (src/L1/opcm/OPContractsManagerUtils.sol:354,372,379,386); net = new v9 implementation. |
| op-mainnet-10 | SystemConfig `0x229047fed2591dbec1ef1118d64f7af3db9eb290` | 0x99f45962..63ff42 | `0x0000000000000000000000001951828ce913dc4383a8a1695695d537a11d896a` | `0x0000000000000000000000002d91e6f2bcf6cd1df90e1faf9714e18705ea331f` | `OPCM_SLOT` (keccak('systemconfig.opcm')-1) = lastUsedOPCM: 8.0.1 OPCM -> OPCMV2 9.0.3. `SystemConfig.initialize` (src/L1/SystemConfig.sol:237) with `addrs.opcm = opcmV2` (OPContractsManagerV2.sol:852). |
| ink-57073 | AddressManager `0x9b7c9bbd6d540a8a4dedd935819fc4408ba71153` | 0x51521693..c9385e | `0x00000000000000000000000059d497530b00062f40950ba8eab88868bf7f86f0` | `0x0000000000000000000000007d4ec7fb1a1b9e6d61c04d5e21e3d68cff639448` | `addresses[keccak('OVM_L1CrossDomainMessenger')]`: L1CDM implementation 2.11.1 -> 2.13.0 (ResolvedDelegateProxy path of `ProxyAdmin.upgrade`, src/universal/ProxyAdmin.sol:159-161). |
| ink-57073 | AnchorStateRegistry `0xee018baf058227872540ac60efbd38b023d9dae2` | 6 | `0x000000000000000000000000000000000000000000000000688271ab00000009` | `0xbd4abb321138e8eddc399ce64e66451294325a1400000000688271ab00000009` | NEW v9 field `ethLockbox` packed into slot 6 bytes 12..31 (zero before). `AnchorStateRegistry.initialize` (src/dispute/AnchorStateRegistry.sol:107). Low 12 bytes (`respectedGameType`, `retirementTimestamp`) rewritten with identical values. |
| ink-57073 | AnchorStateRegistry `0xee018baf058227872540ac60efbd38b023d9dae2` | 0x360894a1..382bbc | `0x0000000000000000000000008f40cc98d694ab986f026c5383a181fcc9b6b281` | `0x0000000000000000000000002b27299c577d4720100e2735b652444dcea652d0` | EIP-1967 implementation. Written 4x in the tx (StorageSetter -> impl -> StorageSetter -> impl) by `OPContractsManagerUtils.upgrade` (src/L1/opcm/OPContractsManagerUtils.sol:354,372,379,386); net = new v9 implementation. |
| ink-57073 | DelayedWETH `0x57b4c29daee99a28e6e86778b499361294c134ea` | 5 | `0x0000000000000000000000000000000000000000000000000000000000000000` | `0x000000000000000000000000bd4abb321138e8eddc399ce64e66451294325a14` | NEW v9 field `ethLockbox` (slot 5, was unused/zero). `DelayedWETH.initialize` (src/dispute/DelayedWETH.sol:62). |
| ink-57073 | DelayedWETH `0x57b4c29daee99a28e6e86778b499361294c134ea` | 0x360894a1..382bbc | `0x000000000000000000000000e440cc08a71694c8229323803f59024e3144630e` | `0x000000000000000000000000f024e96317907c3b8d8cb346b9fd9034c8640e15` | EIP-1967 implementation. Written 4x in the tx (StorageSetter -> impl -> StorageSetter -> impl) by `OPContractsManagerUtils.upgrade` (src/L1/opcm/OPContractsManagerUtils.sol:354,372,379,386); net = new v9 implementation. |
| ink-57073 | DisputeGameFactory `0x10d7b35078d3baabb96dd45a9143b94be65b12cd` | 0x42faa456..aaa794 | `0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df` | `0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9` | `gameArgs[9]` data word 0 (keccak(keccak(9 . 105))) = absolutePrestate of SUPER_CANNON_KONA: 0x031ac6f1.. -> 0x03e5a548..37c9 (kona-client v1.9.0). `DisputeGameFactory.setImplementation` from `_apply` (OPContractsManagerV2.sol:984). |
| ink-57073 | ETHLockbox `0xbd4abb321138e8eddc399ce64e66451294325a14` | 3 | `0x0000000000000000000000000000000000000000000000000000000000000000` | `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c` | NEW v9 field `superchainConfig` (slot 3, was unused/zero). `ETHLockbox.initialize` (src/L1/ETHLockbox.sol:105) with `_cts.systemConfig.superchainConfig()` (OPContractsManagerV2.sol:891). |
| ink-57073 | ETHLockbox `0xbd4abb321138e8eddc399ce64e66451294325a14` | 0x360894a1..382bbc | `0x000000000000000000000000b3a24db07038b51962026329b62e7a965d56a6ad` | `0x000000000000000000000000df75e6b07e98873e36ba5c05508f80c1454e0afe` | EIP-1967 implementation. Written 4x in the tx (StorageSetter -> impl -> StorageSetter -> impl) by `OPContractsManagerUtils.upgrade` (src/L1/opcm/OPContractsManagerUtils.sol:354,372,379,386); net = new v9 implementation. |
| ink-57073 | OptimismPortal2 `0x5d66c1782664115999c47c9fa5cd031f495d3e4f` | 0x360894a1..382bbc | `0x0000000000000000000000001005217ad392dc64cef501fa1777a27d42166748` | `0x000000000000000000000000b20b23af6071405c37ddda0c0640e8ebb7899645` | EIP-1967 implementation. Written 4x in the tx (StorageSetter -> impl -> StorageSetter -> impl) by `OPContractsManagerUtils.upgrade` (src/L1/opcm/OPContractsManagerUtils.sol:354,372,379,386); net = new v9 implementation. |
| ink-57073 | SystemConfig `0x62c0a111929fa32cec2f76adba54c16afb6e8364` | 0x360894a1..382bbc | `0x000000000000000000000000670b850a235a6fa98cd7a195eb139d0277e471fa` | `0x000000000000000000000000ade27248542c0f3e89b49e4eb76155e267f14377` | EIP-1967 implementation. Written 4x in the tx (StorageSetter -> impl -> StorageSetter -> impl) by `OPContractsManagerUtils.upgrade` (src/L1/opcm/OPContractsManagerUtils.sol:354,372,379,386); net = new v9 implementation. |
| ink-57073 | SystemConfig `0x62c0a111929fa32cec2f76adba54c16afb6e8364` | 0x99f45962..63ff42 | `0x0000000000000000000000001951828ce913dc4383a8a1695695d537a11d896a` | `0x0000000000000000000000002d91e6f2bcf6cd1df90e1faf9714e18705ea331f` | `OPCM_SLOT` (keccak('systemconfig.opcm')-1) = lastUsedOPCM: 8.0.1 OPCM -> OPCMV2 9.0.3. `SystemConfig.initialize` (src/L1/SystemConfig.sol:237) with `addrs.opcm = opcmV2` (OPContractsManagerV2.sol:852). |
| soneium-1868 | AddressManager `0xb24bfeece1b3b7a44559f4cbc21bed312b130b70` | 0x51521693..c9385e | `0x00000000000000000000000059d497530b00062f40950ba8eab88868bf7f86f0` | `0x0000000000000000000000007d4ec7fb1a1b9e6d61c04d5e21e3d68cff639448` | `addresses[keccak('OVM_L1CrossDomainMessenger')]`: L1CDM implementation 2.11.1 -> 2.13.0 (ResolvedDelegateProxy path of `ProxyAdmin.upgrade`, src/universal/ProxyAdmin.sol:159-161). |
| soneium-1868 | AnchorStateRegistry `0x4890928941e62e273da359374b105f803329f473` | 6 | `0x000000000000000000000000000000000000000000000000688274ff00000005` | `0x67b4de6ffa66ef201ea6099a89ca397d56622e3100000000688274ff00000005` | NEW v9 field `ethLockbox` packed into slot 6 bytes 12..31 (zero before). `AnchorStateRegistry.initialize` (src/dispute/AnchorStateRegistry.sol:107). Low 12 bytes (`respectedGameType`, `retirementTimestamp`) rewritten with identical values. |
| soneium-1868 | AnchorStateRegistry `0x4890928941e62e273da359374b105f803329f473` | 0x360894a1..382bbc | `0x0000000000000000000000008f40cc98d694ab986f026c5383a181fcc9b6b281` | `0x0000000000000000000000002b27299c577d4720100e2735b652444dcea652d0` | EIP-1967 implementation. Written 4x in the tx (StorageSetter -> impl -> StorageSetter -> impl) by `OPContractsManagerUtils.upgrade` (src/L1/opcm/OPContractsManagerUtils.sol:354,372,379,386); net = new v9 implementation. |
| soneium-1868 | DelayedWETH `0x18fbb58c366e21f395ddec7cba0510a2d9116b47` | 5 | `0x0000000000000000000000000000000000000000000000000000000000000000` | `0x00000000000000000000000067b4de6ffa66ef201ea6099a89ca397d56622e31` | NEW v9 field `ethLockbox` (slot 5, was unused/zero). `DelayedWETH.initialize` (src/dispute/DelayedWETH.sol:62). |
| soneium-1868 | DelayedWETH `0x18fbb58c366e21f395ddec7cba0510a2d9116b47` | 0x360894a1..382bbc | `0x000000000000000000000000e440cc08a71694c8229323803f59024e3144630e` | `0x000000000000000000000000f024e96317907c3b8d8cb346b9fd9034c8640e15` | EIP-1967 implementation. Written 4x in the tx (StorageSetter -> impl -> StorageSetter -> impl) by `OPContractsManagerUtils.upgrade` (src/L1/opcm/OPContractsManagerUtils.sol:354,372,379,386); net = new v9 implementation. |
| soneium-1868 | ETHLockbox `0x67b4de6ffa66ef201ea6099a89ca397d56622e31` | 3 | `0x0000000000000000000000000000000000000000000000000000000000000000` | `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c` | NEW v9 field `superchainConfig` (slot 3, was unused/zero). `ETHLockbox.initialize` (src/L1/ETHLockbox.sol:105) with `_cts.systemConfig.superchainConfig()` (OPContractsManagerV2.sol:891). |
| soneium-1868 | ETHLockbox `0x67b4de6ffa66ef201ea6099a89ca397d56622e31` | 0x360894a1..382bbc | `0x000000000000000000000000b3a24db07038b51962026329b62e7a965d56a6ad` | `0x000000000000000000000000df75e6b07e98873e36ba5c05508f80c1454e0afe` | EIP-1967 implementation. Written 4x in the tx (StorageSetter -> impl -> StorageSetter -> impl) by `OPContractsManagerUtils.upgrade` (src/L1/opcm/OPContractsManagerUtils.sol:354,372,379,386); net = new v9 implementation. |
| soneium-1868 | OptimismPortal2 `0x88e529a6ccd302c948689cd5156c83d4614fae92` | 0x360894a1..382bbc | `0x0000000000000000000000001005217ad392dc64cef501fa1777a27d42166748` | `0x000000000000000000000000b20b23af6071405c37ddda0c0640e8ebb7899645` | EIP-1967 implementation. Written 4x in the tx (StorageSetter -> impl -> StorageSetter -> impl) by `OPContractsManagerUtils.upgrade` (src/L1/opcm/OPContractsManagerUtils.sol:354,372,379,386); net = new v9 implementation. |
| soneium-1868 | SystemConfig `0x7a8ed66b319911a0f3e7288bddab30d9c0c875c3` | 0x360894a1..382bbc | `0x000000000000000000000000670b850a235a6fa98cd7a195eb139d0277e471fa` | `0x000000000000000000000000ade27248542c0f3e89b49e4eb76155e267f14377` | EIP-1967 implementation. Written 4x in the tx (StorageSetter -> impl -> StorageSetter -> impl) by `OPContractsManagerUtils.upgrade` (src/L1/opcm/OPContractsManagerUtils.sol:354,372,379,386); net = new v9 implementation. |
| soneium-1868 | SystemConfig `0x7a8ed66b319911a0f3e7288bddab30d9c0c875c3` | 0x99f45962..63ff42 | `0x0000000000000000000000001951828ce913dc4383a8a1695695d537a11d896a` | `0x0000000000000000000000002d91e6f2bcf6cd1df90e1faf9714e18705ea331f` | `OPCM_SLOT` (keccak('systemconfig.opcm')-1) = lastUsedOPCM: 8.0.1 OPCM -> OPCMV2 9.0.3. `SystemConfig.initialize` (src/L1/SystemConfig.sol:237) with `addrs.opcm = opcmV2` (OPContractsManagerV2.sol:852). |
| unichain-130 | AddressManager `0x8098f676033a377b9defe302e9fe6877cd63d575` | 0x51521693..c9385e | `0x00000000000000000000000059d497530b00062f40950ba8eab88868bf7f86f0` | `0x0000000000000000000000007d4ec7fb1a1b9e6d61c04d5e21e3d68cff639448` | `addresses[keccak('OVM_L1CrossDomainMessenger')]`: L1CDM implementation 2.11.1 -> 2.13.0 (ResolvedDelegateProxy path of `ProxyAdmin.upgrade`, src/universal/ProxyAdmin.sol:159-161). |
| unichain-130 | AnchorStateRegistry `0x27cf508e4e3aa8d30b3226ac3b5ea0e8bcacaff9` | 6 | `0x0000000000000000000000000000000000000000000000006882777b00000009` | `0x08ba0023ed60c7bd040716dd13c45fa0062df5c5000000006882777b00000009` | NEW v9 field `ethLockbox` packed into slot 6 bytes 12..31 (zero before). `AnchorStateRegistry.initialize` (src/dispute/AnchorStateRegistry.sol:107). Low 12 bytes (`respectedGameType`, `retirementTimestamp`) rewritten with identical values. |
| unichain-130 | AnchorStateRegistry `0x27cf508e4e3aa8d30b3226ac3b5ea0e8bcacaff9` | 0x360894a1..382bbc | `0x0000000000000000000000008f40cc98d694ab986f026c5383a181fcc9b6b281` | `0x0000000000000000000000002b27299c577d4720100e2735b652444dcea652d0` | EIP-1967 implementation. Written 4x in the tx (StorageSetter -> impl -> StorageSetter -> impl) by `OPContractsManagerUtils.upgrade` (src/L1/opcm/OPContractsManagerUtils.sol:354,372,379,386); net = new v9 implementation. |
| unichain-130 | DelayedWETH `0x74ad145ac900f1dd5551f0c9e143314dc4022fcf` | 5 | `0x0000000000000000000000000000000000000000000000000000000000000000` | `0x00000000000000000000000008ba0023ed60c7bd040716dd13c45fa0062df5c5` | NEW v9 field `ethLockbox` (slot 5, was unused/zero). `DelayedWETH.initialize` (src/dispute/DelayedWETH.sol:62). |
| unichain-130 | DelayedWETH `0x74ad145ac900f1dd5551f0c9e143314dc4022fcf` | 0x360894a1..382bbc | `0x000000000000000000000000e440cc08a71694c8229323803f59024e3144630e` | `0x000000000000000000000000f024e96317907c3b8d8cb346b9fd9034c8640e15` | EIP-1967 implementation. Written 4x in the tx (StorageSetter -> impl -> StorageSetter -> impl) by `OPContractsManagerUtils.upgrade` (src/L1/opcm/OPContractsManagerUtils.sol:354,372,379,386); net = new v9 implementation. |
| unichain-130 | DisputeGameFactory `0x2f12d621a16e2d3285929c9996f478508951dfe4` | 0x42faa456..aaa794 | `0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df` | `0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9` | `gameArgs[9]` data word 0 (keccak(keccak(9 . 105))) = absolutePrestate of SUPER_CANNON_KONA: 0x031ac6f1.. -> 0x03e5a548..37c9 (kona-client v1.9.0). `DisputeGameFactory.setImplementation` from `_apply` (OPContractsManagerV2.sol:984). |
| unichain-130 | ETHLockbox `0x08ba0023ed60c7bd040716dd13c45fa0062df5c5` | 3 | `0x0000000000000000000000000000000000000000000000000000000000000000` | `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c` | NEW v9 field `superchainConfig` (slot 3, was unused/zero). `ETHLockbox.initialize` (src/L1/ETHLockbox.sol:105) with `_cts.systemConfig.superchainConfig()` (OPContractsManagerV2.sol:891). |
| unichain-130 | ETHLockbox `0x08ba0023ed60c7bd040716dd13c45fa0062df5c5` | 0x360894a1..382bbc | `0x000000000000000000000000b3a24db07038b51962026329b62e7a965d56a6ad` | `0x000000000000000000000000df75e6b07e98873e36ba5c05508f80c1454e0afe` | EIP-1967 implementation. Written 4x in the tx (StorageSetter -> impl -> StorageSetter -> impl) by `OPContractsManagerUtils.upgrade` (src/L1/opcm/OPContractsManagerUtils.sol:354,372,379,386); net = new v9 implementation. |
| unichain-130 | OptimismPortal2 `0x0bd48f6b86a26d3a217d0fa6ffe2b491b956a7a2` | 0x360894a1..382bbc | `0x0000000000000000000000001005217ad392dc64cef501fa1777a27d42166748` | `0x000000000000000000000000b20b23af6071405c37ddda0c0640e8ebb7899645` | EIP-1967 implementation. Written 4x in the tx (StorageSetter -> impl -> StorageSetter -> impl) by `OPContractsManagerUtils.upgrade` (src/L1/opcm/OPContractsManagerUtils.sol:354,372,379,386); net = new v9 implementation. |
| unichain-130 | SystemConfig `0xc407398d063f942febbcc6f80a156b47f3f1bda6` | 0x360894a1..382bbc | `0x000000000000000000000000670b850a235a6fa98cd7a195eb139d0277e471fa` | `0x000000000000000000000000ade27248542c0f3e89b49e4eb76155e267f14377` | EIP-1967 implementation. Written 4x in the tx (StorageSetter -> impl -> StorageSetter -> impl) by `OPContractsManagerUtils.upgrade` (src/L1/opcm/OPContractsManagerUtils.sol:354,372,379,386); net = new v9 implementation. |
| unichain-130 | SystemConfig `0xc407398d063f942febbcc6f80a156b47f3f1bda6` | 0x99f45962..63ff42 | `0x0000000000000000000000001951828ce913dc4383a8a1695695d537a11d896a` | `0x0000000000000000000000002d91e6f2bcf6cd1df90e1faf9714e18705ea331f` | `OPCM_SLOT` (keccak('systemconfig.opcm')-1) = lastUsedOPCM: 8.0.1 OPCM -> OPCMV2 9.0.3. `SystemConfig.initialize` (src/L1/SystemConfig.sol:237) with `addrs.opcm = opcmV2` (OPContractsManagerV2.sol:852). |

Count check: 33 implementation slots (4 x {SystemConfig, Portal, ETHLockbox, ASR, DelayedWETH} = 20... see table; the
L1StandardBridge / L1ERC721Bridge / OptimismMintableERC20Factory / DisputeGameFactory proxies show **no** net change
because their v9 implementation address equals the v8 one, see §4) + 1 SuperchainConfig implementation.

Writes that happened inside the tx but netted to zero (from the call trace, 571 state-changing calls):

* `_initialized` byte of every proxy: zeroed through `StorageSetter.setBytes32(slot 0, current & mask)` and set back to
  the same `initVersion` by `initialize` (Portal/SystemConfig/L1CDM/L1SB/L1ERC721: 3; SuperchainConfig: 2; others: 1).
  For the L1CDM the byte is slot 0 **offset 20** (OPContractsManagerV2.sol:901-908).
* `SystemConfig.initialize` rewrote owner, `batcherHash`, `basefeeScalar`, `blobbasefeeScalar`, `scalar` (recomputed),
  `gasLimit`, unsafe block signer, 6 address slots, `overhead = 0`, `LEGACY_BATCH_INBOX_SLOT = 0`, `_resourceConfig`,
  `l2ChainId`, `superchainConfig` with the values loaded from the proxy just before (`_loadFullConfig`,
  OPContractsManagerV2.sol:552-682). All identical => 3 `ConfigUpdate` events per chain (BATCHER, FEE_SCALARS, GAS_LIMIT;
  12 logs of topic `0x1d2b0bda..` in the receipt) carrying the pre-existing values.
* `OptimismPortal2.initialize(systemConfig, anchorStateRegistry, ethLockbox)` rewrote slots 55, 62, 63 with themselves.
* `ETHLockbox.initialize` re-authorised the chain's own portal (`authorizedPortals[portal]` already `true`).
* `DisputeGameFactory.initialize(Safe)`: `_owner` ProxyAdmin -> Safe (2 `OwnershipTransferred` each for DGF and
  SystemConfig, 16 logs), `setImplementation`/`setInitBond` for types 0,1,8,5,9,10 and the unconditional clear of type 4.
  Only the words listed in the table changed value.
* `L1StandardBridge`, `L1ERC721Bridge`, `OptimismMintableERC20Factory`: re-initialised with unchanged arguments.
* `AnchorStateRegistry.initialize`: `startingAnchorRoot` identical => `anchorGame` kept (AnchorStateRegistry.sol:113-122).
* `SuperchainConfig.initialize(guardian())`: same guardian.
* NOT executed (absent from the trace): `SystemConfig.setFeature`, `OptimismPortal2.migrateLiquidity`, `ETHLockbox.lockETH`,
  any `authorizeLockbox`/`migrateLiquidity`, any `transferOwnership` of a ProxyAdmin.

### 3.2 Whole-block delta N-1 -> N that is NOT from the upgrade tx

| Chain | Contract | Change | Cause |
|---|---|---|---|
| OP Mainnet | OptimismPortal2 slot 1 `params` | `prevBlockNum` 26430830 -> 26430859, `prevBoughtGas` 516982 -> 515958 | deposit tx `0x762e0faa..cfda2`, index **341** of block N (17 txs *before* the upgrade, still executed by v8 code) |
| OP Mainnet | ETHLockbox balance | 182416.3065 -> 182420.5112 ETH (+4.2047) | same deposit (`ETHLocked` log index 633) |
| OP Mainnet | L1CrossDomainMessenger slot 205 `msgNonce` | 0x42a0e -> 0x42a0f | same deposit |

Nothing else changed in block N on any of the 48 dumped contracts (`evidence/lane02/delta_N-1_to_N.txt`).

### 3.3 N -> 26433900 (3041 blocks later)

Only organic activity; **no follow-up privileged write** to any touched proxy (`evidence/lane02/delta_N_to_26433900.txt`,
getter comparison of the two POST dumps):

| Chain | Portal `params.prevBlockNum` | `msgNonce` | ETHLockbox ETH | DGF `gameCount` | ASR `anchorGame` | DelayedWETH ETH |
|---|---|---|---|---|---|---|
| OP | 26430859 -> 26433899 | +94 | +120.557 | 21378 -> 21389 | `0x51024A83..` -> `0x55A5CFd4..` | +0.08 |
| Ink | -> 26433755 | +19 | 0 | 2639 -> 2640 | `0x7A5559F3..` -> `0x38925Ef2..` | 0 |
| Soneium | -> 26433755 | +20 | 0 | 8533 -> 8537 | `0xa64e0DAf..` -> `0x5DFb50E0..` | 0 |
| Unichain | -> 26433755 | +19 | +43.811 | 17681 -> 17691 | `0x55AE7D93..` -> `0x944A783A..` | 0 |

All config slots, implementations, feature flags, `respectedGameType`, `retirementTimestamp`, guardian, owners, pause
timestamps are identical at N and 26433900. (Block 26433755: one tx `0xb5ad9108..d6bcfe` sent one L1CDM message on several
chains at once; ordinary traffic.) On OP Mainnet 3 withdrawals were proven and 4 finalized after N under v9, see §6.

## 4. Slots that "should have changed" and did not (each one explained)

| Expectation | Observation | Verdict |
|---|---|---|
| L1StandardBridge, L1ERC721Bridge, OptimismMintableERC20Factory, DisputeGameFactory get new implementations (they are in the `Upgraded` log sequence, and `SafeCall`/`Constants`/`Predeploys` libraries changed) | implementation addresses identical at N-1 and N: `0xb37a11aa..` (2.8.2), `0x9f164f1d..` (2.9.1), `0xaabea75d..` (1.11.0), `0x72b97171..` (1.6.1) | **correct**: deployed code == local v9 `forge-artifacts` bytecode, immutables masked (`bytecode_check.txt`: MATCH for all 13 contracts incl. OPCMV2 and StorageSetter). v8 -> v9 source changes in these files are formatting only, `bytecode_hash = 'none'` |
| Game implementations / MIPS64 / PreimageOracle redeployed (their sources are in the v8 -> v9 changed list) | `gameImpls(5) = 0x5C3eb47c..`, `gameImpls(9) = 0x19AF533C..`, MIPS `0xacc005dc..` unchanged | **correct**: diffs are formatting only; deployed `SuperFaultDisputeGame` / `SuperPermissionedDisputeGame` match the v9 artifacts |
| Portal legacy slots (53 old `superchainConfig`, 54 `l2Oracle`, 56 `disputeGameFactory`, 59 `respectedGameTypeUpdatedAt`) cleaned up | still non-zero | benign: private `spacer_*`, no reader in v9 (see §5) |
| ETHLockbox / ASR slot 0 and DelayedWETH slot 4 old `systemConfig` cleared when the field became a spacer | still the SystemConfig address | benign today; **latent**: three stale-but-plausible addresses sit in slots a future version might re-use |
| `ETHLockbox.authorizedLockboxes`, portal `spacer_63_20_1` (`superRootsActive`), `INTEROP` feature | zero / false | expected: U21 does not run `migrate` |
| ETH moved portal -> lockbox on a chain that kept ETH in the portal | no ETH moved | expected: all four portals held 0 ETH at N-1 and already had `ETH_LOCKBOX = true` + a lockbox (`wasUsingEthLockbox`, OPContractsManagerV2.sol:864-897) |
| Pause identifier switch portal -> lockbox | none | all four chains already used the lockbox identifier; `SuperchainConfig.pauseTimestamps` is 0 for `address(0)`, the 4 portals and the 4 lockboxes at N-1, N and 26433900 |
| `AnchorStateRegistry.retirementTimestamp` bumped / `anchorGame` cleared by re-init | unchanged | by design (:111-132); pre-U21 type-9 games keep the old prestate and stay valid |
| SUPER_PERMISSIONED proposer changed on all chains | only OP Mainnet changed | upgrade input; Ink `0x3832bfbe..`, Soneium `0x400c164c..`, Unichain `0x86b392ca..` unchanged |
| `SystemConfig` fields not covered by `initialize` (`eip1559Denominator/Elasticity`, `operatorFee*`, `daFootprintGasScalar`, `minBaseFee`) | unchanged, no event | correct: not rewritten, so L2 derivation sees no change (Ink keeps 0/0 EIP-1559 params, Soneium `minBaseFee` 12,000,000, Unichain 500,000) |

## 5. Non-zero legacy slots on mainnet and their v9 reading

| Contract.slot | Legacy meaning | OP Mainnet value at N | Other chains | v9 reader |
|---|---|---|---|---|
| Portal 52 | pre-fault-proof `provenWithdrawals` mapping base | 0 (mapping base) | 0 | none |
| Portal 53[0] | `paused` | 0 | 0 | none |
| Portal 53[1:21] | `superchainConfig` | `0x95703e09..` | same on all | none (v9 uses `ethLockbox.superchainConfig()`) |
| Portal 54 | `l2Oracle` | `0xdfe97868233d1aa22e815a266982f2cf17685a27` | 0 on Ink/Soneium/Unichain | none |
| Portal 56 | `disputeGameFactory` | `0xe5965Ab5..` (= current DGF) | each chain's current DGF | none (v9 uses `anchorStateRegistry.disputeGameFactory()`) |
| Portal 58 | `disputeGameBlacklist` mapping base | 0 | 0 | none (ASR mapping is used) |
| Portal 59[0:4] | `respectedGameType` | 0 | Soneium **1**, Ink/Unichain 0 | none (stale vs ASR: 9 / 5) |
| Portal 59[4:12] | `respectedGameTypeUpdatedAt` | 1726070915 | Ink 1737576635, Soneium 1733134751, Unichain 1737658703 | none (getter returns `asr.retirementTimestamp()`) |
| Portal 61 | `_balance` | 0 | 0 | none |
| Portal 63[20] | `superRootsActive` | 0 | 0 | none |
| ETHLockbox 0[2:22], ASR 0[2:22], DelayedWETH 4 | `systemConfig` | chain's SystemConfig | idem | none |
| L1CDM 51 | OVM `_owner` | `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A` | 0 | none |
| L1CDM 151 | ReentrancyGuard `_status` | 1 | 0 | none |
| L1CDM 251 | `superchainConfig` | `0x95703e09..` | same | none (v9 uses `systemConfig.superchainConfig()`) |
| L1StandardBridge 1 | old `messenger` | `0x4200..0010` | 0 | none |
| L1StandardBridge 50, L1ERC721Bridge 50 | `superchainConfig` | `0x95703e09..` | same | none |
| SystemConfig 101 `overhead`, `LEGACY_BATCH_INBOX_SLOT`, `systemconfig.l2outputoracle`, `systemconfig.disputegamefactory`, `opstack.gaspayingtoken*` | deprecated | all 0 | all 0 | `overhead()` getter only |

Proof that none of them is read: (i) every one is declared `private` with no reference in the v9 sources (no assembly
`sload` in the Portal besides the memory cast at :856-858); (ii) `test_legacySpacerSlotsAreDeadStorage`
(`test/poc/lane02/U21StorageReinit.t.sol`) overwrites all of them with junk on a block-N fork of each of the four chains
and shows that 16 getters (pause, guardian, superchainConfig, lockbox, ASR, DGF, respected type, anchor root ...) are
unchanged and that a 1 ETH `depositTransaction` still lands in the lockbox.

## 6. Proven / finalized withdrawal mappings across the boundary

Layout (identical in v7, v8, v9): `finalizedWithdrawals` slot 51 (`mapping(bytes32 => bool)`), `provenWithdrawals` slot 57
(`mapping(bytes32 => mapping(address => ProvenWithdrawal{IDisputeGame disputeGameProxy; uint64 timestamp}))`, one word:
`[timestamp(8) | game(20)]`), `proofSubmitters` slot 60 (`mapping(bytes32 => address[])`). The legacy single-proof mapping
at slot 52 is a dead spacer.

Sample: `WithdrawalProven` / `WithdrawalProvenExtension1` / `WithdrawalFinalized` logs of the four portals for blocks
[N-5000, 26433900] (`evidence/lane02/portal_withdrawal_logs.json`; older ranges are not served by the public log RPCs).
21 entries (12 OP, 1 Ink, 4 Soneium, 4 Unichain) were read as raw slots **and** through the public getters at N-1 (v8
code), N (v9 code) and 26433900: **21 / 21 byte-identical at N-1 vs N** (`withdrawal_mapping_check.json`).

Cross-boundary life cycles observed on chain (OP Mainnet):

| withdrawalHash | proven (v8) | `checkWithdrawal` at N-1 (v8) | at N (v9) | finalized (v9) |
|---|---|---|---|---|
| `0x73f7d34a..` | ts 1792657955 (2 submitters) | passes | passes | block 26430910 |
| `0x161695e7..` | ts 1792488323 (2026-10-20) | passes | passes | block 26431124 |
| `0x6d7c43da..` | ts 1794231107 | passes | passes | block 26432294 |
| `0x52f21523..` | ts 1794258083 (2026-11-09) | passes | passes | block 26433013 |

The 17 others (proven in the 5000 blocks before N) revert with `OptimismPortal_ProofNotOldEnough` under both versions, and
Soneium `0xfe80b84e..` (first submitter proved against a game created before the retirement timestamp) reverts with
`OptimismPortal_InvalidRootClaim` under both. Fork tests: `test_entriesProvenUnderV8ReadIdenticallyUnderV9`,
`test_deleteProvenWithdrawalLeavesSubmitterResidue` (`test/poc/lane02/U21WithdrawalBoundary.t.sol`).

New in v9: `deleteProvenWithdrawal` (OptimismPortal2.sol:711-728) deletes `provenWithdrawals[h][s]` but leaves `s` in
`proofSubmitters[h]`, so `numProofSubmitters(h)` no longer equals the number of live proofs (PRIM-0203).

## 7. Initialisation state after U21 (block N; identical on the four chains)

| Proxy | `_initialized` | `initVersion()` | Re-init possible? | Implementation slot 0 |
|---|---|---|---|---|
| OptimismPortal2 | 3 | 3 | no | `0xff` |
| SystemConfig | 3 | 3 | no | `0xff` |
| L1CrossDomainMessenger | 3 (slot 0 byte 20) | 3 | no | `0xff << 160` |
| L1StandardBridge / L1ERC721Bridge | 3 / 3 | 3 / 3 | no | `0xff` |
| SuperchainConfig | 2 | 2 | no | `0xff` |
| ETHLockbox / AnchorStateRegistry / DelayedWETH / DisputeGameFactory | 1 | 1 | no | `0xff` |
| OptimismMintableERC20Factory | 1 | n/a (`initializer`) | no | `0xff` |

`test_reinitializeRevertsForEveryCaller` calls all ten initializers on all four chains as a random address, as the Safe
and as the ProxyAdmin: every call reverts with `Initializable: contract is already initialized`.
`test_implementationsAreLocked`: implementations cannot be initialised; `lockETH`/`receiveLiquidity`/`unlockETH` on the
bare ETHLockbox implementation revert. On a bare implementation `proxyAdmin()` itself reverts
(`ProxyAdminOwnedBase_NotResolvedDelegateProxy`, ProxyAdminOwnedBase.sol:58-68), so every owner-gated path is dead there.
The ERC-7201 OZ-v5 `Initializable` slot is zero on every proxy. `ProxyAdmin.upgrading` is false; proxy types are
ERC1967 for everything except L1CDM (RESOLVED, name `OVM_L1CrossDomainMessenger`) and L1StandardBridge (CHUGSPLASH); every
EIP-1967 admin slot (and the AddressManager owner) is the chain's ProxyAdmin; all four ProxyAdmins and the four DGFs are
owned by the Safe `0x5a0Aae59..`.
