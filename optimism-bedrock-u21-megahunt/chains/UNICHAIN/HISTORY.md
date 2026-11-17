# UNICHAIN (chain id 130) — chain history profile (worker F5)

Generated from chain state by `scripts/F5-build-chain-files.py`; every row is a `cast`-equivalent read through the L1 archive proxy `http://127.0.0.1:7545` at or before the pinned block 26433900, or a superchain-registry / superchain-ops file. Raw evidence: `evidence/F5/UNICHAIN-history-raw.json`, `evidence/F5/UNICHAIN-upgrade-txs.json`, `evidence/F5/UNICHAIN-stage2.json`, `evidence/F5/unichain-games-0-17690.json`, `evidence/F5/unichain-root-verification.json`.

## 1. Genesis / deployment generation

- Registry: L2 genesis time 1730748359 (2024-11-04 19:25:59 UTC), L1 origin block 21116363, L2 genesis block 0, block time 1 s, `superchain_time` = 0, fault proofs (chainList.json): permissionless.
- Hardforks: canyon=0, delta=0, ecotone=0, fjord=0, granite=0, holocene=1736445601, isthmus=1746806401, jovian=1764691201, karst=1783526401, lagoon=1799683201.

| Proxy | Address | First code block | Date (UTC) | First implementation (version) | Admin slot at birth |
|---|---|---|---|---|---|
| SystemConfig | `0xc407398d063f942febbcc6f80a156b47f3f1bda6` | 21116351 | 2024-11-04 19:23:35 | `0xf56d96b2535b932656d3c04ebf51babff241d886` (2.2.0) | `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4` |
| OptimismPortal | `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` | 21116350 | 2024-11-04 19:23:23 | `0xe2f826324b2faf99e513d16d266c3f80ae87832b` (3.10.0) | `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4` |
| ETHLockbox | `0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5` | 22990722 | 2025-07-24 18:12:11 | `0x784d2f03593a42a6e4676a012762f18775ecbbe6` (1.2.0) | `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4` |
| AnchorStateRegistry | `0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9` | 22990722 | 2025-07-24 18:12:11 | `0xeb69cc681e8d4a557b30dffbad85affd47a2cf2e` (3.5.0) | `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4` |
| DisputeGameFactory | `0x2F12d621a16e2d3285929C9996f478508951dFe4` | 21116356 | 2024-11-04 19:24:35 | `0xc641a33cab81c559f2bd4b21ea34c290e2440c2b` (1.0.0) | `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4` |
| DelayedWETH | `0x74ad145aC900F1DD5551F0C9E143314DC4022FCf` | 25475307 | 2026-07-06 18:32:35 | `0xe440cc08a71694c8229323803f59024e3144630e` (1.5.1) | `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4` |
| L1CrossDomainMessenger | `0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6` | 21116353 | 2024-11-04 19:23:59 | `0xd3494713a5cfad3f5359379dfa074e2ac8c6fd65` (2.3.0) | `0x0000000000000000000000000000000000000000` |
| L1StandardBridge | `0x81014F44b0a345033bB2b3B21C7a1A308B35fEeA` | 21116352 | 2024-11-04 19:23:47 | `0x64b5a5ed26dcb17370ff4d33a8d503f0fbd06cff` (2.1.0) | `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4` |
| L1ERC721Bridge | `0xD04D0D87E0bd4D2E50286760a3EF323FeA6849Cf` | 21116355 | 2024-11-04 19:24:23 | `0xae2af01232a6c4a4d3012c5ec5b1b35059caf10d` (2.1.0) | `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4` |
| OptimismMintableERC20Factory | `0xA2B597EaeAcb6F627e088cbEaD319e934ED5edad` | 21116354 | 2024-11-04 19:24:11 | `0xe01efbeb1089d1d1db9c6c8b135c934c0734c846` (1.9.0) | `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4` |
| ProxyAdmin | `0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4` | 21116348 | 2024-11-04 19:22:59 | `None` (None) | `None` |
| AddressManager | `0x8098f676033a377b9defe302e9fe6877cd63d575` | 21116347 | 2024-11-04 19:22:47 | `None` (None) | `None` |

## 2. Upgrade path (every implementation change)

`*` = a StorageSetter implementation was installed first in the same transaction (re-initialisation cycle). Task = superchain-ops task whose README status line names this tx (mapping from `evidence/F2-superchain-ops-tasks.json`).

| L1 block | Date | Tx | superchain-ops task | Proxies -> version |
|---|---|---|---|---|
| 21116362 | 2024-11-04 | `0x1623e586faeda506` | — | OptimismPortal=3.10.0 |
| 21116363 | 2024-11-04 | `0xb9a9cca69cc08ba5` | — | SystemConfig=2.2.0 |
| 21116366 | 2024-11-04 | `n/a (slot bisectio` | — | L1StandardBridge=2.1.0 |
| 21116367 | 2024-11-04 | `0xb432a9b2f5b368a8` | — | L1ERC721Bridge=2.1.0 |
| 21116368 | 2024-11-04 | `0x14bd9cb3f3d081f9` | — | OptimismMintableERC20Factory=1.9.0 |
| 21116371 | 2024-11-04 | `0x9efd53c7ecef0094` | — | L1CrossDomainMessenger=2.3.0 |
| 21116372 | 2024-11-04 | `0x742808a336fb214d` | — | DisputeGameFactory=1.0.0 |
| 22081789 | 2025-03-19 | `0x191505a1bff29cc4` | unichain-001-holocene-systemconfig-update | SystemConfig=2.3.0* |
| 22254924 | 2025-04-12 | `0x7e5e478cafbe3029` | 002-opcm-upgrade-v200 | SystemConfig=2.4.0, OptimismPortal=3.13.0, DisputeGameFactory=1.0.1, L1ERC721Bridge=2.3.1, OptimismMintableERC20Factory=1.10.1, L1CrossDomainMessenger=2.5.0, L1StandardBridge=2.2.2 |
| 22342667 | 2025-04-25 | `0xc74c5e0dddfa9e2d` | 005-opcm-upgrade-v300-uni | SystemConfig=2.5.0, OptimismPortal=3.14.0, L1ERC721Bridge=2.4.0, L1CrossDomainMessenger=2.6.0, L1StandardBridge=2.3.0 |
| 22990722 | 2025-07-24 | `0x1f1f283ad793a901` | 019-U16-opcm-upgrade-v400-uni | SystemConfig=3.4.0, OptimismPortal=4.6.0, ETHLockbox=1.2.0, AnchorStateRegistry=3.5.0, DisputeGameFactory=1.2.0, L1ERC721Bridge=2.7.0, L1CrossDomainMessenger=2.9.0, L1StandardBridge=2.6.0 |
| 23492571 | 2025-10-02 | `0xc98240172fa3950e` | 024-U16a-opcm-upgrade-v410-unichain | SystemConfig=3.7.0, OptimismPortal=5.0.0, AnchorStateRegistry=3.5.0, DisputeGameFactory=1.2.0, L1ERC721Bridge=2.8.0, L1CrossDomainMessenger=2.10.0, L1StandardBridge=2.7.0 |
| 23878509 | 2025-11-25 | `0x7c9e6b65258838fb` | 035-U17-main-unichain | SystemConfig=3.11.0, OptimismPortal=5.1.1, DisputeGameFactory=1.3.0, L1ERC721Bridge=2.9.0, OptimismMintableERC20Factory=1.10.2, L1CrossDomainMessenger=2.11.0, L1StandardBridge=2.8.0 |
| 24427874 | 2026-02-10 | `0x5672a02ba8c40bd3` | 041-U18-uni | SystemConfig=3.13.1, OptimismPortal=5.2.0, AnchorStateRegistry=3.7.0, DisputeGameFactory=1.4.0, L1ERC721Bridge=2.9.0, OptimismMintableERC20Factory=1.10.2, L1CrossDomainMessenger=2.11.0 |
| 25475307 | 2026-07-06 | `0xb3c65cbf6285d4b3` | 054-U19-unichain | SystemConfig=3.14.2*, OptimismPortal=5.6.1*, ETHLockbox=1.3.1*, AnchorStateRegistry=3.9.0*, DisputeGameFactory=1.6.1*, DelayedWETH=1.5.1*, L1ERC721Bridge=2.9.1*, OptimismMintableERC20Factory=1.11.0*, L1CrossDomainMessenger=2.11.1*, L1StandardBridge=2.8.2 |
| 26048619 | 2026-09-24 | `0x0a0fe86f7b1a3d3d` | 071-U20-op-ink-soneium-uni | SystemConfig=4.0.0*, OptimismPortal=5.8.0*, ETHLockbox=1.3.1*, AnchorStateRegistry=3.9.0*, DisputeGameFactory=1.6.1*, DelayedWETH=1.5.1*, L1ERC721Bridge=2.9.1*, OptimismMintableERC20Factory=1.11.0*, L1CrossDomainMessenger=2.11.1* |
| 26430859 | 2026-11-16 | `0x024770b5fba87683` | 084-U21-op-ink-soneium-uni | SystemConfig=4.3.0*, OptimismPortal=6.1.0*, ETHLockbox=2.0.0*, AnchorStateRegistry=4.0.0*, DisputeGameFactory=1.6.1*, DelayedWETH=2.0.0*, L1ERC721Bridge=2.9.1*, OptimismMintableERC20Factory=1.11.0*, L1CrossDomainMessenger=2.13.0* |

Cross-check against F2's independent slot-sampling history (`evidence/F2-impl-history-unichain.json`): 49 (proxy, block, implementation) entries compared, 0 mismatches.

`lastUsedOPCM` (SystemConfig) sampled at each upgrade block:

| L1 block | lastUsedOPCM | version |
|---|---|---|
| 23492571 | `None` | None |
| 23878509 | `None` | None |
| 24427874 | `None` | None |
| 25475307 | `0x9ce712ff84e02659846dc6450bb9b7642fe8be5d` | 7.1.17 |
| 26048619 | `0x1951828ce913dc4383a8a1695695d537a11d896a` | 8.0.1 |
| 26430859 | `0x2d91e6f2bcf6cd1df90e1faf9714e18705ea331f` | 9.0.3 |

## 3. Ownership, guardian, SuperchainConfig

- **ProxyAdmin owner history** (net change per tx; same-tx round trips through the ProxyAdmin during re-initialisation omitted): 21116348 (2024-11-04) `0x00000000…` -> `0xfff2f7417be1a4e2ad1f26f538ad6f67d0fe11f2`; 21116381 (2024-11-04) `0xfff2f741…` -> `0x6d5b183f538abb8572f5cd17109c617b994d5833`; 25976344 (2026-09-14) `0x6d5b183f…` -> `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a`.
- **SystemConfig owner history** (net change per tx; same-tx round trips through the ProxyAdmin during re-initialisation omitted): 21116363 (2024-11-04) `0x00000000…` -> `0x9245d5d10aa8a842b31530de71ea86c0760ca1b1`; 26286838 (2026-10-27) `0x9245d5d1…` -> `0x847b5c174615b1b7fdf770882256e2d3e95b9d92`.
- **DisputeGameFactory owner history** (net change per tx; same-tx round trips through the ProxyAdmin during re-initialisation omitted): 21116372 (2024-11-04) `0x00000000…` -> `0xfff2f7417be1a4e2ad1f26f538ad6f67d0fe11f2`; 21116378 (2024-11-04) `0xfff2f741…` -> `0x6d5b183f538abb8572f5cd17109c617b994d5833`; 25976344 (2026-09-14) `0x6d5b183f…` -> `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a`.
- **AddressManager owner history** (net change per tx; same-tx round trips through the ProxyAdmin during re-initialisation omitted): 21116347 (2024-11-04) `0x00000000…` -> `0xfff2f7417be1a4e2ad1f26f538ad6f67d0fe11f2`; 21116360 (2024-11-04) `0xfff2f741…` -> `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4`.
- SuperchainConfig: `0x95703e0982140D16f8ebA6d158FccEde42f04a4C` — portal slot 53 already held it at the proxy's first initialised block (shared instance from genesis for the three 2024 chains; OP Mainnet since the 2024-02-26 SuperchainConfig introduction). Guardian `0x9ba6e03d…` (2024-01-22) -> `0x09f7150d…` (2024-06-10), unchanged since (`evidence/F5/superchainconfig-events.json`).

## 4. Custody (ETH) at every upgrade block

| L1 block | Date | Portal before -> after | ETHLockbox before -> after | L1CDM | L1StandardBridge |
|---|---|---|---|---|---|
| 21116362 | 2024-11-04 | 0.000 -> 0.000 | — -> — | 0.000 | 0.000 |
| 21116363 | 2024-11-04 | 0.000 -> 0.000 | — -> — | 0.000 | 0.000 |
| 21116366 | 2024-11-04 | 0.000 -> 0.000 | — -> — | 0.000 | 0.000 |
| 21116367 | 2024-11-04 | 0.000 -> 0.000 | — -> — | 0.000 | 0.000 |
| 21116368 | 2024-11-04 | 0.000 -> 0.000 | — -> — | 0.000 | 0.000 |
| 21116371 | 2024-11-04 | 0.000 -> 0.000 | — -> — | 0.000 | 0.000 |
| 21116372 | 2024-11-04 | 0.000 -> 0.000 | — -> — | 0.000 | 0.000 |
| 22081789 | 2025-03-19 | 6,935.738 -> 6,935.738 | — -> — | 0.000 | 0.000 |
| 22254924 | 2025-04-12 | 7,112.788 -> 7,112.788 | — -> — | 0.000 | 0.000 |
| 22342667 | 2025-04-25 | 112,975.345 -> 112,975.345 | — -> — | 0.000 | 0.000 |
| 22990722 | 2025-07-24 | 133,613.248 -> 0.000 | — -> 133,613.248 | 0.000 | 0.000 |
| 23492571 | 2025-10-02 | 0.000 -> 0.000 | 100,128.635 -> 100,128.635 | 0.000 | 0.000 |
| 23878509 | 2025-11-25 | 0.000 -> 0.000 | 64,031.755 -> 64,031.755 | 0.000 | 0.000 |
| 24427874 | 2026-02-10 | 0.000 -> 0.000 | 29,898.508 -> 29,898.508 | 0.000 | 0.000 |
| 25475307 | 2026-07-06 | 0.000 -> 0.000 | 14,960.064 -> 14,960.064 | 0.000 | 0.000 |
| 26048619 | 2026-09-24 | 0.000 -> 0.000 | 14,203.121 -> 14,203.121 | 0.000 | 0.000 |
| 26430859 | 2026-11-16 | 0.000 -> 0.000 | 18,222.347 -> 18,222.347 | 0.000 | 0.000 |
| 26433900 | 2026-11-17 | 0.000 -> 0.000 | 18,266.158 -> 18,266.158 | 0.000 | 0.000 |

- `ETHMigrated(lockbox=0x08ba0023ed60c7bd040716dd13c45fa0062df5c5, amount=133,613.248268 ETH)` at block 22990722 tx `0x1f1f283ad793a901a94e11241d46b87cd264b2e276a690b9554148ba56c57959` — the only liquidity migration event of this portal.
- ETHLockbox administrative events since birth: {'AdminChanged(address,address)': 1, 'Upgraded(address)': 11, 'PortalAuthorized(address)': 4, 'Initialized(uint8)': 4} (no `LockboxAuthorized`, `LiquidityMigrated`, `LiquidityReceived`).

## 5. Dispute infrastructure generations

| AnchorStateRegistry | Born | Version now | Games (index range) | Current? | ETH | respectedGameType / retirementTimestamp now |
|---|---|---|---|---|---|---|
| `0x318a642db9e24a85318b8bf18efd5287ba38643b` | 21116359 (2024-11-04) | 2.0.0 | 3731 (0..3730) | orphaned | 0.0000 | None / None |
| `0xd5d0e176be44e61eab3cf1fa8153758df603376f` | 22254924 (2025-04-12) | 2.2.2 | 2455 (3731..6185) | orphaned | 0.0000 | 9 / None |
| `0x27cf508e4e3aa8d30b3226ac3b5ea0e8bcacaff9` | 22990722 (2025-07-24) | 4.0.0 | 11505 (6186..17690) | yes | 0.0000 | 9 / 1753380731 |

| DelayedWETH | Born | Version | Games using it (range) | ETH balance | owner() | SystemConfig-registered? |
|---|---|---|---|---|---|---|
| `0x7d8ea656d7417229f420b0c87f6428baa8499d70` | 21116358 (2024-11-04) | 1.1.0 | 1740 (0..1739) | 0.000000 | `0x6d5b183f538abb8572f5cd17109c617b994d5833` | no (legacy) |
| `0x84b268a4101a8c8e3ccb33004f81ed08202ba124` | 21582222 (2025-01-08) | 1.3.0 | 125 (1740..1867) | 0.000000 | `0x6d5b183f538abb8572f5cd17109c617b994d5833` | no (legacy) |
| `0xc9edb4e340f4e9683b4557bd9db8f9d932177c86` | 21431684 (2024-12-18) | 1.3.0 | 4321 (1822..6185) | 0.080000 | `0x6d5b183f538abb8572f5cd17109c617b994d5833` | no (legacy) |
| `0xa0157f0730dea8d1a5c358dc1d340a05d8796c23` | 22990722 (2025-07-24) | 1.5.0 | 1679 (6186..7864) | 0.000000 | `None` | no (legacy) |
| `0x0bdbec6bd35571f97f96f3ed21822a4f2e071a3c` | 23492571 (2025-10-02) | 1.5.0 | 6616 (7865..14480) | 0.000000 | `None` | no (legacy) |
| `0x74ad145ac900f1dd5551f0c9e143314dc4022fcf` | 25475307 (2026-07-06) | 2.0.0 | 3210 (14481..17690) | 21.419797 | `None` | yes |

Live ASR slot 6 history (`respectedGameType | retirementTimestamp | ethLockbox`), by storage bisection:

| L1 block | Date | respectedGameType | retirementTimestamp | raw |
|---|---|---|---|---|
| 22990722 | 2025-07-24 | 0 | 1753380731 | `0x0000000000000000000000000000000000000000000000006882777b00000000` |
| 25475307 | 2026-07-06 | 8 | 1753380731 | `0x0000000000000000000000000000000000000000000000006882777b00000008` |
| 26048619 | 2026-09-24 | 9 | 1753380731 | `0x0000000000000000000000000000000000000000000000006882777b00000009` |
| 26430859 | 2026-11-16 | 9 | 1753380731 | `0x08ba0023ed60c7bd040716dd13c45fa0062df5c5000000006882777b00000009` |

Portal-era events (pre-U16 respected type lived in the portal): 21689135 (2025-01-23) RespectedGameTypeSet(0, 1737658703).

Game types ever registered (`ImplementationSet` on the DisputeGameFactory):

| L1 block | Date | Tx | type -> implementation |
|---|---|---|---|
| 21116377 | 2024-11-04 | `0xf7ee0b2de7b79b6b` | 1->`0xb2872ec9…` |
| 21645364 | 2025-01-17 | `0xfcdc3edd3631f3b4` | 1->`0xc4571729…`, 0->`0x08f0f8f4…` |
| 22254924 | 2025-04-12 | `0x7e5e478cafbe3029` | 1->`0x5fe2becc…`, 0->`0xd2c3c6f4…` |
| 22342667 | 2025-04-25 | `0xc74c5e0dddfa9e2d` | 1->`0x67d59ac1…`, 0->`0x56ebb9ea…` |
| 22432925 | 2025-05-07 | `0xd3247421f6f8039a` | 0->`0x57a3b426…`, 1->`0x485272c0…` |
| 22990722 | 2025-07-24 | `0x1f1f283ad793a901` | 1->`0xc56ef9c3…`, 0->`0x4f0f6b78…` |
| 23492571 | 2025-10-02 | `0xc98240172fa3950e` | 1->`0x5581f65c…`, 0->`0x42891199…` |
| 23878509 | 2025-11-25 | `0x7c9e6b65258838fb` | 1->`0xfc38ce38…`, 0->`0x6d046285…` |
| 24427874 | 2026-02-10 | `0x5672a02ba8c40bd3` | 1->`0x58bf355c…`, 0->`0x6ddba09b…`, 8->`0x6ddba09b…` |
| 25475307 | 2026-07-06 | `0xb3c65cbf6285d4b3` | 0->unset, 1->`0xe1dffcbe…`, 8->`0x2dda3584…`, 4->unset, 5->unset, 9->unset, 10->unset |
| 26048619 | 2026-09-24 | `0x0a0fe86f7b1a3d3d` | 0->unset, 1->unset, 8->unset, 5->`0x5c3eb47c…`, 9->`0x19af533c…`, 10->unset, 4->unset |
| 26299517 | 2026-10-29 | `0x626a5b99524a4602` | 5->`0x5c3eb47c…` |
| 26430859 | 2026-11-16 | `0x024770b5fba87683` | 0->unset, 1->unset, 8->unset, 5->`0x5c3eb47c…`, 9->`0x19af533c…`, 10->unset, 4->unset |

Game census at the pinned block (lineage classes):

| type | game version | game's own ASR | DelayedWETH | absolutePrestate | n | index range | created | creators |
|---|---|---|---|---|---|---|---|---|
| 1 | 1.3.0 | `0x318a642d…` | `0x7d8ea656…` | `0x00000000…` | 1740 | 0..1739 | 2024-11-04..2025-01-17 | `0xd5f0e291…`×1740 |
| 1 | 1.3.1 | `0x318a642d…` | `0x84b268a4…` | `0x0336751a…` | 125 | 1740..1867 | 2025-01-17..2025-01-23 | `0xd5f0e291…`×125 |
| 0 | 1.3.1 | `0x318a642d…` | `0xc9edb4e3…` | `0x0336751a…` | 1866 | 1822..3730 | 2025-01-22..2025-04-12 | `0xd5f0e291…`×1863, `0xfff2f741…`×3 |
| 0 | 1.4.1 | `0xd5d0e176…` | `0xc9edb4e3…` | `0x039facea…` | 293 | 3731..4023 | 2025-04-12..2025-04-25 | `0xd5f0e291…`×293 |
| 0 | 1.4.1 | `0xd5d0e176…` | `0xc9edb4e3…` | `0x03ee2917…` | 302 | 4024..4325 | 2025-04-25..2025-05-07 | `0xd5f0e291…`×302 |
| 0 | 1.4.1 | `0xd5d0e176…` | `0xc9edb4e3…` | `0x03682932…` | 1860 | 4326..6185 | 2025-05-07..2025-07-24 | `0xd5f0e291…`×1860 |
| 0 | 1.7.0 | `0x27cf508e…` | `0xa0157f07…` | `0x03eb0710…` | 1679 | 6186..7864 | 2025-07-24..2025-10-02 | `0xd5f0e291…`×1679 |
| 0 | 1.7.0 | `0x27cf508e…` | `0x0bdbec6b…` | `0x03eb0710…` | 1286 | 7865..9150 | 2025-10-02..2025-11-25 | `0xd5f0e291…`×1286 |
| 0 | 1.8.0 | `0x27cf508e…` | `0x0bdbec6b…` | `0x03caa187…` | 1835 | 9151..10985 | 2025-11-25..2026-02-10 | `0xd5f0e291…`×1835 |
| 0 | 2.2.0 | `0x27cf508e…` | `0x0bdbec6b…` | `0x033c0009…` | 3495 | 10986..14480 | 2026-02-10..2026-07-06 | `0xd5f0e291…`×3495 |
| 8 | 2.4.2 | `0x27cf508e…` | `0x74ad145a…` | `0x0337ecb3…` | 1914 | 14481..16394 | 2026-07-06..2026-09-24 | `0xd5f0e291…`×1912, `0x7bf86a1d…`×2 |
| 9 | 0.8.0 | `0x27cf508e…` | `0x74ad145a…` | `0x031ac6f1…` | 1286 | 16395..17680 | 2026-09-24..2026-11-16 | `0xd5f0e291…`×836, `0x86b392ca…`×437, `0x8e68f16e…`×10, `0x299c7d6a…`×1, `0x5b92f4f5…`×1, `0x9995c451…`×1 |
| 9 | 0.8.0 | `0x27cf508e…` | `0x74ad145a…` | `0x03e5a548…` | 10 | 17681..17690 | 2026-11-17..2026-11-17 | `0x86b392ca…`×10 |

- Games: 17691; retired (createdAt <= retirementTimestamp): 6186; claim-valid: 11323; blacklisted: 0; non-retired games whose own ASR is not the live ASR: 0; in progress: 85.
- Header-derived root check of every non-retired game: `{"(0, 'DEFENDER_WINS', True, True)": 8295, "(8, 'DEFENDER_WINS', True, True)": 1912, "(8, 'CHALLENGER_WINS', False, False)": 2, "(9, 'DEFENDER_WINS', True, True)": 1116, "(9, 'CHALLENGER_WINS', False, False)": 12, "(9, 'DEFENDER_WINS', False, True)": 83, "(9, 'IN_PROGRESS', False, False)": 1, "(9, 'IN_PROGRESS', False, True)": 84}`; anomalies: 1.
  - index 17586 type 9 `0xa41214c2851f0d538b7c6b37fa66e35472ff6f0e` creator `0x9995c45126e493a80af417eb3f3328a1e4511543` status IN_PROGRESS claimValid False claimed `0x0cf7603494e163125ec6c1c184b047219ce727ea2b5aa10a935f63294f752e52` header-derived `0x6b26df0bc058f0f7d4946a54047d81100822ef6c7df817f8e047a2a367821e8e`.

## 6. Legacy slots at the pinned block

| Slot | Raw value |
|---|---|
| OptimismPortal2.slot53 (legacy paused byte | superchainConfig) | `0x000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c00` |
| OptimismPortal2.slot54 (legacy l2Oracle) | `0x0000000000000000000000000000000000000000000000000000000000000000` |
| OptimismPortal2.slot56 (legacy disputeGameFactory) | `0x0000000000000000000000002f12d621a16e2d3285929c9996f478508951dfe4` |
| OptimismPortal2.slot59 (legacy respectedGameType | respectedGameTypeUpdatedAt) | `0x0000000000000000000000000000000000000000000000006792914f00000000` |
| OptimismPortal2.slot63 (ethLockbox | legacy superRootsActive byte) | `0x00000000000000000000000008ba0023ed60c7bd040716dd13c45fa0062df5c5` |
| L1CrossDomainMessenger.slot51 (legacy OVM owner) | `0x0000000000000000000000000000000000000000000000000000000000000000` |
| L1CrossDomainMessenger.slot151 (legacy reentrancy status) | `0x0000000000000000000000000000000000000000000000000000000000000000` |
| L1CrossDomainMessenger.slot251 (legacy superchainConfig) | `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c` |
| L1StandardBridge.slot1 (legacy l2TokenBridge) | `0x0000000000000000000000000000000000000000000000000000000000000000` |
| L1StandardBridge.slot50 (legacy superchainConfig) | `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c` |
| SystemConfig.slot106 (eip1559Denominator | eip1559Elasticity | operatorFee*) | `0x0000000000000000000000000000000000000000000000000000000c000000fa` |
| SystemConfig.slot108 (superchainConfig | minBaseFee) | `0x00000000000000000007a12095703e0982140d16f8eba6d158fccede42f04a4c` |
| DelayedWETH.slot4 (legacy config/systemConfig spacer) | `0x000000000000000000000000c407398d063f942febbcc6f80a156b47f3f1bda6` |
