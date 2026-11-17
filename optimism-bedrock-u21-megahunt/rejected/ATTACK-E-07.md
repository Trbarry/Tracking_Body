# ATTACK-E-07 — attacker forces migrate failure / partial migration / unsafe retry or repeat (KILLED)

**Hypothesis.** Poisoned state makes migrate revert (governance DoS), leaves a partial migration after a failed
attempt, makes a retry produce different contracts, or allows a repeat/subset re-migration that drains the set.

**Sequence executed.** `test/poc/attack-wave/E/test/ATKE_Poison.t.sol::test_E09_failed_then_retry_and_repeat` after full poison: [UNI,OP] -> REVERT
`ChainIdsNotAscending` 0xe5665c6c; portal still on per-chain lockbox, INTEROP false; retry [OP,UNI] OK with addresses
and anchor identical to the clean run; repeat -> `ChainAlreadyMigrated` 0xd4f98c32; [UNI] alone -> same. Poisoned
migrate itself succeeds (E-01).

**Barrier.** Migrate is one call; every revert source reads governance state only (Migrator.sol:129-166, 287-325,
482-505; OptimismPortal2.sol:528-572); the state-diff shows no attacker-written slot is read except portal resource
params. Gas 3.25 M, far below the EIP-7825 cap 16,777,216 and not attacker-growable (no loop over attacker data).
Re-migration refused by the INTEROP flag (Migrator.sol:309-311).

**Evidence.** forge-E04-E08-E09.txt, E09-retry-repeat.txt, E01-poison-vs-clean.txt (gas).
