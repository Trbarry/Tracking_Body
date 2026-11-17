# ATTACK-CATK-T1-06 — far-future super anchor

## Hypothesis

Because super games lack `challengeRootL2Block`, an attacker proposes an arbitrarily far-future
sequence, resolves it, sets it as anchor and obtains an incorrect withdrawal or permanent freeze.

## Original condition and changed precondition

The original condition was an upper-bound sanity challenge on the anchor number. v9 super-game
initialization checks only `sequence > current anchor` (`SuperFaultDisputeGame.sol:250-320`) and ASR
does the same when anchoring (`AnchorStateRegistry.sol:357-370`). The mutation creates fresh deployed
games after U21 on every chain rather than examining old game metadata.

## Exact sequence and result

The attacker creates sequences near 2,000,000,000 on live type 9 for OP, Ink and Unichain. Before
resolution, every game is claim-invalid. The test deliberately supplies no honest challenge, advances
the full clock, resolves defender-wins, waits finality and calls `setAnchorState`; only then does the
far-future anchor take effect. Soneium's type-5 creation rejects the attacker.

## Barrier and evidence

There is no bytecode bound, but the sequence has no direct exploit without making an objectively
invalid fault-proof claim win the standard challenge process. That exact root cause is acknowledged
(blacklist Part 1 §4 and Part 2 items 5/14), so the successful primitive is not novel or independently
bounty-eligible. Test `test_T06_farFutureSuperAnchorRequiresInvalidGameToWin` passes at
`mirror/CATK-T1/test/FixRegressionCATKT1.t.sol:365`. Known/model-assumption kill; no candidate.

