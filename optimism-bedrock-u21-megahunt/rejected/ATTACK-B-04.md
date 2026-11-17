# ATTACK-B-04 — Third party makes the forced-failed victim message permanently unreplayable
**Hypothesis.** After forcing the failure, the attacker blocks the replay forever (low-gas replay, nested re-entrant
replay, starvation band where the gate passes but the target fails, re-finalize/re-prove).
**Sequence.** test_E2 attempts 1-3; test_E3 sweeps 501 replay gas values 300k..800k after a forced fail of f5.
**Barrier.** Every non-delivering exit re-writes `failedMessages=true` and returns (CrossDomainMessenger.sol:265-282,
:292-295) — no path writes successfulMessages without the call succeeding; the target receives
`gasleft()-135k` (:285) so delivery is monotone in gas: first delivering call gas 412,000, 0 non-delivered above it,
112 below (all still replayable, no partial effect). Portal path closed by finalizedWithdrawals (OptimismPortal2.sol:610).
Outcome = one extra tx for the victim = KNOWN Trust M-1 (KNOWN-FINDINGS Part 2 item 1), score -3/-4.
**Evidence.** test_E2, test_E3_replay_gas_sweep_no_starvation_band PASS, evidence/attack-wave/B/forge-ATKB-output.txt.
