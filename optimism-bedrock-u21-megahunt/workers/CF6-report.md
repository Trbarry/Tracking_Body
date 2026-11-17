# CF6 — Historical harness engineer mirror report

## Outcome

Built the requested self-contained Foundry project at
`mirror/CF6/`. It contains historical fork points, passive fixture generators, exact official
upgrade replays, real in-flight objects, cross-upgrade carry tests, a five-call differential runner,
and four-chain L1 handles. No public transaction was sent; every state change occurred inside a
Foundry fork.

No candidate survived. This worker produced two preservation primitives and two evidenced
rejections.

## Facts locked

### Historical implementation history

`mirror/CF6/op-upgrade-blocks.json` records block-end implementation state for seven contracts.
`HistoricalForkTest::test_all_named_fork_points_are_durable_slot_discontinuities` independently
selected the block before and after all 22 named discontinuities and passed.

| Contract | Durable changes |
|---|---:|
| OptimismPortal | 13 |
| SystemConfig | 14 |
| L1CrossDomainMessenger / AddressManager entry | 15 |
| L1StandardBridge / ChugSplash slot | 11 |
| DisputeGameFactory | 6 |
| AnchorStateRegistry | 4 |
| ETHLockbox | 3 |
| **Total** | **66** |

Earliest recorded points are the messenger AddressManager entry at block 12686756 and bridge slot
at 12686787. Bedrock's staged transition is visible at blocks 17422444 and 17423158. Contract proxy
deployment blocks and every before/after address are in the JSON. Transient StorageSetter hops that
start and end inside one transaction are not separately forkable and are explicitly excluded.

Locator basis at pinned v9 commit `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`:
`src/universal/Proxy.sol:102-109`, `src/legacy/L1ChugSplashProxy.sol:155-161`,
`src/legacy/ResolvedDelegateProxy.sol:33-40`, and `src/legacy/AddressManager.sol:13-38`.

### Official release replays

`UpgradeReplayTest` reconstructs the historical outer call from passive raw transaction fixtures,
uses the actual block number/timestamp, and compares all seven implementation locators with archive
post-state.

| Release | Block | Transaction | Result |
|---|---:|---|---:|
| v5 | 23877377 | `0xf556934cb4de1ab40a4cfba17856cd601cbc8b875b96a9ccd8ee32bcd363abf5` | pass |
| v6 | 24421512 | `0x8808cd53114e4cf07bfde30daf24f2984d4a40ab09c5ca67bd171ac29d6dbf37` | pass |
| v7 | 25397811 | `0xbfdac60c9687a2e469159bf2458e73de2915a0a5eb53c4991a7ecde2b1fb3f15` | pass |
| v8 | 26048619 | `0x0a0fe86f7b1a3d3d2d0be990e3f8b15628b885363ae527fa9548cb2c2375741a` | pass |
| v9 | 26430859 | `0x024770b5fba87683ee1466562eefb1bcb408c29c764e24abd07c7d4050a82a99` | pass |

Result: **5/5 pass** (`test_replay_v5` ... `test_replay_v9`). Release-source corroboration:
develop notices `archive/upgrade-18.mdx:63-67` (v6), `archive/upgrade-19.mdx:105-113` (v7),
`archive/upgrade-20.mdx:300-311` (v8), and `upgrade-21.mdx:23-26` (v9).

### Real in-flight objects

`InFlightObjectsTest` is **4/4 pass**:

1. v7 deposit through `depositTransaction`, with a real `TransactionDeposited` event.
2. Real v7 proof tx `0xb88907…3badc`, block 25398530, reconstructed withdrawal hash equals
   logged hash and `provenWithdrawals` is written.
3. Real v7 failed finalization tx `0x8c8999…d27622`, block 25475826, reconstructed message hash
   equals the real `FailedRelayedMessage` hash and `failedMessages` is written.
4. Permissionless type-8 game creation at the v7 fork, exact bond, status `IN_PROGRESS`.

Both event fixtures were retrieved in explicit 10,000-block windows by
`script/fetch_inflight_fixtures.py`. Protocol sources: pinned v7
`src/L1/OptimismPortal2.sol:368-469` and `src/dispute/DisputeGameFactory.sol:142-163`.

Populated era: **v7 only** for the four object classes. Older proof/message eras remain partial.

### Carry-through

`CarryThroughTest` is **2/2 pass**.

- `test_v7_proof_survives_v8_v9_and_finalizes`: real v7 SequencerFeeVault proof tx
  `0x2a1b15…d0d1c`, withdrawal hash `0x612a09…3ad08`. Proof timestamp was bit-equal after official
  v8 and v9 replays. v9 `checkWithdrawal` passed, finalization succeeded, and target balance delta
  equaled `withdrawal.value`.
- `test_v7_failed_message_replays_after_v8_v9`: message hash `0x43e0b7…bd0deb` stayed failed and
  not successful through both upgrades. Permissionless v9 replay returned normally and failed at
  the historical target again, preserving retryability.

`vm.makePersistent` retains only the protocol-created object-owning proxy while `vm.rollFork`
refreshes Safe nonces, helper deployments, games, and unrelated accounts from each real pre-upgrade
block. No object is inserted with `vm.store`.

### Differential and four chains

`DifferentialRunnerTest::test_differential_five_permissionless_calls` passed. Exact table:
`mirror/CF6/differential-results.md`. Deposit, donate, and sendMessage outcomes/deltas are identical
at blocks 26430858/26430859. Unknown `checkWithdrawal` reverts on both. Unknown
`deleteProvenWithdrawal` changes from empty-selector fallback revert (v8) to the v9 unproven error.

`MultiChainTest::test_same_body_validates_four_l1_deployments` passed for OP (10), Ink (57073),
Soneium (1868), and Unichain (130): SystemConfig -> portal/messenger/bridge/DGF plus portal ->
ASR/lockbox/ProxyAdmin all equal the hardcoded handles at block 26430859. Getter basis: pinned v9
`src/L1/SystemConfig.sol:276-331`.

## Verification summary

Named suites: Historical 1/1; upgrade replay 5/5; objects 4/4; carry 2/2; differential 1/1;
multichain 1/1. **Total 14/14 pass**, all with `forge test -j 1`.

## Outputs

- Project/readme/scripts/tests/fixtures/results: `mirror/CF6/`
- Primitives: `primitives/PRIM-CF6-01.md`, `primitives/PRIM-CF6-02.md`
- Rejections: `rejected/REJ-CF6-01.md`, `rejected/REJ-CF6-02.md`
- Candidate files: none.

## Partial / limits

- Ready-made transaction replays stop at v5; earlier boundaries exist but earlier governance
  transactions are not packaged.
- Bedrock/L2OutputOracle and intermediate withdrawal-proof fixtures were not populated.
- Only one real v7, zero-value failed message was carried; value-bearing and legacy nonce versions
  are untested.
- Four-chain coverage is L1 only. A dual L1/L2 devstack is out of reach here.
- Block-end scans cannot expose an implementation installed and removed inside one transaction.

## Three-line use

```bash
cd /home/user/Tracking_Body/optimism-bedrock-u21-megahunt/mirror/CF6
python3 script/discover_upgrades.py --head 26430859 --out op-upgrade-blocks.json
forge test -j 1 -vv
```

## Next wave

1. Populate a pre-fault-proof/L2OutputOracle proof at each semantic portal era and carry it through
   the U7 ASR transition, then v5-v9.
2. Carry pre-Bedrock nonce-version messages across the messenger's zero-address bricking windows at
   blocks 13596294/13596781 and the Bedrock 17422444/17423158 stages.
3. Repeat the failed-message carry with real value-bearing messages and compose replay with pause and
   lockbox migration. No candidate score: **no candidate**.
