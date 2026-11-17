# ATTACK-CATK-T1-08 — nested SafeCall reserves

## Hypothesis

The outer portal reserve passes while the inner messenger reserve fails in a band that nevertheless
finalizes the portal and leaves neither success nor replayable failure.

## Original condition and changed precondition

The 2023 fix assumes `hasMinGas` and the 63/64/reserve constants conservatively bracket the call.
v9 composes two checks (`SafeCall.sol:95-171`) with L1 135k/15k and L2 40k/5k constants
(`GasConstants.sol:60-78`). This mutation runs a real v1 ERC20 messenger withdrawal through both
layers after the U21 upgrade.

## Exact sequence and result

Fixture f5 is made finalizable and executed in snapshots at 450k, 600k, 750k, 900k, 1.1m, 1.4m,
1.9m and 2.8m outer gas. Completed calls always set the portal bit plus messenger success or failure.
Starved calls revert and leave all three bits unset.

## Barrier and evidence

The inner low-gas branch writes `failedMessages` before returning; an outer failure from L2CDM
reverts the entire portal call. Thus every observed state is delivered, replayable, or retryable—not
non-replayable. Test `test_T08_safeCallReserveSamplesAreAtomicOrReplayable` passes at
`mirror/CATK-T1/test/FixRegressionCATKT1.t.sol:425`. Same-root gas issues are known and no eligible
impact was produced. No candidate.

