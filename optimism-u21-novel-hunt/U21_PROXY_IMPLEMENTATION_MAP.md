# U21 proxy / implementation map (LANE 01)

Source of truth: exact mainnet transition block N-1 = 26430858 (`l1pre`) -> block N = 26430859 (`l1n`, :8547), cross-checked at 26433900 (`l1`).
Upgrade tx `0x024770b5fba87683ee1466562eefb1bcb408c29c764e24abd07c7d4050a82a99` (index 358 in block N, status 1, gasUsed 6,534,939, 307 logs).

How this was built: (1) the tx input was decoded with the v9 ABIs; (2) the tx was replayed in a forge fork of `l1pre` with `vm.startStateDiffRecording()` (`test/poc/lane01/Lane01_Replay.t.sol`), giving 561 storage writes over 46 accounts / 339 distinct slots; (3) the replay end-state of all 339 slots was compared with `cast storage` on `l1n` (0 mismatches) and on `l1` (0 differences N -> 26433900); (4) `version()`, EIP-1967 implementation/admin slots and AddressManager entries were read on all three forks; (5) implementation runtime bytecode was compared with the local v9 build (`forge-artifacts/`, immutables masked).

Evidence files: `evidence/lane01-u21-replay-trace.txt` (full call trace), `evidence/lane01-u21-replay-storage-writes.csv`, `evidence/lane01-net-storage-writes.json`, `evidence/lane01-slotcheck-pre-replay-N-post.json`, `evidence/lane01-upgrades-decoded.json`, `evidence/lane01-u21-logs-decoded.txt`.

## 1. Call structure

```
EOA 0xE10A25d4ec17A94CA455F3cDA84137189843B4f2 (nonce 45)
 -> Safe 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A (ProxyAdminOwner, Safe nonce 48 -> 49)
      execTransaction(to=0x93dc480940585D9961bfcEab58124fFD3d60f76a, value=0, operation=1 DELEGATECALL,
                      safeTxGas=0, baseGas=0, gasPrice=0, gasToken=0, refundReceiver=0,
                      signatures = two pre-approved-hash signatures (v=1): 0x847B5c174615B1B7fDF770882256e2D3E95b9D92, 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03)
   -> [DELEGATECALL] Multicall3DelegateCall.aggregate3(5 calls, allowFailure=false each)
      0: [DELEGATECALL] OPCMv2 0x2d91e6F2....upgradeSuperchain((superchainConfig=0x95703e09..., extraInstructions=[]))
      1: [DELEGATECALL] OPCMv2.upgrade((systemConfig=0x229047fe... OP Mainnet 10, ...))
      2: [DELEGATECALL] OPCMv2.upgrade((systemConfig=0x62C0a111... Ink 57073, ...))
      3: [DELEGATECALL] OPCMv2.upgrade((systemConfig=0x7A8Ed66B... Soneium 1868, ...))
      4: [DELEGATECALL] OPCMv2.upgrade((systemConfig=0xc407398d... Unichain 130, ...))
```

Because every hop is a DELEGATECALL, `address(this)` inside the OPCM is the Safe, i.e. the owner of all five ProxyAdmins involved. Each per-proxy upgrade is `OPCMv2._upgrade` -> DELEGATECALL `OPContractsManagerUtils.upgrade` (0xE1EA0F70fDA205fDfeEc770A259e4C34C0f7c4c6), `src/L1/opcm/OPContractsManagerUtils.sol:312-387`.

### Why every proxy shows `Upgraded -> 0x2476c911... -> impl` twice

`0x2476c911E6D4D9411E677D8Faf15a64ac1fDEEe8` is `StorageSetter` v1.2.2 (runtime bytecode identical to the v9 build), taken from `implementations().storageSetterImpl`. `OPContractsManagerUtils.upgrade` does, per proxy:

| # | Instruction (Utils.sol line) | Log | Storage effect |
|---|---|---|---|
| 1 | `_proxyAdmin.upgrade(target, storageSetter)` (354) | `Upgraded(0x2476c911...)` #1 | impl slot := StorageSetter |
| 2 | `getBytes32(OZ_V5_INITIALIZABLE_SLOT)` must be 0 (359-364) | - | read only |
| 3 | `setBytes32(_slot, current & ~(0xff << 8*offset))` (367-369) | - | clears the one-byte `_initialized` (slot 0 offset 0; L1CrossDomainMessenger slot 0 offset 20) |
| 4 | `_proxyAdmin.upgradeAndCall(target, impl, initData)` (372) | `Upgraded(impl)` #1, then the initializer's own events, `Initialized(initVersion)` | impl slot := real impl; initializer writes |
| 5 | `_proxyAdmin.upgrade(target, storageSetter)` (379) | `Upgraded(0x2476c911...)` #2 | impl slot := StorageSetter (only to read the OZ v5 ERC-7201 slot written by the initializer) |
| 6 | `getBytes32(OZ_V5_INITIALIZABLE_SLOT)` must be 0 (380-382) | - | read only |
| 7 | `_proxyAdmin.upgrade(target, impl)` (386) | `Upgraded(impl)` #2 | impl slot := real impl (no initializer) |

So the impl slot of each ERC-1967 proxy is written 4 times in the tx (verified: `(x4)` on every impl slot in `lane01-net-storage-writes.json`). `L1ChugSplashProxy` (L1StandardBridge) goes through `setStorage` and emits no `Upgraded` event (only `Initialized(3)`); `ResolvedDelegateProxy` (L1CrossDomainMessenger) is retargeted via `AddressManager.setAddress("OVM_L1CrossDomainMessenger", ...)`, hence 4 `AddressSet` events per chain and no `Upgraded`. The StorageSetter is only ever the implementation inside this atomic tx; at block N no touched proxy points at it (checked for all 41).

## 2. Proxies touched (41) - pre impl at N-1, post impl at N (identical at 26433900)


### Superchain

| Contract | Proxy | Proxy type | Admin (EIP-1967 admin slot / AddressManager) | Impl @ N-1 | Impl @ N | Version N-1 -> N | Impl changed |
|---|---|---|---|---|---|---|---|
| SuperchainConfig | `0x95703e0982140D16f8ebA6d158FccEde42f04a4C` | Proxy (ERC-1967) | `0x543ba4aadbab8f9025686bd03993043599c6fb04` | `0x5570b1f2b97b1e35b5c6f9ee76f6cf02c9917504` | `0xa303a644cfbc0c34f6a9dbeafdeba4c967ea01e7` | "2.4.3" -> "2.5.0" | YES |

### OP Mainnet

| Contract | Proxy | Proxy type | Admin (EIP-1967 admin slot / AddressManager) | Impl @ N-1 | Impl @ N | Version N-1 -> N | Impl changed |
|---|---|---|---|---|---|---|---|
| SystemConfig | `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` | Proxy (ERC-1967) | `0x543ba4aadbab8f9025686bd03993043599c6fb04` | `0x670b850a235a6fa98cd7a195eb139d0277e471fa` | `0xade27248542c0f3e89b49e4eb76155e267f14377` | "4.0.0" -> "4.3.0" | YES |
| OptimismPortal2 | `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` | Proxy (ERC-1967) | `0x543ba4aadbab8f9025686bd03993043599c6fb04` | `0x1005217ad392dc64cef501fa1777a27d42166748` | `0xb20b23af6071405c37ddda0c0640e8ebb7899645` | "5.8.0" -> "6.1.0" | YES |
| ETHLockbox | `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43` | Proxy (ERC-1967) | `0x543ba4aadbab8f9025686bd03993043599c6fb04` | `0xb3a24db07038b51962026329b62e7a965d56a6ad` | `0xdf75e6b07e98873e36ba5c05508f80c1454e0afe` | "1.3.1" -> "2.0.0" | YES |
| L1CrossDomainMessenger | `0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1` | ResolvedDelegateProxy | `AddressManager 0xde1fcfb0851916ca5101820a69b13a4e276bd81f` | `0x59D497530b00062f40950ba8EaB88868bf7F86f0` | `0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448` | "2.11.1" -> "2.13.0" | YES |
| L1StandardBridge | `0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1` | L1ChugSplashProxy | `0x543ba4aadbab8f9025686bd03993043599c6fb04` | `0xb37a11aadf167b2f0b8dd85372de4bc66cd4a891` | `0xb37a11aadf167b2f0b8dd85372de4bc66cd4a891` | "2.8.2" -> "2.8.2" | no (same address re-installed, initializer re-run) |
| L1ERC721Bridge | `0x5a7749f83b81B301cAb5f48EB8516B986DAef23D` | Proxy (ERC-1967) | `0x543ba4aadbab8f9025686bd03993043599c6fb04` | `0x9f164f1d02a81e06d639e55f65a87f0070e3cb2e` | `0x9f164f1d02a81e06d639e55f65a87f0070e3cb2e` | "2.9.1" -> "2.9.1" | no (same address re-installed, initializer re-run) |
| OptimismMintableERC20Factory | `0x75505a97BD334E7BD3C476893285569C4136Fa0F` | Proxy (ERC-1967) | `0x543ba4aadbab8f9025686bd03993043599c6fb04` | `0xaabea75da509fa518fd8a91eae4be5813b829b12` | `0xaabea75da509fa518fd8a91eae4be5813b829b12` | "1.11.0" -> "1.11.0" | no (same address re-installed, initializer re-run) |
| DisputeGameFactory | `0xe5965Ab5962eDc7477C8520243A95517CD252fA9` | Proxy (ERC-1967) | `0x543ba4aadbab8f9025686bd03993043599c6fb04` | `0x72b971717e088b59f26d4236be222adb6acd393b` | `0x72b971717e088b59f26d4236be222adb6acd393b` | "1.6.1" -> "1.6.1" | no (same address re-installed, initializer re-run) |
| DelayedWETH | `0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162` | Proxy (ERC-1967) | `0x543ba4aadbab8f9025686bd03993043599c6fb04` | `0xe440cc08a71694c8229323803f59024e3144630e` | `0xf024e96317907c3b8d8cb346b9fd9034c8640e15` | "1.5.1" -> "2.0.0" | YES |
| AnchorStateRegistry | `0x23B2C62946350F4246f9f9D027e071f0264FD113` | Proxy (ERC-1967) | `0x543ba4aadbab8f9025686bd03993043599c6fb04` | `0x8f40cc98d694ab986f026c5383a181fcc9b6b281` | `0x2b27299c577d4720100e2735b652444dcea652d0` | "3.9.0" -> "4.0.0" | YES |

### Ink

| Contract | Proxy | Proxy type | Admin (EIP-1967 admin slot / AddressManager) | Impl @ N-1 | Impl @ N | Version N-1 -> N | Impl changed |
|---|---|---|---|---|---|---|---|
| SystemConfig | `0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364` | Proxy (ERC-1967) | `0xd56045e68956fce2576e680c95a4750cf8241f79` | `0x670b850a235a6fa98cd7a195eb139d0277e471fa` | `0xade27248542c0f3e89b49e4eb76155e267f14377` | "4.0.0" -> "4.3.0" | YES |
| OptimismPortal2 | `0x5d66C1782664115999C47c9fA5cd031f495D3e4F` | Proxy (ERC-1967) | `0xd56045e68956fce2576e680c95a4750cf8241f79` | `0x1005217ad392dc64cef501fa1777a27d42166748` | `0xb20b23af6071405c37ddda0c0640e8ebb7899645` | "5.8.0" -> "6.1.0" | YES |
| ETHLockbox | `0xbd4AbB321138e8Eddc399cE64E66451294325a14` | Proxy (ERC-1967) | `0xd56045e68956fce2576e680c95a4750cf8241f79` | `0xb3a24db07038b51962026329b62e7a965d56a6ad` | `0xdf75e6b07e98873e36ba5c05508f80c1454e0afe` | "1.3.1" -> "2.0.0" | YES |
| L1CrossDomainMessenger | `0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f` | ResolvedDelegateProxy | `AddressManager 0x9b7c9bbd6d540a8a4dedd935819fc4408ba71153` | `0x59D497530b00062f40950ba8EaB88868bf7F86f0` | `0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448` | "2.11.1" -> "2.13.0" | YES |
| L1StandardBridge | `0x88FF1e5b602916615391F55854588EFcBB7663f0` | L1ChugSplashProxy | `0xd56045e68956fce2576e680c95a4750cf8241f79` | `0xb37a11aadf167b2f0b8dd85372de4bc66cd4a891` | `0xb37a11aadf167b2f0b8dd85372de4bc66cd4a891` | "2.8.2" -> "2.8.2" | no (same address re-installed, initializer re-run) |
| L1ERC721Bridge | `0x661235a238B11191211fa95D4Dd9E423d521E0Be` | Proxy (ERC-1967) | `0xd56045e68956fce2576e680c95a4750cf8241f79` | `0x9f164f1d02a81e06d639e55f65a87f0070e3cb2e` | `0x9f164f1d02a81e06d639e55f65a87f0070e3cb2e` | "2.9.1" -> "2.9.1" | no (same address re-installed, initializer re-run) |
| OptimismMintableERC20Factory | `0xA8B389A82e088b164cD03230e900980CcED34d29` | Proxy (ERC-1967) | `0xd56045e68956fce2576e680c95a4750cf8241f79` | `0xaabea75da509fa518fd8a91eae4be5813b829b12` | `0xaabea75da509fa518fd8a91eae4be5813b829b12` | "1.11.0" -> "1.11.0" | no (same address re-installed, initializer re-run) |
| DisputeGameFactory | `0x10d7B35078d3baabB96Dd45a9143B94be65b12CD` | Proxy (ERC-1967) | `0xd56045e68956fce2576e680c95a4750cf8241f79` | `0x72b971717e088b59f26d4236be222adb6acd393b` | `0x72b971717e088b59f26d4236be222adb6acd393b` | "1.6.1" -> "1.6.1" | no (same address re-installed, initializer re-run) |
| DelayedWETH | `0x57b4C29DAee99a28E6E86778b499361294c134eA` | Proxy (ERC-1967) | `0xd56045e68956fce2576e680c95a4750cf8241f79` | `0xe440cc08a71694c8229323803f59024e3144630e` | `0xf024e96317907c3b8d8cb346b9fd9034c8640e15` | "1.5.1" -> "2.0.0" | YES |
| AnchorStateRegistry | `0xEe018bAf058227872540AC60eFbd38b023d9dAe2` | Proxy (ERC-1967) | `0xd56045e68956fce2576e680c95a4750cf8241f79` | `0x8f40cc98d694ab986f026c5383a181fcc9b6b281` | `0x2b27299c577d4720100e2735b652444dcea652d0` | "3.9.0" -> "4.0.0" | YES |

### Soneium

| Contract | Proxy | Proxy type | Admin (EIP-1967 admin slot / AddressManager) | Impl @ N-1 | Impl @ N | Version N-1 -> N | Impl changed |
|---|---|---|---|---|---|---|---|
| SystemConfig | `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3` | Proxy (ERC-1967) | `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a` | `0x670b850a235a6fa98cd7a195eb139d0277e471fa` | `0xade27248542c0f3e89b49e4eb76155e267f14377` | "4.0.0" -> "4.3.0" | YES |
| OptimismPortal2 | `0x88e529A6ccd302c948689Cd5156C83D4614FAE92` | Proxy (ERC-1967) | `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a` | `0x1005217ad392dc64cef501fa1777a27d42166748` | `0xb20b23af6071405c37ddda0c0640e8ebb7899645` | "5.8.0" -> "6.1.0" | YES |
| ETHLockbox | `0x67B4de6FfA66EF201Ea6099A89cA397D56622E31` | Proxy (ERC-1967) | `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a` | `0xb3a24db07038b51962026329b62e7a965d56a6ad` | `0xdf75e6b07e98873e36ba5c05508f80c1454e0afe` | "1.3.1" -> "2.0.0" | YES |
| L1CrossDomainMessenger | `0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f` | ResolvedDelegateProxy | `AddressManager 0xb24bfeece1b3b7a44559f4cbc21bed312b130b70` | `0x59D497530b00062f40950ba8EaB88868bf7F86f0` | `0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448` | "2.11.1" -> "2.13.0" | YES |
| L1StandardBridge | `0xeb9bf100225c214Efc3E7C651ebbaDcF85177607` | L1ChugSplashProxy | `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a` | `0xb37a11aadf167b2f0b8dd85372de4bc66cd4a891` | `0xb37a11aadf167b2f0b8dd85372de4bc66cd4a891` | "2.8.2" -> "2.8.2" | no (same address re-installed, initializer re-run) |
| L1ERC721Bridge | `0x5933e323bE8896DfaCd1cD671442F27dAA10a053` | Proxy (ERC-1967) | `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a` | `0x9f164f1d02a81e06d639e55f65a87f0070e3cb2e` | `0x9f164f1d02a81e06d639e55f65a87f0070e3cb2e` | "2.9.1" -> "2.9.1" | no (same address re-installed, initializer re-run) |
| OptimismMintableERC20Factory | `0xc1047e30EFC9E172cFe7aa0219895B6a43fC415F` | Proxy (ERC-1967) | `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a` | `0xaabea75da509fa518fd8a91eae4be5813b829b12` | `0xaabea75da509fa518fd8a91eae4be5813b829b12` | "1.11.0" -> "1.11.0" | no (same address re-installed, initializer re-run) |
| DisputeGameFactory | `0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0` | Proxy (ERC-1967) | `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a` | `0x72b971717e088b59f26d4236be222adb6acd393b` | `0x72b971717e088b59f26d4236be222adb6acd393b` | "1.6.1" -> "1.6.1" | no (same address re-installed, initializer re-run) |
| DelayedWETH | `0x18fBb58C366e21F395DdEc7cBa0510a2D9116B47` | Proxy (ERC-1967) | `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a` | `0xe440cc08a71694c8229323803f59024e3144630e` | `0xf024e96317907c3b8d8cb346b9fd9034c8640e15` | "1.5.1" -> "2.0.0" | YES |
| AnchorStateRegistry | `0x4890928941e62e273dA359374b105F803329F473` | Proxy (ERC-1967) | `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a` | `0x8f40cc98d694ab986f026c5383a181fcc9b6b281` | `0x2b27299c577d4720100e2735b652444dcea652d0` | "3.9.0" -> "4.0.0" | YES |

### Unichain

| Contract | Proxy | Proxy type | Admin (EIP-1967 admin slot / AddressManager) | Impl @ N-1 | Impl @ N | Version N-1 -> N | Impl changed |
|---|---|---|---|---|---|---|---|
| SystemConfig | `0xc407398d063f942feBbcC6F80a156b47F3f1BDA6` | Proxy (ERC-1967) | `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4` | `0x670b850a235a6fa98cd7a195eb139d0277e471fa` | `0xade27248542c0f3e89b49e4eb76155e267f14377` | "4.0.0" -> "4.3.0" | YES |
| OptimismPortal2 | `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` | Proxy (ERC-1967) | `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4` | `0x1005217ad392dc64cef501fa1777a27d42166748` | `0xb20b23af6071405c37ddda0c0640e8ebb7899645` | "5.8.0" -> "6.1.0" | YES |
| ETHLockbox | `0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5` | Proxy (ERC-1967) | `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4` | `0xb3a24db07038b51962026329b62e7a965d56a6ad` | `0xdf75e6b07e98873e36ba5c05508f80c1454e0afe` | "1.3.1" -> "2.0.0" | YES |
| L1CrossDomainMessenger | `0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6` | ResolvedDelegateProxy | `AddressManager 0x8098f676033a377b9defe302e9fe6877cd63d575` | `0x59D497530b00062f40950ba8EaB88868bf7F86f0` | `0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448` | "2.11.1" -> "2.13.0" | YES |
| L1StandardBridge | `0x81014F44b0a345033bB2b3B21C7a1A308B35fEeA` | L1ChugSplashProxy | `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4` | `0xb37a11aadf167b2f0b8dd85372de4bc66cd4a891` | `0xb37a11aadf167b2f0b8dd85372de4bc66cd4a891` | "2.8.2" -> "2.8.2" | no (same address re-installed, initializer re-run) |
| L1ERC721Bridge | `0xD04D0D87E0bd4D2E50286760a3EF323FeA6849Cf` | Proxy (ERC-1967) | `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4` | `0x9f164f1d02a81e06d639e55f65a87f0070e3cb2e` | `0x9f164f1d02a81e06d639e55f65a87f0070e3cb2e` | "2.9.1" -> "2.9.1" | no (same address re-installed, initializer re-run) |
| OptimismMintableERC20Factory | `0xA2B597EaeAcb6F627e088cbEaD319e934ED5edad` | Proxy (ERC-1967) | `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4` | `0xaabea75da509fa518fd8a91eae4be5813b829b12` | `0xaabea75da509fa518fd8a91eae4be5813b829b12` | "1.11.0" -> "1.11.0" | no (same address re-installed, initializer re-run) |
| DisputeGameFactory | `0x2F12d621a16e2d3285929C9996f478508951dFe4` | Proxy (ERC-1967) | `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4` | `0x72b971717e088b59f26d4236be222adb6acd393b` | `0x72b971717e088b59f26d4236be222adb6acd393b` | "1.6.1" -> "1.6.1" | no (same address re-installed, initializer re-run) |
| DelayedWETH | `0x74ad145aC900F1DD5551F0C9E143314DC4022FCf` | Proxy (ERC-1967) | `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4` | `0xe440cc08a71694c8229323803f59024e3144630e` | `0xf024e96317907c3b8d8cb346b9fd9034c8640e15` | "1.5.1" -> "2.0.0" | YES |
| AnchorStateRegistry | `0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9` | Proxy (ERC-1967) | `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4` | `0x8f40cc98d694ab986f026c5383a181fcc9b6b281` | `0x2b27299c577d4720100e2735b652444dcea652d0` | "3.9.0" -> "4.0.0" | YES |

Notes:
- `impl @ 26433900 == impl @ N` for all 41 (column omitted).
- L1ChugSplashProxy stores its implementation in the same EIP-1967 slot (`0x3608...2bbc`); its owner slot is the EIP-1967 admin slot.
- For the ResolvedDelegateProxy the implementation is `AddressManager.getAddress("OVM_L1CrossDomainMessenger")`; AddressManager owner == the chain's ProxyAdmin on all four chains.
- All four chains moved from the same v8 set to the same v9 set; ProxyAdmin owner is the Safe `0x5a0Aae59...` for all five ProxyAdmins (OP `0x543bA4AA...` which also administers SuperchainConfig, Ink `0xd56045E6...`, Soneium `0x89889B56...`, Unichain `0x3B73Fa8d...`).

## 3. Implementation set and bytecode verification

`OPContractsManagerV2` `0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f` v9.0.3; container `0xeFb3141314FEF7aD1b7c84c0D3df16b63B3dC760` (devFeatureBitmap = 0); utils `0xE1EA0F70fDA205fDfeEc770A259e4C34C0f7c4c6`; migrator `0x5B42AB3d7CB6c6dA53b3d5C148Ff34CD998afAC0`; standard validator `0x9E1D01E25f411c5da20C33d1EaDe0F83256d41B2` v4.1.1. Previous OPCM (lastUsedOPCM at N-1): `0x1951828Ce913DC4383a8A1695695D537a11D896a` v8.0.1.

Runtime bytecode fetched with `cast code` on `l1` and compared byte-for-byte with `forge-artifacts/<Name>.sol/<Name>.json` `deployedBytecode` of the local v9 build after zeroing the `immutableReferences` ranges (script `evidence/lane01-verify-bytecode.py`). Result: **all 23 MATCH, 0 differing bytes**.

| Contract | Address (v9 container) | v8 container value | Verified vs v9 build | Immutables read from chain |
|---|---|---|---|---|
| SuperchainConfig | `0xA303a644cfbC0c34f6a9dBEaFdebA4C967EA01e7` | `0x5570b1f2b97B1E35b5C6f9Ee76f6cf02c9917504` | MATCH | initVersion=2 |
| SystemConfig | `0xADe27248542c0F3E89b49e4eB76155e267F14377` | `0x670b850A235A6fA98cD7a195eB139D0277E471fA` | MATCH | initVersion=3 |
| OptimismPortal2 | `0xb20B23af6071405C37dDDA0C0640e8eBb7899645` | `0x1005217ad392DC64CEf501FA1777A27D42166748` | MATCH | initVersion=3, PROOF_MATURITY_DELAY_SECONDS=604800 |
| ETHLockbox | `0xDF75E6b07E98873E36BA5c05508F80c1454e0aFe` | `0xb3A24DB07038b51962026329B62E7a965d56A6ad` | MATCH | initVersion=1 |
| L1CrossDomainMessenger | `0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448` | `0x59D497530b00062f40950ba8EaB88868bf7F86f0` | MATCH | initVersion=3 |
| L1StandardBridge | `0xB37a11AadF167B2F0b8dD85372De4bC66CD4A891` | same | MATCH | initVersion=3 |
| L1ERC721Bridge | `0x9F164f1d02A81e06D639E55F65a87f0070E3Cb2e` | same | MATCH | initVersion=3 |
| OptimismMintableERC20Factory | `0xaAbEA75Da509fA518Fd8a91Eae4BE5813B829b12` | same | MATCH | none (plain `initializer`) |
| DisputeGameFactory | `0x72B971717E088B59F26d4236BE222ADB6ACD393b` | same | MATCH | initVersion=1 |
| AnchorStateRegistry | `0x2b27299C577d4720100e2735b652444DcEa652D0` | `0x8F40Cc98D694AB986F026C5383A181FCc9B6B281` | MATCH | initVersion=1, DISPUTE_GAME_FINALITY_DELAY_SECONDS=302400 |
| DelayedWETH | `0xF024e96317907C3b8d8CB346B9FD9034c8640e15` | `0xE440CC08A71694C8229323803F59024E3144630e` | MATCH | initVersion=1, DELAY_SECONDS=302400 |
| MIPS64 | `0xaCc005DCd857B401e4732E6F7837135A22825cfA` | same | MATCH | oracle=0x1E1d73536A081Ef2F355d29794547a9770Aeb1E0, stateVersion=8 |
| FaultDisputeGame | `0x2DDA3584b51eF5236f7726Dea5A0FB6B3cA94AeC` | same | MATCH | maxGameDepth=73, splitDepth=30, maxClockDuration=302400, clockExtension=10800 |
| PermissionedDisputeGame | `0xe1dFFCBE4e22B813F26d2106D943C102e7cAb87e` | same | MATCH | same four |
| SuperFaultDisputeGame | `0x19AF533Cc2A2A55786DCB8672aA5717e64213208` | same | MATCH | same four |
| SuperPermissionedDisputeGame | `0x5C3eb47cB0174aea522a2a9Ae79487139A53D691` | same | MATCH | none |
| ZKDisputeGame / SP1 adapter | `0x0000000000000000000000000000000000000000` | 0x0 | n/a | not deployed (ZK disabled) |
| StorageSetter | `0x2476c911E6D4D9411E677D8Faf15a64ac1fDEEe8` | same | MATCH | none |
| OPContractsManagerV2 | `0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f` | n/a | MATCH | opcmUtils, opcmStandardValidator, opcmMigrator, opcmV2(self) |
| OPContractsManagerUtils | `0xE1EA0F70fDA205fDfeEc770A259e4C34C0f7c4c6` | n/a | MATCH | contractsContainer |
| OPContractsManagerContainer | `0xeFb3141314FEF7aD1b7c84c0D3df16b63B3dC760` | n/a | MATCH | devFeatureBitmap=0 |
| OPContractsManagerMigrator | `0x5B42AB3d7CB6c6dA53b3d5C148Ff34CD998afAC0` | n/a | MATCH | opcmUtils |
| OPContractsManagerStandardValidator | `0x9E1D01E25f411c5da20C33d1EaDe0F83256d41B2` | n/a | MATCH | none |
| ProxyAdmin (OP Mainnet instance) | `0x543bA4AADBAb8f9025686Bd03993043599c6fB04` | n/a | MATCH | none |

Consequences worth knowing:
- Seven implementations are byte-identical between the v8 and v9 containers (L1StandardBridge 2.8.2, L1ERC721Bridge 2.9.1, OptimismMintableERC20Factory 1.11.0, DisputeGameFactory 1.6.1, MIPS64 1.10.1, all four dispute-game implementations, StorageSetter). Their v8->v9 source diffs are formatting only (same semver, same deployed bytecode). For those proxies U21 re-installed the same implementation and re-ran the initializer with unchanged arguments: zero net storage change.
- The dispute game implementations registered in every DisputeGameFactory are therefore the pre-U21 ones (`gameImpls(5)=0x5C3eb47c...`, `gameImpls(9)=0x19AF533C...`); only `gameArgs` changed (section 5 of `U21_INITIALIZER_CALLS.md`).
- Implementation contracts themselves: slot 0 `_initialized == 0xff` on all eleven proxied implementations (L1CrossDomainMessenger: byte at offset 20), EIP-1967 admin slot zero, zero balance. `initialize` on an implementation reverts `Initializable: contract is already initialized`.

## 4. Contracts in the system that were NOT touched

| Contract | Address(es) | State N-1 vs N | Expected? |
|---|---|---|---|
| ProxyAdmin x4 | OP `0x543bA4AADBAb8f9025686Bd03993043599c6fB04`, Ink `0xd56045E68956FCe2576E680c95a4750cf8241f79`, Soneium `0x89889B569c3a505f3640ee1Bd0ac1D557f436D2a`, Unichain `0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4` | no storage write. owner = Safe, `isUpgrading()=false`, `proxyType(L1SB)=1`, `proxyType(L1xDM)=2`, `implementationName(L1xDM)="OVM_L1CrossDomainMessenger"` | Yes (not proxies; OPCM never redeploys them on upgrade) |
| AddressManager x4 | OP `0xdE1FCfB0851916CA5101820A69b13a4E276bd81F`, Ink `0x9b7C9BbD6d540A8A4dEDd935819fC4408Ba71153`, Soneium `0xB24bFEeCE1B3b7A44559F4Cbc21BeD312b130b70`, Unichain `0x8098F676033A377b9Defe302e9fE6877cD63D575` | exactly one slot each (`OVM_L1CrossDomainMessenger` entry, slot `0x51521693...385e`) `0x59D49753...` -> `0x7d4Ec7fB...` | Yes |
| Dispute game implementations, MIPS64, PreimageOracle `0x1E1d7353...` (1.1.5) | see section 3 | unchanged | Yes: byte-identical in v9 |
| Legacy DelayedWETH proxies (OP Mainnet) | `0xE497B094d6DbB3D5E4CaAc9a14696D7572588d14` (v1.0.0, 0.16 ETH), `0x82511d494B5C942BE57498a70Fdd7184Ee33B975` (v1.1.0, 0.08 ETH), `0xD061AB95069987868768818cc1248705351e2D0e` (v1.5.0, 0 ETH, `systemConfig()` = OP SystemConfig) | impl slots unchanged; admin = OP ProxyAdmin | Yes by OPCM design: only `systemConfig.delayedWETH()` (`0x1B6DBF05...`) is loaded. They keep resolving pause through `SuperchainConfig.paused()` (v1.0/1.1, global pause only) or `SystemConfig.paused()` (v1.5.0, now routed to the lockbox). Residual balances are unclaimed bonds of old games. Legacy WETH proxies of the other three chains were not enumerated. |
| Legacy AnchorStateRegistry (OP Mainnet) | `0x18DAc71c228D1C32c99489B7323d441E1175e443` (v2.0.0, admin = OP ProxyAdmin) | unchanged | Yes: not referenced by the portal since the ASR `0x23B2C629...` was introduced |
| ProtocolVersions | `0x8062AbC286f5e7D9428a0Ccb9AbD71e50d93b935` (1.1.0) | impl unchanged | Yes: not managed by OPCM |
| OPCM v8 | `0x1951828Ce913DC4383a8A1695695D537a11D896a` | n/a (stateless) | Yes; still deployed (not re-examined by this lane) |
| Other chains sharing SuperchainConfig `0x95703e09...` (e.g. Base portal `0x49048044...`) | - | not in this tx | Yes per the brief. The v8->v9 SuperchainConfig diff only adds `isLocalOrGlobalPaused(address)`; the existing `paused(address)`/`paused()`/`guardian()` ABI is unchanged. Those chains' own contracts were not inspected by this lane |

## 5. Changes between block N and 26433900 on the touched proxies

None of the 339 slots written by the upgrade differs between N and 26433900. Getter-level differences in that window are ordinary operation only:
- `AnchorStateRegistry.anchorGame` advanced on all four chains (OP `0x51024A83...` -> `0x55A5CFd4...`; Ink `0x7A5559F3...` -> `0x38925ef2...`; Soneium `0xa64e0DAf...` -> `0x5dFB50E0...`; Unichain `0x55AE7D93...` -> `0x944a783a...`). The new OP anchor game was created at 1794299939, i.e. before the upgrade (1794871439), with the pre-U21 prestate, and was accepted by ASR v4.0.0 after the upgrade.
- `DisputeGameFactory.gameCount`: OP 21378 -> 21389, Ink 2639 -> 2640, Soneium 8533 -> 8537, Unichain 17681 -> 17691.
- `DelayedWETH.totalSupply` OP 20.582782 -> 20.662782 ETH; ETHLockbox balances OP 182,420.51 -> 182,541.07 ETH, Unichain 18,222.35 -> 18,266.16 ETH, Ink and Soneium unchanged; `L1CrossDomainMessenger.messageNonce` advanced.
- No implementation, admin, owner, guardian, feature flag, game implementation, game args, init bond, respected game type or retirement timestamp changed. Safe nonce at N is 49; the read at 26433900 failed on an upstream 429 and is not verified.

