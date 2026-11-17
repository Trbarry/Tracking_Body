# ATTACK-CATK-B-06 — active failed-message ordering exposes a forced-failure freeze

## Hypothesis

The fifteen currently unsuccessful messages reveal ordering-sensitive token/application state that the nested-failure attacker can reproduce to freeze or misdirect economic withdrawals.

## Exact sequence tried

Replayed all fifteen with full gas on independent pinned forks in chronological and reverse order. Traced each original target failure and decoded its selector/target. Tests: `test_liveZeroValueFailuresChronologicalReplayOrder` and `test_liveZeroValueFailuresReverseReplayOrder`.

## Deterministic barrier

Both orders recover the same three bridge messages and leave the same twelve failed. The remaining barriers are target-local and pre-existing: bare token revert, already-confirmed root, `TransfersBlocked()`, arithmetic underflow, invalid L1 token, subtraction overflow, or `Must be proxy target`. All relay ETH values are zero and L1CDM retains zero ETH. These failures predate U21 and occurred on ordinary first deliveries/retries; the forced-reentrancy primitive did not create their target state. Caller balance remains unchanged in every replay.

## Evidence

- `mirror/CATK-B/evidence/active-zero-value-replays.json`
- `mirror/CATK-B/evidence/active-zero-value-replay-traces.json`
- `mirror/CATK-B/evidence/fork-test-output.txt`

Decision: rejected as no novel forced-failure impact; individual legacy token incompatibilities are outside this U21 root cause.
