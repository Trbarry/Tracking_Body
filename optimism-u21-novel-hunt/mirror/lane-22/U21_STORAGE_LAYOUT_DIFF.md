# U21 storage-layout and reinitialization diff (lane 22)

## Scope and evidence

Pinned source trees:

- v7 `a7c88c8d636ceb9944ea0edaf7d033da258778ab` (`op-contracts/v7.0.0`)
- v8 `f45a5ccfebcdf6da3f5b09cbc512667c063730b7` (`op-contracts/v8.0.0`)
- v9 `ba6fcadbc57eb99918c5b0f14f57c72527f531e3` (`op-contracts/v9.0.0`)

The primary deployed comparison is exact end-of-block state N-1 (26430858) versus N (26430859). `PRE_UPGRADE_STATE.json` and `POST_UPGRADE_STATE.json` contain 41 receipt-touched proxies, implementations, versions, initialized versions, ETH balances, getters, and raw slots 0–69 (plus DGF/SystemConfig 70–109 and messenger 201–207/251–254). `N_MINUS_1_TO_N_DIFF.json` is the mechanical diff. `N_TO_LATER_DIFF.json` repeats the same declared raw-slot set for all 41 proxies at 26433900. Dynamic mappings are handled separately rather than inferred from empty mapping head slots.

## Snapshot comparison

The following compares every named upgradeable L1 snapshot byte-for-byte. v7 and v8 are identical for all 13. v8 and v9 are identical except the three rows marked “changed.”

| Snapshot | v7 = v8 | v8 = v9 | Result |
|---|---:|---:|---|
| OptimismPortal2 | yes | yes | no field change |
| SystemConfig | yes | yes | no linear-layout change; unstructured slots checked live |
| ETHLockbox | yes | **no** | legacy `systemConfig` → spacer; add `superchainConfig` |
| AnchorStateRegistry | yes | **no** | legacy `systemConfig` → spacer; packed add `ethLockbox` |
| DisputeGameFactory | yes | yes | mapping schemas unchanged |
| DelayedWETH | yes | **no** | legacy `systemConfig` → spacer; add `ethLockbox` |
| SuperchainConfig | yes | yes | no field change |
| L1CrossDomainMessenger | yes | yes | legacy spacer/inherited ordering unchanged |
| L1StandardBridge | yes | yes | no field change |
| L1ERC721Bridge | yes | yes | no field change |
| OptimismMintableERC20Factory | yes | yes | no field change |
| ProxyAdmin | yes | yes | no field change |
| DataAvailabilityChallenge | yes | yes | no field change; not upgraded in this receipt |

Representative SHA-256 prefixes/suffixes: Portal `a8b04a…547b`, SystemConfig `0bcf03…0fd8`, DGF `60fec0…c1c5`, messenger `75f195…963c`, bridge `7a5307…63dc`, ERC721 bridge `d52302…f3ca`, factory `f119c6…47f4`, ProxyAdmin `2d885b…8b78`, and DAC `6ea55a…f435` are identical in all three trees. Changed hashes are ETHLockbox `469c36…0052` → `9a6197…6e76`, ASR `8d9317…6d02` → `47daf1…802c`, and DelayedWETH `e8128f…81c7` → `bfc00c…438c`.

### Exhaustive changed-field table

| Contract | v7/v8 field | v9 interpretation | New v9 field |
|---|---|---|---|
| ETHLockbox | slot 0 offset 2, 20-byte `ISystemConfig systemConfig` | same 20 bytes, private `address spacer_0_2_20` | slot 3 offset 0, `ISuperchainConfig superchainConfig` |
| AnchorStateRegistry | slot 0 offset 2, 20-byte `ISystemConfig systemConfig` | same 20 bytes, private `address spacer_0_2_20` | slot 6 offset 12, `IETHLockbox ethLockbox`, packed after `GameType` (4 bytes) + `uint64` (8 bytes) |
| DelayedWETH | slot 4 offset 0, 20-byte `ISystemConfig systemConfig` | same 20 bytes, private `address spacer_4_0_20` | slot 5 offset 0, `IETHLockbox ethLockbox` |

Snapshot evidence: v8 ETHLockbox `snapshots/storageLayout/ETHLockbox.json:16-36` versus v9 lines 16-43; v8 ASR lines 16-64 versus v9 lines 16-71; v8 DelayedWETH lines 16-43 versus v9 lines 16-50. v9 source deliberately labels each displaced field as a legacy spacer (`src/L1/ETHLockbox.sol:66-78`, `src/dispute/AnchorStateRegistry.sol:33-59`, `src/dispute/DelayedWETH.sol:42-48`). No mapping or array type changed, no legacy field was deleted without a same-size spacer, and no gap was narrowed.

### Mainnet deployed interpretation

| Contract/slot | N-1 raw / decoded | N raw / v9 meaning | Finding |
|---|---|---|---|
| ETHLockbox slot 0 | `0x00000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb2900001`: init=1, old SystemConfig `0x2290…B290` | identical; init=1 plus opaque spacer bytes | nonzero legacy address preserved, never read by v9 |
| ETHLockbox slot 3 | zero | `0x…95703e0982140d16f8eba6d158fccede42f04a4c` | correct shared SuperchainConfig |
| ASR slot 0 | same packed init/SystemConfig word as lockbox | identical; SystemConfig portion is spacer | nonzero legacy address preserved |
| ASR slot 6 | `0x0000…0000688271ab00000009` | `0x322b47ff1fa8d5611f761e3e275c45b71b294d4300000000688271ab00000009` | high 20 bytes become lockbox; retirement timestamp and type 9 low 12 bytes unchanged |
| DelayedWETH slot 4 | `0x…229047fed2591dbec1ef1118d64f7af3db9eb290` | identical spacer | nonzero legacy address preserved |
| DelayedWETH slot 5 | zero | `0x…322b47ff1fa8d5611f761e3e275c45b71b294d43` | correct lockbox |

Sibling-chain dependency additions were the same shape: each lockbox slot 3 became shared SuperchainConfig; each WETH slot 5 became its chain lockbox; each ASR slot 6 gained its chain lockbox while retaining the low 12 bytes. Soneium retained game type 5 (`...688274ff00000005`), while OP/Ink/Unichain retained type 9. The old SystemConfig bytes in lockbox slot 0, ASR slot 0, and WETH slot 4 remained identical on every chain.

## Inheritance and special-slot review

`ReinitializableBase` contributes only immutable `INIT_VERSION`, not proxy storage (`src/universal/ReinitializableBase.sol:10-24`). `ProxyAdminOwnedBase` declares no state and resolves either the EIP-1967 admin slot or the messenger's AddressManager mapping (`src/universal/ProxyAdminOwnedBase.sol:45-76`). Initializable therefore owns the packed `_initialized`/`_initializing` bytes shown by each snapshot.

The messenger is deliberately exceptional: its snapshot reserves slot 0 offsets 0–19 for the legacy proxy layout, placing `_initialized` at offset 20 and `_initializing` at 21 (`snapshots/storageLayout/L1CrossDomainMessenger.json:1-28`). `ResolvedDelegateProxy` stores its implementation name and AddressManager in mappings based at slots 0 and 1 (`src/legacy/ResolvedDelegateProxy.sol:13-35`). The bridge's ChugSplash proxy uses the EIP-1967 implementation/admin constants (`src/legacy/L1ChugSplashProxy.sol:155-169,199-218`). Direct reads and ProxyAdmin getters agreed for each proxy type; no reserved slot overlapped implementation state.

Portal's full snapshot is byte-identical. In particular, `finalizedWithdrawals`, `provenWithdrawals`, and `proofSubmitters` stay at slots 51, 57, and 60 with identical value types (`snapshots/storageLayout/OptimismPortal2.json:37-42,86-119`). Nonzero OP legacy spacers also stayed bit-exact N-1→N: slot 53 retained the shared SuperchainConfig bytes, slot 54 retained `0xdfe97868233d1aa22e815a266982f2cf17685a27`, slot 56 retained DGF `0xe596…2fA9`, and slot 59 retained `0x…66e1c08300000000`. Slots 52, 58, and 61 stayed zero. They remain spacers in v9, so none acquired a new meaning.

## Initializer semantics

| Contract | v7 | v8 | v9 | Mechanism |
|---|---:|---:|---:|---|
| Portal / SystemConfig / messenger / StandardBridge / ERC721Bridge | 3 | 3 | 3 | `reinitializer(initVersion())` |
| ETHLockbox / ASR / DGF / DelayedWETH | 1 | 1 | 1 | same |
| SuperchainConfig | 2 | 2 | 2 | same |
| MintableERC20Factory | 1 | 1 | 1 | OZ `initializer` |

These are constructor arguments to `ReinitializableBase` (v9 examples: Portal `src/L1/OptimismPortal2.sol:264-280`, SystemConfig `src/L1/SystemConfig.sol:183-219`, lockbox `src/L1/ETHLockbox.sol:86-102`, ASR `src/dispute/AnchorStateRegistry.sol:83-104`, WETH `src/dispute/DelayedWETH.sol:50-63`). OZ permits a version only when `_initialized < version` (`lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol:95-114`). There is therefore no naturally open version gap.

U21 legitimately re-ran same-version initializers through OPCM's privileged StorageSetter dance: install StorageSetter, clear exactly one initializer byte at the caller-supplied offset, install/call the real implementation, reinstall StorageSetter to reject OZ-v5 state, then restore the real implementation (`src/L1/opcm/OPContractsManagerUtils.sol:352-386`). Every relevant initializer also calls `_assertOnlyProxyAdminOrProxyAdminOwner` (definition `src/universal/ProxyAdminOwnedBase.sol:102-105`). Thus the unchanged final initialized byte is expected and does not imply the initializer never ran.

At N, all 11 unique final implementations themselves were locked: ten had direct slot 0 ending `ff`; messenger had `ff` at offset 20. Fork test `test_implementationInitializersAreDisabled` verifies those bytes. `test_publicReinitializersAreClosedToUnprivilegedCaller` calls all 11 proxy initialization entry points as `0xA11CE`; every call fails. Result: no public replay and no useful implementation takeover.

## Exact N-1 → N deployed delta

The mechanical raw-slot/implementation diff has 25 records: the shared SuperchainConfig plus six changed implementations per chain (SystemConfig, Portal, lockbox, messenger, WETH, ASR). The stable final implementations are DGF, StandardBridge, ERC721Bridge, and MintableERC20Factory on every chain.

| Touched proxy | OP Mainnet direct N-1→N delta | Ink | Soneium | Unichain | Cause |
|---|---|---|---|---|---|
| SuperchainConfig | implementation 2.4.3→2.5.0; no raw field delta | shared | shared | shared | code upgrade; initializer replayed same guardian/version |
| SystemConfig | implementation 4.0.0→4.3.0; OPCM slot `0x1951…896a`→`0x2d91…331f` | same | same | same | install v9 OPCM provenance; all structured/unstructured config otherwise retained |
| OptimismPortal2 | implementation 5.8.0→6.1.0; slot 1 traffic delta | implementation only | implementation only | implementation only | code upgrade; OP slot 1 was earlier block-N deposit metering, not U21 |
| ETHLockbox | implementation 1.3.1→2.0.0; slot 3 zero→`0x9570…4a4c`; balance traffic delta | implementation; slot 3 same | implementation; slot 3 same | implementation; slot 3 same | new shared SuperchainConfig dependency; OP balance was earlier deposit |
| Messenger | implementation 2.11.1→2.13.0; slot 205 `0x42a0e`→`0x42a0f` | implementation only | implementation only | implementation only | code upgrade; OP nonce was earlier deposit message |
| StandardBridge | no final implementation, raw-slot, or balance delta | same | same | same | StorageSetter/reinitializer cycle restored the already-live implementation and values |
| ERC721Bridge | no final implementation or raw-slot delta | same | same | same | same |
| MintableERC20Factory | no final implementation or raw-slot delta | same | same | same | same |
| DisputeGameFactory | no final implementation or linear-slot delta; dynamic args changed | no linear delta; type-9 args changed | no config delta | no linear delta; type-9 args changed | owner-set dynamic payload; see `DGF_MAPPING_DIFF.md` |
| DelayedWETH | implementation 1.5.1→2.0.0; slot 5 zero→OP lockbox | slot 5 zero→Ink lockbox | slot 5 zero→Soneium lockbox | slot 5 zero→Unichain lockbox | new pause dependency |
| AnchorStateRegistry | implementation 3.9.0→4.0.0; slot 6 high20 zero→OP lockbox | high20→Ink lockbox | high20→Soneium lockbox | high20→Unichain lockbox | packed new pause dependency; low96 invariant |

Exact ASR slot-6 words:

| Chain | N-1 | N |
|---|---|---|
| OP Mainnet | `0x000000000000000000000000000000000000000000000000688271ab00000009` | `0x322b47ff1fa8d5611f761e3e275c45b71b294d4300000000688271ab00000009` |
| Ink | `0x000000000000000000000000000000000000000000000000688271ab00000009` | `0xbd4abb321138e8eddc399ce64e66451294325a1400000000688271ab00000009` |
| Soneium | `0x000000000000000000000000000000000000000000000000688274ff00000005` | `0x67b4de6ffa66ef201ea6099a89ca397d56622e3100000000688274ff00000005` |
| Unichain | `0x0000000000000000000000000000000000000000000000006882777b00000009` | `0x08ba0023ed60c7bd040716dd13c45fa0062df5c5000000006882777b00000009` |

Upgrade-caused state mutations:

1. All four SystemConfigs changed only unstructured `OPCM_SLOT` from OPCM 8.0.1 to 9.0.3. All named contract addresses, owner, chain ID, start block, and feature values were retained.
2. All four lockboxes filled slot 3 with the shared SuperchainConfig; authorization entries remained true.
3. All four WETH proxies filled slot 5 with their lockbox.
4. All four ASRs filled the high 20 bytes of slot 6 with their lockbox without changing game type or retirement timestamp.
5. DGF dynamic configuration changed as documented in `DGF_MAPPING_DIFF.md`: OP type-5 proposer, and type-9 absolute prestate on OP/Ink/Unichain. Implementations and bonds did not change.
6. The same initializer versions were restored, and replayed fields that were meant to remain constant did remain constant.

Three OP-only direct deltas came from an earlier transaction in block N, not tx 358 (the upgrade): transaction `0x762e0faad7b2a2800bb7348e7444a4a0d76b7c5c1b43b84b6bc56c19326cfda2`, index 341, emitted `ETHLocked`, the deposit, and messenger events at log indexes 633–636. It increased lockbox balance by exactly `4,204,691,597,090,892,114` wei (event data `0x3a5a10baeaac2952`), incremented messenger slot 205 from `0x42a0e` to `0x42a0f`, and updated Portal resource-metering slot 1. The U21 receipt contains no corresponding deposit/lock event.

No expected dependency write was absent. Conversely, no unchanged field was unexpectedly rewritten. The full exact words are in `N_MINUS_1_TO_N_DIFF.json`; dynamic and authorization entries are in `DGF_MAPPING_DIFF.md`, `PAUSE_AND_AUTHORIZATION_MAPPINGS.md`, and `WITHDRAWAL_MAPPING_SAMPLES.json`.

## N → later

The same raw slots, implementations, versions, and balances were checked for all 41 proxies at block 26433900. No implementation, init word, dependency slot, SystemConfig feature, or OPCM pointer changed after U21. Normal traffic caused:

- DGF game counts: OP 21378→21389, Ink 2639→2640, Soneium 8533→8537, Unichain 17681→17691.
- ASR `anchorGame` updates on all four chains.
- Portal resource-metering updates on all four chains.
- Messenger nonce increments: OP +94, Ink +19, Soneium +20, Unichain +19.
- Lockbox balance increases on OP and Unichain; OP DelayedWETH gained exactly 0.08 ETH (a game bond).

These mutable values are enumerated in `N_TO_LATER_DIFF.json`. DGF arguments, pause/auth entries, and sampled withdrawal entries remained identical to N.

## Conclusion

No silent semantic corruption or initializer opening survived falsification. All three snapshot changes preserve the displaced nonzero address as a spacer and write the new dependency into bytes proven zero at N-1. Portal withdrawal mappings are bit-identical across the boundary, all new v9 dependencies are live and nonzero, Soneium's type-5 configuration is respected, and implementation contracts are locked. No candidate was promoted.
