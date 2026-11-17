# CLOSURE MAP

A path is CLOSED only with a deterministic failing experiment, an exact unreachable precondition,
a scope exclusion, a known-root-cause match, or a proved invariant barrier. Reopen only when new
historical evidence changes a precondition, a state interpretation or a reachable composition.

Paths below refer to `/home/user/Tracking_Body/optimism-u21-novel-hunt/` (PASS A) unless prefixed.

## Closed in PASS A (U20 -> U21 and live U21 state)

| # | Path | Closure type | Killing fact | Evidence | Reopen if |
|---|---|---|---|---|---|
| C1 | U21 upgrade execution left a wrong/stale/uninitialised state | failing experiment | replay on N-1 == block N on 339 slots; 41 proxies initialised, 11 impls locked; 68/283 getters consistent | lanes 01, 21, 02, 22 | a chain with a different pre-U21 history is found (PASS B chain profiles) |
| C2 | Legacy storage slot reinterpreted by v9 | failing experiment | junk in every legacy slot leaves 16 getters + a live deposit unchanged on all four chains | lane 02 `U21StorageReinit.t.sol` | a slot was non-zero only on a chain not tested, or a pre-v7 field is found at a reused slot |
| C3 | ETH conservation portal/lockbox/messenger | invariant barrier | per-lockbox delta == locked - unlocked exactly; nested finalize reverts `NoReentrancy`; relock exact | lanes 03, 23 | pre-U16 custody residue (portal-held ETH, failed-withdrawal ETH) is found on any chain |
| C4 | `deleteProvenWithdrawal` deletes a proof that could finalize | invariant barrier | predicate is CHALLENGER_WINS or blacklisted, both permanent; 44 real proofs none deletable | lanes 05, 25, 12 | a stored proof references a non-game / legacy address (PASS B: pre-fault-proof proofs) |
| C5 | Double execution of a withdrawal (submitters, re-prove, delete, replay) | invariant barrier | `finalizedWithdrawals[hash]` is hash-global; messenger mappings written on every non-reverting exit | lanes 04, 24, 08 | a historical hash/nonce domain change makes two hashes describe one economic withdrawal |
| C6 | Finalized-without-record on the messenger path under v9 | failing experiment | gas sweeps (192 + 500-gas scan + binary search) find none; v8 had it for 100 kB payloads, v9 fixes it | lanes 08, 12, 31 | Amsterdam activates before L2CDM is upgraded (not reproducible locally) |
| C7 | Third party freezes a victim's messenger withdrawal via the new revert | unreachable precondition | first write to either messenger mapping needs the victim's own withdrawal | lane 04 REJ-0403 | — |
| C8 | Pause does not cover a value exit | failing experiment | with lockbox identifier paused every ETH/ERC20/ERC721 exit reverts on all tested paths | lanes 06, 26 | a chain whose pause pointers diverge (history) |
| C9 | Unexpected lockbox authorization / cross-portal leak today | failing experiment | cross product over 4 chains + Base is diagonal; 16 `PortalAuthorized`, all own portal | lanes 09, 29 | single public RPC answered the event history: re-check with a second source |
| C10 | Pre-positioning before the planned `migrate` (CREATE2 squat, pre-registered games, surviving proofs) | unreachable precondition | real flows deploy from the Safe (OPCM -> Utils by DELEGATECALL, `OPContractsManagerUtilsCaller.sol:257`), salt includes `block.timestamp`; proofs die with `InvalidRootClaim` after migrate | lanes 07, 09, 27, 29; orchestrator check of PRIM-2104 | migrate calldata/tooling differs from the deployed OPCM path |
| C11 | Super-root type confusion / cross-factory game reuse | unreachable precondition | one prove function branching on the registered game's own type; games looked up by index in the portal's factory | lanes 07, 27 | — |
| C12 | Non-canonical super root (duplicate/unsorted chain entries) wins | invariant barrier (standard fault-proof model) | wins only if unchallenged 3.5 days; kona inherits the chain list from the anchor pre-state | lanes 07, 27 | a kona soundness difference in the OLD prestate (open lead L1) |
| C13 | Invalid third-party legacy game still claim-valid on OP Mainnet | failing experiment | full census: one third-party DEFENDER_WINS game (idx 19206), root == header-derived output root | `evidence/op-mainnet-games-census.txt` | other chains (Ink, Soneium, Unichain not scanned); official proposer's ~10.2k roots not recomputed |
| C14 | PRIM-2104 CREATE2 occupation via standalone Utils | unreachable precondition | attacker-reachable deployer is the Utils singleton; legitimate flows deploy from the Safe/OPCM | orchestrator, `OPContractsManagerUtilsCaller.sol:257` | a future flow CALLs Utils instead of delegatecalling it |
| C15 | Missing game/registry binding in `isGameRegistered` (removed after v6) lets an old-registry game pass the current registry | failing experiment (full population) | all 11561/1718/5696/11505 non-retired games on OP/Ink/Soneium/Unichain are bound to the portal's current ASR; all older-registry games predate the retirement cut | `evidence/ORCH-registry-binding-check.md`, `evidence/F5/registry-binding-check.json` | retirement timestamp lowered, new ASR without retirement bump, or a foreign-bound implementation registered |

## Open (not closed) after PASS A

| # | Lead | Why open |
|---|---|---|
| L1 | Old-prestate type-9 games judged by the pre-v1.9.0 kona program | kona delta never diffed |
| L3 | Forced-fail of messenger withdrawals (ETH parked in L1CDM) x replay targets / pause / migration | benign alone; compositions not run |
| L4 | Trojan super-root game as sustained withdrawal-delay engine | impact not priced against the Immunefi impact list |
| L5 | EIP-7825 tx gas cap x v9 150k reserve x replay: undeliverable band | not computed |
| L6 | Deposit gas regression at block N (+730k @ 120 kB) | root cause unknown |
| L7 | `tx.origin`-authorised type-5 games, cross-type anchors | proposer tx call graph not traced |
| L8 | Migration residue (orphaned legacy ASR/DGF/WETH, sticky authorizations, `clearedGameTypes`) | only partially composed |
| L9 | Per-chain L2 ETH liability vs lockbox balance before pooling | not checkable from L1 |
| H* | Everything created before v7.0.0 and consumed by v9 | PASS B/C — not started |
