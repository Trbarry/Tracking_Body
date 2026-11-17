# LANE 09 — Shared Lockbox / Multi-Portal Composition

Result: **no candidate**. Lockbox authorization and cross-portal isolation hold on the live state and in the planned
OP Mainnet + Unichain shared-lockbox migration (executed on a fork with the real deployed OPCM). 4 primitives, 6 rejections.
Blind-first respected (no audits / security-reviews / issue archaeology read).

## 1. ETHLockbox v9 (src/L1/ETHLockbox.sol, 236 lines) — who may call what

| Function | Exact gate | Trust in msg.sender | Reentrancy surface |
|---|---|---|---|
| `initialize(superchainConfig, portals[])` L94 | `reinitializer(1)` + `_assertOnlyProxyAdminOrProxyAdminOwner` | — | calls `_portal.proxyAdminOwner()`, `_portal.systemConfig().superchainConfig()` (owner-supplied portals) |
| `authorizePortal` L124 | `proxyAdminOwner() == msg.sender` | — | same views |
| `_authorizePortal` L220 | same ProxyAdmin OWNER (not same ProxyAdmin) + `ISystemConfig(portal.systemConfig()).superchainConfig() == superchainConfig` | — | — |
| `authorizeLockbox` L184 | owner + shared owner; idempotent; irreversible | — | — |
| `receiveLiquidity` L133 payable | `authorizedLockboxes[msg.sender]` | any amount | none |
| `lockETH` L144 payable | `authorizedPortals[msg.sender]`; NOT pause-gated | any amount | none |
| `unlockETH(v)` L157 | `!paused()` -> `authorizedPortals[msg.sender]` -> `v <= balance` -> `msg.sender.l2Sender() == 0xdEaD` | ANY authorized portal, ANY amount up to the whole balance | `msg.sender.donateETH{value:v}()` (portal code, empty body) |
| `migrateLiquidity(lockbox)` L203 | owner + shared owner; sends whole balance to `lockbox.receiveLiquidity` | — | target must have authorized this lockbox |
| `paused()` L112 | view: `superchainConfig.isLocalOrGlobalPaused(address(this))` | | |

No de-authorization exists for portals or lockboxes. No per-portal accounting: liability == `address(this).balance`.

### v8 (1.3.1) -> v9 (2.0.0) semantic changes (complete)
1. Storage: `systemConfig` (slot0, offset 2) became a private spacer (value left in place on chain); new
   `superchainConfig` appended at slot 3 (set by the U21 re-initialization; slot3 0 -> 0x95703e09… on all four).
2. `initialize(ISystemConfig, portals)` -> `initialize(ISuperchainConfig, portals)`.
3. `paused()`: `systemConfig.paused()` -> `superchainConfig.isLocalOrGlobalPaused(address(this))`: the lockbox is now the
   ROOT of pause resolution (portal.paused, SystemConfig.paused, ASR.paused, DelayedWETH all call the lockbox), instead
   of a consumer of SystemConfig.
4. `superchainConfig()`: derived from SystemConfig -> stored. New `guardian()` passthrough (portal/ASR use it).
5. `_authorizePortal`: compares `portal.systemConfig().superchainConfig()` instead of `portal.superchainConfig()` (which is
   now served by the portal's lockbox and would be circular).
Unchanged: every auth gate, `unlockETH` ordering and l2Sender guard, liquidity migration.
Portal side (5.8.0 -> 6.1.0) relevant to custody: `paused/superchainConfig/guardian` now via lockbox; `migrateLiquidity`
gated by `_isUsingLockbox` instead of interop and refuses CGT; lockbox mandatory (`_assertValidLockboxState`);
messenger withdrawals revert instead of finalizing as failed (`OptimismPortal_L1CDMCallFailed`); `deleteProvenWithdrawal`.
`_isUnsafeTarget` and the single unlock call site are unchanged.

## 2. Live state (fork `l1` @26433900; N-1/N diffs on 8546/8547)

| | OP Mainnet | Ink | Soneium | Unichain |
|---|---|---|---|---|
| lockbox | 0x322b47Ff… | 0xbd4AbB32… | 0x67B4de6F… | 0x08bA0023… |
| balance (ETH) | 182541.068 | 23088.758 | 2195.560 | 18266.158 |
| portal (bal 0, l2Sender 0xdEaD) | 0xbEb5Fc57… | 0x5d66C178… | 0x88e529A6… | 0x0bd48f6B… |
| ProxyAdmin | 0x543bA4AA… | 0xd56045E6… | 0x89889B56… | 0x3B73Fa8d… |
| ProxyAdmin owner | Safe 0x5a0Aae59… (all four) | | | |
| SuperchainConfig | 0x95703e09… v2.5.0, guardian 0x09f7150D… (all four; lockbox slot3 == SystemConfig.superchainConfig) | | | |
| features | ETH_LOCKBOX true, INTEROP false, CGT false, not paused (all four) | | | |

Authorization cross product is diagonal-only; `authorizedLockboxes` empty; Base portal authorized nowhere; full event
history = 16 `PortalAuthorized` (own portal only), no `LockboxAuthorized/LiquidityMigrated/LiquidityReceived` ever
(REJ-0901). Deployed impls == v9 build outside immutables.

## 3. `unlockETH` call context (REJ-0902, REJ-0903)
Only caller: `finalizeWithdrawalTransactionExternalProof` L614, after `checkWithdrawal` and `finalizedWithdrawals=true`,
before `l2Sender = _tx.sender`. The only arbitrary call in the portal (L627) runs with `l2Sender != DEFAULT`. Two guards
against "withdrawal targets the lockbox": `_isUnsafeTarget = {portal, portal.ethLockbox}` at prove and finalize, and the
lockbox's l2Sender check. Every `msg.sender == portal`-style check in v9 src/ is keyed on one exact stored address
(lockbox mappings, L1CDM `portal`), so portal A never passes for chain B — today or in a shared set.

## 4. Planned migration, modelled concretely: OP Mainnet (10) + Unichain (130)
Executed on the fork as the Safe DELEGATECALLing the deployed `OPContractsManagerV2.migrate` (setup of a planned,
documented governance action; no other privileged prank). It runs on today's state.
Per chain, in order (Migrator L266-272, L475-556): re-init chain DelayedWETH with shared lockbox -> `systemConfig.paused()`
check (old identifier) -> `shared.authorizePortal(portal)` -> `setFeature(INTEROP)` -> portal re-init with (oldASR,
sharedLockbox) -> `portal.migrateLiquidity()` -> `shared.authorizeLockbox(old)`; `old.migrateLiquidity(shared)` -> clear old
DGF impls -> `portal.migrateToSharedDisputeGame(shared, newASR)` -> re-init old ASR with shared lockbox -> re-init
SystemConfig with chain-0's DelayedWETH. No call leaves the trusted set (trace saved).
Measured post-state: shared lockbox 0x8cc1eE88… (on the test's timestamp) = 200807.226200523469952640 ETH = exact sum;
old lockboxes 0 ETH but still `authorizedPortals[own portal] = true`; shared has both portals + both old lockboxes
authorized; shared contracts under OP's ProxyAdmin; both SystemConfigs -> OP DelayedWETH and shared DGF.

Invariants checked (all hold):
- I1 conservation: Σ old balances + donations == shared balance; no accounting variable can desync.
- I2 no non-owner can add an authorization or move liquidity, before, during (atomic, no untrusted call) or after.
- I3 a portal can make a lockbox release ETH only for a withdrawal that passed its own ASR (`checkWithdrawal`).
- I4 pre-migration proofs / games are dead for the shared ASR (REJ-0905).
- I5 re-migration impossible; CGT chains refused (REJ-0904).
Weakened (documented or benign): per-chain solvency -> pooled (by design); "authorized lockbox ⊆ unsafe targets"
(PRIM-0901); validator zero-balance equalities (PRIM-0902); pause blast radius and orphaned legacy escrow (PRIM-0904).

## 5. Tests (harness /home/user/u21-work/lane09, copies in test/poc/lane09/)
Lane09Migrate (real migration), Lane09PostMigration (6 post-migration probes + 2 present-state isolation tests, the
latter with no mocks), Lane09Remigrate (unprivileged / re-migration / donation sweep), Lane09OldProofs. 13/13 pass
(evidence/lane09-forge-results.txt). Where a withdrawal is injected post-migration, proof validity is mocked
(vm.store + vm.mockCall); those tests locate behaviour of real portal/lockbox code and claim no proof bypass.

## 6. Open questions / not verified
- L2-side backing: whether each chain's L2 ETH supply <= its L1 lockbox balance before pooling (unbacked supply on one
  chain becomes a claim on the other's collateral). Needs L2 state accounting.
- PRIM-0903: how the kona-interop program treats non-canonical super-root preimages (duplicate / foreign chain ids);
  on L1 `rootClaimByChainId` is first-match and all chains share prestate + impl with l2ChainId=0.
- Event history completeness rests on a single public RPC response.
