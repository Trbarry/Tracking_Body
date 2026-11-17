# ATTACK-E-05 — attacker legacy games created before/at migration survive into or bridge to the shared domain (KILLED)

**Hypothesis.** Wrong-root type-9 games created on the per-chain factories in the migration block (P7) stay usable:
registered/claim-valid in the shared ASR, able to move a registry anchor that a shared game reads, or the legacy
factory keeps creating games.

**Sequence executed.** `test/poc/attack-wave/E/test/ATKE_Poison.t.sol::test_E04_postMigration_poisoned_objects_inert`: poison + migrate, then reads and calls.

**Barrier.** shared.isGameRegistered(opAtkGame)=false, isGameClaimValid=false (shared DGF is a new proxy; shared
retirementTimestamp = migration time, AnchorStateRegistry.sol:130-132); legacy DGF type 9 cleared ->
`create` REVERT `NoImplementation(uint32)` 0x031c6de4 (Migrator:537-540); a fresh shared-DGF game is not registered in
the legacy ASR and `oldASR.setAnchorState(sharedGame)` REVERT `AnchorStateRegistry_InvalidAnchorGame`; gen2
`isGameClaimValid(sharedGame)` = false. Legacy anchors have no on-chain reader (no factory can create games on them),
so even an uncontested wrong legacy game only returns its creator's own bond.

**Evidence.** forge-E04-E08-E09.txt, E04-post-migration.txt.
