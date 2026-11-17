# ATK-E report — migration poisoning and orphaned-state composition

Model: **Opus 5.5** (`claude-opus-5-5`), under the user-approved exception in CLAUDE.md (Mythos 5.2 quota exhausted until 2026-11-22 00:00 UTC).
Fork: L1 26433900 (`:8545`), real deployed bytecode, OPCM 9.0.3 `0x2d91e6F2…`, planned OP(10)+Unichain(130) migrate.
Tests: `test/poc/attack-wave/E/` (4 tests, all PASS). Evidence: `evidence/attack-wave/E/`.

| id | hypothesis | command / test | result | outcome |
|---|---|---|---|---|
| E-01 | gen-2 ASR anchor poisoning alters migrate | `test_E01_poison_then_migrate_vs_clean` + `diffacc.py` | gen2 moved OK; migrate touches 0 legacy registries; 34 accounts / 193 reads / 134 writes identical | KILL ATTACK-E-01 |
| E-02 | gen-0 ASR writable | test_E01 P2 | `tryUpdateAnchorState` revert, `setAnchorState` Unauthorized | KILL ATTACK-E-02 |
| E-03 | donations/forced ETH/deposits break solvency or migrate | test_E01 P4-P6 | shared = clean + 6 ETH exactly; only read diff = portal resource params | KILL ATTACK-E-03 |
| E-04 | live-ASR anchor advance poisons legacy reinit / shared anchor | test_E01 P3 + asserts | no advanceable game; anchors carried; rootChanged=false | KILL ATTACK-E-04 |
| E-05 | attacker legacy games survive/bridge into shared domain | `test_E04_postMigration_poisoned_objects_inert` | unregistered, NoImplementation, InvalidAnchorGame, gen2 false | KILL ATTACK-E-05 |
| E-06 | pre-fund predicted CREATE2 shared addresses | `test_E08_prefund_predicted_shared_addresses` | migrate OK, same addresses, +5 ETH surplus | KILL ATTACK-E-06 |
| E-07 | forced failure / partial / retry / repeat | `test_E09_failed_then_retry_and_repeat` | atomic; retry identical; repeat ChainAlreadyMigrated; gas 3.25M << 2^24 | KILL ATTACK-E-07 |
| E-08 | post-migration validator falsification | PASS A `test_post_donation_breaks_validator_equality` | known PRIM-0902, no value | KILL ATTACK-E-08 |
| E-09 | sticky retired-lockbox authorization x poison | PASS A `test_post_target_oldLockbox_lockSucceeds_unlockBlocked` + E-01 diff | self-harm only; known audit Low | KILL ATTACK-E-09 |

Candidates: 0. Decision (mission 5): an attacker cannot pre-position today so that the honest migrate fails or
installs different state: the migrate read set is closed under every attacker-writable object we found (state-diff
equality), and all value pushed in is swept as surplus.

Highest-value next experiment: the same state-diff differential against the real superchain-ops migrate task
calldata once published (C10 reopen condition: calldata/tooling differing from the deployed OPCM path), including
its startingAnchorRoot source.
