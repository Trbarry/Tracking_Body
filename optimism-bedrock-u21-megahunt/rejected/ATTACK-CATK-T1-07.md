# ATTACK-CATK-T1-07 — gas-starved closeGame try/catch

## Hypothesis

An attacker supplies just enough gas that `setAnchorState` fails inside `try/catch`, but
`closeGame()` completes and permanently chooses a bond mode without updating an eligible anchor.

## Original condition and changed precondition

The fix was a gas-cost assumption: a caught EIP-150 failure must leave too little gas for the tail.
v9 still catches the call before computing and storing bond mode
(`SuperFaultDisputeGame.sol:985-1037`). Unlike the earlier legacy-game fuzz rationale, this mutation
uses a freshly created deployed type-9 super game and the v9 ASR path.

## Exact sequence and result

Create an OP type-9 game at `anchor+1`, let it resolve defender-wins, wait ASR finality, and call
`closeGame` in isolated snapshots with 38 explicit gas budgets from 75,000 through 1,000,000. At
every budget the call either reverts, leaving the anchor unchanged, or succeeds with the new game as
anchor. No successful/no-anchor state occurs.

## Barrier and evidence

At the deployed gas boundary, a starved child call and the remaining state-writing tail do not both
fit; revert atomicity removes partial state. The same invariant is encoded upstream at
`test/dispute/FaultDisputeGame.t.sol:2480-2511`. Fork test
`test_T07_closeGameGasStarvationCannotSkipAnchorUpdate` passes at
`mirror/CATK-T1/test/FixRegressionCATKT1.t.sol:396`. Deterministic gas-boundary kill; no candidate.

