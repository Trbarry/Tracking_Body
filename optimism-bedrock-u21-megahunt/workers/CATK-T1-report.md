# CATK-T1 report — fix-regression mirror

## Run identity and legal/scope discipline

- Assigned model: `gpt-daybreak-blue-latest`.
- Date: 2026-11-17 UTC.
- Fork only: L1 `http://127.0.0.1:8545`, pinned block 26,433,900.
- Attacker: unprivileged `0x00000000000000000000000000000000000A11cE` (or another explicitly
  unprivileged proof submitter). No privileged prank, `vm.store`, public transaction, third-party
  target, personal data, or public disclosure.
- In-scope consumers only: the four listed-chain SystemConfig/portal/L1CDM paths and ASR/DGF/WETH as
  consumers of those proxies. The test involving a 90,000 ETH forged proof only deletes its
  terminal-invalid record locally and never targets or transfers third-party funds.
- Final command: `forge test -j 1 --match-path test/FixRegressionCATKT1.t.sol -vv` from
  `/home/user/u21-work/codex-CATK-T1/h`.
- Result: **15 passed, 0 failed, 0 skipped**. Full output:
  `mirror/CATK-T1/evidence/forge-output.txt`.

`ATTACK-MATRIX.md` already listed all 15 broad ATK-T1 titles. I did not inspect the prohibited ATK-T1
worker, test, evidence, or rejection outputs. Each experiment below therefore changes a concrete
precondition visible from the matrix/closures: fresh post-U21 clones (01), attacker-created
invalidation transitions (02), proof written after finalization (03), a real value-bearing v0 object
(04), public pointer writers (05), fresh far-future games (06), deployed super-game gas boundaries
(07), a real v1 two-reserve object (08), a live four-chain deposit (09), direct attacker initializer
calls (10), a wrapper that changes `msg.sender` (11), paired valid/terminal-invalid real proofs (12),
fully ABI-valid binding rewrites (13), a paid move in a concrete old-prestate game (14), and one
deployed legacy WETH history per chain (15). The corresponding prior barriers are C15, the known
anchor lifecycle family, C5, C6, C8, C12/C17, the try/catch invariant, C6/D06, C16/D02, D12, L7,
C4/C5, D12/C15, L1, and L8 respectively.

## Experiment ledger

| ID | Hypothesis / changed precondition | Test | Result and exact barrier | Disposition |
|---|---|---|---|---|
| 01 | Fresh post-U21 sibling-registry clone, all four chains | `test_T01_registryBinding_postUpgradeCreateCannotNameSiblingRegistry` | All registered clones carry current ASR; type-5 attacker creation is proposer-gated. Foreign-bound post-retirement implementation absent. | `rejected/ATTACK-CATK-T1-01.md` |
| 02 | Attacker induces blacklist/retirement/type transition after anchor finality | `test_T02_anchorInvalidationTransitionsAreGuardianOnly` | All 12 transition calls revert at guardian authorization; live anchors unchanged. | `rejected/ATTACK-CATK-T1-02.md` |
| 03 | New submitter proves a real withdrawal after it finalized | `test_T03_reproveAfterFinalizationCannotExecuteTwice` | Re-prove succeeds; second execution reverts on hash-global `finalizedWithdrawals`. | `rejected/ATTACK-CATK-T1-03.md` |
| 04 | Real value-bearing version-0 first relay across gas boundary | `test_T04_versionZeroFirstRelayHasNoFinalizedUnknownOutcome` | Every completed call records success/failure; every failure atomically rolls back portal finalization. | `rejected/ATTACK-CATK-T1-04.md` |
| 05 | Attacker rewrites pause pointer/feature after upgrade | `test_T05_pausePointerCannotBeMutatedByAttacker` | Portal initialize and feature setter reject attacker on all chains; pointer chain remains aligned. | `rejected/ATTACK-CATK-T1-05.md` |
| 06 | Fresh arbitrarily far-future live super game | `test_T06_farFutureSuperAnchorRequiresInvalidGameToWin` | Primitive anchors only after intentionally unchallenged invalid game wins; type 5 rejects attacker. Same acknowledged fault-proof assumption. | `rejected/ATTACK-CATK-T1-06.md` |
| 07 | Deployed super-game `closeGame` at 38 gas budgets | `test_T07_closeGameGasStarvationCannotSkipAnchorUpdate` | Success always updates anchor; starvation reverts before persistent tail state. | `rejected/ATTACK-CATK-T1-07.md` |
| 08 | Real v1 withdrawal between outer/inner reserve regimes | `test_T08_safeCallReserveSamplesAreAtomicOrReplayable` | Eight budgets produce delivered/replayable or atomic-retry state only. | `rejected/ATTACK-CATK-T1-08.md` |
| 09 | Live deposit reads legacy portal slots 52/58/59 | `test_T09_legacyPortalSpacersAreDeadOnPermissionlessDeposit` | Storage access recording on four portals finds no read/write to any target base slot. | `rejected/ATTACK-CATK-T1-09.md` |
| 10 | Permissionless same-version portal/messenger initializer | `test_T10_initializerIdempotenceCannotBeReachedPermissionlessly` | Every call reverts; sentinel-dependent resource params and version remain unchanged. | `rejected/ATTACK-CATK-T1-10.md` |
| 11 | Wrapper launders proposer identity for type 5 | `test_T11_type5TxOriginGateRejectsDirectAndWrappedAttacker` | Direct and wrapped calls fail on all factories because attacker `tx.origin` persists. | `rejected/ATTACK-CATK-T1-11.md` |
| 12 | Delete mature valid proof vs real terminal-invalid proof | `test_T12_deleteProofPredicateSeparatesValidAndInvalidGames` | Valid deletion reverts; only `CHALLENGER_WINS` record deletes; global execution state unaffected. | `rejected/ATTACK-CATK-T1-12.md` |
| 13 | Fully ABI-valid attacker rewrite of validator-only bindings | `test_T13_validatorBindingsCannotBeChangedByAttacker` | All live bindings correct; initializer/factory writers reject attacker on four chains. | `rejected/ATTACK-CATK-T1-13.md` |
| 14 | Pay bond and attack concrete open old-Kona-prestate game | `test_T14_oldPrestateWrappedAttackOnlyCreatesAChallenge` | Claim tree grows 1→2, but root remains claim-invalid until actual defender win/finality. | `rejected/ATTACK-CATK-T1-14.md` |
| 15 | Recover another user's bonds from one legacy WETH per chain | `test_T15_legacyDelayedWETHCannotReleaseSomeoneElsesBond` | Owner paths revert; caller namespace releases only its own one wei; all legacy escrow unchanged. | `rejected/ATTACK-CATK-T1-15.md` |

## Candidate decision

Candidates: **0**. No sequence produced theft, insolvency, permanent/temporary fund freeze, incorrect
withdrawal, or another exact `SCOPE.md` §1.4 impact. Several primitives are reachable (post-finalize
re-prove, far-future proposal, invalid-proof deletion, old-game attack), but their impact is blocked
by an invariant/authorization boundary or has the same root cause and impact as an acknowledged v9
finding. Accordingly, no `candidates/CAND-CATK-T1-*` file was created and no score was inflated past
the `<7` rejection threshold.

The complete condition-to-source map is `mirror/CATK-T1/FIX-CONDITION-MAP.md`. Test SHA-256:
`235df5bc8f89bf25695797e3bba3fb9181f820b4ec00a218570a29f3c7c80ca7`.

## Highest-value next experiment

Execute queue B05 as one deterministic dual-program test: take the exact immutable prestate and
oracle transcript of OP game index 21,377 (`0x031ac6f1…e1df`), replay the same permissionless
user-originated portal-deposit input through that Kona program and the first later program containing
each candidate soundness fix, and assert a concrete `old accepts / new rejects` output-root delta.
Only if such a delta exists, use that exact root/trace in the already-open local game and drive it to
`DEFENDER_WINS`; otherwise record the programs' equal result as the barrier. This directly supplies
the missing premise in T14 without relying on a malicious batcher, operator, or third-party system.

## Stopped lines

- Guardian/ProxyAdmin/factory-owner/proposer mutations: stopped as privileged-only.
- Far-future anchor, stale anchor, post-finalize prove, tx.origin, delay repricing and spacer behavior:
  stopped where the same root cause/impact is acknowledged or documented.
- Any hypothesis needing harm to a DEX, bridge, oracle, token implementation, or other third-party
  protocol: not executed because it is outside authorization.
- T14 stopped after the entrypoint mutation because no concrete old-Kona accepted-invalid semantic
  delta was evidenced; the report does not misstate that broader program-soundness question as closed.

