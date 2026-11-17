# ATTACK-CATK-T1-03 — re-prove after finalization

## Hypothesis

The v1.4+ per-submitter proof model permits a record written after finalization to execute the same
economic withdrawal a second time.

## Original condition and changed precondition

The old fix assumed one proof record per withdrawal. v9 intentionally permits repeated proofs and
does not read `finalizedWithdrawals` in `proveWithdrawalTransaction`
(`OptimismPortal2.sol:390-490`). C5 covered alternate submitters generally; this mutation first
finalizes a real withdrawal, then writes a genuinely new submitter record *after* finalization.

## Exact sequence and result

1. Make real fixture f1 (hash `0x9cd7…2ec7`, 0.0005 ETH) finalizable and finalize it as the original
   submitter.
2. Re-submit its exact production proof from `0xBEEF`; the portal accepts and stores a fresh record.
3. From a third EOA, call `finalizeWithdrawalTransactionExternalProof` using `0xBEEF`'s record.

Step 3 reverts. The second target call/value transfer never occurs.

## Barrier and evidence

`finalizedWithdrawals[withdrawalHash]` is hash-global, set before the external call and checked before
selecting any proof record (`OptimismPortal2.sol:603-610,671-679`). Test
`test_T03_reproveAfterFinalizationCannotExecuteTwice` passes at
`mirror/CATK-T1/test/FixRegressionCATKT1.t.sol:288`. Re-proving after finalize is explicitly known/by
design (blacklist Part 2 item 4); global replay protection kills the impact. No candidate.

