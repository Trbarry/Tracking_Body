PRIM-ID: PRIM-F5-01
Title: Orphaned generation-2 AnchorStateRegistry (v2.2.2) accepts LIVE-registry games as claim-valid and lets anyone move its anchor, on all four U21 chains

Earliest semantic ancestor: v2.0.0 (U13) ASR 2.2.2: `isGameRegistered` = factory lookup only (hist/v3.0.0/packages/contracts-bedrock/src/dispute/AnchorStateRegistry.sol:116-126); retirement/blacklist/respected type/finality delay read from `portal` (:89, :139, :149, :203)
Current consumer: none found on-chain. The anchor is only read by a game's `initialize` through the game's OWN registry (v9 src/dispute/FaultDisputeGame.sol:265, SuperFaultDisputeGame.sol:282, SuperPermissionedDisputeGame.sol:63), and no live implementation or gameArgs binds to a gen2 registry
Releases crossed: v2.0.0 (creation) -> v4.0.0 (U16 orphaning) -> v9.0.0 (the portal still serves the mirrored getters, L1/OptimismPortal2.sol:334,349,357)
Chains affected: OP 0x1c68ECfb…, Ink 0x2fc99fd1…, Soneium 0x190B6ecE… (anchorGame 0 before), Unichain 0xD5D0e176…
Source contracts+functions: ASR v2.2.2 `setAnchorState`, `isGameClaimValid`; v9 portal mirror getters
Persistent object or state: gen2 ASR `anchorGame` slot
Trigger: `setAnchorState(game)` from any EOA
Attacker-controlled inputs: the game address (any claim-valid legacy-domain game in the shared factory, including ones bound to the live registry)
Required pre-state: a claim-valid game with `l2BlockNumber()` greater than the gen2 anchor (true on every chain: types 0/1/8 of the live registry)
State mutation: gen2 `anchorGame` := a live-registry game (fork: `test/F5/F5_ChainHistoryDifferential2.t.sol::test_d`, all four chains OK; live anchor unchanged)
External calls: game.gameData / factory.games / portal getters
Identity dependencies: the gen2 registry treats a game as its own when the factory knows it, without checking `game.anchorStateRegistry()`
Broken or weakened assumption: "an orphaned registry is frozen". It is not, but nothing reads it
Candidate compositions: (1) a future flow that reads `getAnchorRoot()` of an old registry (the planned `migrate`, off-chain tooling, a re-registered old implementation); (2) bond mode of gen2-era games at `closeGame` (OPUS-11, BW0-02)
Current production evidence: fork test at 26433900; gen2 `isGameClaimValid(live anchor game)` = true (cast @26433900 on OP)
Reason it may be benign: no implementation bound to gen2 can be used to create games (registry-binding census: 0 after-cut registrations bound elsewhere; `test_a`); super games revert on gen2 (`test_c`)
Exact falsification experiment: enumerate every on-chain caller of gen2 `getAnchorRoot`/`anchorGame` (trace any pending gen2-era game initialisation — none in progress: census "IN_PROGRESS but retired" = 0) and replay `migrate` on a fork after a gen2 anchor move, comparing its outputs
Audit coverage:
Nearest known finding:
Confidence: high (fact), low (impact)
