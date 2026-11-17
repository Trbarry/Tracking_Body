# Audit edge graph

This graph distinguishes a report aligned to a release from a report that actually reviewed the complete diff between two releases. The security-review index itself pins report commits and release tags (index at repository commit `e5423ae69b154100a77361d74eb6d7170b2c34aa`, `docs/security-reviews/README.md:17-59`). A cell in `AUDIT-COVERAGE-MATRIX.csv` therefore means “reviewed at the indexed release/commit,” not “proved the whole incoming edge safe.”

## Release-aligned reviewed edges

| Edge | Review evidence | Scope actually stated | Important exclusion / qualification |
|---|---|---|---|
| pre-Bedrock -> v1.0.0 | OpenZeppelin Bedrock+Periphery `93d3bd41`; Sherlock Bedrock `3f4b3c32`; Sherlock fix review `9b9f78c6` (index lines 17, 22-23; Sherlock final report PDF pp.1-2) | Bedrock L1/L2 contracts; Sherlock also listed op-node/op-geth | Separate snapshots and fix review; none states that it followed every historical object from OVM creation through Bedrock migration and later consumption. |
| v1.0.0 -> v1.2.0 | Trust `d1651bb2` (index line 24; report pp.5-6) | Changes since Sherlock in eight portal/messenger/bridge/SuperchainConfig contracts | DGF, games, DelayedWETH, OPCM, proof programs, and deployment scripts were outside that scope. |
| v1.2.0 -> v1.3.0 | Cantina MCP L1 `e6ef3a90` (index line 26; report pp.3-4) | Portal, L1 messenger, bridges, ERC20 factory, L2OutputOracle, SystemConfig | Deployment compatibility was reviewed, but no pre-v1 object or later migration consumer was in the same scope. |
| v1.3.0 -> v1.4.0 | Cantina MIPS `71b93116` (index line 28; report pp.3-4) | `MIPS.sol` | The L1 game/portal consumer and off-chain program were not jointly reviewed. Sherlock Fault Proofs audited untagged commit `5137f3b7` (final report pp.1-2), so it is corroborating but not release-edge coverage. |
| v1.4.0 -> v1.6.0 | Spearbit no-MIPS `1f708179` (index line 29; report pp.3-4) | Solidity dispute directory excluding the MIPS VM focus | Does not cover prior MIPS semantics or later SuperRoot/migration consumers. |
| v1.6.0 -> v1.8.0 | 3Doc FGETFD `52d0e60c` (index line 30; markdown sections “Summary” and “Conclusion”) | FGETFD/MIPS change | The sole suspected issue was concluded false-positive; no portal/game migration edge was in scope. |
| v1.8.0 -> v2.0.0 | Spearbit U13 `7d6d1543` (index line 36; report pp.3-5) | SystemConfig, Portal2, ASR, games and OPCM changes | It is an upgrade review, not a historical-object migration proof from v1 withdrawal records. |
| v2.x -> v4.0.0 | Wonderland `9df1fc15`, Cantina `e4b921c9`, Spearbit `7cd84fed`, and U16 `54c19f6a` (index lines 38, 40-41, 45; report finding sections) | Interop Portal/ETHLockbox/SuperRoot changes; U16 broader release delta | No indexed v3.0.0/v3.0.1 report exists. Spearbit Interop Contracts `6c80f23a` is not mapped to a release tag (index line 37). |
| v4.0.0 -> v4.1.0 | Spearbit U16a `47580169` (index line 47; report pp.3-5) | U16-to-U16a upgrade paths and related deploy/feature logic | Informational skipped-history findings were not severity-bearing closure proofs. |
| v4.1.0 -> v5.0.0 | Spearbit U17 `aeed7033` (index line 48; report pp.3-4) | U17 rollback/bond changes and fork-based tests | Report contains informational items only; no Medium+/Low closure record. |
| v5.0.0 -> v6.0.0 | Spearbit CGT `1f888ede` and Cantina U18 `87d406db` (index lines 51-52; reports pp.3-6) | Custom gas token paths; DGF/game compatibility and withdrawal target changes | Separate scopes; neither follows legacy ETH through every portal/lockbox/CGT mode transition. |
| v6.0.0 -> v7.0.0 | Cantina U19 `7cbcb58f` (index line 55; report pp.3-10) | L2CM, OPCM utilities, validators, DGF/ASR/SystemConfig | The report records three Medium and ten Low findings with no fixed Medium in its summary; it does not claim full historical closure. |
| v7.0.0 -> v8.0.0 | Cantina U20 `7799a246` (index line 58; report pp.3-8), plus untagged OPCMv2 review `a00b3972` (index line 56; report pp.3-6) | Super games, validators, SystemConfig, Portal and OPCMv2 migration | The OPCMv2 snapshot is untagged; U20 does not encompass every earlier migrator version. |
| v8.0.0 -> v9.0.0 | Cantina U21 `8fdb2775` (current index line 59; report pp.3-16) | U21 portal/lockbox/messenger/ASR/DelayedWETH/OPCM migration delta | Nineteen findings are Low and acknowledged (report p.3); this is the best edge review, not proof of pre-v8 histories. |

## Transitive paths not covered end-to-end by one report

1. **Withdrawal proof record.** Created as one `provenWithdrawals` record in v1.0.0 (`OptimismPortal.sol:77,308-325`), transformed into submitter-indexed records plus `proofSubmitters` in v2.0.0 (`OptimismPortal2.sol:114,132,366-377`), and consumed/deleted in v9.0.0 (`OptimismPortal2.sol:487,577,711`). The v1, U13, and U21 reports each cover only one stage; none names the full create-transform-delete/finalize path.

2. **Cross-domain gas envelope.** v1.2.0 creates a message gas purchase with `baseGas` (`CrossDomainMessenger.sol:187-190,338-349`); later portal/lockbox migrations change the wrapping and target path (v4.0.0 `OptimismPortal2.sol:396-416,630-679`); v9.0.0 computes a new dynamic/floor budget (`CrossDomainMessenger.sol:371-417`, `L1CrossDomainMessenger.sol:117-118`) before Portal finalization calls `SafeCall` (`OptimismPortal2.sol:627`). Trust, U16, and U21 do not share a single scope statement.

3. **Pause identity and retirement.** v4.0.0 Portal reads pause through SystemConfig and changes lockbox/ASR during `migrateToSuperRoots` (`OptimismPortal2.sol:294-295,396-416`). v9.0.0 places liquidity authority in `authorizedPortals` (`ETHLockbox.sol:72,124-168`) while migration validation separately checks retired portal and legacy-lockbox identifiers (`OPContractsManagerMigrationValidator.sol:536-574`). No report follows one pause record from creation through both identifier substitutions and validator consumption.

4. **Anchor/game lineage.** v2.0.0 Portal accepts a respected game and stores per-submitter proofs (`OptimismPortal2.sol:292-377`). v4.0.0 ASR changes what counts as a proper game and sets a new anchor (`AnchorStateRegistry.sol:241-249,296-340`). v9.0.0 migration validation compares shared ASR/start anchor (`OPContractsManagerMigrationValidator.sol:481-521,663-681`). U13, U16, U20, and U21 cover adjacent pieces, never the entire pre-existing-game path.

5. **Portal ETH -> shared pooled liquidity.** v4.0.0 migration moves Portal balance into a lockbox and can swap lockboxes (`OptimismPortal2.sol:380,396-416`). v9.0.0 retains portal authorization as a mapping without a deauthorization path (`ETHLockbox.sol:72,124-168,220-231`) and finalization unlocks/relocks pooled ETH (`OptimismPortal2.sol:614-663`). Wonderland/U16 and U21 are separate scopes; neither covers all old authorized portals as objects.

6. **SystemConfig legacy words -> OPCM configuration.** v9.0.0 still stores unrestricted-width `batcherHash`, deprecated `overhead`, packed `scalar`, and `l2ChainId` (`SystemConfig.sol:106-151,361-394`) while OPCMv2 reads configuration for upgrades (`OPContractsManagerV2.sol:536-667`). MCP-L1, U13, OPCMv2, U19, and U21 each inspect a snapshot, but no scope follows divergent legacy values through every skipped upgrade.

7. **DelayedWETH/game bond object.** U13 introduced/retouched ASR/DGF/DelayedWETH at v2.0.0; U16/U16a changed redeployment/migration; v9 migrator validates game bonds/durations then clears implementations (`OPContractsManagerMigrator.sol:330-405,537-539`). No one report covers a bond/game created before migration, transformed into shared infrastructure, and paid after migration.

8. **Proof-program output consumed by L1 games.** Cantina MIPS (`71b93116`, report pp.4-7), Spearbit no-MIPS (`1f708179`, pp.4-15), 64-bit Cannon reviews, and Kona (`86910c91`, pp.7-34) audit different program generations. U20/U21 audit L1 game/anchor consumers. No report's scope includes both a pre-existing game, the exact program transition across all generations, and final Portal withdrawal consumption.

## Primary gap

The dominant unaudited shape is **history-sensitive object continuity**, not an unaudited current function: an object is created under an old namespace or gas/finality invariant, transformed by one or more migrators, and consumed by a later validator/finalizer. The next wave should build skipped-upgrade fork tests around paths 1-3 before broadening to new current-code review.
