PRIM-ID: PRIM-W0-02
Title: Superseded AnchorStateRegistry proxies are live mirrors of the current registry: v2.0.0-era code resolves
  blacklist / retirement / respected type / finality delay through the portal's pass-through getters, has no pause
  check, and its anchor can still be moved by anyone using games of the current registry
Earliest semantic ancestor: op-contracts v2.0.0 src/dispute/AnchorStateRegistry.sol:138-140 (isGameBlacklisted ->
  portal.disputeGameBlacklist), :145-150 (isGameRetired -> portal.respectedGameTypeUpdatedAt), :195-208
  (isGameFinalized -> portal.disputeGameFinalityDelaySeconds), :239-261 (permissionless setAnchorState).
  The portal getters became pass-throughs to the NEW registry at v4.0.0 src/L1/OptimismPortal2.sol:304-347.
Current consumer: every FaultDisputeGame 1.4.1 clone created between the U13 and U16 upgrades (immutable
  ANCHOR_STATE_REGISTRY = old proxy): closeGame() -> isGameFinalized / setAnchorState / isGameProper
  (v2.0.0 src/dispute/FaultDisputeGame.sol:993-1034), claimCredit(); plus anything that reads
  anchors()/getAnchorRoot() of the old proxy.
Releases crossed: v2.0.0 (object created) -> v4.0.0 (portal getters re-pointed; new registry proxy
  "AnchorStateRegistry-U16", src/L1/OPContractsManager.sol:671-689) -> v9.0.0 (portal getters unchanged in shape,
  src/L1/OptimismPortal2.sol:306-359).
Chains affected: OP Mainnet verified. Any chain that ran a v2.x/v3.x registry and then took U16/U16a has the same
  shape (not read for Ink / Soneium / Unichain).
Source contracts + functions: AnchorStateRegistry 2.2.2 (proxy 0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b,
  impl 0x7b465370…): isGameRegistered, isGameRetired, isGameBlacklisted, isGameProper, isGameFinalized,
  isGameClaimValid, setAnchorState, getAnchorRoot, anchors; OptimismPortal2 6.1.0 getters respectedGameType,
  respectedGameTypeUpdatedAt, disputeGameBlacklist, disputeGameFinalityDelaySeconds.
Persistent object or state: the old proxy's storage (slot 1 disputeGameFactory = live factory 0xe5965Ab5…,
  slot 2 portal = live portal, slot 3 anchorGame = 0x9C9ac0A342D68040fe44d61de897E30Ad1c57bC3, slots 4-5
  startingAnchorRoot); bonds of unclaimed pre-U16 games in the legacy DelayedWETH proxies (PASS A PRIM-0602).
Trigger: anyone calls `oldRegistry.setAnchorState(game)` with a claim-valid type-0/8 game of the CURRENT registry,
  or closes / claims on a pre-U16 game.
Attacker-controlled inputs: which current game to feed to the old registry; timing of closeGame on old games.
Required pre-state: none beyond what is on chain.
State mutation: old registry `anchorGame` moves forward to a current game (no check that the game belongs to that
  registry: v2.0.0 isGameRegistered is the factory lookup only, and the factory is shared). Pre-U16 games that
  close now get bondDistributionMode = REFUND because the old registry reports them retired through the CURRENT
  retirement timestamp.
External calls: old registry -> portal (current) -> current registry; old registry -> game.
Identity dependencies: old registry trusts `portal` (slot 2) and `disputeGameFactory` (slot 1), both still the live
  contracts; the portal answers with the state of whatever registry it points at today (and will answer with the
  shared registry after the planned migrate).
Broken or weakened assumption: "a replaced registry is frozen". It is not: its predicates track the live
  registry's Guardian actions, and its anchor is writable by anyone.
Candidate compositions:
  (a) any implementation bound to the old registry being registered again (or left registered) in the shared
      factory: its new games would start from an anchor an attacker can choose among all claim-valid current games
      and would count as registered in the current registry (PRIM-W0-01);
  (b) bond accounting of pre-U16 games (REFUND vs NORMAL decided by today's retirement) — bond-only;
  (c) the planned migrate re-points the portal getters at the shared registry while slot 1 of the old registry
      keeps the per-chain factory: the mirror then mixes shared-registry blacklist/retirement with per-chain games.
Current production evidence (cast, fork of L1 block 26433900):
  - `version()` = "2.2.2"; `portal()` = 0xbEb5Fc57…06Ed; `disputeGameFactory()` = 0xe5965Ab5…fA9;
    `respectedGameType()` = 9 (the live value); `getAnchorRoot()` = (0xfce6d556…, 138585637).
  - for current games index 17904 (type 0), 20094 (type 8), 20095 (type 9):
    oldRegistry.isGameRegistered = true, isGameRetired = false, isGameClaimValid = true.
  - `eth_call oldRegistry.setAnchorState(0x908554DC…aE86)` (game 20094, l2BlockNumber 157333888) from
    0x…bEEF returns without revert.
  - pre-U16 game index 9827 (0x9Ff603b3…3a78): oldRegistry.isGameProper = false.
  - generation-1 registry 0x18DAc71c228D1C32c99489B7323d441E1175e443 (`version()` "2.0.0") is also still deployed;
    it is the address the Immunefi asset table lists for AnchorStateRegistry.
Reason it may be benign: no implementation bound to an old registry is registered today (gameImpls only for types
  5 and 9, both carrying the current registry in gameArgs); nothing in the withdrawal path reads an old registry;
  the bond effect is bond-only (carved out of Critical/High).
Exact falsification experiment: (1) fork test: prank an arbitrary EOA, call oldRegistry.setAnchorState(game 20094),
  assert `anchorGame` changed (state-changing confirmation of the eth_call); (2) list pre-U16 games with non-zero
  WETH credit, run closeGame + claimCredit and record REFUND vs NORMAL payouts; (3) grep every historical
  ImplementationSet for an implementation whose anchorStateRegistry() is 0x1c68ECfb… set after block 22,990,599
  (evidence/W0/dgf-implementation-set-logs-*.json).
Confidence: high for the facts (direct reads); impact none found.
Audit coverage:
Nearest known finding:
