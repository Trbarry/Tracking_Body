PRIM-ID: PRIM-F4-01
Title: U20 re-initialised the live AnchorStateRegistry IN PLACE and changed the UNIT of `startingAnchorRoot.l2SequenceNumber`
  (slot 4: L2 block number -> super-root timestamp) without bumping `retirementTimestamp`, so output-root games and
  super-root games are compared in one permissionless predicate (`setAnchorState`)
Earliest semantic ancestor: v4.0.0 `src/dispute/AnchorStateRegistry.sol` (slot 3-4 `startingAnchorRoot`, written once by
  `initialize` at U16 22990599 = (0xfce6d556…, 138,585,637), an OP Mainnet L2 block number).
Current consumer: v9.0.0 `AnchorStateRegistry.setAnchorState` (`src/dispute/AnchorStateRegistry.sol:357-372`:
  `isGameClaimValid(_game)` then `_game.l2SequenceNumber() <= anchorL2BlockNumber` revert); `getAnchorRoot()` read by
  every new game as its starting root.
Releases crossed: v4.0.0 (layout, U16) -> v8.0.0 (U20 re-initialisation with a super root, type 9) -> v9.0.0 (U21).
Chains affected: OP Mainnet, Ink, Unichain (respected type 9), Soneium (type 5) — all re-initialised at U20.
Source contracts + functions: ASR proxy 0x23B2C62946350F4246f9f9D027e071f0264FD113 (OP); `initialize`,
  `setAnchorState`, `isGameClaimValid`, `isGameRetired`; FaultDisputeGame / SuperFaultDisputeGame `l2SequenceNumber()`.
Persistent object or state: ASR slot 3 `0xfce6d556…` -> `0xbd4aeba9…`, slot 4 `0x0842a625` (138,585,637) ->
  `0x6a9f9367` (1,788,842,855 = 2026-09-08 04:47:35 UTC), slot 2 anchorGame `0xe54bc554…` -> 0, slot 6 respected type
  8 -> 9 with retirementTimestamp 1753379243 unchanged (cast storage @26048618 / @26048619, `evidence/F4/trace/26048619-diff.json`).
  Population of output-root games created under the old unit that remain claim-valid (not retired).
Trigger: anyone calls `setAnchorState(g)` with a claim-valid output-root game `g` whose `l2SequenceNumber()` (an L2 block
  number) exceeds the current super-root timestamp anchor; the anchor would become an OUTPUT root consumed as the
  starting root of new super-root games (type confusion of the anchor).
Attacker-controlled inputs: choice of `g`; for a new such game, the claimed L2 block number of a permissionless type-8 proposal.
Required pre-state: an output-root game that is (a) registered in the factory, not blacklisted, created after
  1753379243, (b) `wasRespectedGameTypeWhenCreated() == true`, (c) DEFENDER_WINS and finalized, and (d) with
  l2SequenceNumber > current anchor (>= 1,788,842,855 and rising: Ink 1,794,288,067, Soneium 1,794,596,679, Unichain
  1,794,300,387 at 26433900).
State mutation: ASR slot 2 (`anchorGame`).
External calls: `_game.l2SequenceNumber()`, `status()`, `createdAt()`, `wasRespectedGameTypeWhenCreated()`, factory lookup.
Identity dependencies: the game's factory registration (one DGF per chain, all registry generations).
Broken or weakened assumption: "the anchor's sequence number is in the same unit as every claim-valid game's sequence number".
Candidate compositions: a far-future type-8 output proposal that wins by default / by trace extension (claims beyond
  the safe head) before U20; an Ink/Unichain output-root type left registered.
Current production evidence: census re-counted in this run from `evidence/F5/op-games-0-21388.json` (21,389 games) and
  `evidence/F5/ink-games-0-2639.json` (2,640 games): highest claim-valid output-root l2SequenceNumber 157,333,888 (OP),
  56,762,732 (Ink); output-root games above 1,788,842,855: 4 (OP) + 3 (Ink), all type 8, all CHALLENGER_WINS (final).
  At 26433900 `gameImpls(0) = gameImpls(1) = gameImpls(8) = 0` on all four factories (cast call), so no new output-root
  game can be created, and any created earlier carries `wasRespected` from its creation time only.
Reason it may be benign: the precondition population is closed and empty on OP and Ink; no new output-root games can
  exist; super-root anchors only move upward.
Exact falsification experiment: census of Unichain and Soneium output-root games (status, claimValid, l2SequenceNumber vs
  their anchors) — not done here; if empty the primitive is dead on all four chains. Positive check: fork, pick one of the
  4 OP CHALLENGER_WINS high games, call `setAnchorState` -> must revert `AnchorStateRegistry_InvalidAnchorGame`.
Confidence: high that it is unexploitable on OP / Ink today; medium for Unichain / Soneium (not censused).
Audit coverage:
Nearest known finding:
