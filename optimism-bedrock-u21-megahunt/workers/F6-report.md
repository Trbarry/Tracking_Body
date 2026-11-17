# F6 report: historical harness engineer (Track A, blind)

Worker F6, 2026-11-17. This was a resumed run: the first instance hit the Mythos rate limit.
**Model: Opus 5.5 (`claude-opus-5-5`), not Mythos 5.2.** The Mythos quota is exhausted until
2026-11-22 00:00 UTC. The user approved this exception; it is recorded in `/home/user/Tracking_Body/CLAUDE.md`.

What I did not do:
- I read no audit material.
- I sent nothing to any network. All forks are in-process forks of the read-only archive `:7545`.
- I started no anvil.
- I wrote nothing under `optimism-u21-novel-hunt/`.

Privileged senders were pranked only to replay the official upgrade transactions.

## Result: 59 of 59 tests pass

Command: `cd test && forge test -j 1`. Log: `evidence/F6-forge-test-run.txt`.

The full run gave 58 passes. `test_transact_U16A_V4_1` failed once because the archive proxy returned "could not get transaction". It passed on retry.

## Per piece

| piece | status | verified by (pass count) |
|---|---|---|
| 1. `HistoricalFork.sol` | **done** | See 1 below. 2/2 tests. |
| 2. `UpgradeReplay.sol` | **done** | See 2 below. 38/38 tests. |
| 3. `InFlightObjects.sol` | **done** | See 3 below. 4/4 tests. |
| 4. `CarryThrough.t.sol` | **done** (new) | See 4 below. 6/6 tests. |
| 5. `MultiChain.sol` | **done** | See 5 below. 3/3 tests. |
| helpers | done | `PersistProbeTest` (2/2) pins the `rollFork` + `makePersistent` semantics. `FixtureE2ETest` (4/4) is the PASS A post-U21 fixture. |

### 1. `HistoricalFork.sol`

- 19 named fork points, from BEDROCK_STEP1 (17422444) to U21_V9 (26430859).
- The fork-point JSON is cross-checked against F2's implementation history: `evidence/F6-f2-crosscheck.txt`.
  - OptimismPortal, SystemConfig, DisputeGameFactory, AnchorStateRegistry and ETHLockbox: equal.
  - L1CrossDomainMessenger and L1StandardBridge: F2 also has five changes from 2021 (pre-Bedrock OVM), which are outside F6's range.
- `test_table_matches_chain_at_every_point`: all 14 implementation pointers match the chain before and after every point (38 pins on one fork). Output: `evidence/F6-fork-point-versions.md`.
- `test_named_points_and_era_lookup` also passes.

### 2. `UpgradeReplay.sol`

- **All 19 points are replayed in prank mode.** For each one, every slot the replay wrote equals the real end-of-block state: 0 mismatches each (`evidence/F6-replay/<LABEL>.txt`).
- The last five upgrades wrote these numbers of distinct slots: U17 28, U18 139, U19 508, U20 375, U21 339. U21's 339 equals PASS A's figure.
- All 19 transact-mode replays pass.
- Fix 1, SUPERCHAIN_CONFIG_INIT: its proxy and implementation are created earlier in the same block. The fixture now carries those txs as `preTransact`, plus a `postTxs` entry for the following `changeAdmin` tx (script `scripts/f6_gen_harness_data.py`).
- Fix 2: a `vm.transact` after a pranked write to the same account drops that write. So `postTxs` are replayed in the same mode as the upgrade tx itself.

### 3. `InFlightObjects.sol` — eras populated

| object | eras populated | detail (`evidence/F6-objects-*.md`) |
|---|---|---|
| deposit | 18 of 18 (BEDROCK..U21) | ETH goes to the portal before U16 and to the lockbox from U16 on. |
| proven withdrawal, real prove tx replayed | 18 of 18 | Stored proof equals mainnet. U13_V2 p0 is a real re-prove on mainnet. |
| fresh-submitter proof (an object that never existed on mainnet) | 11 of 12 fault-proof eras | U17 p0 is a wrapped tx; U17 p1 works. |
| failed messenger message | 10 of 18 | The other 8 eras have no `FailedRelayedMessage` log: 23 logs in total from Bedrock to head, 0 refused ranges. |
| game in progress plus a new `create()` | 12 of 12 fault-proof eras | Type 9 needs `rootClaim == keccak(extraData)`; I fixed `_createGameLike` for that. |

Two bugs in the previous instance's tests were fixed:
- the `_eras()` array was sized 17 for 18 points;
- the prove check wrongly rejected re-proves.

### 4. `CarryThrough.t.sol` — outcome per stage in `evidence/F6-carry-*.md`

**(a) Withdrawals**, carried from three starting eras:
- **U17 p1 (4 replays) and U16A p1 (5 replays):** the proof survives every stage. Finalization works from U19 (respectively U18) on, and under v9 it succeeds. The lockbox pays exactly the withdrawal value (150000000000000 and 1919747470310000 wei) and the message relays successfully.
- **U14 p0 (7 replays):** the proof survives, but from U16A on finalization reverts with `OptimismPortal_InvalidRootClaim` (the game is not claim-valid from that stage on). This is the intended invalidation of pre-U16 proofs. The real 0.004 ETH withdrawal (`0x3d0aacb4…`) is still unfinalized on mainnet; it needs a new proof.

**(b) Failed messages:** U18 m0 (3 replays) and U14 m3 (7 replays) stay failed at every stage. Replaying them under v9 emits `FailedRelayedMessage` again (target: L1StandardBridge).

**(c) Differential runner, v8 vs v9 (blocks 26430858 / 26430859):** all five calls give the same outcome and the same balance deltas. Log bytes differ only in deposit nonces and in one third-party target's event.

**Staleness of carried slots:** only portal slot 1 (resource-metering `params`) differs from the real chain, which does not affect these results.

### 5. `MultiChain.sol`

- `OpChain` handles for OP Mainnet, Ink, Soneium and Unichain; I renamed the struct from `Chain` because it collided with forge-std's `StdChains.Chain`.
- The handles equal the values each chain's SystemConfig returns, both pre-U21 (26430858) and post-U21 (26433900).
- `_forEachChain` runs a real deposit on all four chains.

## Partial / limits

- No carry starts before fault proofs (the L2OutputOracle-era proofs, before V1_4_0_FP), although the helpers support it.
- Old eras run under `osaka` gas rules.
- A cold run needs about an hour of RPC fetches.

## Primitives and candidates

No primitives or candidates; this is infrastructure. Edges for the next wave:
1. L2OutputOracle-era proofs carried through V1_4_0_FP.
2. Unfinalized pre-U16 proven withdrawals with value.
3. Old failed messages that replay successfully with full gas (BEDROCK m0, V1_4 m0).

## Usage recipe

```solidity
contract T is InFlightObjects { function test_x() public {
  EraProve memory p = _loadEraProve("U17_V5", 1); _forkAt(p.proveBlock - 1); vm.makePersistent(OP_PORTAL); vm.roll(p.proveBlock); vm.warp(p.proveTimestamp); _proveAs(p, address(0xF6));
  _carry(_point("U17_V5"), _point("U21_V9"), ReplayMode.Prank); _tryFinalize(p.wd, address(0xF6)); } }
```

Exact commands: `test/README.md`.
