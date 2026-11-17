# LANE 12 — Negative-space and omitted-check analysis (v8.0.0 -> v9.0.0, Upgrade 21)

Phase A (blind): derived from the two source trees, NatSpec, the U21 notice and chain state only.
No audit / public-finding material was read. Nothing was broadcast; every state change below
happened inside `forge test` forks of the shared `l1` anvil (block 26433900).

- Target `op-contracts/v9.0.0` @ `ba6fcadb`, baseline `op-contracts/v8.0.0` @ `f45a5ccf`.
- Paths below are relative to `packages/contracts-bedrock/`; `v9:` / `v8:` prefix the tree.
- Fork tests: `test/poc/lane12/Lane12.t.sol` (29 tests, all pass), output in
  `evidence/lane12/lane12-forge-results.txt`; cast reads in `evidence/lane12/lane12-cast-evidence.txt`.
- Result in one line: **no candidate**. Every added / removed / moved / weakened check was walked
  through the seven questions; the permissionless ones were exercised against the deployed
  implementations. Four reusable primitives and nine killed ideas are recorded.

Other lanes reached overlapping conclusions independently (lane 04 on the messenger path, lane 05
on proof deletion, lane 09 on the migration validator). Where that is the case the row says so and
this report only adds what is new (measurements, sibling enumeration, the table itself).

---------------------------------------------------------------------------------------------------

## 1. Interface delta (fastest index of new / removed checks)

`diff -ru v8/interfaces v9/interfaces`, every added / removed `error`, `event`, `function`:

| +/- | Interface | Item |
|---|---|---|
| + | IOptimismPortal2 | `error OptimismPortal_L1CDMCallFailed()` |
| + | IOptimismPortal2 | `error OptimismPortal_NotUsingLockbox()` |
| + | IOptimismPortal2 | `error OptimismPortal_DisputeGameNotInvalidated()` |
| + | IOptimismPortal2 | `event WithdrawalProofDeleted(bytes32 indexed, address indexed)` |
| + | IOptimismPortal2 | `function deleteProvenWithdrawal(bytes32,address)` |
| - | IETHLockbox | `initialize(ISystemConfig, IOptimismPortal2[])`, `systemConfig()` |
| + | IETHLockbox | `initialize(ISuperchainConfig, IOptimismPortal2[])`, `guardian()` |
| + | ISuperchainConfig | `isLocalOrGlobalPaused(address)` |
| - | IAnchorStateRegistry | `systemConfig()`; `initialize(ISystemConfig, …)` |
| + | IAnchorStateRegistry | `ethLockbox()`; `initialize(IETHLockbox, …)` |
| - | IDelayedWETH | `systemConfig()`; `initialize(ISystemConfig)` |
| + | IDelayedWETH | `ethLockbox()`; `initialize(IETHLockbox)` |
| - | IOPContractsManagerMigrator | `error …_InteropNotEnabled`, `…_NotSharedInteropSet`, `…_RespectedGameTypeNotRegistered`; `setInteropDisputeGames(MigrateInput)` |
| + | IOPContractsManagerMigrator | `error …_ChainAlreadyMigrated`, `…_SuperchainConfigNeedsUpgrade`, `…_InvalidInitBond`, `…_InvalidAbsolutePrestate`, `…_InvalidZKDisputeGameConfig`, `…_InvalidGameType`, `…_DisputeGameNotEnabled`, `…_InvalidStartingAnchorRoot`, `SemverComp_InvalidSemverParts` |
| - | IOPContractsManagerUtils | `systemConfigFor(ISystemConfig,address)` |
| + | IOPContractsManagerUtils | `isPermittedUpgradeSequence(ISystemConfig,address)`, `isPermittedMigrateSequence(ISystemConfig,address)` |
| - | IOPContractsManagerV2 | `setInteropDisputeGames(MigrateInput)` |
| + | IOPContractsManagerV2 | `isPermittedMigrateSequence(ISystemConfig)`; `upgradeSuperchain` arg memory -> calldata |
| + | IOPContractsManagerMigrationValidator | structs `LegacyChainContracts`, `ExpectedSharedContracts`, `ExpectedInitBond`; input fields `legacyChainContracts`, `expectedShared`, `expectedInitBonds`, `startingAnchorRoot`, `startingRespectedGameType`; `-cannonPrestate`, `-challenger`, `+superchainConfig` |
| + | ISP1Verifier | `VERIFIER_HASH()` |

Everything else in the v8->v9 `src/{L1,dispute,universal,libraries,legacy,safe}` diff is formatter
noise (cannon/*, DataAvailabilityChallenge, DisputeGameFactory, FaultDisputeGame,
SuperPermissionedDisputeGame, LibGameArgs/LibPosition/LibUDT, ProxyAdmin, ProxyAdminOwnedBase,
L1StandardBridge, L1ERC721Bridge, RLPReader, Predeploys, LegacyMintableERC20, LivenessModule were
checked hunk by hunk: no semantic change). Storage-layout snapshots differ only by
`systemConfig -> spacer` + one appended variable in ETHLockbox (slot 3), DelayedWETH (slot 5) and
AnchorStateRegistry (slot 6 offset 12, packed after `respectedGameType|retirementTimestamp`).

---------------------------------------------------------------------------------------------------

## 2. The check table

Kind: A = added, R = removed, M = moved, W = weakened, C = changed source of truth.
Reach: P = reachable by anyone, G = Guardian, O = ProxyAdmin owner (Safe 0x5a0Aae59…), D = dead on the
four upgraded chains today.

| Row | Kind | v9 location (v8 location) | Check | Reach |
|---|---|---|---|---|
| R01 | C | v9:src/L1/OptimismPortal2.sol:306-308 (v8:292) | `paused()` = `ethLockbox.paused()` (was `systemConfig.paused()`) | P (read) |
| R02 | C | v9:OptimismPortal2.sol:322-330 | `superchainConfig()` / `guardian()` served by the lockbox | P (read) |
| R03 | W+A | v9:OptimismPortal2.sol:502-513 (v8:486-494) | `migrateLiquidity`: gate `_isUsingInterop()` -> `_isUsingLockbox()`; new `_isUsingCustomGasToken()` revert | O |
| R04 | M | v9:OptimismPortal2.sol:635-637 (v8:629) | `GasEstimation` revert moved before the event / re-lock | P (tx.origin = 0x1 only) |
| R05 | A | v9:OptimismPortal2.sol:651-653 | `!success && _tx.sender == L2CDM` -> `OptimismPortal_L1CDMCallFailed` | P |
| R06 | A | v9:OptimismPortal2.sol:711-728 | `deleteProvenWithdrawal`: `timestamp == 0` -> Unproven; `status != CHALLENGER_WINS && !blacklisted` -> NotInvalidated. No auth, no pause check | P |
| R07 | C | v9:OptimismPortal2.sol:839-843 (v8:782-790) | `_assertValidLockboxState`: now `!feature || lockbox == 0` reverts (v8: only the two mismatched combinations) | O (initialize) |
| R08 | - | v9:OptimismPortal2.sol:287-289 | `initialize` keeps the old lockbox when given zero; no `authorizedPortals(this)` check (sibling `migrateToSharedDisputeGame` L558 has it) | O |
| R09 | C | v9:src/L1/ETHLockbox.sol:94-109 | `initialize(ISuperchainConfig, portals)`; no nonzero / code check on `_superchainConfig` | O |
| R10 | C | v9:ETHLockbox.sol:112-114 (v8:111-113) | `paused()` = `superchainConfig.isLocalOrGlobalPaused(address(this))` | P (read) |
| R11 | C | v9:ETHLockbox.sol:224-228 (v8:224) | `_authorizePortal`: SuperchainConfig equality now read through `portal.systemConfig()` | O |
| R12 | A | v9:src/L1/SuperchainConfig.sol:152-154 | `isLocalOrGlobalPaused(id)` = `paused(0) || paused(id)` | P (read) |
| R13 | C | v9:src/L1/SystemConfig.sol:543-547 (v8:553-559) | `setFeature(ETH_LOCKBOX,false)` always reverts (v8: only while the portal had a lockbox) | O / D |
| R14 | W | v9:SystemConfig.sol:552-554 (v8:563-565) | enabling ETH_LOCKBOX: `superchainConfig.paused(portal)` instead of full `paused()` | O / D |
| R15 | A | v9:SystemConfig.sol:559-561 | `setFeature(INTEROP,false)` reverts | O |
| R16 | C | v9:SystemConfig.sol:574-576 (v8:581-589) | `paused()` = `portal.ethLockbox().paused()`; reverts on a zero lockbox, recurses against a v1.3.1 lockbox | P (read) |
| R17 | C | v9:src/universal/CrossDomainMessenger.sol:266 (v8:279) | `hasMinGas(minGas, localReserved + localBuffer)`: on L1 135,000+15,000 (was 40,000+5,000) | P |
| R18 | C | v9:CrossDomainMessenger.sol:285 (v8:298) | target gets `gasleft() - 135,000` (was 40,000) | P |
| R19 | C | v9:CrossDomainMessenger.sol:215 (v8:228) | `_message` is `memory`: decoded and copied before the gas check | P |
| R20 | C | v9:src/L1/L1CrossDomainMessenger.sol:43-74,117-126 | `baseGas` uses REMOTE (L2) constants; public `RELAY_*` getters alias REMOTE | P (read) |
| R21 | A | v9:src/libraries/SafeCall.sol:131-132 (v8:126) | `callWithMinGas` reserves 183,600 more gas when `value != 0 && target.codehash == 0` | P |
| R22 | C | v9:src/dispute/AnchorStateRegistry.sol:136-138 (v8:132) | `paused()` = `ethLockbox.paused()` | P (read) |
| R23 | C | v9:AnchorStateRegistry.sol:375-379 (v8:365) | Guardian = `ethLockbox.guardian()` | G |
| R24 | C | v9:AnchorStateRegistry.sol:107 | `initialize` stores `_ethLockbox` unchecked | O |
| R25 | C | v9:src/dispute/DelayedWETH.sol:102 (v8:97) | `withdraw` pause = `ethLockbox.paused()` | P |
| R26 | C | v9:DelayedWETH.sol:58-64 | `initialize(IETHLockbox)` unchecked | O |
| R27 | A | v9:src/dispute/zk/ZKDisputeGame.sol:362-365 | respected game must build on a respected parent | P once type 10 is registered (it is not) |
| R28 | M | v9:ZKDisputeGame.sol:345-347 (v8: end of initialize) | `wasRespectedGameTypeWhenCreated` set before the parent checks | same |
| R29 | A | v9:src/L1/opcm/OPContractsManagerV2.sol:296-303 | `migrate`: every chain must pass `isPermittedMigrateSequence` | O |
| R30 | R+A | v9:OPContractsManagerV2.sol:360-365 (v8:362-367) | upgrade-instruction allow-list: `overrides.cfg.startingAnchorRoot` allowance gone; "ETHLockbox" proxy deployment allowed while major == 9 | O |
| R31 | R | v9:OPContractsManagerV2.sol:459-468 (v8:464-485) | lockbox is loaded unconditionally (v8: only when the feature was on) | O |
| R32 | A | v9:OPContractsManagerV2.sol:775-779 | ZK config validity in `_assertValidFullConfig` | O |
| R33 | C | v9:OPContractsManagerV2.sol:859-897 (v8:858-888) | `_apply`: lockbox must exist; ETH_LOCKBOX auto-enabled; portal always initialised with the lockbox; `migrateLiquidity()` when the chain was not using a lockbox and is not CGT | O |
| R34 | R | v9:OPContractsManagerV2.sol:885-957 (v8 `_systemConfigFor`, Utils v8:416) | shared contracts no longer keep "their" SystemConfig binding; they get the SuperchainConfig / lockbox directly | O |
| R35 | M | v9:src/L1/opcm/OPContractsManagerUtils.sol:536-560 (v8:OPContractsManagerV2.sol:1079-1109) | `isPermittedUpgradeSequence` moved to Utils, logic identical | O |
| R36 | R | (v8:OPContractsManagerV2.sol:303, Migrator v8:283) | `setInteropDisputeGames` removed with its checks (`NotSharedInteropSet`, `RespectedGameTypeNotRegistered`) | O |
| R37 | R | (v8:OPContractsManagerMigrator.sol:116-119) | `migrate` no longer requires the `OPTIMISM_PORTAL_INTEROP` dev feature | O |
| R38 | A | v9:OPContractsManagerMigrator.sol:145-150 | starting anchor root nonzero and `< uint64.max` | O |
| R39 | A | v9:OPContractsManagerMigrator.sol:309-311 | a chain with INTEROP set cannot be migrated again | O |
| R40 | A | v9:OPContractsManagerMigrator.sol:157-162 | SuperchainConfig must be at least this release's version | O |
| R41 | A | v9:OPContractsManagerMigrator.sol:339-410 | per-config checks (super type only, enabled, bond rules, prestate, ZK bounds, starting type present) | O |
| R42 | W->tight | v9:OPContractsManagerMigrator.sol:179-189 (v8:146-151) | permitted proxy deployments narrowed from "ALL" to three names | O |
| R43 | A | v9:OPContractsManagerMigrator.sol:267,417-430,545-555 | legacy DelayedWETH and legacy ASR are re-pointed at the shared lockbox | O |
| R44 | C | v9:src/dispute/lib/Types.sol:101-110 | `clearedGameTypes()` list {0,1,8,4,5,9,10} replaces seven hard-coded calls | O |
| R45 | A | v9:src/L1/OPContractsManagerStandardValidator.sol:445-446,457,636-640,963,1113-1127,1188-1190; v9:src/L1/opcm/StandardValidatorUtils.sol:364-366,402-404,409-416 | validator-only assertions (LOCKBOX-00/05/40, `-160` init bond, ASR-RGT, ZK duration caps, `-50`/`-40` lockbox pointers, `-70` portal/ASR identity) | off-path |

---------------------------------------------------------------------------------------------------

## 3. The seven questions, row by row

(1) why added, (2) sibling without it, (3) before/after the mutation it protects, (4) other contract
that skips it, (5) current config judging historical state, (6) validated object vs used object,
(7) upgrade/migration bypass.

### R05 — `OptimismPortal_L1CDMCallFailed`

1. Before v9 a messenger withdrawal whose `relayMessage` reverted (out of gas before the messenger
   could write `failedMessages`) was finalized as failed and could never be replayed. Now the whole
   finalize reverts and stays retryable.
2. Siblings:
   - any other L2 sender: still finalized as failed, value re-locked
     (`test_R05_sibling_otherSender_failure_isFinalizedAsFailed`: `finalizedWithdrawals = true`,
     lockbox balance unchanged). Intended: the portal has no replay for arbitrary targets.
   - **the messenger returning normally without delivering.** Two ways exist and neither trips the
     revert: (a) `hasMinGas` fails -> `failedMessages` written, return (v9:CrossDomainMessenger.sol:265-282);
     (b) the messenger is re-entered (`xDomainMsgSender != DEFAULT`) -> same branch. (b) is reachable by
     a third party: replay your own failed message, let its target call
     `portal.finalizeWithdrawalTransactionExternalProof(victim)`; during a replay `portal.l2Sender`
     is the default, so the portal guard (L594) does not fire.
     `test_R05_sibling_replayReentrancy_finalizesVictimAsFailedButReplayable`: victim withdrawal
     finalized, `successfulMessages = false`, `failedMessages = true`, 5 ETH moved lockbox ->
     messenger, then any account replays and the 5 ETH arrive. Pre-existing behaviour, funds
     recoverable permissionlessly, so not a finding (lane 04 PRIM-0401 has the same result).
3. The check runs after `finalizedWithdrawals[h] = true`, `unlockETH`, the external call and the
   `l2Sender` reset; the revert unwinds all of them. `test_R05_checkedPath…`: withdrawal still
   unfinalized, lockbox balance unchanged.
4. There is one finalize path (`finalizeWithdrawalTransaction` forwards to the external-proof
   variant, L496-498). No other contract can mark a withdrawal finalized.
5. No config is read; the discriminator is a constant predeploy address.
6. The check validates `_tx.sender`, the thing later relied on is "target is this chain's
   L1CDM". The link is made on L2: `sendMessage` always targets `otherMessenger`
   (v9:CrossDomainMessenger.sol:183-190, v9:src/L2/L2CrossDomainMessenger.sol `_sendMessage`), and
   `L2CDM.otherMessenger()` on OP Mainnet is `0x25ace71c…` (cast, l2 fork). A withdrawal with
   sender = L2CDM and another target cannot be produced on L2; if one existed it would also revert
   (`test_R05_checkKeysOnSenderOnly`).
7. Not configuration-dependent; no bypass.

Third-party permanent freeze through this revert was enumerated and killed: REJ-1203.

### R06 — `deleteProvenWithdrawal`

1. Storage / tooling hygiene: lets anyone clear a proof that can never finalize.
2. Sibling writes to `provenWithdrawals`: only `proveWithdrawalTransaction` (L483-484), which is
   pause-gated (L399) and re-validates the game. The delete path has **no pause check** and does not
   touch `proofSubmitters[h]` (append-only, L487) — the array keeps a stale entry.
3. Checks precede the single `delete`; no external call after it.
4. No other contract writes the mapping.
5. `isGameBlacklisted` is read from the portal's *current* registry; `status()` from the stored
   game. After a registry swap (`migrateToSharedDisputeGame`) an old proof against a game
   blacklisted only in the old registry is not deletable — and not finalizable either
   (`isGameRegistered` against the new factory). Harmless both ways.
6. The game checked is the one stored in the entry being deleted; a re-prove by the same submitter
   overwrites the entry first, so a stale "bad" game cannot be used to delete a fresh proof.
7. None.

Fork results: valid game -> `OptimismPortal_DisputeGameNotInvalidated`; in-progress game -> same;
unproven -> `OptimismPortal_Unproven`; after a Guardian blacklist a random account deletes while the
chain is paused; a 2024 CHALLENGER_WINS game (DGF index 0) -> deletable; another submitter's proof
of the same withdrawal against a valid game is untouched and finalizes. No griefing of a proof that
could still finalize: both predicates are monotone (`status` is written once at resolution;
`disputeGameBlacklist` only ever set to true, v9:AnchorStateRegistry.sol:184). REJ-1204.

### R01, R02, R10, R12, R16, R22, R23, R25 — pause / guardian resolved through the lockbox

1. One pause identifier per chain (the lockbox) instead of "lockbox if the feature is on, else the
   portal".
2. Every consumer was listed (`grep paused src/…`) and read on the fork:

   | Surface | Path | lockbox-id pause | global pause | portal / SystemConfig / ASR / L1CDM id |
   |---|---|---|---|---|
   | OptimismPortal2 prove / finalize / migrateToSharedDisputeGame | `ethLockbox.paused()` | paused | paused | not paused |
   | ETHLockbox.unlockETH | own | paused | paused | not paused |
   | SystemConfig.paused -> L1CDM.relayMessage, L1StandardBridge.finalize*, L1ERC721Bridge.finalize* | `portal.ethLockbox().paused()` | paused | paused | not paused |
   | AnchorStateRegistry.isGameProper (-> setAnchorState, games' closeGame) | stored `ethLockbox` | paused | paused | not paused |
   | DelayedWETH v2.0.0 withdraw | stored `ethLockbox` | paused | paused | not paused |
   | legacy DelayedWETH 0xE497B094… / 0x82511d49… / 0x323dFC63… (v1.0.0–1.3.0; 0.16 / 0.08 / 0.08 ETH) | `config.paused()` = global only | **not paused** | paused | not paused |

   (`test_pause_*`.) The last line is the only surface a lockbox-identifier pause does not reach;
   it predates U21 and holds dust.
   Entry points with no pause check at all (unchanged from v8 except the first): portal
   `deleteProvenWithdrawal` (new), `depositTransaction`, `donateETH`; lockbox `lockETH`,
   `receiveLiquidity`; `DisputeGameFactory.create`; game moves / `resolve`; `DelayedWETH.unlock`;
   messenger / bridge deposits.
3. View logic; n/a.
4. See table: no consumer skips the lockbox identifier except the legacy escrows.
5. The pause read is always current state; nothing historical is judged by it except
   `isGameProper` (documented "temporarily improper").
6. **Three independent lockbox pointers now exist per chain**: `portal.ethLockbox`,
   `asr.ethLockbox`, `delayedWETH.ethLockbox`, plus `systemConfig.superchainConfig` vs
   `lockbox.superchainConfig`. They can only diverge through privileged calls
   (`migrateToSharedDisputeGame`, a per-contract `initialize`). All equal on the four chains
   (evidence §7); the validator checks them (`-40`, `-50`, LOCKBOX-40).
7. `SystemConfig v4.3.0.paused()` against a still-v1.3.1 lockbox recurses forever
   (lockbox v8:112 -> `systemConfig.paused()` -> v9:575 -> lockbox…), and reverts against a zero
   lockbox. Only reachable inside a non-atomic upgrade; the OPCM changes all three in one
   transaction and never calls `paused()` in between (R14 reads the SuperchainConfig directly,
   which avoids the call). On chain
   all four lockboxes are v2.0.0 with `superchainConfig` = `0x95703e09…` (v2.5.0, which has
   `isLocalOrGlobalPaused`).

### R17 – R20 — messenger relay budgets

1. Under EIP-8037 (Amsterdam) writing the fresh `successfulMessages` / `failedMessages` slot costs
   97,920 more gas; 40,000 reserved gas would no longer cover it, and the copy of a large message
   used to be paid out of the reserve.
2. Sibling = the other chain's messenger. **U21 has no L2 fork**: the live L2CDM is v2.2.1 and
   still budgets `baseGas` with 200,000 + 40,000 + 40,000 + 5,000 (`baseGas("",0)` = 310,160 on both
   forks), while the L1CDM now needs `minGas*64/63 + 190,000` at the check instead of
   `+ 85,000`. The 105,000 difference comes out of the 200,000 "constant overhead" slack.
3. `hasMinGas` runs before `xDomainMsgSender` is written and before the call.
4. A replay (`relayMessage` called directly) runs the same code.
5. n/a.
6. Budget is computed on L2 with L2-side constants and consumed on L1 with L1-side constants; the
   L1CDM's public `RELAY_RESERVED_GAS()` / `RELAY_GAS_CHECK_BUFFER()` return 40,000 / 5,000 (the
   REMOTE values), not the 135,000 / 15,000 it actually uses — an integrator reading them gets the
   wrong number for L1.
7. n/a.

Measured on the fork, real portal + real messenger (`test_R17_*`, `test_R18_*`):

| Case | L2 budget (withdrawal gasLimit) | L1CDM frame gas needed to deliver, cold context | Margin |
|---|---|---|---|
| empty message, minGas 100,000, 1 ETH | 411,747 | 352,835 | 58,912 |
| empty message, minGas 0 (receiver itself needs ~75k) | 310,160 | 273,137 | 37,023 |
| 20 kB message, minGas 200,000 | 833,334 | 525,738 | 307,596 |
| 100 kB message, minGas 200,000 | 4,031,400 | 872,619 | 3,158,781 |

Through the portal: the lowest gas at which finalize does not revert already delivers the message
in every case, and a 500-gas scan from 200k below to 150k above that threshold finds no
"finalize succeeds, message not delivered" sample. A target that burns all forwarded gas is recorded
as failed, not reverted (reserve is sufficient). So the delivery guarantee of `baseGas` still holds
today; the pre-check overhead is ~61k against 120k of remaining slack. REJ-1201. The thin margin and
the misleading getters are recorded as PRIM-1201 (lane 04 PRIM-0404 / lane 32 PRIM-3202 describe the
same asymmetry; the numbers here are new).

### R21 — `callWithMinGas` new-account reservation

1. Under EIP-8037 a value transfer to an empty account costs 183,600 state gas inside the CALL;
   without the reservation the callee could receive less than `minGas`.
2. Siblings `SafeCall.call` / `send` do not reserve (the messenger covers it in its own reserve,
   comment v9:src/libraries/GasConstants.sol:37-41).
3. Before the CALL.
4. Only the portal uses `callWithMinGas`.
5. `codehash` is read at call time for the call being made — correct.
6. Same address is checked and called.
7. n/a.

Measured: minimum portal gas for a 1 ETH withdrawal with gasLimit 0 is 314,286 to an empty account
vs 127,782 to a funded EOA (delta 186,504); 111,548 with zero value. Pure cost increase for the
finalizer today (mainnet has no Amsterdam header fields at 26433900); no correctness effect.

### R03, R07, R08, R09, R11, R13 – R15, R24, R26 — privileged setters / initializers

All `O`. Omitted sibling checks worth knowing (PRIM-1203):
- `ETHLockbox.authorizeLockbox` (L184-196) and `migrateLiquidity` (L203-216) check only the shared
  ProxyAdmin owner; `_authorizePortal` additionally checks the SuperchainConfig.
- `OptimismPortal2.initialize` does not check `lockbox.authorizedPortals(this)`;
  `migrateToSharedDisputeGame` (L558) does.
- `ETHLockbox.initialize`, `AnchorStateRegistry.initialize`, `DelayedWETH.initialize` store their
  pointer with no nonzero / code check; a zero pointer makes `paused()` revert, i.e. blocks prove,
  finalize, bond withdrawal and Guardian actions on that chain while deposits keep flowing in.
- A re-run of `SystemConfig.initialize` can change `superchainConfig` / `l2ChainId` with no re-check
  against the lockbox or, after a migration, against the other members' chain ids. Not reachable
  through `OPContractsManagerV2.upgrade()`: the `overrides.cfg.*` keys exist in `_loadFullConfig`
  (v9:OPContractsManagerV2.sol:568,640) but `_isPermittedInstruction` (L347-376) only lets
  `overrides.cfg.startingRespectedGameType` and the v9 ETHLockbox proxy permission through, so the
  values are always re-read from the chain. It needs a direct ProxyAdmin `upgradeAndCall`.
- `setRespectedGameType` accepts any uint32 (no factory lookup).
- R14: enabling ETH_LOCKBOX is now allowed while the global pause or the lockbox identifier is
  paused (the result is still paused, so the weakening is in the safe direction).
- R13/R15 make both flags one-way; the comment at v9:OPContractsManagerMigrator.sol:305-311 relies
  on that for the re-migration guard.
`test_auth_siblings`: each of these reverts for an unprivileged caller with the expected selector.

### R27, R28 — ZK game parent rule

Type 10 is not registered on any of the four factories and the ZK dev feature is off
(`devFeatureBitmap = 0`), so this is not reachable. For a later lane: the parent is validated on
status, blacklist, retirement, respected flag, game type and sequence number, but not on having been
created with the same `gameArgs` (verifier / absolute prestate / registry). A child created after a
`setImplementation` change can start from a parent proven under the previous verification key.

### R29 – R44 — OPCM

All `O` (delegatecall from the Safe). Points that matter for composition:
- R37: the v8 OPCM on mainnet (`0x1951828C…`, v8.0.1) has `devFeatureBitmap = 0` (cast), so its
  `migrate` reverted with `InteropNotEnabled` for every caller (v8:OPContractsManagerMigrator.sol:117).
  The v9 OPCM (`0x2d91e6F2…`, bitmap also 0) has no such gate and
  `isPermittedMigrateSequence(OP SystemConfig)` already returns true; the only remaining gates are
  the delegatecall-from-owner context and R29. The notice says the runbook is "not yet cleared for
  production chains" — that statement is now enforced off chain only.
- R36: with `setInteropDisputeGames` gone there is no OPCM path to change the games of an already
  migrated set except a per-chain `upgrade()`.
- R44: the list omits types 2, 3, 6, 7, 254, 255, 1337. None is registered on the four factories
  (cast), and the old factory is not consulted by the portal after migration.
- R30: the starting-anchor-root override for upgrades is gone; `overrides.cfg.startingRespectedGameType`
  remains (L370).

### R45 and the off-path validators — see §5.

---------------------------------------------------------------------------------------------------

## 4. Did U21 itself change anything the checks would have caught?

Pre (`l1pre` @26430858) vs post (`l1` @26433900), all four chains (evidence §4–§7):

- Every zero-argument getter of SystemConfig is identical except `version`, `lastUsedOPCM`,
  `lastUsedOPCMVersion`, `getAddresses().opcm`.
- ASR: starting anchor root, respected type (9 / 9 / 5 / 9), retirement timestamp, factory, finality
  delay unchanged. Portal: guardian, SuperchainConfig, proof maturity, registry, lockbox unchanged.
- DGF: `gameArgs(9)` absolute prestate `0x031ac6f1…` -> `0x03e5a548…` on OP, Ink, Unichain
  (documented). **OP Mainnet only: `gameArgs(5)` proposer `0x473300df…` -> `0xc27ba3E0…`**, an EOA
  with nonce 1 before the upgrade that has since been creating the type-9 proposals. Type 5 is not
  respected on OP, so the key has no power today; it is the `tx.origin` that can create
  instantly-DEFENDER_WINS games if the Guardian ever falls back to type 5. A governance input, not
  a bug — flagged because the validator compares this field against a caller-supplied value.
- 33 proxies emitted `Upgraded` in the U21 transaction; each one's EIP-1967 slot equals the last
  implementation it announced, none is the StorageSetter `0x2476c911…`.
- Lockbox / ASR / DelayedWETH pointers and SuperchainConfig are consistent on all four chains.

---------------------------------------------------------------------------------------------------

## 5. Validator-only assertions

Deployed validator `0x9E1D01E25f411c5da20C33d1EaDe0F83256d41B2` (v4.1.1, from
`OPCM.opcmStandardValidator()`), `validate(ValidationInputDev, true)` on the fork:

| Chain | Result |
|---|---|
| OP Mainnet | `""` |
| Ink | `""` |
| Unichain | `""` |
| Soneium | `"SCKDG-SHAPE,SCKDG-10"` (no type-9 game registered; permissioned chain) |

(With the non-dev `ValidationInput` struct the same call returns `SCKDG-40` for OP / Ink / Unichain:
`_toValidationInputDev` maps `absolutePrestate` to the *cannon* prestate and leaves the kona one
zero, v9:OPContractsManagerStandardValidator.sol:1052-1060. A caller using the short struct gets a
false failure on any type-9 chain.)

For each class of assertion, who can change the value after a passing run:

| Assertions | Value | Who can move it |
|---|---|---|
| `*-10/-20` versions, implementations, `PROXYA-10`, `DF-30/40`, `*-80/90` admins, LOCKBOX-20/30/50 | proxy impl / admin / owner / authorization | ProxyAdmin owner |
| SYSCON-20/30/110/120 (gas limit, scalar, operator fee) | SystemConfig setters | SystemConfig owner (chain operator `0x847B5c17…`), any time |
| SYSCON-50…100 (resource config), SYSCON-130/140, LOCKBOX-40, `-50` (DelayedWETH lockbox), `-40` (ASR lockbox), `-70` (portal registry) | initializer-only values | ProxyAdmin owner |
| game `-30…-110`, `-130/-140`, `-160` (args, bonds, proposer) | DGF `setImplementation` / `setInitBond` | DGF owner (Safe) |
| ASR-RGT | respected game type | Guardian (any uint32) |
| SPRCFG-10 | global pause | Guardian |
| `-120` anchor root nonzero | `anchorGame` | anyone via `setAnchorState`, but only to a valid game's nonzero claim |
| **PORTAL-80** `l2Sender == DEFAULT` | portal slot 50 | **anyone, for the duration of a withdrawal call** (`test_validator_PORTAL80_isTransientlyFalse`); irrelevant for an eth_call run |

So on the standard validator no assertion can be falsified durably by an unprivileged actor.
What it compares against caller input rather than chain truth: absolute prestates, proposer,
`l2ChainID`, and (overrides) PAO multisig and challenger.

MigrationValidator (`0x108f611d…`, not applicable to today's state — no chain is migrated):
`MIG-CHAIN-<i>-150` (`address(portal).balance == 0`, v9:OPContractsManagerMigrationValidator.sol:559)
and `-160` (retired lockbox balance == 0, L565-567) are falsifiable by anyone with 1 wei
(`portal.donateETH`, or a forced transfer / an authorized-portal `lockETH` into the retired
lockbox). Lane 09 PRIM-0902 demonstrates this on a simulated migration; `test_auth_siblings` here
shows the permissionless half on today's state (1 ETH donated stays on the portal, lockbox
accounting unaffected). Off-chain check only; no on-chain consumer.

---------------------------------------------------------------------------------------------------

## 6. Primitives and rejected ideas

Primitives: PRIM-1201 (relay budget asymmetry, measured margins, misleading getters),
PRIM-1202 (finalized-but-undelivered messenger withdrawal via replay re-entrancy — the path the new
revert does not cover), PRIM-1203 (catalogue of omitted sibling checks on privileged paths),
PRIM-1204 (pause coverage matrix: dead identifiers, unpaused entry points, legacy escrows).

Rejected: REJ-1201 … REJ-1209 (see files).

---------------------------------------------------------------------------------------------------

## 7. Open questions for other lanes

1. Amsterdam before an L2 messenger upgrade: with the L2 still budgeting 310,160 for an empty
   message, a value transfer to a new account needs ~391k on L1 by the source's own measurement
   (v9:src/libraries/GasConstants.sol:37-41). The failure mode is a revert (retry with more gas) or
   a replayable failed message, never a loss — worth one test on an Amsterdam-rules EVM if one is
   available.
2. `ValidationInput` -> `ValidationInputDev` mapping (SCKDG-40 false failure): is any tooling
   treating validator errors as fatal with the short struct?
3. ZK parent rule vs `gameArgs` rotation (R27) once type 10 is registered anywhere.
