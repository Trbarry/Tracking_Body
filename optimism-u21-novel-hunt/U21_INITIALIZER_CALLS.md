# U21 initializer / reinitializer / StorageSetter calls (LANE 01)

Baseline: mainnet N-1 = 26430858 (`l1pre`) -> N = 26430859 (`l1n`), cross-checked at 26433900 (`l1`). All values below come from the replay of the real tx input on a fork of N-1 (`test/poc/lane01/Lane01_Replay.t.sol`, trace in `evidence/lane01-u21-replay-trace.txt`), whose end state equals the real block-N state on all 339 written slots.

## 1. What ran

- 1 x `OPCMv2.upgradeSuperchain` -> 1 `Utils.upgrade` (SuperchainConfig).
- 4 x `OPCMv2.upgrade` -> 10 `Utils.upgrade` each, in this fixed order (`OPContractsManagerV2.sol:832-959`): SystemConfig, OptimismPortal2, ETHLockbox, L1CrossDomainMessenger, L1StandardBridge, L1ERC721Bridge, OptimismMintableERC20Factory, DisputeGameFactory, DelayedWETH, AnchorStateRegistry; then 7 x (`setImplementation`, `setInitBond`) on the DisputeGameFactory (six configured types + unconditional clear of SUPER_CANNON=4).
- Total: 41 initializer executions, 41 StorageSetter `setBytes32` writes, 28 `setImplementation` + 28 `setInitBond`.
- NOT executed (confirmed by absence in trace and logs): `SystemConfig.setFeature` (ETH_LOCKBOX already true on all four chains, no `FeatureSet` log), `OptimismPortal2.migrateLiquidity` (`wasUsingEthLockbox` true; portal balances 0 before and after), any proxy deployment (no `ProxyCreation` log; the `PermittedProxyDeployment = "ETHLockbox"` instruction passed for all four chains was unused), `transferOwnership` of ProxyAdmin/DGF (initial deployment only), `migrate`.
- No proxied v9 L1 contract has an `upgrade()` reinitializer (`grep 'function upgrade('` under `src/L1`, `src/dispute`, `src/universal` only returns `OPContractsManagerV2.upgrade`, `OPContractsManagerUtils.upgrade` and `ProxyAdmin.upgrade`); the only (re)initializer entry point per contract is `initialize`.

Extra instructions supplied per chain: `overrides.cfg.startingRespectedGameType` = 9 (OP, Ink, Unichain) / 5 (Soneium) - equal to the value already stored in each AnchorStateRegistry at N-1, so the override changed nothing - and `PermittedProxyDeployment` = `"ETHLockbox"` (unused).

## 2. Initializer guard and version, before and after

Every initializer is `reinitializer(initVersion())` (OptimismMintableERC20Factory: `initializer`) plus `_assertOnlyProxyAdminOrProxyAdminOwner()`. The OPCM does not rely on a version bump: it zeroes the `_initialized` byte through StorageSetter and re-runs `initialize`, which sets the byte back to `initVersion()`.

| Contract | initVersion() N-1 | initVersion() N | `_initialized` byte N-1 | during tx (after StorageSetter) | N and 26433900 | `Initialized(v)` event | init slot/offset used by OPCM |
|---|---|---|---|---|---|---|---|
| SuperchainConfig | 2 | 2 | 2 | 0 | 2 / 2 | 2 | slot 0, offset 0 |
| SystemConfig | 3 | 3 | 3 | 0 | 3 / 3 | 3 | slot 0, offset 0 |
| OptimismPortal2 | 3 | 3 | 3 | 0 | 3 / 3 | 3 | slot 0, offset 0 |
| ETHLockbox | 1 | 1 | 1 | 0 | 1 / 1 | 1 | slot 0, offset 0 |
| L1CrossDomainMessenger | 3 | 3 | 3 | 0 | 3 / 3 | 3 | slot 0, offset 20 |
| L1StandardBridge | 3 | 3 | 3 | 0 | 3 / 3 | 3 | slot 0, offset 0 |
| L1ERC721Bridge | 3 | 3 | 3 | 0 | 3 / 3 | 3 | slot 0, offset 0 |
| OptimismMintableERC20Factory | n/a (no ReinitializableBase) | n/a | 1 | 0 | 1 / 1 | 1 | slot 0, offset 0 |
| DisputeGameFactory | 1 | 1 | 1 | 0 | 1 / 1 | 1 | slot 0, offset 0 |
| DelayedWETH | 1 | 1 | 1 | 0 | 1 / 1 | 1 | slot 0, offset 0 |
| AnchorStateRegistry | 1 | 1 | 1 | 0 | 1 / 1 | 1 | slot 0, offset 0 |

The same values hold on all four chains (checked for all 41 proxies in `evidence/lane01-upgrades-decoded.json`). After the upgrade `_initialized == initVersion()` everywhere, so `initialize` cannot be re-run by anyone - an arbitrary account, the Safe, or the ProxyAdmin - without another StorageSetter round, which needs the ProxyAdmin owner (fork test `test_reinitialize_all_proxies_reverts`, 41 proxies x 3 callers).

Implementation contracts: `_initialized == 0xff` on all eleven (`cast storage <impl> 0` on `l1`; L1CrossDomainMessenger shows `0x...ff` at byte offset 20). None is initializable.

## 3. Decoded initializer arguments per proxy


### Superchain

**SuperchainConfig** `0x95703e0982140D16f8ebA6d158FccEde42f04a4C` -> impl `0xA303a644cfbC0c34f6a9dBEaFdebA4C967EA01e7` via ProxyAdmin/AddressManager `0x543ba4aadbab8f9025686bd03993043599c6fb04`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address)`
  - arg0: `0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2`
- storage: 2 distinct slots written, 1 net-changed:
  - `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`: `0x0000000000000000000000005570b1f2b97b1e35b5c6f9ee76f6cf02c9917504` -> `0x000000000000000000000000a303a644cfbc0c34f6a9dbeafdeba4c967ea01e7`


### OP Mainnet

**SystemConfig** `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` -> impl `0xADe27248542c0F3E89b49e4eB76155e267F14377` via ProxyAdmin/AddressManager `0x543ba4aadbab8f9025686bd03993043599c6fb04`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address,uint32,uint32,bytes32,uint64,address,(uint32,uint8,uint8,uint32,uint32,uint128),(address,address,address,address,address,address,address),uint256,address)`
  - arg0: `0x847B5c174615B1B7fDF770882256e2D3E95b9D92`
  - arg1: `5227`
  - arg2: `1014213 [1.014e6]`
  - arg3: `0x0000000000000000000000006887246668a3b87f54deb3b94ba47a6f63f32985`
  - arg4: `40000000 [4e7]`
  - arg5: `0xAAAA45d9549EDA09E70937013520214382Ffc4A2`
  - arg6: `(20000000 [2e7], 10, 8, 1000000000 [1e9], 1000000 [1e6], 340282366920938463463374607431768211455 [3.402e38])`
  - arg7: `(0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1, 0x5a7749f83b81B301cAb5f48EB8516B986DAef23D, 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1, 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed, 0x75505a97BD334E7BD3C476893285569C4136Fa0F, 0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162, 0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f)`
  - arg8: `10`
  - arg9: `0x95703e0982140D16f8ebA6d158FccEde42f04a4C`
- storage: 19 distinct slots written, 2 net-changed:
  - `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`: `0x000000000000000000000000670b850a235a6fa98cd7a195eb139d0277e471fa` -> `0x000000000000000000000000ade27248542c0f3e89b49e4eb76155e267f14377`
  - `0x99f45962df4bc30de8d4c3c6d1ffc0f100edce16e80c7a5768b6d55ca463ff42`: `0x0000000000000000000000001951828ce913dc4383a8a1695695d537a11d896a` -> `0x0000000000000000000000002d91e6f2bcf6cd1df90e1faf9714e18705ea331f`

**OptimismPortal2** `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` -> impl `0xb20B23af6071405C37dDDA0C0640e8eBb7899645` via ProxyAdmin/AddressManager `0x543ba4aadbab8f9025686bd03993043599c6fb04`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address,address,address)`
  - arg0: `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290`
  - arg1: `0x23B2C62946350F4246f9f9D027e071f0264FD113`
  - arg2: `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43`
- storage: 5 distinct slots written, 1 net-changed:
  - `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`: `0x0000000000000000000000001005217ad392dc64cef501fa1777a27d42166748` -> `0x000000000000000000000000b20b23af6071405c37ddda0c0640e8ebb7899645`

**ETHLockbox** `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43` -> impl `0xDF75E6b07E98873E36BA5c05508F80c1454e0aFe` via ProxyAdmin/AddressManager `0x543ba4aadbab8f9025686bd03993043599c6fb04`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address,address[])`
  - arg0: `0x95703e0982140D16f8ebA6d158FccEde42f04a4C`
  - arg1: `[0xbEb5Fc579115071764c7423A4f12eDde41f106Ed]`
- storage: 4 distinct slots written, 2 net-changed:
  - `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`: `0x000000000000000000000000b3a24db07038b51962026329b62e7a965d56a6ad` -> `0x000000000000000000000000df75e6b07e98873e36ba5c05508f80c1454e0afe`
  - `0x0000000000000000000000000000000000000000000000000000000000000003`: `0x0000000000000000000000000000000000000000000000000000000000000000` -> `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c`

**L1CrossDomainMessenger** `0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1` -> impl `0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448` via ProxyAdmin/AddressManager `AddressManager 0xde1fcfb0851916ca5101820a69b13a4e276bd81f`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 20 zeroed>)`
- `initialize(address,address)`
  - arg0: `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290`
  - arg1: `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed`
- storage: 4 distinct slots written, 0 net-changed (all rewritten with identical values)

**L1StandardBridge** `0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1` -> impl `0xB37a11AadF167B2F0b8dD85372De4bC66CD4A891` via ProxyAdmin/AddressManager `0x543ba4aadbab8f9025686bd03993043599c6fb04`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address,address)`
  - arg0: `0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1`
  - arg1: `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290`
- storage: 5 distinct slots written, 0 net-changed (all rewritten with identical values)

**L1ERC721Bridge** `0x5a7749f83b81B301cAb5f48EB8516B986DAef23D` -> impl `0x9F164f1d02A81e06D639E55F65a87f0070E3Cb2e` via ProxyAdmin/AddressManager `0x543ba4aadbab8f9025686bd03993043599c6fb04`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address,address)`
  - arg0: `0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1`
  - arg1: `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290`
- storage: 5 distinct slots written, 0 net-changed (all rewritten with identical values)

**OptimismMintableERC20Factory** `0x75505a97BD334E7BD3C476893285569C4136Fa0F` -> impl `0xaAbEA75Da509fA518Fd8a91Eae4BE5813B829b12` via ProxyAdmin/AddressManager `0x543ba4aadbab8f9025686bd03993043599c6fb04`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address)`
  - arg0: `0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1`
- storage: 3 distinct slots written, 0 net-changed (all rewritten with identical values)

**DisputeGameFactory** `0xe5965Ab5962eDc7477C8520243A95517CD252fA9` -> impl `0x72B971717E088B59F26d4236BE222ADB6ACD393b` via ProxyAdmin/AddressManager `0x543ba4aadbab8f9025686bd03993043599c6fb04`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address)`
  - arg0: `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`
- storage: 30 distinct slots written, 3 net-changed:
  - `0x7879f54b7a738fb6adc3b9585859cd2970241c1545ca5cbe8b1895abdfa5acf7`: `0x23b2c62946350f4246f9f9d027e071f0264fd113473300df21d047806a082244` -> `0x23b2c62946350f4246f9f9d027e071f0264fd113c27ba3e0fc01567a5e57ae0c`
  - `0x7879f54b7a738fb6adc3b9585859cd2970241c1545ca5cbe8b1895abdfa5acf8`: `0xb417f96b32f13a33000000000000000000000000000000000000000000000000` -> `0x391aa98cecba5be0000000000000000000000000000000000000000000000000`
  - `0x42faa4569684ce9de6c0b2f969e15e6e43a595549e706530ccb0e79bc8aaa794`: `0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df` -> `0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9`

**DelayedWETH** `0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162` -> impl `0xF024e96317907C3b8d8CB346B9FD9034c8640e15` via ProxyAdmin/AddressManager `0x543ba4aadbab8f9025686bd03993043599c6fb04`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address)`
  - arg0: `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43`
- storage: 3 distinct slots written, 2 net-changed:
  - `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`: `0x000000000000000000000000e440cc08a71694c8229323803f59024e3144630e` -> `0x000000000000000000000000f024e96317907c3b8d8cb346b9fd9034c8640e15`
  - `0x0000000000000000000000000000000000000000000000000000000000000005`: `0x0000000000000000000000000000000000000000000000000000000000000000` -> `0x000000000000000000000000322b47ff1fa8d5611f761e3e275c45b71b294d43`

**AnchorStateRegistry** `0x23B2C62946350F4246f9f9D027e071f0264FD113` -> impl `0x2b27299C577d4720100e2735b652444DcEa652D0` via ProxyAdmin/AddressManager `0x543ba4aadbab8f9025686bd03993043599c6fb04`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address,address,(bytes32,uint256),uint32)`
  - arg0: `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43`
  - arg1: `0xe5965Ab5962eDc7477C8520243A95517CD252fA9`
  - arg2: `(0xbd4aeba96e33ef5582e14257fb776b3223ad45934ccd368c2f3084c8b75c1d68, 1788842855 [1.788e9])`
  - arg3: `9`
- storage: 6 distinct slots written, 2 net-changed:
  - `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`: `0x0000000000000000000000008f40cc98d694ab986f026c5383a181fcc9b6b281` -> `0x0000000000000000000000002b27299c577d4720100e2735b652444dcea652d0`
  - `0x0000000000000000000000000000000000000000000000000000000000000006`: `0x000000000000000000000000000000000000000000000000688271ab00000009` -> `0x322b47ff1fa8d5611f761e3e275c45b71b294d4300000000688271ab00000009`


### Ink

**SystemConfig** `0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364` -> impl `0xADe27248542c0F3E89b49e4eB76155e267F14377` via ProxyAdmin/AddressManager `0xd56045e68956fce2576e680c95a4750cf8241f79`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address,uint32,uint32,bytes32,uint64,address,(uint32,uint8,uint8,uint32,uint32,uint128),(address,address,address,address,address,address,address),uint256,address)`
  - arg0: `0x847B5c174615B1B7fDF770882256e2D3E95b9D92`
  - arg1: `4424`
  - arg2: `810831 [8.108e5]`
  - arg3: `0x0000000000000000000000006db6161fc5662450e801398bad62dd9921216b98`
  - arg4: `30000000 [3e7]`
  - arg5: `0x7b322282DF45E537E5de76D60E1432Db3cF3F8E1`
  - arg6: `(20000000 [2e7], 10, 8, 1000000000 [1e9], 1000000 [1e6], 340282366920938463463374607431768211455 [3.402e38])`
  - arg7: `(0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f, 0x661235a238B11191211fa95D4Dd9E423d521E0Be, 0x88FF1e5b602916615391F55854588EFcBB7663f0, 0x5d66C1782664115999C47c9fA5cd031f495D3e4F, 0xA8B389A82e088b164cD03230e900980CcED34d29, 0x57b4C29DAee99a28E6E86778b499361294c134eA, 0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f)`
  - arg8: `57073 [5.707e4]`
  - arg9: `0x95703e0982140D16f8ebA6d158FccEde42f04a4C`
- storage: 19 distinct slots written, 2 net-changed:
  - `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`: `0x000000000000000000000000670b850a235a6fa98cd7a195eb139d0277e471fa` -> `0x000000000000000000000000ade27248542c0f3e89b49e4eb76155e267f14377`
  - `0x99f45962df4bc30de8d4c3c6d1ffc0f100edce16e80c7a5768b6d55ca463ff42`: `0x0000000000000000000000001951828ce913dc4383a8a1695695d537a11d896a` -> `0x0000000000000000000000002d91e6f2bcf6cd1df90e1faf9714e18705ea331f`

**OptimismPortal2** `0x5d66C1782664115999C47c9fA5cd031f495D3e4F` -> impl `0xb20B23af6071405C37dDDA0C0640e8eBb7899645` via ProxyAdmin/AddressManager `0xd56045e68956fce2576e680c95a4750cf8241f79`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address,address,address)`
  - arg0: `0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364`
  - arg1: `0xEe018bAf058227872540AC60eFbd38b023d9dAe2`
  - arg2: `0xbd4AbB321138e8Eddc399cE64E66451294325a14`
- storage: 5 distinct slots written, 1 net-changed:
  - `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`: `0x0000000000000000000000001005217ad392dc64cef501fa1777a27d42166748` -> `0x000000000000000000000000b20b23af6071405c37ddda0c0640e8ebb7899645`

**ETHLockbox** `0xbd4AbB321138e8Eddc399cE64E66451294325a14` -> impl `0xDF75E6b07E98873E36BA5c05508F80c1454e0aFe` via ProxyAdmin/AddressManager `0xd56045e68956fce2576e680c95a4750cf8241f79`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address,address[])`
  - arg0: `0x95703e0982140D16f8ebA6d158FccEde42f04a4C`
  - arg1: `[0x5d66C1782664115999C47c9fA5cd031f495D3e4F]`
- storage: 4 distinct slots written, 2 net-changed:
  - `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`: `0x000000000000000000000000b3a24db07038b51962026329b62e7a965d56a6ad` -> `0x000000000000000000000000df75e6b07e98873e36ba5c05508f80c1454e0afe`
  - `0x0000000000000000000000000000000000000000000000000000000000000003`: `0x0000000000000000000000000000000000000000000000000000000000000000` -> `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c`

**L1CrossDomainMessenger** `0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f` -> impl `0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448` via ProxyAdmin/AddressManager `AddressManager 0x9b7c9bbd6d540a8a4dedd935819fc4408ba71153`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 20 zeroed>)`
- `initialize(address,address)`
  - arg0: `0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364`
  - arg1: `0x5d66C1782664115999C47c9fA5cd031f495D3e4F`
- storage: 4 distinct slots written, 0 net-changed (all rewritten with identical values)

**L1StandardBridge** `0x88FF1e5b602916615391F55854588EFcBB7663f0` -> impl `0xB37a11AadF167B2F0b8dD85372De4bC66CD4A891` via ProxyAdmin/AddressManager `0xd56045e68956fce2576e680c95a4750cf8241f79`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address,address)`
  - arg0: `0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f`
  - arg1: `0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364`
- storage: 5 distinct slots written, 0 net-changed (all rewritten with identical values)

**L1ERC721Bridge** `0x661235a238B11191211fa95D4Dd9E423d521E0Be` -> impl `0x9F164f1d02A81e06D639E55F65a87f0070E3Cb2e` via ProxyAdmin/AddressManager `0xd56045e68956fce2576e680c95a4750cf8241f79`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address,address)`
  - arg0: `0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f`
  - arg1: `0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364`
- storage: 5 distinct slots written, 0 net-changed (all rewritten with identical values)

**OptimismMintableERC20Factory** `0xA8B389A82e088b164cD03230e900980CcED34d29` -> impl `0xaAbEA75Da509fA518Fd8a91Eae4BE5813B829b12` via ProxyAdmin/AddressManager `0xd56045e68956fce2576e680c95a4750cf8241f79`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address)`
  - arg0: `0x88FF1e5b602916615391F55854588EFcBB7663f0`
- storage: 3 distinct slots written, 0 net-changed (all rewritten with identical values)

**DisputeGameFactory** `0x10d7B35078d3baabB96Dd45a9143B94be65b12CD` -> impl `0x72B971717E088B59F26d4236BE222ADB6ACD393b` via ProxyAdmin/AddressManager `0xd56045e68956fce2576e680c95a4750cf8241f79`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address)`
  - arg0: `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`
- storage: 30 distinct slots written, 1 net-changed:
  - `0x42faa4569684ce9de6c0b2f969e15e6e43a595549e706530ccb0e79bc8aaa794`: `0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df` -> `0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9`

**DelayedWETH** `0x57b4C29DAee99a28E6E86778b499361294c134eA` -> impl `0xF024e96317907C3b8d8CB346B9FD9034c8640e15` via ProxyAdmin/AddressManager `0xd56045e68956fce2576e680c95a4750cf8241f79`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address)`
  - arg0: `0xbd4AbB321138e8Eddc399cE64E66451294325a14`
- storage: 3 distinct slots written, 2 net-changed:
  - `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`: `0x000000000000000000000000e440cc08a71694c8229323803f59024e3144630e` -> `0x000000000000000000000000f024e96317907c3b8d8cb346b9fd9034c8640e15`
  - `0x0000000000000000000000000000000000000000000000000000000000000005`: `0x0000000000000000000000000000000000000000000000000000000000000000` -> `0x000000000000000000000000bd4abb321138e8eddc399ce64e66451294325a14`

**AnchorStateRegistry** `0xEe018bAf058227872540AC60eFbd38b023d9dAe2` -> impl `0x2b27299C577d4720100e2735b652444DcEa652D0` via ProxyAdmin/AddressManager `0xd56045e68956fce2576e680c95a4750cf8241f79`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address,address,(bytes32,uint256),uint32)`
  - arg0: `0xbd4AbB321138e8Eddc399cE64E66451294325a14`
  - arg1: `0x10d7B35078d3baabB96Dd45a9143B94be65b12CD`
  - arg2: `(0x25b22a0c711fa1d01b3cdb95fb98c0e7ff003b00909bfe8fade3507a6e62d44e, 1788848282 [1.788e9])`
  - arg3: `9`
- storage: 6 distinct slots written, 2 net-changed:
  - `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`: `0x0000000000000000000000008f40cc98d694ab986f026c5383a181fcc9b6b281` -> `0x0000000000000000000000002b27299c577d4720100e2735b652444dcea652d0`
  - `0x0000000000000000000000000000000000000000000000000000000000000006`: `0x000000000000000000000000000000000000000000000000688271ab00000009` -> `0xbd4abb321138e8eddc399ce64e66451294325a1400000000688271ab00000009`


### Soneium

**SystemConfig** `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3` -> impl `0xADe27248542c0F3E89b49e4eB76155e267F14377` via ProxyAdmin/AddressManager `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address,uint32,uint32,bytes32,uint64,address,(uint32,uint8,uint8,uint32,uint32,uint128),(address,address,address,address,address,address,address),uint256,address)`
  - arg0: `0x509182eC226b3B71D36A3255A80EF0b1A9D43033`
  - arg1: `9736`
  - arg2: `1540079 [1.54e6]`
  - arg3: `0x0000000000000000000000006776be80dbada6a02b5f2095cf13734ac303b8d1`
  - arg4: `40000000 [4e7]`
  - arg5: `0x7c2Bd59ee2a2C7391c9A240132f26071e9546262`
  - arg6: `(20000000 [2e7], 10, 8, 1000000000 [1e9], 1000000 [1e6], 340282366920938463463374607431768211455 [3.402e38])`
  - arg7: `(0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f, 0x5933e323bE8896DfaCd1cD671442F27dAA10a053, 0xeb9bf100225c214Efc3E7C651ebbaDcF85177607, 0x88e529A6ccd302c948689Cd5156C83D4614FAE92, 0xc1047e30EFC9E172cFe7aa0219895B6a43fC415F, 0x18fBb58C366e21F395DdEc7cBa0510a2D9116B47, 0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f)`
  - arg8: `1868`
  - arg9: `0x95703e0982140D16f8ebA6d158FccEde42f04a4C`
- storage: 19 distinct slots written, 2 net-changed:
  - `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`: `0x000000000000000000000000670b850a235a6fa98cd7a195eb139d0277e471fa` -> `0x000000000000000000000000ade27248542c0f3e89b49e4eb76155e267f14377`
  - `0x99f45962df4bc30de8d4c3c6d1ffc0f100edce16e80c7a5768b6d55ca463ff42`: `0x0000000000000000000000001951828ce913dc4383a8a1695695d537a11d896a` -> `0x0000000000000000000000002d91e6f2bcf6cd1df90e1faf9714e18705ea331f`

**OptimismPortal2** `0x88e529A6ccd302c948689Cd5156C83D4614FAE92` -> impl `0xb20B23af6071405C37dDDA0C0640e8eBb7899645` via ProxyAdmin/AddressManager `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address,address,address)`
  - arg0: `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3`
  - arg1: `0x4890928941e62e273dA359374b105F803329F473`
  - arg2: `0x67B4de6FfA66EF201Ea6099A89cA397D56622E31`
- storage: 5 distinct slots written, 1 net-changed:
  - `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`: `0x0000000000000000000000001005217ad392dc64cef501fa1777a27d42166748` -> `0x000000000000000000000000b20b23af6071405c37ddda0c0640e8ebb7899645`

**ETHLockbox** `0x67B4de6FfA66EF201Ea6099A89cA397D56622E31` -> impl `0xDF75E6b07E98873E36BA5c05508F80c1454e0aFe` via ProxyAdmin/AddressManager `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address,address[])`
  - arg0: `0x95703e0982140D16f8ebA6d158FccEde42f04a4C`
  - arg1: `[0x88e529A6ccd302c948689Cd5156C83D4614FAE92]`
- storage: 4 distinct slots written, 2 net-changed:
  - `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`: `0x000000000000000000000000b3a24db07038b51962026329b62e7a965d56a6ad` -> `0x000000000000000000000000df75e6b07e98873e36ba5c05508f80c1454e0afe`
  - `0x0000000000000000000000000000000000000000000000000000000000000003`: `0x0000000000000000000000000000000000000000000000000000000000000000` -> `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c`

**L1CrossDomainMessenger** `0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f` -> impl `0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448` via ProxyAdmin/AddressManager `AddressManager 0xb24bfeece1b3b7a44559f4cbc21bed312b130b70`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 20 zeroed>)`
- `initialize(address,address)`
  - arg0: `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3`
  - arg1: `0x88e529A6ccd302c948689Cd5156C83D4614FAE92`
- storage: 4 distinct slots written, 0 net-changed (all rewritten with identical values)

**L1StandardBridge** `0xeb9bf100225c214Efc3E7C651ebbaDcF85177607` -> impl `0xB37a11AadF167B2F0b8dD85372De4bC66CD4A891` via ProxyAdmin/AddressManager `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address,address)`
  - arg0: `0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f`
  - arg1: `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3`
- storage: 5 distinct slots written, 0 net-changed (all rewritten with identical values)

**L1ERC721Bridge** `0x5933e323bE8896DfaCd1cD671442F27dAA10a053` -> impl `0x9F164f1d02A81e06D639E55F65a87f0070E3Cb2e` via ProxyAdmin/AddressManager `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address,address)`
  - arg0: `0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f`
  - arg1: `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3`
- storage: 5 distinct slots written, 0 net-changed (all rewritten with identical values)

**OptimismMintableERC20Factory** `0xc1047e30EFC9E172cFe7aa0219895B6a43fC415F` -> impl `0xaAbEA75Da509fA518Fd8a91Eae4BE5813B829b12` via ProxyAdmin/AddressManager `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address)`
  - arg0: `0xeb9bf100225c214Efc3E7C651ebbaDcF85177607`
- storage: 3 distinct slots written, 0 net-changed (all rewritten with identical values)

**DisputeGameFactory** `0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0` -> impl `0x72B971717E088B59F26d4236BE222ADB6ACD393b` via ProxyAdmin/AddressManager `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address)`
  - arg0: `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`
- storage: 26 distinct slots written, 0 net-changed (all rewritten with identical values)

**DelayedWETH** `0x18fBb58C366e21F395DdEc7cBa0510a2D9116B47` -> impl `0xF024e96317907C3b8d8CB346B9FD9034c8640e15` via ProxyAdmin/AddressManager `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address)`
  - arg0: `0x67B4de6FfA66EF201Ea6099A89cA397D56622E31`
- storage: 3 distinct slots written, 2 net-changed:
  - `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`: `0x000000000000000000000000e440cc08a71694c8229323803f59024e3144630e` -> `0x000000000000000000000000f024e96317907c3b8d8cb346b9fd9034c8640e15`
  - `0x0000000000000000000000000000000000000000000000000000000000000005`: `0x0000000000000000000000000000000000000000000000000000000000000000` -> `0x00000000000000000000000067b4de6ffa66ef201ea6099a89ca397d56622e31`

**AnchorStateRegistry** `0x4890928941e62e273dA359374b105F803329F473` -> impl `0x2b27299C577d4720100e2735b652444DcEa652D0` via ProxyAdmin/AddressManager `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address,address,(bytes32,uint256),uint32)`
  - arg0: `0x67B4de6FfA66EF201Ea6099A89cA397D56622E31`
  - arg1: `0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0`
  - arg2: `(0x08a53686fd0b1671ff7b89c3a994582503f15f7be00f0f2e7c9f0d3b187ab124, 1788848425 [1.788e9])`
  - arg3: `5`
- storage: 6 distinct slots written, 2 net-changed:
  - `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`: `0x0000000000000000000000008f40cc98d694ab986f026c5383a181fcc9b6b281` -> `0x0000000000000000000000002b27299c577d4720100e2735b652444dcea652d0`
  - `0x0000000000000000000000000000000000000000000000000000000000000006`: `0x000000000000000000000000000000000000000000000000688274ff00000005` -> `0x67b4de6ffa66ef201ea6099a89ca397d56622e3100000000688274ff00000005`


### Unichain

**SystemConfig** `0xc407398d063f942feBbcC6F80a156b47F3f1BDA6` -> impl `0xADe27248542c0F3E89b49e4eB76155e267F14377` via ProxyAdmin/AddressManager `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address,uint32,uint32,bytes32,uint64,address,(uint32,uint8,uint8,uint32,uint32,uint128),(address,address,address,address,address,address,address),uint256,address)`
  - arg0: `0x847B5c174615B1B7fDF770882256e2D3E95b9D92`
  - arg1: `2000`
  - arg2: `900000 [9e5]`
  - arg3: `0x0000000000000000000000009ef649e8746cc47a17708a5e86b2d66c7f6c00d1`
  - arg4: `60000000 [6e7]`
  - arg5: `0xFaACA0A10e4a23C5E01485DE07767547d4D8056D`
  - arg6: `(20000000 [2e7], 10, 8, 1000000000 [1e9], 1000000 [1e6], 340282366920938463463374607431768211455 [3.402e38])`
  - arg7: `(0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6, 0xD04D0D87E0bd4D2E50286760a3EF323FeA6849Cf, 0x81014F44b0a345033bB2b3B21C7a1A308B35fEeA, 0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2, 0xA2B597EaeAcb6F627e088cbEaD319e934ED5edad, 0x74ad145aC900F1DD5551F0C9E143314DC4022FCf, 0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f)`
  - arg8: `130`
  - arg9: `0x95703e0982140D16f8ebA6d158FccEde42f04a4C`
- storage: 19 distinct slots written, 2 net-changed:
  - `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`: `0x000000000000000000000000670b850a235a6fa98cd7a195eb139d0277e471fa` -> `0x000000000000000000000000ade27248542c0f3e89b49e4eb76155e267f14377`
  - `0x99f45962df4bc30de8d4c3c6d1ffc0f100edce16e80c7a5768b6d55ca463ff42`: `0x0000000000000000000000001951828ce913dc4383a8a1695695d537a11d896a` -> `0x0000000000000000000000002d91e6f2bcf6cd1df90e1faf9714e18705ea331f`

**OptimismPortal2** `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` -> impl `0xb20B23af6071405C37dDDA0C0640e8eBb7899645` via ProxyAdmin/AddressManager `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address,address,address)`
  - arg0: `0xc407398d063f942feBbcC6F80a156b47F3f1BDA6`
  - arg1: `0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9`
  - arg2: `0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5`
- storage: 5 distinct slots written, 1 net-changed:
  - `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`: `0x0000000000000000000000001005217ad392dc64cef501fa1777a27d42166748` -> `0x000000000000000000000000b20b23af6071405c37ddda0c0640e8ebb7899645`

**ETHLockbox** `0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5` -> impl `0xDF75E6b07E98873E36BA5c05508F80c1454e0aFe` via ProxyAdmin/AddressManager `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address,address[])`
  - arg0: `0x95703e0982140D16f8ebA6d158FccEde42f04a4C`
  - arg1: `[0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2]`
- storage: 4 distinct slots written, 2 net-changed:
  - `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`: `0x000000000000000000000000b3a24db07038b51962026329b62e7a965d56a6ad` -> `0x000000000000000000000000df75e6b07e98873e36ba5c05508f80c1454e0afe`
  - `0x0000000000000000000000000000000000000000000000000000000000000003`: `0x0000000000000000000000000000000000000000000000000000000000000000` -> `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c`

**L1CrossDomainMessenger** `0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6` -> impl `0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448` via ProxyAdmin/AddressManager `AddressManager 0x8098f676033a377b9defe302e9fe6877cd63d575`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 20 zeroed>)`
- `initialize(address,address)`
  - arg0: `0xc407398d063f942feBbcC6F80a156b47F3f1BDA6`
  - arg1: `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2`
- storage: 4 distinct slots written, 0 net-changed (all rewritten with identical values)

**L1StandardBridge** `0x81014F44b0a345033bB2b3B21C7a1A308B35fEeA` -> impl `0xB37a11AadF167B2F0b8dD85372De4bC66CD4A891` via ProxyAdmin/AddressManager `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address,address)`
  - arg0: `0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6`
  - arg1: `0xc407398d063f942feBbcC6F80a156b47F3f1BDA6`
- storage: 5 distinct slots written, 0 net-changed (all rewritten with identical values)

**L1ERC721Bridge** `0xD04D0D87E0bd4D2E50286760a3EF323FeA6849Cf` -> impl `0x9F164f1d02A81e06D639E55F65a87f0070E3Cb2e` via ProxyAdmin/AddressManager `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address,address)`
  - arg0: `0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6`
  - arg1: `0xc407398d063f942feBbcC6F80a156b47F3f1BDA6`
- storage: 5 distinct slots written, 0 net-changed (all rewritten with identical values)

**OptimismMintableERC20Factory** `0xA2B597EaeAcb6F627e088cbEaD319e934ED5edad` -> impl `0xaAbEA75Da509fA518Fd8a91Eae4BE5813B829b12` via ProxyAdmin/AddressManager `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address)`
  - arg0: `0x81014F44b0a345033bB2b3B21C7a1A308B35fEeA`
- storage: 3 distinct slots written, 0 net-changed (all rewritten with identical values)

**DisputeGameFactory** `0x2F12d621a16e2d3285929C9996f478508951dFe4` -> impl `0x72B971717E088B59F26d4236BE222ADB6ACD393b` via ProxyAdmin/AddressManager `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address)`
  - arg0: `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`
- storage: 30 distinct slots written, 1 net-changed:
  - `0x42faa4569684ce9de6c0b2f969e15e6e43a595549e706530ccb0e79bc8aaa794`: `0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df` -> `0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9`

**DelayedWETH** `0x74ad145aC900F1DD5551F0C9E143314DC4022FCf` -> impl `0xF024e96317907C3b8d8CB346B9FD9034c8640e15` via ProxyAdmin/AddressManager `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address)`
  - arg0: `0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5`
- storage: 3 distinct slots written, 2 net-changed:
  - `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`: `0x000000000000000000000000e440cc08a71694c8229323803f59024e3144630e` -> `0x000000000000000000000000f024e96317907c3b8d8cb346b9fd9034c8640e15`
  - `0x0000000000000000000000000000000000000000000000000000000000000005`: `0x0000000000000000000000000000000000000000000000000000000000000000` -> `0x00000000000000000000000008ba0023ed60c7bd040716dd13c45fa0062df5c5`

**AnchorStateRegistry** `0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9` -> impl `0x2b27299C577d4720100e2735b652444DcEa652D0` via ProxyAdmin/AddressManager `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4`
- StorageSetter write: `setBytes32(slot 0, <slot value with byte 0 zeroed>)`
- `initialize(address,address,(bytes32,uint256),uint32)`
  - arg0: `0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5`
  - arg1: `0x2F12d621a16e2d3285929C9996f478508951dFe4`
  - arg2: `(0xaf64a866304eb17696278d26290bb172aa941eac3370d9bc8bd313d492beb7d3, 1788848651 [1.788e9])`
  - arg3: `9`
- storage: 6 distinct slots written, 2 net-changed:
  - `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`: `0x0000000000000000000000008f40cc98d694ab986f026c5383a181fcc9b6b281` -> `0x0000000000000000000000002b27299c577d4720100e2735b652444dcea652d0`
  - `0x0000000000000000000000000000000000000000000000000000000000000006`: `0x0000000000000000000000000000000000000000000000006882777b00000009` -> `0x08ba0023ed60c7bd040716dd13c45fa0062df5c5000000006882777b00000009`

## 4. Slot-by-slot attribution (OP Mainnet shown; the other three chains have the identical slot set, verified programmatically)

`(xk)` = number of SSTOREs to the slot inside the tx. "same" = final value equals the N-1 value.

| Proxy | Slot | Meaning | Instruction that wrote it | Net change |
|---|---|---|---|---|
| Safe | 5 | Safe nonce | `execTransaction` | 48 -> 49 |
| SuperchainConfig | 0x3608...2bbc (x4) | EIP-1967 implementation | Utils.upgrade steps 1,4,5,7 | `0x5570b1f2...` -> `0xA303a644...` |
| SuperchainConfig | 0 (x4) | `_initialized`,`_initializing`,`guardian` | StorageSetter clear; `reinitializer` enter; `_setGuardian`; `reinitializer` exit | same (`guardian=0x09f7150D...`, `_initialized=2`) |
| SystemConfig | 0x3608...2bbc (x4) | implementation | Utils.upgrade | `0x670b850A...` -> `0xADe27248...` |
| SystemConfig | 0 (x3) | `_initialized`,`_initializing` | StorageSetter clear; modifier enter/exit | same (3) |
| SystemConfig | 0x33 (x2) | `_owner` | `__Ownable_init()` (owner := ProxyAdmin), `transferOwnership(_owner)` | same (`0x847B5c17...`); two `OwnershipTransferred` logs |
| SystemConfig | 0x67 | `batcherHash` | `_setBatcherHash` | same; emits `ConfigUpdate(0, BATCHER)` |
| SystemConfig | 0x66, 0x68 (x2) | `scalar`; `gasLimit`/`basefeeScalar`/`blobbasefeeScalar` | `_setGasConfigEcotone`, `_setGasLimit` | same; emits `ConfigUpdate(0, FEE_SCALARS)` and `ConfigUpdate(0, GAS_LIMIT)` |
| SystemConfig | 0x65a7ed54...1c08 | UNSAFE_BLOCK_SIGNER_SLOT | `Storage.setAddress` | same |
| SystemConfig | 0x383f2918...0636, 0x46adcbeb...d5a7, 0x9904ba90...6376, 0x4b6c74f9...19ac, 0xa04c5bb9...320c, 0x51547f31...58ff | L1xDM, L1ERC721Bridge, L1StandardBridge, OptimismPortal, OptimismMintableERC20Factory, DelayedWETH address slots | `Storage.setAddress` x6 | same |
| SystemConfig | 0x99f45962...ff42 | OPCM_SLOT (`lastUsedOPCM`) | `Storage.setAddress(OPCM_SLOT, opcmV2)` | **`0x1951828C...` (8.0.1) -> `0x2d91e6F2...` (9.0.3)** |
| SystemConfig | 0x65; 0x71ac1282...c597 | `overhead`; LEGACY_BATCH_INBOX_SLOT | `overhead = 0`; `Storage.setAddress(LEGACY_BATCH_INBOX_SLOT, 0)` | same (both already 0) |
| SystemConfig | 0x69; 0x6b; 0x6c | `_resourceConfig`; `l2ChainId`; `superchainConfig` (+`minBaseFee` packed) | `_setResourceConfig`; assignments | same |
| OptimismPortal2 | 0x3608...2bbc (x4) | implementation | Utils.upgrade | `0x1005217a...` -> `0xb20B23af...` |
| OptimismPortal2 | 0 (x3); 0x37; 0x3e; 0x3f | init bytes; `systemConfig`; `anchorStateRegistry`; `ethLockbox` | StorageSetter + `initialize` | same |
| ETHLockbox | 0x3608...2bbc (x4) | implementation | Utils.upgrade | `0xb3A24DB0...` -> `0xDF75E6b0...` |
| ETHLockbox | 0 (x3) | init bytes (+ legacy `systemConfig` at offset 2, now `spacer_0_2_20`) | StorageSetter + modifier | same; the stale SystemConfig address stays in the spacer and is never read by v2.0.0 |
| ETHLockbox | 3 | `superchainConfig` (NEW slot) | `superchainConfig = _superchainConfig` | **0 -> `0x95703e09...`** |
| ETHLockbox | 0xe94ce3e9...2398 | `authorizedPortals[portal]` | `_authorizePortal` | same (true); emits `PortalAuthorized` |
| AddressManager | 0x51521693...385e (x4) | `addresses[keccak("OVM_L1CrossDomainMessenger")]` | ProxyAdmin.upgrade for RESOLVED type | `0x59D49753...` -> `0x7d4Ec7fB...` |
| L1CrossDomainMessenger | 0 (x3); 0xfc; 0xfe; 0xcf | init byte at offset 20; `portal`; `systemConfig`; `otherMessenger` | StorageSetter + `initialize` / `__CrossDomainMessenger_init` | same (`xDomainMsgSender` slot 0xcc not written: already non-zero) |
| L1StandardBridge | 0x3608...2bbc (x4); 0 (x3); 3; 4; 0x34 | impl (via `setStorage`); init; `messenger`; `otherBridge`; `systemConfig` | Utils.upgrade + `initialize` | same (impl `0xB37a11Aa...` unchanged) |
| L1ERC721Bridge | 0x3608...2bbc (x4); 0 (x3); 1; 2; 0x33 | impl; init; `messenger`; `otherBridge`; `systemConfig` | same pattern | same (impl `0x9F164f1d...` unchanged) |
| OptimismMintableERC20Factory | 0x3608...2bbc (x4); 0 (x4); 1 | impl; init; `bridge` | same pattern | same (impl `0xaAbEA75D...` unchanged) |
| DisputeGameFactory | 0x3608...2bbc (x4); 0 (x3); 0x33 (x2) | impl; init; `_owner` | Utils.upgrade; `__Ownable_init` + `_transferOwnership(Safe)` | same (impl `0x72B97171...` unchanged; owner = Safe) |
| DisputeGameFactory | 27 mapping/bytes slots (23 on Soneium) | `gameImpls[t]`, `initBonds[t]`, `gameArgs[t]` for t in {0,1,8,5,9,10,4} | 7 x `setImplementation` + 7 x `setInitBond` | 3 changed on OP (type-5 args: 2 words; type-9 args word 0), 1 on Ink and Unichain (type-9 args word 0), 0 on Soneium |
| DelayedWETH | 0x3608...2bbc (x4) | implementation | Utils.upgrade | `0xE440CC08...` -> `0xF024e963...` |
| DelayedWETH | 0 (x3) | init bytes | StorageSetter + modifier | same |
| DelayedWETH | 5 | `ethLockbox` (NEW slot) | `ethLockbox = _ethLockbox` | **0 -> chain lockbox**; legacy slot 4 (`systemConfig`, now `spacer_4_0_20`) not written and keeps the SystemConfig address |
| AnchorStateRegistry | 0x3608...2bbc (x4) | implementation | Utils.upgrade | `0x8F40Cc98...` -> `0x2b27299C...` |
| AnchorStateRegistry | 0 (x3) | init bytes (+ legacy `systemConfig` at offset 2, now spacer) | StorageSetter + modifier | same; stale SystemConfig address stays in the spacer |
| AnchorStateRegistry | 1; 3; 4 | `disputeGameFactory`; `startingAnchorRoot.root`; `.l2SequenceNumber` | `initialize` | same (`rootChanged == false`, so `anchorGame` slot 2 is not touched) |
| AnchorStateRegistry | 6 | `respectedGameType` (4 bytes) + `retirementTimestamp` (8) + `ethLockbox` (20, NEW, offset 12) | `ethLockbox = ...`, `respectedGameType = ...` | **upper 20 bytes 0 -> chain lockbox**; game type and retirement timestamp unchanged (`retirementTimestamp != 0` so it is not reset) |

Totals: 339 distinct slots written over 46 accounts; net-changed slots per chain = 2 (SystemConfig) + 1 (Portal) + 2 (Lockbox) + 1 (AddressManager) + 2 (DelayedWETH) + 2 (ASR) + DGF (3/1/0/1), plus 1 for SuperchainConfig and 1 for the Safe nonce. Every written slot is attributed above; there is no write outside the proxies being upgraded, their AddressManagers and the Safe.

## 5. DisputeGameFactory configuration writes (per chain, N-1 -> N)

Input order is fixed by `VALID_GAME_TYPES` (`OPContractsManagerV2.sol:122`): CANNON(0), PERMISSIONED_CANNON(1), CANNON_KONA(8), SUPER_PERMISSIONED(5), SUPER_CANNON_KONA(9), ZK_DISPUTE_GAME(10); then SUPER_CANNON(4) is cleared unconditionally (line 995-996). Game args are built by `Utils.makeGameArgs` (lines 445-509); for super games the chain id word is 0.

| Chain | Type | impl N-1 | bond N-1 | gameArgs N-1 | impl N | bond N | gameArgs N |
|---|---|---|---|---|---|---|---|
| OP | 5 | `0x5C3eb47cB0174aea522a2a9Ae79487139A53D691` | 0 | `0x23b2c62946350f4246f9f9d027e071f0264fd113473300df21d047806a082244b417f96b32f13a33` | `0x5C3eb47cB0174aea522a2a9Ae79487139A53D691` | 0 | `0x23b2c62946350f4246f9f9d027e071f0264fd113c27ba3e0fc01567a5e57ae0c391aa98cecba5be0` |
| OP | 9 | `0x19AF533Cc2A2A55786DCB8672aA5717e64213208` | 80000000000000000 | `0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1dfacc005dcd857b401e4732e6f7837135a22825cfa23b2c62946350f4246f9f9d027e071f0264fd1131b6dbf05eaf22d4e70dc993e8a19dd9f3dcb31620000000000000000000000000000000000000000000000000000000000000000` | `0x19AF533Cc2A2A55786DCB8672aA5717e64213208` | 80000000000000000 | `0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9acc005dcd857b401e4732e6f7837135a22825cfa23b2c62946350f4246f9f9d027e071f0264fd1131b6dbf05eaf22d4e70dc993e8a19dd9f3dcb31620000000000000000000000000000000000000000000000000000000000000000` |
| Ink | 5 | `0x5C3eb47cB0174aea522a2a9Ae79487139A53D691` | 0 | `0xee018baf058227872540ac60efbd38b023d9dae23832bfbef03173e4c49a00ec0dd178817a02d177` | `0x5C3eb47cB0174aea522a2a9Ae79487139A53D691` | 0 | `0xee018baf058227872540ac60efbd38b023d9dae23832bfbef03173e4c49a00ec0dd178817a02d177` |
| Ink | 9 | `0x19AF533Cc2A2A55786DCB8672aA5717e64213208` | 80000000000000000 | `0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1dfacc005dcd857b401e4732e6f7837135a22825cfaee018baf058227872540ac60efbd38b023d9dae257b4c29daee99a28e6e86778b499361294c134ea0000000000000000000000000000000000000000000000000000000000000000` | `0x19AF533Cc2A2A55786DCB8672aA5717e64213208` | 80000000000000000 | `0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9acc005dcd857b401e4732e6f7837135a22825cfaee018baf058227872540ac60efbd38b023d9dae257b4c29daee99a28e6e86778b499361294c134ea0000000000000000000000000000000000000000000000000000000000000000` |
| Soneium | 5 | `0x5C3eb47cB0174aea522a2a9Ae79487139A53D691` | 0 | `0x4890928941e62e273da359374b105f803329f473400c164c4a8ca84385b70eed6eb03ea847c8e1b8` | `0x5C3eb47cB0174aea522a2a9Ae79487139A53D691` | 0 | `0x4890928941e62e273da359374b105f803329f473400c164c4a8ca84385b70eed6eb03ea847c8e1b8` |
| Unichain | 5 | `0x5C3eb47cB0174aea522a2a9Ae79487139A53D691` | 0 | `0x27cf508e4e3aa8d30b3226ac3b5ea0e8bcacaff986b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | `0x5C3eb47cB0174aea522a2a9Ae79487139A53D691` | 0 | `0x27cf508e4e3aa8d30b3226ac3b5ea0e8bcacaff986b392ca30ad7453c8d88b56eb5a04fd0e2175b7` |
| Unichain | 9 | `0x19AF533Cc2A2A55786DCB8672aA5717e64213208` | 80000000000000000 | `0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1dfacc005dcd857b401e4732e6f7837135a22825cfa27cf508e4e3aa8d30b3226ac3b5ea0e8bcacaff974ad145ac900f1dd5551f0c9e143314dc4022fcf0000000000000000000000000000000000000000000000000000000000000000` | `0x19AF533Cc2A2A55786DCB8672aA5717e64213208` | 80000000000000000 | `0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9acc005dcd857b401e4732e6f7837135a22825cfa27cf508e4e3aa8d30b3226ac3b5ea0e8bcacaff974ad145ac900f1dd5551f0c9e143314dc4022fcf0000000000000000000000000000000000000000000000000000000000000000` |

All other types written by the loop (0, 1, 8, 10, 4; and 9 on Soneium) were already unset at N-1 and stay unset: implementation 0, bond 0, empty args. Types the OPCM does not manage (2, 3, 6, 7, 11, 12 probed) are unset on all four factories.

Decoded changes:
- SUPER_CANNON_KONA (9) on OP, Ink, Unichain: `absolutePrestate` `0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df` -> `0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9`; vm `0xaCc005DC...` (MIPS64), the chain's own AnchorStateRegistry and DelayedWETH, chain id word 0, bond 0.08 ETH: all unchanged.
- SUPER_PERMISSIONED (5) on OP Mainnet only: `proposer` `0x473300df21D047806A082244b417f96b32f13A33` -> `0xc27ba3E0Fc01567a5E57Ae0c391AA98cECBA5bE0` (an EOA, nonce 1 at N-1 and 11 at 26433900). Ink/Soneium/Unichain proposers unchanged. This is input chosen by the ProxyAdmin owner, not derived on chain.
- Game implementations are unchanged on every chain, so games created before and after U21 run the same code; they differ only in prestate (type 9) and they all read the upgraded ASR v4.0.0 / DelayedWETH v2.0.0 through the same proxies.

## 6. "Should have changed but did not" and "changed unexpectedly"

- Changed unexpectedly: nothing. The only value-level surprise relative to a pure "same config, new code" upgrade is the OP Mainnet type-5 proposer rotation (section 5), which is explicit in the tx input.
- Legacy `systemConfig` words left in place: ETHLockbox slot 0 bytes 2-21, AnchorStateRegistry slot 0 bytes 2-21, DelayedWETH slot 4. In v9 these are private spacers with no reader (`grep` shows no use). They are stale-but-correct pointers to the same chain's SystemConfig and are harmless; they would only matter to a later implementation that re-labels the spacer.
- `SystemConfig.START_BLOCK_SLOT` not rewritten (`_setStartBlock` only writes when zero): correct, start blocks preserved (OP 17422444, Ink 21344310, Soneium 21314185, Unichain 21116363).
- `AnchorStateRegistry.retirementTimestamp` not bumped (1753379243 OP/Ink, 1753380095 Soneium, 1753380731 Unichain): by design (`AnchorStateRegistry.sol:124-132`), so no game created before U21 was retired by it - see PRIM-0101/0102.
- `L1CrossDomainMessenger.xDomainMsgSender` not rewritten: correct (only set when zero).
- SystemConfig fields that `initialize` does not take (EIP-1559 params, operator fee, `minBaseFee`, `daFootprintGasScalar`) are untouched storage and no `ConfigUpdate` is emitted for them; the three re-emitted `ConfigUpdate` events (batcher, fee scalars, gas limit) carry the values already in force.
- Pause state: `SuperchainConfig.expiration(x) == 0` at N-1 and after for address(0) and for every portal and lockbox of the four chains, so the identifier consolidation onto the lockbox could not drop an active pause.

