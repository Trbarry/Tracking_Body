REJ-ID: REJ-F4-02
Title: "`deleteProvenWithdrawal(hash, submitter)` calls `status()` on a stored legacy / non-game address" (C4 reopen condition)

Idea
- v9 `deleteProvenWithdrawal` loads `provenWithdrawals[hash][submitter].disputeGameProxy` and calls `status()` on it
  (op-v9.0.0 src/L1/OptimismPortal2.sol:711-728). A stored address that is not a dispute game (legacy output data, an
  EOA, an attacker contract) could make the deletion predicate attacker-controlled.

Killing fact
- The `timestamp == 0` check (:713-715) reverts `OptimismPortal_Unproven` before `status()` for every legacy-only hash
  (slot 52 is a different mapping; slot-57 entry is zero) — fork test above.
- Every slot-57 entry ever written comes from `proveWithdrawalTransaction`, which takes the game from the portal's own
  DisputeGameFactory by index (`gameAtIndex`): the stored address is always a factory clone, and every clone generation
  (FDG 1.2.0 .. SFDG) implements `status()`. No other writer of slot 57 exists in any tag v1.4.0 .. v9.0.0 (layout lineage,
  `STORAGE-ARCHAEOLOGY.md` §3/§6.1).
