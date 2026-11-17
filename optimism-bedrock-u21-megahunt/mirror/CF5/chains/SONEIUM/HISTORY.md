# Soneium chain history (CF5)

Pinned state: Ethereum block **26433900**. Current implementation tag: `op-contracts/v9.0.0` (`ba6fcadb…`). The exhaustive machine-readable event path is in `UPGRADE-PATH.json`; raw reads are under `../../evidence/`.

## Birth and reachable historical state

The registry identifies chain ID 1868 and the canonical proxies at `superchain/configs/mainnet/soneium.toml:1-53`. `DEPLOYMENT.json` records a code-presence binary search for each proxy, its first implementation block, and the semantic version it was born with. This chain was born after Bedrock with SystemConfig 2.2.0 / Portal 3.10.0-era components, so pre-Bedrock objects cannot exist in its lineage.

## Executed release path

| release | L1 block | UTC date | transaction | lastUsedOPCM | selected versions after transaction |
|---|---:|---|---|---|---|
| U2 | 22182531 | 2025-04-02 | `0x5f3530e593…` | `0x026b2F158255Beac46c1E7c6b8BbF29A4b6A7B76` | DGF=1.0.1, Portal=3.13.0, SystemConfig=2.4.0 |
| U3 | 22339996 | 2025-04-24 | `0xbe44244e35…` | `0x3a1f523a4bc09cd344a2745a108bb0398288094f` | DGF=1.0.1, Portal=3.14.0, SystemConfig=2.5.0 |
| U16 | 22990670 | 2025-07-24 | `0xdd89a3933d…` | `0x56ebc5c4870f5367b836081610592241ad3e0734` | ASR=3.5.0, DGF=1.2.0, ETHLockbox=1.2.0, Portal=4.6.0, SystemConfig=3.4.0 |
| U16a | 23491328 | 2025-10-02 | `0x744cf7d283…` | `0x8123739c1368c2dedc8c564255bc417feeebff9d` | ASR=3.5.0, DGF=1.2.0, ETHLockbox=1.2.0, Portal=5.0.0, SystemConfig=3.7.0 |
| U17 | 23877377 | 2025-11-25 | `0xf556934cb4…` | `0xfa1ef97fb02b0da2ee2346b8e310907ab5519449` | ASR=3.5.0, DGF=1.3.0, ETHLockbox=1.2.0, Portal=5.1.1, SystemConfig=3.11.0 |
| U18 | 24478557 | 2026-02-17 | `0xeba2fc77f8…` | `0x50f47b43c24f40b92c873fa0704d4207586d0c9f` | ASR=3.7.0, DGF=1.4.0, ETHLockbox=1.2.0, Portal=5.2.0, SystemConfig=3.13.1 |
| U19 | 25397811 | 2026-06-25 | `0xbfdac60c96…` | `0x9ce712ff84e02659846dc6450bb9b7642fe8be5d` | ASR=3.9.0, DGF=1.6.1, DelayedWETH=1.5.1, ETHLockbox=1.3.1, Portal=5.6.1, SystemConfig=3.14.2 |
| U20 | 26048619 | 2026-09-24 | `0x0a0fe86f7b…` | `0x1951828ce913dc4383a8a1695695d537a11d896a` | ASR=3.9.0, DGF=1.6.1, DelayedWETH=1.5.1, ETHLockbox=1.3.1, Portal=5.8.0, SystemConfig=4.0.0 |
| U21 | 26430859 | 2026-11-16 | `0x024770b5fb…` | `0x2d91e6f2bcf6cd1df90e1faf9714e18705ea331f` | ASR=4.0.0, DGF=1.6.1, DelayedWETH=2.0.0, ETHLockbox=2.0.0, Portal=6.1.0, SystemConfig=4.3.0 |

All listed release transactions are marked EXECUTED in `superchain-ops/src/tasks/eth/<task>/README.md:3`; the corresponding OPCM is pinned in each task's `config.toml`. No post-birth release in U2→U21 was skipped. Per-component no-op/skipped upgrades are explicit in `unchangedAtRelease`. Manual prestate, proposer, and ownership operations are in `ancillaryConfigurationAndOwnershipTasks`.

## Ownership, features, and chain-specific parameters at U21

- ProxyAdmin owner: `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`; DGF owner: `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`; SystemConfig owner: `0x509182eC226b3B71D36A3255A80EF0b1A9D43033`.
- Guardian: `0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2` through shared SuperchainConfig `0x95703e…`; `lastUsedOPCM=0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f`.
- ETH lockbox feature `true`, interop `false`, custom gas token `false`.
- `gasLimit=40000000 [4e7]`, EIP-1559 denominator/elasticity `250/10`, `minBaseFee=12000000 [1.2e7]`. These are operator/governance inputs, not hidden implementation differences.

## Custody

| release | block | Portal wei | ETHLockbox wei | L1XDM wei | L1StandardBridge wei |
|---|---:|---:|---:|---:|---:|
| U2 | 22182531 | 12442118868938746738330 | None | 0 | 0 |
| U3 | 22339996 | 12220844299450762675742 | None | 0 | 0 |
| U16 | 22990670 | 0 | 8877050938229307093797 | 0 | 0 |
| U16a | 23491328 | 0 | 7318018292827552040143 | 0 | 0 |
| U17 | 23877377 | 0 | 6243194801028430953370 | 0 | 0 |
| U18 | 24478557 | 0 | 3860070833369666589605 | 0 | 0 |
| U19 | 25397811 | 0 | 2616620564470803012851 | 0 | 0 |
| U20 | 26048619 | 0 | 2185790124415560109941 | 0 | 0 |
| U21 | 26430859 | 0 | 2195560152606106316659 | 0 | 0 |

The U16 `ETHMigrated` event is decoded in `UPGRADE-PATH.json`. At 26433900, balances are `{"ETHLockbox": 2195560152606106316659, "L1StandardBridge": 0, "L1XDM": 0, "Portal": 0}`: no ETH remains in Portal/L1XDM/L1StandardBridge; custody is in the chain's lockbox. Portal pause now delegates to lockbox pause at `OptimismPortal2.sol:305-308`, and lockbox uses its own address as identifier at `ETHLockbox.sol:111-114` (v9 tag).

## Dispute lineage and retained bond custody

| object | address | first-code block | game indices (count) | ETH wei at 26433900 | version |
|---|---|---:|---|---:|---|
| ASR | `0x190b6ecee5a2ddf39669288b9b8daea4641ae8b1` | 22182531 | 1486–2840 (1355) | 0 | `2.2.2` |
| ASR | `0x4890928941e62e273da359374b105f803329f473` | 22990670 | 2841–8536 (5696) | 0 | `4.0.0` |
| ASR | `0x61f89a381e0be13bd8ab356cf4b7301bc97d7522` | 21314185 | 0–1485 (1486) | 0 | `2.0.1-beta.3` |
| DelayedWETH | `0x18fbb58c366e21f395ddec7cba0510a2d9116b47` | 25397811 | 6867–7954 (1088) | 0 | `2.0.0` |
| DelayedWETH | `0x372dc0b87b790d6e1308cf9e7f73f0f1fcbd3754` | 22990670 | 2841–3678 (838) | 0 | `1.5.0` |
| DelayedWETH | `0x70277624cde90492231eb23309e1251beb18dff5` | 23491328 | 3679–6866 (3188) | 0 | `1.5.0` |
| DelayedWETH | `0x9aea1fd851b63d57ba4fc556b0e0c170126c9eaf` | 21314185 | 0–2840 (2841) | 0 | `1.3.0` |

Current respected type is **5**, retirement timestamp `1753380095 [1.753e9]`, anchor `0x50c1c95b0ebce6c4f928ad428f7dc55ada152471e31e0e78c1fae1f34a60a717 at L2 timestamp 1794559147 [1.794e9]`. Every `ImplementationSet`, bond, args, absolute-prestate observation, anchor update, retirement, and blacklist event is retained in `UPGRADE-PATH.json`. v9 accepts a factory-registered game only after blacklist/retirement/finality checks (`AnchorStateRegistry.sol:256-262,286-325,331-352`) and records respect at creation (`SuperFaultDisputeGame.sol:338-340`).

## Game census

Scanned `8537` games in batches of 20 through Multicall3 at L1 block 26433900; types `{1: 7955, 5: 582}`, statuses `{2: 8537}`, claim-valid `5668`, blacklisted `0`. Raw current-proposer flags: `0`; after recognizing documented proposer rotations: `0`. Passive L2 endpoint used for header verification: `https://rpc.soneium.org`. Root-check detail is embedded in the JSON.

## Pause and storage-history notes

The shared config emitted one global pause at block 22,482,108 and unpause at 22,482,160. Its only address-scoped pause was Swell's portal at block 25,689,317, not this chain; it expired after three months under `SuperchainConfig.sol:139-162`. Current chain identifier `0x67B4de6FfA66EF201Ea6099A89cA397D56622E31` has no pause event.

The four OP-only legacy residues (XDM 51/151, bridge 1, portal 54) are zero on this chain; full labelled storage is in STATE-U21.json.

## Coverage limits

L1 logs were scanned from genesis through 26433900; code birth used archive binary search. The census is complete to the factory count observed at the pinned block. L2 header verification was limited to unexpected live games, plus one claim-valid OP control. Balance history is sampled at every executed release plus the migration event and pinned head; intra-release deposits/withdrawals were not reconstructed transaction-by-transaction.
