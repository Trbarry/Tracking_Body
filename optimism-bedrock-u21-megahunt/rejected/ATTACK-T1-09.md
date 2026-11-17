# ATTACK-T1-09 — Legacy portal spacers are never cleared: residue in a legacy slot changes v9 behaviour

Lane ATK-T1, Opus 5.5. Target 9 (row 17). Kill type: failing experiment, four chains.

**Original condition.** Spearbit 2025-05 5.3.6: "stop clearing spacers in all upgrade() functions"; v9 `OptimismPortal2.sol:67-132`
reserves legacy slots 52 (legacy proofs), 53, 54, 56 (factory), 58 (blacklist), 59 (respected type/timestamp), 61, 63 byte 20.

**Sequence executed** (`T1_Portal.t.sol::test_T1_05_legacySlotResidueNeverRead`, L1 @ 26433900): residue read on all four portals
(e.g. slot 53 = 0x…95703e09…4c00, slot 56 = the chain's DGF, slot 59 = legacy respected type/timestamp, Soneium slot 59 low byte =
1); then `vm.record()` over an attacker deposit, `checkWithdrawal`, `deleteProvenWithdrawal` attempt and a full
`finalizeWithdrawalTransactionExternalProof` (proof-cell vehicle) on each chain: 41 portal slot reads per chain, none of
52/53/54/56/58/59/61 nor `keccak(hash,52)` / `keccak(game,58)`.

**Barrier.** No v9 entry point reads a legacy slot (complements C2 junk test and C16 slot-52 trace). Residue matters only if a
future layout reuses those slots (future-only, -5). Older intermediate versions are not live code. Output:
`evidence/attack-wave/T1/T1_Portal_04_05_06.out.txt`.
