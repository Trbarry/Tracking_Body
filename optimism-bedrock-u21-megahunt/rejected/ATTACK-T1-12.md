# ATTACK-T1-12 — Timeless blacklist / retirement after finality interacts with matured proofs or deleteProvenWithdrawal

Lane ATK-T1, Opus 5.5. Target 12 (row 30). Kill type: privileged precondition + executed invariant + history read.

**Original condition.** Sherlock 2023-01 M-10: finalized outputs could not be deleted. Replaced by guardian blacklist (no age limit,
`AnchorStateRegistry.sol` blacklistDisputeGame) and retirement (`updateRetirementTimestamp`).

**Executed.**
- History: the four current ASRs never emitted `DisputeGameBlacklisted` or `RetirementTimestampSet` (scan 22,980,000..26,433,900,
  `evidence/attack-wave/T1/asr-guardian-events.json`); F5 census: no blacklisted game on any chain. No such interaction exists.
- `T1_Games.t.sol::test_T1_10_…`: on a real matured proof, `deleteProvenWithdrawal` is refused for a valid game; after
  finalization nothing a guardian does reaches the withdrawal (`finalizedWithdrawals` checked first, `OptimismPortal2.sol:677`).
- Old-generation proof cells under v9 (F6 carry-through) revert `InvalidRootClaim` and remain re-provable (L2ToL1MessagePasser
  `sentMessages` is permanent), so retirement is a re-prove inconvenience, not a freeze.

**Barrier.** Every variant needs a guardian action (blacklist or retirement) — privileged (-5) — and its effect on pending proofs is
the documented safety design (U19 3.3.1, U21 3.2.1: re-prove). The permissionless delete predicate is CHALLENGER_WINS or
blacklisted only (:711-723). Score <= 0.
