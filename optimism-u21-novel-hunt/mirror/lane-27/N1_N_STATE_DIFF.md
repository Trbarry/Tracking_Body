# Lane 27 N-1 -> N -> later state diff

## N-1 (26430858) to N (26430859)

- Portal: implementation/version 5.8.0 -> 6.1.0. ASR, lockbox and derived DGF pointers unchanged. ResourceMetering slot 1 changed only in its normal block/timestamp accounting fields.
- ASR: implementation/version 3.9.0 -> 4.0.0. The new ETHLockbox field was populated. `respectedGameType=9`, `retirementTimestamp=1753379243`, DGF, starting root and current anchor stayed unchanged.
- DGF: implementation and `gameCount=21378` unchanged. Only type-5 proposer and type-9 prestate packed args changed; their implementations and initialization bonds stayed fixed.
- Anchor at both blocks: game `0x51024A83c2F94c8e70014A732d3e2559CdceeB1D`, root `0x1780727e85b9a6a2f265739802b24afdeb1d3f86b6f8b0bdd762c7b0c6ff0846`, sequence 1794262423.

## N to later block 26433900

- DGF count increased 21378 -> 21389.
- Anchor advanced permissionlessly to game `0x55A5CFd4270340b3822BB9D8eebdb450ac206f95`, root `0xca640c8db165091618e7edc23995b250d4b3e6dfbe918bded900a38efbf76fbc`, sequence 1794298459.
- The latest 30 games at the later block are all type 9, respect-snapshotted, ASR-bound, and `IN_PROGRESS`; see `GAME_INVENTORY.md`.

## Relevant v8 -> v9 source diff

`diff -U0` results: `SuperFaultDisputeGame.sol`, `Encoding.sol` and `Hashing.sol` have zero changed lines. `SuperPermissionedDisputeGame`, `FaultDisputeGame`, `LibGameArgs` and DGF changes are formatting/minor registration support. Material changes are:

- ASR 3.9 -> 4.0: pause/guardian/SuperchainConfig resolution moves from SystemConfig to ETHLockbox while preserving the old slot as a spacer.
- Portal 5.8 -> 6.1: lockbox/pause hardening and migration support; the game-type-selected super-root proof branch is unchanged.
- Migrator: fresh shared infrastructure, re-migration prevention, chain-ID uniqueness/order, game-config validation, liquidity/old-factory cleanup and atomic portal cutover.

Source anchors: `AnchorStateRegistry.sol:89-144`; `OptimismPortal2.sol:390-492,528-572`; `OPContractsManagerMigrator.sol:129-285,287-410,475-555`.
