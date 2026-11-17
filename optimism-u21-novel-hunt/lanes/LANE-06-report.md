# LANE 06 — SystemConfig feature-state machine (U21 / op-contracts v9.0.0)

Phase A (blind). Sources: v9 `ba6fcadb`, v8 `f45a5ccf`, v7 `a7c88c8d`; chain state from the local forks
`l1` @26433900 (post) and `l1pre` @26430858 (pre). No audits / public findings were read.
All fork tests use the real deployed bytecode; privileged `vm.prank`s are flagged where used.

Result: **no candidate**. The feature machine and the pause system are consistent on all four upgraded
chains. Six primitives (all privileged-only, pre-existing, documented, or an open question for the
dispute lanes) and six explicit kills.

Files

- `primitives/PRIM-0601.md` … `PRIM-0606.md`
- `rejected/REJ-0601.md` … `REJ-0606.md`
- `test/poc/lane06/{PauseMatrix,FeatureMachine,Enum}.t.sol` (harness: `/home/user/u21-work/lane06`)
- `evidence/lane06/state-pre-26430858.txt`, `state-post-26433900.txt`, `state.sh`,
  `systemconfig-raw-slots-pre-vs-post.txt`

## 1. Feature table (v9 `SystemConfig.isFeatureEnabled`)

Single writer: `SystemConfig.setFeature` (`src/L1/SystemConfig.sol:532-568`), gated by
`_assertOnlyProxyAdminOrProxyAdminOwner()` (:534). `initialize` never touches the mapping. Feature names are
free-form `bytes32`; unknown names are accepted.

| Feature | Who sets | When (std paths) | Unset? | Validated at set time | Read by / when |
|---|---|---|---|---|---|
| `ETH_LOCKBOX` | ProxyAdmin / PAO | OPCM `_apply` before the portal re-init if not already on (`OPContractsManagerV2.sol:861-871`); Migrator (:508-510) | **No** (:545-547) | not already on (:538); `!superchainConfig.paused(optimismPortal())` (:552) — v8 checked `paused()` (global OR identifier) | Portal `_isUsingLockbox` (:806-808) at execution: deposit lock (:757), finalize unlock/relock (:613, :661), `migrateLiquidity` (:503); Portal `initialize` requires flag AND lockbox != 0 (:839-843); `_isUsingInterop` (:812-814); StandardValidator LOCKBOX-00 |
| `CUSTOM_GAS_TOKEN` | ProxyAdmin / PAO | OPCM initial deploy only (`:1000-1009`; upgrade path reverts `CannotUpgradeToCustomGasToken`) | **Yes**, freely | only "state differs" (:538) | Portal at execution: deposit `msg.value>0` (:752-754), prove value>0 (:407-409), finalize value>0 (:587-589), `migrateLiquidity` (:507); Migrator refuses CGT chains (`Migrator.sol:484`); `SystemConfig.isCustomGasToken()` → OPCM `_loadFullConfig` |
| `INTEROP` | ProxyAdmin / PAO | only `OPContractsManagerMigrator._migratePortal` (:513) | **No** (:559-561) | "state differs" only; Portal `initialize` requires `INTEROP ⇒ ETH_LOCKBOX` (:832-836) | Portal `migrateToSharedDisputeGame` (:534); Migrator re-migration guard (:309); StandardValidator (:948) |

v7 → v8 changed nothing here (v8 removed `setGasConfig`, `batchInbox`). v8 → v9: `paused()` no longer
branches on the flag; ETH_LOCKBOX and INTEROP became one-way; the enable guard was narrowed (PRIM-0605).

Combinations: `ETH_LOCKBOX` is mandatory on every v9 portal. `CGT + ETH_LOCKBOX` is the *standard* v9 CGT
shape (the lockbox exists only as pause identifier, holds no ETH). `CGT + INTEROP` is refused by the
Migrator but reachable by a direct PAO `setFeature`. Nothing is reachable by the SystemConfig owner, the
Guardian or an arbitrary caller (fork-tested, REJ-0603).

Objects in flight: all three flags are read at execution time, never snapshotted in a deposit or a proven
withdrawal. A PAO flip of CGT therefore retroactively blocks every value-bearing withdrawal that was proven
earlier (and unblocks on flip-back); a pause is likewise evaluated at prove, at finalize and at
`unlockETH`. No permissionless actor can cause a flip.

On chain (pre and post, all four chains): `ETH_LOCKBOX=true`, `CUSTOM_GAS_TOKEN=false`, `INTEROP=false`.
The U21 receipt contains **no** `FeatureSet` log.

## 2. Pause resolution after U21

`ETHLockbox.paused()` = `superchainConfig.isLocalOrGlobalPaused(address(this))` (`ETHLockbox.sol:112-114`).

| Contract | v9 resolution | Pointer storage |
|---|---|---|
| OptimismPortal2 6.1.0 | `ethLockbox.paused()` (:306-308) | portal slot 63 |
| SystemConfig 4.3.0 | `portal.ethLockbox().paused()` (:574-576) | via portal |
| AnchorStateRegistry 4.0.0 | `ethLockbox.paused()` (:136-138) | ASR slot 6 off 12 (new) |
| DelayedWETH 2.0.0 | `ethLockbox.paused()` (:102) | slot 5 (new) |
| L1CDM 2.13.0 / L1StandardBridge 2.8.2 / L1ERC721Bridge 2.9.1 | `systemConfig.paused()` | via SystemConfig → portal |
| games (FDG, SuperFDG, ZK) | `anchorStateRegistry().paused()` | via ASR |
| DelayedWETH 1.5.0 (un-upgraded, old games) | `systemConfig.paused()` | via SystemConfig → portal |
| DelayedWETH ≤ 1.3.0 (un-upgraded, pre-U16 games) | `SuperchainConfig.paused()` = **global only** | — (PRIM-0602) |

On chain every pointer of every chain equals that chain's lockbox, and every lockbox's `superchainConfig`
(slot 3, new in v9) is `0x95703e09…` (evidence/lane06/state-post-26433900.txt):

| Chain | Identifier (lockbox) | Portal | ASR.ethLockbox | DelayedWETH.ethLockbox |
|---|---|---|---|---|
| OP 10 | `0x322b47Ff…294D43` | ✓ | ✓ | ✓ (`0x1B6DBF05…`) |
| Ink 57073 | `0xbd4AbB32…325a14` | ✓ | ✓ | ✓ (`0x57b4C29D…`) |
| Soneium 1868 | `0x67B4de6F…622E31` | ✓ | ✓ | ✓ (`0x18fBb58C…`) |
| Unichain 130 | `0x08bA0023…2df5C5` | ✓ | ✓ | ✓ (`0x74ad145a…`) |

- The identifier did **not** change in U21 for these chains: the same lockboxes were already the identifier
  at block 26430858. `pauseTimestamps` = 0 for `address(0)`, all lockboxes, all portals, pre and post
  (REJ-0601).
- CGT chain: identifier is still its (empty) lockbox — the portal cannot be initialised without one.
- Shared lockbox (post-interop): one identifier for every sharer; pausing one pauses all. This is the stated
  design ("superchain cluster identifier"); the Migrator re-points the old ASR and
  `SystemConfig.delayedWETH()` at the shared lockbox (`Migrator.sol:417-430, 545-555`).
- `SuperchainConfig` 2.5.0 vs 2.4.3: only adds the view `isLocalOrGlobalPaused`. `pause/unpause/extend`
  are Guardian-only (non-guardian calls revert on the fork). Expiry 7,884,000 s; `paused(id)` goes false
  silently at expiry; `pause(id)` then reverts `AlreadyPaused` until `unpause`; `extend` re-arms an expired
  pause (PRIM-0603, documented). `paused()` (no arg) = `paused(address(0))` = global only.
- Guardian Safe `0x09f7150D…`: 1 owner (`0xc2819DC7…`), threshold 1, one module = DeputyPauseModule 2.1.0
  (`0x76fC2F97…`, `pause(bytes32,address,bytes)`, same SuperchainConfig). Module → Safe → `pause(lockbox)`
  verified to pause the OP portal on the fork.

Fork tests (all PASS, `test/poc/lane06/PauseMatrix.t.sol`, `FeatureMachine.t.sol`):

| Test | Shows |
|---|---|
| `test_identifier_consistency` | 7 pause getters × 4 chains: lockbox_i pause flips exactly chain i; portal / SystemConfig identifiers flip nothing; global flips all |
| `test_value_paths_under_pause_op` | prove, finalize (both), `unlockETH`, `relayMessage`, `finalizeBridgeETH/ERC20`, `finalizeBridgeERC721`, `DelayedWETH.withdraw`, `claimCredit`, `closeGame`, `setAnchorState` all revert with the pause error; deposits (portal and bridge) and `DelayedWETH.unlock` stay live |
| `test_expiry_semantics` | expiry / re-arm / access control |
| `test_legacy_weth_ignores_identifier_pause` | PRIM-0602 |
| `test_setFeature_access_and_transitions` | REJ-0603, PRIM-0605 (PAO pranks only to document the machine) |
| `test_owner_surface_bounds` | REJ-0604 |
| `test_deputy_module_path` | deputy path reaches the lockbox identifier; cannot re-arm an expired pause |
| `test_gas_of_pause_getters` | REJ-0605 |

What remains live during a pause: value **in** (deposits lock ETH in the lockbox), game moves / resolution,
`DelayedWETH.unlock`, DGF.create, PAO-only functions (`Portal.migrateLiquidity`,
`ETHLockbox.migrateLiquidity`, `authorize*`), and the 0.40 ETH in legacy DelayedWETH proxies. Nothing lets
funds exit the lockbox, the bridges or the current DelayedWETH. Clocks (proof maturity, finality airgap,
DelayedWETH delay, game clocks) keep running during a pause, as before.

## 3. Chain id and resource config

- `l2ChainId` written only in `initialize` (:246, PAO). Portal uses it as the super-root selector
  (`OptimismPortal2.sol:441-445`). On chain 10 / 57073 / 1868 / 130; each chain's latest game extraData
  holds exactly one `(chainId, outputRoot)` tuple with that id.
- All four chains already ran super games before U21 (respected type 9 = SUPER_CANNON_KONA on OP / Ink /
  Unichain, 5 = SUPER_PERMISSIONED on Soneium; `INTEROP` is nevertheless false). `gameArgs(9)` are identical
  across OP / Ink / Unichain apart from ASR and WETH, with `l2ChainId = 0` → PRIM-0606.
- No external resource-config setter; on chain = `DEFAULT_RESOURCE_CONFIG` everywhere; `setGasLimit`
  bounded to [21M, 500M]; `ResourceMetering.sol` unchanged (REJ-0604).

## 4. SystemConfig state of the four chains (post; full dump in evidence)

| | OP | Ink | Soneium | Unichain |
|---|---|---|---|---|
| impl / version / initVersion | `0xade27248…` / 4.3.0 / 3 | same | same | same |
| owner | `0x847B5c17…` | `0x847B5c17…` | `0x509182eC…` | `0x847B5c17…` |
| ProxyAdmin (owner = Safe `0x5a0Aae59…`) | `0x543bA4AA…` | `0xd56045E6…` | `0x89889B56…` | `0x3B73Fa8d…` |
| gasLimit | 40M | 30M | 40M | 60M |
| basefee / blob scalar | 5227 / 1014213 | 4424 / 810831 | 9736 / 1540079 | 2000 / 900000 |
| EIP-1559 denom / elasticity | 250 / 2 | **0 / 0** | 250 / 10 | 250 / 12 |
| minBaseFee | 0 | 0 | 12,000,000 | 500,000 |
| operator fee, DA footprint scalar, overhead | 0 | 0 | 0 | 0 |
| lastUsedOPCM | `0x2d91e6F2…` 9.0.3 (pre: `0x1951828C…` 8.0.1) | same | same | same |
| superchainConfig / guardian | `0x95703e09…` / `0x09f7150D…` | same | same | same |

Only `OPCM_SLOT` changed in SystemConfig storage across U21 (REJ-0606). The one eyebrow-raiser, Ink's
0/0 EIP-1559 params, is the "never set" state (initialize does not write them), unchanged by U21.
The lockboxes keep the legacy `systemConfig` address in the slot-0 spacer (harmless, unread).

## 5. DelayedWETH / ASR instances referenced by games (Enum.t.sol, sampled every 700 games + last 25)

| Chain | DelayedWETH | Version | Pause source | Balance | Game index range |
|---|---|---|---|---|---|
| OP | `0xE497B094…` | 1.0.0 | global only | 0.16 | 0 – ~2100 |
| OP | `0x82511d49…` | 1.1.0 | global only | 0.08 | ~2800 – 4900 |
| OP | `0x323dFC63…` | 1.3.0 | global only | 0.08 | ~5600 – 9800 |
| OP | `0xe214879a…`, `0xD061AB95…` | 1.5.0 | SystemConfig | 0 | ~10500 – 17500 |
| OP | `0x1B6DBF05…` | 2.0.0 | lockbox | 20.66 | ~18200 – 21388 |
| Ink | `0x14773a80…` 1.1.0, `0xf6b1554F…` 1.3.0, `0x6Cbd14DA…` 1.5.0 | — | global / global / SystemConfig | 0 | old |
| Ink | `0x57b4C29D…` | 2.0.0 | lockbox | 5.71 | current |
| Soneium | `0x9AEA1FD8…` 1.3.0, `0x372dC0B8…` + `0x70277624…` 1.5.0 | — | global / SystemConfig | 0 | old |
| Soneium | `0x18fBb58C…` | 2.0.0 | lockbox | 0 | ~7000 – 7700 (type 1); the current type-5 games use no WETH |
| Unichain | `0x7d8Ea656…` 1.1.0, `0xc9edb4E3…` 1.3.0 | — | global only | 0 / 0.08 | old |
| Unichain | `0xa0157F07…`, `0x0bdbEc6b…` | 1.5.0 | SystemConfig | 0 | old |
| Unichain | `0x74ad145a…` | 2.0.0 | lockbox | 21.42 | current |

Sampling caveat: a DelayedWETH used only by games that fall between sample points would be missed.

## 6. Invariants checked

1. Every pause reader of chain C resolves to `SuperchainConfig.{global ∨ lockbox_C}` — holds (fork test).
2. A Guardian pause of lockbox_C blocks every path that moves value out of lockbox / bridges / current
   DelayedWETH of C — holds.
3. Chain isolation of identifiers — holds.
4. No pause was lost or resurrected by U21 — holds (identifier unchanged, timestamps zero).
5. Features only move by ProxyAdmin / PAO; ETH_LOCKBOX and INTEROP are monotone — holds.
6. New v9 storage (lockbox.superchainConfig, ASR.ethLockbox, DelayedWETH.ethLockbox) initialised on every
   upgraded proxy — holds.
7. U21 re-init left derivation-relevant SystemConfig values untouched — holds.

## 7. Open questions / hand-offs

1. PRIM-0606: does the kona-interop program bind the claimed super root's chain set (count, order,
   duplicates, foreign ids) to the anchor's? On L1 nothing does, and `rootClaimByChainId` is first-match.
2. PRIM-0601 at the future interop migration: any v2.0.0 DelayedWETH / ASR proxy other than
   `SystemConfig.delayedWETH()` and `portal.anchorStateRegistry()` would keep the old lockbox as its pause
   identifier. Today there is exactly one of each per chain.
3. Not verified here: chains outside this tx that share SuperchainConfig `0x95703e09…` and will switch
   identifier portal → lockbox when they take v9 (operational, PRIM-0604).
