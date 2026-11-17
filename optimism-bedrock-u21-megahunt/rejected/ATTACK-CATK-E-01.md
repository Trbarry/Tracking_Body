# ATTACK-CATK-E-01 — poison orphan/live anchors before OP+Unichain migration

## Hypothesis

An ordinary account can advance the orphan v2.2.2 or live v4.0.0 anchor and thereby make the planned
OPCM migration revert, select the attacker root, or recognize an attacker game afterward.

## Exact sequence tried

1. On both chains, pass each live type-9 anchor game to the gen-2 registry. The registry reports the
   game claim-valid, but `setAnchorState` reverts when v2.2.2 calls missing `l2BlockNumber()`.
2. Use selector-compatible finalized type-8 games instead. OP advances `138585637 -> 155450031` and
   Unichain advances `22024228 -> 58101694` from an unprivileged caller.
3. Separately create/resolve/finalize an attacker OP type-9 game and set it as the live v4 anchor.
4. Execute deployed OPCM 9.0.3 for OP+Unichain under `vm.record`.

## Deterministic barrier

The fresh shared ASR is initialized exclusively from `_input.startingAnchorRoot`
(`op-v9.0.0/src/L1/opcm/OPContractsManagerMigrator.sol:254-263`). The migrator updates only each
portal's current ASR and passes its fixed `getStartingAnchorRoot()`
(`OPContractsManagerMigrator.sol:545-555`). It never enumerates historical ASRs or reads current
`anchorGame`.

E01 records zero accesses to all gen-1/gen-2 ASRs and installs the supplied root. E02 records no read
or write to current ASR slot 2 (`anchorGame`); the poisoned old anchor persists only in the newly
orphaned registry, and its game is unregistered in the shared ASR.

Evidence: `CATKEMigrationTest.test_E01_moveBothGen2Anchors_migrationDoesNotReadThem` and
`test_E02_advanceLiveAnchor_anchorSlotNotReadByMigration` (11/11 suite pass).

## Disposition and honest score

Rejected. The mutation is current and permissionless, but it has no consumer in migration and no
eligible impact. Score: `+8 -5 future-only -3 no eligible impact -4 documented orphan/migration
separation = -4`.

