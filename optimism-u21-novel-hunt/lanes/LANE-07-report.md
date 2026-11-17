# LANE 07 — AnchorStateRegistry and dispute migration (output-root games → super-root games → shared registry)

Phase A (blind). Target v9 `ba6fcadb`, baseline v8 `f45a5ccf`. All state claims are reads on fork `l1` @ 26433900 (or `l1pre` /
the block-N fork where stated). Fork tests run the real deployed bytecode; the only privileged action simulated is the
planned, documented `OPContractsManagerV2.migrate` for OP Mainnet (10) + Unichain (130), executed as the real
ProxyAdminOwner Safe by DELEGATECALL (the Safe's code is swapped for a one-function delegatecaller).

**Result: no candidate.** Five primitives, eight rejected paths, one fork model of the migration. Nothing in this lane gives
a permissionless actor a way to make the portal accept an output root that the fault path did not have the chance to reject.

Files: `primitives/PRIM-0701..0705.md`, `rejected/REJ-0701..0708.md`, `test/poc/Lane07_{Migration,Probes,Boundary,Recon,Scan2}.t.sol`,
`evidence/lane07-forge-results.txt`, `evidence/lane07-onchain-reads.md`. Harness: `/home/user/u21-work/lane07`.

## 1. What game types 5 and 9 are (on chain)

- **Type 9 = SUPER_CANNON_KONA** → `SuperFaultDisputeGame` v0.8.0 at 0x19AF533C… (bytecode identical to the local v9 build).
  Permissionless, 0.08 ETH init bond, split depth 30, max depth 73, 3.5-day clocks, 3 h extension, MIPS64 1.10.1.
  CWIA args: creator ‖ rootClaim ‖ l1Head ‖ gameType ‖ extraData ‖ prestate ‖ vm ‖ ASR ‖ DelayedWETH ‖ l2ChainId(=0, enforced, L309).
  `extraData` **is** the super-root preimage (`0x01 ‖ uint64 timestamp ‖ n×(uint256 chainId ‖ bytes32 outputRoot)`), and
  `rootClaim == keccak(extraData)` is enforced at init (L278-279). `l2SequenceNumber()` is the timestamp read from those same
  bytes (L649-651), so there is no separate extraData↔claim binding to attack and no `challengeRootL2Block` equivalent is needed.
- **Type 5 = SUPER_PERMISSIONED** → `SuperPermissionedDisputeGame` v1.1.0 at 0x5C3eb47c…: no bonds, no VM, no challenger;
  `tx.origin == proposer`, status DEFENDER_WINS and `resolvedAt = createdAt` at creation, invalidation only by Guardian blacklist.
- v8→v9 `GameTypes` diff: only `clearedGameTypes()` added (types 0,1,8,4,5,9,10 — what migrate() clears on a legacy factory).
  `isSuperGame` = {4,5,7,9,10}. SFDG, PermissionedDisputeGame, Hashing, Encoding: zero diff v8→v9; FDG/DGF/LibGameArgs: formatting only.
- OP Mainnet respected type 9 **before** U21 as well (ASR slot 6 at N-1). U21 changed, in this lane's scope, exactly:
  ASR pause/guardian source (systemConfig → ethLockbox, one new storage field), `gameArgs(9)` prestate, `gameArgs(5)` proposer.
- Who creates games: last 99 games are all by the proposer EOA (old 0x473300df…, new 0xc27ba3E0… from idx 21379), none
  challenged. Creation is permissionless for type 9 (fork test), tx.origin-gated for type 5, impossible for legacy types.

## 2. State machines

**Registration.** `DGF.create(type, root, extra)`: impl ≠ 0, `msg.value == initBonds[type]`, UUID = keccak(abi.encode(type,
root, extra)) unused, clone = CREATE2(factory, uuid, impl ‖ creator ‖ root ‖ parentHash ‖ type ‖ extra ‖ gameArgs[type]),
`initialize{value}`, then `_disputeGames[uuid]` and `_disputeGameList.push`. For super games the UUID is a function of the
super root alone (PRIM-0703).

**Validity (ASR v4.0.0).**
- registered: `factory.games(game.gameData()).proxy == address(game)` — binds game→factory by address; does **not** bind game→ASR.
- respected: `game.wasRespectedGameTypeWhenCreated()` (self-reported, set at init from the game's own ASR).
- retired: `createdAt <= retirementTimestamp`; blacklisted: mapping, Guardian-only, irreversible.
- proper = registered ∧ ¬blacklisted ∧ ¬retired ∧ ¬paused. finalized = resolved ∧ now − resolvedAt > 302400.
- claimValid = proper ∧ respected ∧ finalized ∧ DEFENDER_WINS.
- `setAnchorState(g)` (anyone): claimValid(g) ∧ `g.l2SequenceNumber() > current anchor seq`. One anchor for all game types; the
  comparator is unit-less (PRIM-0702). `getAnchorRoot()` keeps returning the anchor game's claim even if it is later retired/blacklisted.

**Portal.** prove: game by factory index; proper ∧ respected ∧ status ≠ CHALLENGER_WINS ∧ now > createdAt; root =
`isSuperGame(game.gameType()) ? game.rootClaimByChainId(systemConfig.l2ChainId()) : game.rootClaim()`; then
`root == hashOutputRootProof(proof)` and the trie proof. finalize: stored game must be claimValid in the portal's **current**
ASR + 7-day proof maturity. deleteProvenWithdrawal: stored game CHALLENGER_WINS or blacklisted in the current ASR.

**Invariants checked and found to hold**
- I1 every game the portal can use was created by the factory of the portal's current ASR (index lookup + address identity).
- I2 a proven withdrawal is bound to an output root that hashes to the selected claim on every path (L448).
- I3 chain selection is by `SystemConfig.l2ChainId()` (10/57073/1868/130 on chain), never by caller input.
- I4 a legacy (block-number) game cannot replace a super (timestamp) anchor on these chains (numeric, not typed).
- I5 after migrate(): {games usable by the portal} ∩ {games created before migrate()} = ∅.

## 3. The super-root proof path (brief §4)

*Who supplies the preimage / what is verified.* The game creator supplies it as `extraData`; L1 checks version byte, length
(9 + 64·n, n ≥ 1) and `keccak == rootClaim`. Nothing else: no ordering, no uniqueness, no membership in a dependency set, no
upper bound on the timestamp. `rootClaimByChainId` returns the **first** matching entry. On a fork I created, as a random
account, games with unsorted lists, two entries for chain 10, a canonical list followed by a second chain-10 entry, and a
chain-57073-only list in the (modelled) OP+Unichain shared factory: all are registered and "proper" (and, by L339-340, respected).

*What the fault proof guarantees.* The kona-interop client never decodes the claim. It reads the chain-id list from the agreed
pre-state (boot.rs L118-125), builds the next super root by pairing its own derived blocks with the pre-state's chain ids
(pre_state.rs L86-98) and sorting (root.rs L26), and compares keccak commitments (transition.rs L230, consolidate.rs L158).
Hence, for any game that the fault path lets stand, `extraData` equals the canonical encoding with exactly the anchor
lineage's chain ids in ascending order; a duplicate or foreign list is just a wrong hash. Not enough L1 data at the game's
`l1Head` → `keccak("invalid")`, which L1 refuses as a root claim. So first-match is safe **given** a canonical anchor root.
The anchor root's shape is validated nowhere on chain; it enters only through governance (`startingAnchorRoot` in OPCM
upgrade/migrate). Assumption not re-derived here: prestate 0x03e5a548… is built from this source (U21 notice: kona-client v1.9.0).

*Non-interop chain respecting a super type.* INTEROP is false on all four chains; the portal does not look at INTEROP for
proving. The "dependency set" is whatever chain ids the ASR anchor root contains — a single entry on OP/Ink/Unichain/Soneium.
`rootClaimByChainId(10)` returns the entry; `(130)` reverts `UnknownChainId` on an OP game.

*Type confusion.* One prove function; branch on the game's own immutable type; binding always applied (REJ-0703).

*Old games.* Types 0/1/8 cannot be created (no impl). ≈10k type-0/8 games created after 2025-07-24 remain claim-valid in the
same ASR and are still accepted as proof targets; this set is unchanged by U21 (ASR storage diff N-1→N is one field). They
cannot become the anchor. Whether any of them carries a wrong root cannot be decided from L1; none was created by a
non-proposer in the ranges read (PRIM-0702, REJ-0704).

*Anchor.* Shared across types; only claim-valid games move it. Type-5 games on OP/Ink/Unichain are not respected, so they
cannot move the anchor that type-9 games start from; on Soneium type 5 is the only type.

## 4. Planned OP Mainnet + Unichain migration (brief §5, orchestrator addendum 2)

Modelled with the real OPCM 9.0.3 against today's state (`Lane07_Migration.t.sol`, 5 tests, all pass):
- `migrate()` runs to completion today with chains [OP, Unichain], type 9 (current prestate, 0.08 ETH) + type 5, respected 9.
- Shared lockbox ends with 200,807 ETH; both portals point at one new ASR + DGF; new ASR `retirementTimestamp = block.timestamp`.
- The three proxies are CREATE2-deployed by the Safe account itself (its nonce rises by exactly 3) with a salt containing
  `block.timestamp`: nothing to squat or pre-register (REJ-0705).
- Pre-positioning today: an attacker game + proof on the legacy OP factory (which would pay 1000 ETH if nobody challenged
  it — control test) is dead after migrate(): `OptimismPortal_InvalidRootClaim`, although the legacy ASR still reports the
  game claim-valid. Re-creating the same UUID in the shared factory gives a different clone; the legacy game stays unregistered.
  A legacy game with a timestamp 60 days ahead (L1 allows it) changes nothing.
- Two-chain root `[(10,A),(130,B)]`: OP portal proves only under A, Unichain portal only under B.
- A game created in the migration block is retired (`createdAt <= retirementTimestamp`) — only affects a proposer that
  proposes in that same block.
- Legacy game bonds remain claimable after migrate() (unlock + withdraw through the re-pointed legacy DelayedWETH).

## 5. Answers to the orchestrator's relayed questions (PRIM-0903 / PRIM-0904, verified independently)

- Facts in PRIM-0903 confirmed by my own reads: identical type-9 impl + prestate + l2ChainId 0 on OP/Ink/Unichain, only ASR and
  DelayedWETH differ; first-match; `isGameRegistered` has no ASR check.
- (1) kona-interop neither rejects nor canonicalises a duplicate/foreign list — it never sees the list; the claim loses on
  hash mismatch. A DEFENDER_WINS game with the attacker's chain-10 entry first requires an unchallenged game or a malformed
  governance anchor (REJ-0701).
- (2) A game of factory A cannot be used at portal/ASR B, today or after migrate(): index lookup in B's factory + address
  identity in `isGameRegistered` (REJ-0702). The missing ASR check would only matter for one factory serving two ASRs; the
  one historical instance per chain (2025-07-24) is covered by the retirement cut — sampled, not exhaustively scanned.
- PRIM-0904's topology (shared DelayedWETH = OP's, legacy ASR/DGF/DelayedWETH orphaned but live) matches what my test measured.

## 6. Smaller observations (not findings)

- SFDG 0.8.0 `closeGame` checks `paused()` before the "already closed" early return (L993-1001); FDG 2.4.2 does it after.
  While paused, `claimCredit` on an already-closed super game reverts at the unlock step too. Temporary, and withdraw is
  pause-gated in DelayedWETH anyway.
- On OP Mainnet the type-5 `proposer` (tx.origin auth) is the same EOA that originates the type-9 proposals, both before U21
  (0x473300df…) and after it (0xc27ba3E0…, from idx 21379) (PRIM-0705).
- Trace capacity is 2^23 L2 seconds (≈97 d) from the game's start anchor (128 steps per timestamp); anchor lag today 7.05 d.

## 7. Not done / open

- No exhaustive scan of the ~10k non-retired legacy games per chain (upstream archive RPC returned HTTP 429 under bulk reads;
  I stopped the scans so other lanes were not starved). Covered: bisection of the retirement cut, 18 sampled games per chain
  (OP, Unichain), the last 99 OP games. Not covered: Ink and Soneium boundaries; non-proposer creators in OP idx 20095-21289.
- Prestate hashes were not rebuilt; kona source was read at the v9 tag only. Why U21 bumped the prestate (v1.9.0 changelog)
  is a novelty-phase question; the 74 in-flight games created under the Upgrade-20 prestate are all honest-proposer games.
- op-proposer / op-supernode behaviour (which timestamps get proposed, anchor staleness at migration) was not analysed beyond
  the trace-capacity bound.
- The real migration task's `startingAnchorRoot` does not exist yet; its preimage shape is the single unvalidated input.

## 8. Compositions worth another lane's time

1. **Anchor-root shape at migrate()/upgrade()** (signer-review, not permissionless): L1 accepts any non-zero root; the program
   inherits the chain list from it forever; the portal takes the first match. A check that the preimage is exactly
   `[(10,·),(130,·)]` ascending belongs in the superchain-ops validation.
2. **Respected-type fallback to 5 on a type-9 chain**: the same EOA that originates hourly proposals becomes sole root
   authority under `tx.origin`; worth reviewing with the Guardian/incident-response lane together with EIP-7702 delegation of
   that key and the 3.5-day blacklist window (finality counts from creation, not from a resolution).
3. **Legacy valid-set hygiene**: `retirementTimestamp` has not moved since 2025-07-24 on any of the four chains, across two
   game-type switches and two prestate changes. An exhaustive off-line audit of non-retired legacy games (creator ≠ proposer,
   ASR ≠ current) with an unthrottled archive node would close PRIM-0702 / REJ-0702 item 4.
