# U21 proxy implementation map — mirror lane 21

Pinned source: op-contracts/v9.0.0 at `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`. State is read at N-1 `26430858`, N `26430859`, and later `26433900`. The machine-readable source is [proxy-implementation-map.json](artifacts/proxy-implementation-map.json).

## Result

The bundle touched 41 proxies: the shared SuperchainConfig plus ten proxies on each of OP Mainnet, Ink, Soneium, and Unichain. Twenty-five final implementation pointers changed and sixteen were reinitialized at the same implementation. No proxy initializer-version byte changed across N-1→N (the reset/reinitialize cycle restores the same release-specific value), every post implementation singleton has its initializer byte locked at `0xff`, and every implementation/version/init byte remained stable through block 26433900.

Proxy type and implementation reads use the deployed ProxyAdmin dispatch logic at `packages/contracts-bedrock/src/universal/ProxyAdmin.sol:101-114`; the three upgrade routes are at lines 149-166.

## Complete map

| Chain | Contract / proxy | Type | Pre implementation · version | Post implementation · version | init |
|---|---|---|---|---|---:|
| Superchain | `SuperchainConfig`<br>`0x95703e0982140D16f8ebA6d158FccEde42f04a4C` | ERC1967 | `0x5570b1f2b97B1E35b5C6f9Ee76f6cf02c9917504` · 2.4.3 | `0xA303a644cfbC0c34f6a9dBEaFdebA4C967EA01e7` · 2.5.0 | 2 |
| OP Mainnet | `SystemConfig`<br>`0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` | ERC1967 | `0x670b850A235A6fA98cD7a195eB139D0277E471fA` · 4.0.0 | `0xADe27248542c0F3E89b49e4eB76155e267F14377` · 4.3.0 | 3 |
| OP Mainnet | `OptimismPortal2`<br>`0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` | ERC1967 | `0x1005217ad392DC64CEf501FA1777A27D42166748` · 5.8.0 | `0xb20B23af6071405C37dDDA0C0640e8eBb7899645` · 6.1.0 | 3 |
| OP Mainnet | `ETHLockbox`<br>`0x322b47Ff1FA8D5611F761e3E275C45B71b294D43` | ERC1967 | `0xb3A24DB07038b51962026329B62E7a965d56A6ad` · 1.3.1 | `0xDF75E6b07E98873E36BA5c05508F80c1454e0aFe` · 2.0.0 | 1 |
| OP Mainnet | `L1CrossDomainMessenger`<br>`0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1` | RESOLVED | `0x59D497530b00062f40950ba8EaB88868bf7F86f0` · 2.11.1 | `0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448` · 2.13.0 | 3 |
| OP Mainnet | `L1StandardBridge`<br>`0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1` | CHUGSPLASH | `0xB37a11AadF167B2F0b8dD85372De4bC66CD4A891` · 2.8.2 | `0xB37a11AadF167B2F0b8dD85372De4bC66CD4A891` · 2.8.2 | 3 |
| OP Mainnet | `L1ERC721Bridge`<br>`0x5a7749f83b81B301cAb5f48EB8516B986DAef23D` | ERC1967 | `0x9F164f1d02A81e06D639E55F65a87f0070E3Cb2e` · 2.9.1 | `0x9F164f1d02A81e06D639E55F65a87f0070E3Cb2e` · 2.9.1 | 3 |
| OP Mainnet | `OptimismMintableERC20Factory`<br>`0x75505a97BD334E7BD3C476893285569C4136Fa0F` | ERC1967 | `0xaAbEA75Da509fA518Fd8a91Eae4BE5813B829b12` · 1.11.0 | `0xaAbEA75Da509fA518Fd8a91Eae4BE5813B829b12` · 1.11.0 | 1 |
| OP Mainnet | `DisputeGameFactory`<br>`0xe5965Ab5962eDc7477C8520243A95517CD252fA9` | ERC1967 | `0x72B971717E088B59F26d4236BE222ADB6ACD393b` · 1.6.1 | `0x72B971717E088B59F26d4236BE222ADB6ACD393b` · 1.6.1 | 1 |
| OP Mainnet | `DelayedWETH`<br>`0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162` | ERC1967 | `0xE440CC08A71694C8229323803F59024E3144630e` · 1.5.1 | `0xF024e96317907C3b8d8CB346B9FD9034c8640e15` · 2.0.0 | 1 |
| OP Mainnet | `AnchorStateRegistry`<br>`0x23B2C62946350F4246f9f9D027e071f0264FD113` | ERC1967 | `0x8F40Cc98D694AB986F026C5383A181FCc9B6B281` · 3.9.0 | `0x2b27299C577d4720100e2735b652444DcEa652D0` · 4.0.0 | 1 |
| Ink | `SystemConfig`<br>`0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364` | ERC1967 | `0x670b850A235A6fA98cD7a195eB139D0277E471fA` · 4.0.0 | `0xADe27248542c0F3E89b49e4eB76155e267F14377` · 4.3.0 | 3 |
| Ink | `OptimismPortal2`<br>`0x5d66C1782664115999C47c9fA5cd031f495D3e4F` | ERC1967 | `0x1005217ad392DC64CEf501FA1777A27D42166748` · 5.8.0 | `0xb20B23af6071405C37dDDA0C0640e8eBb7899645` · 6.1.0 | 3 |
| Ink | `ETHLockbox`<br>`0xbd4AbB321138e8Eddc399cE64E66451294325a14` | ERC1967 | `0xb3A24DB07038b51962026329B62E7a965d56A6ad` · 1.3.1 | `0xDF75E6b07E98873E36BA5c05508F80c1454e0aFe` · 2.0.0 | 1 |
| Ink | `L1CrossDomainMessenger`<br>`0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f` | RESOLVED | `0x59D497530b00062f40950ba8EaB88868bf7F86f0` · 2.11.1 | `0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448` · 2.13.0 | 3 |
| Ink | `L1StandardBridge`<br>`0x88FF1e5b602916615391F55854588EFcBB7663f0` | CHUGSPLASH | `0xB37a11AadF167B2F0b8dD85372De4bC66CD4A891` · 2.8.2 | `0xB37a11AadF167B2F0b8dD85372De4bC66CD4A891` · 2.8.2 | 3 |
| Ink | `L1ERC721Bridge`<br>`0x661235a238B11191211fa95D4Dd9E423d521E0Be` | ERC1967 | `0x9F164f1d02A81e06D639E55F65a87f0070E3Cb2e` · 2.9.1 | `0x9F164f1d02A81e06D639E55F65a87f0070E3Cb2e` · 2.9.1 | 3 |
| Ink | `OptimismMintableERC20Factory`<br>`0xA8B389A82e088b164cD03230e900980CcED34d29` | ERC1967 | `0xaAbEA75Da509fA518Fd8a91Eae4BE5813B829b12` · 1.11.0 | `0xaAbEA75Da509fA518Fd8a91Eae4BE5813B829b12` · 1.11.0 | 1 |
| Ink | `DisputeGameFactory`<br>`0x10d7B35078d3baabB96Dd45a9143B94be65b12CD` | ERC1967 | `0x72B971717E088B59F26d4236BE222ADB6ACD393b` · 1.6.1 | `0x72B971717E088B59F26d4236BE222ADB6ACD393b` · 1.6.1 | 1 |
| Ink | `DelayedWETH`<br>`0x57b4C29DAee99a28E6E86778b499361294c134eA` | ERC1967 | `0xE440CC08A71694C8229323803F59024E3144630e` · 1.5.1 | `0xF024e96317907C3b8d8CB346B9FD9034c8640e15` · 2.0.0 | 1 |
| Ink | `AnchorStateRegistry`<br>`0xEe018bAf058227872540AC60eFbd38b023d9dAe2` | ERC1967 | `0x8F40Cc98D694AB986F026C5383A181FCc9B6B281` · 3.9.0 | `0x2b27299C577d4720100e2735b652444DcEa652D0` · 4.0.0 | 1 |
| Soneium | `SystemConfig`<br>`0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3` | ERC1967 | `0x670b850A235A6fA98cD7a195eB139D0277E471fA` · 4.0.0 | `0xADe27248542c0F3E89b49e4eB76155e267F14377` · 4.3.0 | 3 |
| Soneium | `OptimismPortal2`<br>`0x88e529A6ccd302c948689Cd5156C83D4614FAE92` | ERC1967 | `0x1005217ad392DC64CEf501FA1777A27D42166748` · 5.8.0 | `0xb20B23af6071405C37dDDA0C0640e8eBb7899645` · 6.1.0 | 3 |
| Soneium | `ETHLockbox`<br>`0x67B4de6FfA66EF201Ea6099A89cA397D56622E31` | ERC1967 | `0xb3A24DB07038b51962026329B62E7a965d56A6ad` · 1.3.1 | `0xDF75E6b07E98873E36BA5c05508F80c1454e0aFe` · 2.0.0 | 1 |
| Soneium | `L1CrossDomainMessenger`<br>`0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f` | RESOLVED | `0x59D497530b00062f40950ba8EaB88868bf7F86f0` · 2.11.1 | `0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448` · 2.13.0 | 3 |
| Soneium | `L1StandardBridge`<br>`0xeb9bf100225c214Efc3E7C651ebbaDcF85177607` | CHUGSPLASH | `0xB37a11AadF167B2F0b8dD85372De4bC66CD4A891` · 2.8.2 | `0xB37a11AadF167B2F0b8dD85372De4bC66CD4A891` · 2.8.2 | 3 |
| Soneium | `L1ERC721Bridge`<br>`0x5933e323bE8896DfaCd1cD671442F27dAA10a053` | ERC1967 | `0x9F164f1d02A81e06D639E55F65a87f0070E3Cb2e` · 2.9.1 | `0x9F164f1d02A81e06D639E55F65a87f0070E3Cb2e` · 2.9.1 | 3 |
| Soneium | `OptimismMintableERC20Factory`<br>`0xc1047e30EFC9E172cFe7aa0219895B6a43fC415F` | ERC1967 | `0xaAbEA75Da509fA518Fd8a91Eae4BE5813B829b12` · 1.11.0 | `0xaAbEA75Da509fA518Fd8a91Eae4BE5813B829b12` · 1.11.0 | 1 |
| Soneium | `DisputeGameFactory`<br>`0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0` | ERC1967 | `0x72B971717E088B59F26d4236BE222ADB6ACD393b` · 1.6.1 | `0x72B971717E088B59F26d4236BE222ADB6ACD393b` · 1.6.1 | 1 |
| Soneium | `DelayedWETH`<br>`0x18fBb58C366e21F395DdEc7cBa0510a2D9116B47` | ERC1967 | `0xE440CC08A71694C8229323803F59024E3144630e` · 1.5.1 | `0xF024e96317907C3b8d8CB346B9FD9034c8640e15` · 2.0.0 | 1 |
| Soneium | `AnchorStateRegistry`<br>`0x4890928941e62e273dA359374b105F803329F473` | ERC1967 | `0x8F40Cc98D694AB986F026C5383A181FCc9B6B281` · 3.9.0 | `0x2b27299C577d4720100e2735b652444DcEa652D0` · 4.0.0 | 1 |
| Unichain | `SystemConfig`<br>`0xc407398d063f942feBbcC6F80a156b47F3f1BDA6` | ERC1967 | `0x670b850A235A6fA98cD7a195eB139D0277E471fA` · 4.0.0 | `0xADe27248542c0F3E89b49e4eB76155e267F14377` · 4.3.0 | 3 |
| Unichain | `OptimismPortal2`<br>`0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` | ERC1967 | `0x1005217ad392DC64CEf501FA1777A27D42166748` · 5.8.0 | `0xb20B23af6071405C37dDDA0C0640e8eBb7899645` · 6.1.0 | 3 |
| Unichain | `ETHLockbox`<br>`0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5` | ERC1967 | `0xb3A24DB07038b51962026329B62E7a965d56A6ad` · 1.3.1 | `0xDF75E6b07E98873E36BA5c05508F80c1454e0aFe` · 2.0.0 | 1 |
| Unichain | `L1CrossDomainMessenger`<br>`0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6` | RESOLVED | `0x59D497530b00062f40950ba8EaB88868bf7F86f0` · 2.11.1 | `0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448` · 2.13.0 | 3 |
| Unichain | `L1StandardBridge`<br>`0x81014F44b0a345033bB2b3B21C7a1A308B35fEeA` | CHUGSPLASH | `0xB37a11AadF167B2F0b8dD85372De4bC66CD4A891` · 2.8.2 | `0xB37a11AadF167B2F0b8dD85372De4bC66CD4A891` · 2.8.2 | 3 |
| Unichain | `L1ERC721Bridge`<br>`0xD04D0D87E0bd4D2E50286760a3EF323FeA6849Cf` | ERC1967 | `0x9F164f1d02A81e06D639E55F65a87f0070E3Cb2e` · 2.9.1 | `0x9F164f1d02A81e06D639E55F65a87f0070E3Cb2e` · 2.9.1 | 3 |
| Unichain | `OptimismMintableERC20Factory`<br>`0xA2B597EaeAcb6F627e088cbEaD319e934ED5edad` | ERC1967 | `0xaAbEA75Da509fA518Fd8a91Eae4BE5813B829b12` · 1.11.0 | `0xaAbEA75Da509fA518Fd8a91Eae4BE5813B829b12` · 1.11.0 | 1 |
| Unichain | `DisputeGameFactory`<br>`0x2F12d621a16e2d3285929C9996f478508951dFe4` | ERC1967 | `0x72B971717E088B59F26d4236BE222ADB6ACD393b` · 1.6.1 | `0x72B971717E088B59F26d4236BE222ADB6ACD393b` · 1.6.1 | 1 |
| Unichain | `DelayedWETH`<br>`0x74ad145aC900F1DD5551F0C9E143314DC4022FCf` | ERC1967 | `0xE440CC08A71694C8229323803F59024E3144630e` · 1.5.1 | `0xF024e96317907C3b8d8CB346B9FD9034c8640e15` · 2.0.0 | 1 |
| Unichain | `AnchorStateRegistry`<br>`0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9` | ERC1967 | `0x8F40Cc98D694AB986F026C5383A181FCc9B6B281` · 3.9.0 | `0x2b27299C577d4720100e2735b652444DcEa652D0` · 4.0.0 | 1 |

## Runtime-bytecode verification

All twelve relevant runtime images—eleven final contract implementations plus StorageSetter—match the local v9 build exactly after zeroing only the artifact-declared immutable ranges. Lengths also match. The reproducible results and immutable counts are in [runtime-bytecode-verification.json](artifacts/runtime-bytecode-verification.json); no comparison failed. This covers the OP Mainnet implementation set as well as the shared implementation addresses used by the other three chains.

The transient StorageSetter is `0x2476c911E6D4D9411E677D8Faf15a64ac1fDEEe8`, version 1.2.2. Its arbitrary slot setters are explicit at `packages/contracts-bedrock/src/universal/StorageSetter.sol:10-42`; it is safe here only because ProxyAdmin installs it and removes it atomically.

## What was not upgraded

- No standard OPCMv2 proxy in the four supplied chain configurations was omitted. Same-implementation rows above were still passed through StorageSetter and reinitialized.
- The four ProxyAdmins are owner contracts, not proxies. Their implementations cannot change; their AddressManagers were touched only to replace the resolved messenger implementation mapping.
- The Safe proxy implementation, dispute-game implementation singletons, MIPS/preimage contracts, and pre-existing game clones were not implementation-upgraded. This is expected: the Safe only executed the bundle, and the DGF mutates future-clone configuration rather than existing clones.
- Base and every other chain were outside the five aggregate calls and therefore untouched. No L2 contract was called.

## Intermediate implementation pattern

For each ERC1967 row, receipt logs show `StorageSetter → real implementation (upgradeAndCall) → StorageSetter → real implementation`. The first setter pass zeros the one-byte v4 initializer field; the second reads the OZ-v5 namespaced slot after initialization before restoring the real implementation. Exact code: `OPContractsManagerUtils.sol:352-386`. Resolved messenger proxies make the same four transitions through AddressManager events, and Chugsplash bridges make them through the legacy storage route, so they do not emit the ERC1967 `Upgraded` event. All 307 logs are instruction-attributed in [decoded-logs.json](artifacts/decoded-logs.json).

