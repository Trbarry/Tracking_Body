# CF6 historical OP Mainnet harness

Self-contained Foundry infrastructure for replaying OP Mainnet L1 contract history through
`op-contracts/v9.0.0` / Upgrade 21. All RPC activity is passive. Tests mutate only Foundry's
in-process forks; there is no broadcast path in this project.

The project is pinned to Ethereum mainnet block `26430859` for U21 and uses the read-only archive
proxy at `http://127.0.0.1:7545`. `lib/forge-std` is a symlink, as requested.

## Three-line usage recipe

```bash
cd /home/user/Tracking_Body/optimism-bedrock-u21-megahunt/mirror/CF6
python3 script/discover_upgrades.py --head 26430859 --out op-upgrade-blocks.json
forge test -j 1 -vv
```

The full suite is intentionally slow because five governance transactions and 44 historical fork
boundaries are replayed from archive state. For a fast smoke run:

```bash
forge test -j 1 --match-contract InFlightObjectsTest -vv
forge test -j 1 --match-contract DifferentialRunnerTest -vv
forge test -j 1 --match-contract MultiChainTest -vv
```

Refresh the passive transaction fixtures with:

```bash
python3 script/fetch_upgrade_fixtures.py --out-dir fixtures
python3 script/fetch_inflight_fixtures.py --out-dir fixtures
```

## Contents

- `test/HistoricalFork.sol`: 22 named, durable block-end discontinuities covering 66 contract
  implementation changes. `op-upgrade-blocks.json` contains before/after implementations,
  transaction hashes where emitted, storage locators, and per-contract histories.
- `test/UpgradeReplay.sol`: generic raw `from/to/value/data/gas` replay plus ready-made v5, v6,
  v7, v8, and v9 tests. Each test compares seven implementation locators with real post-state.
- `test/InFlightObjects.sol`: protocol-only creation/replay of a deposit, v7 proof, real v7 failed
  messenger message, and permissionless type-8 dispute game in progress.
- `test/CarryThrough.t.sol`: v7 proof and failed-message carry-through across official v8/v9
  replays, plus a generic two-fork outcome differential.
- `test/MultiChain.sol`: one `ChainHandles` body for OP Mainnet, Ink, Soneium, and Unichain.
- `differential-results.md`: generated five-call v8/v9 outcome table.

## Verified results

All commands used `-j 1`.

| Piece | Named verification | Result |
|---|---|---:|
| Historical forks | `test_all_named_fork_points_are_durable_slot_discontinuities` | 1/1 pass |
| Upgrade replay | `test_replay_v5` through `test_replay_v9` | 5/5 pass |
| In-flight objects | four `InFlightObjectsTest` tests | 4/4 pass |
| Carry-through | two `CarryThroughTest` tests | 2/2 pass |
| Differential | `test_differential_five_permissionless_calls` | 1/1 pass |
| Four-chain handles | `test_same_body_validates_four_l1_deployments` | 1/1 pass |
| Total | named tests above | **14/14 pass** |

The v7 SequencerFeeVault proof retained the same proof timestamp after exact v8 and v9 upgrade
calls, passed v9 `checkWithdrawal`, finalized, and increased the target balance by exactly
`withdrawal.value`. The v7 failed-message bit remained set across both upgrades; replay after v9
returned normally and emitted the failed path again, leaving it retryable.

Upgrade blocks and transaction hashes independently fixed by archive state:

| Release | Block | Official transaction |
|---|---:|---|
| v5 | 23877377 | `0xf556934c…63abf5` |
| v6 | 24421512 | `0x8808cd53…d6dbf37` |
| v7 | 25397811 | `0xbfdac60c…fb3f15` |
| v8 | 26048619 | `0x0a0fe86f…75741a` |
| v9 / U21 | 26430859 | `0x024770b5…a82a99` |

## Historical discovery semantics

Six targets use the EIP-1967 implementation slot. The legacy messenger resolves its implementation
from the AddressManager mapping; the eventless ChugSplash bridge stores its implementation in the
same EIP-1967 slot. The bridge history is sampled at no more than 10,000-block intervals and each
changed interval is refined by binary search. EIP-1967/AddressManager event blocks are independently
checked against storage at `block - 1` and `block`.

`op-upgrade-blocks.json` reports selectable block-end state. A StorageSetter installed and removed
inside one transaction is not a separate fork point because no Ethereum block exposes that state.
The discovery script states the related A→B→A checkpoint limitation explicitly.

Pinned source basis (commit `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`):

- `src/universal/Proxy.sol:102-109` stores and emits EIP-1967 implementation updates.
- `src/legacy/L1ChugSplashProxy.sol:155-161` writes the bridge implementation locator.
- `src/legacy/ResolvedDelegateProxy.sol:33-40` resolves through AddressManager, whose mapping is
  defined at `src/legacy/AddressManager.sol:13-38`.
- `src/L1/SystemConfig.sol:276-331` defines the cross-chain address getters used by `MultiChain`.

Pinned v7 source basis (commit `a7c88c8d636ceb9944ea0edaf7d033da258778ab`):

- `src/L1/OptimismPortal2.sol:368-469` is the real proof path and proof write.
- `src/dispute/DisputeGameFactory.sol:142-163` is the permissionless create/bond path.
- `src/dispute/FaultDisputeGame.sol:242-299` initializes a newly created game as in progress.

Release notices identify v6 at `notices/archive/upgrade-18.mdx:61-67`, v7 at
`notices/archive/upgrade-19.mdx:105-112`, v8 at `notices/archive/upgrade-20.mdx:300-311`, and v9
at `notices/upgrade-21.mdx:23-26` in the pinned develop checkout.

## Partial coverage and limits

- Object fixtures are populated for the v7 era: deposit, proof, failed message, and dispute game.
  Bedrock/L2OutputOracle and intermediate proof-era fixtures were not populated. The two real event
  fixtures were re-queried in explicit 10,000-block windows and include their complete calldata.
- Ready-made full transaction replays cover the requested last five releases only. Earlier exact
  implementation boundaries are selectable and verified, but their governance transactions are not
  packaged as replay fixtures.
- The four-chain helper validates L1 deployments at block 26430859; it does not assert L2 state.
- A dual L1/L2 devstack is out of reach here. No claim relies on one.
- The carry tests use `vm.makePersistent` only to retain the protocol-created object-owning proxy
  while the fork base advances. Upgrade senders are impersonated solely to reproduce already-mined
  official governance calls. No object is inserted with `vm.store`.
