# F6 historical harness (OP Mainnet L1, Bedrock -> Upgrade 21)

Self-contained Foundry project (forge-std only). Every fork is created from the local read-only
L1 archive proxy `http://127.0.0.1:7545`. Nothing is broadcast. Privileged senders are pranked
only to replay official upgrade transactions that already executed on mainnet, during setup.

## Layout

| file | piece | what it gives you |
|---|---|---|
| `src/HistoricalForkData.sol` | 1 | generated table of 19 fork points (block, timestamp, tx hashes, impl before/after for 14 proxies). Regenerate with `python3 ../scripts/f6_gen_harness_data.py` |
| `src/HistoricalFork.sol` | 1 | `_forkBefore(i)`, `_forkAfter(i)`, `_rollBefore/_rollAfter`, `_point("U19_V7")`, `_eraOf(block)`, `_impl(c)`, `_assertImpls(i, after)` |
| `src/UpgradeReplay.sol` | 2 | `_replayUpgrade(i, mode)` (Prank or vm.transact), `_forkAndReplay`, `_carry(from, to, mode)`, `_replayUpgradeRecording` + `_compareWithRealPostState` |
| `src/InFlightObjects.sol` | 3 | era fixture loaders, `_deposit`, `_proveReal` / `_proveAs`, `_matureProof`, `_tryFinalize*`, `_produceFailedReal`, `_replayFailed`, `_findGameInProgress`, `_createGameLike`, `_outcome` |
| `src/MultiChain.sol` | 5 | `OpChain` handles for OP Mainnet, Ink, Soneium, Unichain; `_resolveChain` (from SystemConfig), `_forEachChain(this.body)` |
| `src/Ifaces.sol`, `src/U21Fixtures.sol` | - | minimal interfaces for every era; PASS A post-U21 withdrawal fixture (copy) |
| `fixtures/upgrades/<LABEL>.json` | 2 | the real upgrade transaction(s) of each fork point (from, to, value, gas, input) |
| `../evidence/F6-era-fixtures/<ERA>/p<i>.json, m<i>.json` | 3 | real prove transactions and real FailedRelayedMessage-producing transactions per era |

Fork point labels (block): BEDROCK_STEP1 17422444, BEDROCK 17423158, PROTOCOL_VERSIONS_INIT 18367320,
SUPERCHAIN_CONFIG_INIT 19064589, V1_2_0 19314493, V1_3_0 19634866, FP_PROXIES_INIT 19884570,
V1_4_0_FP 20062696, V1_6_0_ASR 20723924, V1_8_0 21695024, U13_V2 22182531, U14_V3 22339996,
U16_V4 22990599, U16A_V4_1 23491328, U17_V5 23877377, U18_V6 24421512, U19_V7 25397811,
U20_V8 26048619, U21_V9 26430859.

## Commands (always single-threaded)

```bash
cd /home/user/Tracking_Body/optimism-bedrock-u21-megahunt/test
forge build
forge test -j 1 --list

# 1. fork-point table == chain at all 19 points (38 pins, one fork)       ~70 s
forge test -j 1 --match-contract HistoricalForkTest -vv
# cheatcode semantics that _carry relies on (rollFork + makePersistent)
forge test -j 1 --match-contract PersistProbeTest -vv

# 2. upgrade replays: prank replay + every written slot vs the real end-of-block state
forge test -j 1 --match-contract UpgradeReplayTest --match-test 'test_prank_U(17|18|19|20|21)' -vv
forge test -j 1 --match-contract UpgradeReplayTest --match-test 'test_prank_' -vv      # all 19
forge test -j 1 --match-contract UpgradeReplayTest --match-test 'test_transact_' -vv   # vm.transact mode

# 3. in-flight objects in every era
forge test -j 1 --match-contract InFlightObjectsTest -vv

# 4. carry-through and differential runner
forge test -j 1 --match-contract CarryThroughTest --match-test test_differential_five_calls -vv
F6_DIFF_A=24421511 F6_DIFF_B=24421512 forge test -j 1 --match-test test_differential_five_calls -vv  # any two blocks
forge test -j 1 --match-contract CarryThroughTest --match-test 'test_carry_withdrawal_from_U17_V5' -vv
forge test -j 1 --match-contract CarryThroughTest --match-test 'test_carry_' -vv

# 5. four-chain handles
forge test -j 1 --match-contract MultiChainTest -vv

# PASS A post-U21 fixture end-to-end (needs the pinned anvil :8545)
forge test -j 1 --match-contract FixtureE2ETest -vv
```

Outputs (written by the tests): `../evidence/F6-fork-point-versions.md`, `../evidence/F6-replay/<LABEL>.txt`,
`../evidence/F6-objects-{deposits,proves,failed,games}.md`, `../evidence/F6-carry-withdrawal-<ERA>.md`,
`../evidence/F6-carry-failed-<ERA>.md`, `../evidence/F6-differential-<A>-<B>.md`, `../evidence/F6-multichain-<block>.md`.

## Usage recipe

```solidity
contract MyTest is InFlightObjects {                       // also gives HistoricalFork + UpgradeReplay
    function test_x() public {
        EraProve memory p = _loadEraProve("U17_V5", 1);      // real prove of the v5 era
        _forkAt(p.proveBlock - 1); vm.makePersistent(OP_PORTAL);
        vm.roll(p.proveBlock); vm.warp(p.proveTimestamp); _proveAs(p, address(0xF6));   // object
        _carry(_point("U17_V5"), _point("U21_V9"), ReplayMode.Prank);                    // U18..U21 replayed
        _tryFinalize(p.wd, address(0xF6));                   // now under v9
    }
}
```

## Rules and caveats

- `-j 1`; at most one private anvil (none is needed: tests fork the archive proxy directly).
- Never call `_forkAt` in a loop: it creates a new fork each time (PASS A hit a 6.3 GB OOM that way).
  Use one fork + `_rollTo` / `_rollBefore` / `_rollAfter`, and `vm.snapshotState` +
  `vm.revertToStateAndDelete` (never a bare `vm.snapshotState` in a loop).
- Fuzz runs are capped at 32, invariant runs at 8 x depth 20 (`foundry.toml`).
- `_carry` semantics (pinned by `PersistProbeTest`): a persistent account keeps every slot it has
  loaded or written so far across `vm.rollFork`; untouched slots and all other accounts come from
  the real chain at the new block. A slot of the persistent holder that real non-upgrade traffic
  changes later stays at its carried value. The carry tests measure that set against the real end
  of the U21 block and print it (section "Carried-slot staleness"). Keep the persistent set minimal
  (the one contract that holds your object).
- The prank replay sets `block.number`/`timestamp` to the upgrade block but runs on the state at
  END(block-1), i.e. without the transactions that precede the upgrade tx in its block. Every
  replayed slot is compared with the real END(block) state, so such interference shows up as a
  mismatch in `../evidence/F6-replay/<LABEL>.txt`.
- EVM version is `osaka` (mainnet rules at the U21 pin). Old eras execute old bytecode under these
  rules; gas-dependent behaviour of very old eras can differ from what mainnet did at the time.
