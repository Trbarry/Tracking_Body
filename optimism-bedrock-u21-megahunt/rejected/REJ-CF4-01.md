# REJ-CF4-01 — Legacy portal proof coerces v9 `status()` call

## Hypothesis

A surviving slot-52 output root is decoded as a dispute-game address by v9
`deleteProvenWithdrawal`, enabling an attacker-controlled or malformed external `status()` call.

## Falsification

V9 derives `provenWithdrawals[hash][submitter]` from base 57, not base 52, and checks its timestamp
before the call (`op-contracts/v9.0.0/src/L1/OptimismPortal2.sol:711-725`). On the block-26433900
fork, `testLegacyPortalProofSlot52IsNonzeroButV9DeleteDoesNotReachIt` proves a real legacy entry is
non-zero, overwrites both words with maximum junk, observes a zero v9 getter, and receives
`OptimismPortal_Unproven()`.

## Verdict

Rejected. Exact production state and named fork test; no current reachability.
