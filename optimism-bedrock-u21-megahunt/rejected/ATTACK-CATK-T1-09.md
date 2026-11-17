# ATTACK-CATK-T1-09 — legacy portal spacer reuse

## Hypothesis

Residue in legacy portal slots 52, 58 or 59 is reinterpreted by a later permissionless v9 entrypoint
and changes live behavior.

## Original condition and changed precondition

The historical upgrade safety condition was that removed fields are cleared or never read. v9 keeps
them as spacers (`OptimismPortal2.sol:64-107`). C16 proved old slot-52 proofs are unreachable; this
mutation records accesses of an actual post-U21 permissionless deposit on all four portal histories,
including chains with different deployment ancestry.

## Exact sequence and result

For OP, Ink, Soneium and Unichain, enable Foundry storage-access recording, call
`depositTransaction(attacker,0,100000,false,"")`, and inspect every portal read/write slot. All four
deposits succeed. No access equals base slot 52, 58 or 59.

## Barrier and evidence

Dead Solidity spacers have no reachable accessor or write in the exercised v9 entrypoint; legacy
residue cannot affect it. Test `test_T09_legacyPortalSpacersAreDeadOnPermissionlessDeposit` passes at
`mirror/CATK-T1/test/FixRegressionCATKT1.t.sol:458`. This agrees with D02/C16 and the known decision
never to clear the slots. Deterministic kill; no candidate.

