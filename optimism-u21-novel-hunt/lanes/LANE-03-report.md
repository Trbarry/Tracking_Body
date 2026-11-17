# LANE 03 — Portal / ETHLockbox conservation

Phase A (blind). Target `op-contracts/v9.0.0` (`ba6fcadb`), baseline v8.0.0, deployed state at L1
block 26433900. No prior audits or public findings were read.

## Result

No violation of ETH conservation was found. No candidate is filed.

Every way ETH enters, leaves or moves between the portal, the lockbox and the L1 messenger
reconciles exactly once on the real deployed implementations, including under re-entrant targets,
failed targets, gas starvation, pause, and the U21 upgrade boundary. Six primitives and eleven
rejected ideas are recorded.

## What was done

| Step | Output |
|---|---|
| Read and diffed v8 → v9: `OptimismPortal2`, `ETHLockbox`, `SystemConfig`, `Features`, `SafeCall`, `GasConstants`, `CrossDomainMessenger`, `L1CrossDomainMessenger`, `L1StandardBridge`, `SuperchainConfig`, `OPContractsManagerV2` (upgrade path), `OPContractsManagerMigrator` | `U21_TRUST_AND_VALUE_FLOW.md` |
| Read deployed wiring for OP, Ink, Soneium, Unichain before and after U21 | section 6 of that file |
| Decoded lockbox and portal events in the U21 receipt | REJ-0305 |
| Reconciled lockbox balance deltas against `ETHLocked` / `ETHUnlocked` / deposit mint fields from the U21 block to the fork block, four chains | `evidence/lane03/reconcile_u21_window.json` |
| Pulled 30 days of OP Mainnet `MessagePassed` logs (358 withdrawals) and classified each against L1 portal state | `evidence/lane03/classified.json` |
| Wrote 21 fork tests against the real implementations | `test/poc/lane03/Lane03Conservation.t.sol`, `Fixtures.sol`; run log `evidence/lane03/test-run.log` |

Withdrawal population at the fork block (30-day window): 255 finalized, 16 proven and ready, 66
proven and waiting (all `ProofNotOldEnough`), 21 unproven. All 16 ready ones are messenger
withdrawals; the largest is 638.177 ETH. One direct withdrawal with value was available
(SequencerFeeVault, 53.47 ETH, proven 1794824939 against an in-progress game).

## State machine

Custody places: lockbox `L`, portal `P`, messenger `M`, outside `O`. Liability `Λ` is L2 ETH.

| Transition | L | P | M | Λ | Guard |
|---|---|---|---|---|---|
| deposit `v` | +v | 0 | 0 | +v | none (CGT: `v` must be 0) |
| donate `d` | 0 | +d | 0 | 0 | none |
| finalize direct, success | −v | 0 | 0 | 0 (burned earlier on L2) | proof, `finalizedWithdrawals`, not paused |
| finalize direct, target fails | 0 | 0 | 0 | 0 | same; relock is exact |
| finalize messenger, relayed | −v | 0 | 0 | 0 | same + `l2Sender == L2CDM` |
| finalize messenger, target fails or relay is nested | −v | 0 | +v | 0 | message goes to `failedMessages` |
| finalize messenger, messenger reverts | 0 | 0 | 0 | 0 | whole tx reverts (v9) |
| replay failed message, success | 0 | 0 | −v | 0 | `failedMessages && !successfulMessages` |
| PAO sweep | +P | −P | 0 | 0 | PAO only |

Invariants tested:

1. `Δ(L) = Σ deposits − Σ values of withdrawals finalized with a delivered or parked call`, at every step of random sequences.
2. `P` equals the sum of donations; no withdrawal changes it.
3. Each withdrawal hash unlocks at most once; each failed message pays at most once.
4. A transaction either completes one row of the table or changes nothing.

## Tests

All run against deployed code at block 26433900. Substitutions are marked in the test source.

| Test | Shows | Substitution |
|---|---|---|
| `test_A_*` (3) | deposit, `receive`, zero value, `_value > msg.value`, donation | none |
| `test_B_lockbox_callerRestrictions` | every lockbox entry point rejects a non-portal / non-PAO caller; plain ETH send reverts | none |
| `test_B_portal_callerRestrictions` | `migrateLiquidity`, `migrateToSharedDisputeGame`, `initialize`, `setFeature`; PAO cannot disable `ETH_LOCKBOX` | `vm.prank(PAO)` for the last check only |
| `test_B_finalize_guards` | wrong submitter, tampered value, target = portal / lockbox, too little gas, replay | none |
| `test_B_unlockGuard_l2Sender_mockedPortalCaller` | `NoWithdrawalTransactions`, `InsufficientBalance` | mocked caller and `vm.store` |
| `test_C_finalize_real638ETH_exactOnce` | 638.177 ETH: one `ETHUnlocked` of exactly the value, portal 0, message relayed | none |
| `test_C_…reentrancyMatrix` | re-entry outcomes behind L1CDM and the bridge | recipient code etched |
| `test_C_…recipientReverts…replayOnce` | value parked in L1CDM, one replay pays, second reverts | recipient code etched, then restored |
| `test_C_L1CDMCallFailed_…` | v9 revert keeps the withdrawal unfinalized and the lockbox whole | messenger call mocked to revert |
| `test_D_direct_feeVault_realTarget_success` | real direct withdrawal, real target, +53.47 ETH | time warp, permissionless `resolveClaim` / `resolve` |
| `test_D_direct_targetReverts_…` | unlock then exact relock, `success=false` | target etched |
| `test_D_direct_targetBurnsAllGas_…` | gas sweep: revert or exact relock | target etched |
| `test_D_direct_reentrantTarget_matrix_…` | re-entry outcomes for a direct target; stranded donation; PAO sweep | target etched; `vm.prank(PAO)` for the sweep |
| `test_D_direct_estimationOrigin_…` | `GasEstimation` revert leaves state unchanged | `tx.origin = address(1)` |
| `test_E_pause_…` | pause key is the lockbox; deposits still lock | `vm.prank(guardian)` |
| `testFuzz_F_sequenceConservation` | invariants 1-3 over 256 random 12-step sequences | none |
| `test_G_*` (2) | pre-U21 messages relay at the minimum gas the v9 portal accepts | none |
| `test_H_nestedFinalizeInsideReplay_…` | PRIM-0304 | attacker's recipient etched |

How to run: `cd /home/user/u21-work/lane03 && forge test --match-path test/Lane03Conservation.t.sol -vv`.
The shared anvil's upstream returned HTTP 429 for uncached state during this lane, so the final
run used a private anvil: `anvil --port 18030 --fork-url https://eth.drpc.org --fork-block-number 26433900`
and `LANE03_RPC=l1lane03 forge test …`. The private anvil was stopped afterwards.

## Primitives

| ID | One line |
|---|---|
| PRIM-0301 | Anyone can finalize any ready withdrawal with their own gas and call context; a failing direct target ends as finalized + exact relock. |
| PRIM-0302 | Inside a withdrawal call the callee can still deposit, donate, prove and delete proofs; it cannot finalize or touch the lockbox. |
| PRIM-0303 | ETH in the portal is outside lockbox accounting, never spent by withdrawals, and movable only by the PAO (`migrateLiquidity` gate widened in v9). |
| PRIM-0304 | From inside an L1CDM replay, a third party can finalize a victim's messenger withdrawal so its ETH moves lockbox → L1CDM and needs a replay (shown with a real 638 ETH withdrawal). |
| PRIM-0305 | The pause key is the lockbox address; pausing the portal address does nothing; deposits keep locking while paused. |
| PRIM-0306 | After an interop migration, old lockboxes and sibling portals are legal withdrawal targets; only the `l2Sender` check protects an old lockbox (code reading only). |

## Rejected

| ID | Idea | Killed by |
|---|---|---|
| REJ-0301 | double unlock | flag set before unlock; `NoReentrancy`; fuzz |
| REJ-0302 | unlock survives `L1CDMCallFailed` | transaction-level rollback, tested |
| REJ-0303 | portal-held ETH spent or taken | no balance read on the withdrawal path; PAO-only sweep |
| REJ-0304 | gas-burning target prevents relock | out-of-gas reverts everything; gas sweep |
| REJ-0305 | U21 left value in the wrong contract | all four chains already on lockbox; exact reconciliation |
| REJ-0306 | old-`baseGas` messages lost under v9 relay budgets | relayed at minimum gas; otherwise revert and retry |
| REJ-0307 | CGT double custody | value is rejected on every path in CGT mode |
| REJ-0308 | foreign portal on a lockbox | cross-authorization reads all false |
| REJ-0309 | `sender == 0x…dEaD` | address preimage; target and flag guards remain |
| REJ-0310 | pause asymmetry | portal and lockbox read the same pause function |
| REJ-0311 | mint exceeds lock | mint field is `msg.value` |

## Not covered

- The interop Migrator was read, not executed. PRIM-0306 rows after migration are unverified on a fork.
- Behaviour under EIP-8037 (Amsterdam) gas rules: the fork runs current mainnet rules. `SafeCall.NEW_ACCOUNT_STATE_GAS` and the 135k / 15k L1 relay budgets were not measured under the new rules.
- Lockbox balance against total L2 ETH supply was not checked; only flows since U21 were reconciled.
- Historical `PortalAuthorized` / `LockboxAuthorized` sets were not enumerated.
- Ink, Soneium and Unichain were checked by state reads and event reconciliation only; finalizations were exercised on OP Mainnet.

## Worth another lane

1. Execute `OPContractsManagerMigrator.migrate` on a fork for two of the four chains and test PRIM-0306: withdrawals targeting the old lockbox and the sibling portal, and whether any ETH remains reachable in an old lockbox.
2. Re-run `test_G_*` and the direct-withdrawal gas sweep under Amsterdam rules, to confirm the v9 budgets hold for value sent to a new account and that every shortfall ends in a revert, not a recorded finalization.
3. PRIM-0304 combined with a messenger-side change: anything that assumes L1CDM holds no ETH, or a relay target that only works inside the finalization transaction.
