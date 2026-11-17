# ATTACK-E-08 — post-migration falsification of the migration validator by 1-wei donations (KILLED: known, no impact)

**Hypothesis.** `assertRetiredContractsClean` requires `portal.balance == 0` and `legacyLockbox.balance == 0`
(OPContractsManagerMigrationValidator.sol:559, 565-567); an attacker donating after migrate makes the review fail.

**Barrier.** Pre-migration donations are swept (E-03), so only a post-migration donation trips MIG-CHAIN-n-150/160;
it is a false alarm in an off-chain review step, sweepable by the owner, moving no value. Same root cause as PASS A
PRIM-0902 / `Lane09PostMigration.t.sol::test_post_donation_breaks_validator_equality` (PASS). No SCOPE 1.4 impact.
