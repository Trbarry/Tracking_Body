# OP Mainnet chain history (CF5)

Pinned state: Ethereum block **26433900**. Current implementation tag: `op-contracts/v9.0.0` (`ba6fcadb…`). The exhaustive machine-readable event path is in `UPGRADE-PATH.json`; raw reads are under `../../evidence/`.

## Birth and reachable historical state

The registry identifies chain ID 10 and the canonical proxies at `superchain/configs/mainnet/op.toml:1-53`. `DEPLOYMENT.json` records a code-presence binary search for each proxy, its first implementation block, and the semantic version it was born with. OP predates the OPCM deployment model and therefore carries Bedrock-era storage and game objects.

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
- `gasLimit=40000000`, EIP-1559 denominator/elasticity `250/2`, `minBaseFee=0`. These are operator/governance inputs, not hidden implementation differences.

## Custody

| release | block | Portal wei | ETHLockbox wei | L1XDM wei | L1StandardBridge wei |
|---|---:|---:|---:|---:|---:|
| U2 | 22182531 | 483805267105615744591856 | — | 0 | 0 |
| U3 | 22339996 | 301511525285562494391525 | — | 0 | 0 |
| U16 | 22990599 | 0 | 236752243071584240518225 | 0 | 0 |
| U16a | 23491328 | 0 | 184285651037784160207246 | 0 | 0 |
| U17 | 23877377 | 0 | 203290192380985161754577 | 0 | 0 |
| U18 | 24421512 | 0 | 214111932316544015494341 | 0 | 0 |
| U19 | 25397811 | 0 | 177196876605627620804901 | 0 | 0 |
| U20 | 26048619 | 0 | 180279048035126057158656 | 0 | 0 |
| U21 | 26430859 | 0 | 182420511216757812708529 | 0 | 0 |

The U16 `ETHMigrated` event is decoded in `UPGRADE-PATH.json`. At 26433900, balances are `{"ETHLockbox": 182541068255115703234018, "L1StandardBridge": 0, "L1XDM": 0, "Portal": 0}`: no ETH remains in Portal/L1XDM/L1StandardBridge; custody is in the chain's lockbox. Portal pause now delegates to lockbox pause at `OptimismPortal2.sol:305-308`, and lockbox uses its own address as identifier at `ETHLockbox.sol:111-114` (v9 tag).

## Dispute lineage and retained bond custody

| object | address | first-code block | game indices (count) | ETH wei at 26433900 | version |
|---|---|---:|---|---:|---|
| ASR | `0x18dac71c228d1c32c99489b7323d441e1175e443` | 19884569 | 0–7109 (7110) | 0 | `2.0.0` |
| ASR | `0x1c68ecfbf9c8b1e6c0677965b3b9ecf9a104305b` | 22182531 | 7110–9827 (2718) | 0 | `2.2.2` |
| ASR | `0x23b2c62946350f4246f9f9d027e071f0264fd113` | 22990599 | 9828–21388 (11561) | 0 | `4.0.0` |
| DelayedWETH | `0x1b6dbf05eaf22d4e70dc993e8a19dd9f3dcb3162` | 25397811 | 17905–21388 (3484) | 20662782000000000000 | `2.0.0` |
| DelayedWETH | `0x323dfc63c9b83cb83f40325aab74b245937cbdf0` | 21379271 | 5098–9827 (4730) | 80000000000000000 | `1.3.0` |
| DelayedWETH | `0x82511d494b5c942be57498a70fdd7184ee33b975` | 20637593 | 2253–5097 (2845) | 80000000000000000 | `1.1.0` |
| DelayedWETH | `0x9f9b897e37de5052cd70db6d08474550ddb07f39` | 20637594 | 2237–2252 (16) | 0 | `1.1.0` |
| DelayedWETH | `0xd061ab95069987868768818cc1248705351e2d0e` | 23491328 | 11507–17904 (6398) | 0 | `1.5.0` |
| DelayedWETH | `0xe214879ad573693a4c49f7654449caa455cde34f` | 22990599 | 9828–11506 (1679) | 0 | `1.5.0` |
| DelayedWETH | `0xe497b094d6dbb3d5e4caac9a14696d7572588d14` | 19884569 | 0–2236 (2237) | 160000000000000000 | `1.0.0` |

At the U21 state block 26430859, respected type is **9**, retirement timestamp `1753379243`, and anchor snapshot `0x1780727e85b9a6a2f265739802b24afdeb1d3f86b6f8b0bdd762c7b0c6ff0846 at L2 timestamp 1794262423`. Subsequent anchor updates through the pinned head are retained. Every `ImplementationSet`, bond, args, absolute-prestate observation, anchor update, retirement, and blacklist event is in `UPGRADE-PATH.json`. v9 accepts a factory-registered game only after blacklist/retirement/finality checks (`AnchorStateRegistry.sol:256-262,286-325,331-352`) and records respect at creation (`SuperFaultDisputeGame.sol:338-340`).

## Game census

Scanned `21389` games in batches of 20 through Multicall3 at L1 block 26433900; types `{0: 17288, 1: 617, 8: 2190, 9: 1294}`, statuses `{0: 85, 1: 145, 2: 21159}`, claim-valid `11312`, blacklisted `0`. Raw current-proposer flags: `12`; after recognizing documented proposer rotations: `1`. Passive L2 endpoint used for header verification: `http://127.0.0.1:7546`. Root-check detail is embedded in the JSON.

## Pause and storage-history notes

The shared config emitted one global pause at block 22,482,108 and unpause at 22,482,160. Its only address-scoped pause was Swell's portal at block 25,689,317, not this chain; it expired after three months under `SuperchainConfig.sol:139-162`. Current chain identifier `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43` has no pause event.

OP alone retains non-zero legacy spacers: XDM slots 51/151, bridge slot 1, portal slot 54. At v9 they are declared private spacers (`CrossDomainMessenger.sol:40,63`, `StandardBridge.sol:38`, `OptimismPortal2.sol:82`) and no executable path reads them.

## Coverage limits

L1 logs were scanned from genesis through 26433900; code birth used archive binary search. The census is complete to the factory count observed at the pinned block. L2 header verification was limited to unexpected live games, plus one claim-valid OP control. Balance history is sampled at every executed release plus the migration event and pinned head; intra-release deposits/withdrawals were not reconstructed transaction-by-transaction.
