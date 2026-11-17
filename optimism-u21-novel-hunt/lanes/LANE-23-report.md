# Lane 23 report — Portal / ETHLockbox conservation (mirror of lane 03)

## Result

No permissionless, production-reachable conservation violation survived
falsification. No `CAND-23xx` file was created. The deployed v9 state machine
conserves ETH across deposit, unlock, target execution, messenger replay escrow,
failure rollback/relock, and admin migration in every reviewed reachable sequence.

This is a blind-first result. I did not read another lane's files, prior audits,
public findings, top-level U21 artifacts, or forbidden PoC/evidence directories. No
public transaction or state-changing shared-RPC call was made.

## Scope reviewed

Line-by-line v9 review and v8 diff at the pinned commits covered:

- `src/L1/OptimismPortal2.sol`
- `src/L1/ETHLockbox.sol`
- `src/L1/SystemConfig.sol`
- `src/libraries/Features.sol`
- `src/libraries/SafeCall.sol`
- `src/L1/L1StandardBridge.sol` plus inherited
  `src/universal/StandardBridge.sol`
- `src/L1/L1CrossDomainMessenger.sol` and
  `src/universal/CrossDomainMessenger.sol`
- `src/L1/opcm/OPContractsManagerMigrator.sol`, with the owner/delegatecall entry
  in `OPContractsManagerV2.sol` and role checks in `ProxyAdminOwnedBase.sol`

The v9 custody-relevant changes are recorded in
`mirror/lane-23/SOURCE_DIFF_NOTES.md`. Most importantly, a failed outer call to the
L1 messenger now reverts the entire finalization; the lockbox stores and resolves
pause through SuperchainConfig directly; and migration rejects CGT and invalid
multi-chain configurations.

## Conservation state machine

Let `L` be lockbox ETH, `P` portal ETH, `M` messenger-held failed-relay ETH, `Q`
outstanding backed claims, and `S` non-liability surplus. The checked invariant is:

    L + P + M = Q + S

Transitions:

1. Deposit/receive: `L += msg.value`, `Q += msg.value`. `_value` is only derived-L2
   call value; `msg.value` is the mint and locked backing
   (`OptimismPortal2.sol:730-795`, `ETHLockbox.sol:142-151`).
2. Successful withdrawal: `finalized=true`; `L -= value`; portal transiently
   receives value; target receives it; `Q -= value`
   (`OptimismPortal2.sol:583-630`).
3. Failed non-messenger target: CALL transfers nothing and exact `_tx.value` is
   re-locked; `L` net zero, `P` unchanged, claim extinguished, `S += value`
   (`OptimismPortal2.sol:655-665`).
4. Failed messenger inner target: portal-to-messenger call succeeds; value moves
   `L -> M`, messenger records replay entitlement
   (`CrossDomainMessenger.sol:239-306`).
5. Failed messenger outer call: v9 reverts; finalized bit, unlock, and nested state
   all roll back (`OptimismPortal2.sol:639-653`).
6. Donation/forced ETH: `P` or `L` and `S` rise, with no liability. Only the
   ProxyAdmin owner can sweep all `P -> L`
   (`OptimismPortal2.sol:380-383,500-512`).
7. Lockbox migration: old `L ->` new `L`; portal/old-lockbox sweeps and pointer
   changes are one owner transaction in the production OPCM path
   (`OPContractsManagerMigrator.sol:475-555`).

The complete caller/trust/value-edge table is
`mirror/lane-23/U21_TRUST_AND_VALUE_FLOW.md`.

## Exact finalization ordering and callback analysis

v9 order is: pause and CGT checks; `l2Sender` reentrancy guard; bad-target check;
proof/finality checks; finalized bit; unlock; set `l2Sender`; all-remaining-gas CALL
subject to `_tx.gasLimit` floor; reset `l2Sender`; estimation revert; new messenger
failure revert; event; exact relock for a failed non-messenger call
(`OptimismPortal2.sol:583-665`, `SafeCall.sol:121-171`).

At the arbitrary callback:

- nested finalize fails before unlock because `l2Sender != 0xdead`;
- direct old/current lockbox unlock fails for the same reason;
- nested deposit locks its own exact value and emits the matching new liability;
- proof deletion cannot clear the already-set finalized bit and valid proofs do not
  satisfy its permanent-invalidation guard (`OptimismPortal2.sol:707-728`);
- migration/configuration calls remain owner-only
  (`ProxyAdminOwnedBase.sol:88-105`).

Portal and current lockbox are explicitly bad targets
(`OptimismPortal2.sol:845-849`). The L1 messenger blocks itself and portal as inner
message targets (`L1CrossDomainMessenger.sol:140-143`). Former lockboxes remain
authorized after migration and are not on the dynamic bad-target list, but a target
can only re-lock its own withdrawn value there; unlock is stopped by `l2Sender`.

## Exact N-1 -> N -> later state

At blocks 26430858 / 26430859 / 26433900:

- OP portal version is 5.8.0 / 6.1.0 / 6.1.0 and balance is 0 / 0 / 0.
- Lockbox balance is 182416306525160721816415 /
  182420511216757812708529 / 182541068255115703234018 wei.
- Portal lockbox pointer and authorization are unchanged.
- At N: ETH_LOCKBOX=true, INTEROP=false, CGT=false, unpaused, `l2Sender=0xdead`.

The exact 4.204691597090892114 ETH N-1 -> N increase is an ordinary
`ETHLocked` event in transaction index 341; U21 is index 358. The upgrade receipt
has no value-moving portal/lockbox event. Ink and Soneium lockbox balances do not
change at N; Unichain also changes only later. All four portal balances remain zero.

The implementation/storage map in
`mirror/lane-23/U21_PROXY_IMPLEMENTATION_MAP.md` accounts for all 41 touched
proxies. Custody-relevant static changes are lockbox slot 3 (SuperchainConfig), ASR
slot 6 (lockbox), and DelayedWETH slot 5 (lockbox). OP portal slot 1 and messenger
slot 205 changes are same-block ordinary activity, not the U21 transaction. No
interop migration ran.

## Fork evidence

The harness is `mirror/lane-23/test/PortalETHLockboxConservation.t.sol`. Command:

    forge test --match-path test/PortalETHLockboxConservation.t.sol -vvv

Result: 14 passed, 0 failed, 0 skipped. This includes a modeled-balance test that
sets the lockbox to one wei below the real withdrawal value, observes
`ETHLockbox_InsufficientBalance`, and confirms atomic preservation of the
unfinalized state. It is not a claim that the live lockbox is underfunded.

A real mature unfinalized withdrawal was found and finalized against unmodified
deployed bytecode at block 26433900:

- hash `0xb16e5fc2aab1c33e0426b1ad64aa82484b4fe2a637027d2854ad00677f7ed612`
- proof tx `0x424a6ad7ef4500fb905359f319796f5b9396e1465e8ddffc8ff8152e4da3bae6`
- proof submitter `0x67E10B7764A99165665557B3E6cF24555bfC88c3`
- game `0x90F9C9E91fc12E23d170fdeE06be3E00Db21B3F2`
- value 638177259920741319864 wei

The trace shows exact `ETHUnlocked`, L1 messenger relay with the same value,
`RelayedMessage`, and `WithdrawalFinalized(..., true)`. Lockbox falls by exactly the
withdrawal value, portal remains zero, `l2Sender` resets, and a repeat fails.

Target reentrancy/failure tests use the real proof but `vm.etch`; the direct failed
branch additionally copies a real proof word with `vm.store`. Those tests prove
deployed-code ordering/arithmetic only and are not claimed as mainnet-reachable.
This limitation is repeated in `mirror/lane-23/traces/TEST_RESULTS.md`.

## Falsified hypotheses

| ID | Idea | Exact killing fact |
|---|---|---|
| REJ-2301 | Double unlock by reentrancy/replay | `l2Sender` rejects nested finalize before unlock; finalized hash rejects later replay |
| REJ-2302 | Failed call leaves takeable portal ETH | Messenger outer failure rolls back; direct failure relocks exact value; inner messenger failure escrows for replay |
| REJ-2303 | Pre-U21 value in wrong contract | Portal zero, same pointer/auth, no U21 value event; N delta is earlier ordinary deposit |
| REJ-2304 | Pause creates unbacked liability | Deposits lock the same minted `msg.value`; unlocks merely wait |
| REJ-2305 | Omitted bad target drains pool | Current critical targets blocked; old-box unlock hits `l2Sender`; remaining methods role/auth gated |
| REJ-2306 | CGT drain | All positive-value liability paths and migration blocked; live CGT=false |
| REJ-2307 | No per-portal quota is standalone drain | Only authentic mature withdrawals through authorized portals unlock; duplicate IDs rejected |
| REJ-2308 | Proof deletion enables replay | Only permanently invalid proofs delete; finalized mapping is separate and never cleared |
| REJ-2309 | Migration is public/non-atomic | Delegatecall owner context and one EVM transaction; direct/non-owner paths revert |

## Primitives and next compositions

Eight reusable primitives are recorded as PRIM-2301 through PRIM-2308. The three
compositions worth separate attention are:

1. Shared aggregate lockbox plus any independent super-root chain-ID/proof-domain
   confusion in one authorized portal. The migrator rejects duplicate configured IDs,
   but a proof bug would have cross-chain pool blast radius.
2. Monotonic authorization on former lockboxes plus the bad-target list tracking only
   the current lockbox. It is harmless today because `l2Sender` blocks unlock and
   `lockETH` is self-harm; re-evaluate against future portal/lockbox call surfaces and
   the planned interop migration.
3. L1 messenger replay escrow plus portal outer-failure rollback at gas boundaries,
   especially under future Amsterdam state-gas rules. Today's rules and fork tests
   conserve value; Amsterdam is not active and cannot be locally reproduced here.

No candidate score is reported because no candidate survived.

## Independence protocol note

All analysis, tests, primitives, rejections, and this report were completed before a
final validation grep was accidentally scoped across shared output directories and
printed lines from other lanes. No technical conclusion or artifact content was
derived from that output; subsequent work is limited to recording this disclosure
and final mechanical verification. The independent-discovery chronology is
therefore preserved, but the late read itself violated the requested directory
isolation and is disclosed rather than hidden.

