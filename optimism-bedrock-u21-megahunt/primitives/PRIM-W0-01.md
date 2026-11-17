PRIM-ID: PRIM-W0-01
Title: Since op-contracts v7.0.0 the AnchorStateRegistry no longer checks that a game is bound to it: in a factory
  that has served several registry generations, the retirement timestamp is the only thing separating
  previous-registry games from the current registry
Earliest semantic ancestor: v2.0.0 src/dispute/AnchorStateRegistry.sol:116-126 (isGameRegistered = factory UUID
  lookup only). v4.0.0 :182-200 added `IFaultDisputeGame(game).anchorStateRegistry() == address(this)`.
  v7.0.0 :216-226 removed it again (v9 src/dispute/AnchorStateRegistry.sol:227-237, comment :217-224).
Current consumer: AnchorStateRegistry.isGameProper / isGameClaimValid / setAnchorState (v9 :286-372);
  OptimismPortal2.proveWithdrawalTransaction (:415-427), checkWithdrawal (:702), deleteProvenWithdrawal (:720).
Releases crossed: v2.0.0 (registry #2 deployed as a new proxy, same factory) -> v4.0.0 (registry #3 deployed as a
  new proxy "AnchorStateRegistry-U16", binding check added) -> v7.0.0 (binding check removed) -> v9.0.0.
Chains affected: OP Mainnet, Ink, Unichain, Soneium each have THREE registry generations behind ONE factory
  (first implementation bound to each, from ImplementationSet logs):
  OP 0x18DAc71c… (L1 block 19884592) -> 0x1c68ECfb… (22182531) -> 0x23B2C629… (22990599);
  Ink 0xde744491… (21344310) -> 0x2fc99fd1… (22182531) -> 0xEe018bAf… (22990599);
  Unichain 0x318A642d… (21116377) -> 0xD5D0e176… (22254924) -> 0x27Cf508E… (22990722);
  Soneium 0x61f89A38… (21314185) -> 0x190B6ecE… (22182531) -> 0x48909289… (22990670).
Source contracts + functions: AnchorStateRegistry.isGameRegistered / isGameRetired; DisputeGameFactory.create /
  setImplementation; game clone `anchorStateRegistry()` and `wasRespectedGameTypeWhenCreated()`.
Persistent object or state: every game clone in a shared factory (`_disputeGames`, `_disputeGameList`), each with an
  immutable (or clone-arg) registry pointer; `gameImpls[type]` / `gameArgs[type]`; `retirementTimestamp`.
Trigger: a game type left on (or pointed back at) an implementation that is bound to a superseded registry, while
  the current registry's retirement timestamp is older than the game's creation.
Attacker-controlled inputs: permissionless `DisputeGameFactory.create` for that type (bond), root claim, extraData.
Required pre-state: `gameImpls[t]` bound to registry R_old at a time later than R_current.retirementTimestamp.
  For the game to be USABLE for withdrawals, t must also be the respected type at creation: the game's snapshot is
  `R_old.respectedGameType() == t`, and a v2.0.0-era R_old returns the LIVE respected type through the portal getter
  (PRIM-W0-02), so the snapshot would be true whenever t is the live respected type.
State mutation: none by itself; the game would start from R_old's anchor (which anyone can move, PRIM-W0-02), post
  bonds into R_old's DelayedWETH generation, be judged by the fault-proof program of the old implementation, and
  still be `isGameRegistered` / `isGameProper` / `isGameClaimValid` in R_current.
External calls: R_current -> factory.games(); R_current -> game.createdAt / wasRespectedGameTypeWhenCreated / status.
Identity dependencies: the factory address is the only link between a game and a registry from v7.0.0 on.
Broken or weakened assumption: "a game accepted by registry X was created under X's rules (anchor, respected type,
  pause, WETH)". True v4.0.0..v6.0.0 by construction; true afterwards only while every live implementation of the
  shared factory is bound to the current registry.
Candidate compositions: registry replacement that does not clear every game type (the v9 migrator clears the finite
  list `clearedGameTypes` = {0,1,8,4,5,9,10} and deploys a NEW factory, which removes the shared-factory condition);
  a Guardian respected-type switch to a type whose implementation predates the registry; PRIM-W0-02 (attacker-chosen
  anchor in R_old).
Current production evidence:
  - fork test `test/W0/W0Lineage.t.sol::test_W0_01_currentRegistryRegistersGameOfOldRegistry` (L1 block 26433900,
    deployed bytecode, no prank): game index 9827 (0x9Ff603b3…3a78, FaultDisputeGame 1.4.1) has
    `anchorStateRegistry() == 0x1c68ECfb…`, yet `0x23B2C629….isGameRegistered(game) == true`; it is rejected only
    because `isGameRetired == true`. Game 9828 (first after U16) is bound to 0x23B2C629….
  - complete `ImplementationSet` / `ImplementationArgsSet` history of the four factories, L1 blocks
    19,800,000..26,433,900 (250 logs, 0 RPC errors): `evidence/W0/dgf-implementation-set-logs-19800000-26433900.json`,
    analysed in `evidence/W0/dgf-implementation-registry-binding.json`. Only game types 0, 1, 8, 5, 9 were ever
    given an implementation (4 and 10 only cleared). At each registry switch every live type was re-pointed in the
    same transaction. Implementations active at or after the current registry's retirement and NOT bound to it: 0 on
    OP, 0 on Ink, 0 on Unichain, 0 on Soneium.
Reason it may be benign: the precondition has never held on the four chains (previous bullet), and today only types
  5 and 9 are registered, both carrying the current registry in `gameArgs`. The removal was made for net-new
  registries (code comment at v9 :217-224).
Exact falsification experiment: done for history (implementation scan above). To keep it closed: after any
  registry replacement, assert for every t with `gameImpls[t] != 0` that the clone's registry == portal's registry;
  on a fork, register a FaultDisputeGame 1.4.1 implementation (bound to 0x1c68ECfb…) for the respected type with a
  privileged prank — as a LOCATOR only — and show a new game is claim-valid in 0x23B2C629… (not run: mock-only
  condition, no exploitability claim rests on it).
Confidence: high for the mechanism and for the historical negative; no current reachability.
Audit coverage:
Nearest known finding:
