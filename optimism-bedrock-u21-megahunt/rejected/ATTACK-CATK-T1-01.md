# ATTACK-CATK-T1-01 — removed registry binding

## Hypothesis

A post-retirement game whose immutable `anchorStateRegistry()` names registry B can be registered by
registry A through a shared/current factory and then authorize an incorrect withdrawal.

## Original condition and changed precondition

The removed condition was `game.anchorStateRegistry() == address(this)`. v9 instead relies on the
first initialization retiring old games and on factory UUID equality
(`op-v9.0.0/packages/contracts-bedrock/src/dispute/AnchorStateRegistry.sol:94-132,215-236,256-262`). C15 already censused old
games; this mirror changed the precondition by creating new post-upgrade games through the live
factories and checking their immutable ASR on all four chains.

## Exact sequence and result

1. Read each ASR factory/type/retirement and latest post-retirement clone.
2. From `0xA11CE`, create a new type-9 clone on OP, Ink and Unichain using valid super-root encoding.
3. Attempt a type-5 clone on Soneium.
4. Present each created clone to the current ASR.

Every existing and new clone names the same current ASR that registers it. Soneium creation reverts
at the proposer gate. No live factory has an attacker-reachable foreign-ASR implementation/args pair.

## Barrier and evidence

The missing precondition is a registered implementation bound to a sibling registry after the
current retirement cut. Creating a clone cannot choose or rewrite implementation immutables. Test
`test_T01_registryBinding_postUpgradeCreateCannotNameSiblingRegistry` passes at
`mirror/CATK-T1/test/FixRegressionCATKT1.t.sol:229`; final output is
`mirror/CATK-T1/evidence/forge-output.txt`. The abstract root cause is also known (blacklist Part 2
item 7). Deterministic kill; no candidate.

