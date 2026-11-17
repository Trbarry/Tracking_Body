# LANE 25 — Proof Lifecycle and Permissionless Deletion

## Result

No bounty-grade candidate survived falsification.

The U21 claim holds for every production-reachable proof state I found: `deleteProvenWithdrawal` cannot delete a proof that can later become finalizable. Its two enabling facts—`CHALLENGER_WINS` and blacklist—are permanent for every configured game family. The permissionless caller can target another submitter, but only after that exact proof already fails `checkWithdrawal` permanently.

Two concrete quirks are real but did not produce eligible impact:

1. deletion clears the authoritative nested mapping but never removes the address from `proofSubmitters`, leaving stale entries; repeated proof already appended duplicates before U21;
2. `status()` is called before the blacklist lookup, so a hypothetical stored no-code/reverting game cannot be cleaned even when blacklisted. No permissionless path can create such a stored entry.

No candidate file was created. The best suspicious item, paid duplicate/stale-array growth, scores 0 (+2 permissionless, +2 real-implementation reproduction, +1 deterministic, −3 no eligible impact, −2 economically irrational without amplification) and remains a rejected primitive rather than a candidate.

## Scope and method

Blind-first analysis only. I did not read prior audits, public findings, other lanes, top-level U21 artifacts, or other mirror outputs.

Pinned roots:

- target `/home/user/ethereum-optimism/op-v9.0.0` at `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`;
- baseline `/home/user/ethereum-optimism/op-v8.0.0` at `f45a5ccfebcdf6da3f5b09cbc512667c063730b7`;
- older reachability check `/home/user/ethereum-optimism/op-v7.0.0` at `a7c88c8d636ceb9944ea0edaf7d033da258778ab`;
- permitted develop docs at `e5423ae69b154100a77361d74eb6d7170b2c34aa`.

All chain operations were passive reads. All state changes were in-process Forge fork state. Privileged `vm.prank` was used only to construct states the deployed Guardian can create today: blacklist, retirement, and pause. Synthetic storage writes are explicitly marked boundary models and are not cited as production exploitability.

Primary harness: `mirror/lane-25/test/ProofLifecycle.t.sol`. Result: 14/14 tests pass; transcript in `mirror/lane-25/artifacts/forge-proof-lifecycle.txt`.

## Proof state machine

For a withdrawal hash `H` and submitter `S`, the authoritative portal cell is:

```text
P[H][S] = (game, proofTimestamp)
```

The discovery history is a separate append-only array:

```text
submitters[H] = [S0, S1, ...]
```

### Transitions

**Prove.** v9 fetches a game by factory index, requires it to be proper, respected at creation, and not already challenger-wins, verifies the output root/storage proof, overwrites `P[H][msg.sender]`, and unconditionally appends `msg.sender` (`src/L1/OptimismPortal2.sol:390-491`). v8 used the same provenance and two writes (`v8 src/L1/OptimismPortal2.sol:375-476`).

**Check/finalize.** Finalization computes `H`, calls `checkWithdrawal(H, explicitly selected S)`, then sets the independent replay flag before target execution (`v9 OptimismPortal2.sol:577-627`). `checkWithdrawal` requires a nonzero proof timestamp, timestamp sanity, proof maturity, and `currentASR.isGameClaimValid(storedGame)` (`:671-705`). ASR validity requires properness, creation-time respect, game finality, and `DEFENDER_WINS` (`src/dispute/AnchorStateRegistry.sol:331-352`).

**Delete.** Any caller may clear `P[H][S]` if and only if the stored game says challenger-wins or the current ASR has blacklisted that address (`OptimismPortal2.sol:707-728`). The array and replay flag are untouched.

**Re-prove.** The same submitter overwrites the deleted/stale/invalid cell with a new game and timestamp and appends another array entry (`:480-487`). No other address can reset that submitter's timer.

**Migrate.** The planned interop migration swaps the portal to a fresh ASR/DGF. The proof cell survives, but the old stored game fails the new ASR's registration and retirement tests. A new proof overwrites it.

### Required invariants

1. A valid-later proof must not satisfy the deletion predicate now.
2. One submitter's proof must not overwrite or block another's.
3. Deleting proof metadata must not clear withdrawal replay protection.
4. Historical proof provenance must ensure the stored game has stable `status()` semantics.
5. Migration invalidation must be total and atomic if users are instructed to re-prove.

All five held in source and deployed-state tests.

## Exact deletion predicate

The executable condition is:

```solidity
timestamp != 0 &&
(
    storedGame.status() == CHALLENGER_WINS ||
    currentASR.isGameBlacklisted(storedGame)
)
```

Notably absent: `finalizedWithdrawals`, registered/proper/respected/retired/finalized checks, pause, caller authorization, or proof-submitter consent.

### Permanence of challenger-wins

`GameStatus` has only in-progress, challenger-wins, and defender-wins (`src/dispute/lib/Types.sol:20-27`).

- `FaultDisputeGame.resolve` requires `IN_PROGRESS`, derives one terminal result, sets `resolvedAt`, and writes status (`src/dispute/FaultDisputeGame.sol:698-717`). `closeGame` changes anchor/bond mode only (`:1019-1072`).
- `SuperFaultDisputeGame` has the same one-shot pattern (`src/dispute/SuperFaultDisputeGame.sol:667-686`); its close path does not change status (`:985-1036`).
- `PermissionedDisputeGame` inherits Fault's resolution state (`src/dispute/PermissionedDisputeGame.sol:19-35`).
- `ZKDisputeGame.resolve` rejects a second resolution, selects one terminal result, then records `resolvedAt` (`src/dispute/zk/ZKDisputeGame.sol:570-640`). Its close path only selects bond distribution (`:696-750`).
- `SuperPermissionedDisputeGame.initialize` immediately sets defender-wins; `resolve` is a pure defender-wins no-op (`src/dispute/SuperPermissionedDisputeGame.sol:51-78`). It can never enable status-based deletion.

No terminal-to-terminal transition or reset exists.

### Permanence of blacklist

`blacklistDisputeGame` is Guardian-only and writes `true`; there is no unblacklist function (`AnchorStateRegistry.sol:177-186`). A proxy upgrade could rewrite this fact, but that is privileged protocol replacement, not a permissionless production path.

### Boundary results

| Stored state | Result | Security meaning |
|---|---|---|
| `IN_PROGRESS` | `DisputeGameNotInvalidated` | preserved; may later become valid |
| `DEFENDER_WINS` | `DisputeGameNotInvalidated` | preserved |
| `CHALLENGER_WINS` | deleted by arbitrary caller | already permanently invalid |
| blacklisted | deleted by arbitrary caller | already permanently invalid |
| retired only | not deletable | cleanup incomplete, but re-proof overwrites |
| unregistered only | not deletable | migration leaves stale but overwriteable cell |
| not respected only | not deletable | accepted proof cannot naturally flip its creation bit |
| paused only | not deletable | correct: pause is temporary |
| challenger/blacklisted while paused | deletable | permanent reason remains decisive |
| already finalized | predicate ignores finalization | replay flag remains independent |
| no code at stored game | ABI call reverts | unreachable cleanup-denial edge |

See `mirror/lane-25/artifacts/SOURCE_MATRIX.md` for line-level detail and test mapping.

## Historical stored-game reachability

The dangerous hypothetical is an address whose `status()` lies, changes later, reenters, or disappears. I found no permissionless provenance path.

Both v8 and v9 fetch the address from `DisputeGameFactory.gameAtIndex` and require ASR properness and creation-time respect before storage (v8 portal `:396-412`; v9 portal `:411-427`). Properness starts with `isGameRegistered` (`AnchorStateRegistry.sol:286-300`), which reconstructs the game key and compares the factory's recorded address (`:227-236`). Factory creation clones a configured implementation, successfully initializes it, then records it in both mapping and array (`DisputeGameFactory.sol:142-225`). v7 has the same factory/properness provenance (`v7 OptimismPortal2.sol:390-397`).

The configured game sources contain no selfdestruct or upgrade hook; existing clones retain their implementation even when the factory pointer for a type is later unset. A malicious implementation registration would require the factory owner and is operator/governance misconfiguration. A view-interface status call is static, so it cannot mutate portal state through reentrancy.

Synthetic fork injection confirms the edge behavior: an unregistered in-progress entry is not deletable; if its fake status is challenger-wins it is deletable because provenance is not rechecked. A no-code entry reverts before a true blacklist is read. Neither state is reachable from an accepted historical proof.

## Mapping/array integrity

The mapping and array have deliberately different semantics:

- mapping slot 57: current proof for a specific address;
- array slot 60: append-only discovery history.

Proving overwrites the former and pushes to the latter (`OptimismPortal2.sol:480-487`). Deletion clears only the former (`:725`). `numProofSubmitters` only returns array length (`:800-802`), and source-wide search finds no portal loop or automatic selection. Finalization indexes the mapping by the user-supplied address (`:603-607,671-705`).

Therefore:

- stale entries after deletion: confirmed;
- duplicates after re-prove: confirmed from unconditional push;
- another user's deletion: confirmed and intended;
- already-finalized cleanup: confirmed safe because `finalizedWithdrawals[H]` remains true;
- gas amplification of portal finalization: absent;
- paid storage growth: possible, but already possible in v8 (`v8 OptimismPortal2.sol:465-472`) and has no eligible direct impact;
- naive off-chain “try index zero and stop” behavior: possible integration bug, not a contract invariant break. U21 docs expressly tell proof trackers to handle `WithdrawalProofDeleted` (`docs/public-docs/notices/upgrade-21.mdx:187-193`).

## Proof-submitter identity and attacker-controlled games

Anyone can prove anyone's real withdrawal. On OP Mainnet, type 9 is respected, its implementation is `0x19AF…3208`, and the creation bond is exactly 0.08 ETH at N-1, N, and later. Thus an attacker can create a candidate root containing a victim withdrawal and submit a proof before that bad game loses.

That primitive does not escalate:

- the cell key uses `msg.sender`, so attacker and victim cells are disjoint (`OptimismPortal2.sol:480-484`);
- default finalization uses the finalizer's address (`:496-498`);
- external finalization explicitly names a submitter (`:577-607`);
- the array is not consulted;
- deletion of the attacker's later-losing proof cannot alter the victim's mapping/timer.

Fork test `test_badSubmitterProofDoesNotBlockGoodSubmitterProof` writes a bad proof first in the discovery array, then a good proof. The good proof validates before and after deleting the bad cell.

Soneium's respected type 5/bond zero does not create a permissionless variant: `SuperPermissionedDisputeGame.initialize` requires `tx.origin == proposer` and immediately sets defender-wins (`SuperPermissionedDisputeGame.sol:51-72`).

## Exact N-1 to N and real cross-version evidence

Portal implementation changed from `0x100521…6748` v5.8.0 to `0xb20b23…9645` v6.1.0. Its v8/v9 storage-layout snapshots are identical, and raw portal slots 0, 50–63 were byte-identical across N. ASR changed v3.9.0 to v4.0.0; the only relevant raw write was the new ETHLockbox address packed into previously unused high bytes of slot 6. DGF implementation remained v1.6.1.

### Sample proof preserved exactly

Withdrawal `0x8df3…f241` was proven at block 26429408 before U21 by `0x6A9C…BDf2` against game `0xbEc6…B356`, timestamp `1794853991`. The mapping tuple and array entry are identical at N-1, N, and later. At N the real game is registered/proper/respected and in progress; deletion reverts.

### Strong cross-version finalization

Withdrawal `0x6d7c…74af4` was proven under v8:

- proof block 26377651;
- proof tx `0x0495619a…97b7`;
- submitter `0xBF8472…78E3`;
- game `0xFd0C…37D6`;
- timestamp `1794231107`, before U21 timestamp `1794871439`.

At N, portal v6.1.0 retained the tuple and the withdrawal was not finalized. It finalized successfully after U21 at block 26432294 in tx `0x734db37e…77af`, with `WithdrawalFinalized(success=true)`. At block 26433900 the replay flag is true. This is real deployed-bytecode evidence, not a mocked condition.

Types 0/1 were already unset at N-1 and remained unset. That affects only future creation. Existing clone code, factory registration, and `wasRespectedGameTypeWhenCreated` do not depend on the current implementation pointer.

Full reads are recorded in `mirror/lane-25/artifacts/CHAIN_READS.md`.

## Planned interop migration

The documented migration intentionally invalidates all prior proofs (`src/L1/opcm/OPContractsManagerV2.sol:280-287`; U21 notice `upgrade-21.mdx:62-68`). Mechanism:

1. deploy fresh shared lockbox, DGF, and ASR (`OPContractsManagerMigrator.sol:191-222`);
2. initialize the new ASR with the fresh DGF (`:246-263`); first ASR initialization sets retirement to the current timestamp (`AnchorStateRegistry.sol:124-132`);
3. atomically repoint each portal to the new ASR (`OPContractsManagerMigrator.sol:469-555`; `OptimismPortal2.sol:528-571`).

Old proof bytes remain. Nevertheless no old proof can survive:

- old games are absent from the new factory mapping, so registration fails;
- every old game was created before or at the new retirement timestamp, so retirement also fails;
- the new factory did not exist before the atomic transaction, so no user can pre-install a proof against one of its games;
- there is no cross-transaction interleaving inside migration.

After the transaction, users prove against new shared games. The same submitter overwrites the old cell. Old array entries remain, but all entries for the same address resolve to its current mapping cell.

The fork migration test uses deployed ASR code with the two decisive new-ASR properties (fresh empty factory and migration-time retirement) and confirms: old proof remains stored, `isGameRegistered=false`, `isGameRetired=true`, `isGameClaimValid=false`, finalization fails, and narrow deletion also fails until challenger/blacklist. This validates mechanism, not a vulnerability.

## Fork test inventory

All tests pass:

1. `test_exactNPreservesV8ProofAndInProgressCannotBeDeleted`
2. `test_challengerWinsDeletionIsPermissionlessAndLeavesArrayStale`
3. `test_blacklistedProofCanBeDeletedByAnotherUserWhilePaused`
4. `test_defenderWinsCannotBeDeleted`
5. `test_retirementAloneDoesNotAuthorizeDeletion`
6. `test_notRespectedBoundaryCannotDeleteWithoutPermanentInvalidation` (synthetic unreachable flip)
7. `test_unregisteredSyntheticEntryOnlyDeletesIfStatusIsChallengerWins` (synthetic provenance boundary)
8. `test_noCodeStoredGameRevertsEvenIfBlacklisted` (synthetic unreachable entry)
9. `test_crossVersionProofFinalizedUnderV9`
10. `test_deletingAlreadyFinalizedProofDoesNotClearReplayProtection`
11. `test_deleteFrontRunCannotChangeAnInvalidProofIntoAValidOne`
12. `test_badSubmitterProofDoesNotBlockGoodSubmitterProof`
13. `test_plannedMigrationMechanismRejectsAllOldFactoryProofsButDoesNotDeleteThem`
14. `test_realProofPackingMatchesSlot57Layout`

## Rejected hypotheses

- valid-later proof deletion: killed by permanent, narrow predicate (`REJ-2501`);
- bad proof overwrites/blocks victim: killed by per-submitter mapping and explicit selection (`REJ-2502`);
- finalize front-run/timer-reset grief: killed because proof was already permanently invalid and attacker cannot write victim cell (`REJ-2503`);
- stale-array portal DoS: killed by absence of on-chain iteration and pre-existing duplicate behavior (`REJ-2504`);
- U21 invalidates v8 proofs: killed by a real post-U21 finalization (`REJ-2505`);
- fake/no-code game exploit: killed by factory provenance; only unreachable cleanup denial remains (`REJ-2506`);
- retired/migrated stale proof freezes withdrawal: killed by overwriteable mapping and explicit re-proof design (`REJ-2507`);
- delete after finalization permits replay: killed by independent replay flag (`REJ-2508`);
- pause enables deletion: killed because pause is never read (`REJ-2509`);
- types 0/1 unset or Soneium type 5 create deletion path: killed by clone persistence and permissioned proposer (`REJ-2510`).

## Compositions worth a separate lane's attention

These are follow-ups, not candidates:

1. **Real integration behavior for stale/deleted entries.** Audit the production withdrawal relayer/SDK selection algorithm for “first array entry then stop.” The contract remains safe, but an off-chain client could self-inflict temporary failure if it ignores `WithdrawalProofDeleted`.
2. **Historical game-code survivability across all upgraded sibling chains.** OP Mainnet provenance is clean. A broad chain-history scan could confirm no accepted proof on Ink/Soneium/Unichain references an anomalous implementation whose `status()` can revert; this is the only route to the status-before-blacklist cleanup edge.
3. **Migration-day re-proof/indexer load.** The registry swap necessarily leaves all old discovery entries stale and all users re-prove. Validate that indexers replace mapping state by `(hash,submitter)` rather than treating array length as unique-proof count.

None changes the on-chain negative result.

