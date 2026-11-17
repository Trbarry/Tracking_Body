# FIX-CLOSURE-MATRIX — did each fix close the root cause, and is its safety condition still true at v9?

Worker F3 (Track B). One row per Medium+ fix and per important Low fix recorded in `AUDIT-FINDINGS.json`.
Code citations: `hist/<ver>` = `/home/user/ethereum-optimism/hist/<ver>/packages/contracts-bedrock/`,
`op-vN` = `/home/user/ethereum-optimism/op-vN.0.0/packages/contracts-bedrock/`.
"VERIFIED" = read in the tree at that tag by F3. "report" = stated by the report only. Chain reads were made on the
local read-only fork `:8545` (L1 block 26433900).

Column key — **RC**: root cause fixed (R) or only the observed instance (I) or not fixed (N: acknowledged / documented).
**Inv**: inverse direction (L1->L2 vs L2->L1, prove vs finalize, set vs unset) covered. **Sib**: sibling contracts
covered. **Wrap**: direct and wrapped entrypoints both covered. **Pre**: pre-existing objects tested. **Skip**:
skipped-upgrade histories tested. **Re**: later code reintroduced the assumption under a new abstraction.
**Rem**: later cleanup removed the condition that made the fix safe. y / n / ? (not determinable from the corpus) / – (n.a.).

## A. Matrix

| # | Finding (report id) | Fix as stated | RC | Inv | Sib | Wrap | Pre | Skip | Re | Rem | Evidence at later tags |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Game usable in another registry (Cantina contest 2025-04 3.2.9) | `isGameRegistered` requires `game.anchorStateRegistry() == address(this)` (b671b67) | R at v4 | n | y (4 game kinds checked by reviewer) | n | n | n | **y** (U20 3.1.6 moved the binding to the off-chain validator) | **y** | VERIFIED present `hist/v4.0.0 src/dispute/AnchorStateRegistry.sol:182-200` .. `hist/v6.0.0 …:196-214`; ABSENT `op-v7 …:216-226`, `op-v8 …:216-226`, `op-v9 …:227-237` (NatSpec `:217-222` explains the removal). Game snapshots respected-ness from its own registry: `op-v9 src/dispute/FaultDisputeGame.sol:318-319` |
| 2 | Blacklisted anchor bricks the system (U13 5.1.2) | blacklist check REMOVED from `getAnchorRoot` (PR 14232) "under the assumption that invalid games are invalidated before they are finalized" | I (liveness instance; opens the inverse safety case) | n | n | – | n | n | y (super games copy the anchor: U20 3.1.4) | – (the fix itself is a removal) | VERIFIED `op-v9 AnchorStateRegistry.sol:205-213` returns `anchorGame` root with no blacklist/retirement test; consequences re-reported as contest 3.2.1 / 3.2.18 and U21 3.2.11 |
| 3 | Re-prove resets the finalization timer (ToB 2023-01 TOB-OPTCW-1) | re-prove only if the output root at the stored index changed (PR 4057) | R at v1.0.0 | – | – | – | n | – | **y** | **y** | VERIFIED gate at `hist/v1.0.0 contracts/L1/OptimismPortal.sol:277-280`; GONE in `hist/v1.4.0 src/L1/OptimismPortal2.sol:318-327` (record keyed by `msg.sender`, any number of proofs); same `op-v9 src/L1/OptimismPortal2.sol:483-487`. Replacement condition = per-submitter records + `finalizeWithdrawalTransactionExternalProof(_tx, _proofSubmitter)` |
| 4 | Victim funds lost through messenger reentrancy guard (Sherlock 2023-01 H-3) and revert-on-low-gas (2023-03 M-4, M-1, M-6) | messenger never reverts for a portal-originated first relay; records `failedMessages`; 40k reserve | R for v1.0.0 sizes | n (L1->L2 direction: 2023-01 M-12 fixed separately by removing the pause) | y (portal + messenger) | n | n | – | y | **y** (two steps) | VERIFIED v1.0.0 no pause/no nonReentrant (`hist/v1.0.0 contracts/universal/CrossDomainMessenger.sol` relayMessage, spacers `:61-71`); v1.2.0 adds `require(paused() == false)` (`hist/v1.2.0 src/universal/CrossDomainMessenger.sol:224`); v9 portal now REVERTS on messenger failure (`op-v9 OptimismPortal2.sol:638-653`) and reserve is 135k+15k (`op-v9 src/libraries/GasConstants.sol:60,75`) while the L2 side keeps 40k/5k (`:63`) |
| 5 | Upgrade resets the reentrancy sentinel -> double withdrawal (Trust TRST-H-1) | initializer writes `xDomainMsgSender` only if zero; assert `successfulMessages == false` after the call; portal guard added | R | – | y (portal `l2Sender`) | y | n | n | n | n | VERIFIED `op-v9 src/universal/CrossDomainMessenger.sol` `__CrossDomainMessenger_init` (`if (xDomainMsgSender == address(0))`), `relayMessage` assert; `op-v9 OptimismPortal2.sol:297-299` |
| 6 | Pointer change silently unpauses (Spearbit 2025-05 5.1.3; U16a 5.1.3) | `whenNotPaused` on `migrateToSuperRoots` (33695ee); U16a variant acknowledged | I (one writer of the identifier) | n | n | n (`initialize`/`upgrade` can also write `ethLockbox`) | n | n | **y** (v4.1.0 made the identifier depend on a feature flag) | partly | VERIFIED `paused()`: v4.0.0 `paused(lockbox) or paused(0)`; v4.1.0–v8 `paused(0) or paused(flag ? lockbox : portal)`; v9 `portal.ethLockbox().paused()` (`SystemConfig.sol paused()` at each tag). `setFeature`: no pause guard at v4.1.0; guard from v5.0.0; v9 refuses while `superchainConfig.paused(optimismPortal())`. `op-v9 OptimismPortal2.sol:537` (`migrateToSharedDisputeGame` asserts not paused) but `initialize` (`:273-302`) writes `ethLockbox` with no pause test |
| 7 | Unprotected `upgrade()` (contest 3.2.11) | `ProxyAdminOwnedBase` + `ReinitializableBase` on every initialize/upgrade (PR 15615) | R | – | y | n (initialize usable in place of upgrade: Spearbit 5.1.1 acknowledged) | n | n | n | n | VERIFIED `op-v9 OptimismPortal2.sol:279-282`, `AnchorStateRegistry.sol:101-104`; ResolvedDelegateProxy heuristic documented only (Spearbit 5.1.5) |
| 8 | Failed withdrawal leaves ETH in the portal (Wonderland L-2) | re-lock on failure (observed, not stated) | R | – | – | y | n | n (lockbox-less chains unaffected until they get a lockbox) | n | n | VERIFIED `hist/v4.0.0 src/L1/OptimismPortal2.sol:679`, `op-v8 …:622`, `op-v9 …:663` |
| 9 | closeGame during pause latches REFUND (contest 3.1.1) | closeGame reverts while paused (b671b67); then early return moved before the pause check (3ad1915) | R | – | y (super games) | y | n | – | n | n | VERIFIED `op-v9 FaultDisputeGame.sol:1038` after the early return |
| 10 | Precompile OOG overwrites preimage part (Spearbit No-MIPS 5.1.1) | (later) `_requiredGas` argument + NotEnoughGas | R | – | ? (other load* paths write-once by construction) | – | n | – | n | ? (precompile repricing changes the right `_requiredGas`) | VERIFIED absent `hist/v1.4.0 src/cannon/PreimageOracle.sol`, present `hist/v1.6.0`, `op-v9 src/cannon/PreimageOracle.sol:402-432` |
| 11 | GameType truncated to uint8 (Sherlock FP M-1) | `raw()` returns uint32 (PR 10152) | R | – | y | – | – | – | n | n | VERIFIED `hist/v1.4.0 src/dispute/lib/LibUDT.sol:231`, `op-v9 …:224` |
| 12 | Anchor poisoned with max block number (Sherlock FP M-2) | `challengeRootL2Block` (PRs 10431/10434/10438) | I | n | n (permissioned game: U19 3.2.10; super games have no block number, bound added nowhere: U21 3.2.11) | n | n | – | y | – | VERIFIED `op-v9 FaultDisputeGame.sol:655-691` (no `resolvedSubgames[0]` check: Spearbit 5.2.2 still open); `op-v9 PermissionedDisputeGame.sol` has no override |
| 13 | Creator = tx.origin (Sherlock FP M-3) | factory passes `msg.sender` as `gameCreator` (PR 10149) | I | – | n (permissioned games keep `tx.origin == proposer`) | – | – | – | y (SuperPermissioned, U20 3.2.4 acknowledged) | n | VERIFIED `op-v9 PermissionedDisputeGame.sol:75`, `SuperPermissionedDisputeGame.sol:60` |
| 14 | Legacy v0 message relayed twice (Sherlock 2023-03 H-2) | storage layout aligned with legacy; v0 hash checked | R | – | ? | – | y (that was the point) | – | n | n | VERIFIED `op-v9 src/universal/CrossDomainMessenger.sol:21-78` spacers, `:122`, `:229-232` |
| 15 | Metering reset by re-initialisation (Trust TRST-L-2) | init only when unset | R | – | n (other initializers reviewed one by one later) | – | – | n | y (OPCMv2 re-runs every initializer each upgrade) | n | VERIFIED `op-v9 src/L1/ResourceMetering.sol:168-172` |
| 16 | Try/catch around `setAnchorState` can be starved of gas (IRI L-01, U13 5.2.6) | fuzz test + semgrep rule + monitoring (PR 14144) — no code change | N | – | – | – | – | – | – | ? (holds only while the callee is cheap relative to the caller's tail; gas schedule and super-game `setAnchorState` changed since) | VERIFIED still `try … catch { }` at `op-v9 FaultDisputeGame.sol:1057`, `SuperFaultDisputeGame.sol:1022` |
| 17 | Portal `upgrade()` clears/sets wrong slots (Spearbit 2025-05 5.3.6) | stop writing `systemConfig`; **stop clearing spacers in all `upgrade()` functions** (3f77c1b) | – | – | y | – | n | n | – | – | VERIFIED legacy slots are reserved, not cleared: `op-v9 OptimismPortal2.sol:67-132` (`spacer_52_0_32` legacy proofs, `spacer_56_0_20` factory, `spacer_58_0_32` blacklist, `spacer_59_*` respected type / timestamp, `spacer_63_20_1` superRootsActive) |
| 18 | Each upgrade deployed a new DelayedWETH (U16a 5.1.2) | gate redeploy (PR 17406) | R going forward | – | – | – | n (proxies already minted stay) | n | – | – | report; U21 re-points WETH pause to the lockbox (`op-v9 src/dispute/DelayedWETH.sol:43-63`) |
| 19 | Migrator forgot the new DelayedWETH (OPCMv2 3.1.1) | reuse member 0's existing proxy (PR 19281) | I | – | – | – | n | n | y (U21 3.1.15) | – | report |
| 20 | deploy() front-run / missing onlyDelegateCall (OPCMv2 3.2.6) | `msg.sender` in salt; onlyDelegateCall (PR 19272) | R | – | y | y | – | – | n | n | report; PASS A C10/C14 re-derived it |
| 21 | Validator did not bind game registry to portal registry (U20 3.1.6) | validator check ANCHORP-70 (ef695a3), negative tests for legacy/super/ZK | N on-chain | – | y | – | – | n | – | – | see row 1 |
| 22 | Validator did not bind `SystemConfig.l2ChainId` (U20 3.1.3) | validator check SYSCON-140 (cba37e8) | N on-chain | – | n (migration validator: U21 3.1.18) | – | – | n | – | – | portal consumes the value at `op-v9 OptimismPortal2.sol:437-442` |
| 23 | Lookalike super-permissioned implementation (U20 3.1.2) | address equality (283bb45) | R (validator) | – | ? | – | – | – | – | – | report |
| 24 | SuperPermissioned payable init traps bond (U20 3.1.5) | reject nonzero value (44eb954) | R | – | – | – | – | – | – | – | report |
| 25 | `extend()` could pause (Spearbit 5.3.7) | require already paused (1891f66) | R | – | – | – | – | – | – | – | report |
| 26 | Inverted finalization check (Zeppelin 2022-05 H-01); l2Sender clobber (M-04) | corrected; non-reentrancy via `l2Sender` | R | – | y | – | – | – | n | n | VERIFIED `hist/v1.0.0 contracts/L1/OptimismPortal.sol:333`, `op-v9 OptimismPortal2.sol:594-596` |
| 27 | Unauthenticated refund path (Zeppelin 2022-05 C-01) | moved behind `onlyOtherBridge`; refunds later removed | R | y | y (ERC721 bridges got and lost refunds too) | – | – | – | n | n | report + v1.0.0 tree |
| 28 | Portal gas check before SSTORE / 63-64 (Sherlock 2023-01 H-1, H-2; 2023-03 H-3) | `SafeCall.callWithMinGas` / `hasMinGas` with 40k base | R for the then-current gas schedule | y | y | y | n (migrated legacy withdrawals: 2023-03 H-1 handled by migration change) | – | y (v9 adds NEW_ACCOUNT_STATE_GAS 183,600 reserve: U21 3.1.10) | ? | VERIFIED `hist/v1.0.0 contracts/libraries/SafeCall.sol:91-121`, `op-v9 src/libraries/SafeCall.sol:9` |
| 29 | Deposits without gas (Sherlock 2023-01 M-11, 2023-03 M-5) | `minimumGasLimit(len)`; 120 kB cap | R | – | – | y | – | – | n | n | VERIFIED `hist/v1.0.0 contracts/L1/OptimismPortal.sol:196,453,461` |
| 30 | Deleting finalized outputs (Sherlock 2023-01 M-10) | (code) cannot delete finalized outputs | R | – | – | – | – | – | y (blacklist + retirement replace it; no age limit on blacklisting) | – | VERIFIED `hist/v1.0.0 contracts/L1/L2OutputOracle.sol` deleteL2Outputs; `op-v9 AnchorStateRegistry.sol:179` has no time bound |
| 31 | kona trace-extension and zero-root acceptance (Kona 3.1.1, 3.1.2); decompression divergence (3.2.1) | PR 19775; PR 455 | R in kona after the fix | – | ? (interop path waved off) | – | n (prestates built before the fix) | – | ? | ? | report only; kona tree not available locally |
| 32 | MIPS64 futex / shifts / bltzal (Spearbit MT-Cannon 5.1.1, 5.2.1, 5.3.1; Base M-01) | PRs 13453, 14114, 14185, 13429 | R | – | y (Go + Solidity) | – | n | – | ? | ? | report |
| 33 | MIPS64 syscall error registers swapped; eventfd (Cannon fix review) | PRs 16341/16346/16384 | R | – | y | – | n (earlier VM deployments) | – | – | – | report |
| 34 | Interop before liquidity pooling bricks withdrawals (Interop Contracts 5.2.1) | redesign: `unlockETH` reverts on insufficient balance | R by redesign | – | – | y | n | n | ? (ordering of L2 activation vs L1 `migrate` is operational) | – | VERIFIED `op-v9 src/L1/ETHLockbox.sol:166` |
| 35 | setFeature / CGT / lockbox toggles (U16a 5.2.1 acknowledged; CGT 3.1.2 fixed) | v9: "ETHLockbox cannot be disabled" | R at v9 for the lockbox flag | n | n (other features) | – | n | n | – | – | VERIFIED `op-v9 src/L1/SystemConfig.sol` setFeature |

## B. Top 15 — fixes whose safety condition may have been removed or bypassed later (mutation targets)

Ranking = (how directly the condition gates a value exit) x (strength of the code evidence that it changed) x
(whether any later report re-validated it on-chain rather than in a validator or a comment).

1. **Row 1 — registry binding check removed at v7.** Condition that made removal "safe": every pre-existing game is
   retired by `retirementTimestamp` at `initialize`. At v9 that timestamp is set only when zero
   (`op-v9 AnchorStateRegistry.sol:130-132`) while `initialize` rewrites `disputeGameFactory` and `respectedGameType`
   (`:107-109`). Mutations: (a) a type left registered in a chain's factory whose `gameArgs` name another registry;
   (b) a factory shared by two registries (post-`migrate`, or the U15->U16a two-ASR history); (c) a game created after the
   chain's retirement cut-off under registry B and presented to registry A. OP Mainnet is clean for (a) at block
   26433900; the other three chains are unread.
2. **Row 2 — blacklist check removed from `getAnchorRoot`.** Stated assumption: invalid games are invalidated BEFORE
   they finalize. Since then: games start from the anchor without re-validation, super games reinterpret a legacy
   anchor (U20 3.1.4), `initialize` keeps `anchorGame` unless the starting root changes. Mutation: an anchor game that
   is later blacklisted or retired, or belongs to a de-respected type, keeps seeding new games.
3. **Row 3 — re-prove gate removed at v1.4.0.** The v1.0.0 fix relied on one record per withdrawal. v1.4.0+ allows
   any number of per-submitter records and never checks `finalizedWithdrawals` in `prove` (`op-v9 OptimismPortal2.sol:390-490`).
   Mutations: records written after finalization; records that survive registry replacement; the new permissionless
   `deleteProvenWithdrawal` acting on records whose stored address predates the current factory.
4. **Row 4 — "messenger never reverts / portal always finalizes" inverted at v9.** New condition: the portal reverts
   iff `!success && _tx.sender == L2CDM`. Mutations: every way `relayMessage` can return false or revert for a first
   relay (pause pointer mismatch, unsafe target, version-0 already relayed, reserve under the Amsterdam schedule,
   reentrant-relay branch) and every withdrawal initiated under older L2 constants.
5. **Row 6 — pause identifier follows a mutable pointer.** Fix covered one function. Mutations: other writers of
   `ethLockbox` (`initialize`), of `SystemConfig.optimismPortal`, of the lockbox's own `systemConfig`; contracts that
   resolve pause through a different pointer chain (messenger -> its SystemConfig; bridges; legacy WETH/ASR proxies);
   pauses recorded under the retired portal identifier.
6. **Row 12 — block-number challenge is the only anchor sanity check and exists only on output-root games.** Still
   callable between `resolveClaim` and `resolve` (Spearbit 5.2.2 open at v9), unpermissioned on the permissioned game
   (U19 3.2.10 open at v9), absent on super games (U21 3.2.11).
7. **Row 16 — try/catch gas assumption.** Never fixed in code; depends on relative gas costs that changed with
   super-root `setAnchorState` and with the Amsterdam constants shipped in v9.
8. **Row 28 — SafeCall reserve constants.** The 2023 fix hard-codes EVM gas rules; v9 adds a second reserve and the
   invariant test does not exercise it (U21 3.2.8). Mutation: targets/values that sit between the two reserve regimes.
9. **Row 17 — spacers are no longer cleared.** Any later layout that reuses a legacy portal slot, or any chain whose
   legacy slots hold non-default residue, changes behaviour silently (PASS A tested junk at v9 on four chains; older
   intermediate versions untested).
10. **Row 15 / Row 5 — initializer idempotence under OPCMv2.** The 2023 fixes guard two fields. OPCMv2 re-runs every
    initializer on every upgrade with live values plus overrides; the answer to OPCMv2 3.3.13 was a review rule.
    Mutation: initializer arguments that differ from live state for a chain with a non-standard history.
11. **Row 13 — creator identity.** Permissionless games fixed; permissioned and super-permissioned games still
    authorise by `tx.origin`, and a super-permissioned game is DEFENDER_WINS at creation.
12. **Row 30 — "finalized outputs cannot be deleted" replaced by timeless blacklist/retirement.** Mutation: guardian
    actions after finality interacting with proofs already matured or with `deleteProvenWithdrawal`.
13. **Row 21/22 — bindings that exist only in the validator** (game registry == portal registry; `l2ChainId`).
    Mutation: any state not produced by the standard OPCM flow or not re-validated after a later privileged step.
14. **Row 31/33 — proof-program fixes vs prestates already deployed.** Mutation: games created under a prestate built
    before a soundness fix and still open or claim-valid after the prestate switch.
15. **Row 18/19 — DelayedWETH generations.** Old proxies keep bonds; later releases change what "paused" and "delay"
    mean for them (U21 3.1.5, 3.1.15) or stop upgrading them altogether.

## C. Fixes that are still sound at v9 (checked)

Rows 5, 7 (access control part), 8, 9, 10, 11, 14, 15 (the two guarded fields), 26, 29: the guard is present at
`op-v9` at the cited lines and no later report weakens it.
