# Lane 29 report — Shared Lockbox / Multi-Portal Composition

## Result

No bounty candidate survived falsification. Three concrete primitives were retained:

- PRIM-2901: every authorized portal has amount-unbounded authority over the fungible shared pool
  while idle;
- PRIM-2902: a withdrawal can cause portal A to originate an arbitrary L2 deposit through portal B,
  executing on L2 B as portal A's alias;
- PRIM-2903: portal/retired-lockbox authorizations are monotonic, and common ProxyAdmin ownership is
  checked only when authorization is granted.

The live authorization state is expected, the OP Mainnet/Unichain migration preconditions hold,
withdrawal proofs are chain-bound, and no permissionless migration poison or current cross-portal
value leak was found. Six rejected compositions record their exact killing facts.

Source target is commit `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`; baseline is
`f45a5ccfebcdf6da3f5b09cbc512667c063730b7`. No audit, finding, issue, or PR history was consulted.
All public RPC use was passive.

## 1. ETHLockbox v9 state machine

Pinned source: `packages/contracts-bedrock/src/L1/ETHLockbox.sol`.

| Function | Exact caller condition | Trusted inputs/state | Mutation/value flow | External/reentrancy surface |
|---|---|---|---|---|
| `initialize` (94-109) | ProxyAdmin or its owner (101-102) and reinitializer version 1 | owner-chosen SuperchainConfig and portal list | stores SC, authorizes every portal | each authorization introspects both proxies and the portal's SystemConfig/SC; only owner-chosen targets can callback |
| `paused` (111-114) | anyone/view | stored SC | none | external view call `isLocalOrGlobalPaused(address(this))` |
| `guardian` (116-120) | anyone/view | stored SC | none | external view call |
| `authorizePortal` (122-130) | ProxyAdmin owner | portal proxy must have same PA owner; portal SystemConfig must name the same SC | sticky `authorizedPortals = true` | proxy/owner/SystemConfig view calls occur before mutation |
| `authorizeLockbox` (180-196) | ProxyAdmin owner | target lockbox proxy must have same PA owner; there is no SC check | sticky `authorizedLockboxes = true` | target proxy owner introspection |
| `receiveLiquidity` (132-140) | `authorizedLockboxes[msg.sender]` | only `msg.value` | ETH remains in lockbox; event | no external call |
| `lockETH` (142-151) | `authorizedPortals[msg.sender]` | only `msg.value`; not pause-gated | ETH remains in lockbox; event | no external call |
| `unlockETH` (153-178) | unpaused; authorized portal; `_value <= total balance`; caller portal's `l2Sender` must be default | caller portal chooses `_value`; no per-portal accounting | sends `_value` to caller's `donateETH` | SC pause view, portal `l2Sender` view, then value-bearing portal call; real `donateETH` is empty |
| `migrateLiquidity` (198-216) | ProxyAdmin owner; destination has same PA owner | entire current balance and owner-chosen destination | calls destination `receiveLiquidity` with all ETH | value-bearing call to same-owner destination; no reentrancy guard, but destination must separately authorize source or revert |

`ProxyAdminOwnedBase.sol:40-76` resolves the proxy's ProxyAdmin from the reserved proxy-owner slot
(or the one legacy ResolvedDelegateProxy shape), and lines 79-105 implement same-owner and caller
assertions. Equality is between ProxyAdmin *owners*, so distinct ProxyAdmins are intentionally
compatible.

### v8 -> v9

The liquidity functions and their runtime authorization logic are otherwise unchanged. The material
lockbox changes are:

- v8's `systemConfig` in slot 0 offset 2 became a legacy spacer; v9 adds stored
  `superchainConfig` at slot 3 (`v8 ETHLockbox.sol:66-74`; v9:66-78).
- initialization now accepts the SC directly (`v8:86-108`; v9:91-109).
- pause/guardian resolution goes directly through the stored SC (`v9:111-120`) rather than through
  one chain's SystemConfig (`v8:110-119`).
- portal authorization now reads `portal.systemConfig().superchainConfig()` (`v9:218-235`) rather
  than `portal.superchainConfig()` (`v8:217-230`). This avoids a self-comparison after a portal has
  already been pointed at the candidate shared lockbox.

All four live lockboxes retain initialized byte 1 because the implementation's `INIT_VERSION` is
still 1. OPCM resets the byte through StorageSetter before rerunning initialization
(`OPContractsManagerUtils.sol:352-386`). The v9 implementation constructor remains permanently
initialized/disabled; the proxy is not permissionlessly reinitializable.

## 2. Live L1 state

Full addresses, balances, slots, authorization matrices, implementation hashes, and events are in
`mirror/lane-29/LIVE_STATE.md`.

At block 26433900:

- each lockbox authorizes exactly its own portal among the four known portals;
- all 16 known-lockbox `authorizedLockboxes` entries are false;
- all four portal/lockbox pairs use distinct ProxyAdmins with the same owner Safe
  `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`;
- all use SC `0x95703e...4a4C`, are unpaused, have `ETH_LOCKBOX=true`, `INTEROP=false`,
  `CUSTOM_GAS_TOKEN=false`, and last OPCM version 9.0.3;
- portals have zero balance; lockboxes total 226091.544689757786595528 ETH.

The exact N-1 -> N state change is narrow: lockbox slot 3 went from zero to the common SC and the
implementations/versions changed. Inspected portal state addresses, `l2Sender`, initialized byte,
and balances did not change in the U21 transaction. The old per-chain SystemConfig bytes remain in
the lockbox spacer. The only N-block balance delta was a normal OP deposit before the upgrade tx.

A 10,000-block authorization/migration-topic scan found only the four expected U21
`PortalAuthorized` events. No live unexpected authorization or migration was found.

## 3. Every portal-caller gate in v9 `src/`

The exhaustive source search produced these runtime gates:

1. `ETHLockbox.lockETH`: `authorizedPortals[msg.sender]` gates depositing ETH into the lockbox
   (`ETHLockbox.sol:142-151`).
2. `ETHLockbox.unlockETH`: the same mapping plus the caller portal's default `l2Sender` gates
   releasing any amount up to the total pool balance (`ETHLockbox.sol:153-177`).
3. `L1CrossDomainMessenger._isOtherMessenger`: exact equality
   `msg.sender == portal && portal.l2Sender() == otherMessenger` gates the initial relay path and
   its value; callers failing it may only replay an already-failed message with zero value
   (`L1CrossDomainMessenger.sol:128-143`; `CrossDomainMessenger.sol:239-248`).

Related but not a caller check, `OptimismPortal2.migrateToSharedDisputeGame` refuses a new lockbox
unless that lockbox already authorizes this portal (`OptimismPortal2.sol:528-571`). Validators read
authorization but do not grant runtime capability.

## 4. Withdrawal target analysis

The v8 and v9 portal bad-target lists are identical and contain only the current portal and current
lockbox (`v8 OptimismPortal2.sol:791-795`; v9:845-849). Both prove and finalize enforce it.

### Current/shared lockbox

A direct call to the current lockbox is rejected before proof/finalization. After migration the
current address is the shared lockbox, so calldata `unlockETH`, `lockETH`, `receiveLiquidity`, or
`migrateLiquidity` never reaches it as a direct withdrawal target. This is reproduced against the
deployed bytecode.

### Retired/source lockbox

After migration the source portal remains authorized on its old lockbox, which is no longer a bad
target.

- `unlockETH` still fails because target execution occurs after the portal sets non-default
  `l2Sender` (`OptimismPortal2.sol:617-630`; `ETHLockbox.sol:168-174`).
- `receiveLiquidity` sees a portal, not an authorized lockbox.
- `migrateLiquidity` sees the portal, not the ProxyAdmin owner.
- `lockETH` can succeed and strand the user's own withdrawn ETH in the retired box. That value was
  burned on L2; aggregate liability and shared liquid backing fall equally. This is self-harm, not
  a deficit or theft.

A different chain's retired lockbox does not authorize the source portal. If the target call fails,
the portal returns the withdrawal value to its current lockbox (`OptimismPortal2.sol:659-665`).

### Sibling portal

A sibling portal is allowed. Its useful public paths are:

- `donateETH`: accepts the withdrawing user's value into the sibling portal without L2 mint;
- `receive`/`depositTransaction`: locks `msg.value` into B's lockbox and emits an L2 B deposit from
  portal A's alias;
- `finalizeWithdrawal...`: can nest a separately valid B withdrawal if the outer call carries no
  value; B's finalized flag and proof checks still apply;
- migration functions: reject because portal A is not the ProxyAdmin owner.

The derived-deposit case is PRIM-2902. All portal aliases are empty on all four L2s, and no core L2
contract trusts one. Thus the zero-mint/arbitrary-call-value shape has no current asset or core
authority to consume. An own-portal alias cannot be synthesized because self-targeting is blocked.

### Reentrancy

Same-portal withdrawal reentrancy is blocked by non-default `l2Sender` before any unlock
(`OptimismPortal2.sol:591-596`). Cross-portal nesting is possible, but each portal independently
checks/marks its withdrawal before the target call. The lockbox has no per-portal accounting or
storage update that can be corrupted; its ETH balance is reduced by the EVM value transfer. No
one-proof/two-unlock sequence was found.

## 5. Chain binding before shared-pool debit

For super games, `proveWithdrawalTransaction` retrieves the game output root through
`rootClaimByChainId(systemConfig.l2ChainId())` (`OptimismPortal2.sol:437-449`) and verifies the
withdrawal against that output's message-passer storage root (452-478). Super game implementations
return only the tuple matching the requested ID and revert if it is absent
(`SuperPermissionedDisputeGame.sol:80-89`; `SuperFaultDisputeGame.sol:806-818`).

Migration enforces nonzero, distinct, ascending IDs (`OPContractsManagerMigrator.sol:287-327`).
Live OP/Unichain are 10 and 130. Therefore a withdrawal proven only in OP's output cannot be proven
through Unichain's portal. This kills the direct shared-pool double-debit composition.

## 6. Planned migration ordering

`OPContractsManagerV2.migrate` must execute via delegatecall, validates each chain's OPCM sequence,
then delegatecalls the release migrator (`OPContractsManagerV2.sol:278-313`). The effective
production context is the common owner Safe; mutating calls from any other delegatecall context
fail against the real ProxyAdmins.

`OPContractsManagerMigrator.migrate` executes this atomic order:

1. Validate nonempty input, super game type/anchor, common owners/SC, chain IDs, SC version, and game
   configs (`OPContractsManagerMigrator.sol:129-166`, 287-410).
2. CREATE2-deploy new shared lockbox, DGF, and ASR from the delegatecall context, using chain 0's
   ProxyAdmin and a timestamp salt (`168-222`).
3. Reuse chain 0's DelayedWETH and initialize shared lockbox, DGF, and ASR (`224-263`).
4. For each chain (`265-272`):
   - repoint its legacy DelayedWETH to the shared lockbox;
   - read old lockbox/ASR/DGF and reject CGT or paused state (`475-500`);
   - authorize portal on shared box, enable ETH_LOCKBOX if necessary, irreversibly enable INTEROP
     (`502-514`);
   - upgrade/reinitialize portal to the shared lockbox but old ASR (`515-521`);
   - sweep direct portal ETH (`523-524`);
   - authorize and sweep the old lockbox (`526-534`);
   - clear old DGF implementations (`536-540`);
   - repoint portal to the shared ASR (`542-543`);
   - repoint legacy ASR to shared lockbox (`545-555`);
   - update that SystemConfig to chain 0's DelayedWETH while preserving per-chain fields
     (`432-467`).
5. Register implementations and bonds on the new shared DGF (`275-284`).

No unrelated transaction can enter a migration window. Attacker-influenced code is not called:
all chain addresses are privileged migration inputs, all implementations/blueprints come from the
immutable OPCM container, and the only value recipients are the freshly initialized shared box.
An attacker can call the public migrator directly, but calls originate from the migrator/attacker
context rather than the Safe and revert at the real ProxyAdmin checks, rolling back deployments.

The separate migration validator checks shared implementations/SC, portal authorization and
repointing, feature flags, legacy game clearing/pause routing, and zero portal/retired-lockbox
balances (`OPContractsManagerMigrationValidator.sol:430-577`). It is a view validator, not a call
inside `migrate`; the execution path itself supplies the safety conditions above.

### Repetition and donations

Every input chain must have INTEROP off before any mutation (`OPContractsManagerMigrator.sol:305-311`).
SystemConfig forbids disabling INTEROP (`SystemConfig.sol:528-567`), so same-block, later-block, and
partial re-migrations revert atomically.

The CREATE2 deployer in production is the Safe; a third party cannot predeploy at its address.
Sending ETH to a future CREATE2 address does not set code/nonce and simply gives the future shared
lockbox surplus. Donations to a portal or old box before migration are included by the full-balance
sweeps. There is no equality assertion whose accounting can be poisoned.

## 7. OP Mainnet + Unichain concrete model

Live facts make the documented two-chain migration executable:

- common SC `0x95703e...4a4C`, version 2.5.0;
- distinct ProxyAdmins, common owner Safe;
- IDs 10 then 130;
- ETH_LOCKBOX on, INTEROP/CGT off, neither paused;
- both on OPCM 9.0.3 and `isPermittedMigrateSequence = true`;
- portals hold zero; old boxes total exactly 200807.226200523469952640 ETH.

Ignoring unsolicited ETH sent to the future address, the post-transaction shared balance is
therefore the exact sum of the two old boxes and two zero portal balances; both old boxes and
portals end at zero. There is no per-chain balance after pooling. This is safe only if aggregate
circulating L2 ETH (excluding ETHLiquidity reserves) is backed in aggregate.

Checked non-fault deficit hypotheses:

- no direct portal, bridge, or messenger custody is omitted;
- deposits lock `msg.value` and withdrawals release the proven `_tx.value`;
- no external transaction interleaves during migration;
- the inactive ETHLiquidity proxies are zero today; when activated, only SuperchainETHBridge can
  move the deliberately preloaded reserve, and source burn/destination mint conserves aggregate
  circulating value;
- a valid chain-specific withdrawal can consume either chain's contributed ETH by design, but no
  permissionless source of unbacked circulating ETH was found.

JSON-RPC cannot enumerate total L2 native balances, so historical deposit/withdrawal/state-migration
reconciliation remains an appropriate independent follow-up. This lane does not claim a wei-exact
circulating-supply proof.

## 8. Fork evidence

Harness: `/home/user/u21-work/codex-29/h`, with `l1n` added as required. Mirrored test:
`mirror/lane-29/LockboxLane29.t.sol`. Six tests pass against the block-N deployed proxies:

- diagonal portal authorization and empty known-lockbox authorization matrix;
- EOA direct unlock rejection and authorized-idle-portal amount authority;
- non-default `l2Sender` rejection on the real lockbox;
- exact self/current-lockbox versus sibling bad-target behavior;
- owner/authorization gates;
- sibling portal's zero-mint/nonzero-L2-value aliased deposit behavior.

The portal impersonation and slot-50 setup are explicitly primitive tests, not claims of attacker
reachability.

## 9. Final disposition and follow-up

No `CAND-29xx` file was created. Strongest negative results are REJ-2901 (two-layer direct-target
defense), REJ-2904 (chain-bound proofs), and REJ-2903 (atomic, non-poisonable migration).

Compositions worth independent attention:

1. Search future/application state for balances or privileges at *cross-portal* and cross-messenger
   L2 aliases before interop activation; the generic origin capability is real even though core
   state is clean today.
2. Treat permanent common ProxyAdmin ownership as a formal interop-set invariant. Sticky portal
   authorization becomes dangerous if ownership domains later separate.
3. Independently reconcile historical circulating OP/Unichain ETH against the 200807.2262 ETH that
   will be pooled, explicitly excluding the preloaded ETHLiquidity reserves.

