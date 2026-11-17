# Lane 32 report — Negative-space and omitted-check analysis

## Executive result

Independent v8→v9 source/ABI review, exact block 26430858→26430859 storage comparison, bounded block-N→26433900 reads, and nine fork tests found **no permissionless, production-reachable eligible vulnerability**. No `CAND-32xx` file was created.

Three reusable primitives remain: validator-only zero-balance assertions are permissionlessly unstable (PRIM-3201); the deployed L1/L2 messenger gas budgets are deliberately asymmetric during the mixed-version rollout (PRIM-3202); and historical withdrawal proofs are judged through the portal's mutable current registry (PRIM-3203). Each was reproduced or bounded against deployed bytecode, then killed as a present-impact candidate.

## Scope, method, and safety

- Target: `op-contracts/v9.0.0` commit `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`; baseline: v8 commit `f45a5ccfebcdf6da3f5b09cbc512667c063730b7`.
- Compared all files under `src/{L1,dispute,universal,libraries,legacy,safe}` and all `interfaces/`, using tree diffs because the tag checkouts are shallow.
- Mainnet reads used local passive forks only: N−1 `:8546`, N `:8547`, later L1 `:8545`, and OP Mainnet L2 `:9545`.
- Mutating calls occurred only inside `forge test` forks. No public-network transaction, impersonated live write, or state-changing RPC method was used.
- Short source references below are relative to `packages/contracts-bedrock/src/` in the stated tag. `v9:` is the target; `v8:` is the baseline.

## Complete changed-file classification

| Area | Semantic security/check changes | Diff-only, no check semantic change |
|---|---|---|
| `L1/` | `ETHLockbox`, `L1CrossDomainMessenger`, `OPContractsManagerStandardValidator`, `OptimismPortal2`, `SuperchainConfig`, `SystemConfig`; every `L1/opcm/*` file listed below | `DataAvailabilityChallenge`, `L1ERC721Bridge`, `L1StandardBridge` (format only) |
| `L1/opcm/` | `OPContractsManagerMigrationValidator`, `OPContractsManagerMigrator`, `OPContractsManagerUtils`, `OPContractsManagerUtilsCaller`, `OPContractsManagerV2`, `StandardValidatorUtils` | none |
| `dispute/` | `AnchorStateRegistry`, `DelayedWETH`, `lib/Types` (central cleared-type list), `zk/ZKDisputeGame` | `DisputeGameFactory`, `FaultDisputeGame`, `SuperPermissionedDisputeGame`, `lib/{LibGameArgs,LibPosition,LibUDT}` (format/import cleanup) |
| `universal/` | `CrossDomainMessenger` | `ProxyAdmin`, `ProxyAdminOwnedBase` (format only) |
| `libraries/` | new `GasConstants`, `SafeCall`; `Constants`, `DevFeatures`, `Features` comments describe the new policy | `Burn` (future-fork TODO), `GasPayingToken`, `Predeploys`, `rlp/RLPReader` (comments/format only) |
| `legacy/`, `safe/` | none | `LegacyMintableERC20`, `LivenessModule` (format only) |

This classification was made from the complete directory diff, not only the receipt-touched implementations. Unchanged requires/reverts were not duplicated in the changed-check matrix; any changed resolver that alters what such an unchanged guard reads is included.

## Complete interface declaration diff

The table includes every added/removed/changed `error`, `event`, and `function` declaration in the requested `interfaces/` tree. `~` means remove+add with the new signature. `IOPContractsManagerMigrationValidator` changed struct schemas only and has no declaration in these categories.

| Interface | Added | Removed / changed |
|---|---|---|
| `L1/IETHLockbox` | `guardian()`; `initialize(ISuperchainConfig,IOptimismPortal2[])` (~) | `systemConfig()`; `initialize(ISystemConfig,IOptimismPortal2[])` (~) |
| `L1/IOptimismPortal2` | errors `OptimismPortal_L1CDMCallFailed`, `OptimismPortal_NotUsingLockbox`, `OptimismPortal_DisputeGameNotInvalidated`; event `WithdrawalProofDeleted`; function `deleteProvenWithdrawal(bytes32,address)` | none |
| `L1/ISuperchainConfig` | `isLocalOrGlobalPaused(address)` | none |
| `L1/opcm/IOPContractsManagerMigrator` | errors `ChainAlreadyMigrated`, `SuperchainConfigNeedsUpgrade`, `InvalidInitBond`, `InvalidAbsolutePrestate`, `InvalidZKDisputeGameConfig`, `InvalidGameType`, `DisputeGameNotEnabled`, `InvalidStartingAnchorRoot`, `SemverComp_InvalidSemverParts` | errors `InteropNotEnabled`, `NotSharedInteropSet`, `RespectedGameTypeNotRegistered`; function `setInteropDisputeGames(MigrateInput)` |
| `L1/opcm/IOPContractsManagerUtils` | `isPermittedUpgradeSequence(ISystemConfig,address)`, `isPermittedMigrateSequence(ISystemConfig,address)` | `systemConfigFor(ISystemConfig,address)` |
| `L1/opcm/IOPContractsManagerV2` | `isPermittedMigrateSequence(ISystemConfig)`; `upgradeSuperchain` data location memory→calldata (ABI-equivalent ~) | `setInteropDisputeGames(MigrateInput)` |
| `L1/opcm/IOPContractsManagerMigrationValidator` | no added declaration in these categories; migration input/config structs expanded | no removed declaration in these categories |
| `dispute/IAnchorStateRegistry` | `ethLockbox()` | `systemConfig()` |
| `dispute/IDelayedWETH` | `ethLockbox()`; `initialize(IETHLockbox)` (~) | `systemConfig()`; `initialize(ISystemConfig)` (~) |
| `vendor/ISP1Verifier` | `VERIFIER_HASH()` | none |

No other interface file differs.

## Exact N−1→N deployed-state boundary

The upgrade receipt touched 33 proxies: shared SuperchainConfig plus eight proxies on each of OP, Ink, Soneium, and Unichain. Every proxy emitted an intermediate StorageSetter upgrade and a restoration/final upgrade, so logs alone overcount final implementation changes. The full address map is in `mirror/lane-32/U21_PROXY_IMPLEMENTATION_MAP.md`.

| Class | N−1 implementation | N implementation | Linear-state delta at N |
|---|---|---|---|
| SuperchainConfig | `0x5570b1f2…` | `0xa303a644…` | none in selected layout |
| SystemConfig (×4) | `0x670b850a…` | `0xade27248…` | none in selected layout |
| Portal (×4) | `0x1005217a…` | `0xb20b23af…` | OP resource-metering slot advanced; no pointer change |
| ETHLockbox (×4) | `0xb3a24db0…` | `0xdf75e6b0…` | slot 3: zero → shared SuperchainConfig |
| DelayedWETH (×4) | `0xe440cc08…` | `0xf024e963…` | slot 5: zero → exact chain lockbox |
| AnchorStateRegistry (×4) | `0x8f40cc98…` | `0x2b27299c…` | slot 6 gains exact lockbox; retirement timestamp/type retained |
| L1ERC721Bridge, MintableFactory, DGF (×4 each) | existing | same existing | no selected linear delta; StorageSetter hop only |

`StateDiff.t.sol::test_exactNMinus1ToNLinearStorageDiff` passed and asserted all 33 EIP-1967 admin slots unchanged. Getter-level state at N/later confirms `ETH_LOCKBOX=true`, `INTEROP=false`, exact portal authorization, and a common `0x95703e…` SuperchainConfig on all four chains.

## N→26433900 bounded state

Exact values are saved in `mirror/lane-32/N_TO_LATER_STATE.md`. Portal balances stayed zero. OP and Unichain lockbox balances increased; Ink/Soneium were unchanged. DGF counts advanced 11/1/4/10 games, DelayedWETH changed only on OP (+0.08 ETH), and every current anchor game advanced. Implementations and checked configuration pointers did not change. These are ordinary operational deltas, not a corrective U21 mutation.

## Changed runtime and upgrade checks

Each row explicitly covers the requested negative-space questions. “Sibling/alternate” answers whether another operation skips the check. “Order/object” says whether it executes before mutation/call and whether the validated object is the one used. “Temporal/upgrade result” distinguishes current configuration from snapshotted historical state and states whether an upgrade/migration can bypass it.

| ID | Added/removed/moved check and why | Sibling / alternate operation | Order / exact object | Temporal / upgrade result |
|---|---|---|---|---|
| R01 | Lockbox pause moved from `systemConfig.paused()` (`v8:L1/ETHLockbox.sol:111-112`) to `superchainConfig.isLocalOrGlobalPaused(this)` (`v9:…:112-114`) so a shared lockbox has its own pause identifier. | `lockETH`, `receiveLiquidity`, and donation accept inbound value while paused; only `unlockETH` is pause-gated. Portal/ASR/WETH now resolve through their exact lockbox. | Read before balance/auth checks and before ETH transfer in `unlockETH`; object is current lockbox address. | Reads mutable current SuperchainConfig, intentionally not historical. Migration rebinds old WETH/ASR to the new lockbox; fork bindings were exact. No outbound bypass found. |
| R02 | Portal pause moved from SystemConfig (`v8:L1/OptimismPortal2.sol:291-292`) to current `ethLockbox.paused()` (`v9:…:305-307`) to eliminate feature-selected recursion/ambiguity. | `donateETH` and deposits are intentionally not pause-gated; proof/finalize/migration checks use `_assertNotPaused`. Bridges/messenger still call SystemConfig, which delegates to this lockbox. | Finalize checks before state mutation/external call; deposit does not. Validated lockbox is the one later unlocked. | Mutable current lockbox judges historical proofs (PRIM-3203). Only authorized migration/upgrade can switch it. |
| R02a | Portal `superchainConfig()` and `guardian()` authorization sources likewise moved SystemConfig→current lockbox (`v8:OptimismPortal2.sol:306-317`; `v9:…:321-337`) so shared historical components resolve one governance domain. | ASR now reads guardian through its exact lockbox; ETHLockbox portal authorization deliberately reads portal **SystemConfig** instead, avoiding a self-referential check after pointer swap (R05). | View resolution occurs when the consuming guard runs; exact current lockbox. | An authorized lockbox migration changes current guardian/SC for historical games, intentionally and atomically; no permissionless pointer change. |
| R03 | SystemConfig pause resolver changed from feature-selected portal/lockbox plus global (`v8:L1/SystemConfig.sol:581-588`) to exact portal lockbox (`v9:…:570-575`). | L1 messenger/bridges delegate to this resolver; direct lockbox calls use the same lockbox resolver. | View-only; typed call fails if no lockbox, which is why v9 makes lockbox mandatory. | Current pointer/config; v9 upgrade initializes lockbox before dependent paths. No alternate unpaused withdrawal path found. |
| R04 | Added `isLocalOrGlobalPaused(identifier)` (`v9:L1/SuperchainConfig.sol:149-154`) because `paused(identifier)` itself excludes the global identifier. | Legacy zero-argument `paused()` remains global-only; v9 lockbox explicitly uses the combined helper. | Pure view before any lockbox unlock. Exact identifier supplied by lockbox. | Mutable current pause. A sibling calling only `paused(identifier)` could omit global, but audited consumers either combine or use lockbox; no affected path found. |
| R05 | Portal authorization's same-superchain check now reads `portal.systemConfig().superchainConfig()` instead of `portal.superchainConfig()` (`v8:L1/ETHLockbox.sol:217-223`; `v9:…:220-228`) to avoid comparing the lockbox to itself after pointer installation. | `authorizeLockbox` checks shared ProxyAdmin owner, not SuperchainConfig (`v9:184-192`); `receiveLiquidity` then trusts that list. | Same-config check precedes `authorizedPortals=true`; it validates the portal later authorized. | Current SystemConfig. A governance upgrade can rebind config after authorization, but that actor controls both proxies; no permissionless mutation. |
| R06 | ASR initializer/pause/guardian dependency moved SystemConfig→ETHLockbox (`v9:dispute/AnchorStateRegistry.sol:94-107,135-143,374-378`) so old games follow the migrated shared pause authority. | Fault/Super/Permissioned games all consume their ASR; ZK also does. No game-specific bypass. | Binding is written during reinitializer before later use; guardian check occurs before blacklist/type mutation. | Current lockbox judges historical games. Migrator explicitly upgrades old ASR after portal migration (`v9:L1/opcm/OPContractsManagerMigrator.sol:545-555`). Privileged temporal coupling only. |
| R07 | DelayedWETH initializer/pause source moved SystemConfig→ETHLockbox (`v9:dispute/DelayedWETH.sol:58-75,99-106`) for historical game pause continuity. | `recover`/`hold` remain owner-only; normal withdrawal is pause-gated. All game siblings use their configured WETH. | Pause and withdrawal-record checks precede amount mutation and ETH call. Exact bound lockbox is used. | Current lockbox controls old withdrawals. Migrator upgrades old WETH before portal mutation (`v9:OPContractsManagerMigrator.sol:265-271,417-429`). |
| R08 | ETH_LOCKBOX disabling tightened from “reject only if a portal pointer is nonzero” (`v8:L1/SystemConfig.sol:549-557`) to unconditional rejection (`v9:…:543-547`) because v9 requires lockbox use. | No equivalent flag-clearing operation; storage can change only by an upgrade/StorageSetter under governance. | Authorization/no-op checks run first; rejection precedes mapping mutation. | Current flag, not historical. Upgrade can overwrite by privilege; direct fork call from attacker reverted. |
| R09 | ETH_LOCKBOX transition pause check changed from `paused()` (`v8:…:560-565`) to the old portal identifier only (`v9:…:549-554`), preventing enablement from hiding an active portal-local pause without recursively requiring a configured lockbox. | No sibling feature-enablement path. Global pause is not checked here, but remains active after identifier switch via the lockbox's combined resolver. | Before flag mutation; validates the old identifier that would otherwise be abandoned. | Current pause. Upgrade path can initialize atomically; privileged only. |
| R10 | Added irreversible INTEROP check (`v9:L1/SystemConfig.sol:557-560`) because migrator uses it as a durable “already migrated” marker. | No alternate setter besides privileged storage upgrade. | Before mapping mutation. Exact INTEROP flag used later by portal/migrator. | Current durable state; combined with migrator's precheck. Fork state is false on all four chains. |
| R11 | `Portal.migrateLiquidity` gate changed INTEROP→active lockbox (`v8:L1/OptimismPortal2.sol:486-494`; `v9:…:500-512`) so standard v9 upgrades can move portal ETH before interop. | Old-lockbox `migrateLiquidity` is a separate ProxyAdmin-owner path; `donateETH` can add new portal ETH afterward but cannot extract it. | Gate and ProxyAdmin-owner check precede balance read and exact current-lockbox call. | Current feature/pointer. v9 OPCM invokes only if portal was not already using a lockbox and chain is not CGT. No attacker bypass. |
| R12 | Added custom-gas-token rejection to portal liquidity migration (`v9:OptimismPortal2.sol:507`) to prevent pooling non-ETH accounting. | OPCM also skips this call for CGT (`v9:OPContractsManagerV2.sol:894-897`); old-lockbox migration is unreachable in supported CGT setup. | Before balance read/external call. Exact current SystemConfig mode. | Current config; only privileged config changes. |
| R13 | Added failed-L1CDM-call revert (`v9:OptimismPortal2.sol:639-653`; absent after `v8:609-630`) so a failed messenger withdrawal stays unfinalized/retryable. | Non-messenger withdrawals preserve success=false finalization and refund; `finalizeWithdrawalTransaction` delegates to the same external-proof path. | Check is after portal mutation, unlock, and external call, but revert atomically rolls all back. It keys the exact stored withdrawal sender. | Historical sender plus current target execution. Upgrade cannot leave partial state; REJ-3201. |
| R14 | Added proof-deletion “must be proven” check (`v9:OptimismPortal2.sol:711-715`) to make permissionless cleanup safe. | Re-proving overwrites the caller's proof slot through the normal proof path; finalization uses the same proof entry. | Before game calls and delete; exact `(hash,submitter)` entry. | Historical timestamp, no config dependence. No migration bypass. |
| R15 | Added deletion invalidation check: game must have CHALLENGER_WINS or be blacklisted (`v9:…:717-725`). | Finalization instead calls `currentASR.isGameClaimValid`; both operate on the stored exact game, but through current ASR policy. | Before deletion; external view calls only. | Historical game/current registry coupling is PRIM-3203. A real live proof reverted, REJ-3202. Authorized migration can deliberately invalidate and users re-prove. |
| R16 | Lockbox-state invariant changed from feature/pointer symmetry (`v8:OptimismPortal2.sol:782-788`) to mandatory feature **and** nonzero pointer (`v9:…:839-842`). | All portal initializers call it; OPCM now always loads/upgrades a lockbox. No legacy no-lockbox initialization sibling remains in v9. | Initialization check runs after fields are assigned, but a revert rolls the reinitializer back. Validates exact stored pointer. | Current feature. Upgrade/migration must satisfy it atomically; block-N storage confirms this on four chains. |
| R17 | ZK initialization now snapshots respected status before parent validation and rejects a respected child over an unrespected parent (`v9:dispute/zk/ZKDisputeGame.sol:342-365`; snapshot was after parent work at `v8:402-404`). | Fault, permissioned, super-permissioned games do not use this ZK parent graph; no alternate ZK initializer. | Before WETH deposit and final initialization; exact parent comes from the creating DGF index. | Parent's historical snapshot, not current type. Upgrade cannot change clone storage. Type 10 is unregistered on all four chains; REJ-3207. |
| R18 | `SafeCall.callWithMinGas` adds 183,600 gas for value to `codehash==0` targets (`v9:libraries/SafeCall.sol:9,120-131`; absent `v8:116-126`) in preparation for Amsterdam new-account state gas. | Direct `SafeCall.call` does not add this floor; Portal finalization specifically uses `callWithMinGas`. Messenger target relay uses its own gas guard then `SafeCall.call`. | Codehash is read for the exact target immediately before the call; failure is a pre-call revert. | Current account existence; CREATE in the same tx can change it before finalization. Under today's fork it only over-reserves; future semantics not locally reproducible, REJ-3206. |
| R19 | Messenger's fixed relay gas check/call budget (`v8:universal/CrossDomainMessenger.sol:272-298`) moved to chain-local virtual values (`v9:…:259-285`); public/baseGas getters represent the remote chain (`v9:L1/L1CrossDomainMessenger.sol:43-74,117-152`). | L1 and L2 implementations override opposite local/remote values; portal still forwards all remaining gas. | Guard is before target call; call subtracts exact local reserve. Message replay state is written only on success. | Mixed current implementations produce PRIM-3202. A future upgrade changes semantics but failed L2-messenger withdrawals remain retryable. |

### OPCM / migration check changes

| ID | Added/removed/moved check and why | Sibling / alternate operation | Order / exact object | Temporal / upgrade result |
|---|---|---|---|---|
| R20 | Removed `OPTIMISM_PORTAL_INTEROP` dev-feature gate from `migrate` (`v8:L1/opcm/OPContractsManagerMigrator.sol:113-119`) because v9 makes production migration an explicit release operation. | Standard `upgrade` cannot set INTEROP/shared contracts; the meaningful entry is `OPContractsManagerV2.migrate`, which is delegatecall-only. | Old check was first; replacement sequence/config checks all precede mutation. | Current dev bitmap no longer blocks migration. Authority remains the ProxyAdmin/OPCM execution context; not permissionless. |
| R21 | Removed the separate `setInteropDisputeGames` dev-feature check and whole function (`v8:OPContractsManagerMigrator.sol:283-292`, `v8:OPContractsManagerV2.sol:303-311`). | v9 has no sibling for re-pointing an already-migrated set; only one-shot `migrate` remains. | Old check preceded mutation. | An upgrade is now required to re-point shared games. This narrows, rather than opens, a bypass. |
| R21a | Removed `setInteropDisputeGames` nonempty-chain check (`v8:OPContractsManagerMigrator.sol:284-287`) with the function. | One-shot `migrate` retains its own `NoChains` check (`v9:130-133`). | Old check was first and guarded the chain-0 dereference. | There is no v9 existing-set re-point operation to call with an empty list. |
| R21b | Removed `setInteropDisputeGames` ZK dev-feature gate (`v8:…:292-295`) with the function. | One-shot migration applies the ZK gate per supplied config (`v9:389-395`). | Old check preceded ASR/DGF mutation and applied to the whole ZK-transition operation. | Re-pointing now requires replacement code; no unchecked sibling remains. |
| R21c | Removed `setInteropDisputeGames` generic super-type check (`v8:…:297-300`) with the function. | One-shot migration uses the narrower allowed starting types plus per-config super-game check (`v9:135-142,369-373`). | New checks are before deployment and validate exact ASR/config values. | Existing-set swaps are upgrade-only. |
| R21d | Removed that function's call to the common owner/SC/chain-ID validator (`v8:…:302-305`) with the function. | One-shot `migrate` retains the same call (`v9:152-155`) and adds the already-migrated rejection. | Before all mutations in both versions; exact supplied chain list. | No v9 path performs the removed existing-set operation. |
| R22 | Removed `setInteropDisputeGames` “all chains already share this DGF” check (`v8:OPContractsManagerMigrator.sol:310-320`) with that function. | One-shot v9 migration derives/deploys the shared DGF and validates all members instead. | Old check inspected each exact current factory before writes. | No replacement path for an existing set; upgrade-only. |
| R23 | Removed post-swap “respected game registered” check (`v8:OPContractsManagerMigrator.sol:344-353`) with `setInteropDisputeGames`. | v9 `migrate` validates the starting type is present before deployment (`v9:339-357`) and registers every validated config. | New check is before mutations, stronger than the old post-write check for the supported path. | No existing-set sibling. Privileged upgrade needed for later game swaps. |
| R24 | Added nonzero starting anchor root and `sequence < uint64.max` (`v9:OPContractsManagerMigrator.sol:144-150`) so the shared ASR is usable and can advance. | OPCMv2 deploy/upgrade has the analogous initial-deploy check; portal proof cannot repair a bad anchor. | Before proxy deployment; exact proposal passed to ASR initializer. | Calldata is snapshotted, not derived from current legacy anchors. A privileged caller can choose a stale but nonzero anchor; see composition C3, no permissionless exploit found. |
| R25 | Added SuperchainConfig minimum-version check (`v9:OPContractsManagerMigrator.sol:157-162`). | `OPContractsManagerV2._apply` performs the same check on standard upgrade (`v9:817-820`). | Before deployment/mutation; all member chains were already required to name the same exact SC. | Reads current version; implementation can later upgrade. Prevents migration against older semantics. |
| R26 | Existing ProxyAdmin **owner** equality is retained (`v8:364-366`; `v9:OPContractsManagerMigrator.sol:291-298`) and now feeds the production migration after the dev gate was removed. | Individual ProxyAdmins may differ; portal/lockbox admin checks use each actual chain admin. No separate member-add path. | Before deployment; compares every exact supplied SystemConfig's PA owner. | Current owners, not snapshotted. Governance could change ownership before execution, causing revert, not bypass. |
| R27 | Existing exact shared SuperchainConfig equality is retained (`v8:368-371`; `v9:300-303`) while the shared lockbox's initializer now stores that SC directly. | Lockbox authorization independently checks a portal's SystemConfig→SC. | Before deployment and authorization; same object initializes shared lockbox. | Current pointers. A later privileged rebind could diverge; validator detects it. |
| R28 | Added `INTEROP`-already-enabled rejection (`v9:OPContractsManagerMigrator.sol:305-311`) to prevent draining/re-clearing an existing shared set. | No `setInteropDisputeGames` sibling in v9; SystemConfig cannot clear INTEROP (R10). | Before all mutation; exact feature on every supplied chain. | Durable current marker. Direct portal migration also requires INTEROP but remains PA-owner-only; no re-migrate bypass. |
| R29 | Existing zero L2 chain-ID rejection is retained (`v8:373-380`; `v9:313-320`) because super-root proofs key per chain. | Standard upgrade preserves each SystemConfig's configured ID; no portal override. | Before deployment; exact IDs later encoded into games/portal proof selection. | Current values. Privileged SystemConfig upgrade is only bypass. |
| R30 | Existing duplicate L2 chain-ID rejection is retained (`v8:381-382`; `v9:321-322`). | No member alias/add path. | Before mutation; adjacent comparison is complete because R31 enforces sorting. | Current list and current IDs; reordered duplicates still fail. |
| R31 | Existing ascending-order rejection is retained (`v8:383-384`; `v9:323-325`) to make the adjacent duplicate test complete/deterministic. | No sibling unsorted ingestion. | Before mutation; validates exact calldata order used by the loop. | Calldata-only, unaffected by later config changes in the atomic tx. |
| R32 | Added starting respected type must appear in supplied configs (`v9:OPContractsManagerMigrator.sol:346-357`). | ASR cannot synthesize an implementation; DGF register loop is the only sibling. | Before proxy deployment; matches raw type later written to ASR and registered. | Calldata consistency, not current state. Upgrade cannot bypass without replacing code. |
| R33 | Added “migration config must be a super game” (`v9:OPContractsManagerMigrator.sol:367-373`) because migration uses l2ChainId 0/shared roots. | OPCMv2 standard config still supports L1 output-root game types on non-migrated chains. | Before deployment; same exact config is later encoded. | Calldata-only. No alternative registration in `migrate`. |
| R34 | Added “every supplied migration config enabled” (`v9:OPContractsManagerMigrator.sol:375-378`) because every entry is registered. | Standard OPCM accepts disabled fixed-list entries; migration's variable list intentionally does not. | Before deployment/registration; exact entry. | Calldata-only; no later bypass in the atomic call. |
| R35 | Added SUPER_PERMISSIONED bond must equal zero (`v9:OPContractsManagerMigrator.sol:380-384`). | Standard OPCM has the same type-specific rule. | Before DGF writes; exact type/bond pair. | Calldata-only. Validator also checks expected final bond. |
| R36 | Added every other migration game bond must be nonzero (`v9:OPContractsManagerMigrator.sol:385-387`) to prevent free permissionless game spam. | SUPER_PERMISSIONED is the explicit sibling exception; Soneium type 5 zero bond is not a migrated permissionless super game. | Before DGF writes; exact pair later used. | Calldata-only; DGF owner could change later by privilege. |
| R37 | Added ZK dev-feature gate (`v9:OPContractsManagerMigrator.sol:389-395`). | Standard OPCM has the same gate; non-ZK configs skip it. | Before deployment/registration; exact current container bitmap. | Current deployment policy, not historical. A later OPCM upgrade can enable it. |
| R38 | Added nonzero absolute prestate for permissionless super fault games (`v9:OPContractsManagerMigrator.sol:397-403`). | Permissioned game is the deliberate sibling exception; standard OPCM validates its permissionless configs too. | Before registration; validates the bytes decoded and later encoded into the same game args. | Calldata-only. No another-contract bypass during migration. |
| R39 | Added full ZK args validation (nonzero prestate, nonzero/bounded durations, nonzero challenger bond) (`v9:OPContractsManagerMigrator.sol:404-408`, helper in `OPContractsManagerUtils.sol`). | Standard OPCM and StandardValidator repeat equivalent checks; other game families use their own config checks. | Before deployment/registration; exact bytes later used. | Calldata-only; later DGF-owner mutation is privileged and validator-detectable. |
| R40 | Replaced migration's broad “permit all proxy deployments” with exactly ETHLockbox, DGF, ASR (`v9:OPContractsManagerMigrator.sol:178-189`; v8 used the `ALL` instruction). | Initial deployment still permits all; standard v9 upgrades permit only exact ETHLockbox as an extra. | Permit list is constructed before `_loadOrDeployProxy`; names match the exact three calls. | Atomic calldata/internal list; no permissionless bypass. This closes negative space. |
| R41 | CGT migration rejection retained but now sits in the production path (`v9:OPContractsManagerMigrator.sol:483-486`), preventing pooled ETH semantics on token-gas chains. | Standard v9 upgrade skips only portal liquidity migration for CGT; it can still install lockbox infrastructure. | Before portal pointer/feature mutation; exact SystemConfig. | Current config. Privileged config upgrade could change mode, but no attacker setter. |
| R42 | Pause check now relies on the v9 exact-lockbox resolver and is explicitly before pointer mutation (`v9:OPContractsManagerMigrator.sol:494-500`; old check `v8:467-472`). | Portal migration also checks pause, but after INTEROP is enabled; checking here preserves the old identifier. | Before authorization, feature flags, and portal reinitializer; validates the currently active lockbox/portal identifier. | Current pause for historical system. Prevents migration hiding an old local pause. |
| R43 | INTEROP enabling changed from conditional to unconditional after R28 proves it false (`v9:OPContractsManagerMigrator.sol:505-513`; conditional in v8). | ETH_LOCKBOX remains conditional because a chain may already use a per-chain lockbox. | Precheck before any mutation guarantees `setFeature(true)` is not a no-op; occurs before portal pointer swap. | Exact same current flag. Atomic rollback on any later failure. |
| R44 | Clearing old DGF implementations moved to centralized `clearedGameTypes`, adding ZK type 10 (`v9:dispute/lib/Types.sol:96-113`; use at `OPContractsManagerMigrator.sol:536-540`). | No other old-factory registration path in migration; shared DGF is separately populated. | Clearing occurs after liquidity moves but before portal ASR swap; exact existing DGF. Atomic transaction prevents partial state. | Current registry contents, including historical types. Later owner re-registration is privileged. |
| R45 | Added per-chain permitted-migrate-sequence check in OPCMv2 (`v9:OPContractsManagerV2.sol:293-303`) so every chain is already on this release; unlike upgrade it rejects next-major jumps (`OPContractsManagerUtils.sol:571-582`). | Standard `upgrade` uses its distinct sequential-upgrade helper (`:536-564`). | Before delegatecall and all migrator mutation; exact `lastUsedOPCM`/version for every supplied SystemConfig. | Current historical upgrade marker. Same OPCM or same-major-at-least-minor only; no list member skips the loop. |
| R46 | Upgrade-instruction allowance changed from starting-anchor override in pre-v9 dev migration to exact ETHLockbox proxy deployment only while major==9 (`v8:OPContractsManagerV2.sol:359-366`; `v9:347-375`). | Initial deployment's internal permit-all remains; migration has its own exact three-name list. | Instruction validation precedes load/deploy; exact key+data consumed. | Current OPCM version self-expiring by major. No arbitrary proxy deployment through this allowance. |
| R47 | Added ZK config structural check to standard deploy/upgrade (`v9:OPContractsManagerV2.sol:772-779`), supplementing the existing ZK feature/bond checks. | Migrator and validator repeat it; non-ZK games have their own prestate rules. | Before `_apply` and DGF mutation; exact config bytes later registered. | Calldata-only; privileged later mutation remains possible. |
| R48 | Standard upgrade changed lockbox from optional/feature-dependent to mandatory nonzero (`v9:OPContractsManagerV2.sol:456-470,860-897`; old conditional at `v8:461-485,860-889`). | CGT only skips the liquidity move, not binding/initialization. Portal, ASR, and WETH all receive the exact loaded lockbox. | Nonzero check and feature enablement precede portal initialization; lockbox is initialized before conditional migration call completes. All atomic. | Current pre-upgrade feature/pointer is snapshotted in `wasUsingEthLockbox`; exact object later used. N-state confirms all four bindings. |
| R49 | Removed `systemConfigFor`'s try/catch/fallback (`v8:OPContractsManagerUtils.sol:404-424`) and directly binds lockbox/ASR/WETH through exact SuperchainConfig/ETHLockbox (`v9:OPContractsManagerV2.sol:884-897,944-962`). | No fallback sibling remains; migration explicitly preserves shared bindings for historical contracts. | Typed reads/writes fail loud before completing upgrade rather than silently select caller default. | Eliminates mutable-current-config ambiguity and swallowed call failures. Any bypass requires privileged replacement code. |

## StandardValidator-only changed checks

These functions are read-only postcondition checks: they run **after** upgrade mutation, make no protected external call, and do not themselves constrain on-chain state. Thus every row can be bypassed by an upgrade workflow that simply does not invoke the validator. The concrete question is whether a permissionless actor can violate the condition after a successful validation; that answer is given per row. Runtime/OPCM enforcement, where present, is the sibling path.

| ID | Validator check (v9 line; v8 replacement where relevant) and reason | Sibling/runtime, exact object, and post-validation mutability |
|---|---|---|
| V01 | `LOCKBOX-00`: ETH_LOCKBOX must be enabled (`L1/OPContractsManagerStandardValidator.sol:444-446`); v8 skipped the entire lockbox validator when false (`v8:444-446`). | Runtime Portal initializer now requires the same flag (R16) and SystemConfig cannot disable it (R08). Exact chain SystemConfig; attacker setter reverted on fork. |
| V02 | `LOCKBOX-05`: portal lockbox must be nonzero (`:446-449`) to avoid later validator calls reverting and to make custody usable. | OPCMv2 rejects zero and Portal initializer checks it. Exact current portal pointer; only upgrade authority can change it. |
| V03 | `LOCKBOX-10`: version check is no longer skippable via a false feature (`:451-453`). | OPCM selects implementation; no runtime version guard. Exact current proxy; only ProxyAdmin can upgrade. |
| V04 | `LOCKBOX-20`: exact implementation is no longer skippable (`:454-455`). | ProxyAdmin `_upgrade` writes it. Exact EIP-1967 implementation; privileged mutable only. |
| V05 | `LOCKBOX-30`: exact shared/chain ProxyAdmin is no longer skippable (`:456`). | Proxy itself enforces admin; no permissionless admin-slot write. Exact lockbox proxy. |
| V06 | `LOCKBOX-40`: binding changed from lockbox→SystemConfig to lockbox→the chain's SuperchainConfig (`:457`; v8 lockbox stored SystemConfig). | Runtime pause uses this binding and portal authorization checks portal SystemConfig→same SC. Exact current objects; only reinitializer/upgrade can alter. All four live values match. |
| V07 | `LOCKBOX-50`: exact portal authorization is no longer skippable (`:458`). | `lockETH`/`unlockETH` enforce the mapping at runtime. PA owner mutates it; attacker admin call reverted. |
| V08 | Permissionless game init bond must be nonzero (`:636-640`) to prevent free root-claim spam; permissioned game validator is the sibling exception. | OPCM config validation enforces before registration. Exact factory/type; only DGF owner can alter. Types 9 have 0.08 ETH live; Soneium type 5 zero is intentional. |
| V09 | Shared factory ProxyAdmin owner must be expected PAO (`:947-953`) because interop member chains retain distinct ProxyAdmins. | Migration enforces common chain PA owner and initializes shared proxies under the first. Exact current factory admin owner; ownership is privileged mutable only. |
| V10 | `ASR-RGT`: current respected type must be a type the selected validator branch actually validates (`:958-964`, predicate `:862-890`). | ASR guardian controls type; game registration is DGF-owner-only. Exact current ASR/factory. Attacker type change reverted. ZK counts only with feature+implementation. |
| V11 | `ZKDG-NOSHAPE`: when ZK dev feature is off, type 10 must be unregistered (`:1014-1024`). | OPCM prevents enabling ZK configs without feature. Exact current factory; DGF owner can later violate, not permissionless. All four production factories have type 10 unset. |
| V12 | ZK game-args length/shape must decode (`:1062-1089`, ZK branch `:1074-1077`). | OPCM/migrator validate args before registration. Exact factory bytes; privileged DGF owner only. |
| V13 | ZK absolute prestate/verifier key nonzero (`:1105-1108`). | Same check in `_isValidZKDisputeGameConfig`; exact registered args. Privileged mutable only. |
| V14 | ZK verifier must equal expected adapter **and have code** (`:1108-1112`), closing nonzero-EOA/missing-code negative space. | ZK runtime calls that exact verifier. Adapter code can disappear only through unusual privileged/protocol-level action; no permissionless configuration setter. |
| V15 | Challenge duration in `(0,uint32.max]` (`:1113-1119`) prevents an overflowed uint64 deadline/past deadline. | OPCM/migrator prevalidate exact args. Privileged mutable only. |
| V16 | Prove duration in `(0,uint32.max]` (`:1120-1124`) for the same deadline reason. | Same sibling enforcement and object identity as V15. |
| V17 | Challenger bond nonzero (`:1125`) prevents free challenges. | OPCM/migrator exact-args checks; privileged mutable only. |
| V18 | Current ASR anchor root nonzero (`:1126-1127`) ensures a playable ZK anchor. | Migrator checks supplied starting root; ASR can advance permissionlessly only through a valid respected game, which cannot create a zero accepted root under normal game semantics. |
| V19 | ZK implementation address must equal expected implementation (`:1179-1186`, `ZKDG-150`) in addition to semantic version. | Proxy-less DGF implementation mapping is set by owner; no permissionless setter. Exact registered address used for clones. |
| V20 | ZK init bond nonzero (`:1187-1190`) because ZK creation is permissionless. | OPCM/migrator bond rules enforce before registration. Exact type 10 bond; owner-only later mutation. |
| V21 | Removed direct portal→DGF equality `PORTAL-30` (`v8:L1/opcm/StandardValidatorUtils.sol:296-298`; absent `v9:297-307`). | Replacement is transitive: portal→ASR is checked at `v9:412-415`, ASR→DGF at `:399-401`, and SystemConfig's DGF is validated. This covers the exact proof path and shared interop architecture. Privileged pointers only; no gap found. |
| V22 | DelayedWETH binding changed SystemConfig equality (`v8:358`) to exact expected ETHLockbox (`v9:364-366`) for migrated historical games. | Runtime WETH pause calls that exact lockbox. Privileged reinitializer only; all four live bindings match. |
| V23 | Added DelayedWETH address must equal `SystemConfig.delayedWETH()` (`v9:370`) because V22 no longer proves the chain points back to that WETH. | Standard games decode WETH from DGF args, also validated; exact current chain pointer. Privileged only. |
| V24 | ASR binding changed SystemConfig equality (`v8:393`) to exact expected ETHLockbox (`v9:402-404`) for pause/guardian continuity. | Runtime ASR reads that lockbox; portal→ASR exact check remains `:412-415`. Privileged reinitializer only; all live values match. |
| V25 | Mode selection changed from dev-feature alone to current ASR respected type plus feature (`v9:958-990`), with V10 ensuring the selected type is actually covered. | Runtime portal always asks current ASR. Exact current config; guardian can change type, but validation must be rerun and permissionless caller cannot. |
| V26 | ZK validator deliberately returns early when type 10 is unregistered even if its dev feature is on (`:1161-1171`); this is an explicit per-chain opt-in negative space, not a new require. | V10 refuses ZK as respected unless registered; other respected super types are still validated. It cannot skip validation of the object later used for withdrawals. |

## MigrationValidator-only postconditions

The v9 diff substantially rewired/expanded this validator. The following is one row per literal added or materially changed `internalRequire` (a looped require is one source row). All execute **after** migration and are read-only; the validator result is not an on-chain capability. Skipping the validator is always possible for the privileged upgrade executor, so these are not runtime enforcement. The sibling runtime/OPCM check and permissionless stability are stated per row.

| ID | Postcondition and purpose (v9 `OPContractsManagerMigrationValidator.sol`) | Runtime sibling / exact object / can permissionless state violate later? |
|---|---|---|
| M01 | `MIG-SASR-RGT`: shared ASR respected type is a super type (`:123-130`). | Migrator prevalidates starting type and writes that exact ASR. Guardian can later change type; attacker cannot. |
| M02 | `MIG-DGF-10`: SUPER_PERMISSIONED registered (`:222-224`). | Migrator registers exact supplied configs and requires enabled; DGF owner only can remove. |
| M03 | `MIG-DGF-20`: SUPER_CANNON_KONA registered (`:224-225`). | Same exact shared DGF; owner-only later mutation. |
| M04 | `MIG-DGF-30`: legacy CANNON absent (`:226`). | Migrator creates a fresh shared DGF; owner-only later registration. |
| M05 | `MIG-DGF-40`: PERMISSIONED_CANNON absent (`:227-229`). | Same; no permissionless mapping setter. |
| M06 | `MIG-DGF-50`: CANNON_KONA absent (`:230`). | Same. |
| M07 | `MIG-DGF-60`: retired SUPER_CANNON absent (`:231`). | Same. ZK is intentionally not constrained by this fixed shape; ZK config has separate feature checks. |
| M08 | `MIG-SDGF-10`: shared DGF semantic version matches expected (`:247-251`). | OPCM selects implementation; only ProxyAdmin can change. Exact DGF discovered from input. |
| M09 | `MIG-SDGF-20`: exact DGF implementation (`:252-254`). | Runtime proxy admin controls it; permissionless stable. |
| M10 | `MIG-SDGF-30`: DGF owner equals PAO (`:255`). | Migrator initializes exact DGF with first PA owner. Ownership can change only by owner. |
| M11 | `MIG-SDGF-40`: DGF names discovered shared ProxyAdmin (`:256-258`). | Exact proxy slot, privileged stable. |
| M12 | `MIG-SPDG-GARGS-10`: shared permissioned args have exact decodable shape (`:272-279`). | Migrator encodes them; DGF owner-only later mutation. |
| M13 | `MIG-SCKDG-GARGS-10`: shared permissionless args have exact decodable shape (`:303-310`). | Same exact factory bytes; owner-only. |
| M14 | `MIG-SCKDG-GARGS-30`: super permissionless game's WETH equals chain-0/shared WETH (`:314-318`). | Migrator reuses chain 0 WETH and encodes it into the exact game args. Owner-only later mutation. |
| M15 | `MIG-SLOCKBOX-10`: lockbox version matches expected (`:440-444`). | OPCM writes exact implementation; privileged stable. |
| M16 | `MIG-SLOCKBOX-20`: exact lockbox implementation (`:445-447`). | ProxyAdmin-only later change. |
| M17 | `MIG-SLOCKBOX-30`: lockbox exact ProxyAdmin (`:448-452`). | Created under first chain PA; permissionless stable. |
| M18 | `MIG-SLOCKBOX-40`: lockbox exact intended SuperchainConfig (`:453-455`). | Migrator initializes with chain 0 SC after all-chain equality check. Privileged reinitializer only. |
| M19 | `MIG-CHAIN-EMPTY`: chain array nonempty (`:471-473`). | Migrator runtime rejects zero chains at `OPContractsManagerMigrator.sol:130-133`; calldata immutable within call. |
| M20 | `MIG-CHAIN-LEGACY-MISMATCH`: chain/legacy arrays same length (`:475-477`). | This is chiefly validator input integrity; migrator operates only on chain list and cannot enforce a later-supplied validator array. Caller-controlled, not an on-chain invariant. |
| M21 | `MIG-LOCKBOX-MISSING`: discovered portal lockbox nonzero (`:485-488`). | Portal initializer and migrator enforce exact nonzero lockbox. Privileged pointer only. |
| M22 | Per chain `-10`: portal names common ASR (`:495-497`). | Migrator writes the same exact new ASR into each portal; PA-owner only later change. |
| M23 | Per chain `-80`: shared lockbox authorizes portal (`:501-503`). | `lockETH`/`unlockETH` enforce exact mapping; lockbox PA owner only mutates. |
| M24 | Per chain `-90`: portal names exact shared lockbox (`:505-507`). | Portal uses that exact object for custody/pause; PA-owner only mutation. |
| M25 | Per chain `-100`: INTEROP feature on (`:509-513`). | Migrator sets it and SystemConfig forbids disabling; permissionless stable. |
| M26 | Per chain `-110`: ETH_LOCKBOX feature on (`:514-518`). | Migrator/standard upgrade set it and SystemConfig forbids disabling; stable. |
| M27 | Per chain `-120`: every SystemConfig points to common WETH (`:520-522`). | Migrator rewrites exact pointer to chain-0 WETH; only SystemConfig upgrade can alter. |
| M28 | Per chain `-130`: every SystemConfig names expected SC (`:523-527`). | Runtime precheck required equality before migration; privileged pointer only. |
| M29 | Per chain cleared-game loop (`:499`, implementation `:719-735`): all seven old types, including ZK, are zero in each legacy DGF. | Migrator clears the same centralized seven-type list before portal swap. DGF owner can re-register later; attacker cannot. |
| M30 | Per chain `-150`: retired portal balance zero (`:559`). | Migrator calls exact portal `migrateLiquidity`, but `donateETH` or forced ETH can violate immediately and permissionlessly. This is PRIM-3201; no custody impact found. |
| M31 | Per chain `-160`: retired old lockbox balance zero if distinct (`:563-567`). | Migrator authorizes/sweeps exact old lockbox. Forced ETH can later violate permissionlessly; PRIM-3201. |
| M32 | Per chain `-170`: retired portal identifier unpaused (`:569-571`). | Guardian controls current SC pause. Not permissionless; runtime now keys the new shared lockbox, so this only detects stale retired-state policy. |
| M33 | Per chain `-180`: retired lockbox identifier unpaused (`:572-575`). | Same guardian-only mutability; no current runtime path trusts old identifier after exact legacy rebinding. |
| M34 | `MIG-SHARED-10`: discovered ASR equals caller's expected ASR (`:596-598`). | Input-attestation check; portal runtime uses discovered/current pointer. Caller can lie only to make validation fail, not alter state. |
| M35 | `MIG-SHARED-20`: discovered lockbox equals expected (`:599-601`). | Same input-integrity role; runtime portal/authorization checks exact discovered object. |
| M36 | `MIG-SHARED-30`: discovered WETH equals expected (`:602`). | Same; SystemConfig/game-args exact checks independently bind it. |
| M37 | `MIG-SHARED-40`: input DGF equals shared ASR's DGF (`:603-607`). | Portal proof path reaches ASR→that exact DGF. Privileged ASR reinitializer only. |
| M38 | Legacy WETH `-190`: present and rebound to shared lockbox (`:633-642`). | Migrator upgrades exact chain WETH before portal migration. Privileged proxy upgrade only. |
| M39 | Legacy WETH `-200`: still under the chain's actual ProxyAdmin (`:643-647`). | Migrator uses that exact PA to upgrade it. Admin slot permissionless stable. |
| M40 | Legacy ASR `-210`: present and rebound to shared lockbox (`:649-654`). | Migrator upgrades exact old ASR after portal migration. Privileged only. |
| M41 | Legacy ASR `-220`: still under chain's actual ProxyAdmin (`:655-659`). | Exact admin slot; permissionless stable. |
| M42 | `MIG-SASR-10`: starting anchor root bytes equal intended (`:678-680`). | Migrator prevalidates nonzero and writes exact initializer value. `getStartingAnchorRoot` is not the permissionlessly advancing current anchor. |
| M43 | `MIG-SASR-20`: starting sequence equals intended (`:680-682`). | Same exact immutable starting proposal; permissionless current anchor advancement does not violate it. |
| M44 | `MIG-SASR-30`: starting respected type equals intended (`:683-685`). | Initializer exact; guardian can later change current respected type, so postvalidation is privileged mutable. |
| M45 | `MIG-BOND-i`: every caller-specified expected type/bond equals shared DGF (`:694-709`). | Migrator writes exact validated bond pairs. DGF owner can later change; attacker cannot. Expected list completeness is caller policy, so omitted types are negative space but mandatory permissionless type is separately validated. |

### Four-chain validator state at block 26433900

| Chain | ETH_LOCKBOX / INTEROP | portal→lockbox / ASR | WETH→lockbox / ASR→lockbox | respected type / implementation / bond | pause |
|---|---|---|---|---|---|
| OP | true / false | exact / exact | exact / exact | 9 / `0x19AF…` / 0.08 ETH | false |
| Ink | true / false | exact / exact | exact / exact | 9 / `0x19AF…` / 0.08 ETH | false |
| Soneium | true / false | exact / exact | exact / exact | 5 / `0x5C3e…` / 0 (permissioned exception) | false |
| Unichain | true / false | exact / exact | exact / exact | 9 / `0x19AF…` / 0.08 ETH | false |

All four lockboxes name the shared SuperchainConfig; all four portals are authorized; portal/lockbox/ASR ProxyAdmin-owner relationships tested equal. The only handful of validator conditions a permissionless actor can later falsify are the two raw-balance assertions. Current anchor games can advance permissionlessly, but the validator compares the stored **starting** anchor proposal, so ordinary advancement does not falsify M42/M43.

## Suspicious-row fork tests

Harness: `/home/user/u21-work/codex-32/h`; copied artifacts: `mirror/lane-32/test/NegativeSpace.t.sol` and `StateDiff.t.sol`. The first suite passed 8/8; the boundary suite passed 1/1. Full names/results are in `mirror/lane-32/TEST_RESULTS.md`.

| Test | Rows / bypass attempted | Real deployed outcome |
|---|---|---|
| `test_allFourChains_bindPauseAndGamesToExactLiveLockbox` | R01-R07, R16, V01-V10, V22-V25 | All four chains have exact SC/portal/lockbox/ASR/WETH/admin bindings; enabled respected type registered; permissionless type bond nonzero; not paused. |
| `test_configurationValidatorsCannotBeViolatedPermissionlessly` | R08/R10, V08/V10/V20, M02-M29 | Unprivileged `setFeature`, `setRespectedGameType`, and `setInitBond` each revert with the expected access-control error. |
| `test_deleteProvenWithdrawal_rejectsLiveNonInvalidatedHistoricalObject` | R14-R15, PRIM-3203 | Real nonzero proof, IN_PROGRESS game, no blacklist; permissionless deletion reverts `OptimismPortal_DisputeGameNotInvalidated`. |
| `test_liveL1AndL2MessengerGasBudgetsExposeAsymmetricUpgrade` | R18-R19, PRIM-3202 | L1 v9 ABI exposes remote 40k/5k while source local relay uses 135k/15k; live L2 remains old 40k/5k/version. No failed-finalization persistence demonstrated. |
| `test_lockboxAdministrativeSiblingsRemainProxyAdminOwnerOnly` | R05, R11, R48; lock/unlock/authorize siblings | `authorizePortal`, `authorizeLockbox`, `unlockETH`, and portal `migrateLiquidity` all revert from attacker context. |
| `test_migrateToSharedDisputeGame_featureGateRunsBeforeAuthorization` | R28/R43/R45; direct portal alternate | With live INTEROP=false, direct portal migration reverts `OptimismPortal_NotUsingInterop` before state mutation. |
| `test_siblingValuePaths_unauthorizedLockAndReceiveRevert_butDonateSucceeds` | R01/R11; `lockETH` vs `receiveLiquidity` vs `donateETH` | Unauthorized lock and receive revert; attacker-funded portal donation succeeds without changing lockbox. PRIM-3201 only. |
| `test_validatorZeroBalanceCanBeInvalidatedAfterValidationByForceSend` | M30-M31 | Constructor `SELFDESTRUCT` raises portal balance without invoking it, proving validator raw-balance instability. No claim/custody state changes. |
| `test_exactNMinus1ToNLinearStorageDiff` | Upgrade/initializer bypass R16/R48/R49 | 33 receipt-touched proxies compared; expected implementation/binding slots changed, admin slots did not, no unexplained selected-layout delta. |

## External-call result handling audit

- Portal target call: return value is intentionally retained for arbitrary withdrawals; failed value is returned to the exact current lockbox (`OptimismPortal2.sol:627-665`). For L2-messenger withdrawals v9 now reverts, and EVM atomicity restores all prior writes/calls (REJ-3201).
- Messenger relay: `SafeCall.call` result gates `successfulMessages`; failure records `failedMessages` and remains replayable under existing relay rules (`universal/CrossDomainMessenger.sol:285-303`). No ignored success bit was added.
- DelayedWETH recovery: raw call success is required (`dispute/DelayedWETH.sol:114-117`).
- Lockbox transfers use `SafeCall.send`, and failure reverts before completion (`L1/ETHLockbox.sol:168-173,209-212`).
- The removed `systemConfigFor` try/catch was the only changed path that swallowed a failed typed call; v9 removes the fallback and fails loud (R49).

## Primitives

### PRIM-3201 — validator zero balances are permissionlessly unstable

MigrationValidator checks portal/retired-lockbox balances after migration, but `donateETH` and forced ETH can make those balances nonzero after a successful validation. Unauthorized custody functions still revert. This is deterministic against deployed bytecode but attacker-funded, produces no claim, and no operation trusts a persistent validator attestation.

### PRIM-3202 — mixed-version gas-budget asymmetry

L1 v9 distinguishes local 135k/15k reserve/buffer from remote 40k/5k public/baseGas values, while live L2 remains on the older constants. The asymmetry is real; current behavior is conservative/retryable. Amsterdam state-gas behavior is future-only and was not represented as fork-reproduced.

### PRIM-3203 — historical proof/current registry coupling

A proof snapshots a dispute game and timestamp, not its registry. Finalization and proof deletion consult the portal's current ASR. Authorized migration therefore changes the policy judging historical objects. The planned first migration's proof invalidation/re-proof is explicit design; a live valid proof could not be deleted.

## Killed hypotheses

| Rejection | Exact killing fact |
|---|---|
| REJ-3201 | New post-call messenger revert atomically rolls back `finalizedWithdrawals`, lockbox unlock, `l2Sender`, and target state. |
| REJ-3202 | Live non-invalidated proof deletion reverts; status/blacklist condition precedes delete. |
| REJ-3203 | `lockETH`, `receiveLiquidity`, `unlockETH`, and authorization/admin siblings all enforce exact deployed authorization. Donation is self-funded only. |
| REJ-3204 | Config/type/bond/shared-owner validator invariants are role-controlled; attacker mutation calls revert. Only raw balances are permissionlessly unstable. |
| REJ-3205 | Re-migration is blocked by irreversible INTEROP, sequence check, same-owner/SC checks, and zero/duplicate/sorted chain IDs before mutation. |
| REJ-3206 | New SafeCall account gas is over-reservation under the active fork; messenger failure leaves withdrawal retryable. Amsterdam is not locally reproducible. |
| REJ-3207 | ZK respected-child check uses the exact DGF parent before funds/deadline initialization; type 10 is absent on all four factories. |
| REJ-3208 | Portal migration lacks a literal ASR `code.length` test, but typed pre-use plus INTEROP and ProxyAdmin-owner authority prevents an EOA from completing it; malicious interface contract is privileged misconfiguration. |

No candidate file was created. Each possible composition loses the candidate score on direct eligible impact and/or privileged-only state transition; none survives its rejection file's killing fact.

## Compositions deserving another lane

1. **Planned OP+Unichain migration × temporal proof policy × legacy pause routing.** Track one real pre-migration proof/game across shared-ASR installation, old ASR/WETH rebinding, proof deletion, re-proof, and a local pause. PRIM-3203 supplies the temporal edge; the risk would require a divergence beyond intended one-time invalidation.
2. **Future Amsterdam state gas × mixed L1/L2 budgets × portal retry.** Model EIP-8037 accurately when tooling supports it, especially value-bearing calls to a zero-code target created/destroyed within the transaction. A finding requires showing retry cannot recover, not merely estimation mismatch.
3. **Governance-calldata freeze × permissionless anchor advance × migration starting anchor.** Migrator only checks supplied anchor nonzero/room, not monotonicity against every legacy chain's current anchor. Determine whether a valid but stale shared starting proposal can cause more than extra computation/re-proof when the planned two-chain migration executes.

## Final assessment

The v9 security direction is consistently toward mandatory lockbox binding, exact shared-object identity, irreversible migration markers, pre-mutation config validation, and retryable messenger failures. The meaningful negative spaces are temporal (current registry/pause judging historical games), validator-only (raw balances), and future-fork gas accounting. None currently yields permissionless theft, insolvency, consensus corruption, or permanent withdrawal blocking on the deployed four-chain configuration.




