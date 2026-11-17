# Lane 23 independent U21 proxy / storage map

This map was reconstructed independently from the 307-log U21 receipt, proxy
implementation slots, version getters, SystemConfig/portal getters, and raw storage
at blocks 26430858 and 26430859. Intermediate implementation
`0x2476c911e6d4d9411e677d8faf15a64ac1fdeee8` is a transaction-local StorageSetter;
the end-of-block implementation and state are controlling.

## Final common implementations relevant to custody

| Contract family | Final implementation | Post version | Boundary observation |
|---|---|---:|---|
| OptimismPortal2 | `0xb20b23af6071405c37ddda0c0640e8ebb7899645` | 6.1.0 | OP pre impl `0x1005217ad392dc64cef501fa1777a27d42166748`, v5.8.0 |
| ETHLockbox | `0xdf75e6b07e98873e36ba5c05508f80c1454e0afe` | 2.0.0 | OP pre impl `0xb3a24db07038b51962026329b62e7a965d56a6ad`, v1.3.1 |
| SystemConfig | `0xade27248542c0f3e89b49e4eb76155e267f14377` | 4.3.0 | OP pre impl `0x670b850a235a6fa98cd7a195eb139d0277e471fa`, v4.0.0 |
| AnchorStateRegistry | `0x2b27299c577d4720100e2735b652444dcea652d0` | 4.0.0 | Now stores its lockbox pointer |
| DisputeGameFactory | `0x72b971717e088b59f26d4236be222adb6acd393b` | 1.6.1 | Implementation unchanged |
| L1CrossDomainMessenger | `0x7d4ec7fb1a1b9e6d61c04d5e21e3d68cff639448` | 2.13.0 | AddressManager resolution; OP pre `0x59d497530b00062f40950ba8eab88868bf7f86f0`, v2.11.1 |
| L1StandardBridge | `0xb37a11aadf167b2f0b8dd85372de4bc66cd4a891` | 2.8.2 | ChugSplash `getImplementation`; unchanged |
| L1ERC721Bridge | `0x9f164f1d02a81e06d639e55f65a87f0070e3cb2e` | — | Final receipt upgrade target |
| OptimismMintableERC20Factory | `0xaabea75da509fa518fd8a91eae4be5813b829b12` | — | Final receipt upgrade target |
| DelayedWETH | `0xf024e96317907c3b8d8cb346b9fd9034c8640e15` | — | Final receipt upgrade target; stores lockbox pointer |
| SuperchainConfig | `0xa303a644cfbc0c34f6a9dbeafdeba4c967ea01e7` | 2.5.0 | Shared proxy upgraded once |

All four AddressManagers resolve L1CrossDomainMessenger to the same final
implementation. All four L1StandardBridge proxies return the same unchanged
implementation from `getImplementation()`; the receipt still runs the
initialization/upgrade choreography across each chain.

## Forty chain-local proxies plus shared SuperchainConfig

| Family | OP | Ink | Soneium | Unichain |
|---|---|---|---|---|
| SystemConfig | `0x229047fed2591dbec1ef1118d64f7af3db9eb290` | `0x62c0a111929fa32cec2f76adba54c16afb6e8364` | `0x7a8ed66b319911a0f3e7288bddab30d9c0c875c3` | `0xc407398d063f942febbcc6f80a156b47f3f1bda6` |
| Portal | `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` | `0x5d66C1782664115999C47c9fA5cd031f495D3e4F` | `0x88e529A6ccd302c948689Cd5156C83D4614FAE92` | `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` |
| Lockbox | `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43` | `0xbd4AbB321138e8Eddc399cE64E66451294325a14` | `0x67B4de6FfA66EF201Ea6099A89cA397D56622E31` | `0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5` |
| ASR | `0x23B2C62946350F4246f9f9D027e071f0264FD113` | `0xEe018bAf058227872540AC60eFbd38b023d9dAe2` | `0x4890928941e62e273dA359374b105F803329F473` | `0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9` |
| DGF | `0xe5965Ab5962eDc7477C8520243A95517CD252fA9` | `0x10d7B35078d3baabB96Dd45a9143B94be65b12CD` | `0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0` | `0x2F12d621a16e2d3285929C9996f478508951dFe4` |
| L1 XDM | `0x25ace71c97b33cc4729cf772ae268934f7ab5fa1` | `0x69d3cf86b2bf1a9e99875b7e2d9b6a84426c171f` | `0x9cf951e3f74b644e621b36ca9cea147a78d4c39f` | `0x9a3d64e386c18cb1d6d5179a9596a4b5736e98a6` |
| L1 StandardBridge | `0x99c9fc46f92e8a1c0dec1b1747d010903e884be1` | `0x88ff1e5b602916615391f55854588efcbb7663f0` | `0xeb9bf100225c214efc3e7c651ebbadcf85177607` | `0x81014f44b0a345033bb2b3b21c7a1a308b35feea` |
| L1 ERC721Bridge | `0x5a7749f83b81b301cab5f48eb8516b986daef23d` | `0x661235a238b11191211fa95d4dd9e423d521e0be` | `0x5933e323be8896dfacd1cd671442f27daa10a053` | `0xd04d0d87e0bd4d2e50286760a3ef323fea6849cf` |
| Mintable factory | `0x75505a97bd334e7bd3c476893285569c4136fa0f` | `0xa8b389a82e088b164cd03230e900980cced34d29` | `0xc1047e30efc9e172cfe7aa0219895b6a43fc415f` | `0xa2b597eaeacb6f627e088cbead319e934ed5edad` |
| DelayedWETH | `0x1b6dbf05eaf22d4e70dc993e8a19dd9f3dcb3162` | `0x57b4c29daee99a28e6e86778b499361294c134ea` | `0x18fbb58c366e21f395ddec7cba0510a2d9116b47` | `0x74ad145ac900f1dd5551f0c9e143314dc4022fcf` |

The shared SuperchainConfig proxy is
`0x95703e0982140d16f8eba6d158fccede42f04a4c`. The 41 addresses above are exactly
the proxies emitting `Initialized(uint8)` in the saved upgrade receipt; initializer
versions are 2 for SuperchainConfig, 3 for SystemConfig/Portal/XDM/bridges, and 1
for lockbox/factory/DGF/DelayedWETH/ASR.

## Raw storage delta accounting

A declared-static-slot scan over all 41 touched proxies found:

- Every lockbox slot 3 changes from zero to the shared SuperchainConfig address.
- Every ASR slot 6 gains its chain's lockbox pointer.
- Every DelayedWETH slot 5 gains its chain's lockbox pointer.
- OP portal slot 1 changes because of the ordinary deposit/resource-metering
  transaction at index 341, before U21; it is not upgrade-created custody state.
- OP messenger slot 205 increments by one from an ordinary cross-domain deposit in
  the same block, not from U21.
- No declared static SystemConfig slot changes N-1 -> N, and no other declared
  static slot in the touched proxies changes.
- DGF mapping state changes for OP game types 5 and 9 and Unichain game type 9;
  Ink and Soneium getter values do not change. These are game configuration writes,
  not ETH custody movement.

Portal/lockbox pointer and authorization are unchanged on all four chains. INTEROP
remains false, so U21 did not run the future shared-lockbox migration.

