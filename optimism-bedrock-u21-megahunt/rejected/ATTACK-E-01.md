# ATTACK-E-01 — orphaned gen-2 ASR anchor poisoning alters the planned migrate (KILLED)

Lane ATK-E (Opus 5.5, CLAUDE.md quota exception). Inputs: PRIM-F5-01 x C10, lead L8.

**Hypothesis.** An unprivileged EOA moves the anchor of the orphaned v2.2.2 registries (OP 0x1c68ECfb…, Unichain
0xD5D0e176…) with a live-registry game; the later honest OP+Unichain `migrate` reads that state, so the deployed
addresses, starting anchor, claim validity or pooled custody change.

**Sequence executed.** `test/poc/attack-wave/E/test/ATKE_Poison.t.sol::test_E01_poison_then_migrate_vs_clean`: snapshot -> clean migrate (state-diff
recorded) -> revert -> attacker `OP_GEN2.setAnchorState(game#20094)` OK, `UNI_GEN2.setAnchorState(game#16394)` OK
(+ P2..P7) -> migrate (recorded) -> compare.

**Barrier.** `migrate` never touches a gen-2 (or gen-0) registry: 0 occurrences of 0x1c68…/0xD5D0…/0x18DA…/0x318A… in
`evidence/attack-wave/E/migrate-poisoned.accesses.txt`; clean and poisoned runs access the same 34 accounts, the same
193 read slots and the same 134 written slots with identical final values (`E01-access-diff.txt`). The Migrator
loads only `portal.anchorStateRegistry()` (the gen-3 registry) — /home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/L1/opcm/OPContractsManagerMigrator.sol:489-492 (oldASR = portal.anchorStateRegistry() at :491).
The shared anchor comes from `_input.startingAnchorRoot` (:258-262), which op-deployer takes from a config file
(op-deployer/pkg/deployer/manage/migrate.go:33), not from chain state. After migrate gen-2 is even weaker: the portal
mirror getters now read the shared ASR, so `gen2.isGameClaimValid(game#20094)` flips to false (`E04-post-migration.txt`).

**Evidence.** forge-E01.txt (PASS), migrate-{clean,poisoned}.accesses.txt, E01-access-diff.txt.
