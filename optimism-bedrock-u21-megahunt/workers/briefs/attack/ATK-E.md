# LANE E — MIGRATION POISONING AND ORPHANED-STATE COMPOSITION

Inputs: PRIM-F5-01 x C10; lead L8; PRIM-0901, PRIM-0904, PRIM-2903, PRIM-3005 (PASS A), PRIM-CF2-01,
PRIM-CF4-03; orphaned gen-2 ASRs (v2.2.2) whose anchors anyone can move and which accept the live
registry's legacy games as claim-valid; retired lockboxes with sticky authorizations; the exact deployed
`OPContractsManagerV2.migrate` (OPCM 9.0.3 `0x2d91e6F2…`). The OP+Unichain migration is planned
(Lagoon target 2027-01-11) — anything that depends on it is FUTURE-ONLY unless current permissionless
pre-positioning is hidden, irreversible or unvalidated and produces an unavoidable later impact.

Mission:
1. Permissionlessly mutate EVERY attacker-writable orphaned or legacy state that exists today on OP and
   Unichain: move gen-2 ASR anchors (`setAnchorState` with any claim-valid game), create games on old
   factories if still possible, donate ETH to old/new lockboxes and portals, create games/proofs on the
   current factories, anything else writable without privilege (enumerate by reading every external
   non-view function of every legacy/orphaned contract — F5's `chains/*/HISTORY.md` and
   `evidence/F2-impl-history-*.json` list them).
2. Then execute the exact planned migration on a fork (reuse PASS A `test/poc/lane09/` /
   `Lane07_Migration.t.sol`; the Safe delegatecall prank is allowed ONLY for this documented action).
3. Trace every value read by OPCM, migrator, portal, ASR, DGF, DelayedWETH and lockboxes during and
   after `migrate` (`vm.record` / `-vvvv` trace) and test whether the poisoned state alters: deployed
   addresses, selected/starting anchor roots, migration validity (revert = governance DoS, low value),
   post-migration claim validity, pause coverage, pooled solvency (shared lockbox balance vs liabilities),
   withdrawal availability.
4. Test partial failure / retry and a repeated migration.
5. Decide: can an attacker pre-position TODAY so that a later honest governance execution
   deterministically fails or installs unsafe state that review would not catch? Kill if governance can
   trivially inspect and avoid it.
