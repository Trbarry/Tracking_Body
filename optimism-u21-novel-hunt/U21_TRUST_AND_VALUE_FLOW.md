# U21 trust and value flow — ETH custody (Portal / ETHLockbox / L1CDM)

Lane 03 orchestrator artifact. Scope: every edge that moves ETH into, out of, or between
`OptimismPortal2` (v6.1.0), `ETHLockbox` (v2.0.0), `L1CrossDomainMessenger` (v2.13.0) and
`L1StandardBridge` (v2.8.2) at `op-contracts/v9.0.0` (`ba6fcadb`), checked against the deployed
OP Mainnet / Ink / Soneium / Unichain proxies at L1 block 26433900.

Paths below are relative to `packages/contracts-bedrock/` in
`/home/user/ethereum-optimism/op-v9.0.0`. "Tested" names a test in
`test/poc/lane03/Lane03Conservation.t.sol` (21 tests, all pass against the real implementations).

## 1. Where value sits (custody) and where liability is created

| Custodian | Holds | On-chain at 26433900 (OP / Ink / Soneium / Unichain) |
|---|---|---|
| `ETHLockbox` | all ETH backing L2 ETH | 182,541.07 / 23,088.76 / 2,195.56 / 18,266.16 ETH |
| `OptimismPortal2` | nothing by design; only `donateETH` / forced ETH | 0 / 0 / 0 / 0 |
| `L1CrossDomainMessenger` | value of messages recorded in `failedMessages` and not yet replayed | 0 / 0 / 0 / 0 |
| `L1StandardBridge` | no ETH (pass-through) | 0 / 0 / 0 / 0 |

| Event | Liability change | Where it is decided |
|---|---|---|
| Deposit | +`msg.value` L2 ETH (mint field of `opaqueData`, not `_value`) | `src/L1/OptimismPortal2.sol:790` |
| Withdrawal initiated on L2 | −`value` L2 ETH (burn in `L2ToL1MessagePasser`) | L2, out of lane |
| Finalization, call succeeded | L1 asset −`_tx.value` | `OptimismPortal2.sol:614`, `:627` |
| Finalization, direct sender, call failed | L1 asset unchanged (relock); L2 burn already happened, so the lockbox gains permanent surplus | `OptimismPortal2.sol:661-665` |
| Finalization, sender = L2CDM, call failed | none: whole tx reverts, withdrawal stays unfinalized | `OptimismPortal2.sol:651-653` (new in v9) |

Balance reads (`address(x).balance`) exist in exactly three places:
`OptimismPortal2.migrateLiquidity` (`:510`), `ETHLockbox.unlockETH` solvency check
(`ETHLockbox.sol:166`), `ETHLockbox.migrateLiquidity` (`:211`). No withdrawal path pays from
`address(portal).balance` beyond the amount it just unlocked.

## 2. Value-moving edges

`PAO` = ProxyAdmin owner Safe `0x5a0A…3d2A`. "anyone" = permissionless.

### 2.1 Into the system

| # | Edge | Function (file:line) | Caller restriction | Pause | Trust assumption |
|---|---|---|---|---|---|
| E1 | user → portal → lockbox | `depositTransaction` (`OptimismPortal2.sol:741`, lock at `:757-759`) | anyone; reverts on `msg.value>0` in CGT mode (`:752-754`) | not blocked | lockbox authorizes this portal; mint == `msg.value` |
| E2 | user → portal → lockbox | `receive()` (`:376`) → E1 with `_to = msg.sender`, gas 100k | anyone | not blocked | contracts get the value at their aliased L2 address |
| E3 | user → L1CDM → portal → lockbox | `sendMessage` (`CrossDomainMessenger.sol:178`) → `_sendMessage` (`L1CrossDomainMessenger.sol:129`) | anyone | not blocked | L1CDM never keeps deposit value |
| E4 | user → bridge → L1CDM → portal → lockbox | `_initiateBridgeETH` (`StandardBridge.sol:309`, send at `:324`) | anyone | not blocked | bridge never keeps ETH |
| E5 | anyone → portal (stays) | `donateETH` (`OptimismPortal2.sol:381`) | anyone, also mid-withdrawal | not blocked | no liability created; value is outside lockbox accounting |
| E6 | forced ETH → portal / lockbox / L1CDM | selfdestruct, coinbase | anyone | n/a | surplus only; lockbox has no `receive`/fallback so plain sends revert |

### 2.2 Out of the system

| # | Edge | Function (file:line) | Caller restriction | Pause | Trust assumption |
|---|---|---|---|---|---|
| X1 | lockbox → portal | `unlockETH` (`ETHLockbox.sol:157-178`) via `donateETH` | `authorizedPortals[msg.sender]`; `msg.sender.l2Sender() == DEFAULT`; `_value <= balance` | blocked (`:159`) | an authorized portal only asks for the value of a withdrawal it has just marked finalized |
| X2 | portal → target | `finalizeWithdrawalTransactionExternalProof` (`OptimismPortal2.sol:577-666`) | anyone, for any proof submitter; target ∉ {portal, current lockbox} | blocked (`:584`) | proof + game validity (`checkWithdrawal` `:671-705`); `finalizedWithdrawals` set at `:610` before any external call |
| X3 | portal → L1CDM → target | `relayMessage` first relay (`CrossDomainMessenger.sol:209-307`) | `msg.sender == portal && portal.l2Sender() == L2CDM` (`L1CrossDomainMessenger.sol:136-138`); target ∉ {L1CDM, portal} | blocked (`:222`) | `msg.value == _value` asserted |
| X4 | L1CDM → target | `relayMessage` replay | anyone, only if `failedMessages[hash]` and not `successfulMessages[hash]`; `msg.value == 0` | blocked | hash commits to value; pays from L1CDM balance |
| X5 | L1CDM → bridge → recipient | `finalizeBridgeETH` (`StandardBridge.sol:239`, pay at `:258`) | messenger + `xDomainMessageSender == L2 bridge` | blocked | — |

### 2.3 Internal moves (no liability change)

| # | Edge | Function (file:line) | Caller restriction | Trust assumption |
|---|---|---|---|---|
| I1 | portal → lockbox (relock) | `lockETH` after a failed direct withdrawal (`OptimismPortal2.sol:661-665`) | internal | exactly `_tx.value`; a failed CALL returned the value |
| I2 | portal → lockbox (sweep) | `migrateLiquidity()` (`OptimismPortal2.sol:502-513`) | PAO; reverts in CGT mode; needs `_isUsingLockbox()` (v8 required INTEROP) | sweeps `address(this).balance` |
| I3 | lockbox → lockbox | `ETHLockbox.migrateLiquidity` (`:203-216`) → `receiveLiquidity` (`:133-140`) | PAO on source; destination must have `authorizedLockboxes[source]`; same PAO | must be atomic with `migrateToSharedDisputeGame` |
| I4 | portal re-pointing | `migrateToSharedDisputeGame` (`OptimismPortal2.sol:528-572`) | PAO; needs INTEROP + ETH_LOCKBOX; not paused; new lockbox authorizes portal | moves no ETH by itself |
| I5 | authorization | `authorizePortal` / `authorizeLockbox` / `initialize` (`ETHLockbox.sol:124`, `:184`, `:94`) | PAO (init: ProxyAdmin or PAO); same PAO; same SuperchainConfig via `portal.systemConfig()` | cannot be revoked |

### 2.4 U21 upgrade and planned migration

| Step | Code | What moved on-chain |
|---|---|---|
| `OPContractsManagerV2` upgrade | `src/L1/opcm/OPContractsManagerV2.sol:860-897` | Nothing. All four chains were already lockbox chains (`wasUsingEthLockbox == true`), so `migrateLiquidity()` (`:895-897`) was skipped. Receipt shows only `Upgraded`, `Initialized`, `PortalAuthorized(own portal)` on portal and lockbox; no `ETHMigrated` / `Liquidity*`. |
| Interop migration (future, PAO) | `src/L1/opcm/OPContractsManagerMigrator.sol:475-556` | In one tx: authorize portal on shared lockbox, re-init portal onto it, `portal.migrateLiquidity()`, `newLockbox.authorizeLockbox(old)`, `old.migrateLiquidity(new)`, `migrateToSharedDisputeGame`. Old lockbox keeps `authorizedPortals[portal] == true` with zero balance. |

## 3. `finalizeWithdrawalTransactionExternalProof` ordering (v9)

| Step | Line | What a re-entrant callee can do from here |
|---|---|---|
| 1. `_assertNotPaused` (`ethLockbox.paused()`) | 584 | — |
| 2. CGT: revert if `_tx.value > 0` | 587-589 | — |
| 3. `l2Sender == DEFAULT` else `NoReentrancy` | 594-596 | — |
| 4. `_isUnsafeTarget` (portal, current lockbox) | 599-601 | — |
| 5. `checkWithdrawal` (view) | 607 | — |
| 6. `finalizedWithdrawals[hash] = true` | 610 | — |
| 7. `ethLockbox.unlockETH(_tx.value)` if value > 0 | 613-615 | lockbox is trusted; it calls back `portal.donateETH` only |
| 8. `l2Sender = _tx.sender` | 618 | — |
| 9. `SafeCall.callWithMinGas(target, gasLimit, value, data)` | 627 | see matrix below |
| 10. `l2Sender = DEFAULT` | 630 | — |
| 11. `!success && tx.origin == address(1)` → `GasEstimation` | 635-637 | moved before the relock in v9 |
| 12. `!success && sender == L2CDM` → `L1CDMCallFailed` | 651-653 | new in v9; rolls back steps 6-10 |
| 13. `emit WithdrawalFinalized` | 657 | — |
| 14. `!success && value > 0` → `lockETH{value}` | 661-665 | — |

Re-entrancy matrix during step 9 (tested: `test_C_…reentrancyMatrix`, `test_D_…matrix…`):

| Callee action | Result |
|---|---|
| `portal.finalize…` (any withdrawal) | reverts `OptimismPortal_NoReentrancy` |
| `lockbox.unlockETH` / `lockETH` / `receiveLiquidity` | reverts `ETHLockbox_Unauthorized` |
| `portal.migrateLiquidity` | reverts (not PAO) |
| `portal.depositTransaction{value}` | allowed: relocks, creates a new L2 mint |
| `portal.donateETH{value}` | allowed: value stays in the portal until PAO sweeps it |
| `portal.proveWithdrawalTransaction`, `deleteProvenWithdrawal` | allowed (no `l2Sender` check); no value effect |
| `L1CDM.relayMessage` replay of the in-flight message | reverts (not in `failedMessages`) |
| `L1CDM.relayMessage` replay of another failed message | no-op: re-marked failed because `xDomainMsgSender` is set |

Reverse nesting is open: from inside an L1CDM **replay**, `portal.l2Sender` is `DEFAULT`, so a
callee can finalize someone else's L2CDM withdrawal; L1CDM then records it as failed and keeps
the value until it is replayed (tested: `test_H_…`, 638.18 ETH moved lockbox → L1CDM).

## 4. Withdrawal-target restrictions

| Target | v9 | Why it is or is not a problem |
|---|---|---|
| portal itself | forbidden at prove and finalize (`:402`, `:599`, `:846-849`) | — |
| current `ethLockbox` | forbidden (same check) | — |
| L1CDM | allowed (required) | only `l2Sender == L2CDM` gets first-relay rights |
| a previous lockbox of this portal (after migration) | not forbidden | `unlockETH` stops on `l2Sender != DEFAULT`; `lockETH{value}` is accepted and strands the caller's own withdrawal value there |
| another portal on the same lockbox (after migration) | not forbidden | portal-as-sender has no rights there; a deposit just moves the liability to the other chain |
| SystemConfig, ASR, DGF, DelayedWETH, SuperchainConfig, ProxyAdmin, bridges | not forbidden | none of them gives `msg.sender == portal` any role (grep of `msg.sender` checks in `src/L1`, `src/dispute`, `src/universal`) |

The only two places that trust `msg.sender == portal` are `ETHLockbox` (lock/unlock) and
`L1CrossDomainMessenger._isOtherMessenger`.

## 5. Pause keying

`portal.paused()`, `SystemConfig.paused()`, `L1CDM.paused()`, `ASR.paused()`, `DelayedWETH` all
resolve to `ethLockbox.paused()` = `superchainConfig.isLocalOrGlobalPaused(address(lockbox))`
(`ETHLockbox.sol:112-114`, `OptimismPortal2.sol:306-308`, `SystemConfig.sol:574-576`).

| Action | While paused |
|---|---|
| deposit (E1-E4), `donateETH`, `lockETH` | allowed |
| prove, finalize, `unlockETH`, relay, replay | blocked |

`SuperchainConfig.pause(portal)` does not pause the chain; the key is the lockbox address
(tested: `test_E_…`). All four chains were already keyed on their lockbox before U21, so the key
did not change in this upgrade.

## 6. Deployed wiring checked at block 26433900

| Check | OP | Ink | Soneium | Unichain |
|---|---|---|---|---|
| `portal.ethLockbox == ASR.ethLockbox == DelayedWETH.ethLockbox` | yes | yes | yes | yes |
| `lockbox.authorizedPortals(own portal)` | true | true | true | true |
| `lockbox.authorizedPortals(other three portals, Base portal)` | false | false | false | false |
| `lockbox.superchainConfig` | `0x9570…4a4C` | same | same | same |
| ETH_LOCKBOX / INTEROP / CUSTOM_GAS_TOKEN | T / F / F | T / F / F | T / F / F | T / F / F |
| portal, L1CDM, bridge balance pre and post U21 | 0 | 0 | 0 | 0 |
| Δlockbox from U21 block to fork block == ΣETHLocked − ΣETHUnlocked | yes (+124.7617 ETH) | yes (0) | yes (0) | yes (+43.8109 ETH) |
| ΣETHLocked == Σ deposit mint fields | yes | yes | yes | yes |

Reconciliation data: `evidence/lane03/reconcile_u21_window.json`.

Not checked: the full historical set of `PortalAuthorized` / `LockboxAuthorized` events per
lockbox (archive log queries were unavailable). Both mappings are PAO-write-only.
