# OP Mainnet + Unichain planned migration model

Target described in the allowed develop notice: 2027-01-11, subject to governance. This is a model against Ethereum block 26430859/current deployed v9 state, not an executed migration.

## Current preconditions

| property | OP Mainnet | Unichain | migrator consequence |
|---|---|---|---|
| SystemConfig | `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` | `0xc407398d063f942febbcc6f80a156b47f3f1bda6` | distinct chains |
| l2ChainId | 10 | 130 | nonzero, distinct, ascending |
| Portal | `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` | `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` | currently separate proof domains |
| ProxyAdmin | `0x543bA4AADBAb8f9025686Bd03993043599c6fB04` | `0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4` | different PAs |
| ProxyAdmin owner | `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` | same | satisfies common-owner check |
| SuperchainConfig | `0x95703e0982140D16f8ebA6d158FccEde42f04a4C` | same | satisfies common-SCC check |
| last OPCM/version | `0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f` / 9.0.3 | same | permitted migration sequence |
| ASR | `0x23B2C62946350F4246f9f9D027e071f0264FD113` | `0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9` | separate today |
| DGF | `0xe5965Ab5962eDc7477C8520243A95517CD252fA9` | `0x2F12d621a16e2d3285929C9996f478508951dFe4` | separate today |
| lockbox | `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43` | `0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5` | separate today |
| DelayedWETH | `0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162` | `0x74ad145aC900F1DD5551F0C9E143314DC4022FCf` | migration reuses chain-0 WETH |
| INTEROP | false | false | re-migration guard passes |
| paused / CGT | false / false | false / false (state read during lane) | migration expects usable portals |

The validation code is `OPContractsManagerMigrator.sol:129-166,287-410`. It also requires starting type 5 or 9, a nonzero anchor with sequence below `uint64.max`, enabled super-game configs, bond 0 for type 5/nonzero otherwise, and a nonzero type-9 prestate.

## Atomic transition

1. Under delegatecall context, derive deployment salts from execution timestamp plus names and deploy fresh lockbox, DGF and ASR (`:168-222`).
2. Initialize the three as one shared domain (`:236-263`).
3. For each chain: retarget old DelayedWETH pause source, authorize the portal, enable ETH_LOCKBOX/INTEROP, attach/sweep liquidity, clear old-factory game implementations, switch the portal to the fresh ASR, then retarget the old ASR's lockbox (`:265-272,412-555`).
4. Register only supplied super-game configs in the new DGF; all super game args use l2ChainId zero because the super-root entries carry IDs (`:275-284`; `OPContractsManagerUtils.sol:445-490`).

All operations share one transaction. A revert in either chain rolls the deployment/state changes back.

## Proof/game survival

- Portal proof records store a game address, but finalization queries the portal's **current** ASR (`OptimismPortal2.sol:671-704`). Old-factory games are not registered in the fresh DGF, so prior proofs fail after cutover. The notice and `OPContractsManagerV2.sol:278-287` explicitly document reproving.
- Old games continue to exist for bond/pause accounting. Old factory implementations are cleared; old ASR and old DelayedWETH are pointed at the shared lockbox (`OPContractsManagerMigrator.sol:412-430,536-555`).
- The starting shared anchor, not any old per-chain game, establishes the new proof domain. Both portals then select their own entry by `systemConfig.l2ChainId()`.

## Pre-positioning attempts

| attempt | result / exact barrier |
|---|---|
| Predict and occupy shared CREATE2 addresses | Different deployer for an attacker; governance delegatecall context is the common PA-owner Safe. Timestamp salt also remains execution-dependent. Prefunding does not occupy an address. |
| Pre-register a game in the future DGF | DGF does not exist before the atomic transaction and is initialized/registered inside it. |
| Carry an OP/Uni old game into new ASR | New ASR verifies against fresh DGF UUID mapping; address mismatch. |
| Preserve an old withdrawal proof | Current-ASR finalization check deliberately invalidates it. |
| Duplicate chain IDs in the migration set | Explicit distinct and ascending checks at `:313-326`. |
| Re-run migration to drain shared lockbox/clear shared DGF | INTEROP re-migration guard at `:305-311`. |
| Create a harmful type-9 game now for future domain | Today's game embeds today's ASR and registers in today's DGF; neither is reused by the fresh shared proof domain. |

Conclusion: no permissionless “act now, triggers on migration” sequence survived. The strongest residual review target is an implementation mismatch in any off-chain two-chain super-root consumer, especially duplicate/order semantics, not the L1 migrator wiring itself.
