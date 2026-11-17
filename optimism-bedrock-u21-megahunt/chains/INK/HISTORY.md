# INK (chain id 57073) — chain history profile (worker F5)

Generated from chain state by `scripts/F5-build-chain-files.py`; every row is a `cast`-equivalent read through the L1 archive proxy `http://127.0.0.1:7545` at or before the pinned block 26433900, or a superchain-registry / superchain-ops file. Raw evidence: `evidence/F5/INK-history-raw.json`, `evidence/F5/INK-upgrade-txs.json`, `evidence/F5/INK-stage2.json`, `evidence/F5/ink-games-0-2639.json`, `evidence/F5/ink-root-verification.json`.

## 1. Genesis / deployment generation

- Registry: L2 genesis time 1733498411 (2024-12-06 15:20:11 UTC), L1 origin block 21344310, L2 genesis block 0, block time 1 s, `superchain_time` = 1742396400, fault proofs (chainList.json): permissionless.
- Hardforks: canyon=0, delta=0, ecotone=0, fjord=0, granite=0, holocene=1742396400, isthmus=1746806401, jovian=1764691201, karst=1783526401, lagoon=1799683201.

| Proxy | Address | First code block | Date (UTC) | First implementation (version) | Admin slot at birth |
|---|---|---|---|---|---|
| SystemConfig | `0x62c0a111929fa32cec2f76adba54c16afb6e8364` | 21344310 | 2024-12-06 15:20:11 | `0xf56d96b2535b932656d3c04ebf51babff241d886` (2.2.0) | `0xd56045e68956fce2576e680c95a4750cf8241f79` |
| OptimismPortal | `0x5d66C1782664115999C47c9fA5cd031f495D3e4F` | 21344310 | 2024-12-06 15:20:11 | `0xe2f826324b2faf99e513d16d266c3f80ae87832b` (3.10.0) | `0xd56045e68956fce2576e680c95a4750cf8241f79` |
| ETHLockbox | `0xbd4AbB321138e8Eddc399cE64E66451294325a14` | 22990599 | 2025-07-24 17:47:23 | `0x784d2f03593a42a6e4676a012762f18775ecbbe6` (1.2.0) | `0xd56045e68956fce2576e680c95a4750cf8241f79` |
| AnchorStateRegistry | `0xEe018bAf058227872540AC60eFbd38b023d9dAe2` | 22990599 | 2025-07-24 17:47:23 | `0xeb69cc681e8d4a557b30dffbad85affd47a2cf2e` (3.5.0) | `0xd56045e68956fce2576e680c95a4750cf8241f79` |
| DisputeGameFactory | `0x10d7B35078d3baabB96Dd45a9143B94be65b12CD` | 21344310 | 2024-12-06 15:20:11 | `0xc641a33cab81c559f2bd4b21ea34c290e2440c2b` (1.0.0) | `0xd56045e68956fce2576e680c95a4750cf8241f79` |
| DelayedWETH | `0x57b4C29DAee99a28E6E86778b499361294c134eA` | 25397811 | 2026-06-25 23:05:47 | `0xe440cc08a71694c8229323803f59024e3144630e` (1.5.1) | `0xd56045e68956fce2576e680c95a4750cf8241f79` |
| L1CrossDomainMessenger | `0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f` | 21344310 | 2024-12-06 15:20:11 | `0x0000000000000000000000000000000000000000` (<none>) | `0x0000000000000000000000000000000000000000` |
| L1StandardBridge | `0x88FF1e5b602916615391F55854588EFcBB7663f0` | 21344310 | 2024-12-06 15:20:11 | `0x64b5a5ed26dcb17370ff4d33a8d503f0fbd06cff` (2.1.0) | `0xd56045e68956fce2576e680c95a4750cf8241f79` |
| L1ERC721Bridge | `0x661235a238B11191211fa95D4Dd9E423d521E0Be` | 21344310 | 2024-12-06 15:20:11 | `0xae2af01232a6c4a4d3012c5ec5b1b35059caf10d` (2.1.0) | `0xd56045e68956fce2576e680c95a4750cf8241f79` |
| OptimismMintableERC20Factory | `0xA8B389A82e088b164cD03230e900980CcED34d29` | 21344310 | 2024-12-06 15:20:11 | `0xe01efbeb1089d1d1db9c6c8b135c934c0734c846` (1.9.0) | `0xd56045e68956fce2576e680c95a4750cf8241f79` |
| ProxyAdmin | `0xd56045E68956FCe2576E680c95a4750cf8241f79` | 21344310 | 2024-12-06 15:20:11 | `None` (None) | `None` |
| AddressManager | `0x9b7c9bbd6d540a8a4dedd935819fc4408ba71153` | 21344310 | 2024-12-06 15:20:11 | `None` (None) | `None` |

## 2. Upgrade path (every implementation change)

`*` = a StorageSetter implementation was installed first in the same transaction (re-initialisation cycle). Task = superchain-ops task whose README status line names this tx (mapping from `evidence/F2-superchain-ops-tasks.json`).

| L1 block | Date | Tx | superchain-ops task | Proxies -> version |
|---|---|---|---|---|
| 21344310 | 2024-12-06 | `0x45c2b63987a8c7ab` | — | SystemConfig=2.2.0, OptimismPortal=3.10.0, DisputeGameFactory=1.0.0, L1ERC721Bridge=2.1.0, OptimismMintableERC20Factory=1.9.0, L1CrossDomainMessenger=2.3.0, L1StandardBridge=2.1.0 |
| 22182531 | 2025-04-02 | `0x5f3530e593bbac37` | 000-opcm-upgrade-v200 | SystemConfig=2.4.0, OptimismPortal=3.13.0, DisputeGameFactory=1.0.1, L1ERC721Bridge=2.3.1, OptimismMintableERC20Factory=1.10.1, L1CrossDomainMessenger=2.5.0, L1StandardBridge=2.2.2 |
| 22339996 | 2025-04-24 | `0xbe44244e352a9ffa` | 003-opcm-upgrade-v300-op-ink-soneium | SystemConfig=2.5.0, OptimismPortal=3.14.0, L1ERC721Bridge=2.4.0, L1CrossDomainMessenger=2.6.0, L1StandardBridge=2.3.0 |
| 22990599 | 2025-07-24 | `0x46acdce174c8d83e` | 017-U16-opcm-upgrade-v400-op-ink | SystemConfig=3.4.0, OptimismPortal=4.6.0, ETHLockbox=1.2.0, AnchorStateRegistry=3.5.0, DisputeGameFactory=1.2.0, L1ERC721Bridge=2.7.0, L1CrossDomainMessenger=2.9.0, L1StandardBridge=2.6.0 |
| 23491328 | 2025-10-02 | `0x744cf7d28324729c` | 023-U16a-opcm-upgrade-v410-op-soneium-ink | SystemConfig=3.7.0, OptimismPortal=5.0.0, AnchorStateRegistry=3.5.0, DisputeGameFactory=1.2.0, L1ERC721Bridge=2.8.0, L1CrossDomainMessenger=2.10.0, L1StandardBridge=2.7.0 |
| 23877377 | 2025-11-25 | `0xf556934cb4de1ab4` | 032-U17-main-op-sony-ink | SystemConfig=3.11.0, OptimismPortal=5.1.1, DisputeGameFactory=1.3.0, L1ERC721Bridge=2.9.0, OptimismMintableERC20Factory=1.10.2, L1CrossDomainMessenger=2.11.0, L1StandardBridge=2.8.0 |
| 24421512 | 2026-02-09 | `0x8808cd53114e4cf0` | 040-U18-op-ink-mmz-arena-swell | SystemConfig=3.13.1, OptimismPortal=5.2.0, AnchorStateRegistry=3.7.0, DisputeGameFactory=1.4.0, L1ERC721Bridge=2.9.0, OptimismMintableERC20Factory=1.10.2, L1CrossDomainMessenger=2.11.0 |
| 25397811 | 2026-06-25 | `0xbfdac60c9687a2e4` | 053-U19-op-ink-mmz-soneium | SystemConfig=3.14.2*, OptimismPortal=5.6.1*, ETHLockbox=1.3.1*, AnchorStateRegistry=3.9.0*, DisputeGameFactory=1.6.1*, DelayedWETH=1.5.1*, L1ERC721Bridge=2.9.1*, OptimismMintableERC20Factory=1.11.0*, L1CrossDomainMessenger=2.11.1*, L1StandardBridge=2.8.2 |
| 26048619 | 2026-09-24 | `0x0a0fe86f7b1a3d3d` | 071-U20-op-ink-soneium-uni | SystemConfig=4.0.0*, OptimismPortal=5.8.0*, ETHLockbox=1.3.1*, AnchorStateRegistry=3.9.0*, DisputeGameFactory=1.6.1*, DelayedWETH=1.5.1*, L1ERC721Bridge=2.9.1*, OptimismMintableERC20Factory=1.11.0*, L1CrossDomainMessenger=2.11.1* |
| 26430859 | 2026-11-16 | `0x024770b5fba87683` | 084-U21-op-ink-soneium-uni | SystemConfig=4.3.0*, OptimismPortal=6.1.0*, ETHLockbox=2.0.0*, AnchorStateRegistry=4.0.0*, DisputeGameFactory=1.6.1*, DelayedWETH=2.0.0*, L1ERC721Bridge=2.9.1*, OptimismMintableERC20Factory=1.11.0*, L1CrossDomainMessenger=2.13.0* |

Cross-check against F2's independent slot-sampling history (`evidence/F2-impl-history-ink.json`): 48 (proxy, block, implementation) entries compared, 12 mismatches.

`lastUsedOPCM` (SystemConfig) sampled at each upgrade block:

| L1 block | lastUsedOPCM | version |
|---|---|---|
| 23491328 | `None` | None |
| 23877377 | `None` | None |
| 24421512 | `None` | None |
| 25397811 | `0x9ce712ff84e02659846dc6450bb9b7642fe8be5d` | 7.1.17 |
| 26048619 | `0x1951828ce913dc4383a8a1695695d537a11d896a` | 8.0.1 |
| 26430859 | `0x2d91e6f2bcf6cd1df90e1faf9714e18705ea331f` | 9.0.3 |

## 3. Ownership, guardian, SuperchainConfig

- **ProxyAdmin owner history** (net change per tx; same-tx round trips through the ProxyAdmin during re-initialisation omitted): 21344310 (2024-12-06) `0x00000000…` -> `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a`.
- **SystemConfig owner history** (net change per tx; same-tx round trips through the ProxyAdmin during re-initialisation omitted): 21344310 (2024-12-06) `0x00000000…` -> `0xbea2bc852a160b8547273660e22f4f08c2fa9bbb`; 25573527 (2026-07-20) `0xbea2bc85…` -> `0x9ba6e03d8b90de867373db8cf1a58d2f7f006b3a`; 25834840 (2026-08-25) `0x9ba6e03d…` -> `0x847b5c174615b1b7fdf770882256e2d3e95b9d92`.
- **DisputeGameFactory owner history** (net change per tx; same-tx round trips through the ProxyAdmin during re-initialisation omitted): 21344310 (2024-12-06) `0x00000000…` -> `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a`.
- **AddressManager owner history** (net change per tx; same-tx round trips through the ProxyAdmin during re-initialisation omitted): 21344310 (2024-12-06) `0x00000000…` -> `0xd56045e68956fce2576e680c95a4750cf8241f79`.
- SuperchainConfig: `0x95703e0982140D16f8ebA6d158FccEde42f04a4C` — portal slot 53 already held it at the proxy's first initialised block (shared instance from genesis for the three 2024 chains; OP Mainnet since the 2024-02-26 SuperchainConfig introduction). Guardian `0x9ba6e03d…` (2024-01-22) -> `0x09f7150d…` (2024-06-10), unchanged since (`evidence/F5/superchainconfig-events.json`).

## 4. Custody (ETH) at every upgrade block

| L1 block | Date | Portal before -> after | ETHLockbox before -> after | L1CDM | L1StandardBridge |
|---|---|---|---|---|---|
| 21344310 | 2024-12-06 | 0.000 -> 0.000 | — -> — | 0.000 | 0.000 |
| 22182531 | 2025-04-02 | 9,443.050 -> 9,443.050 | — -> — | 0.000 | 0.000 |
| 22339996 | 2025-04-24 | 9,609.735 -> 9,609.735 | — -> — | 0.000 | 0.000 |
| 22990599 | 2025-07-24 | 6,020.611 -> 0.000 | — -> 6,020.611 | 0.000 | 0.000 |
| 23491328 | 2025-10-02 | 0.000 -> 0.000 | 6,649.408 -> 6,649.408 | 0.000 | 0.000 |
| 23877377 | 2025-11-25 | 0.000 -> 0.000 | 41,099.014 -> 41,099.014 | 0.000 | 0.000 |
| 24421512 | 2026-02-09 | 0.000 -> 0.000 | 28,473.189 -> 28,473.189 | 0.000 | 0.000 |
| 25397811 | 2026-06-25 | 0.000 -> 0.000 | 26,190.818 -> 26,190.818 | 0.000 | 0.000 |
| 26048619 | 2026-09-24 | 0.000 -> 0.000 | 22,846.565 -> 22,846.565 | 0.000 | 0.000 |
| 26430859 | 2026-11-16 | 0.000 -> 0.000 | 23,088.758 -> 23,088.758 | 0.000 | 0.000 |
| 26433900 | 2026-11-17 | 0.000 -> 0.000 | 23,088.758 -> 23,088.758 | 0.000 | 0.000 |

- `ETHMigrated(lockbox=0xbd4abb321138e8eddc399ce64e66451294325a14, amount=6,020.610510 ETH)` at block 22990599 tx `0x46acdce174c8d83ebe2f208d8c76c867e75617483d64c3e407f69ae2f9868716` — the only liquidity migration event of this portal.
- ETHLockbox administrative events since birth: {'AdminChanged(address,address)': 1, 'Upgraded(address)': 11, 'PortalAuthorized(address)': 4, 'Initialized(uint8)': 4} (no `LockboxAuthorized`, `LiquidityMigrated`, `LiquidityReceived`).

## 5. Dispute infrastructure generations

| AnchorStateRegistry | Born | Version now | Games (index range) | Current? | ETH | respectedGameType / retirementTimestamp now |
|---|---|---|---|---|---|---|
| `0xde744491bcf6b2dd2f32146364ea1487d75e2509` | 21344310 (2024-12-06) | 2.0.1-beta.3 | 470 (0..469) | orphaned | 0.0000 | None / None |
| `0x2fc99fd16d8d3f6f66d164aa84e244c567e58a3d` | 22182531 (2025-04-02) | 2.2.2 | 452 (470..921) | orphaned | 0.0000 | 9 / None |
| `0xee018baf058227872540ac60efbd38b023d9dae2` | 22990599 (2025-07-24) | 4.0.0 | 1718 (922..2639) | yes | 0.0000 | 9 / 1753379243 |

| DelayedWETH | Born | Version | Games using it (range) | ETH balance | owner() | SystemConfig-registered? |
|---|---|---|---|---|---|---|
| `0x14773a8040ff22e3dcbb0c83ec8e33be7d920d38` | 21344310 (2024-12-06) | 1.1.0 | 190 (0..191) | 0.000000 | `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a` | no (legacy) |
| `0x3beaca17eae5643fb1479aa5f4b1ff75cc4b9b50` | 21387926 (2024-12-12) | 1.1.0 | 216 (155..405) | 0.080000 | `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a` | no (legacy) |
| `0xf6b1554f483c391414d3830927e3600c105aae6e` | 21995971 (2025-03-07) | 1.3.0 | 516 (406..921) | 0.000000 | `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a` | no (legacy) |
| `0x3f7b07a5d638024a37a776fa228fe90b317af6de` | 22990599 (2025-07-24) | 1.5.0 | 280 (922..1201) | 0.000000 | `None` | no (legacy) |
| `0x6cbd14da021e39a7895ae151ac72ecc9023e87f6` | 23491328 (2025-10-02) | 1.5.0 | 1064 (1202..2265) | 0.000000 | `None` | no (legacy) |
| `0x57b4c29daee99a28e6e86778b499361294c134ea` | 25397811 (2026-06-25) | 2.0.0 | 374 (2266..2639) | 5.710376 | `None` | yes |

Live ASR slot 6 history (`respectedGameType | retirementTimestamp | ethLockbox`), by storage bisection:

| L1 block | Date | respectedGameType | retirementTimestamp | raw |
|---|---|---|---|---|
| 22990599 | 2025-07-24 | 0 | 1753379243 | `0x000000000000000000000000000000000000000000000000688271ab00000000` |
| 25397811 | 2026-06-25 | 8 | 1753379243 | `0x000000000000000000000000000000000000000000000000688271ab00000008` |
| 26048619 | 2026-09-24 | 9 | 1753379243 | `0x000000000000000000000000000000000000000000000000688271ab00000009` |
| 26430859 | 2026-11-16 | 9 | 1753379243 | `0xbd4abb321138e8eddc399ce64e66451294325a1400000000688271ab00000009` |

Portal-era events (pre-U16 respected type lived in the portal): 21682329 (2025-01-22) RespectedGameTypeSet(0, 1737576635).

Game types ever registered (`ImplementationSet` on the DisputeGameFactory):

| L1 block | Date | Tx | type -> implementation |
|---|---|---|---|
| 21344310 | 2024-12-06 | `0x45c2b63987a8c7ab` | 1->`0xa8e6a9bf…` |
| 21618223 | 2025-01-13 | `0x71234ec9d3df3236` | 0->`0x6a8efcba…`, 1->`0x0a780be3…` |
| 22069032 | 2025-03-17 | `0xd80b96282ad4d71a` | 1->`0x8d9faaeb…`, 0->`0x7e87b471…` |
| 22182531 | 2025-04-02 | `0x5f3530e593bbac37` | 1->`0x4699d204…`, 0->`0x69361c91…` |
| 22339996 | 2025-04-24 | `0xbe44244e352a9ffa` | 1->`0x436bac2e…`, 0->`0x499e30a3…` |
| 22432368 | 2025-05-07 | `0xc4a7089a92c96b83` | 0->`0x3ccf7c31…`, 1->`0x40641a40…` |
| 22990599 | 2025-07-24 | `0x46acdce174c8d83e` | 1->`0x46dde051…`, 0->`0x1a20c06a…` |
| 23491328 | 2025-10-02 | `0x744cf7d28324729c` | 1->`0x5562d33b…`, 0->`0x5f5bea59…` |
| 23877377 | 2025-11-25 | `0xf556934cb4de1ab4` | 1->`0x467e6a8d…`, 0->`0x4cbfba0a…` |
| 24421512 | 2026-02-09 | `0x8808cd53114e4cf0` | 1->`0x58bf355c…`, 0->`0x6ddba09b…`, 8->`0x6ddba09b…` |
| 25397811 | 2026-06-25 | `0xbfdac60c9687a2e4` | 0->unset, 1->`0xe1dffcbe…`, 8->`0x2dda3584…`, 4->unset, 5->unset, 9->unset, 10->unset |
| 25674914 | 2026-08-03 | `0x6065d3a2decf0b16` | 1->`0xe1dffcbe…` |
| 26048619 | 2026-09-24 | `0x0a0fe86f7b1a3d3d` | 0->unset, 1->unset, 8->unset, 5->`0x5c3eb47c…`, 9->`0x19af533c…`, 10->unset, 4->unset |
| 26430859 | 2026-11-16 | `0x024770b5fba87683` | 0->unset, 1->unset, 8->unset, 5->`0x5c3eb47c…`, 9->`0x19af533c…`, 10->unset, 4->unset |

Game census at the pinned block (lineage classes):

| type | game version | game's own ASR | DelayedWETH | absolutePrestate | n | index range | created | creators |
|---|---|---|---|---|---|---|---|---|
| 1 | 1.3.1-beta.3 | `0xde744491…` | `0x14773a80…` | `0x038512e0…` | 152 | 0..151 | 2024-12-06..2025-01-13 | `0x65436ddc…`×152 |
| 1 | 1.3.0 | `0xde744491…` | `0x14773a80…` | `0x03c50b9f…` | 38 | 152..191 | 2025-01-13..2025-01-23 | `0x65436ddc…`×38 |
| 0 | 1.3.0 | `0xde744491…` | `0x3beaca17…` | `0x03c50b9f…` | 216 | 155..405 | 2025-01-14..2025-03-17 | `0x65436ddc…`×214, `0x21d6658c…`×2 |
| 0 | 1.3.1 | `0xde744491…` | `0xf6b1554f…` | `0x039facea…` | 64 | 406..469 | 2025-03-17..2025-04-02 | `0x65436ddc…`×64 |
| 0 | 1.4.1 | `0x2fc99fd1…` | `0xf6b1554f…` | `0x039facea…` | 88 | 470..557 | 2025-04-02..2025-04-24 | `0x65436ddc…`×88 |
| 0 | 1.4.1 | `0x2fc99fd1…` | `0xf6b1554f…` | `0x03ee2917…` | 51 | 558..608 | 2025-04-24..2025-05-07 | `0x65436ddc…`×51 |
| 0 | 1.4.1 | `0x2fc99fd1…` | `0xf6b1554f…` | `0x03682932…` | 313 | 609..921 | 2025-05-07..2025-07-24 | `0x65436ddc…`×313 |
| 0 | 1.7.0 | `0xee018baf…` | `0x3f7b07a5…` | `0x03eb0710…` | 280 | 922..1201 | 2025-07-24..2025-10-02 | `0x65436ddc…`×280 |
| 0 | 1.7.0 | `0xee018baf…` | `0x6cbd14da…` | `0x03eb0710…` | 216 | 1202..1417 | 2025-10-02..2025-11-25 | `0x65436ddc…`×216 |
| 0 | 1.8.0 | `0xee018baf…` | `0x6cbd14da…` | `0x03caa187…` | 304 | 1418..1721 | 2025-11-25..2026-02-09 | `0x65436ddc…`×304 |
| 0 | 2.2.0 | `0xee018baf…` | `0x6cbd14da…` | `0x033c0009…` | 544 | 1722..2265 | 2026-02-09..2026-06-25 | `0x65436ddc…`×544 |
| 8 | 2.4.2 | `0xee018baf…` | `0x57b4c29d…` | `0x0337ecb3…` | 256 | 2266..2521 | 2026-06-26..2026-09-24 | `0x65436ddc…`×130, `0x3832bfbe…`×117, `0x0976d8e6…`×9 |
| 9 | 0.8.0 | `0xee018baf…` | `0x57b4c29d…` | `0x031ac6f1…` | 117 | 2522..2638 | 2026-09-24..2026-11-16 | `0x3832bfbe…`×107, `0x0976d8e6…`×7, `0x1d0519ee…`×1, `0xe3b96e68…`×1, `0x05f97bc0…`×1 |
| 9 | 0.8.0 | `0xee018baf…` | `0x57b4c29d…` | `0x03e5a548…` | 1 | 2639..2639 | 2026-11-17..2026-11-17 | `0x3832bfbe…`×1 |

- Games: 2640; retired (createdAt <= retirementTimestamp): 922; claim-valid: 1685; blacklisted: 0; non-retired games whose own ASR is not the live ASR: 0; in progress: 8.
- Header-derived root check of every non-retired game: `{"(0, 'DEFENDER_WINS', True, True)": 1344, "(8, 'DEFENDER_WINS', True, True)": 247, "(8, 'CHALLENGER_WINS', False, 'NO_SUCH_L2_BLOCK')": 9, "(9, 'DEFENDER_WINS', True, True)": 94, "(9, 'CHALLENGER_WINS', False, False)": 9, "(9, 'DEFENDER_WINS', False, True)": 7, "(9, 'IN_PROGRESS', False, True)": 7, "(9, 'IN_PROGRESS', False, False)": 1}`; anomalies: 1.
  - index 2638 type 9 `0x40bec00713a38ee5fd697764d50f0055ba4942cc` creator `0x05f97bc048711287e912a72f4dbaa8faa7599eb5` status IN_PROGRESS claimValid False claimed `0x4bf7a459f2a916c09923fe3d8290e223d982d7d4a4c1f7839952b596ddb6f493` header-derived `0xaf30eecb2fb746b58c5ab9f302e25f16d7118aa05aec7454b869263b7a8aeadb`.

## 6. Legacy slots at the pinned block

| Slot | Raw value |
|---|---|
| OptimismPortal2.slot53 (legacy paused byte | superchainConfig) | `0x000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c00` |
| OptimismPortal2.slot54 (legacy l2Oracle) | `0x0000000000000000000000000000000000000000000000000000000000000000` |
| OptimismPortal2.slot56 (legacy disputeGameFactory) | `0x00000000000000000000000010d7b35078d3baabb96dd45a9143b94be65b12cd` |
| OptimismPortal2.slot59 (legacy respectedGameType | respectedGameTypeUpdatedAt) | `0x000000000000000000000000000000000000000000000000679150bb00000000` |
| OptimismPortal2.slot63 (ethLockbox | legacy superRootsActive byte) | `0x000000000000000000000000bd4abb321138e8eddc399ce64e66451294325a14` |
| L1CrossDomainMessenger.slot51 (legacy OVM owner) | `0x0000000000000000000000000000000000000000000000000000000000000000` |
| L1CrossDomainMessenger.slot151 (legacy reentrancy status) | `0x0000000000000000000000000000000000000000000000000000000000000000` |
| L1CrossDomainMessenger.slot251 (legacy superchainConfig) | `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c` |
| L1StandardBridge.slot1 (legacy l2TokenBridge) | `0x0000000000000000000000000000000000000000000000000000000000000000` |
| L1StandardBridge.slot50 (legacy superchainConfig) | `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c` |
| SystemConfig.slot106 (eip1559Denominator | eip1559Elasticity | operatorFee*) | `0x0000000000000000000000000000000000000000000000000000000000000000` |
| SystemConfig.slot108 (superchainConfig | minBaseFee) | `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c` |
| DelayedWETH.slot4 (legacy config/systemConfig spacer) | `0x00000000000000000000000062c0a111929fa32cec2f76adba54c16afb6e8364` |
