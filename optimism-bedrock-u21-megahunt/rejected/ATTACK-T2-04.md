# ATTACK-T2-04 — Never-finalized Bedrock-era withdrawals of older eras are mis-consumed by v9

Model: Opus 5.5. Verdict: **KILLED — failing experiment + full population read.**

Hypothesis: withdrawals initiated under older L2 rules (Regolith..Holocene; older L2CDM baseGas formulas; direct
L2ToL1MessagePasser withdrawals) and never finalized (11,196, 6,253 ETH) are now undeliverable or deliver a different
outcome under v9: gas floor beyond the 2^24 cap, unsafe target (portal/lockbox/L1CDM), the v9 L2CDM-sender revert
freezing them, or value to someone other than the committed target.

Sequence tried: three real representatives proven with real storage proofs against game #21388 and finalized by an
unprivileged EOA: oldest unproven Regolith messenger ETH withdrawal (L2 105,240,078, old baseGas 287,624), an Ecotone
direct withdrawal to an EOA, an Isthmus fee-vault withdrawal (11.4446 ETH).

Barrier: all three deliver exactly (lockbox −value, target +value). Population: 0 never-finalized objects target the
portal or lockbox (`/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/L1/OptimismPortal2.sol:402,599`), 0 inner targets are L1CDM/portal (messenger revert path), max
gasLimit 8,415,632 < 2^24, 0 historical `success=false` Bedrock-era finalizations; `_tx.gasLimit` is a floor
(SafeCall forwards all gas). Remaining never-finalized objects are ordinary pending user withdrawals.

Evidence: `::test_T2b_bedrock_regolith_messenger_deliveredOnce`, `::test_T2b_ecotone_direct_eoa_deliveredOnce`,
`::test_T2b_isthmus_direct_feevault_deliveredOnce` (PASS); `bedrock-messagepassed-census.json.gz`.
