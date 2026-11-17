# ATK-T2 fork tests — legacy carry-through (OVM 1.0 / OVM 2.0 / Bedrock-era objects consumed by v9)

Model: Opus 5.5 (CLAUDE.md exception, Mythos 5.2 quota exhausted until 2026-11-22).

    cd /home/user/Tracking_Body/optimism-bedrock-u21-megahunt/test/poc/attack-wave/T2
    forge test -j 1 -vv          # 9 tests, all PASS (fork: read-only archive proxy :7545, L1 block 26,433,900)

`foundry.toml` = u21-work template + `evm_version = "osaka"` + `via_ir = true`; `lib/forge-std` -> v9 checkout.

Every T2a/T2b object is a REAL OP Mainnet L2 withdrawal that is live in `L2ToL1MessagePasser.sentMessages` and was
never finalized. Each is proven with a REAL storage proof (`eth_getProof` at L2 159,653,251, fetched read-only by
`scripts/attack-wave-T2/build_fixtures.py`) against the REAL OP game #21388 `0x668513Ab…8b65` whose
`rootClaimByChainId(10)` equals the recomputed output root `0x05bfbbc4…4111` (asserted in `setUp`). The game is
resolved honestly (warp past its clock, `resolveClaim`, `resolve` -> DEFENDER_WINS), the proof matured by warp, and
finalized by an unprivileged EOA through `finalizeWithdrawalTransactionExternalProof`. No vm.store, no mock, no
privileged prank in T2a/T2b. T2c uses one stated vehicle: `vm.store(L1CDM slot 204 = L2StandardBridge)` + prank L1CDM
to enter `onlyOtherBridge`; the classification/pair/mint/escrow code is deployed bytecode.

| Test | Object | Result |
|---|---|---|
| `test_T2a_ovm1_unrelayed_v0_deliveredOnce` | OVM 1.0 migrated v0, nonce 668, 25.714 ETH finalizeETHWithdrawal, never relayed | delivered exactly once to the committed recipient; 2nd finalize and direct replay fail |
| `test_T2a_ovm2_unrelayed_v0_deliveredOnce` | OVM 2.0 migrated v0, nonce 132,971, 0.0899 ETH | same |
| `test_T2a_ovm1_relayed_v0_600ETH_blocked` | OVM 1.0 v0 nonce 16,753, 599.999 ETH, paid pre-Bedrock | proof accepted; finalize reverts `OptimismPortal_L1CDMCallFailed` (0x979d93bf); lockbox and recipient unchanged |
| `test_T2a_ovm2_relayed_v0_35555ETH_blocked` | OVM 2.0 v0 nonce 110,269, 35,555.8 ETH, paid pre-Bedrock | same |
| `test_T2b_bedrock_regolith_messenger_deliveredOnce` | oldest unproven Bedrock-era (Regolith, L2 105,240,078) messenger ETH withdrawal, old baseGas 287,624 | delivered exactly |
| `test_T2b_ecotone_direct_eoa_deliveredOnce` | direct L2ToL1MessagePasser withdrawal (Ecotone era) to an EOA | delivered exactly |
| `test_T2b_isthmus_direct_feevault_deliveredOnce` | fee-vault withdrawal 11.4446 ETH, unproven | delivered exactly |
| `test_T2c_legacyEscrowPair_reclassifiedMintable_frozen` | L1StandardBridge escrow `deposits[EDU][EDU]` = 90,170e18 written pre-Bedrock; the L1 token answers ILegacyMintableERC20 | v9 takes the mint branch; token `mint` reverts (0x58973715); escrow has no release path |
| `test_T2c_negativeControl_nonMintableLegacyPair_releases` | WBTC legacy pair | escrow branch releases exactly |
