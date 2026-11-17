# test/poc — Lane 11 executable suites (real-withdrawal fixture, invariants, differential, gas fuzz)

Everything here runs in-process in `forge test` against the local anvil forks (`l1` = post-U21
v9 code @ 26433900, `l1pre` = v8 code @ 26430858). Nothing is broadcast anywhere.

## 0. Install into a lane harness

```bash
H=/home/user/Tracking_Body/optimism-u21-novel-hunt
cp -r /home/user/u21-work/template /home/user/u21-work/<lane-id>-fx && cd /home/user/u21-work/<lane-id>-fx
for f in U21Fixtures.sol U21GasScan.sol FixtureE2E.t.sol GasBoundary.t.sol InjectedGas.t.sol \
         Differential.t.sol PortalInvariants.t.sol NestedReplay.t.sol L2RelayGas.t.sol; do cp $H/test/poc/$f test/; done
cp $H/test/poc/foundry.toml.lane11 foundry.toml      # template + evm_version "osaka" + unlimited test gas
mkdir -p evidence && cp -r $H/evidence/withdrawal-fixtures evidence/   # split per-fixture JSON (fast loader)
forge test -j 1 --match-path test/FixtureE2E.t.sol -vv   # proves the fixture works end to end
```

`foundry.toml.lane11` differs from the template in two lines: `evm_version = "osaka"` (mainnet
rules at the pin; the template says cancun, which would ignore EIP-7702 delegations) and
`gas_limit = "18446744073709551615"` (the gas scans do 10^4–10^5 probes per test). Only
`U21Fixtures.sol` + the `evidence/withdrawal-fixtures/` directory are needed to reuse the fixture.
The suites write their outputs to `evidence/` of the harness; lane 11's outputs are archived in
`$H/evidence/lane11/`. Helper scripts (log fetch, calldata decoding, fixture generation, result
tables, diff) are in `lane11-tools/` (paths inside them point at `/home/user/u21-work/lane-11`).

Use `-j 1`: the shared anvils sit behind a rate-limited upstream (HTTP 429 when several tests
fetch cold state in parallel). Second runs are served from the anvil cache and are fast.
Guard memory with `ulimit -v 6000000` — a scan that forgets `vm.revertToStateAndDelete`
(instead of `vm.revertToState`) grows to >6 GB and gets OOM-killed (this happened once).

## 1. The real-withdrawal fixture

Source: every `WithdrawalProven` / `WithdrawalProvenExtension1` / `WithdrawalFinalized` /
`WithdrawalProofDeleted` log of the OP Mainnet portal `0xbEb5…06Ed` in L1 blocks
26363900..26433900 (1347 logs, fetched with `eth_getLogs` in 2000-block windows; publicnode
refuses ranges older than ~8k blocks as "archive", `https://rpc.mevblocker.io` served them).
355 distinct withdrawal hashes were proven in the window, 221 of them are finalized at the `l1`
pin; the other **134 hashes (145 proof entries)** are the fixture population.

Each `Types.WithdrawalTransaction` was reconstructed from the calldata of the L1 prove
transaction (selector `0x4870496f`; one transaction batches 9 proofs through a Safe/MultiSend, the
decoder matches every embedded call to its logged hash). The loader re-hashes every struct
(`keccak256(abi.encode(nonce,sender,target,value,gasLimit,data))`) and requires equality with the
logged `withdrawalHash`.

Files (under `evidence/`):

| File | Content |
|---|---|
| `withdrawal-fixtures-all.json` | all 145 unfinalized proof entries + 2 reference entries, with the exact prove calldata |
| `withdrawal-fixtures.json` | curated 31 fixtures + 2 reference entries (single file, same schema) |
| `withdrawal-fixtures/index.json`, `f<i>.json`, `ref<i>.json` | the curated set split per fixture — this is what the Solidity loader reads (parsing the 300 KB single file per key costs ~250 M gas / 40 s) |

Schema of one fixture: `hash`, `nonce`, `sender`, `target`, `value`, `gasLimit`, `data`
(the struct), `proofSubmitter`, `proveTx`, `proveTxFrom`, `proveTxTo`, `proveBlock`,
`proofTimestamp` (= `provenWithdrawals[hash][submitter].timestamp` at the `l1` pin),
`proveTxTimestamp`, `supersededByReprove`, `postU21`, `gameIndex`, `game`, `gameType`,
`gameStatusAtPin`, `gameCreatedAt`, `gameResolvedAt`, `gameClaimValidAtPin`, `matureAtPin`,
`kind` (`messenger` = sender `0x42…07` / `plain`), `hasValue`, `multiSubmitter`, `class`,
`proveCalldata` (exact mainnet `proveWithdrawalTransaction` calldata, replayable by any
submitter), and for messenger withdrawals `inner` = decoded `relayMessage` arguments.

Classes in the population (all against type-9 SUPER_CANNON_KONA games, impl `0x19AF…3208`, v0.8.0):

| class | meaning at the `l1` pin | all / curated |
|---|---|---|
| `pre_mature_valid` | proven before U21, older than 7 d, game finalized DEFENDER_WINS → finalizable with **no** setup | 24 / 8 |
| `pre_immature_gamefinal` | proven before U21, game already claim-valid, proof not yet 7 d old | 36 / 6 |
| `pre_immature_resolved` | game DEFENDER_WINS, air-gap not over | 35 / 4 |
| `pre_immature_inprogress` | game still IN_PROGRESS | 46 / 9 (2 plain) |
| `post_inprogress` | proven AFTER U21 (v9 portal) against an IN_PROGRESS game | 3 / 3 |
| `pre_challenger_wins` | forged proof against a game that resolved CHALLENGER_WINS | 1 / 1 (plain, 90 000 ETH) |

Notable real fixtures: f1–f4 are **legacy version-0 (pre-Bedrock) messages** (`msgNonce` 7973…,
selector `finalizeETHWithdrawal`); f0/f16 carry the **old L2 `baseGas` formula**
(`285000 + 16·len + minGas·64/63`, no 21 000 and no 260-byte encoding overhead); f13/f15 are
`SequencerFeeVault → 0xa3d5…adea` plain withdrawals with 53.5 / 27.2 ETH; f23–f28 are three
hashes proven by **two different submitters** against different games; f9 is the forged proof
(see `primitives/PRIM-1101.md`); `ref0/ref1` were finalized on mainnet by v9 code between the two
pins (unfinalized + mature on `l1pre`).

### Solidity base — `U21Fixtures.sol`

```solidity
import "./U21Fixtures.sol";
contract MyTest is U21FixtureBase {
    function setUp() public { vm.createSelectFork("l1"); }
    function test_x() public {
        Fixture memory f = _findFixture("post_inprogress", /*messenger*/ true, /*hasValue*/ true);
        require(_makeFinalizable(f));           // warp + game.resolveClaim()/resolve() + warp
        _finalizeAs(f, address(0xBEEF));        // permissionless external-proof entry point
    }
}
```

* `_loadFixture(i)`, `_loadRef(i)`, `_findFixture(class, messenger, hasValue)`, `_fixtureCount()`.
* `_resolveGameHonestly(game)` — warps to `createdAt + maxClockDuration + 1` (twice that if a
  contested subgame needs it), calls `resolveClaim(i,0)` from the last claim down and `resolve()`.
* `_makeFinalizable(f)` — the above plus a warp past `max(proof + 7 d, resolvedAt + 3.5 d)`, then
  `checkWithdrawal` must pass. Returns false when the game resolves CHALLENGER_WINS.
* `_finalizeAs`, `_finalizeWithGas(f, gas)`, `_reproveAs(f, submitter)` (replays `proveCalldata`),
  `messageHash(wd)` (= v1 cross-domain hash = `keccak256(wd.data)`), `decodeInner(wd)`.

**Pranks/cheats needed on the honest path: none except `vm.warp`** (and `vm.prank(caller)` to pick
the caller of a permissionless function). No `vm.store`, no privileged role, no mock.
`FixtureE2E.t.sol::test_e2e_all_fixtures` finalizes 30 of the 31 curated fixtures on `l1`
(the 31st is the forged proof: `OptimismPortal_InvalidRootClaim`), output in
`evidence/lane11/e2e-l1.json`.

Cold-access note: accesses made in `setUp()` do not warm the test body, and
`vm.revertToState` restores coldness (measured: 300 220 gas first touch = after revert; 236 220
when warmed). Do all preparation in `setUp()` if you measure gas.

## 2. Suites

| File | What | How to run |
|---|---|---|
| `FixtureE2E.t.sol` | integrity of every fixture vs chain state; e2e finalization of all fixtures | `U21_FORK=l1 forge test -j 1 --match-path test/FixtureE2E.t.sol -vv` |
| `U21GasScan.sol` | shared probe machinery: outcome class of `finalize…ExternalProof{gas:g}` from a cold snapshot, with ETH accounting on every probe | (library) |
| `GasBoundary.t.sol` | REAL fixtures: binary search of the minimum gas, every gas value ±`U21_DENSE` around the boundaries, coarse sweep from 0; plus a gas fuzz | `U21_FORK=l1pre|l1 U21_DENSE=800 forge test -j 1 --match-path test/GasBoundary.t.sol -vv` |
| `InjectedGas.t.sol` | **HARNESS-ONLY injected** withdrawals (`vm.store` of one `provenWithdrawals` entry pointing at a real valid game): inner message size / minGasLimit / value / target behaviour (ok, revert, burn-all-gas, return-bomb, re-enter, empty account, EOA, EIP-7702 delegated) on the real portal + messenger bytecode | `U21_FORK=l1pre|l1 U21_SET=1|2|3 U21_TAG=-S1 forge test -j 1 --match-path test/InjectedGas.t.sol -vv` |
| `Differential.t.sol` | D1 getters, D2 re-prove, D3 deposits (0…120 001 bytes), D4 finalize with a failing messenger, D5 pause identifiers, D6 `deleteProvenWithdrawal` — `key := value` lines per fork | run with `U21_FORK=l1pre` then `l1`, diff with `python3 lane11-tools/diff.py` |
| `NestedReplay.t.sol` | finalizing a real victim withdrawal from inside an L1CDM replay → forced `failedMessages` at any gas (PRIM-1102), both forks | `U21_FORK=l1pre|l1 forge test -j 1 --match-path test/NestedReplay.t.sol -vv` |
| `L2RelayGas.t.sol` | fork `l2`: the un-upgraded L2CDM 2.2.1 relaying L1→L2 messages with the protocol-fixed gas; size × target matrix (PRIM-1103) | `forge test -j 1 --match-path test/L2RelayGas.t.sol -vv` |
| `PortalInvariants.t.sol` | stateful invariant campaign on `l1` (handlers: deposit, sendMessage, donateETH, prove-replay by other submitters, finalize own/external/random gas, messenger replay, deleteProvenWithdrawal, warp, adversarial `vm.etch` targets, guardian pause/unpause/blacklist) | `FOUNDRY_INVARIANT_RUNS=24 FOUNDRY_INVARIANT_DEPTH=40 forge test -j 1 --match-path test/PortalInvariants.t.sol -vv` |

Outcome classes used by the gas suites: `REVERTED`, `FINALIZED_RELAYED` (successfulMessages),
`FINALIZED_FAILEDMSG` (failedMessages → replayable), `FINALIZED_NEITHER` (finalized, recorded
nowhere → unreplayable), `FINALIZED_PLAIN_OK`, `FINALIZED_PLAIN_FAIL`.

Results, numbers and coverage limits: `lanes/LANE-11-report.md`; raw outputs: `evidence/lane11/`.
