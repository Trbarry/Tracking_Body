# ATTACK-B-01 — Historical value-bearing failed messages left unbacked / unreplayable (L1CDM pool)
Model: Opus 5.5 (CLAUDE.md exception).
**Hypothesis.** Some FailedRelayedMessage with value>0 is still pending while the L1CDM holds 0 ETH (swept at U16 or
otherwise), so a forced-fail victim's parked ETH could be drained by replaying it (cross-victim miscredit), or
those victims are frozen.
**Sequence tried.** Full census Bedrock..26,433,900 on OP/Ink/Soneium/Unichain (scan.py/decode.py); read
successfulMessages/failedMessages @26433900; L1CDM balances @18.5M/20M/22M/26.43M; replay all 15 still-failed hashes
under v9 (test_E1_census_replay_stillFailed_underV9).
**Barrier.** All 4 value-bearing failures (Ink 17.29/58.33/15.87 ETH, OP 236.75 ETH) are already successful; all 15
pending failures have value 0, matching L1CDM balance 0 on every chain. The 12 replays that still fail fail in
third-party targets or on per-pair `deposits` underflow (StandardBridge.sol:292) for never-deposited pairs.
**Evidence.** evidence/attack-wave/B/LIVE-OBJECTS-B.md §A, census-decoded.json, evidence/attack-wave/B/forge-ATKB-output.txt (E1).
