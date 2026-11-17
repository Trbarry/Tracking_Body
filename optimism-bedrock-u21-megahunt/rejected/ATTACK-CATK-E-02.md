# ATTACK-CATK-E-02 — mutate gen-1 anchors or extend a retired factory lineage

## Hypothesis

An ordinary account can create a gen-1/gen-2 legacy fault game or directly update a gen-1 ASR, then
carry that chosen state into migration.

## Exact sequence tried

- Read both deployed factories: type 0 and type 1 implementations are zero.
- Call `create(0,...)` from the attacker on both factories.
- Call registered type-5 `create` from a non-proposer origin.
- Call both gen-1 registries' `tryUpdateAnchorState()` and `setAnchorState(...)` from the attacker.
- Call DGF owner setters from the attacker.

## Deterministic barrier

Every call fails in E07. `DisputeGameFactory.create` reverts on a zero implementation at
`op-v9.0.0/src/dispute/DisputeGameFactory.sol:156-160`. Type 5 rejects the non-proposer during clone
initialization. Gen-1 `tryUpdateAnchorState` requires `msg.sender` to be the registered game, while
`setAnchorState` is guardian-only. Factory configuration is owner-only.

Even if an old game updates an old anchor through its intended close path, E01 proves every gen-1
and gen-2 ASR has zero migration accesses.

Evidence: `CATKEMigrationTest.test_E07_gen1AndRetiredGameMutationGates` and E01.

## Disposition and honest score

Rejected. No attacker-selected gen-1 entry point exists, and the residual old-game path has no
migration consumer. Score below 0 after `-3 no eligible impact` and `-5 future-only`.

