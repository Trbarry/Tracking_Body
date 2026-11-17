# Lane 30 — v9 assumption-marker audit

Command: `rg -ni "TODO|FIXME|XXX|HACK|nosemgrep|not strictly necessary|should never|cannot happen|assume|invariant|safe because|legacy|deprecated|spacer_" packages/contracts-bedrock/src`. Pinned source is v9 `ba6fcadb…`. The table groups repeated storage/event annotations but lists every matching line under `src/L1`; the verdict addresses whether U21 falsified the reason.

## `src/L1` matches

| File and matching lines | Meaning | U21 verdict |
|---|---|---|
| `DataAvailabilityChallenge.sol:169` | Refund math assumes percentage ≤100. | Preserved by explicit owner setter bound at `:171-175`. |
| `ResourceMetering.sol:138` | Floors L1 base fee at 1 gwei. | Unchanged v7-v9; U21 neither changes the config invariant nor the metering order. Economic approximation, not authorization. |
| `SuperchainConfig.sol:130-131` | Legacy global-pause getter. | U21 adds/uses local pause identifiers but retains global pause behavior; live Lockbox/ASR/WETH reads route to the same SC. |
| `L1CrossDomainMessenger.sol:25,27-28,34,36-37,109,111` | Two storage spacers and legacy `PORTAL()` getter. | Static-slot scan shows only `msgNonce` changed; spacer state survived. Resolved proxy implementation changed, storage did not shift. |
| `ETHLockbox.sol:66,68-69` | Old SystemConfig slot is now a spacer. | Slot 0 retained the old SystemConfig bytes; new SC pointer was written to slot 3. No reinterpretation. |
| `L1ERC721Bridge.sol:30,32-33` | Legacy SC spacer. | Final implementation remains v2.9.1 and compiler-declared static slots are unchanged. |
| `L1StandardBridge.sol:29,37,45,62,83,85-86,88,90-91,137,147,162,185,209,227,248,287-288,303-304,319-320,337-338` | Legacy getters/events and two storage spacers. | Final implementation remains v2.8.2 behind the same ChugSplash proxy; all compiler-declared static slots are unchanged. Event duplication is compatibility behavior, not a gate. |
| `SystemConfig.sol:95-96,107,240,242,392,484,502,584` | Legacy batch-inbox slot, deprecated overhead, legacy patch path, resource invariants. | Initializer explicitly re-zeroes the legacy slot; all compiler-declared static slots are unchanged. Only unstructured `OPCM_SLOT` changed from old to v9 OPCM. Resource config was preserved. |
| `OptimismPortal2.sol:64,66-67,69,72,74,77,79,81-82,89,91-92,97,99,101,103,105,107,118,120,130,132,326,332,338,344,353` | Storage spacers and legacy getters. | Static-slot scan shows no spacer movement; only resource `params` changed in block N. Pointer getters remain coherent. |
| `OptimismPortal2.sol:430,689` | Creation/starting timestamps are “not strictly necessary” defense in depth. | Still checked around proof/finalization. U21 does not reorder them after a new external call. |
| `OptimismPortal2.sol:438-439` | Legacy `rootClaim()` fallback vs super-root extraction. | INTEROP remained false at N and active type 9 uses the super-game branch. No branch confusion found. |
| `OptimismPortal2.sol:645` | Legacy messenger messages may be proven but never finalized. | Explicitly documented/suppressed behavior. New failure handling at `:639-653` keeps retryable messenger failures unfinalized. |
| `opcm/OPContractsManagerContainer.sol:102` | `0xbeefcafe` should have no production code. | `cast code 0x…beefcafe` at N returned `0x`; chainid is 1, so testing mode is false (`:101-106`). |
| `opcm/OPContractsManagerV2.sol:22,296,393,471` | Legacy import; migration release assumption; zero SC means new chain; missing address means deploy. | Release assumption is enforced by `isPermittedMigrateSequence` at `:297-303`. Load/deploy assumptions are governance execution paths and U21 migration was not run. |
| `opcm/OPContractsManagerMigrator.sol:268-269,370` | Preserve old pause resolver in call order; legacy games excluded from config path. | The sequence deliberately upgrades WETH before SystemConfig/Portal. Planned migration only. Current 84 sampled in-flight games are type 9, not legacy, and fork payout succeeds. |
| `opcm/OPContractsManagerUtils.sol:15,268,278,378` | Legacy proxy special cases; OZ-v5 initializer TODO. | Chug and Resolved routing is explicit. v5 namespaced state is checked both before and after initializer (`:352-386`), so the TODO is not an unchecked acceptance. |
| `opcm/StandardValidatorUtils.sol:202,275` | ZK TODO; permissioned legacy/super alternative. | OP type 10 is unset; U21 did not activate ZK or interop. |
| `OPContractsManagerStandardValidator.sol:479,550,1166-1167` | Legacy-game validation and optional-ZK TODO. | Validator behavior matches inactive ZK production state; no U21 reachability change. |
| `opcm/OPContractsManagerMigrationValidator.sol:121,168,175,212,475-476,499,530,557,563,566,574,622,633-634,637,639,644,649,651,656,719` | Comments/identifiers for shared invariants and legacy contracts. | These are validations, not authorization. The one blind spot is structural: `assertLegacyGamesCleared` iterates the same finite `clearedGameTypes()` list as Migrator, so both omit types 2,3,6,7,254,255,1337. Current OP entries for all omitted types are zero. |

## L1-executed matches outside `src/L1`

| File and lines | U21 verdict |
|---|---|
| `universal/Proxy.sol:25` | Address-zero call assumption remains an EVM execution property; U21 does not make `msg.sender==0` reachable. |
| `legacy/L1ChugSplashProxy.sol:36` | Failed `isUpgrading()` calls are ignored. Live owner is ProxyAdmin `0x543b…`, and `isUpgrading()` returned `false`; no owner-type change. |
| `universal/ReinitializableBase.sol:15` | “Never zero” is enforced immediately at `:16`. |
| `libraries/trie/MerkleTrie.sol:10,81` | Hexary assumption is configured by the library; key bound is enforced at `:82`. Unchanged proof code. |
| `libraries/Encoding.sol:71,87,111`; `libraries/LegacyCrossDomainUtils.sol:27` | `nosemgrep` permits fixed legacy/current ABI signatures where `abi.encodeCall` is unsuitable. Selectors are constants, not attacker-controlled strings. |
| `dispute/AnchorStateRegistry.sol:33,35-36,188-189,243-244` | Spacer preserved. The no-try/catch “legacy games gone” assumption is not hit by sampled type-9 games; moreover `closeGame` catches failed anchor updates before checking `isGameProper`. |
| `dispute/DelayedWETH.sol:42,44-45` | Spacer preserves old SystemConfig at slot 4; new Lockbox is slot 5. Balances, supply and withdrawal delay survive. |
| `universal/OptimismMintableERC20Factory.sol:23,38-39,71,73,78-79,136,139` | Layout/event/API compatibility only; final implementation unchanged. |
| `universal/StandardBridge.sol:16,30,33,35,38,138,140,146,148,255,297,321,366,392,403-404,410,428,446,468` | Legacy token detection/events and spacers; byte-identical v7-v9. U21 does not change custody checks. |
| `cannon/PreimageOracle.sol:428-429,505,552,647` | Gas/memory assumptions and explicitly bypassable EOA checks are unchanged; v8→v9 is formatting only and the live oracle address/version did not change. EIP-7702 bypass is already acknowledged and state/log reconstruction does not trust calldata origin. |
| `dispute/FaultDisputeGame.sol:254,371,382,409,418,434,448,454,464,471,475,487,495,527,582,656,705,708,731,737-738,742,770,774,780,936,971,1079` | Invariants are paired with checks/state-machine conditions. Registered implementation did not change at U21. |
| `dispute/SuperFaultDisputeGame.sol:263,308,405,416,443,452,468,482,488,498,505,517,525,557,612,674,677,700,706-707,711,739,743,749,902,937,1044` | Same. Relevant resolution/credit path was exercised against a real pre-U21 clone after the singleton upgrades. |
| `dispute/zk/SP1PlonkAdapter.sol:19`; `dispute/zk/ZKDisputeGame.sol:735` | Immutable verifier and EIP-150 try/catch suppressions are inactive on OP because game type 10 implementation is zero. |

No `TODO/FIXME/nosemgrep/assume/invariant` reason was falsified by the executed U21 state. The finite game-type list remains the strongest future-composition question.
