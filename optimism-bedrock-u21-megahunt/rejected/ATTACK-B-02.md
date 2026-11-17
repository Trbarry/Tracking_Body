# ATTACK-B-02 — Historical "finalized in portal, unknown to messenger" objects carrying value (A-068 historical half)
**Hypothesis.** Pre-v9 messenger reverts left value-bearing withdrawals finalized and unreplayable (permanent loss).
**Sequence tried.** WithdrawalFinalized(success=false) scan Bedrock..26,433,900 on 4 portals; trace each; compute v1
and v0 message hashes; read both messenger mappings.
**Barrier.** 4 hits (OP only; Ink/Soneium/Unichain none). All are version-0 migrated legacy withdrawals whose legacy
hash is already `successfulMessages=true` (paid pre-Bedrock); L1CDM reverted at
`legacy withdrawal already relayed` (/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/universal/CrossDomainMessenger.sol:231) and the portal relocked the ETH
(lockETH 0x1ee116bf in the trace). Failed double-withdrawals, no stranded value. v9 reverts instead (OptimismPortal2.sol:652). KNOWN item 3 (already-relayed legacy messages).
**Evidence.** LIVE-OBJECTS-B.md §B, census-decoded.json (fields v0hash, legacy_successful).
