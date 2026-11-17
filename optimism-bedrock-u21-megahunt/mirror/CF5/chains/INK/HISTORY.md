# Ink chain history (CF5)

Pinned state: Ethereum block **26433900**. Current implementation tag: `op-contracts/v9.0.0` (`ba6fcadb…`). The exhaustive machine-readable event path is in `UPGRADE-PATH.json`; raw reads are under `../../evidence/`.

## Birth and reachable historical state

The registry identifies chain ID 57073 and the canonical proxies at `superchain/configs/mainnet/ink.toml:1-53`. `DEPLOYMENT.json` records a code-presence binary search for each proxy, its first implementation block, and the semantic version it was born with. This chain was born after Bedrock with SystemConfig 2.2.0 / Portal 3.10.0-era components, so pre-Bedrock objects cannot exist in its lineage.

## Executed release path

| release | L1 block | UTC date | transaction | lastUsedOPCM | selected versions after transaction |
|---|---:|---|---|---|---|
| U2 | 22182531 | 2025-04-02 | `0x5f3530e593…` | `0x026b2F158255Beac46c1E7c6b8BbF29A4b6A7B76` | DGF=1.0.1, Portal=3.13.0, SystemConfig=2.4.0 |
| U3 | 22339996 | 2025-04-24 | `0xbe44244e35…` | `0x3a1f523a4bc09cd344a2745a108bb0398288094f` | DGF=1.0.1, Portal=3.14.0, SystemConfig=2.5.0 |
| U16 | 22990599 | 2025-07-24 | `0x46acdce174…` | `0x56ebc5c4870f5367b836081610592241ad3e0734` | ASR=3.5.0, DGF=1.2.0, ETHLockbox=1.2.0, Portal=4.6.0, SystemConfig=3.4.0 |
| U16a | 23491328 | 2025-10-02 | `0x744cf7d283…` | `0x8123739c1368c2dedc8c564255bc417feeebff9d` | ASR=3.5.0, DGF=1.2.0, ETHLockbox=1.2.0, Portal=5.0.0, SystemConfig=3.7.0 |
| U17 | 23877377 | 2025-11-25 | `0xf556934cb4…` | `0xfa1ef97fb02b0da2ee2346b8e310907ab5519449` | ASR=3.5.0, DGF=1.3.0, ETHLockbox=1.2.0, Portal=5.1.1, SystemConfig=3.11.0 |
| U18 | 24421512 | 2026-02-09 | `0x8808cd5311…` | `0x50f47b43c24f40b92c873fa0704d4207586d0c9f` | ASR=3.7.0, DGF=1.4.0, ETHLockbox=1.2.0, Portal=5.2.0, SystemConfig=3.13.1 |
| U19 | 25397811 | 2026-06-25 | `0xbfdac60c96…` | `0x9ce712ff84e02659846dc6450bb9b7642fe8be5d` | ASR=3.9.0, DGF=1.6.1, DelayedWETH=1.5.1, ETHLockbox=1.3.1, Portal=5.6.1, SystemConfig=3.14.2 |
| U20 | 26048619 | 2026-09-24 | `0x0a0fe86f7b…` | `0x1951828ce913dc4383a8a1695695d537a11d896a` | ASR=3.9.0, DGF=1.6.1, DelayedWETH=1.5.1, ETHLockbox=1.3.1, Portal=5.8.0, SystemConfig=4.0.0 |
| U21 | 26430859 | 2026-11-16 | `0x024770b5fb…` | `0x2d91e6f2bcf6cd1df90e1faf9714e18705ea331f` | ASR=4.0.0, DGF=1.6.1, DelayedWETH=2.0.0, ETHLockbox=2.0.0, Portal=6.1.0, SystemConfig=4.3.0 |

All listed release transactions are marked EXECUTED in `superchain-ops/src/tasks/eth/<task>/README.md:3`; the corresponding OPCM is pinned in each task's `config.toml`. No post-birth release in U2→U21 was skipped. Per-component no-op/skipped upgrades are explicit in `unchangedAtRelease`. Manual prestate, proposer, and ownership operations are in `ancillaryConfigurationAndOwnershipTasks`.

## Ownership, features, and chain-specific parameters at U21

- ProxyAdmin owner: `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`; DGF owner: `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`; SystemConfig owner: `0x847B5c174615B1B7fDF770882256e2D3E95b9D92`.
- The ProxyAdmin/DGF owner is a 2-of-2 Safe; its owner Safes are 5-of-7 and 10-of-13. The SystemConfig owner is a 5-of-7 Safe. Setup and every `AddedOwner`, `RemovedOwner`, and `ChangedThreshold` event through the pinned block are in `governanceSafeHistory`.
- Guardian: `0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2` through shared SuperchainConfig `0x95703e…`; `lastUsedOPCM=0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f`.
- ETH lockbox feature `true`, interop `false`, custom gas token `false`.
- `gasLimit=30000000 [3e7]`, EIP-1559 denominator/elasticity `0/0`, `minBaseFee=0`. These are operator/governance inputs, not hidden implementation differences.

## Custody

| release | block | Portal wei | ETHLockbox wei | L1XDM wei | L1StandardBridge wei |
|---|---:|---:|---:|---:|---:|
| U2 | 22182531 | 9443049970572497463405 | None | 0 | 0 |
| U3 | 22339996 | 9609734661147026713142 | None | 0 | 0 |
| U16 | 22990599 | 0 | 6020610509607786200086 | 0 | 0 |
| U16a | 23491328 | 0 | 6649408111715493707256 | 0 | 0 |
| U17 | 23877377 | 0 | 41099014285771799553956 | 0 | 0 |
| U18 | 24421512 | 0 | 28473189152176655746001 | 0 | 0 |
| U19 | 25397811 | 0 | 26190818034283778051475 | 0 | 0 |
| U20 | 26048619 | 0 | 22846565041625233361513 | 0 | 0 |
| U21 | 26430859 | 0 | 23088758336628210326229 | 0 | 0 |

The U16 `ETHMigrated` event is decoded in `UPGRADE-PATH.json`. At 26433900, balances are `{"ETHLockbox": 23088758336628210326229, "L1StandardBridge": 0, "L1XDM": 0, "Portal": 0}`: no ETH remains in Portal/L1XDM/L1StandardBridge; custody is in the chain's lockbox. Portal pause now delegates to lockbox pause at `OptimismPortal2.sol:305-308`, and lockbox uses its own address as identifier at `ETHLockbox.sol:111-114` (v9 tag).

## Dispute lineage and retained bond custody

| object | address | first-code block | game indices (count) | ETH wei at 26433900 | version |
|---|---|---:|---|---:|---|
| ASR | `0x2fc99fd16d8d3f6f66d164aa84e244c567e58a3d` | 22182531 | 470–921 (452) | 0 | `2.2.2` |
| ASR | `0xde744491bcf6b2dd2f32146364ea1487d75e2509` | 21344310 | 0–469 (470) | 0 | `2.0.1-beta.3` |
| ASR | `0xee018baf058227872540ac60efbd38b023d9dae2` | 22990599 | 922–2639 (1718) | 0 | `4.0.0` |
| DelayedWETH | `0x14773a8040ff22e3dcbb0c83ec8e33be7d920d38` | 21344310 | 0–191 (190) | 0 | `1.1.0` |
| DelayedWETH | `0x3beaca17eae5643fb1479aa5f4b1ff75cc4b9b50` | 21387926 | 155–405 (216) | 80000000000000000 | `1.1.0` |
| DelayedWETH | `0x3f7b07a5d638024a37a776fa228fe90b317af6de` | 22990599 | 922–1201 (280) | 0 | `1.5.0` |
| DelayedWETH | `0x57b4c29daee99a28e6e86778b499361294c134ea` | 25397811 | 2266–2639 (374) | 5710376000000000000 | `2.0.0` |
| DelayedWETH | `0x6cbd14da021e39a7895ae151ac72ecc9023e87f6` | 23491328 | 1202–2265 (1064) | 0 | `1.5.0` |
| DelayedWETH | `0xf6b1554f483c391414d3830927e3600c105aae6e` | 21995971 | 406–921 (516) | 0 | `1.3.0` |

Current respected type is **9**, retirement timestamp `1753379243 [1.753e9]`, anchor `0x6cf0114f1c0fab7f2d989c7b4fec4870afb70959ff328d23f3ac4fe74c948231 at L2 timestamp 1794244697 [1.794e9]`. Every `ImplementationSet`, bond, args, absolute-prestate observation, anchor update, retirement, and blacklist event is retained in `UPGRADE-PATH.json`. v9 accepts a factory-registered game only after blacklist/retirement/finality checks (`AnchorStateRegistry.sol:256-262,286-325,331-352`) and records respect at creation (`SuperFaultDisputeGame.sol:338-340`).

## Game census

Scanned `2640` games in batches of 20 through Multicall3 at L1 block 26433900; types `{0: 2076, 1: 190, 8: 256, 9: 118}`, statuses `{0: 8, 1: 19, 2: 2613}`, claim-valid `1685`, blacklisted `0`. Raw current-proposer flags: `1475`; after recognizing documented proposer rotations: `1`. Passive L2 endpoint used for header verification: `https://rpc-gel.inkonchain.com`. Root-check detail is embedded in the JSON.

## Pause and storage-history notes

The shared config emitted one global pause at block 22,482,108 and unpause at 22,482,160. Its only address-scoped pause was Swell's portal at block 25,689,317, not this chain; it expired after three months under `SuperchainConfig.sol:139-162`. Current chain identifier `0xbd4AbB321138e8Eddc399cE64E66451294325a14` has no pause event.

The four OP-only legacy residues (XDM 51/151, bridge 1, portal 54) are zero on this chain; full labelled storage is in STATE-U21.json.

## Coverage limits

L1 logs were scanned from genesis through 26433900; code birth used archive binary search. The census is complete to the factory count observed at the pinned block. L2 header verification was limited to unexpected live games, plus one claim-valid OP control. Balance history is sampled at every executed release plus the migration event and pinned head; intra-release deposits/withdrawals were not reconstructed transaction-by-transaction.
