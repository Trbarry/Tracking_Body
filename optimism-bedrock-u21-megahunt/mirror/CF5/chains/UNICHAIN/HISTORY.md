# Unichain chain history (CF5)

Pinned state: Ethereum block **26433900**. Current implementation tag: `op-contracts/v9.0.0` (`ba6fcadb…`). The exhaustive machine-readable event path is in `UPGRADE-PATH.json`; raw reads are under `../../evidence/`.

## Birth and reachable historical state

The registry identifies chain ID 130 and the canonical proxies at `superchain/configs/mainnet/unichain.toml:1-53`. `DEPLOYMENT.json` records a code-presence binary search for each proxy, its first implementation block, and the semantic version it was born with. This chain was born after Bedrock with SystemConfig 2.2.0 / Portal 3.10.0-era components, so pre-Bedrock objects cannot exist in its lineage.

## Executed release path

| release | L1 block | UTC date | transaction | lastUsedOPCM | selected versions after transaction |
|---|---:|---|---|---|---|
| U2 | 22254924 | 2025-04-12 | `0x7e5e478caf…` | `0x026b2F158255Beac46c1E7c6b8BbF29A4b6A7B76` | DGF=1.0.1, Portal=3.13.0, SystemConfig=2.4.0 |
| U3 | 22342667 | 2025-04-25 | `0xc74c5e0ddd…` | `0x3a1f523a4bc09cd344a2745a108bb0398288094f` | DGF=1.0.1, Portal=3.14.0, SystemConfig=2.5.0 |
| U16 | 22990722 | 2025-07-24 | `0x1f1f283ad7…` | `0x56ebc5c4870f5367b836081610592241ad3e0734` | ASR=3.5.0, DGF=1.2.0, ETHLockbox=1.2.0, Portal=4.6.0, SystemConfig=3.4.0 |
| U16a | 23492571 | 2025-10-02 | `0xc98240172f…` | `0x8123739c1368c2dedc8c564255bc417feeebff9d` | ASR=3.5.0, DGF=1.2.0, ETHLockbox=1.2.0, Portal=5.0.0, SystemConfig=3.7.0 |
| U17 | 23878509 | 2025-11-25 | `0x7c9e6b6525…` | `0xfa1ef97fb02b0da2ee2346b8e310907ab5519449` | ASR=3.5.0, DGF=1.3.0, ETHLockbox=1.2.0, Portal=5.1.1, SystemConfig=3.11.0 |
| U18 | 24427874 | 2026-02-10 | `0x5672a02ba8…` | `0x50f47b43c24f40b92c873fa0704d4207586d0c9f` | ASR=3.7.0, DGF=1.4.0, ETHLockbox=1.2.0, Portal=5.2.0, SystemConfig=3.13.1 |
| U19 | 25475307 | 2026-07-06 | `0xb3c65cbf62…` | `0x9ce712ff84e02659846dc6450bb9b7642fe8be5d` | ASR=3.9.0, DGF=1.6.1, DelayedWETH=1.5.1, ETHLockbox=1.3.1, Portal=5.6.1, SystemConfig=3.14.2 |
| U20 | 26048619 | 2026-09-24 | `0x0a0fe86f7b…` | `0x1951828ce913dc4383a8a1695695d537a11d896a` | ASR=3.9.0, DGF=1.6.1, DelayedWETH=1.5.1, ETHLockbox=1.3.1, Portal=5.8.0, SystemConfig=4.0.0 |
| U21 | 26430859 | 2026-11-16 | `0x024770b5fb…` | `0x2d91e6f2bcf6cd1df90e1faf9714e18705ea331f` | ASR=4.0.0, DGF=1.6.1, DelayedWETH=2.0.0, ETHLockbox=2.0.0, Portal=6.1.0, SystemConfig=4.3.0 |

All listed release transactions are marked EXECUTED in `superchain-ops/src/tasks/eth/<task>/README.md:3`; the corresponding OPCM is pinned in each task's `config.toml`. No post-birth release in U2→U21 was skipped. Per-component no-op/skipped upgrades are explicit in `unchangedAtRelease`. Manual prestate, proposer, and ownership operations are in `ancillaryConfigurationAndOwnershipTasks`.

## Ownership, features, and chain-specific parameters at U21

- ProxyAdmin owner: `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`; DGF owner: `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`; SystemConfig owner: `0x847B5c174615B1B7fDF770882256e2D3E95b9D92`.
- Guardian: `0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2` through shared SuperchainConfig `0x95703e…`; `lastUsedOPCM=0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f`.
- ETH lockbox feature `true`, interop `false`, custom gas token `false`.
- `gasLimit=60000000 [6e7]`, EIP-1559 denominator/elasticity `250/12`, `minBaseFee=500000 [5e5]`. These are operator/governance inputs, not hidden implementation differences.

## Custody

| release | block | Portal wei | ETHLockbox wei | L1XDM wei | L1StandardBridge wei |
|---|---:|---:|---:|---:|---:|
| U2 | 22254924 | 7112787816511489527676 | None | 0 | 0 |
| U3 | 22342667 | 112975345150884031215154 | None | 0 | 0 |
| U16 | 22990722 | 0 | 133613248268096507106891 | 0 | 0 |
| U16a | 23492571 | 0 | 100128634737695642066910 | 0 | 0 |
| U17 | 23878509 | 0 | 64031754985238360154101 | 0 | 0 |
| U18 | 24427874 | 0 | 29898508302600775462827 | 0 | 0 |
| U19 | 25475307 | 0 | 14960064005021256032592 | 0 | 0 |
| U20 | 26048619 | 0 | 14203120985766609097399 | 0 | 0 |
| U21 | 26430859 | 0 | 18222347018032559647506 | 0 | 0 |

The U16 `ETHMigrated` event is decoded in `UPGRADE-PATH.json`. At 26433900, balances are `{"ETHLockbox": 18266157945407766718622, "L1StandardBridge": 0, "L1XDM": 0, "Portal": 0}`: no ETH remains in Portal/L1XDM/L1StandardBridge; custody is in the chain's lockbox. Portal pause now delegates to lockbox pause at `OptimismPortal2.sol:305-308`, and lockbox uses its own address as identifier at `ETHLockbox.sol:111-114` (v9 tag).

## Dispute lineage and retained bond custody

| object | address | first-code block | game indices (count) | ETH wei at 26433900 | version |
|---|---|---:|---|---:|---|
| ASR | `0x27cf508e4e3aa8d30b3226ac3b5ea0e8bcacaff9` | 22990722 | 6186–17690 (11505) | 0 | `4.0.0` |
| ASR | `0x318a642db9e24a85318b8bf18efd5287ba38643b` | 21116359 | 0–3730 (3731) | 0 | `2.0.0` |
| ASR | `0xd5d0e176be44e61eab3cf1fa8153758df603376f` | 22254924 | 3731–6185 (2455) | 0 | `2.2.2` |
| DelayedWETH | `0x0bdbec6bd35571f97f96f3ed21822a4f2e071a3c` | 23492571 | 7865–14480 (6616) | 0 | `1.5.0` |
| DelayedWETH | `0x74ad145ac900f1dd5551f0c9e143314dc4022fcf` | 25475307 | 14481–17690 (3210) | 21419797000000000000 | `2.0.0` |
| DelayedWETH | `0x7d8ea656d7417229f420b0c87f6428baa8499d70` | 21116358 | 0–1739 (1740) | 0 | `1.1.0` |
| DelayedWETH | `0x84b268a4101a8c8e3ccb33004f81ed08202ba124` | 21582222 | 1740–1867 (125) | 0 | `1.3.0` |
| DelayedWETH | `0xa0157f0730dea8d1a5c358dc1d340a05d8796c23` | 22990722 | 6186–7864 (1679) | 0 | `1.5.0` |
| DelayedWETH | `0xc9edb4e340f4e9683b4557bd9db8f9d932177c86` | 21431684 | 1822–6185 (4321) | 80000000000000000 | `1.3.0` |

Current respected type is **9**, retirement timestamp `1753380731 [1.753e9]`, anchor `0xaf8bf886b957cbe734cdaabd672ec35e2d0095e4a780853e2ad1c5e818630c2b at L2 timestamp 1794263862 [1.794e9]`. Every `ImplementationSet`, bond, args, absolute-prestate observation, anchor update, retirement, and blacklist event is retained in `UPGRADE-PATH.json`. v9 accepts a factory-registered game only after blacklist/retirement/finality checks (`AnchorStateRegistry.sol:256-262,286-325,331-352`) and records respect at creation (`SuperFaultDisputeGame.sol:338-340`).

## Game census

Scanned `17691` games in batches of 20 through Multicall3 at L1 block 26433900; types `{0: 12616, 1: 1865, 8: 1914, 9: 1296}`, statuses `{0: 85, 1: 16, 2: 17590}`, claim-valid `11323`, blacklisted `0`. Raw current-proposer flags: `11044`; after recognizing documented proposer rotations: `1`. Passive L2 endpoint used for header verification: `https://mainnet.unichain.org`. Root-check detail is embedded in the JSON.

## Pause and storage-history notes

The shared config emitted one global pause at block 22,482,108 and unpause at 22,482,160. Its only address-scoped pause was Swell's portal at block 25,689,317, not this chain; it expired after three months under `SuperchainConfig.sol:139-162`. Current chain identifier `0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5` has no pause event.

The four OP-only legacy residues (XDM 51/151, bridge 1, portal 54) are zero on this chain; full labelled storage is in STATE-U21.json.

## Coverage limits

L1 logs were scanned from genesis through 26433900; code birth used archive binary search. The census is complete to the factory count observed at the pinned block. L2 header verification was limited to unexpected live games, plus one claim-valid OP control. Balance history is sampled at every executed release plus the migration event and pinned head; intra-release deposits/withdrawals were not reconstructed transaction-by-transaction.
