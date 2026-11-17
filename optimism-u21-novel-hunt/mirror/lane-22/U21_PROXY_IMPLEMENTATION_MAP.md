# U21 proxy and implementation map (lane 22)

Checkpoint reads: N-1 = 26430858 (`:8546`), N = 26430859 (`:8547`), later = 26433900 (`:8545`). Standard and ChugSplash proxy implementations were read from the EIP-1967 implementation slot; messenger implementations were resolved through each ProxyAdmin/AddressManager. The proxy variants and lookup branches are defined in `op-v9.0.0/packages/contracts-bedrock/src/universal/ProxyAdmin.sol:22-42,101-115,149-191`; reserved implementation/admin slots are defined in `.../src/libraries/Constants.sol:25-32`.

## Implementations

All four chains use the same implementations listed below. “Stable” means the final N implementation equals N-1 even though the receipt temporarily installed StorageSetter and restored the implementation.

| Contract | N-1 implementation / version | N implementation / version | init version | Proxy kind |
|---|---|---|---:|---|
| SuperchainConfig (shared) | `0x5570b1f2b97b1e35b5c6f9ee76f6cf02c9917504` / 2.4.3 | `0xA303a644cfbC0c34f6a9dBEaFdebA4C967EA01e7` / 2.5.0 | 2 | ERC1967 |
| SystemConfig | `0x670b850a235a6fa98cd7a195eb139d0277e471fa` / 4.0.0 | `0xADe27248542c0F3E89b49e4eB76155e267F14377` / 4.3.0 | 3 | ERC1967 |
| OptimismPortal2 | `0x1005217ad392dc64cef501fa1777a27d42166748` / 5.8.0 | `0xb20B23af6071405C37dDDA0C0640e8eBb7899645` / 6.1.0 | 3 | ERC1967 |
| ETHLockbox | `0xb3a24db07038b51962026329b62e7a965d56a6ad` / 1.3.1 | `0xDF75E6b07E98873E36BA5c05508F80c1454e0aFe` / 2.0.0 | 1 | ERC1967 |
| L1CrossDomainMessenger | `0x59D497530b00062f40950ba8EaB88868bf7F86f0` / 2.11.1 | `0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448` / 2.13.0 | 3 | ResolvedDelegateProxy |
| L1StandardBridge | `0xB37a11AadF167B2F0b8dD85372De4bC66CD4A891` / 2.8.2 | stable | 3 | L1ChugSplashProxy |
| L1ERC721Bridge | `0x9F164f1d02A81e06D639E55F65a87f0070E3Cb2e` / 2.9.1 | stable | 3 | ERC1967 |
| OptimismMintableERC20Factory | `0xaAbEA75Da509fA518Fd8a91Eae4BE5813B829b12` / 1.11.0 | stable | 1 (OZ `initializer`) | ERC1967 |
| DisputeGameFactory | `0x72B971717E088B59F26d4236BE222ADB6ACD393b` / 1.6.1 | stable | 1 | ERC1967 |
| DelayedWETH | `0xe440cc08a71694c8229323803f59024e3144630e` / 1.5.1 | `0xF024e96317907C3b8d8CB346B9FD9034c8640e15` / 2.0.0 | 1 | ERC1967 |
| AnchorStateRegistry | `0x8f40cc98d694ab986f026c5383a181fcc9b6b281` / 3.9.0 | `0x2b27299C577d4720100e2735b652444DcEa652D0` / 4.0.0 | 1 | ERC1967 |

All final implementations and versions above were unchanged at the later checkpoint. All four SystemConfigs changed unstructured `lastUsedOPCM` from `0x1951828Ce913DC4383a8A1695695D537a11D896a` (8.0.1) to `0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f` (9.0.3); the slot is defined at `op-v9.0.0/packages/contracts-bedrock/src/L1/SystemConfig.sol:92-99` and read at lines 312-320.

## Proxies

| Contract | OP Mainnet | Ink | Soneium | Unichain |
|---|---|---|---|---|
| SystemConfig | `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` | `0x62c0a111929fa32cec2f76adba54c16afb6e8364` | `0x7a8ed66b319911a0f3e7288bddab30d9c0c875c3` | `0xc407398d063f942febbcc6f80a156b47f3f1bda6` |
| OptimismPortal2 | `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` | `0x5d66C1782664115999C47c9fA5cd031f495D3e4F` | `0x88e529A6ccd302c948689Cd5156C83D4614FAE92` | `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` |
| ETHLockbox | `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43` | `0xbd4AbB321138e8Eddc399cE64E66451294325a14` | `0x67B4de6FfA66EF201Ea6099A89cA397D56622E31` | `0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5` |
| Messenger | `0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1` | `0x69d3cf86b2bf1a9e99875b7e2d9b6a84426c171f` | `0x9cf951e3f74b644e621b36ca9cea147a78d4c39f` | `0x9a3d64e386c18cb1d6d5179a9596a4b5736e98a6` |
| StandardBridge | `0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1` | `0x88ff1e5b602916615391f55854588efcbb7663f0` | `0xeb9bf100225c214efc3e7c651ebbadcf85177607` | `0x81014f44b0a345033bb2b3b21c7a1a308b35feea` |
| ERC721Bridge | `0x5a7749f83b81B301cAb5f48EB8516B986DAef23D` | `0x661235a238b11191211fa95d4dd9e423d521e0be` | `0x5933e323be8896dfacd1cd671442f27daa10a053` | `0xd04d0d87e0bd4d2e50286760a3ef323fea6849cf` |
| MintableERC20Factory | `0x75505a97BD334E7BD3C476893285569C4136Fa0F` | `0xa8b389a82e088b164cd03230e900980cced34d29` | `0xc1047e30efc9e172cfe7aa0219895b6a43fc415f` | `0xa2b597eaeacb6f627e088cbead319e934ed5edad` |
| DisputeGameFactory | `0xe5965Ab5962eDc7477C8520243A95517CD252fA9` | `0x10d7b35078d3baabb96dd45a9143b94be65b12cd` | `0x512a3d2c7a43bd9261d2b8e8c9c70d4bd4d503c0` | `0x2f12d621a16e2d3285929c9996f478508951dfe4` |
| DelayedWETH | `0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162` | `0x57b4c29daee99a28e6e86778b499361294c134ea` | `0x18fbb58c366e21f395ddec7cba0510a2d9116b47` | `0x74ad145ac900f1dd5551f0c9e143314dc4022fcf` |
| AnchorStateRegistry | `0x23B2C62946350F4246f9f9D027e071f0264FD113` | `0xee018bAf058227872540AC60eFbd38b023d9dAe2` | `0x4890928941e62e273dA359374b105F803329F473` | `0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9` |

The shared SuperchainConfig proxy is `0x95703e0982140D16f8ebA6d158FccEde42f04a4C`.

## ProxyAdmin and legacy-proxy state

| Chain | ProxyAdmin | AddressManager | Owner |
|---|---|---|---|
| OP Mainnet | `0x543bA4AADBAb8f9025686Bd03993043599c6fB04` | `0xdE1FCfB0851916CA5101820A69b13a4E276bd81F` | `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` |
| Ink | `0xd56045e68956fce2576e680c95a4750cf8241f79` | `0x9b7C9BbD6d540A8A4dEDd935819fC4408Ba71153` | same |
| Soneium | `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a` | `0xB24bFEeCE1B3b7A44559F4Cbc21BeD312b130b70` | same |
| Unichain | `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4` | `0x8098F676033A377b9Defe302e9fE6877cD63D575` | same |

At N-1, N, and later, all four ProxyAdmins had `upgrading == false`, unchanged owner/addressManager slots, and proxy types Portal=0 (ERC1967), Messenger=2 (Resolved), StandardBridge=1 (ChugSplash). The Resolved proxy stores its name and AddressManager in address-keyed mappings (`.../src/legacy/ResolvedDelegateProxy.sol:13-35`); the ChugSplash proxy reads/writes the reserved slots (`.../src/legacy/L1ChugSplashProxy.sol:155-169,199-218`). Messenger's EIP-1967 admin slot is therefore zero, while its `proxyAdmin()` is resolved through AddressManager by `ProxyAdminOwnedBase` (`.../src/universal/ProxyAdminOwnedBase.sol:45-76`).

The AddressManager registry uses mapping slot 1 (`op-v9.0.0/packages/contracts-bedrock/src/legacy/AddressManager.sol:13-45`). For name hash `keccak256("OVM_L1CrossDomainMessenger") = 0x3b4a…665a`, the derived storage slot is `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e`. On every chain its raw value changed from `0x…59d497530b00062f40950ba8eab88868bf7f86f0` at N-1 to `0x…7d4ec7fb1a1b9e6d61c04d5e21e3d68cff639448` at N and stayed there later. This exactly matches both AddressManager and ProxyAdmin getters.

## Implementation initialization locks

Direct storage slot 0 at block N:

| Implementation | Raw slot 0 |
|---|---|
| SuperchainConfig, SystemConfig, Portal, ETHLockbox, StandardBridge, ERC721Bridge, Factory, DGF, DelayedWETH, ASR (10 implementations) | `0x00000000000000000000000000000000000000000000000000000000000000ff` |
| Messenger `0x7d4E…9448` | `0x0000000000000000000000ff0000000000000000000000000000000000000000` (`_initialized` at offset 20) |

The constructors call `_disableInitializers()` (representative: Portal `.../OptimismPortal2.sol:264-268`, ETHLockbox `.../ETHLockbox.sol:86-89`, ASR `.../AnchorStateRegistry.sol:83-87`). OZ writes `0xff` when disabling (`op-v9.0.0/packages/contracts-bedrock/lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol:125-136`). The fork test `test_implementationInitializersAreDisabled` checks all 11 addresses.
