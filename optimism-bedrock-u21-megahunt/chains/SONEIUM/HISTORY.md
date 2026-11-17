# SONEIUM (chain id 1868) — chain history profile (worker F5)

Generated from chain state by `scripts/F5-build-chain-files.py`; every row is a `cast`-equivalent read through the L1 archive proxy `http://127.0.0.1:7545` at or before the pinned block 26433900, or a superchain-registry / superchain-ops file. Raw evidence: `evidence/F5/SONEIUM-history-raw.json`, `evidence/F5/SONEIUM-upgrade-txs.json`, `evidence/F5/SONEIUM-stage2.json`, `evidence/F5/soneium-games-0-8536.json`, `evidence/F5/soneium-root-verification.json`.

## 1. Genesis / deployment generation

- Registry: L2 genesis time 1733134751 (2024-12-02 10:19:11 UTC), L1 origin block 21314185, L2 genesis block 0, block time 2 s, `superchain_time` = 1738573200, fault proofs (chainList.json): permissioned.
- Hardforks: canyon=0, delta=0, ecotone=0, fjord=0, granite=0, holocene=1738573200, isthmus=1746806401, jovian=1764691201, karst=1783526401, lagoon=1799683201.

| Proxy | Address | First code block | Date (UTC) | First implementation (version) | Admin slot at birth |
|---|---|---|---|---|---|
| SystemConfig | `0x7a8ed66b319911a0f3e7288bddab30d9c0c875c3` | 21314185 | 2024-12-02 10:19:11 | `0xf56d96b2535b932656d3c04ebf51babff241d886` (2.2.0) | `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a` |
| OptimismPortal | `0x88e529A6ccd302c948689Cd5156C83D4614FAE92` | 21314185 | 2024-12-02 10:19:11 | `0xe2f826324b2faf99e513d16d266c3f80ae87832b` (3.10.0) | `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a` |
| ETHLockbox | `0x67B4de6FfA66EF201Ea6099A89cA397D56622E31` | 22990670 | 2025-07-24 18:01:35 | `0x784d2f03593a42a6e4676a012762f18775ecbbe6` (1.2.0) | `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a` |
| AnchorStateRegistry | `0x4890928941e62e273dA359374b105F803329F473` | 22990670 | 2025-07-24 18:01:35 | `0xeb69cc681e8d4a557b30dffbad85affd47a2cf2e` (3.5.0) | `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a` |
| DisputeGameFactory | `0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0` | 21314185 | 2024-12-02 10:19:11 | `0xc641a33cab81c559f2bd4b21ea34c290e2440c2b` (1.0.0) | `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a` |
| DelayedWETH | `0x18fBb58C366e21F395DdEc7cBa0510a2D9116B47` | 25397811 | 2026-06-25 23:05:47 | `0xe440cc08a71694c8229323803f59024e3144630e` (1.5.1) | `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a` |
| L1CrossDomainMessenger | `0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f` | 21314185 | 2024-12-02 10:19:11 | `0xd3494713a5cfad3f5359379dfa074e2ac8c6fd65` (2.3.0) | `0x0000000000000000000000000000000000000000` |
| L1StandardBridge | `0xeb9bf100225c214Efc3E7C651ebbaDcF85177607` | 21314185 | 2024-12-02 10:19:11 | `0x64b5a5ed26dcb17370ff4d33a8d503f0fbd06cff` (2.1.0) | `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a` |
| L1ERC721Bridge | `0x5933e323bE8896DfaCd1cD671442F27dAA10a053` | 21314185 | 2024-12-02 10:19:11 | `0xae2af01232a6c4a4d3012c5ec5b1b35059caf10d` (2.1.0) | `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a` |
| OptimismMintableERC20Factory | `0xc1047e30EFC9E172cFe7aa0219895B6a43fC415F` | 21314185 | 2024-12-02 10:19:11 | `0xe01efbeb1089d1d1db9c6c8b135c934c0734c846` (1.9.0) | `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a` |
| ProxyAdmin | `0x89889B569c3a505f3640ee1Bd0ac1D557f436D2a` | 21314185 | 2024-12-02 10:19:11 | `None` (None) | `None` |
| AddressManager | `0xb24bfeece1b3b7a44559f4cbc21bed312b130b70` | 21314185 | 2024-12-02 10:19:11 | `None` (None) | `None` |

## 2. Upgrade path (every implementation change)

`*` = a StorageSetter implementation was installed first in the same transaction (re-initialisation cycle). Task = superchain-ops task whose README status line names this tx (mapping from `evidence/F2-superchain-ops-tasks.json`).

| L1 block | Date | Tx | superchain-ops task | Proxies -> version |
|---|---|---|---|---|
| 21314185 | 2024-12-02 | `0x521e36f9009b6c25` | — | SystemConfig=2.2.0, OptimismPortal=3.10.0, DisputeGameFactory=1.0.0, L1ERC721Bridge=2.1.0, OptimismMintableERC20Factory=1.9.0, L1CrossDomainMessenger=2.3.0, L1StandardBridge=2.1.0 |
| 21945575 | 2025-02-28 | `0x9c6af2cb2b4fcde9` | 030-soneium-holocene-system-config-upgrade | SystemConfig=2.3.0* |
| 22182531 | 2025-04-02 | `0x5f3530e593bbac37` | 000-opcm-upgrade-v200 | SystemConfig=2.4.0, OptimismPortal=3.13.0, DisputeGameFactory=1.0.1, L1ERC721Bridge=2.3.1, OptimismMintableERC20Factory=1.10.1, L1CrossDomainMessenger=2.5.0, L1StandardBridge=2.2.2 |
| 22339996 | 2025-04-24 | `0xbe44244e352a9ffa` | 003-opcm-upgrade-v300-op-ink-soneium | SystemConfig=2.5.0, OptimismPortal=3.14.0, L1ERC721Bridge=2.4.0, L1CrossDomainMessenger=2.6.0, L1StandardBridge=2.3.0 |
| 22990670 | 2025-07-24 | `0xdd89a3933dea0f44` | 018-U16-opcm-upgrade-v400-soneium | SystemConfig=3.4.0, OptimismPortal=4.6.0, ETHLockbox=1.2.0, AnchorStateRegistry=3.5.0, DisputeGameFactory=1.2.0, L1ERC721Bridge=2.7.0, L1CrossDomainMessenger=2.9.0, L1StandardBridge=2.6.0 |
| 23491328 | 2025-10-02 | `0x744cf7d28324729c` | 023-U16a-opcm-upgrade-v410-op-soneium-ink | SystemConfig=3.7.0, OptimismPortal=5.0.0, AnchorStateRegistry=3.5.0, DisputeGameFactory=1.2.0, L1ERC721Bridge=2.8.0, L1CrossDomainMessenger=2.10.0, L1StandardBridge=2.7.0 |
| 23877377 | 2025-11-25 | `0xf556934cb4de1ab4` | 032-U17-main-op-sony-ink | SystemConfig=3.11.0, OptimismPortal=5.1.1, DisputeGameFactory=1.3.0, L1ERC721Bridge=2.9.0, OptimismMintableERC20Factory=1.10.2, L1CrossDomainMessenger=2.11.0, L1StandardBridge=2.8.0 |
| 24478557 | 2026-02-17 | `0xeba2fc77f814ea5d` | 042-U18-soneium | SystemConfig=3.13.1, OptimismPortal=5.2.0, AnchorStateRegistry=3.7.0, DisputeGameFactory=1.4.0, L1ERC721Bridge=2.9.0, OptimismMintableERC20Factory=1.10.2, L1CrossDomainMessenger=2.11.0 |
| 25397811 | 2026-06-25 | `0xbfdac60c9687a2e4` | 053-U19-op-ink-mmz-soneium | SystemConfig=3.14.2*, OptimismPortal=5.6.1*, ETHLockbox=1.3.1*, AnchorStateRegistry=3.9.0*, DisputeGameFactory=1.6.1*, DelayedWETH=1.5.1*, L1ERC721Bridge=2.9.1*, OptimismMintableERC20Factory=1.11.0*, L1CrossDomainMessenger=2.11.1*, L1StandardBridge=2.8.2 |
| 26048619 | 2026-09-24 | `0x0a0fe86f7b1a3d3d` | 071-U20-op-ink-soneium-uni | SystemConfig=4.0.0*, OptimismPortal=5.8.0*, ETHLockbox=1.3.1*, AnchorStateRegistry=3.9.0*, DisputeGameFactory=1.6.1*, DelayedWETH=1.5.1*, L1ERC721Bridge=2.9.1*, OptimismMintableERC20Factory=1.11.0*, L1CrossDomainMessenger=2.11.1* |
| 26430859 | 2026-11-16 | `0x024770b5fba87683` | 084-U21-op-ink-soneium-uni | SystemConfig=4.3.0*, OptimismPortal=6.1.0*, ETHLockbox=2.0.0*, AnchorStateRegistry=4.0.0*, DisputeGameFactory=1.6.1*, DelayedWETH=2.0.0*, L1ERC721Bridge=2.9.1*, OptimismMintableERC20Factory=1.11.0*, L1CrossDomainMessenger=2.13.0* |

Cross-check against F2's independent slot-sampling history (`evidence/F2-impl-history-soneium.json`): 49 (proxy, block, implementation) entries compared, 0 mismatches.

`lastUsedOPCM` (SystemConfig) sampled at each upgrade block:

| L1 block | lastUsedOPCM | version |
|---|---|---|
| 23491328 | `None` | None |
| 23877377 | `None` | None |
| 24478557 | `None` | None |
| 25397811 | `0x9ce712ff84e02659846dc6450bb9b7642fe8be5d` | 7.1.17 |
| 26048619 | `0x1951828ce913dc4383a8a1695695d537a11d896a` | 8.0.1 |
| 26430859 | `0x2d91e6f2bcf6cd1df90e1faf9714e18705ea331f` | 9.0.3 |

## 3. Ownership, guardian, SuperchainConfig

- **ProxyAdmin owner history** (net change per tx; same-tx round trips through the ProxyAdmin during re-initialisation omitted): 21314185 (2024-12-02) `0x00000000…` -> `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a`.
- **SystemConfig owner history** (net change per tx; same-tx round trips through the ProxyAdmin during re-initialisation omitted): 21314185 (2024-12-02) `0x00000000…` -> `0x509182ec226b3b71d36a3255a80ef0b1a9d43033`.
- **DisputeGameFactory owner history** (net change per tx; same-tx round trips through the ProxyAdmin during re-initialisation omitted): 21314185 (2024-12-02) `0x00000000…` -> `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a`.
- **AddressManager owner history** (net change per tx; same-tx round trips through the ProxyAdmin during re-initialisation omitted): 21314185 (2024-12-02) `0x00000000…` -> `0x89889b569c3a505f3640ee1bd0ac1d557f436d2a`.
- SuperchainConfig: `0x95703e0982140D16f8ebA6d158FccEde42f04a4C` — portal slot 53 already held it at the proxy's first initialised block (shared instance from genesis for the three 2024 chains; OP Mainnet since the 2024-02-26 SuperchainConfig introduction). Guardian `0x9ba6e03d…` (2024-01-22) -> `0x09f7150d…` (2024-06-10), unchanged since (`evidence/F5/superchainconfig-events.json`).

## 4. Custody (ETH) at every upgrade block

| L1 block | Date | Portal before -> after | ETHLockbox before -> after | L1CDM | L1StandardBridge |
|---|---|---|---|---|---|
| 21314185 | 2024-12-02 | 0.000 -> 0.000 | — -> — | 0.000 | 0.000 |
| 21945575 | 2025-02-28 | 9,199.335 -> 9,199.335 | — -> — | 0.000 | 0.000 |
| 22182531 | 2025-04-02 | 12,442.119 -> 12,442.119 | — -> — | 0.000 | 0.000 |
| 22339996 | 2025-04-24 | 12,220.844 -> 12,220.844 | — -> — | 0.000 | 0.000 |
| 22990670 | 2025-07-24 | 8,877.051 -> 0.000 | — -> 8,877.051 | 0.000 | 0.000 |
| 23491328 | 2025-10-02 | 0.000 -> 0.000 | 7,318.018 -> 7,318.018 | 0.000 | 0.000 |
| 23877377 | 2025-11-25 | 0.000 -> 0.000 | 6,243.195 -> 6,243.195 | 0.000 | 0.000 |
| 24478557 | 2026-02-17 | 0.000 -> 0.000 | 3,860.071 -> 3,860.071 | 0.000 | 0.000 |
| 25397811 | 2026-06-25 | 0.000 -> 0.000 | 2,616.621 -> 2,616.621 | 0.000 | 0.000 |
| 26048619 | 2026-09-24 | 0.000 -> 0.000 | 2,185.790 -> 2,185.790 | 0.000 | 0.000 |
| 26430859 | 2026-11-16 | 0.000 -> 0.000 | 2,195.560 -> 2,195.560 | 0.000 | 0.000 |
| 26433900 | 2026-11-17 | 0.000 -> 0.000 | 2,195.560 -> 2,195.560 | 0.000 | 0.000 |

- `ETHMigrated(lockbox=0x67b4de6ffa66ef201ea6099a89ca397d56622e31, amount=8,877.050938 ETH)` at block 22990670 tx `0xdd89a3933dea0f44e1a461441f3c78e341702e9a4148784780644cdac90148c2` — the only liquidity migration event of this portal.
- ETHLockbox administrative events since birth: {'AdminChanged(address,address)': 1, 'Upgraded(address)': 11, 'PortalAuthorized(address)': 4, 'Initialized(uint8)': 4} (no `LockboxAuthorized`, `LiquidityMigrated`, `LiquidityReceived`).

## 5. Dispute infrastructure generations

| AnchorStateRegistry | Born | Version now | Games (index range) | Current? | ETH | respectedGameType / retirementTimestamp now |
|---|---|---|---|---|---|---|
| `0x61f89a381e0be13bd8ab356cf4b7301bc97d7522` | 21314185 (2024-12-02) | 2.0.1-beta.3 | 1486 (0..1485) | orphaned | 0.0000 | None / None |
| `0x190b6ecee5a2ddf39669288b9b8daea4641ae8b1` | 22182531 (2025-04-02) | 2.2.2 | 1355 (1486..2840) | orphaned | 0.0000 | 5 / None |
| `0x4890928941e62e273da359374b105f803329f473` | 22990670 (2025-07-24) | 4.0.0 | 5696 (2841..8536) | yes | 0.0000 | 5 / 1753380095 |

| DelayedWETH | Born | Version | Games using it (range) | ETH balance | owner() | SystemConfig-registered? |
|---|---|---|---|---|---|---|
| `0x9aea1fd851b63d57ba4fc556b0e0c170126c9eaf` | 21314185 (2024-12-02) | 1.3.0 | 2841 (0..2840) | 0.000000 | `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a` | no (legacy) |
| `0x372dc0b87b790d6e1308cf9e7f73f0f1fcbd3754` | 22990670 (2025-07-24) | 1.5.0 | 838 (2841..3678) | 0.000000 | `None` | no (legacy) |
| `0x70277624cde90492231eb23309e1251beb18dff5` | 23491328 (2025-10-02) | 1.5.0 | 3188 (3679..6866) | 0.000000 | `None` | no (legacy) |
| `0x18fbb58c366e21f395ddec7cba0510a2d9116b47` | 25397811 (2026-06-25) | 2.0.0 | 1088 (6867..7954) | 0.000000 | `None` | yes |

Live ASR slot 6 history (`respectedGameType | retirementTimestamp | ethLockbox`), by storage bisection:

| L1 block | Date | respectedGameType | retirementTimestamp | raw |
|---|---|---|---|---|
| 22990670 | 2025-07-24 | 1 | 1753380095 | `0x000000000000000000000000000000000000000000000000688274ff00000001` |
| 26048619 | 2026-09-24 | 5 | 1753380095 | `0x000000000000000000000000000000000000000000000000688274ff00000005` |
| 26430859 | 2026-11-16 | 5 | 1753380095 | `0x67b4de6ffa66ef201ea6099a89ca397d56622e3100000000688274ff00000005` |

Portal-era events (pre-U16 respected type lived in the portal): none.

Game types ever registered (`ImplementationSet` on the DisputeGameFactory):

| L1 block | Date | Tx | type -> implementation |
|---|---|---|---|
| 21314185 | 2024-12-02 | `0x521e36f9009b6c25` | 1->`0x42d15f04…` |
| 22182531 | 2025-04-02 | `0x5f3530e593bbac37` | 1->`0x1661af71…` |
| 22339996 | 2025-04-24 | `0xbe44244e352a9ffa` | 1->`0x3d56d47b…` |
| 22990670 | 2025-07-24 | `0xdd89a3933dea0f44` | 1->`0x3c12f1f4…` |
| 23491328 | 2025-10-02 | `0x744cf7d28324729c` | 1->`0xb4343238…` |
| 23877377 | 2025-11-25 | `0xf556934cb4de1ab4` | 1->`0x0ddf929e…` |
| 24478557 | 2026-02-17 | `0xeba2fc77f814ea5d` | 1->`0x58bf355c…` |
| 25397811 | 2026-06-25 | `0xbfdac60c9687a2e4` | 0->unset, 1->`0xe1dffcbe…`, 8->unset, 4->unset, 5->unset, 9->unset, 10->unset |
| 26048619 | 2026-09-24 | `0x0a0fe86f7b1a3d3d` | 0->unset, 1->unset, 8->unset, 5->`0x5c3eb47c…`, 9->unset, 10->unset, 4->unset |
| 26430859 | 2026-11-16 | `0x024770b5fba87683` | 0->unset, 1->unset, 8->unset, 5->`0x5c3eb47c…`, 9->unset, 10->unset, 4->unset |

Game census at the pinned block (lineage classes):

| type | game version | game's own ASR | DelayedWETH | absolutePrestate | n | index range | created | creators |
|---|---|---|---|---|---|---|---|---|
| 1 | 1.3.1-beta.3 | `0x61f89a38…` | `0x9aea1fd8…` | `0x038512e0…` | 1486 | 0..1485 | 2024-12-02..2025-04-02 | `0x400c164c…`×1486 |
| 1 | 1.4.1 | `0x190b6ece…` | `0x9aea1fd8…` | `0x039facea…` | 264 | 1486..1749 | 2025-04-02..2025-04-24 | `0x400c164c…`×264 |
| 1 | 1.4.1 | `0x190b6ece…` | `0x9aea1fd8…` | `0x03ee2917…` | 1091 | 1750..2840 | 2025-04-24..2025-07-24 | `0x400c164c…`×1091 |
| 1 | 1.7.0 | `0x48909289…` | `0x372dc0b8…` | `0x03eb0710…` | 838 | 2841..3678 | 2025-07-24..2025-10-02 | `0x400c164c…`×838 |
| 1 | 1.7.0 | `0x48909289…` | `0x70277624…` | `0x03eb0710…` | 647 | 3679..4325 | 2025-10-02..2025-11-25 | `0x400c164c…`×647 |
| 1 | 1.8.0 | `0x48909289…` | `0x70277624…` | `0x03caa187…` | 1006 | 4326..5331 | 2025-11-25..2026-02-17 | `0x400c164c…`×1006 |
| 1 | 2.2.0 | `0x48909289…` | `0x70277624…` | `0x033c0009…` | 1535 | 5332..6866 | 2026-02-17..2026-06-25 | `0x400c164c…`×1535 |
| 1 | 2.4.0 | `0x48909289…` | `0x18fbb58c…` | `0xdead0000…` | 1088 | 6867..7954 | 2026-06-25..2026-09-24 | `0x400c164c…`×1088 |
| 5 | 1.1.0 | `0x48909289…` | `None` | `None` | 582 | 7955..8536 | 2026-09-24..2026-11-17 | `0x400c164c…`×582 |

- Games: 8537; retired (createdAt <= retirementTimestamp): 2841; claim-valid: 5668; blacklisted: 0; non-retired games whose own ASR is not the live ASR: 0; in progress: 0.
- Header-derived root check of every non-retired game: `{"(1, 'DEFENDER_WINS', True, True)": 5114, "(5, 'DEFENDER_WINS', True, True)": 554, "(5, 'DEFENDER_WINS', False, True)": 28}`; anomalies: 0.

## 6. Legacy slots at the pinned block

| Slot | Raw value |
|---|---|
| OptimismPortal2.slot53 (legacy paused byte | superchainConfig) | `0x000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c00` |
| OptimismPortal2.slot54 (legacy l2Oracle) | `0x0000000000000000000000000000000000000000000000000000000000000000` |
| OptimismPortal2.slot56 (legacy disputeGameFactory) | `0x000000000000000000000000512a3d2c7a43bd9261d2b8e8c9c70d4bd4d503c0` |
| OptimismPortal2.slot59 (legacy respectedGameType | respectedGameTypeUpdatedAt) | `0x000000000000000000000000000000000000000000000000674d899f00000001` |
| OptimismPortal2.slot63 (ethLockbox | legacy superRootsActive byte) | `0x00000000000000000000000067b4de6ffa66ef201ea6099a89ca397d56622e31` |
| L1CrossDomainMessenger.slot51 (legacy OVM owner) | `0x0000000000000000000000000000000000000000000000000000000000000000` |
| L1CrossDomainMessenger.slot151 (legacy reentrancy status) | `0x0000000000000000000000000000000000000000000000000000000000000000` |
| L1CrossDomainMessenger.slot251 (legacy superchainConfig) | `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c` |
| L1StandardBridge.slot1 (legacy l2TokenBridge) | `0x0000000000000000000000000000000000000000000000000000000000000000` |
| L1StandardBridge.slot50 (legacy superchainConfig) | `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c` |
| SystemConfig.slot106 (eip1559Denominator | eip1559Elasticity | operatorFee*) | `0x0000000000000000000000000000000000000000000000000000000a000000fa` |
| SystemConfig.slot108 (superchainConfig | minBaseFee) | `0x000000000000000000b71b0095703e0982140d16f8eba6d158fccede42f04a4c` |
| DelayedWETH.slot4 (legacy config/systemConfig spacer) | `0x0000000000000000000000007a8ed66b319911a0f3e7288bddab30d9c0c875c3` |
