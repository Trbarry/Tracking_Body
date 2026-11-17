# ATTACK-CATK-T1-04 — version-0 first relay unknown outcome

## Hypothesis

A first relay of an old nonce-version-0 messenger withdrawal reverts or exhausts gas after the
portal marks it finalized but before either messenger outcome mapping is written.

## Original condition and changed precondition

The old assumption “messenger never reverts, portal always finalizes” was inverted at v9. The new
condition is that messenger exits write success/failure (`CrossDomainMessenger.sol:209-307`) and an
unrecorded L2CDM failure makes the portal revert (`OptimismPortal2.sol:639-653`). C6 tested v9 paths;
this mutation uses a real value-bearing version-0 object rather than a newly encoded v1 message.

## Exact sequence and result

Fixture f1 is driven through its real proof/game, then finalized in independent snapshots with outer
gas budgets 600k, 800k, 1m, 1.3m, 1.7m, 2.2m and 3m. Both low-gas reverts and completed calls are
observed. For every completed call, `finalized=true` and at least one of `successfulMessages` or
`failedMessages` is true. Every revert leaves all three false.

## Barrier and evidence

EVM transaction atomicity rolls back the portal flag when L1CDM reverts; every non-reverting
messenger branch writes an outcome. Test
`test_T04_versionZeroFirstRelayHasNoFinalizedUnknownOutcome` passes at
`mirror/CATK-T1/test/FixRegressionCATKT1.t.sol:307`. No eligible incorrect withdrawal or permanent
freeze was produced. Deterministic kill; no candidate.

