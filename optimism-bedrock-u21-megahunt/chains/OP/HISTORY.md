# OP (chain id 10) — chain history profile (worker F5)

Generated from chain state by `scripts/F5-build-chain-files.py`; every row is a `cast`-equivalent read through the L1 archive proxy `http://127.0.0.1:7545` at or before the pinned block 26433900, or a superchain-registry / superchain-ops file. Raw evidence: `evidence/F5/OP-history-raw.json`, `evidence/F5/OP-upgrade-txs.json`, `evidence/F5/OP-stage2.json`, `evidence/F5/op-games-0-21388.json`, `evidence/F5/op-root-verification.json`.

## 1. Genesis / deployment generation

- Registry: L2 genesis time 1686068903 (2023-06-06 16:28:23 UTC), L1 origin block 17422590, L2 genesis block 105235063, block time 2 s, `superchain_time` = 0, fault proofs (chainList.json): permissionless.
- Hardforks: canyon=1704992401, delta=1708560000, ecotone=1710374401, fjord=1720627201, granite=1726070401, holocene=1736445601, isthmus=1746806401, jovian=1764691201, karst=1783526401, lagoon=1799683201.

| Proxy | Address | First code block | Date (UTC) | First implementation (version) | Admin slot at birth |
|---|---|---|---|---|---|
| SystemConfig | `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` | 17365804 | 2023-05-29 16:23:23 | `0x5efa852e92800d1c982711761e45c3fe39a2b6d8` (1.3.0) | `0x543ba4aadbab8f9025686bd03993043599c6fb04` |
| OptimismPortal | `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` | 17365802 | 2023-05-29 16:22:59 | `0x28a55488fef40005309e2da0040dbe9d300a64ab` (1.6.0) | `0x543ba4aadbab8f9025686bd03993043599c6fb04` |
| ETHLockbox | `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43` | 22990599 | 2025-07-24 17:47:23 | `0x784d2f03593a42a6e4676a012762f18775ecbbe6` (1.2.0) | `0x543ba4aadbab8f9025686bd03993043599c6fb04` |
| AnchorStateRegistry | `0x23B2C62946350F4246f9f9D027e071f0264FD113` | 22990599 | 2025-07-24 17:47:23 | `0xeb69cc681e8d4a557b30dffbad85affd47a2cf2e` (3.5.0) | `0x543ba4aadbab8f9025686bd03993043599c6fb04` |
| DisputeGameFactory | `0xe5965Ab5962eDc7477C8520243A95517CD252fA9` | 19884569 | 2024-05-16 19:17:23 | `0xc641a33cab81c559f2bd4b21ea34c290e2440c2b` (1.0.0) | `0xf2fbae9b080ae2ac24a56cf456636804fa54db29` |
| DelayedWETH | `0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162` | 25397811 | 2026-06-25 23:05:47 | `0xe440cc08a71694c8229323803f59024e3144630e` (1.5.1) | `0x543ba4aadbab8f9025686bd03993043599c6fb04` |
| L1CrossDomainMessenger | `0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1` | 12686757 | 2021-06-22 22:29:57 | `0x16393737d09d2722ad13dca3ca8c3db957699f1d` (<none>) | `0x0000000000000000000000000000000000000000` |
| L1StandardBridge | `0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1` | 12686786 | 2021-06-22 22:37:44 | `0x9091dda480b232133a7d2e4cb23336b4f0293196` (<no version(); codeSize 5525>) | `0x9996571372066a1545d3435c6935e3f9593a7ef5` |
| L1ERC721Bridge | `0x5a7749f83b81B301cAb5f48EB8516B986DAef23D` | 15677422 | 2022-10-04 21:23:11 | `0x3268ed09f76e619331528270b6267d4d2c5ab5c2` (1.0.0) | `0x53a6eecc2dd4795fcc68940ddc6b4d53bd88bd9e` |
| OptimismMintableERC20Factory | `0x75505a97BD334E7BD3C476893285569C4136Fa0F` | 17365803 | 2023-05-29 16:23:11 | `0xae849efa4bcfc419593420e14707996936e365e2` (1.1.0) | `0x543ba4aadbab8f9025686bd03993043599c6fb04` |
| ProxyAdmin | `0x543bA4AADBAb8f9025686Bd03993043599c6fB04` | 17365800 | 2023-05-29 16:22:35 | `None` (None) | `None` |
| AddressManager | `0xde1fcfb0851916ca5101820a69b13a4e276bd81f` | 12686687 | 2021-06-22 22:13:53 | `None` (None) | `None` |

## 2. Upgrade path (every implementation change)

`*` = a StorageSetter implementation was installed first in the same transaction (re-initialisation cycle). Task = superchain-ops task whose README status line names this tx (mapping from `evidence/F2-superchain-ops-tasks.json`).

| L1 block | Date | Tx | superchain-ops task | Proxies -> version |
|---|---|---|---|---|
| 17422444 | 2023-06-06 | `0x76bceccd7d44656f` | — | SystemConfig=1.3.0, L1CrossDomainMessenger=<none> |
| 17423158 | 2023-06-06 | `0xe2ff41f9bdf03d54` | — | OptimismPortal=1.6.0, L1ERC721Bridge=1.0.0, OptimismMintableERC20Factory=1.1.0, L1CrossDomainMessenger=1.4.0, L1StandardBridge=1.1.0 |
| 19314493 | 2024-02-26 | `0x3f7c36a1d636cdb2` | 004-add-superchainConfig | SystemConfig=1.11.0*, OptimismPortal=2.4.0*, L1ERC721Bridge=2.0.0*, OptimismMintableERC20Factory=1.8.0*, L1CrossDomainMessenger=2.2.0*, L1StandardBridge=2.0.0 |
| 19634866 | 2024-04-11 | `0x4758bd62359bc69d` | 006-MCP-L1 | SystemConfig=1.12.0*, OptimismPortal=2.5.0*, L1ERC721Bridge=2.1.0*, OptimismMintableERC20Factory=1.9.0*, L1CrossDomainMessenger=2.3.0*, L1StandardBridge=2.1.0 |
| 19884570 | 2024-05-16 | `0x2c16c813ff50e9e0` | — | DisputeGameFactory=1.0.0 |
| 20062696 | 2024-06-10 | `0xbe810ed6e1e82793` | 009-fp-upgrade | SystemConfig=2.2.0*, OptimismPortal=3.10.0* |
| 21695024 | 2025-01-24 | `0x86da7386a26978c3` | 028-holocene-system-config-upgrade-and-init-multi-chain | SystemConfig=2.3.0* |
| 22182531 | 2025-04-02 | `0x5f3530e593bbac37` | 000-opcm-upgrade-v200 | SystemConfig=2.4.0, OptimismPortal=3.13.0, DisputeGameFactory=1.0.1, L1ERC721Bridge=2.3.1, OptimismMintableERC20Factory=1.10.1, L1CrossDomainMessenger=2.5.0, L1StandardBridge=2.2.2 |
| 22339996 | 2025-04-24 | `0xbe44244e352a9ffa` | 003-opcm-upgrade-v300-op-ink-soneium | SystemConfig=2.5.0, OptimismPortal=3.14.0, L1ERC721Bridge=2.4.0, L1CrossDomainMessenger=2.6.0, L1StandardBridge=2.3.0 |
| 22990599 | 2025-07-24 | `0x46acdce174c8d83e` | 017-U16-opcm-upgrade-v400-op-ink | SystemConfig=3.4.0, OptimismPortal=4.6.0, ETHLockbox=1.2.0, AnchorStateRegistry=3.5.0, DisputeGameFactory=1.2.0, L1ERC721Bridge=2.7.0, L1CrossDomainMessenger=2.9.0, L1StandardBridge=2.6.0 |
| 23491328 | 2025-10-02 | `0x744cf7d28324729c` | 023-U16a-opcm-upgrade-v410-op-soneium-ink | SystemConfig=3.7.0, OptimismPortal=5.0.0, AnchorStateRegistry=3.5.0, DisputeGameFactory=1.2.0, L1ERC721Bridge=2.8.0, L1CrossDomainMessenger=2.10.0, L1StandardBridge=2.7.0 |
| 23877377 | 2025-11-25 | `0xf556934cb4de1ab4` | 032-U17-main-op-sony-ink | SystemConfig=3.11.0, OptimismPortal=5.1.1, DisputeGameFactory=1.3.0, L1ERC721Bridge=2.9.0, OptimismMintableERC20Factory=1.10.2, L1CrossDomainMessenger=2.11.0, L1StandardBridge=2.8.0 |
| 24421512 | 2026-02-09 | `0x8808cd53114e4cf0` | 040-U18-op-ink-mmz-arena-swell | SystemConfig=3.13.1, OptimismPortal=5.2.0, AnchorStateRegistry=3.7.0, DisputeGameFactory=1.4.0, L1ERC721Bridge=2.9.0, OptimismMintableERC20Factory=1.10.2, L1CrossDomainMessenger=2.11.0 |
| 25397811 | 2026-06-25 | `0xbfdac60c9687a2e4` | 053-U19-op-ink-mmz-soneium | SystemConfig=3.14.2*, OptimismPortal=5.6.1*, ETHLockbox=1.3.1*, AnchorStateRegistry=3.9.0*, DisputeGameFactory=1.6.1*, DelayedWETH=1.5.1*, L1ERC721Bridge=2.9.1*, OptimismMintableERC20Factory=1.11.0*, L1CrossDomainMessenger=2.11.1*, L1StandardBridge=2.8.2 |
| 26048619 | 2026-09-24 | `0x0a0fe86f7b1a3d3d` | 071-U20-op-ink-soneium-uni | SystemConfig=4.0.0*, OptimismPortal=5.8.0*, ETHLockbox=1.3.1*, AnchorStateRegistry=3.9.0*, DisputeGameFactory=1.6.1*, DelayedWETH=1.5.1*, L1ERC721Bridge=2.9.1*, OptimismMintableERC20Factory=1.11.0*, L1CrossDomainMessenger=2.11.1* |
| 26309074 | 2026-10-31 | `0xd80476b3ec562837` | — | OptimismPortal=5.8.0 |
| 26430859 | 2026-11-16 | `0x024770b5fba87683` | 084-U21-op-ink-soneium-uni | SystemConfig=4.3.0*, OptimismPortal=6.1.0*, ETHLockbox=2.0.0*, AnchorStateRegistry=4.0.0*, DisputeGameFactory=1.6.1*, DelayedWETH=2.0.0*, L1ERC721Bridge=2.9.1*, OptimismMintableERC20Factory=1.11.0*, L1CrossDomainMessenger=2.13.0* |

Cross-check against F2's independent slot-sampling history (`evidence/F2-impl-history-op-mainnet.json`): 93 (proxy, block, implementation) entries compared, 14 mismatches.

`lastUsedOPCM` (SystemConfig) sampled at each upgrade block:

| L1 block | lastUsedOPCM | version |
|---|---|---|
| 23491328 | `None` | None |
| 23877377 | `None` | None |
| 24421512 | `None` | None |
| 25397811 | `0x9ce712ff84e02659846dc6450bb9b7642fe8be5d` | 7.1.17 |
| 26048619 | `0x1951828ce913dc4383a8a1695695d537a11d896a` | 8.0.1 |
| 26309074 | `0x1951828ce913dc4383a8a1695695d537a11d896a` | 8.0.1 |
| 26430859 | `0x2d91e6f2bcf6cd1df90e1faf9714e18705ea331f` | 9.0.3 |

## 3. Ownership, guardian, SuperchainConfig

- **ProxyAdmin owner history** (net change per tx; same-tx round trips through the ProxyAdmin during re-initialisation omitted): 17365800 (2023-05-29) `0x00000000…` -> `0x354f3f4ecdca5e0a7ace08d71348cdc1dab48960`; 17381274 (2023-05-31) `0x354f3f4e…` -> `0x9ba6e03d8b90de867373db8cf1a58d2f7f006b3a`; 17422444 (2023-06-06) `0x9ba6e03d…` -> `0xb4453ceb33d2e67fa244a24acf2e50cef31f53cb`; 17423158 (2023-06-06) `0xb4453ceb…` -> `0x9ba6e03d8b90de867373db8cf1a58d2f7f006b3a`; 19193284 (2024-02-09) `0x9ba6e03d…` -> `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a`.
- **SystemConfig owner history** (net change per tx; same-tx round trips through the ProxyAdmin during re-initialisation omitted): 17422444 (2023-06-06) `0x00000000…` -> `0x9ba6e03d8b90de867373db8cf1a58d2f7f006b3a`; 20186225 (2024-06-27) `0x9ba6e03d…` -> `0x847b5c174615b1b7fdf770882256e2d3e95b9d92`.
- **DisputeGameFactory owner history** (net change per tx; same-tx round trips through the ProxyAdmin during re-initialisation omitted): 19884570 (2024-05-16) `0x00000000…` -> `0xf2fbae9b080ae2ac24a56cf456636804fa54db29`; 19884592 (2024-05-16) `0xf2fbae9b…` -> `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a`.
- **AddressManager owner history** (net change per tx; same-tx round trips through the ProxyAdmin during re-initialisation omitted): 12686687 (2021-06-22) `0x00000000…` -> `0x9996571372066a1545d3435c6935e3f9593a7ef5`; 12686795 (2021-06-22) `0x99965713…` -> `0x9ba6e03d8b90de867373db8cf1a58d2f7f006b3a`; 13596773 (2021-11-11) `0x9ba6e03d…` -> `0x7a74f7934a233e10e8757264132b2e4ebccf5098`; 13596781 (2021-11-11) `0x7a74f793…` -> `0x9ba6e03d8b90de867373db8cf1a58d2f7f006b3a`; 17422444 (2023-06-06) `0x9ba6e03d…` -> `0xb4453ceb33d2e67fa244a24acf2e50cef31f53cb`; 17423158 (2023-06-06) `0xb4453ceb…` -> `0x543ba4aadbab8f9025686bd03993043599c6fb04`.
- SuperchainConfig: `0x95703e0982140D16f8ebA6d158FccEde42f04a4C` — portal slot 53 already held it at the proxy's first initialised block (shared instance from genesis for the three 2024 chains; OP Mainnet since the 2024-02-26 SuperchainConfig introduction). Guardian `0x9ba6e03d…` (2024-01-22) -> `0x09f7150d…` (2024-06-10), unchanged since (`evidence/F5/superchainconfig-events.json`).

## 4. Custody (ETH) at every upgrade block

| L1 block | Date | Portal before -> after | ETHLockbox before -> after | L1CDM | L1StandardBridge |
|---|---|---|---|---|---|
| 17422444 | 2023-06-06 | 0.000 -> 0.000 | — -> — | 0.000 | 293,288.257 |
| 17423158 | 2023-06-06 | 0.000 -> 293,288.257 | — -> — | 0.000 | 0.000 |
| 19314493 | 2024-02-26 | 354,469.951 -> 354,469.951 | — -> — | 0.000 | 0.000 |
| 19634866 | 2024-04-11 | 417,432.038 -> 417,432.038 | — -> — | 0.000 | 0.000 |
| 19884570 | 2024-05-16 | 462,419.098 -> 462,419.098 | — -> — | 0.000 | 0.000 |
| 20062696 | 2024-06-10 | 483,123.829 -> 483,123.829 | — -> — | 0.000 | 0.000 |
| 21695024 | 2025-01-24 | 545,893.458 -> 545,893.458 | — -> — | 0.000 | 0.000 |
| 22182531 | 2025-04-02 | 483,805.267 -> 483,805.267 | — -> — | 0.000 | 0.000 |
| 22339996 | 2025-04-24 | 301,511.525 -> 301,511.525 | — -> — | 0.000 | 0.000 |
| 22990599 | 2025-07-24 | 236,752.243 -> 0.000 | — -> 236,752.243 | 0.000 | 0.000 |
| 23491328 | 2025-10-02 | 0.000 -> 0.000 | 184,285.651 -> 184,285.651 | 0.000 | 0.000 |
| 23877377 | 2025-11-25 | 0.000 -> 0.000 | 203,290.192 -> 203,290.192 | 0.000 | 0.000 |
| 24421512 | 2026-02-09 | 0.000 -> 0.000 | 214,111.932 -> 214,111.932 | 0.000 | 0.000 |
| 25397811 | 2026-06-25 | 0.000 -> 0.000 | 177,196.877 -> 177,196.877 | 0.000 | 0.000 |
| 26048619 | 2026-09-24 | 0.000 -> 0.000 | 180,279.048 -> 180,279.048 | 0.000 | 0.000 |
| 26309074 | 2026-10-31 | 0.000 -> 0.000 | 180,126.427 -> 180,126.427 | 0.000 | 0.000 |
| 26430859 | 2026-11-16 | 0.000 -> 0.000 | 182,416.307 -> 182,420.511 | 0.000 | 0.000 |
| 26433900 | 2026-11-17 | 0.000 -> 0.000 | 182,541.068 -> 182,541.068 | 0.000 | 0.000 |

- `ETHMigrated(lockbox=0x322b47ff1fa8d5611f761e3e275c45b71b294d43, amount=236,752.243072 ETH)` at block 22990599 tx `0x46acdce174c8d83ebe2f208d8c76c867e75617483d64c3e407f69ae2f9868716` — the only liquidity migration event of this portal.
- ETHLockbox administrative events since birth: {'AdminChanged(address,address)': 1, 'Upgraded(address)': 11, 'PortalAuthorized(address)': 4, 'Initialized(uint8)': 4} (no `LockboxAuthorized`, `LiquidityMigrated`, `LiquidityReceived`).

## 5. Dispute infrastructure generations

| AnchorStateRegistry | Born | Version now | Games (index range) | Current? | ETH | respectedGameType / retirementTimestamp now |
|---|---|---|---|---|---|---|
| `0x18dac71c228d1c32c99489b7323d441e1175e443` | 19884569 (2024-05-16) | 2.0.0 | 7110 (0..7109) | orphaned | 0.0000 | None / None |
| `0x1c68ecfbf9c8b1e6c0677965b3b9ecf9a104305b` | 22182531 (2025-04-02) | 2.2.2 | 2718 (7110..9827) | orphaned | 0.0000 | 9 / None |
| `0x23b2c62946350f4246f9f9d027e071f0264fd113` | 22990599 (2025-07-24) | 4.0.0 | 11561 (9828..21388) | yes | 0.0000 | 9 / 1753379243 |

| DelayedWETH | Born | Version | Games using it (range) | ETH balance | owner() | SystemConfig-registered? |
|---|---|---|---|---|---|---|
| `0xe497b094d6dbb3d5e4caac9a14696d7572588d14` | 19884569 (2024-05-16) | 1.0.0 | 2237 (0..2236) | 0.160000 | `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a` | no (legacy) |
| `0x9f9b897e37de5052cd70db6d08474550ddb07f39` | 20637594 (2024-08-29) | 1.1.0 | 16 (2237..2252) | 0.000000 | `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a` | no (legacy) |
| `0x82511d494b5c942be57498a70fdd7184ee33b975` | 20637593 (2024-08-29) | 1.1.0 | 2845 (2253..5097) | 0.080000 | `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a` | no (legacy) |
| `0x323dfc63c9b83cb83f40325aab74b245937cbdf0` | 21379271 (2024-12-11) | 1.3.0 | 4730 (5098..9827) | 0.080000 | `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a` | no (legacy) |
| `0xe214879ad573693a4c49f7654449caa455cde34f` | 22990599 (2025-07-24) | 1.5.0 | 1679 (9828..11506) | 0.000000 | `None` | no (legacy) |
| `0xd061ab95069987868768818cc1248705351e2d0e` | 23491328 (2025-10-02) | 1.5.0 | 6398 (11507..17904) | 0.000000 | `None` | no (legacy) |
| `0x1b6dbf05eaf22d4e70dc993e8a19dd9f3dcb3162` | 25397811 (2026-06-25) | 2.0.0 | 3484 (17905..21388) | 20.662782 | `None` | yes |

Live ASR slot 6 history (`respectedGameType | retirementTimestamp | ethLockbox`), by storage bisection:

| L1 block | Date | respectedGameType | retirementTimestamp | raw |
|---|---|---|---|---|
| 22990599 | 2025-07-24 | 0 | 1753379243 | `0x000000000000000000000000000000000000000000000000688271ab00000000` |
| 25397811 | 2026-06-25 | 8 | 1753379243 | `0x000000000000000000000000000000000000000000000000688271ab00000008` |
| 26048619 | 2026-09-24 | 9 | 1753379243 | `0x000000000000000000000000000000000000000000000000688271ab00000009` |
| 26430859 | 2026-11-16 | 9 | 1753379243 | `0x322b47ff1fa8d5611f761e3e275c45b71b294d4300000000688271ab00000009` |

Portal-era events (pre-U16 respected type lived in the portal): 17423158 (2023-06-06) Unpaused( 9ba6e03d8b90de867373db8cf1a58d2f7f006b3a); 19233786 (2024-02-15) Paused( 9ba6e03d8b90de867373db8cf1a58d2f7f006b3a); 19234082 (2024-02-15) Unpaused( 9ba6e03d8b90de867373db8cf1a58d2f7f006b3a); 20543021 (2024-08-16) RespectedGameTypeSet(1, 1723833359); 20728464 (2024-09-11) RespectedGameTypeSet(0, 1726070915).

Game types ever registered (`ImplementationSet` on the DisputeGameFactory):

| L1 block | Date | Tx | type -> implementation |
|---|---|---|---|
| 19884592 | 2024-05-16 | `0x4bc2e27452a7ffab` | 0->`0x4146df64…` |
| 19884592 | 2024-05-16 | `0xecd85766224e3bad` | 1->`0xe9dad167…` |
| 20270847 | 2024-07-09 | `0x7abecacd8b1a54db` | 0->`0xf691f8a6…`, 1->`0xc307e93a…` |
| 20723924 | 2024-09-11 | `0x3bd2d811d0298313` | 0->`0xa6f3dfdb…`, 1->`0x050ed6f6…` |
| 21580854 | 2025-01-08 | `0x22ab07b0bb1bc850` | 1->`0x91a66189…`, 0->`0x27b81db4…` |
| 22182531 | 2025-04-02 | `0x5f3530e593bbac37` | 1->`0xd113ad13…`, 0->`0xba94955c…` |
| 22339996 | 2025-04-24 | `0xbe44244e352a9ffa` | 1->`0x1ae178eb…`, 0->`0x5738a876…` |
| 22432368 | 2025-05-07 | `0xc4a7089a92c96b83` | 0->`0x89d68b1d…`, 1->`0xa1e0bacd…` |
| 22990599 | 2025-07-24 | `0x46acdce174c8d83e` | 1->`0xecca4bfb…`, 0->`0xd73dd0f5…` |
| 23491328 | 2025-10-02 | `0x744cf7d28324729c` | 1->`0xbf2027a1…`, 0->`0x22f2afb8…` |
| 23877377 | 2025-11-25 | `0xf556934cb4de1ab4` | 1->`0x8081fab7…`, 0->`0x478c2610…` |
| 24421512 | 2026-02-09 | `0x8808cd53114e4cf0` | 1->`0x58bf355c…`, 0->`0x6ddba09b…`, 8->`0x6ddba09b…` |
| 25397811 | 2026-06-25 | `0xbfdac60c9687a2e4` | 0->unset, 1->`0xe1dffcbe…`, 8->`0x2dda3584…`, 4->unset, 5->unset, 9->unset, 10->unset |
| 26048619 | 2026-09-24 | `0x0a0fe86f7b1a3d3d` | 0->unset, 1->unset, 8->unset, 5->`0x5c3eb47c…`, 9->`0x19af533c…`, 10->unset, 4->unset |
| 26430859 | 2026-11-16 | `0x024770b5fba87683` | 0->unset, 1->unset, 8->unset, 5->`0x5c3eb47c…`, 9->`0x19af533c…`, 10->unset, 4->unset |

Game census at the pinned block (lineage classes):

| type | game version | game's own ASR | DelayedWETH | absolutePrestate | n | index range | created | creators |
|---|---|---|---|---|---|---|---|---|
| 0 | 1.2.0 | `0x18dac71c…` | `0xe497b094…` | `0x037ef3c1…` | 709 | 0..708 | 2024-05-16..2024-07-09 | `0x473300df…`×698, `0xaa08d454…`×7, `0xf2fbae9b…`×3, `0x64d8b3da…`×1 |
| 0 | 1.2.0 | `0x18dac71c…` | `0xe497b094…` | `0x03617abe…` | 927 | 709..2089 | 2024-07-09..2024-09-04 | `0x473300df…`×918, `0xaa08d454…`×9 |
| 1 | 1.2.0 | `0x18dac71c…` | `0xe497b094…` | `0x03617abe…` | 601 | 1633..2236 | 2024-08-16..2024-09-10 | `0x473300df…`×601 |
| 1 | 1.3.0 | `0x18dac71c…` | `0x9f9b897e…` | `0x038512e0…` | 16 | 2237..2252 | 2024-09-11..2024-09-11 | `0x473300df…`×16 |
| 0 | 1.3.0 | `0x18dac71c…` | `0x82511d49…` | `0x038512e0…` | 2845 | 2253..5097 | 2024-09-11..2025-01-08 | `0x473300df…`×2827, `0xaa08d454…`×17, `0x39440057…`×1 |
| 0 | 1.3.1 | `0x18dac71c…` | `0x323dfc63…` | `0x03f89406…` | 2012 | 5098..7109 | 2025-01-08..2025-04-02 | `0x473300df…`×1999, `0xaa08d454…`×12, `0x7cfed2a2…`×1 |
| 0 | 1.4.1 | `0x1c68ecfb…` | `0x323dfc63…` | `0x039facea…` | 529 | 7110..7638 | 2025-04-02..2025-04-24 | `0x473300df…`×525, `0xaa08d454…`×4 |
| 0 | 1.4.1 | `0x1c68ecfb…` | `0x323dfc63…` | `0x03ee2917…` | 310 | 7639..7948 | 2025-04-24..2025-05-07 | `0x473300df…`×309, `0xaa08d454…`×1 |
| 0 | 1.4.1 | `0x1c68ecfb…` | `0x323dfc63…` | `0x03682932…` | 1879 | 7949..9827 | 2025-05-07..2025-07-24 | `0x473300df…`×1867, `0xaa08d454…`×11, `0xc37f6a6c…`×1 |
| 0 | 1.7.0 | `0x23b2c629…` | `0xe214879a…` | `0x03eb0710…` | 1679 | 9828..11506 | 2025-07-24..2025-10-02 | `0x473300df…`×1669, `0xaa08d454…`×10 |
| 0 | 1.7.0 | `0x23b2c629…` | `0xd061ab95…` | `0x03eb0710…` | 1298 | 11507..12804 | 2025-10-02..2025-11-25 | `0x473300df…`×1291, `0xaa08d454…`×7 |
| 0 | 1.8.0 | `0x23b2c629…` | `0xd061ab95…` | `0x03caa187…` | 1828 | 12805..14632 | 2025-11-25..2026-02-09 | `0x473300df…`×1817, `0xaa08d454…`×11 |
| 0 | 2.2.0 | `0x23b2c629…` | `0xd061ab95…` | `0x033c0009…` | 3272 | 14633..17904 | 2026-02-09..2026-06-25 | `0x473300df…`×3252, `0xaa08d454…`×20 |
| 8 | 2.4.2 | `0x23b2c629…` | `0x1b6dbf05…` | `0x0337ecb3…` | 2190 | 17905..20094 | 2026-06-25..2026-09-24 | `0x473300df…`×2167, `0xaa08d454…`×13, `0x34e0f440…`×2, `0x4cea68bf…`×2, `0x9a2e021d…`×1, `0x86205ad7…`×1 |
| 9 | 0.8.0 | `0x23b2c629…` | `0x1b6dbf05…` | `0x031ac6f1…` | 1283 | 20095..21377 | 2026-09-24..2026-11-16 | `0x473300df…`×1272, `0xaa08d454…`×6, `0x6842ec29…`×1, `0x0bce8d03…`×1, `0x1d0519ee…`×1, `0x7813cc25…`×1 |
| 9 | 0.8.0 | `0x23b2c629…` | `0x1b6dbf05…` | `0x03e5a548…` | 11 | 21378..21388 | 2026-11-16..2026-11-17 | `0xc27ba3e0…`×10, `0x473300df…`×1 |

- Games: 21389; retired (createdAt <= retirementTimestamp): 9828; claim-valid: 11312; blacklisted: 0; non-retired games whose own ASR is not the live ASR: 0; in progress: 85.
- Header-derived root check of every non-retired game: `{"(0, 'DEFENDER_WINS', True, True)": 8029, "(0, 'CHALLENGER_WINS', False, 'NO_SUCH_L2_BLOCK')": 48, "(8, 'DEFENDER_WINS', True, True)": 2168, "(8, 'CHALLENGER_WINS', False, 'NO_SUCH_L2_BLOCK')": 16, "(8, 'CHALLENGER_WINS', False, False)": 6, "(9, 'DEFENDER_WINS', True, True)": 1115, "(9, 'CHALLENGER_WINS', False, 'NO_SUCH_L2_BLOCK')": 2, "(9, 'CHALLENGER_WINS', False, False)": 8, "(9, 'DEFENDER_WINS', False, True)": 84, "(9, 'IN_PROGRESS', False, True)": 85}`; anomalies: 0.

## 6. Legacy slots at the pinned block

| Slot | Raw value |
|---|---|
| OptimismPortal2.slot53 (legacy paused byte | superchainConfig) | `0x000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c00` |
| OptimismPortal2.slot54 (legacy l2Oracle) | `0x000000000000000000000000dfe97868233d1aa22e815a266982f2cf17685a27` |
| OptimismPortal2.slot56 (legacy disputeGameFactory) | `0x000000000000000000000000e5965ab5962edc7477c8520243a95517cd252fa9` |
| OptimismPortal2.slot59 (legacy respectedGameType | respectedGameTypeUpdatedAt) | `0x00000000000000000000000000000000000000000000000066e1c08300000000` |
| OptimismPortal2.slot63 (ethLockbox | legacy superRootsActive byte) | `0x000000000000000000000000322b47ff1fa8d5611f761e3e275c45b71b294d43` |
| L1CrossDomainMessenger.slot51 (legacy OVM owner) | `0x0000000000000000000000009ba6e03d8b90de867373db8cf1a58d2f7f006b3a` |
| L1CrossDomainMessenger.slot151 (legacy reentrancy status) | `0x0000000000000000000000000000000000000000000000000000000000000001` |
| L1CrossDomainMessenger.slot251 (legacy superchainConfig) | `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c` |
| L1StandardBridge.slot1 (legacy l2TokenBridge) | `0x0000000000000000000000004200000000000000000000000000000000000010` |
| L1StandardBridge.slot50 (legacy superchainConfig) | `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c` |
| SystemConfig.slot106 (eip1559Denominator | eip1559Elasticity | operatorFee*) | `0x00000000000000000000000000000000000000000000000000000002000000fa` |
| SystemConfig.slot108 (superchainConfig | minBaseFee) | `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c` |
| DelayedWETH.slot4 (legacy config/systemConfig spacer) | `0x000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb290` |
