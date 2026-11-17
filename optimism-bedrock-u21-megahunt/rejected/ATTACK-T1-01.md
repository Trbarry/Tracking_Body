# ATTACK-T1-01 — Registry-binding check removed at v7: a game bound to another registry passes the portal's registry

Lane ATK-T1 (FIX-REGRESSION), Opus 5.5 (CLAUDE.md exception, Mythos 5.2 quota until 2026-11-22). Target 1 of
`audit/FIX-CLOSURE-MATRIX.md` section B (row 1). Kill type: failing experiment on deployed bytecode, four chains.

**Original safety condition.** Cantina 2025-04 3.2.9 fix: `isGameRegistered` required `game.anchorStateRegistry() == address(this)`
(present v4.0.0..v6.0.0). Removed at v7; v9 `src/dispute/AnchorStateRegistry.sol:227-237` only checks the factory UUID
(NatSpec :217-222 relies on `retirementTimestamp` set once at :130-132). `isGameRespected` (:242) trusts the game's own
`wasRespectedGameTypeWhenCreated`, which the game snapshots from ITS registry (`SuperFaultDisputeGame.sol` initialize tail).
So v9 safety = "no claim-valid-able game in the portal's factory is bound to a different registry".

**Prior coverage.** C15 (full census, 30,480 non-retired games bound to the current ASR). Not covered: whether an attacker can
create NEW foreign-bound games today on Ink/Soneium/Unichain (mutation a), cross-chain presentation of a game through the
shared type-9 implementation `0x19AF533C…3208` (b/c).

**Sequence executed** (`test/poc/attack-wave/T1/test/T1_Registry.t.sol::test_T1_01_registeredTypesBoundToPortalRegistry`, L1 @ 26433900):
1. Enumerated every game type ever configured on the four factories (full-history `ImplementationSet` / `ImplementationArgsSet` /
   `InitBondUpdated` scan, `evidence/attack-wave/T1/dgf-config-events.json`: types {0,1,4,5,8,9,10}; live after U21: 5 and 9
   on OP/Ink/Unichain, 5 only on Soneium) plus a probe band 0..16, 42, 254, 255, 1337, 2^32-1.
2. For each live type: `gameArgs(t)` contains the portal's own ASR and none of the sibling chains' ASRs nor gen-0/gen-1 ASRs.
3. Unprivileged EOA creates a type-9 game on OP, Ink, Unichain (bond 0.08 ETH): the clone's `anchorStateRegistry()` is the
   portal ASR, registered, not retired, `wasRespected == true`; `rootClaimByChainId` resolves only the portal's own
   `SystemConfig.l2ChainId()` (10 / 57073 / 130 asserted), sibling ids revert `UnknownChainId`.
4. Cross product: `ASR_i.isGameRegistered(anchor_j)` and `ASR_i.isGameRegistered(attackerGame_j)` true iff i == j.
5. Type 5 (tx.origin-authorised) creation by the attacker reverts on all four chains.

**Barrier.** Every registered implementation's immutable args name the portal's own registry (factory args are written only by the
DGF owner, `DisputeGameFactory.sol:312`), and games are looked up by UUID in the portal's own factory, so no game bound to registry
B can sit in factory A unless the owner registers it (privileged, -5). Result file: `evidence/attack-wave/T1/T1_Registry.out.txt`.
Reopen only if a factory owner registers an implementation whose args name another registry (watch `ImplementationArgsSet`).
