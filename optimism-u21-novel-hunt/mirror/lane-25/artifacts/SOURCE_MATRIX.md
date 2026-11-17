# Lane 25 source and predicate matrix

Pinned target commit: `ba6fcadbc57eb99918c5b0f14f57c72527f531e3` (`op-contracts/v9.0.0`). Baseline: `f45a5ccfebcdf6da3f5b09cbc512667c063730b7` (`v8.0.0`).

## Exact predicate

`OptimismPortal2.deleteProvenWithdrawal` at `src/L1/OptimismPortal2.sol:711-728`:

1. load `provenWithdrawals[hash][submitter]`;
2. revert `Unproven` if its timestamp is zero;
3. call `status()` on the stored game address;
4. permit deletion iff status is `CHALLENGER_WINS` **or** the current ASR blacklist maps that exact address to true;
5. delete only the nested mapping cell and emit `WithdrawalProofDeleted`.

There is no finalized, registration, properness, retirement, respect, finality, pause, caller, or submitter-ownership check.

| State of stored game/proof | Delete? | Fork evidence | Can it later become valid? |
|---|---:|---|---|
| timestamp zero | no (`Unproven`) | repeat-delete test | n/a |
| `IN_PROGRESS`, proper/respected | no | real pre-N proof at N | yes, if defender wins and finalizes |
| `DEFENDER_WINS`, valid/finalized | no | production-reachable status modeled on real registered game | already valid |
| `CHALLENGER_WINS` | yes | production-reachable terminal status modeled on real registered game | no; game resolve is one-shot |
| blacklisted, any ordinary status | yes | real Guardian blacklist call | no; mapping has no unblacklist path |
| retired only | no | real Guardian retirement update | no, but the submitter may overwrite with a new proof |
| no longer respected only | no | synthetic boundary | accepted proofs captured `true` at creation; production-unreachable flip |
| unregistered only | no | synthetic unregistered game and migration model | after migration, old proof stays stored but is unusable and overwriteable |
| paused only | no | source; pause is not read | temporary invalidity must not authorize deletion |
| challenger/blacklisted while paused | yes | actual lockbox-scoped pause on fork | still permanently invalid |
| already finalized + defender game | no | real post-U21 finalized proof | irrelevant to replay |
| already finalized + later blacklist | yes | fork test | `finalizedWithdrawals` remains true |
| no-code stored address | call reverts | fork test, even when blacklisted | unreachable from honest history |

## Why the permanent predicates are permanent

- `GameStatus` is `{IN_PROGRESS, CHALLENGER_WINS, DEFENDER_WINS}` (`src/dispute/lib/Types.sol:20-27`).
- Fault and super-fault `resolve` require current `IN_PROGRESS`, then write one terminal status and `resolvedAt` (`FaultDisputeGame.sol:698-717`; `SuperFaultDisputeGame.sol:667-686`). `closeGame` changes only bond distribution/anchor state (`FaultDisputeGame.sol:1019-1072`; `SuperFaultDisputeGame.sol:985-1036`).
- Permissioned fault games inherit that resolution logic (`PermissionedDisputeGame.sol:19-35`).
- ZK resolution likewise rejects a second resolution and writes the terminal status once (`zk/ZKDisputeGame.sol:570-640`); `closeGame` only selects bond mode (`:696-750`).
- Super-permissioned games initialize directly to `DEFENDER_WINS`; `resolve` is a pure no-op returning defender (`SuperPermissionedDisputeGame.sol:51-78`).
- `AnchorStateRegistry.blacklistDisputeGame` only writes `true` and exposes no clearing function (`AnchorStateRegistry.sol:177-186`).

## Reachability of stored game addresses

Both v8 and v9 proof paths obtain the game from `DisputeGameFactory.gameAtIndex`, require `isGameProper`, and require `isGameRespected` before storing it (v8 `OptimismPortal2.sol:375-412,465-472`; v9 `:390-427,480-487`). `isGameProper` begins with factory registration (`AnchorStateRegistry.sol:286-300`). Factory games are deterministic immutable-implementation clones and are recorded only after successful initialization (`DisputeGameFactory.sol:142-225`). The relevant game implementations contain no `selfdestruct` or upgrade hook.

Therefore a no-code, reverting-status, or arbitrary unregistered game can be injected in a test to map the boundary, but no permissionless path was found to create such a historical proof entry. A no-code entry would impede cleanup rather than delete a valid proof.

## Two proof structures

The authoritative cell is `provenWithdrawals[hash][submitter]` at portal slot 57. Every prove overwrites that cell with `msg.sender` and a fresh timestamp, then unconditionally appends `msg.sender` to `proofSubmitters[hash]` at slot 60 (`OptimismPortal2.sol:480-487`). Deletion clears only the slot-57 cell (`:725`); it never edits the array. The only on-chain array consumer is its generated index getter plus `numProofSubmitters` (`:800-802`). Finalization calls `checkWithdrawal(hash, explicitSubmitter)` (`:603-607,671-705`) and never selects from the array.

Consequences: stale entries and duplicates are real; repeated re-proof can grow the array and reset only the caller's timer. But there is no portal loop, no automatic “first proof” choice, and no cross-submitter overwrite. This behavior already existed in v8 (`OptimismPortal2.sol:465-472`).

## Planned migration

`OPContractsManagerV2.migrate` explicitly documents that every prior proof is invalidated (`src/L1/opcm/OPContractsManagerV2.sol:280-287`). The migrator deploys a fresh DGF and ASR (`OPContractsManagerMigrator.sol:191-222`), initializes the ASR with that factory (lines 246-263; ASR initialization sets retirement timestamp on first initialization at `AnchorStateRegistry.sol:124-132`), and repoints each portal (`OPContractsManagerMigrator.sol:542-543`; portal write at `OptimismPortal2.sol:562-571`).

The proof mapping is not cleared. Instead, every old game fails at least two new-ASR conditions: it is not registered in the new factory and its creation is at/before the new retirement timestamp. `checkWithdrawal` therefore rejects it at `isGameClaimValid`; re-proving against a new shared game overwrites the submitter's same mapping cell and appends another array entry. No pre-migration proof can survive the registry swap, and atomic migration leaves no interleaving window in which a user can install a proof against the new factory before the pointer changes.

