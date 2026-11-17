# Semantic lineage — CW0 independent Track-A reconstruction

Scope: pinned Bedrock `v1.0.0` through `op-contracts/v9.0.0`. `v2.1.0`, `v2.2.0`, and `v3.0.1` are indexed maintenance branches; the target function bodies are semantically identical to their v2/v3 bases (see `SOURCE-FUNCTION-INDEX.json`). Selector- and storage-stable semantic pivots are called out explicitly.

## Release spine

| Release | Security-surface pivot | Evidence |
|---|---|---|
| v1.0.0 | Portal custody/L2OO proofs; v0/v1 messenger replay; SafeCall; StandardBridge; DGF; ProxyAdmin | `v1.0.0:contracts/L1/OptimismPortal.sol:50-490`; `v1.0.0:contracts/universal/CrossDomainMessenger.sol:123-413` |
| v1.1.0 | Initialized dependency storage; structured SystemConfig addresses; append-only DGF list | `v1.1.0:src/L1/OptimismPortal.sol:120-135`; `v1.1.0:src/L1/SystemConfig.sol:30-73,155-191` |
| v1.2.0 | Global SuperchainConfig pause; messenger/bridge pause; DGF bonds/UUID form | `v1.2.0:src/L1/SuperchainConfig.sol:19-81`; `v1.2.0:src/L1/L1CrossDomainMessenger.sol:63-64` |
| v1.3.0 | Structured SystemConfig restored; messenger otherMessenger becomes storage | `v1.3.0:src/L1/SystemConfig.sol:150-210`; `v1.3.0:src/universal/CrossDomainMessenger.sol:80-110` |
| v1.4.0 | Portal2 per-submitter game proofs; ASR per-type anchors; DelayedWETH | `v1.4.0:src/L1/OptimismPortal2.sol:51-522`; `v1.4.0:src/dispute/AnchorStateRegistry.sol:20-87` |
| v1.5.0 | Legacy Portal/messenger/bridge gain custom-gas-token branches | `v1.5.0:src/L1/OptimismPortal.sol:165-215,232-585`; `v1.5.0:src/universal/CrossDomainMessenger.sol:176-195` |
| v1.6.0 | Custom-gas-token custody branch; guardian anchor override; safer recover call | `v1.6.0:src/L1/OptimismPortal2.sol:362-440,504-573`; `v1.6.0:src/dispute/AnchorStateRegistry.sol:99-119` |
| v1.8.0 | Typed-interface migration and Ecotone fee/EIP-1559 initializer arguments | `v1.8.0:src/L1/SystemConfig.sol:192-230,383-438`; `v1.8.0:src/L1/OptimismPortal2.sol:208-240` |
| v2.0.0 | Snapshot-respect games, single anchorGame, full ASR predicates; super games/type-5 | `v2.0.0:src/dispute/AnchorStateRegistry.sol:39-262`; `v2.0.0:src/dispute/SuperPermissionedDisputeGame.sol:89-108` |
| v2.1/v2.2 | No indexed target semantic delta | `SOURCE-FUNCTION-INDEX.json` |
| v3.0.0 | EIP-7623-aware messenger baseGas | `v3.0.0:src/universal/CrossDomainMessenger.sol:357-396` |
| v3.0.1 | No indexed target semantic delta | `SOURCE-FUNCTION-INDEX.json` |
| v4.0.0 | ETHLockbox custody; scoped expiring pauses; ASR owns invalidation; super-root Portal | `v4.0.0:src/L1/ETHLockbox.sol:67-232`; `v4.0.0:src/dispute/AnchorStateRegistry.sol:34-340` |
| v4.1.0 | Output-root/interoperability Portal split; runtime features/pause-key selection | `v4.1.0:src/L1/SystemConfig.sol:139,503-534` |
| v5.0.0 | DGF gameArgs becomes persistent future-clone configuration | `v5.0.0:src/dispute/DisputeGameFactory.sol:70-190,278-292` |
| v6.0.0 | ASR retirement preserved; dual clone-arg layout; feature-gated Portal CGT behavior returns | `v6.0.0:src/dispute/AnchorStateRegistry.sol:107-115`; `v6.0.0:src/dispute/DisputeGameFactory.sol:140-220`; `v6.0.0:src/L1/OptimismPortal2.sol:337-369,636-640` |
| v7.0.0 | Unified super-game proving, shared-game migration, deterministic DGF clones, OPCM V2 | `v7.0.0:src/L1/OptimismPortal2.sol:368-537`; `v7.0.0:src/L1/opcm/OPContractsManagerV2.sol:229-290` |
| v8.0.0 | Shared migration validation hardening; type-5 becomes a born-resolved proposer-gated game | `v8.0.0:src/L1/OptimismPortal2.sol:510-554`; `v8.0.0:src/dispute/SuperPermissionedDisputeGame.sol:48-73` |
| v9.0.0 | Lockbox-sourced pause/guardian, delete proof, split gas budgets, atomic failed-L1CDM withdrawal | `v9.0.0:src/L1/OptimismPortal2.sol:273-330,577-728`; `v9.0.0:src/L1/L1CrossDomainMessenger.sol:43-153` |

## Per-function/field records

### OptimismPortal/OptimismPortal2 — `l2Sender; provenWithdrawals; proofSubmitters; finalizedWithdrawals`

- **FIRST_INTRODUCED:** v1.0.0:contracts/L1/OptimismPortal.sol:67-83
- **ORIGINAL_MEANING:** One output-root proof per withdrawal hash; l2Sender is a reentrancy/context sentinel; finalization is hash-global.
- **ORIGINAL_INVARIANT:** A withdrawal executes at most once, and only inside the authenticated L2-sender context.
- **ALL_SEMANTIC_CHANGES:**
  - v1.4.0:src/L1/OptimismPortal2.sol:51-95 — proof storage becomes hash×submitter and an append-only submitter list; selector/storage head survive.
  - v9.0.0:src/L1/OptimismPortal2.sol:711-728 — permissionless delete clears one proof cell only; global finalization/list remain.
- **ALL_CALL_ORDER_CHANGES:**
  - v1.0.0:contracts/L1/OptimismPortal.sol:383-409 — set finalized and l2Sender before target call, reset sender after.
  - v4.0.0:src/L1/OptimismPortal2.sol:624-681 — lockbox unlock precedes target call; failed direct call relocks.
- **ALL_REVERT_SEMANTIC_CHANGES:**
  - v1.4.0:src/L1/OptimismPortal2.sol:461-522 — validity failures move into checkWithdrawal.
  - v9.0.0:src/L1/OptimismPortal2.sol:711-728 — delete reverts unless CHALLENGER_WINS or current-registry blacklist.
- **ALL_IDENTITY_SOURCE_CHANGES:**
  - v1.4.0:src/L1/OptimismPortal2.sol:83-95 — proof submitter becomes part of proof identity, not execution identity.
- **ALL_AUTHORIZATION_CHANGES:**
  - None identified in the pinned releases.
- **ALL_PAUSE_SOURCE_CHANGES:**
  - None identified in the pinned releases.
- **OBJECTS_CREATED_UNDER_OLD_MEANING:**
  - All L2OO proofs, per-submitter game proofs, duplicated submitter entries, and finalized hashes written since Bedrock.
- **MIGRATION_OR_INVALIDATION_EVENTS:**
  - v1.4.0 fault-proof migration changes proof keying without changing finalization key.
  - v7.0.0 super-game migration changes the game/root meaning while preserving cells.
  - v9.0.0 adds selective deletion.
- **CURRENT_CONSUMERS:**
  - v9.0.0:src/L1/OptimismPortal2.sol:577-728
- **UNREVIEWED_TRANSITIVE_PATHS:**
  - Pre-v1.4 proof records if any survived historical production migration; current cleanup of a legacy/non-game address (C4 reopen condition).

### OptimismPortal/OptimismPortal2 — `initialize; paused; guardian; superchainConfig`

- **FIRST_INTRODUCED:** v1.0.0:contracts/L1/OptimismPortal.sol:50-60,83,165-187
- **ORIGINAL_MEANING:** Portal stored immutable dependencies plus a local guardian-controlled paused bool.
- **ORIGINAL_INVARIANT:** The same guardian and pause bit gate proving/finalization for one portal.
- **ALL_SEMANTIC_CHANGES:**
  - v1.1.0:src/L1/OptimismPortal.sol:120-135 — oracle/SystemConfig/guardian become initialized storage.
  - v1.2.0:src/L1/OptimismPortal.sol:147-149 — pause/guardian route through SuperchainConfig.
  - v1.4.0:src/L1/OptimismPortal2.sol:163-190 — initializer adds DGF and game-validity state.
  - v4.0.0:src/L1/OptimismPortal2.sol:250-273,294-318 — dependencies reinitialized; pause/guardian route through SystemConfig.
  - v4.1.0:src/L1/OptimismPortal2.sol:222-260,446-514,566-616 — lockbox use becomes feature-gated.
  - v7.0.0:src/L1/OptimismPortal2.sol:251-281 — initializer accepts lockbox and interop config.
  - v9.0.0:src/L1/OptimismPortal2.sol:273-330 — pause, guardian, and SuperchainConfig now route through ETHLockbox.
- **ALL_CALL_ORDER_CHANGES:**
  - None identified in the pinned releases.
- **ALL_REVERT_SEMANTIC_CHANGES:**
  - v9.0.0:src/L1/OptimismPortal2.sol:273-303 — initializer rejects invalid interop/lockbox combinations.
- **ALL_IDENTITY_SOURCE_CHANGES:**
  - v1.0.0 local guardian → v1.2.0 SuperchainConfig → v4.0.0 SystemConfig → v9.0.0 ETHLockbox: v9.0.0:src/L1/OptimismPortal2.sol:306-330.
- **ALL_AUTHORIZATION_CHANGES:**
  - v1.0.0 guardian direct calls; current setters/migrations require ProxyAdmin or its owner: v9.0.0:src/L1/OptimismPortal2.sol:273-303,528-572.
- **ALL_PAUSE_SOURCE_CHANGES:**
  - v1.0.0 local bool; v1.2.0 global SC; v4.0.0 SystemConfig-selected scoped key; v9.0.0 local-or-global ETHLockbox key.
- **OBJECTS_CREATED_UNDER_OLD_MEANING:**
  - Pause timestamps under portal/SystemConfig identifiers and dependency pointers initialized before U21.
- **MIGRATION_OR_INVALIDATION_EVENTS:**
  - Each reinitializer preserves proxy storage but changes the authority/pause indirection; v9 migrateToSharedDisputeGame can repoint lockbox/ASR.
- **CURRENT_CONSUMERS:**
  - prove/finalize/deposit bridge pause checks: v9.0.0:src/L1/OptimismPortal2.sol:390-492,577-666,741-795
- **UNREVIEWED_TRANSITIVE_PATHS:**
  - Historic pointer divergence on a non-profiled chain; old scoped pause timestamp consumed after identifier pivot (C8 reopen).

### OptimismPortal/OptimismPortal2 — `proveWithdrawalTransaction; checkWithdrawal; blacklist/respected-type/retirement`

- **FIRST_INTRODUCED:** v1.0.0:contracts/L1/OptimismPortal.sol:242-318
- **ORIGINAL_MEANING:** Proof binds an L2 output-oracle proposal to withdrawal storage; proof validity is stored with the oracle root.
- **ORIGINAL_INVARIANT:** Only a finalized canonical output root can authorize a withdrawal.
- **ALL_SEMANTIC_CHANGES:**
  - v1.4.0:src/L1/OptimismPortal2.sol:254-328,441-522 — indexed game proof; Portal owns blacklist, respected type, cutoff and rechecks them at finalization.
  - v2.0.0:src/L1/OptimismPortal2.sol:292-378 — respect is snapshotted at game creation and creation must be after cutoff.
  - v4.0.0:src/L1/OptimismPortal2.sol:439-570,693-727 — validity governance moves into ASR; super-root proof branch added.
  - v4.1.0:src/L1/OptimismPortal2.sol:430-570 — output-root Portal2 and interop Portal split.
  - v7.0.0:src/L1/OptimismPortal2.sol:368-471 — one function branches on registered game type and extracts per-chain root from super games.
  - v9.0.0:src/L1/OptimismPortal2.sol:390-492,671-705 — current ASR proper/respected checks and current-registry revalidation.
- **ALL_CALL_ORDER_CHANGES:**
  - v1.4.0 proves game identity before MPT inclusion and writes last; v4.0.0 delegates current validity to ASR before root-format branch.
- **ALL_REVERT_SEMANTIC_CHANGES:**
  - v1.4.0 allowed reprove after root change; v2.0.0 rejects games not respected at creation; v4.0.0 returns InvalidRootClaim through ASR result.
- **ALL_IDENTITY_SOURCE_CHANGES:**
  - L2OO address+index → DGF index/game address → ASR's DGF registration plus game-snapshotted respect; super game additionally uses SystemConfig.l2ChainId.
- **ALL_AUTHORIZATION_CHANGES:**
  - v1.4.0 Portal guardian setters → v4.0.0 ASR guardian setters: v9.0.0:src/dispute/AnchorStateRegistry.sol:156-185.
- **ALL_PAUSE_SOURCE_CHANGES:**
  - v4.0.0 ASR pause participates in isGameProper; v9 routes it via ETHLockbox: v9.0.0:src/dispute/AnchorStateRegistry.sol:136-143,286-305.
- **OBJECTS_CREATED_UNDER_OLD_MEANING:**
  - Old L2OO proofs, games created under each respected-type/prestate, and proof cells referencing an old DGF/ASR.
- **MIGRATION_OR_INVALIDATION_EVENTS:**
  - Fresh-ASR migration retires old games; current initializer retains an already nonzero retirement timestamp: v9.0.0:src/dispute/AnchorStateRegistry.sol:124-132.
- **CURRENT_CONSUMERS:**
  - v9.0.0:src/L1/OptimismPortal2.sol:390-492,671-705; v9.0.0:src/dispute/AnchorStateRegistry.sol:227-352
- **UNREVIEWED_TRANSITIVE_PATHS:**
  - L1: pre-v1.9 kona prestate game consumed by current ASR; L8: old game/proof after shared-registry migration.

### OptimismPortal/OptimismPortal2 — `finalizeWithdrawalTransactionExternalProof; unsafe targets`

- **FIRST_INTRODUCED:** base finalize: v1.0.0:contracts/L1/OptimismPortal.sol:325-420; external-proof overload: v1.4.0:src/L1/OptimismPortal2.sol:339-387
- **ORIGINAL_MEANING:** Anyone may execute a mature proof; global finalization is committed before the target call; failed target call is normally non-reverting.
- **ORIGINAL_INVARIANT:** Global hash replay protection survives arbitrary finalizer identity and target behavior.
- **ALL_SEMANTIC_CHANGES:**
  - v1.4.0:src/L1/OptimismPortal2.sol:339-387 — caller may select another proof submitter.
  - v4.0.0:src/L1/OptimismPortal2.sol:624-681,805-808 — ETH unlock/relock surrounds call and lockbox joins unsafe-target list.
  - v9.0.0:src/L1/OptimismPortal2.sol:577-666 — failed L1CDM call from the L2CDM sender now reverts the entire finalization; other failures remain finalized/relocked.
- **ALL_CALL_ORDER_CHANGES:**
  - v4.0.0 unlock before finalized bit/target then exact relock on failure; v9 checks feature/pause/game before unlock and performs messenger-specific revert after call.
- **ALL_REVERT_SEMANTIC_CHANGES:**
  - v1.0.0 only estimation-origin failure reverts after target failure; v9 additionally reverts failed L1CDM messenger withdrawals at lines 639-653.
- **ALL_IDENTITY_SOURCE_CHANGES:**
  - Unsafe target began as Portal/self; v4 adds current ETHLockbox; retired lockboxes and sibling portals are not identity-derived targets: v9.0.0:src/L1/OptimismPortal2.sol:846-849.
- **ALL_AUTHORIZATION_CHANGES:**
  - None identified in the pinned releases.
- **ALL_PAUSE_SOURCE_CHANGES:**
  - Pause source follows Portal generations; current check is lockbox pause before state mutation: v9.0.0:src/L1/OptimismPortal2.sol:583-589.
- **OBJECTS_CREATED_UNDER_OLD_MEANING:**
  - Mature proofs from every prior proof regime; failedMessages and portal/lockbox balances produced before U21.
- **MIGRATION_OR_INVALIDATION_EVENTS:**
  - v9 messenger atomicity invalidates the prior finalized+failed L1CDM outcome but deliberately retains direct-call failure semantics.
- **CURRENT_CONSUMERS:**
  - ETHLockbox, L1CrossDomainMessenger, arbitrary L1 target, SafeCall: v9.0.0:src/L1/OptimismPortal2.sol:620-660
- **UNREVIEWED_TRANSITIVE_PATHS:**
  - L3 replay callback → nested finalization → parked L1CDM value across pause/migration; retired-lockbox target after shared migration.

### OptimismPortal/OptimismPortal2 — `depositTransaction; donateETH; migrateLiquidity; migrateToSuperRoots/migrateToSharedDisputeGame`

- **FIRST_INTRODUCED:** deposit/donate: v1.0.0:contracts/L1/OptimismPortal.sol:196-215,434-490; migrations: v4.0.0:src/L1/OptimismPortal2.sol:374-429
- **ORIGINAL_MEANING:** Deposits escrow msg.value in Portal and emit an opaque L2 mint/call-value transaction; donate accepts unaccounted ETH.
- **ORIGINAL_INVARIANT:** Deposit value is exactly escrowed once; migration cannot strand the active withdrawal backing.
- **ALL_SEMANTIC_CHANGES:**
  - v1.5.0:src/L1/OptimismPortal.sol:165-215,232-585 — the legacy Portal first adds custom-gas-token balance, prove/finalize and split mint/value deposit branches.
  - v1.6.0:src/L1/OptimismPortal2.sol:362-440,504-573 — custom-gas-token mode separates native balance accounting.
  - v2.0.0:src/L1/OptimismPortal2.sol:135-136,292-490 — Portal2 removes custom-gas-token execution and turns `_balance` into a spacer.
  - v4.0.0:src/L1/OptimismPortal2.sol:374-429,740-788 — deposits lock ETH in ETHLockbox; portal liquidity and super-root migrations added.
  - v4.1.0:src/L1/OptimismPortal2.sol:222-260,446-514,566-616 — lockbox use becomes feature-gated.
  - v6.0.0:src/L1/OptimismPortal2.sol:337-369,440-465,565-588,636-640 — custom-gas-token behavior returns behind the SystemConfig feature map.
  - v7.0.0:src/L1/OptimismPortal2.sol:503-537 — shared-dispute-game migration repoints lockbox and ASR.
  - v8.0.0:src/L1/OptimismPortal2.sol:510-554 — nonzero/new-lockbox authorization checks hardened.
  - v9.0.0:src/L1/OptimismPortal2.sol:502-572,741-795 — CGT guard and current shared migration.
- **ALL_CALL_ORDER_CHANGES:**
  - v4.0.0 deposit body locks ETH before ResourceMetering modifier completes: v9.0.0:src/L1/OptimismPortal2.sol:741-795.
- **ALL_REVERT_SEMANTIC_CHANGES:**
  - Lockbox authorization/balance failures now revert deposit; CGT rejects positive ETH liability paths: v9.0.0:src/L1/OptimismPortal2.sol:741-759.
- **ALL_IDENTITY_SOURCE_CHANGES:**
  - Custody address changes from Portal itself to its current ETHLockbox; migration selects a new shared lockbox/ASR.
- **ALL_AUTHORIZATION_CHANGES:**
  - Migration restricted to ProxyAdmin owner and same-admin authorization: v9.0.0:src/L1/OptimismPortal2.sol:528-572.
- **ALL_PAUSE_SOURCE_CHANGES:**
  - Deposits intentionally stay open while unlocks are paused: v9.0.0:src/L1/ETHLockbox.sol:142-159.
- **OBJECTS_CREATED_UNDER_OLD_MEANING:**
  - Portal surplus, per-chain lockbox liquidity, historical deposits and sticky authorization records.
- **MIGRATION_OR_INVALIDATION_EVENTS:**
  - migrateLiquidity drains portal to lockbox; shared migration authorizes/repoints and separately migrates old lockbox liquidity.
- **CURRENT_CONSUMERS:**
  - v9.0.0:src/L1/ETHLockbox.sol:124-235; v9.0.0:src/L1/OptimismPortal2.sol:502-572,741-795
- **UNREVIEWED_TRANSITIVE_PATHS:**
  - L8/L9: pre-pooling L2 ETH liability vs each lockbox; orphaned per-chain lockbox and portal surplus after cutover.

### OptimismPortal2 — `deleteProvenWithdrawal`

- **FIRST_INTRODUCED:** v9.0.0:src/L1/OptimismPortal2.sol:711-728
- **ORIGINAL_MEANING:** Anyone may clear one submitter's proof only after its game is challenger-wins or current-registry-blacklisted.
- **ORIGINAL_INVARIANT:** Deletion cannot make a still-finalizable proof unavailable and cannot clear global replay protection.
- **ALL_SEMANTIC_CHANGES:**
  - None identified in the pinned releases.
- **ALL_CALL_ORDER_CHANGES:**
  - status() is called before current-registry blacklist at v9.0.0:src/L1/OptimismPortal2.sol:717-723.
- **ALL_REVERT_SEMANTIC_CHANGES:**
  - A no-code/reverting stored game makes cleanup revert before blacklist; deletion does not cover retirement/unregistration.
- **ALL_IDENTITY_SOURCE_CHANGES:**
  - Blacklist identity is the Portal's current ASR, not necessarily the ASR that accepted the proof.
- **ALL_AUTHORIZATION_CHANGES:**
  - None identified in the pinned releases.
- **ALL_PAUSE_SOURCE_CHANGES:**
  - None identified in the pinned releases.
- **OBJECTS_CREATED_UNDER_OLD_MEANING:**
  - All pre-v9 proof cells and stale proofSubmitters entries.
- **MIGRATION_OR_INVALIDATION_EVENTS:**
  - Shared-registry swap makes old proofs dead but normally undeletable unless the new ASR blacklists the old address.
- **CURRENT_CONSUMERS:**
  - proof cell/list and checkWithdrawal: v9.0.0:src/L1/OptimismPortal2.sol:671-728
- **UNREVIEWED_TRANSITIVE_PATHS:**
  - Pre-fault-proof/non-game storage record (C4 reopen); cleanup after a non-atomic registry swap.

### CrossDomainMessenger — `relayMessage; hash versions; replay/reentrancy; gas constants`

- **FIRST_INTRODUCED:** v1.0.0:contracts/universal/CrossDomainMessenger.sol:123-193,303-413
- **ORIGINAL_MEANING:** Accept v0 legacy and v1 canonical hashes; initial relay authenticates other messenger, replay requires failedMessages; sentinel blocks reentrancy; every nonreverting call writes success or failure.
- **ORIGINAL_INVARIANT:** One economic message cannot succeed twice, and failed messages remain permissionlessly retryable.
- **ALL_SEMANTIC_CHANGES:**
  - v1.2.0:src/universal/CrossDomainMessenger.sol:211-314 — relay becomes pause-aware and asserts success mapping consistency.
  - v1.3.0:src/universal/CrossDomainMessenger.sol:80-110 — otherMessenger changes immutable→storage without changing hash.
  - v1.5.0:src/universal/CrossDomainMessenger.sol:176-195,346-371 — custom-gas-token mode forbids value-message creation and changes base-gas support; v2.0.0:src/universal/CrossDomainMessenger.sol:177-195 removes that send-time branch.
  - v3.0.0:src/universal/CrossDomainMessenger.sol:357-396 — baseGas accounts for EIP-7623 calldata floor.
  - v9.0.0:src/universal/CrossDomainMessenger.sol:209-310,339-420,461-466 — local reserve/check split from advertised remote budget.
- **ALL_CALL_ORDER_CHANGES:**
  - Initial/replay branch precedes unsafe-target and success checks; gas/reentrant failure is recorded before target call; target call then selects success vs failed mapping.
- **ALL_REVERT_SEMANTIC_CHANGES:**
  - Low local gas or reentrant sentinel returns after marking failed, rather than reverting; current Portal wraps a failed L1CDM low-level call with a withdrawal-level revert.
- **ALL_IDENTITY_SOURCE_CHANGES:**
  - v0 uses legacy hash; v1+ canonical hash includes value/minGas/nonce; replay identity remains canonical message hash.
- **ALL_AUTHORIZATION_CHANGES:**
  - Initial relay uses authenticated other messenger; replay is public but requires failedMessages.
- **ALL_PAUSE_SOURCE_CHANGES:**
  - v1.2 adds chain pause; L1 source changes SuperchainConfig→SystemConfig in v4: v9.0.0:src/L1/L1CrossDomainMessenger.sol:98-100.
- **OBJECTS_CREATED_UNDER_OLD_MEANING:**
  - Legacy v0 hashes, successful/failed mappings, in-flight withdrawals sized under older remote constants.
- **MIGRATION_OR_INVALIDATION_EVENTS:**
  - Proxy upgrades preserve mapping slots and legacy hash branch; U21 changes local execution budget without migrating message objects.
- **CURRENT_CONSUMERS:**
  - Portal, L1StandardBridge and arbitrary message target: v9.0.0:src/universal/CrossDomainMessenger.sol:256-302
- **UNREVIEWED_TRANSITIVE_PATHS:**
  - L3 forced failedMessages × target replay/pause/migration; L5 transaction cap × maximum calldata and local reserve.

### L1CrossDomainMessenger — `paused; _isUnsafeTarget; local/remote gas getters`

- **FIRST_INTRODUCED:** v1.0.0:contracts/L1/L1CrossDomainMessenger.sol:45-66
- **ORIGINAL_MEANING:** Portal authenticates L2 messenger; Portal and messenger itself are unsafe relay targets; no L1 pause override.
- **ORIGINAL_INVARIANT:** Relayed calls cannot recursively control the transport contracts.
- **ALL_SEMANTIC_CHANGES:**
  - v1.2.0:src/L1/L1CrossDomainMessenger.sol:63-64 — pause supplied by SuperchainConfig.
  - v4.0.0:src/L1/L1CrossDomainMessenger.sol:74-75 — pause supplied by SystemConfig.
  - v9.0.0:src/L1/L1CrossDomainMessenger.sol:43-74,117-153 — exposes distinct local 135k/15k budget and remote-budget getters.
- **ALL_CALL_ORDER_CHANGES:**
  - None identified in the pinned releases.
- **ALL_REVERT_SEMANTIC_CHANGES:**
  - Current local budget can reject/record failure even when the remote advertised floor was lower.
- **ALL_IDENTITY_SOURCE_CHANGES:**
  - Portal address remains the authentication and unsafe-target identity; its SystemConfig now supplies pause indirectly through lockbox.
- **ALL_AUTHORIZATION_CHANGES:**
  - onlyOtherMessenger still resolves through Portal l2Sender: v9.0.0:src/L1/L1CrossDomainMessenger.sol:129-143.
- **ALL_PAUSE_SOURCE_CHANGES:**
  - none → SuperchainConfig → SystemConfig → SystemConfig→Portal→ETHLockbox.
- **OBJECTS_CREATED_UNDER_OLD_MEANING:**
  - All old-budget L2→L1 messages and failedMessages.
- **MIGRATION_OR_INVALIDATION_EVENTS:**
  - None identified in the pinned releases.
- **CURRENT_CONSUMERS:**
  - CrossDomainMessenger.relayMessage and Portal finalization.
- **UNREVIEWED_TRANSITIVE_PATHS:**
  - Amsterdam/EIP-7825 budget boundary; historical v0 message encoded under pre-Bedrock budget.

### SafeCall — `hasMinGas; callWithMinGas`

- **FIRST_INTRODUCED:** v1.0.0:contracts/libraries/SafeCall.sol:91-159
- **ORIGINAL_MEANING:** Precheck EIP-150 forwarding plus 40k reserve, then call with exactly the requested minimum-gas envelope.
- **ORIGINAL_INVARIANT:** Caller retains enough gas to record the outcome after an adversarial callee.
- **ALL_SEMANTIC_CHANGES:**
  - v1.6.0:src/libraries/SafeCall.sol:93-161 — overload/refactor preserves reserve meaning.
  - v9.0.0:src/libraries/SafeCall.sol:7-9,103-171 — value call to codehash-zero target reserves 183,600 future new-account state gas.
- **ALL_CALL_ORDER_CHANGES:**
  - State-dependent codehash test occurs before computing the call gas/reserve at v9 lines 121-171.
- **ALL_REVERT_SEMANTIC_CHANGES:**
  - Insufficient envelope returns false from hasMinGas or reverts the guarded call; target failure remains a boolean.
- **ALL_IDENTITY_SOURCE_CHANGES:**
  - Target codehash now changes the gas identity class.
- **ALL_AUTHORIZATION_CHANGES:**
  - None identified in the pinned releases.
- **ALL_PAUSE_SOURCE_CHANGES:**
  - None identified in the pinned releases.
- **OBJECTS_CREATED_UNDER_OLD_MEANING:**
  - Persisted messages targeting accounts that were empty/nonempty at different times.
- **MIGRATION_OR_INVALIDATION_EVENTS:**
  - None identified in the pinned releases.
- **CURRENT_CONSUMERS:**
  - Portal finalization and CrossDomainMessenger relay.
- **UNREVIEWED_TRANSITIVE_PATHS:**
  - L5: empty-target state transition between proof and relay; Amsterdam actual cost vs pre-reserved 183,600.

### StandardBridge — `finalizeBridgeETH/finalizeBridgeERC20 (legacy finalizeETHWithdrawal/finalizeERC20Withdrawal)`

- **FIRST_INTRODUCED:** v1.0.0:contracts/universal/StandardBridge.sol:294-348
- **ORIGINAL_MEANING:** Only the counterpart bridge may finalize; ETH requires exact msg.value and successful recipient call; ERC20 mints native token or decrements escrow then transfers.
- **ORIGINAL_INVARIANT:** Exactly one messenger-authenticated finalize releases/mints exactly the encoded amount.
- **ALL_SEMANTIC_CHANGES:**
  - v1.2.0:src/universal/StandardBridge.sol:139-141,227-299 — both finalize paths become pause-aware.
  - v1.5.0:src/universal/StandardBridge.sol:244-266 — ETH finalization rejects custom-gas-token mode; v2.0.0:src/universal/StandardBridge.sol:239-260 removes that extra rejection.
  - v2.0.0:src/universal/StandardBridge.sol:230-310 — naming/interface refactor; custody invariant unchanged.
  - v9.0.0:src/universal/StandardBridge.sol:239-299 — current exact-value and escrow/mint split.
- **ALL_CALL_ORDER_CHANGES:**
  - ETH external call follows messenger authentication, pause, value and unsafe recipient checks; ERC20 escrow decrement precedes transfer.
- **ALL_REVERT_SEMANTIC_CHANGES:**
  - ETH recipient failure reverts bridge call; messenger records failure/replay rather than partial release.
- **ALL_IDENTITY_SOURCE_CHANGES:**
  - Native-vs-remote token pair selects mint vs escrow branch.
- **ALL_AUTHORIZATION_CHANGES:**
  - onlyOtherBridge resolves xDomainMessageSender through messenger: v9.0.0:src/universal/StandardBridge.sol:111-117.
- **ALL_PAUSE_SOURCE_CHANGES:**
  - v1.2 virtual pause; current L1 bridge reads SystemConfig.paused at v9.0.0:src/L1/L1StandardBridge.sol:122-124, which reaches the ETHLockbox key via v9.0.0:src/L1/SystemConfig.sol:574-576.
- **OBJECTS_CREATED_UNDER_OLD_MEANING:**
  - Legacy v0 bridge messages, escrowed ERC20 balances, failedMessages.
- **MIGRATION_OR_INVALIDATION_EVENTS:**
  - None identified in the pinned releases.
- **CURRENT_CONSUMERS:**
  - L1/L2 CrossDomainMessenger and token contracts.
- **UNREVIEWED_TRANSITIVE_PATHS:**
  - Legacy hash-domain change describing the same bridge release (C5 reopen); L3 replay target composition.

### SystemConfig — `initialize arguments; address storage scheme`

- **FIRST_INTRODUCED:** v1.0.0:contracts/L1/SystemConfig.sol:43-64,125-143
- **ORIGINAL_MEANING:** Initialize owner, fee scalars, batcher/gas limit, unsafe-block signer and resource config in ordinary storage.
- **ORIGINAL_INVARIANT:** One authoritative per-chain configuration supplies derivation and L1 contract dependencies.
- **ALL_SEMANTIC_CHANGES:**
  - v1.1.0:src/L1/SystemConfig.sol:30-73,155-191 — Addresses struct moves dependencies into fixed unstructured slots and adds startBlock/batchInbox.
  - v1.2.0:src/L1/SystemConfig.sol:109-150 — maintenance branch temporarily retains lean initializer shape.
  - v1.3.0:src/L1/SystemConfig.sol:150-210 — structured address scheme restored with automatic startBlock.
  - v1.5.0:src/L1/SystemConfig.sol:168-305 — gas-paying-token state/getters enter initialization-era configuration.
  - v1.8.0:src/L1/SystemConfig.sol:192-230,383-438 — initializer uses Ecotone basefee/blob scalars and EIP-1559 parameters are added.
  - v4.0.0:src/L1/SystemConfig.sol:133-200 — l2ChainId and SuperchainConfig added.
  - v4.1.0:src/L1/SystemConfig.sol:139-226 — features mapping enters initializer state.
  - v9.0.0:src/L1/SystemConfig.sol:49-99,203-248 — Addresses includes DelayedWETH/OPCM; no batch-inbox initializer argument.
- **ALL_CALL_ORDER_CHANGES:**
  - None identified in the pinned releases.
- **ALL_REVERT_SEMANTIC_CHANGES:**
  - Current initializer has explicit dependency validity and ProxyAdmin authority checks.
- **ALL_IDENTITY_SOURCE_CHANGES:**
  - Dependency identity moves from ordinary fields to named slots; l2ChainId becomes the Portal's super-game chain selector.
- **ALL_AUTHORIZATION_CHANGES:**
  - Initializer authority evolves to ProxyAdmin or owner under ReinitializableBase.
- **ALL_PAUSE_SOURCE_CHANGES:**
  - None identified in the pinned releases.
- **OBJECTS_CREATED_UNDER_OLD_MEANING:**
  - Every proxy slot/address written by older initializers and all deposits/games using the historical chain config.
- **MIGRATION_OR_INVALIDATION_EVENTS:**
  - OPCM reset/reinitializer rewrites named addresses but retains fee/config state.
- **CURRENT_CONSUMERS:**
  - Portal, bridges, messenger, resource metering, dispute games.
- **UNREVIEWED_TRANSITIVE_PATHS:**
  - Pre-v1.3 chain whose temporarily lean initializer history differs; l2ChainId written after a game root was created.

### SystemConfig — `features; paused; superchainConfig; guardian`

- **FIRST_INTRODUCED:** superchainConfig/l2ChainId: v4.0.0:src/L1/SystemConfig.sol:133-200; features: v4.1.0:src/L1/SystemConfig.sol:139,503-534
- **ORIGINAL_MEANING:** SystemConfig owned feature bits and selected a portal-or-lockbox pause identifier against SuperchainConfig.
- **ORIGINAL_INVARIANT:** Feature transitions cannot enable an invalid custody mode, and all chain contracts observe one pause/guardian.
- **ALL_SEMANTIC_CHANGES:**
  - v4.1.0:src/L1/SystemConfig.sol:503-534 — feature map and pause-key selection introduced.
  - v9.0.0:src/L1/SystemConfig.sol:532-581 — ETH_LOCKBOX/INTEROP are immutable once set; paused delegates to Portal's lockbox while guardian remains the stored SC guardian.
- **ALL_CALL_ORDER_CHANGES:**
  - v9 setFeature checks portal-identifier pause before enabling ETH_LOCKBOX; paused then calls Portal→ETHLockbox.
- **ALL_REVERT_SEMANTIC_CHANGES:**
  - Feature transitions reject disabling immutable features and some paused enables.
- **ALL_IDENTITY_SOURCE_CHANGES:**
  - Pause identifier changes SystemConfig/Portal→Portal's ETHLockbox, while guardian identity remains SystemConfig.superchainConfig.
- **ALL_AUTHORIZATION_CHANGES:**
  - onlyOwner sets features: v9.0.0:src/L1/SystemConfig.sol:532-568.
- **ALL_PAUSE_SOURCE_CHANGES:**
  - v4.1 local/global key selection; v9 Portal-lockbox delegation.
- **OBJECTS_CREATED_UNDER_OLD_MEANING:**
  - Existing ETH, proofs, messages and games when a runtime feature flips.
- **MIGRATION_OR_INVALIDATION_EVENTS:**
  - OPCM migrations enable features and repoint Portal; no object-by-object conversion.
- **CURRENT_CONSUMERS:**
  - Portal, messenger, bridges, resource-metered deposit path.
- **UNREVIEWED_TRANSITIVE_PATHS:**
  - Privileged feature transition over pre-existing liquidity; independent L1/L2 feature state machines.

### SuperchainConfig — `guardian; pause generations`

- **FIRST_INTRODUCED:** v1.2.0:src/L1/SuperchainConfig.sol:19-23,49-81
- **ORIGINAL_MEANING:** One guardian controls one global unstructured paused bit.
- **ORIGINAL_INVARIANT:** A global pause consistently blocks security-critical exits until guardian unpauses.
- **ALL_SEMANTIC_CHANGES:**
  - v4.0.0:src/L1/SuperchainConfig.sol:40-182 — pause becomes expiring timestamp mapping keyed by identifier; initializer migrates old guardian/global pause.
  - v9.0.0:src/L1/SuperchainConfig.sol:30-40,79-153 — local paused(address) excludes global; new isLocalOrGlobalPaused explicitly ORs both.
- **ALL_CALL_ORDER_CHANGES:**
  - pause refuses any nonzero historical timestamp, even expired; extend refreshes a nonzero timestamp: v9 lines 79-120.
- **ALL_REVERT_SEMANTIC_CHANGES:**
  - Expired pause reads false but still makes pause() revert AlreadyPaused; guardian must unpause/extend.
- **ALL_IDENTITY_SOURCE_CHANGES:**
  - Pause identity expands global address(0) → arbitrary address → current ETHLockbox consumers.
- **ALL_AUTHORIZATION_CHANGES:**
  - Guardian remains initializer-set and directly authorizes pause/unpause/extend.
- **ALL_PAUSE_SOURCE_CHANGES:**
  - global bool → expiring scoped mapping → explicit local-or-global helper.
- **OBJECTS_CREATED_UNDER_OLD_MEANING:**
  - All historical nonzero pause timestamps, including inert/expired keys.
- **MIGRATION_OR_INVALIDATION_EVENTS:**
  - v4 initializer clears/migrates old global state; v9 preserves timestamps and changes consumers.
- **CURRENT_CONSUMERS:**
  - ETHLockbox.paused at v9.0.0:src/L1/ETHLockbox.sol:112-113; legacy consumers of paused().
- **UNREVIEWED_TRANSITIVE_PATHS:**
  - Historical identifier divergence; a non-lockbox timestamp made operational again by future pointer reuse.

### AnchorStateRegistry — `anchors → anchorGame/startingAnchorRoot; setAnchorState`

- **FIRST_INTRODUCED:** v1.4.0:src/dispute/AnchorStateRegistry.sol:20-87
- **ORIGINAL_MEANING:** Store an independent anchor root per game type; a registered defender-win game may advance its type's anchor.
- **ORIGINAL_INVARIANT:** Only a valid newer output for that game type advances that type's starting state.
- **ALL_SEMANTIC_CHANGES:**
  - v1.6.0:src/dispute/AnchorStateRegistry.sol:99-119 — guardian can override an anchor via SuperchainConfig authority.
  - v2.0.0:src/dispute/AnchorStateRegistry.sol:39-84,239-262 — per-type mapping collapses to one anchorGame plus starting root.
  - v4.0.0:src/dispute/AnchorStateRegistry.sol:34-55,168-200,294-340 — ASR owns validity/retirement and one shared anchor.
  - v7.0.0:src/dispute/AnchorStateRegistry.sol:94-133 — reinitializer may clear anchor only when a changed starting root is ahead.
  - v9.0.0:src/dispute/AnchorStateRegistry.sol:188-212,355-370 — legacy anchors(type) returns the same current root for every type.
- **ALL_CALL_ORDER_CHANGES:**
  - Current setAnchorState runs full isGameClaimValid before comparing l2SequenceNumber.
- **ALL_REVERT_SEMANTIC_CHANGES:**
  - Mixed output-root block numbers and super-root timestamps share one monotonic comparison.
- **ALL_IDENTITY_SOURCE_CHANGES:**
  - Anchor identity changes (gameType,root) mapping → one game address/factory domain.
- **ALL_AUTHORIZATION_CHANGES:**
  - Permissionless claim-valid game can advance; guardian can change validity inputs rather than direct current setter.
- **ALL_PAUSE_SOURCE_CHANGES:**
  - v4 isGameProper incorporates pause; v9 pause comes from ETHLockbox.
- **OBJECTS_CREATED_UNDER_OLD_MEANING:**
  - Per-type anchors, output-root games and super-root games with different sequence-number units.
- **MIGRATION_OR_INVALIDATION_EVENTS:**
  - Fresh-ASR migration installs a starting root; reinitializer can preserve or clear current anchor under ahead check.
- **CURRENT_CONSUMERS:**
  - Dispute-game initialization and fault-proof programs; Portal proof validity.
- **UNREVIEWED_TRANSITIVE_PATHS:**
  - L7 type-5 born-resolved game advancing shared anchor; old output-root block number versus timestamp ordering.

### AnchorStateRegistry — `isGameRegistered/isGameRespected/isGameRetired/isGameProper/isGameClaimValid`

- **FIRST_INTRODUCED:** registration precursor: v1.4.0:src/dispute/AnchorStateRegistry.sol:59-87; full predicate set: v2.0.0:src/dispute/AnchorStateRegistry.sol:116-239
- **ORIGINAL_MEANING:** Factory membership plus current Portal-owned respect/blacklist/cutoff/finality defines whether one game claim can authorize a withdrawal.
- **ORIGINAL_INVARIANT:** Only an authentic, noninvalidated, finalized defender-win game respected when created is claim-valid.
- **ALL_SEMANTIC_CHANGES:**
  - v2.0.0:src/dispute/AnchorStateRegistry.sol:116-239 — single-game validity predicates introduced, reading Portal governance.
  - v4.0.0:src/dispute/AnchorStateRegistry.sol:182-340 — ASR owns DGF, blacklist, respected type, retirement; registration also checks game.anchorStateRegistry().
  - v6.0.0:src/dispute/AnchorStateRegistry.sol:107-115 — reinitialize sets retirement only if zero.
  - v7.0.0:src/dispute/AnchorStateRegistry.sol:215-352 — registration removes embedded-ASR equality; retirement-at-init is the invalidation boundary; proper no longer requires current type.
  - v9.0.0:src/dispute/AnchorStateRegistry.sol:227-352 — current registered/snapshotted-respect/retirement/pause/finality predicates.
- **ALL_CALL_ORDER_CHANGES:**
  - isGameClaimValid calls proper → respected → finalized → status; Portal prove may accept proper/respected before game is final.
- **ALL_REVERT_SEMANTIC_CHANGES:**
  - Registration ABI failure reverts; ordinary invalidation predicates return false; retirement uses <= timestamp.
- **ALL_IDENTITY_SOURCE_CHANGES:**
  - Portal governance → ASR storage; embedded ASR equality removed in favor of DGF UUID domain and retirement.
- **ALL_AUTHORIZATION_CHANGES:**
  - Guardian writes blacklist/type/retirement via current ETHLockbox guardian: v9 lines 156-185,374-378.
- **ALL_PAUSE_SOURCE_CHANGES:**
  - v4 proper includes pause; v9 pause source pivots SystemConfig→ETHLockbox.
- **OBJECTS_CREATED_UNDER_OLD_MEANING:**
  - Every game clone created before a reinitializer, DGF swap, type change or retirement update.
- **MIGRATION_OR_INVALIDATION_EVENTS:**
  - Fresh DGF+ASR makes old games unregistered and retired; in-place reinitializer preserves nonzero retirement.
- **CURRENT_CONSUMERS:**
  - Portal prove/check/finalize and setAnchorState.
- **UNREVIEWED_TRANSITIVE_PATHS:**
  - L1 old prestate game under current predicate; L8 DGF/ASR partial cutover; game with old immutable ASR after registration check removal.

### AnchorStateRegistry — `guardian; blacklist; respectedGameType; retirementTimestamp; pause dependency`

- **FIRST_INTRODUCED:** guardian anchor override: v1.6.0:src/dispute/AnchorStateRegistry.sol:99-119; owned governance fields: v4.0.0:src/dispute/AnchorStateRegistry.sol:34-55,127-159
- **ORIGINAL_MEANING:** Guardian can invalidate exact games, change accepted type, or blanket-retire old games; SystemConfig supplies guardian/pause.
- **ORIGINAL_INVARIANT:** Emergency invalidation is monotonic enough that a known-bad game cannot later authorize a withdrawal accidentally.
- **ALL_SEMANTIC_CHANGES:**
  - v6.0.0:src/dispute/AnchorStateRegistry.sol:107-115 — reinitialization no longer advances an existing retirement timestamp.
  - v9.0.0:src/dispute/AnchorStateRegistry.sol:33-59,94-185 — SystemConfig slot becomes spacer; ETHLockbox supplies pause, guardian and SuperchainConfig.
- **ALL_CALL_ORDER_CHANGES:**
  - None identified in the pinned releases.
- **ALL_REVERT_SEMANTIC_CHANGES:**
  - Retirement equality is invalid (createdAt <= retirement); blacklist is address exact and permanent.
- **ALL_IDENTITY_SOURCE_CHANGES:**
  - Guardian and pause identity change from SC/SystemConfig to ETHLockbox while DGF/game identity is unchanged.
- **ALL_AUTHORIZATION_CHANGES:**
  - Guardian through ethLockbox.guardian at v9 lines 374-378; initialize through ProxyAdmin/owner at lines 103-105.
- **ALL_PAUSE_SOURCE_CHANGES:**
  - SystemConfig.paused → ETHLockbox.paused.
- **OBJECTS_CREATED_UNDER_OLD_MEANING:**
  - Games created when a type was respected and proofs referring to a pre-retirement game.
- **MIGRATION_OR_INVALIDATION_EVENTS:**
  - In-place U21 reinitialize preserves retirement; fresh shared ASR stamps migration time and retires all old games.
- **CURRENT_CONSUMERS:**
  - isGameProper/isGameClaimValid, Portal prove/check, setAnchorState.
- **UNREVIEWED_TRANSITIVE_PATHS:**
  - Current-state-only PASS A census does not prove historical blacklist/type/retirement transitions on every chain.

### DisputeGameFactory — `create; UUID inputs; gameArgs`

- **FIRST_INTRODUCED:** v1.0.0:contracts/dispute/DisputeGameFactory.sol:30-37,78-162
- **ORIGINAL_MEANING:** Clone implementation selected by gameType with immutable rootClaim+extraData; UUID identifies (type,root,extra).
- **ORIGINAL_INVARIANT:** At most one registered game exists for a UUID and its immutable arguments cannot change.
- **ALL_SEMANTIC_CHANGES:**
  - v1.1.0:src/dispute/DisputeGameFactory.sol:30-115 — append-only GameId list/timestamp and upgradeability added.
  - v1.2.0:src/dispute/DisputeGameFactory.sol:87-134 — init bonds and abi.encode UUID form established.
  - v1.4.0:src/dispute/DisputeGameFactory.sol:84-132 — creator/root/parentHash/extraData immutable layout.
  - v5.0.0:src/dispute/DisputeGameFactory.sol:70-190,278-292 — mutable per-type gameArgs appended to future clones.
  - v6.0.0:src/dispute/DisputeGameFactory.sol:140-220 — empty legacy args and explicit-gameType new layout bifurcate clone decoding.
  - v7.0.0:src/dispute/DisputeGameFactory.sol:147-225 — collision check precedes deterministic CREATE2 clone.
  - v9.0.0:src/dispute/DisputeGameFactory.sol:147-245,312-318 — current dual-layout create and dynamic gameArgs setter.
- **ALL_CALL_ORDER_CHANGES:**
  - v1 create cloned/initialized before collision store; v7 checks UUID collision before deterministic clone; initialization still precedes registry/list write.
- **ALL_REVERT_SEMANTIC_CHANGES:**
  - Duplicate UUID now fails before external clone initialization rather than after it.
- **ALL_IDENTITY_SOURCE_CHANGES:**
  - UUID inputs stay type/root/extra while clone identity also depends on factory CREATE2 domain and mutable implementation/gameArgs.
- **ALL_AUTHORIZATION_CHANGES:**
  - Anyone creates after posting initBond; owner configures implementation, args and bond.
- **ALL_PAUSE_SOURCE_CHANGES:**
  - None identified in the pinned releases.
- **OBJECTS_CREATED_UNDER_OLD_MEANING:**
  - Every clone permanently embeds the implementation args active at creation; append-only list preserves old entries.
- **MIGRATION_OR_INVALIDATION_EVENTS:**
  - Implementation/gameArgs updates bifurcate old/new clones without migrating them; DGF replacement changes registration domain.
- **CURRENT_CONSUMERS:**
  - ASR registration and Portal proof game-index lookup.
- **UNREVIEWED_TRANSITIVE_PATHS:**
  - Old clone under pre-current gameArgs/prestate consumed by current mutable ASR; incomplete clearedGameTypes during migration.

### DelayedWETH — `fallback deposit; unlock/withdraw/recover; pause/guardian dependency`

- **FIRST_INTRODUCED:** v1.4.0:src/dispute/weth/DelayedWETH.sol:20-92 and v1.4.0:src/dispute/weth/WETH98.sol:28-42
- **ORIGINAL_MEANING:** WETH receive/fallback deposits mint; unlock starts a delay; withdraw burns/transfers after delay and global SC pause check; guardian recovers excess.
- **ORIGINAL_INVARIANT:** Recorded bond credit is redeemable once after delay, subject only to emergency pause, and recover cannot consume backed credit.
- **ALL_SEMANTIC_CHANGES:**
  - v1.6.0:src/dispute/weth/DelayedWETH.sol:85-98 — recover uses call instead of transfer.
  - v9.0.0:src/dispute/DelayedWETH.sol:37-129 — SystemConfig slot becomes spacer; ETHLockbox supplies pause/guardian/SC.
- **ALL_CALL_ORDER_CHANGES:**
  - unlock writes timestamp/amount; withdraw validates pause+delay then clears/burns/transfers.
- **ALL_REVERT_SEMANTIC_CHANGES:**
  - Unknown payable selector still succeeds as WETH fallback deposit; nonpayable unknown selector reverts by value requirement.
- **ALL_IDENTITY_SOURCE_CHANGES:**
  - Pause/guardian identity moves SC→SystemConfig→ETHLockbox; token-credit identity stays account address.
- **ALL_AUTHORIZATION_CHANGES:**
  - Game owner can unlock/withdraw its credit; guardian recovery routes through current lockbox guardian.
- **ALL_PAUSE_SOURCE_CHANGES:**
  - global SuperchainConfig → per-chain SystemConfig → v9 ETHLockbox local-or-global.
- **OBJECTS_CREATED_UNDER_OLD_MEANING:**
  - Credits/unlock timestamps in old DelayedWETH proxies and games immutable-bound to an older proxy.
- **MIGRATION_OR_INVALIDATION_EVENTS:**
  - OPCM may reinitialize singleton pointers, but immutable game clones can retain old DelayedWETH addresses.
- **CURRENT_CONSUMERS:**
  - Dispute games' bond credit and guardian recovery.
- **UNREVIEWED_TRANSITIVE_PATHS:**
  - L8 orphaned legacy WETH credit after shared migration; pause behavior of pre-v1.4 deployments.

### ETHLockbox — `authorized portals/lockboxes; lockETH/unlockETH; migrateLiquidity; pause/guardian`

- **FIRST_INTRODUCED:** v4.0.0:src/L1/ETHLockbox.sol:67-232
- **ORIGINAL_MEANING:** Per-chain lockbox escrows Portal deposits, returns value through donateETH before withdrawal execution, and can migrate all balance to an authorized same-owner lockbox.
- **ORIGINAL_INVARIANT:** Only authorized same-domain portals debit; unlock is paused, nonreentrant against an executing withdrawal, and backed by balance.
- **ALL_SEMANTIC_CHANGES:**
  - v7.0.0:src/L1/ETHLockbox.sol:67-232 — shared-lockbox authorization/migration paths are used by interop migration.
  - v9.0.0:src/L1/ETHLockbox.sol:66-78,94-235 — SystemConfig slot becomes spacer; SC stored directly; local-or-global pause keyed by lockbox.
- **ALL_CALL_ORDER_CHANGES:**
  - unlock checks pause/auth/balance/l2Sender then donateETH; Portal then marks/calls and may relock. migrate reads whole balance then calls receiveLiquidity.
- **ALL_REVERT_SEMANTIC_CHANGES:**
  - Unauthorized, paused, insufficient or during-withdrawal unlock reverts; locks intentionally do not check pause.
- **ALL_IDENTITY_SOURCE_CHANGES:**
  - Portal domain check resolves its SystemConfig.superchainConfig, not Portal.superchainConfig, at v9 lines 220-228.
- **ALL_AUTHORIZATION_CHANGES:**
  - ProxyAdmin owner authorizes; shared owner equality is sampled at authorization/migration time and authorization is monotonic.
- **ALL_PAUSE_SOURCE_CHANGES:**
  - SystemConfig.paused in v4 → directly stored SuperchainConfig.isLocalOrGlobalPaused(this) in v9.
- **OBJECTS_CREATED_UNDER_OLD_MEANING:**
  - All lockbox balances and authorization entries from per-chain/shared generations.
- **MIGRATION_OR_INVALIDATION_EVENTS:**
  - Portal migrate/repoint and lockbox migrate are separate calls expected to be atomic in governed batch.
- **CURRENT_CONSUMERS:**
  - Portal deposit/finalize/migrate and other authorized lockboxes.
- **UNREVIEWED_TRANSITIVE_PATHS:**
  - L8 sticky retired lockbox authorization; L9 per-chain liability before pooling; later PA ownership divergence after authorization.

### ProxyAdmin — `proxy type/name mappings; upgrade; upgradeAndCall`

- **FIRST_INTRODUCED:** v1.0.0:contracts/universal/ProxyAdmin.sol:40-70,211-254
- **ORIGINAL_MEANING:** Owner chooses proxy adapter (ERC1967/chugsplash/resolved) and performs implementation upgrades or upgrade+call.
- **ORIGINAL_INVARIANT:** Only current owner can mutate implementation; adapter-specific routing reaches the intended proxy.
- **ALL_SEMANTIC_CHANGES:**
  - v4.0.0:src/universal/ProxyAdmin.sol:120-194 — proxy adapter support refactored without changing owner gate.
  - v9.0.0:src/universal/ProxyAdmin.sol:152-192 — current upgrade and upgradeAndCall behavior remains owner-gated.
- **ALL_CALL_ORDER_CHANGES:**
  - upgradeAndCall upgrades first and calls initializer atomically.
- **ALL_REVERT_SEMANTIC_CHANGES:**
  - Adapter misclassification causes adapter-specific revert; successful call commits both implementation and initialization.
- **ALL_IDENTITY_SOURCE_CHANGES:**
  - Proxy type/name and AddressManager mappings select target semantics.
- **ALL_AUTHORIZATION_CHANGES:**
  - Ownable owner is sole external upgrade authority.
- **ALL_PAUSE_SOURCE_CHANGES:**
  - None identified in the pinned releases.
- **OBJECTS_CREATED_UNDER_OLD_MEANING:**
  - Every proxy registered under historical type/name metadata.
- **MIGRATION_OR_INVALIDATION_EVENTS:**
  - OPCM invokes ProxyAdmin from the governed Safe context; ownership transfers change authority without proxy storage migration.
- **CURRENT_CONSUMERS:**
  - All L1 proxy upgrades.
- **UNREVIEWED_TRANSITIVE_PATHS:**
  - Historical proxy registered with a different adapter/name than current OPCM metadata.

### ProxyAdminOwnedBase — `proxyAdmin; proxyAdminOwner; shared-owner assertions`

- **FIRST_INTRODUCED:** v4.0.0:src/L1/ProxyAdminOwnedBase.sol:35-105
- **ORIGINAL_MEANING:** Implementation discovers its proxy admin through the proxy owner slot (including resolved-proxy special cases), then derives ProxyAdmin.owner and compares domains.
- **ORIGINAL_INVARIANT:** Privileged cross-contract operations require the same live ProxyAdmin owner/security domain.
- **ALL_SEMANTIC_CHANGES:**
  - v7.0.0:src/universal/ProxyAdminOwnedBase.sol:35-105 — file moves to universal; semantics remain.
  - v9.0.0:src/universal/ProxyAdminOwnedBase.sol:41-101 — current owner probing and shared-owner assertion.
- **ALL_CALL_ORDER_CHANGES:**
  - shared-owner check reads both owners at call time; authorizers may persist the result after ownership later diverges.
- **ALL_REVERT_SEMANTIC_CHANGES:**
  - Nonproxy/unrecognized proxy shapes revert on owner probing.
- **ALL_IDENTITY_SOURCE_CHANGES:**
  - ERC1967 PROXY_OWNER slot first; resolved-delegate special mapping slots second.
- **ALL_AUTHORIZATION_CHANGES:**
  - ProxyAdmin or its owner gates initialize; ProxyAdmin owner alone gates cross-domain authorization/migration.
- **ALL_PAUSE_SOURCE_CHANGES:**
  - None identified in the pinned releases.
- **OBJECTS_CREATED_UNDER_OLD_MEANING:**
  - Monotonic authorizations created when owners matched.
- **MIGRATION_OR_INVALIDATION_EVENTS:**
  - No automatic invalidation on later ownership transfer.
- **CURRENT_CONSUMERS:**
  - Portal/ETHLockbox/ASR/DGF initializers and lockbox migration.
- **UNREVIEWED_TRANSITIVE_PATHS:**
  - L8 authorization snapshot consumed after one ProxyAdmin ownership changes; spoofable proxyAdminOwner on untrusted address before a stronger identity check.
