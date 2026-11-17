# ATTACK-CATK-T1-14 — old-prestate game wrapped attack

## Hypothesis

An open game deployed with the pre-v1.9.0 Kona prestate can be driven through a permissionless
sibling/wrapped move so a pre-fix claim becomes ASR-valid without re-running the fixed program.

## Original condition and changed precondition

The safety condition is that the immutable prestate faithfully adjudicates every reachable claim.
The mutation selects a concrete still-open old-prestate production game rather than comparing source
abstractly, and executes the cheapest state-changing root attack on its deployed bytecode.

## Exact sequence and result

At OP DGF index 21,377, verify immutable prestate
`0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df`, current ASR binding,
proper-but-not-claim-valid status and one claim. Pay the exact root-attack bond from `0xA11CE` and add
a child claim. `claimDataLen` becomes 2, but `isGameClaimValid(oldGame)` remains false.

## Barrier and evidence

A move only enters the adjudication tree. ASR validity still requires finalized
`DEFENDER_WINS` (`AnchorStateRegistry.sol:331-370`). No old-Kona semantic divergence was supplied that
makes an incorrect defender claim win, so no portal proof becomes executable. Test
`test_T14_oldPrestateWrappedAttackOnlyCreatesAChallenge` passes at
`mirror/CATK-T1/test/FixRegressionCATKT1.t.sol:604`. This kills the entrypoint-only mutation, not every
possible Kona semantic delta; the concrete differential is the highest-value next experiment. No
candidate.

