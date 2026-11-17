# LANE 24 — Withdrawal Finalization and Replay

Mirror of lane 04, independently executed. Pinned v9 commit: `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`. Upgrade boundary: Ethereum blocks 26,430,858 / 26,430,859; later state block 26,433,900.

## 1. Outcome

**No bounty candidate promoted.** Invariant B (at-most-once economic execution) held across alternate submitters, games, deletion, migration-shaped state, messenger replay, and v8→v9 storage continuity.

The literal broad form of invariant A has one reproducible exception: a failed *direct, non-messenger* contract withdrawal is globally finalized and its ETH is re-locked. Because the external-proof entry point is permissionless, a third party can choose a just-sufficient outer gas cap and force that outcome when the encoded gas floor is below the target's real requirement. This is PRIM-2401. It is explicitly documented/covered as intended Portal behavior, requires the originator to use the direct path with an insufficient floor (or a target whose needs later rise), and predates U21. Honest score 3; rejected as REJ-2401.

For genuine messenger withdrawals, v9 closes the dangerous state: if the Messenger reverts before recording success/failure, the Portal rolls the whole finalization back. If the Messenger returns normally without delivering, it has recorded `failedMessages`, so application replay remains available.

## 2. Scope and evidence standard

Reviewed line-by-line and diffed v7 `a7c88c8…778ab`, v8 `f45a5ccf…30b7`, and v9 `ba6fcadb…31e3`:

- `L1/OptimismPortal2.sol`
- `universal/CrossDomainMessenger.sol`, L1/L2 specializations
- `libraries/SafeCall.sol`, `GasConstants.sol`, `Hashing.sol`, `Encoding.sol`
- `dispute/AnchorStateRegistry.sol`
- v9 Portal tests around direct failure, messenger rollback, and external proofs.

The v9 source contains one `proveWithdrawalTransaction` entry point (`OptimismPortal2.sol:390-492`) and two finalization entry points: the caller-proof wrapper and the public external-proof form (`:494-498,574-666`). All three are represented below.

No prior audit/public finding was consulted. Claims are tied to pinned source lines, passive state reads, real logs/calldata, or deployed-code fork tests. Full artifacts are under `mirror/lane-24/`.

Relevant deployed boundary:

| Contract | N-1 | N / later |
|---|---|---|
| Portal `0xbEb5…106Ed` | v5.8.0 / `0x1005…6748` | v6.1.0 / `0xb20b…9645` |
| L1 Messenger `0x25ac…5fA1` | v2.11.1 / `0x59D4…86f0` | v2.13.0 / `0x7d4E…9448` |

Portal wiring remained SystemConfig `0x2290…B290`, ASR `0x23B2…D113`, Lockbox `0x322b…4D43`; ETH_LOCKBOX enabled, CGT/INTEROP disabled, all relevant pause reads false. See `mirror/lane-24/U21_PROXY_IMPLEMENTATION_MAP.md` and `CHAIN_STATE_READS.md`.

## 3. State variables and identities

For withdrawal transaction `w`:

```
H = keccak256(abi.encode(nonce, sender, target, value, gasLimit, data))
P[H][s] = (disputeGame, proofTimestamp) for proof submitter s
F[H] = Portal finalized bit, global across every submitter/game
L = Portal transient l2Sender reentrancy state
```

The hash commits every economically relevant outer field (`Hashing.sol:104-109`). Proofs are per submitter, but finalization is per hash (`OptimismPortal2.sol:61-62,94-116`).

For encoded cross-domain message `m`:

```
M = keccak256(encodeRelayMessage(nonce,sender,target,value,minGas,message))
MF[M] = Messenger failed-at-least-once bit
MS[M] = Messenger successfully-executed bit
```

The failed bit is intentionally monotonic; the success bit is the terminal at-most-once gate (`CrossDomainMessenger.sol:119-142,239-306`).

## 4. Withdrawal state machine

### States

| State | Predicate | Economic meaning |
|---|---|---|
| U | `P[H][s].timestamp=0` for chosen `s`, `F[H]=false` | No usable proof for that submitter |
| PI | proof exists but maturity/game claim guard false | Proven, not finalizable now |
| PR | proof mature and current ASR says claim valid, `F[H]=false` | Ready through that submitter |
| X | transient `L != DEFAULT` during target call | Finalization executing; nested finalization blocked |
| FD | `F[H]=true`, target call succeeded | Outer withdrawal delivered |
| FF | `F[H]=true`, direct non-messenger target call failed | Terminal Portal failure; value re-locked if nonzero |
| FM | `F[H]=true`, Messenger returned normally with `MF[M]=true,MS[M]=false` | Outer terminal; inner message replayable |
| MS | `F[H]=true`, `MS[M]=true` | Message economically executed once |

PI/PR are views over mutable current guards, not distinct stored enums.

### Transitions

| Transition | Caller | From → to | Guards / effects |
|---|---|---|---|
| Prove | anyone; record owned by `msg.sender` | U/PI/PR → PI | Current unpaused/safe target/feature mode; factory game is proper and creation-respected; not challenger-wins; valid output/withdrawal proof. Writes `P[H][caller]`, appends caller (`OptimismPortal2.sol:390-492`). |
| Re-prove | same or another submitter | PI/PR → PI | Same proving guards. Same key overwrites game/timestamp and resets timer; another submitter creates an independent record (`:480-487`). No check of `F[H]`. |
| Delete proof | anyone | PI/PR → U for selected key | Game challenger-wins or blacklisted in **current** ASR. Deletes only `P[H][s]` (`:707-728`). |
| Standard finalize | anyone | PR → X | Uses caller as proof submitter (`:494-498`). |
| External-proof finalize | anyone | PR → X | Caller supplies any `s`; current pause/CGT/reentrancy/target/checkWithdrawal guards. Sets `F[H]=true`, unlocks value, sets `L=sender`, then calls target (`:574-630`). |
| SafeCall floor failure | finalizer | X → PR (whole tx reverts) | `callWithMinGas` reverts before CALL; all Portal/Lockbox writes roll back (`SafeCall.sol:121-154`). |
| Target success | finalizer | X → FD | `L` reset, event success=true; value remains delivered (`OptimismPortal2.sol:627-665`). |
| Direct target false | finalizer | X → FF | If not estimation origin and encoded sender is not L2 messenger: event false, nonzero ETH re-locked, `F[H]` stays true (`:632-665`). |
| Genuine messenger pre-record revert | finalizer | X → PR (whole tx reverts) | Encoded sender L2 messenger + Portal SafeCall false → `L1CDMCallFailed`; proof remains (`:639-653`). |
| Messenger records application failure | finalizer | X → FM | Messenger sets `MF[M]=true` and returns; Portal call itself is true and commits `F[H]` (`CrossDomainMessenger.sol:256-306`). Messenger retains any value for replay. |
| Replay failed message | anyone | FM → FM or MS | Requires `MF=true`, caller is not authenticated other messenger, `msg.value=0`, `MS=false`; failure stays replayable, success sets MS (`:239-306`). |
| Attempt replay after success | anyone | MS → MS | Reverts because `MS=true`, even though MF may remain true (`:250-254`). |

`finalizedWithdrawals` is set before external effects but EVM atomicity removes it on every outer revert. There is no partially committed Portal state.

## 5. Mutable-current guard audit

| Guard read later | Mutable source | Earlier object affected | Consequence of change |
|---|---|---|---|
| Portal pause | current ETHLockbox/Superchain config (`OptimismPortal2.sol:305-308,824-829`) | unproven/proven withdrawal | Prove/finalize temporarily reverts |
| ETH_LOCKBOX / CGT / INTEROP | current SystemConfig features (`:406-409,534-537,586-589,820-842`) | earlier withdrawal | Value finalization can become disallowed; current mainnet has Lockbox only |
| Unsafe target | current Portal + current Lockbox addresses (`:401-404,598-601,845-849`) | withdrawal created earlier | Migration can make a formerly safe address unsafe; privileged configuration |
| ASR pointer | Portal storage, privileged migration (`:528-571`) | every old proof | Finalization validates through new registry; re-proof required by design |
| Factory registration | current ASR factory mapping (`AnchorStateRegistry.sol:215-237`) | previously selected game | Must still map game data to same proxy |
| Blacklist | current ASR mapping (`:249-253,292-295`) | existing proof/game | Permanently invalidates claim; permits deletion |
| Retirement timestamp | current ASR timestamp (`:256-263,297-300`) | existing proof/game | Can retire game; re-proof against newer game |
| ASR pause | current ASR pause (`:302-305`) | existing proof/game | Claim temporarily improper |
| Respected game type | game creation snapshot (`:239-247`) | game | **Not** current type setting; stored `wasRespected…` bit avoids retroactive type switch |
| Game status/resolution/finality | live game + immutable delay (`:265-270,310-350`) | existing proof/game | Normal progression to valid/invalid terminal game |
| Proof timestamp | stored record; overwritten by re-proof | one submitter record | Maturity timer resets (`OptimismPortal2.sol:480-487,696-699`) |
| Messenger pause/auth/unsafe target | current L1 Messenger dependencies (`CrossDomainMessenger.sol:220-254`; `L1CrossDomainMessenger.sol:135-142`) | earlier message | Pre-record revert; v9 Portal rollback protects genuine messenger withdrawal |
| Relay gas constants | current implementation code | earlier message gasLimit | v9 memory/local budgets govern execution; failed record or Portal rollback preserves retry |

`deleteProvenWithdrawal` also uses the current ASR blacklist. After an ASR pointer swap it may not recognize an old registry's blacklist, but re-proving overwrites the key without requiring deletion. The append-only submitter array is not consulted on-chain during finalization.

## 6. Invariant A — no finalized economic non-delivery without replay

### Genuine messenger path: held

Two exhaustive cases exist after Portal SafeCall:

1. Messenger returns normally. If its application call failed or its internal gas/reentrancy check failed, it set `MF[M]=true` before returning (`CrossDomainMessenger.sol:256-306`). Portal may finalize, but anyone can replay the message.
2. Messenger reverts before recording. Portal sees false, recognizes encoded L2 messenger sender, and reverts the whole finalization (`OptimismPortal2.sol:639-653`). `F[H]` remains false.

Fork tests prove both (`tests/WithdrawalFinalization24.t.sol:359-428`). An actual v8 failed message retained `MF=true,MS=false` across U21 and its exact calldata executed through v9, re-emitting failure while retaining replay (`:455-476`).

The sender-only check is sufficient for authentic flow: `sendMessage` always directs `_sendMessage` to `otherMessenger` (`CrossDomainMessenger.sol:178-190`), and L2 Messenger initiates that withdrawal through the message passer (`L2CrossDomainMessenger.sol:92-106`). Synthetic sender/target mismatches cannot be created by the authenticated messenger path.

### Direct Portal path: literal exception, rejected as intended

Non-messenger target false is terminal FF. Deployed fork reproduction found an outer-success/inner-failure window at 350,000 gas for a target needing 260,000 while the encoded floor was 30,000. A third party used another submitter's proof through the external-proof entry point; the target received no ETH, `F[H]=true`, and the 1 ETH was re-locked. Adequate gas delivered the equivalent withdrawal (`tests/WithdrawalFinalization24.t.sol:275-335`).

Who is harmed: the owner/recipient of a direct L2→L1 contract withdrawal whose encoded minimum is below current target needs. The L2-side ETH has been withdrawn/burned while the L1 backing returns to protocol custody, and Portal offers no replay. EOAs and contracts whose execution fits the floor are unaffected. Higher-level replayable wrappers may recover by design.

Why no candidate: the code expressly limits rollback to messenger origin and says other replayability belongs in contracts above Portal (`OptimismPortal2.sol:639-657`); v9 tests deliberately assert direct finalized failure (`test/L1/OptimismPortal2.t.sol:1648-1719`). This is a longstanding documented semantic plus victim-selected direct path/floor, not a novel U21 vulnerability.

### Return/gas edge cases

- Return bomb: no returndata copied by Portal SafeCall (`SafeCall.sol:161-169`); fork passed.
- Exactly insufficient SafeCall floor: library reverts, so F/unlock roll back; retry survives.
- Value to nonexistent account today: v9's 183,600 reserve is conservative because Amsterdam is inactive. Low gas reverts atomically; adequate gas delivered to `codehash=0`. Existing empty-code accounts have `keccak256("")`, not zero (`SafeCall.sol:119-135`; fork tests `:192-224`).
- Amsterdam future: not locally reproducible. No current exploitability claim.

## 7. Invariant B — no double economic execution

Held in every tested composition:

- alternate submitters/games: one global `F[H]` (`OptimismPortal2.sol:671-679`);
- proof deletion/recreation: cannot clear F;
- re-proof after maturity: resets only selected proof timer, not F;
- standard vs external proof: both converge on same internal function/bit;
- messenger failed then success: MF remains true, but MS blocks another call (`CrossDomainMessenger.sol:239-254,288-293`);
- Messenger and Portal reentrancy: transient sender guards and post-call success assertion;
- v8/v9 storage: layout snapshots identical; real proof/message bits retained exactly.

Fork test with two real finalized games and two submitters executed the target once; alternate finalization reverted (`tests/WithdrawalFinalization24.t.sol:478-495`). Messenger failure→success executed application once; later messenger and Portal replays both reverted (`:359-399`).

No economically equivalent alternative hash was found. Changing any outer withdrawal field changes H; changing any message nonce/sender/target/value/minGas/data changes M. An authenticated L2 Messenger increments its nonce and cannot emit two different withdrawals for one message without creating distinct L2 actions.

## 8. Cross-version findings

### Proof proven under v8, v9 finalization

Real proof tx `0xe7d3…c089` at block 26,429,992 retained the same `(game,timestamp)`, submitter count, and false finalized bit at N-1, N, and later. It is currently unresolved, not migration-invalid. v8/v9 Portal storage-layout snapshot hashes are identical. Full decoded struct/read set: `mirror/lane-24/REAL_WITHDRAWAL_EVIDENCE.md`.

### v8 failed messages under v9

Real v8 message `0x9546…11312` remained `failed=true,successful=false` through U21. Exact replay through deployed v9 ran safely and re-recorded failure because its application still rejected. Synthetic unchanged-slot test showed a v8 failed bit can also transition to v9 success; MS then blocks further execution (`tests/WithdrawalFinalization24.t.sol:430-476`).

### Historical v8 pre-record failure hypothesis

Log scan covered the full Portal v5.8.0 deployment (and earlier margin): blocks 25,900,000–26,430,858, 2,508 finalizations, one `success=false`. That sole event was a version-0 message whose legacy oldHash already had `successfulMessages=true`; no economic delivery was missing. The v1 hash having neither bit was therefore benign. See REJ-2409 and `REAL_WITHDRAWAL_EVIDENCE.md`.

This is the strongest deployed-state falsification of a latent v8→v9 stranded withdrawal. The theoretical v8 behavior existed, but no affected production instance appeared in the complete observed window, and v9 prevents new ones.

## 9. Fork matrix

Seventeen tests passed against deployed proxies, covering EOA/contract, zero/nonzero value, revert, gas window, return bomb, sender-only directions, Messenger record/rollback/replay, multiple games/submitters, deletion/recreation, real v8 proof, synthetic v8 failed storage, and real v8 failed replay. Exact results and methodology boundaries: `mirror/lane-24/FORK_TEST_RESULTS.md`.

Synthetic arbitrary withdrawals install only a proof record; all Portal/ASR/Game/Lockbox/Messenger code and configuration remain deployed state. Findings are not presented as Merkle-proof bypasses.

## 10. Rejected ideas and candidate scoring

| ID | Result / killing fact |
|---|---|
| REJ-2401 | Direct external-proof gas grief reproduced, but explicit intended direct semantics + inadequate floor; score 3 |
| REJ-2402 | Alternate proofs converge on hash-global finalized bit |
| REJ-2403 | Deletion/re-proof never clears finalized bit |
| REJ-2404 | Normal Messenger non-delivery records failed; pre-record revert triggers Portal rollback |
| REJ-2405 | Sender-only mismatch is synthetic; authentic L2 Messenger fixes target to otherMessenger |
| REJ-2406 | Today-only 183,600 over-reserve reverts atomically; adequate gas succeeds |
| REJ-2407 | Current-registry invalidation is recoverable by re-proof and documented for migration |
| REJ-2408 | Return bomb copies no returndata; reentrancy guard holds |
| REJ-2409 | Only historical Portal false event was an already-delivered legacy duplicate |
| REJ-2410 | Persistent failed bit cannot bypass successful bit |

No `CAND-24xx` file was created.

## 11. Compositions deserving follow-up

1. **Direct external proof + dynamically rising target gas.** Although documented, review higher-level bridges/wrappers for any route that emits a direct Portal withdrawal with a low fixed floor and no application replay mechanism. That removes the “victim chose the unsafe direct path” kill fact.
2. **Amsterdam activation boundary.** Re-run the same value/new-account and Messenger all-gas-consuming cases on an Amsterdam-capable EVM. Validate the 183,600 state charge, 135k post-call reserve, memory-copy-before-check, and baseGas slack together; current Forge cannot establish future execution.
3. **Migration + target/config identity.** Check orchestrator sequencing for a new Lockbox address colliding with an already-created withdrawal target and for off-chain finalizers choosing stale append-only proof submitters after ASR migration. Presently privileged/by-design, but a wrapper or automation layer could turn it into user impact.

## 12. Final conclusion

U21's v9 messenger rollback preserves a legitimate Portal replay path precisely when the L1 Messenger fails before recording its own replay state. When Messenger state is recorded, replay remains within Messenger and its success bit enforces once-only execution. Hash-global Portal finalization defeats every alternate proof/game path tested. The only actual finalized non-delivery primitive is the explicitly retained direct-withdrawal behavior, which is real but not a defensible novel bounty finding under this engagement's scoring rules.
