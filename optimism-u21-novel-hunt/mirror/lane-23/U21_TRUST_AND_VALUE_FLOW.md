# Lane 23 — U21 Portal / ETHLockbox trust and value flow

## Scope and accounting model

This is an independent blind-first review of op-contracts/v9.0.0 at commit
`ba6fcadbc57eb99918c5b0f14f57c72527f531e3`, compared with v8.0.0 at
`f45a5ccfebcdf6da3f5b09cbc512667c063730b7`. State observations use Ethereum
blocks 26430858 (N-1), 26430859 (N), and 26433900 (later). No public-network
transaction was broadcast.

For conservation, define:

- `L`: ETH in every lockbox backing the relevant portal set.
- `P`: ETH held directly by those portals.
- `M`: ETH held by the L1CrossDomainMessenger for a failed, replayable relay.
- `Q`: aggregate outstanding L2 ETH obligations, including initiated withdrawals.
- `S`: excess ETH that has no protocol creditor (donations, forced ETH, or value
  forfeited by a finalized direct withdrawal whose chosen target reverted).

The useful invariant is `L + P + M = Q + S` over value-moving transitions. A
deposit increases both custody and `Q`; a successful withdrawal reduces both;
migration only changes the custody location; a donation/forced transfer increases
`S`; and a failed replayable messenger delivery moves backing from `L` to `M`.

The deposit event commits separately to `msg.value` and `_value`: `msg.value` is
locked and minted on L2, while `_value` is only the amount the derived L2
transaction sends to its target. Their inequality therefore does not create an
unbacked mint. See `src/L1/OptimismPortal2.sol:730-795`.

## Every ETH-moving edge

| Edge | Caller / restriction | Balance and liability effect | Balance read / trust boundary | Evidence |
|---|---|---|---|---|
| `receive()` -> `depositTransaction` | Anyone; contract callers are aliased | Exact `msg.value` moves directly to current lockbox and creates the same L2 mint obligation | No portal-balance read; exact call value | `OptimismPortal2.sol:372-378,730-795`; `test_receiveAlsoMovesValueDirectlyIntoLockbox` |
| `depositTransaction` | Anyone; not pause-gated; positive `msg.value` forbidden in CGT | `L += msg.value`, `Q += msg.value`; portal stays at zero | Current feature flag and lockbox pointer; lockbox trusts authorized portal | `OptimismPortal2.sol:741-794`; `ETHLockbox.sol:142-151`; deposit fork test |
| `donateETH` | Anyone, including lockbox during unlock | ETH remains in portal; no deposit event and no L2 liability | No reads or restriction | `OptimismPortal2.sol:380-383` |
| Forced ETH to portal or lockbox | Anyone able to self-destruct a funded contract; coinbase-style forced value is also outside ordinary dispatch | Increases `P` or `L` and `S`; creates no liability | Bypasses Solidity entry points | `test_donationAndForcedETHStayInPortalUntilAdminMigration` |
| `ETHLockbox.lockETH` | Authorized portal only | Exact `msg.value` enters pool; the liability is created by the portal deposit event, not by the lockbox | No aggregate balance read and no per-portal ledger | `ETHLockbox.sol:142-151` |
| `ETHLockbox.unlockETH` | Authorized portal; unpaused; enough aggregate balance; portal `l2Sender == 0xdead` | Sends exact `_value` to caller portal via `donateETH`; transiently `L -= v`, `P += v` | Reads global `address(this).balance`; trusts every authorized portal and its proof domain | `ETHLockbox.sol:153-178` |
| Successful direct withdrawal target call | Permissionless finalizer after a valid mature proof | Unlock gives portal `v`, then CALL transfers `v` to target; `L -= v`, `Q -= v` | Target and calldata are L2-user-controlled; SafeCall forwards all remaining gas subject to a floor | `OptimismPortal2.sol:577-665`; `SafeCall.sol:121-171` |
| Failed non-messenger target call | Same | CALL retains `v` in portal, then exact `v` is re-locked; `L` net zero, claim finalized, `S += v`; pre-existing portal surplus is untouched | Relock uses `_tx.value`, never `address(this).balance` | `OptimismPortal2.sol:655-665`; modeled-only `test_modeledDirectWithdrawalFailureRelocksExactValueAndPreservesPortalSurplus` |
| Successful L2 messenger -> L1 messenger outer call, successful inner relay | Valid messenger withdrawal | `L -= v`; messenger forwards `v`; claim is finalized | Portal authenticates proof and sender; L1 messenger authenticates portal plus L2 messenger | `L1CrossDomainMessenger.sol:136-143`; `CrossDomainMessenger.sol:209-307`; real 638.177 ETH fork finalization |
| Successful outer messenger call, failed inner target | Valid messenger withdrawal | Portal sees success and finalizes; messenger retains `v`, marks message failed, and permits zero-value replay: backing moves `L -> M` | Messenger replay mapping becomes the creditor/accounting record | `CrossDomainMessenger.sol:239-306` |
| Reverted L1 messenger outer call | Valid messenger withdrawal whose portal-to-messenger CALL returns false | v9 reverts the entire finalize: unlock, finalized flag, and every nested change roll back; `L`, `P`, `M`, `Q` unchanged | Sender must equal L2 messenger predeploy for the new special revert | `OptimismPortal2.sol:639-653`; etched-target negative test |
| `OptimismPortal2.migrateLiquidity` | ProxyAdmin owner; active lockbox; non-CGT | Reads the entire portal balance and locks it; `P -> L`, aggregate custody unchanged | Reads `address(this).balance`; privileged sweep | `OptimismPortal2.sol:500-512` |
| `ETHLockbox.migrateLiquidity` -> `receiveLiquidity` | ProxyAdmin owner; destination must share owner; receiver must have authorized source lockbox | Reads and transfers the entire old lockbox balance; old `L ->` new `L` | Reads `address(this).balance`; trusted atomic migration | `ETHLockbox.sol:180-216` |
| `migrateToSharedDisputeGame` | Interop enabled, unpaused, ProxyAdmin owner, new lockbox already authorizes portal | Pointer change only; it moves no ETH. It is unsafe if separated from the old-lockbox sweep, as NatSpec states | Privileged migration transaction is the atomicity boundary | `OptimismPortal2.sol:515-571` |
| OPCM interop migration | Must execute through the owner-controlled OPCM delegatecall flow | Authorize new portal -> enable features -> point portal at new lockbox -> sweep portal -> sweep old lockbox -> update ASR; aggregate custody unchanged or whole tx reverts | Rejects CGT, pause, duplicate chain IDs, and repeat migration | `OPContractsManagerMigrator.sol:129-328,475-555` |
| Standard bridge ETH deposit | User / bridge API; requires `msg.value == amount` | Bridge -> messenger -> portal deposit -> lockbox; exactly one mint liability | Each hop forwards the same amount | `universal/StandardBridge.sol:309-329`; `L1CrossDomainMessenger.sol:128-133` |
| Standard bridge ETH withdrawal finalization | Only remote bridge through authenticated messenger | Messenger sends exact `_amount`, bridge requires `msg.value == _amount`, then sends it once to recipient | Messenger and remote-bridge authentication | `universal/StandardBridge.sol:239-260` |

## Finalization ordering and reentrancy surface

v9 performs, in order: pause/CGT checks; `l2Sender` reentrancy check; bad-target
check; proof/finality checks; `finalizedWithdrawals = true`; lockbox unlock;
`l2Sender = _tx.sender`; all-gas target CALL; reset `l2Sender`; estimation-address
revert; new L2-messenger failure revert; event; and exact-value relock on failed
non-messenger calls (`OptimismPortal2.sol:583-665`). Any later revert rolls back the
earlier finalized bit and unlock atomically.

During the target call:

- Another finalization is rejected because `l2Sender != 0xdead` before it can
  unlock. The finalized bit independently blocks replay after return.
- `unlockETH` on any lockbox that still authorizes this portal is rejected by the
  lockbox's `l2Sender` check. This includes a formerly used lockbox.
- A nested deposit or donation is allowed. A deposit locks its own exact call value
  and creates the matching new liability; it cannot spend unrelated portal ETH. A
  target that returns success after donating received value merely converts its own
  completed withdrawal into portal surplus.
- Proving another withdrawal can succeed if the callback supplies a genuine proof,
  but it moves no ETH. Re-proving the active hash cannot clear the already-set
  finalized mapping. Deleting another permanently invalid proof also moves no ETH;
  the active valid proof fails the deletion guard
  (`OptimismPortal2.sol:390-491,707-728`).
- A callback may invoke permissionless replay of some previously failed messenger
  message, but that replay spends the value already escrowed in the messenger; it
  does not access this withdrawal's transient portal balance. Messenger target and
  reentrancy guards remain independent.
- Admin liquidity migration is owner-only (`ProxyAdminOwnedBase.sol:88-105`).

The portal blocks itself and its current lockbox as withdrawal targets
(`OptimismPortal2.sol:845-849`). The messenger separately blocks itself and the
portal (`L1CrossDomainMessenger.sol:140-143`). SystemConfig, ASR, ProxyAdmin, and
migration entry points either reject value/nonprivileged callers or have no ETH
exit. The StandardBridge's outbound payable path only deposits the same value back
through the messenger; its inbound finalizer requires the authenticated remote
bridge. A former lockbox is not on the portal's dynamic bad-target list and retains
authorization, but a target call can only re-lock the withdrawal into that old box
(user self-harm); an attempted unlock sees non-default `l2Sender` and reverts. No
permissionless drain was found.

## Pause, CGT, and zero-value states

- Pause blocks proof/finalization and `unlockETH`, but not deposits or `lockETH`.
  Consequently both backing and liabilities can grow while exits wait; neither is
  duplicated (`ETHLockbox.sol:157-170`, `OptimismPortal2.sol:398-409,583-615`).
- CGT mode rejects positive-value deposits, positive-value proof/finalization, and
  portal liquidity migration. `donateETH` and forced ETH remain possible but create
  surplus, not ETH liability. Zero-value proof/finalization may still read the
  lockbox as the pause oracle, but never calls its value-moving methods; a zero-value
  deposit skips `lockETH`. OPCM refuses CGT chains
  (`OPContractsManagerMigrator.sol:483-486`). Live OP Mainnet has CGT=false.
- Zero-value deposit creates no ETH mint; zero-value withdrawal skips both unlock
  and relock; zero-value lock/migration can emit events but cannot change custody.

## Deployed-state conclusion

At N-1, N, and the later fork the portal balance is zero, its lockbox pointer is
unchanged, and the portal is authorized. The lockbox increases at N by exactly
4.204691597090892114 ETH due to an ordinary `ETHLocked` log in transaction 341;
the U21 transaction is transaction 358 and emits no custody event. The later real
withdrawal test decreases the lockbox by exactly 638.177259920741319864 ETH,
leaves the portal at zero, relays the message, sets the finalized bit once, and
restores `l2Sender` to `0xdead`. No conservation violation survived.

