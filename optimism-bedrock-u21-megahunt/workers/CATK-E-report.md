# CATK-E report — migration poisoning and orphaned-state composition

Model: Codex (GPT-5). Date: 2026-11-17. Fork: Ethereum block `26433900`, hash
`0xf5b501c77cfc14ad3f0ea6a0ba2a7b91b510bab4bc91de5da99b052aa257507e`.
Target: deployed OPCM `0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f`, `version() = 9.0.3`.

## Outcome

No bounty candidate. Eleven independent fork experiments passed. Every permissionless state mutation
found in the OP/Unichain orphan and migration-relevant objects was either absent from the deployed
migrator's read set, confined to attacker-owned value, invalidated by the fresh DGF/ASR registration
boundary, or protected by an exact caller gate. A fresh post-migration shared game successfully proved
and finalized a withdrawal, so the negative results are not caused by a dead migrated system.

Candidate count: **0**. No `CAND-CATK-E-*` file was created. Best-looking hypothesis (orphan/live
anchor poisoning) scores `-4` after future-only, no-impact, and documented-orphan deductions.

## Experiment matrix

| ID | Test/command | Result | Disposition |
|---|---|---|---|
| E01 | `test_E01_moveBothGen2Anchors_migrationDoesNotReadThem` | permissionlessly moved both gen-2 anchors; zero gen-1/gen-2 migration accesses; calldata root installed | K01 |
| E02 | `test_E02_advanceLiveAnchor_anchorSlotNotReadByMigration` | attacker advanced live anchor; slot 2 not read/written; game unregistered in shared ASR | K01 |
| E03 | `test_E03_mutateEveryLegacyWETH_allUnreadAndRedeemable` | balance/allowance/unlock mutated on all 11 legacy WETHs; zero migration accesses | K03 |
| E04 | `test_E04_currentWETHStateSurvivesRewire_andBothWithdraw` | both live WETH states preserved and redeemable after shared-WETH rewire | K03 |
| E05 | `test_E05_gamesAndProofsOnBothChains_doNotSurviveAuthoritySwap` | two attacker games/proofs recorded; both lose authority at migration | K04 |
| E06 | `test_E06_depositDonateForceETH_conservedAndUnauthorized` | deposits/donations/forced ETH exactly pooled; sticky auth gives EOA no call right | K05 |
| E07 | `test_E07_gen1AndRetiredGameMutationGates` | gen-1 updates, old-type creates, type-5 non-proposer create, owner setters all fail | K02 |
| E08 | `test_E08_prefundFutureProxyAddresses_noCollisionOrUnsafeRoot` | pre-funded future addresses still deploy; only attacker surplus remains | K05 |
| E09 | `test_E09_lateFailureRollsBackAllState_thenRetrySucceeds` | real late decode failure is fully atomic; corrected retry succeeds | K06 |
| E10 | `test_E10_repeatedMigrationRejected_stateUnchanged` | exact `ChainAlreadyMigrated` selector; no delta | K06 |
| E11 | `test_E11_postMigrationGameAndWithdrawal_payFromSharedPool` | new shared game finalizes 1 ETH OP withdrawal | positive control |

Exact command: `forge test -j 1 --match-contract CATKEMigrationTest -vv`. Result: **11/11**;
full harness including sanity: **12/12**. Detailed ledger:
`mirror/CATK-E/evidence/EXPERIMENTS.md`.

## Top deterministic kills

1. **Anchor poison has no migration consumer.** Fresh ASR initialization uses only
   `_input.startingAnchorRoot` (`OPContractsManagerMigrator.sol:254-263`). Historical ASRs have zero
   accesses; current `anchorGame` slot 2 is not read. The old current ASR reinitializer uses its fixed
   `getStartingAnchorRoot()` (`:545-555`).
2. **Pre-proofs die at the factory/registry boundary.** Old game records persist, but old DGF types are
   cleared (`:536-543`) and the shared ASR rejects both game addresses. A new shared game works.
3. **No partial state.** A type-5 argument error that occurs only after both per-chain mutation loops
   reverts all pointers, features, balances, deployments, and Safe nonce. Repeat is preflight-blocked
   by INTEROP (`:305-311`).
4. **Liquidity poison only adds assets.** `200810526200523469952700` wei was exactly conserved. Direct
   lockbox calls fail authorized-caller/owner checks; balance-only prefunding cannot occupy CREATE2.

## Notable compatibility observation (not a candidate)

Both v2.2.2 orphan ASRs report the current type-9 anchor games claim-valid, then revert in
`setAnchorState` because they call legacy `l2BlockNumber()`. Selector-compatible finalized type-8
games still move the anchors. No deployed consumer reads those anchors, so there is no scoped impact.

## Highest-value next experiment

When the Lagoon Safe payload is published, replay its **byte-exact calldata, chosen starting root,
timestamp, and game configs** on a private fork after the same full poison corpus, then diff every
storage access and post-migration withdrawal against this baseline. This is the only material unknown:
the future governance inputs; the deployed-code and current attacker-state paths are closed.
