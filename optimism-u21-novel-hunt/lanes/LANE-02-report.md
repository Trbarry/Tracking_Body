# LANE 02 — Storage and Reinitialization (U21, op-contracts/v9.0.0)

Phase A (blind). No audit reports, findings lists or issue archaeology were read. Sources: the three tag checkouts,
the U21 notice, chain state through the shared forks (26430858 / 26430859 / 26433900), one `debug_traceTransaction`
(prestate diff + call trace) of the upgrade tx from the archive upstream, log queries on the public log RPC. Nothing was
broadcast; the shared anvils were only read.

## 1. Verdict

**No candidate.** On OP Mainnet, Ink, Soneium and Unichain the U21 transaction is a pointer-only upgrade: 47 storage slots
changed (net), all attributed (U21_STORAGE_LAYOUT_DIFF.md §3.1). No pre-existing value is re-interpreted by v9, no new v9
field is zero, no initializer can be re-run, implementations are locked, withdrawal-proof mappings decode identically
across the boundary. Four low-value primitives and nine rejected ideas with their killing facts are recorded.

## 2. Files written

| Path | What |
|---|---|
| `PRE_UPGRADE_STATE.json` | block 26430858, 4 chains x 12 contracts, slots + named slots + getters |
| `POST_UPGRADE_STATE.json` | block 26430859 (end of the upgrade block) |
| `POST_UPGRADE_STATE_26433900.json` | block 26433900 |
| `U21_STORAGE_LAYOUT_DIFF.md` | v7/v8/v9 per-field tables with on-chain values, changed-field semantics, attributed N-1 -> N delta, N -> 26433900 delta, "should have changed" list, legacy slots, withdrawal mappings, init state |
| `primitives/PRIM-0201..0204.md` | see §6 |
| `rejected/REJ-0201..0209.md` | see §5 |
| `test/poc/lane02/U21StorageReinit.t.sol`, `U21WithdrawalBoundary.t.sol` | 7 fork tests, all PASS (`evidence/lane02/forge_test_output.txt`); harness `/home/user/u21-work/lane02` (add `l1n = "http://127.0.0.1:8547"`) |
| `evidence/lane02/` | `u21-tx-prestate-diff.json`, `u21-tx-calltrace.json` (+ summary), `delta_N-1_to_N.txt`, `delta_N_to_26433900.txt`, `bytecode_check.txt`, `withdrawal_mapping_check.json`, `portal_withdrawal_logs.json`, `pre_nonzero_slots.txt`, scripts |

## 3. How U21 re-initialises (state machine actually executed)

Safe `execTransaction` -> DELEGATECALL Multicall3Delegatecall `aggregate3` -> 5 DELEGATECALLs into OPCMV2 `0x2d91e6F2..`:
`upgradeSuperchain` once, then `upgrade` for OP, Ink, Soneium, Unichain. For each proxy
(`OPContractsManagerUtils.upgrade`, src/L1/opcm/OPContractsManagerUtils.sol:312-387):

1. downgrade / pre-release-tag guards (:335-350);
2. `ProxyAdmin.upgrade(proxy, StorageSetter)` (:354);
3. revert if the OZ-v5 ERC-7201 slot is non-zero (:359-364);
4. `setBytes32(initSlot, current & ~(0xff << 8*offset))` — zero exactly the `_initialized` byte (:367-369); offset 20 for
   the L1CDM, 0 for everything else;
5. `ProxyAdmin.upgradeAndCall(proxy, impl, initialize(...))` (:372);
6. `ProxyAdmin.upgrade(proxy, StorageSetter)` again, re-check the OZ-v5 slot (:379-382);
7. `ProxyAdmin.upgrade(proxy, impl)` (:386).

Hence four `Upgraded` events per ERC-1967 proxy (132 = 33 proxies x 4). Order per chain (`_apply`,
OPContractsManagerV2.sol:803-1028): SystemConfig -> (ETH_LOCKBOX feature already on, no `setFeature`) -> Portal ->
ETHLockbox -> (no `migrateLiquidity`) -> L1CDM -> L1StandardBridge -> L1ERC721Bridge -> OptimismMintableERC20Factory ->
DGF -> DelayedWETH -> ASR -> `setImplementation`/`setInitBond` for types 0,1,8,5,9,10 -> clear type 4.
Initializer arguments are read back from the live proxies (`_loadFullConfig`, :552-682), so every re-init is an
identity write except for the three new pointers and the upgrade inputs (prestate; OP proposer).

Initializer versions are the same in v7, v8 and v9; the StorageSetter reset is the only thing that makes a re-init
possible, and it is ProxyAdmin-only and atomic.

## 4. Invariants checked (all hold at N and at 26433900 on the four chains)

| # | Invariant | Evidence |
|---|---|---|
| I1 | `_initialized == initVersion()` on every proxy; implementations `_initialized == 255` | dumps; `test_reinitializeRevertsForEveryCaller`, `test_implementationsAreLocked` |
| I2 | `portal.ethLockbox == asr.ethLockbox == delayedWETH.ethLockbox != 0`; `lockbox.superchainConfig == systemConfig.superchainConfig == 0x95703e09..` | `test_newV9FieldsWiredOnAllFourChains` |
| I3 | one pause answer: portal == systemConfig == asr == lockbox == l1cdm; guardian unchanged | dumps (getters) |
| I4 | `ETH_LOCKBOX` on, `INTEROP` off, `CUSTOM_GAS_TOKEN` off; ETH_LOCKBOX/INTEROP cannot be disabled | dumps; `test_featureFlagsAreOneWay` |
| I5 | portal holds 0 ETH; lockbox authorises exactly its portal; no authorised lockboxes | dumps |
| I6 | no legacy slot is read by v9 | `test_legacySpacerSlotsAreDeadStorage` |
| I7 | proven / finalized entries decode identically under v8 and v9; a v8 proof finalises under v9 | `withdrawal_mapping_check.json` (21 entries), 4 real finalisations, `test_entriesProvenUnderV8ReadIdenticallyUnderV9` |
| I8 | deployed implementations == v9 source build | `bytecode_check.txt` (15 contracts MATCH) |
| I9 | upgrade tx delta fully attributed; whole-block delta = tx delta + one earlier deposit (tx index 341) | prestate diff vs dumps |
| I10 | nothing privileged changed between N and 26433900 | `delta_N_to_26433900.txt`, getter diff of the two POST dumps |
| I11 | proxy plumbing: ProxyAdmin types/names, EIP-1967 admins, AddressManager, `upgrading == false`, OZ-v5 slot 0 | dumps |

## 5. Negative results (each with its killing fact in `rejected/`)

* REJ-0201 legacy Portal slot re-interpreted — private, unread, differential test.
* REJ-0202 new v9 field left zero — 12 pointers set; all four chains were already lockbox chains with empty portals.
* REJ-0203 re-initialisation / unlocked implementation — versions equal, ACL on every initializer, 0xff everywhere.
* REJ-0204 withdrawal mapping drift — layout identical, 21 real entries identical, 4 cross-boundary finalisations.
* REJ-0205 SystemConfig re-init changes L2 parameters or owner — SystemConfig net delta is impl + OPCM slot only.
* REJ-0206 contract left on v8 code — bytecode equality with v9 artifacts for the "unchanged" implementations and games.
* REJ-0207 pause-identifier discontinuity — identifier was already the lockbox; all pause timestamps are 0.
* REJ-0208 per-chain asymmetry (custody, game type 5 on Soneium, owners) — no asymmetric code path.
* REJ-0209 proxy special slots (ChugSplash, ResolvedDelegateProxy, ProxyAdmin, OZ-v5) — clean.

Also checked and found uninteresting: SystemConfig `isFeatureEnabled` is a `mapping(bytes32 => bool)` (slot 109), not a
bitmap, entries `ETH_LOCKBOX = 1`, others 0; `lastUsedOPCM` moved 8.0.1 -> 9.0.3; deprecated hashed SystemConfig slots
(`batchinbox`, `l2outputoracle`, `disputegamefactory`, `gaspayingtoken*`) are all zero; `SystemConfig.overhead` is 0.

## 6. Primitives

* PRIM-0201 — pause/guardian/SuperchainConfig resolution pinned in four per-contract pointers; consistency now depends on
  OPCM re-initialising all of them together; after the planned `migrate` every non-first chain's DelayedWETH is orphaned
  from its SystemConfig.
* PRIM-0202 — inventory of non-zero dead legacy slots (three new `systemConfig` spacers per chain plus the old Portal /
  L1CDM / bridge ones), with real values; some still equal the live contract (Portal 56 = DGF, 53 = SuperchainConfig).
* PRIM-0203 — `deleteProvenWithdrawal` leaves the submitter in `proofSubmitters`; no pause check; "permanent" is relative
  to the current ASR.
* PRIM-0204 — U21 rotated the SUPER_PERMISSIONED proposer on OP Mainnet only (`0x473300df..` -> `0xc27BA3e0..`).

## 7. Open questions / hand-offs

1. **Planned interop migration (OP Mainnet + Unichain), storage side.** `OPContractsManagerMigrator.migrate` re-uses
   chain[0]'s DelayedWETH for the shared factory and rewrites every other chain's `SystemConfig.delayedWETH` to it
   (OPContractsManagerMigrator.sol:229, 271, 437-467). Afterwards a per-chain `OPContractsManagerV2.upgrade` of Unichain
   loads the *shared* lockbox / DGF / ASR / DelayedWETH and re-initialises them and re-writes the shared DGF's game
   configuration from that one chain's input (OPContractsManagerV2.sol:887-996); `ETHLockbox.initialize` is called with
   only that chain's portal (harmless: the mapping is additive). Worth a migration-lane check that two members' upgrade
   inputs cannot disagree in a harmful way and that the orphaned Unichain DelayedWETH (`0x74ad145a..`, ~21.4 ETH of
   bonds) and both old lockboxes stay consistent (PRIM-0201).
2. **Old lockbox after migration.** It keeps `authorizedPortals[portal] == true`, and `OptimismPortal2._isUnsafeTarget`
   only blocks the portal and its *current* lockbox (OptimismPortal2.sol:846-849). A withdrawal can therefore call
   `oldLockbox.lockETH{value}` (ETH parked in a dead lockbox until the ProxyAdmin owner sweeps it); `unlockETH` from inside
   a withdrawal is blocked by the `l2Sender` check (ETHLockbox.sol:169-171). I see only self-harm; a withdrawal lane
   should confirm there is no way to make someone else's value land there. Same question for portal A -> portal B
   targets once both share one lockbox.
3. **`overrides.cfg.startingRespectedGameType`** is a permitted upgrade instruction (OPContractsManagerV2.sol:367-372):
   an OPCM upgrade can set `respectedGameType` through `ASR.initialize`, a power otherwise reserved to the Guardian.
   Privileged-to-privileged, noted for the governance/roles lane.
4. Game implementation templates (`0x19AF533C..`, `0x5C3eb47c..`) are not `Initializable`-locked (CWIA clones); unchanged
   by U21, left to the dispute lane.
5. Log history older than ~10k blocks was not available from the public log RPCs, so the withdrawal sample is limited to
   proofs from the 5000 blocks before N plus everything finalised after N (which were proven >= 7 days earlier).

## 8. Reproduction

```
cd /home/user/Tracking_Body/optimism-u21-novel-hunt
python3 -I evidence/lane02/dump_state.py pre  PRE_UPGRADE_STATE.json
python3 -I evidence/lane02/dump_state.py n    POST_UPGRADE_STATE.json
python3 -I evidence/lane02/dump_state.py post POST_UPGRADE_STATE_26433900.json
python3 -I evidence/lane02/bytecode_check.py
python3 -I evidence/lane02/withdrawal_mapping_check.py
python3 -I evidence/lane02/delta_N_to_26433900.py
cd /home/user/u21-work/lane02 && forge test --match-path "test/U21*.t.sol" -vv
```
