# Lane 22 report — Storage and Reinitialization

## Outcome

No production-reachable vulnerability survived falsification. No candidate was promoted. U21's three storage-layout changes preserve legacy bytes as explicit spacers and place new dependencies in bytes proven empty at N-1. Same-version initializers were intentionally replayed through a privileged atomic StorageSetter flow, ended at the correct version, cannot be called by an unprivileged account, and all final implementation contracts are locked.

The strongest result is a high-confidence negative: historical withdrawal proof/finalization entries, pause/authorization mappings, packed ASR fields, and all live dependency pointers remain coherent across N-1→N and through block 26433900.

## Boundaries and method

Source was read only from the pinned v7/v8/v9 trees. No other lane output or prior finding was read. State changes were never sent to a public or shared fork. Public RPC use was passive `eth_getLogs`; state testing used `forge test` forks at N-1/N.

Coverage:

- Compared 13 storage snapshots field-for-field across v7→v8→v9; hashes prove all but ETHLockbox, ASR, and DelayedWETH are byte-identical.
- Read 41 receipt-touched proxies at exact N-1 and N: first 70 slots each, extended DGF/SystemConfig slots through 109, messenger operational ranges, EIP-1967/admin resolution, versions, initialized bytes, getters, and balances.
- Queried relevant hashed entries: SystemConfig features/OPCM; lockbox authorization; SuperchainConfig pause identifiers; DGF types 0–10 plus dynamic arguments; Portal withdrawal mappings/arrays.
- Repeated the declared raw-slot set, implementation, version, and balance for all 41 at block 26433900, then rechecked targeted mappings.
- Tested the real deployed bytecode with five deterministic fork tests; 5 passed, 0 failed.

The receipt's 46 distinct log emitters resolve to those 41 proxies, the common owner Safe, and four per-chain AddressManagers. The Safe/AddressManagers are direct execution/legacy-resolution contracts, not additional upgradeable implementations. All four direct ProxyAdmins were separately checked at N-1/N/later: owner, AddressManager, `upgrading=false`, and proxy-type mappings were stable (`mirror/lane-22/U21_PROXY_IMPLEMENTATION_MAP.md`).

Mapping keys cannot be enumerated from storage, so “full” mapping coverage means every entry identified by live configuration/events and every entry implicated by U21—not unknown arbitrary keys. Exact schemas and data are in the lane artifacts.

## Storage invariants and results

### Layout

Only three snapshots differ v8→v9:

1. ETHLockbox slot 0 offset 2 `systemConfig` becomes an address spacer; new `superchainConfig` is slot 3.
2. ASR slot 0 offset 2 `systemConfig` becomes an address spacer; new `ethLockbox` occupies slot 6 offset 12 after the 4-byte game type and 8-byte retirement timestamp.
3. DelayedWETH slot 4 `systemConfig` becomes an address spacer; new `ethLockbox` is slot 5.

Evidence: v8/v9 snapshots and v9 declarations at `op-v9.0.0/packages/contracts-bedrock/src/L1/ETHLockbox.sol:66-78`, `src/dispute/AnchorStateRegistry.sol:33-59`, and `src/dispute/DelayedWETH.sol:42-48`. Complete matrix and live words: `mirror/lane-22/U21_STORAGE_LAYOUT_DIFF.md`.

All four chains satisfy:

- displaced legacy SystemConfig bytes are nonzero and bit-identical N-1→N;
- every new field was zero before U21 and equals the intended dependency after;
- ASR low 96 bits are invariant (Soneium stays type 5; others type 9);
- no v9 dependency is zero;
- portal legacy spacers remain spacers, including nonzero OP slots 53/54/56/59.

### Reinitialization state machine

```text
real v8 impl / closed initializer
  → StorageSetter
  → clear exactly one OZ-v4 initializer byte
  → real v9 impl + authorized initialize(...)
  → StorageSetter + reject any OZ-v5 initializer state
  → real v9 impl / same version closed
```

This is exactly `OPContractsManagerUtils.upgrade` at `src/L1/opcm/OPContractsManagerUtils.sol:352-386`. `ReinitializableBase` stores the version as an immutable (`src/universal/ReinitializableBase.sol:10-24`); OZ enforces monotonic versions (`lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol:95-114`). All proxy initializers use their intended historical version and enforce ProxyAdmin/owner access (`src/universal/ProxyAdminOwnedBase.sol:102-105`).

Messenger is the notable packing exception: `_initialized` is slot 0 offset 20, not offset 0 (`snapshots/storageLayout/L1CrossDomainMessenger.json:1-28`). U21 used the correct offset. This is recorded as PRIM-2205 for future bundle review.

Direct implementation slot-0 reads show `0xff` at each initializer byte. Both `test_implementationInitializersAreDisabled` and `test_publicReinitializersAreClosedToUnprivilegedCaller` pass.

### Exact upgrade delta

Upgrade-caused state is limited to:

- implementation changes for shared SuperchainConfig and SystemConfig/Portal/lockbox/messenger/WETH/ASR on each chain;
- SystemConfig `lastUsedOPCM` 8.0.1→9.0.3 on each chain;
- lockbox slot 3, WETH slot 5, ASR slot 6 high 20 bytes;
- DGF game arguments: OP type-5 proposer and type-9 absolute prestate on OP/Ink/Unichain.

DGF/StandardBridge/ERC721Bridge/factory final implementations are unchanged. DGF implementations and bonds are unchanged; Soneium has no type 9. `DGF_MAPPING_DIFF.md` records exact payloads and sources (`DisputeGameFactory.sol:298-327`; `LibGameArgs.sol:9-23,61-103,116-142`).

OP Portal slot 1, lockbox balance, and messenger nonce changed because transaction `0x762e0f…cfda2` at block-N index 341 preceded the upgrade at index 358. Its event amount exactly equals the `4.204691597090892114 ETH` balance delta. These are not U21 writes.

No expected dependency write was absent. No supposedly retained field changed unexpectedly.

### Withdrawals

Portal mapping bases and `ProvenWithdrawal` packing are identical in v7/v8/v9 (`src/L1/OptimismPortal2.sol` v7:37-43, v8:38-44, v9:39-45; v9 snapshot lines 37-42 and 86-119). Publicnode logs supplied three recent proof/extension pairs and three finalized hashes. Nested mapping words, dynamic-array lengths/elements, getters, and finalization flags are bit-identical at N-1, N, and later. Exact event/slot data: `WITHDRAWAL_MAPPING_SAMPLES.json`. Fork test: `test_historicalWithdrawalMappingsAreBitExact`.

### Pause and authorization

All four portal authorization entries are raw 1/true. Global zero, all four portal, and all four lockbox pause entries are raw zero/false at all checkpoints. ETH_LOCKBOX=true; INTEROP=false; CUSTOM_GAS_TOKEN=false. The v9 resolution chain is SystemConfig/Portal/ASR/WETH → ETHLockbox → SuperchainConfig (`SystemConfig.sol:570-576`, `ETHLockbox.sol:111-114`, `AnchorStateRegistry.sol:135-143`, `DelayedWETH.sol:98-108`). Exact slots: `PAUSE_AND_AUTHORIZATION_MAPPINGS.md`.

The planned migrator checks pause before pointer mutation and repoints old WETH/ASR (`OPContractsManagerMigrator.sol:488-555`); its validator requires legacy pause routing (`OPContractsManagerMigrationValidator.sol:612-660`). No current bypass was found.

## N → 26433900

All 41 proxy implementations, versions, initializer words, U21 dependency slots, SystemConfig features, and OPCM pointers remain stable. Only ordinary mutable state changed: DGF counts, ASR anchors, Portal metering, messenger nonces, OP/Unichain lockbox balances, and one 0.08 ETH OP WETH bond. Exact words are in `N_TO_LATER_DIFF.json`; DGF args and sampled withdrawal/pause/auth entries stayed at N values.

## Rejected ideas

- REJ-2201: legacy SystemConfig/new-field collision — killed by exact spacers and zero-before/nonzero-after dependency locations.
- REJ-2202: initializer replay/singleton takeover — killed by access checks, final versions, direct `0xff` reads, and fork calls.
- REJ-2203: withdrawal mapping corruption — killed by identical layouts and six real historical samples.
- REJ-2204: pause identifier silently unpauses — killed by raw mapping reads and live pointer checks.
- REJ-2205: DGF argument corruption — killed by clean decoding, unchanged implementations/bonds, correct Soneium type, and later stability.

## Primitives and follow-up compositions

- PRIM-2201: atomic same-version reset/replay is safe here but makes initializer completeness and external-call ordering a first-class future-upgrade invariant.
- PRIM-2202: ASR adds a 20-byte dependency to a live packed word; future widening/repacking deserves byte-mask tests.
- PRIM-2203: pause authority follows a mutable dependency pointer; planned shared-lockbox migration is the highest-value cross-contract composition to keep testing.
- PRIM-2204: dynamic DGF argument tails can change while linear slots look stable; future upgrade tooling should semantic-diff them.
- PRIM-2205: initializer byte offsets differ by proxy variant; future bundle metadata should be generated/validated against deployed layout, especially messenger offset 20.

Recommended follow-up attention (not candidates):

1. Replay a future OP Mainnet+Unichain shared-lockbox migration and invariant-test all old/new ASR/WETH pause paths plus ProxyAdmin routing.
2. Mutation-test OPCM reset metadata across standard, ChugSplash, and Resolved proxies; assert any wrong byte offset fails atomically without neighbor corruption.
3. Add semantic DGF-argument decoding to upgrade validation, including chain-specific respected type and absolute-prestate intent.

## Artifact index

- `mirror/lane-22/{PRE_UPGRADE_STATE,POST_UPGRADE_STATE,N_MINUS_1_TO_N_DIFF,N_TO_LATER_DIFF}.json`
- `mirror/lane-22/U21_STORAGE_LAYOUT_DIFF.md`
- `mirror/lane-22/U21_PROXY_IMPLEMENTATION_MAP.md`
- `mirror/lane-22/DGF_MAPPING_DIFF.md`
- `mirror/lane-22/PAUSE_AND_AUTHORIZATION_MAPPINGS.md`
- `mirror/lane-22/WITHDRAWAL_MAPPING_SAMPLES.json`
- `mirror/lane-22/test/StorageBoundary.t.sol` and `FORGE_TEST_OUTPUT.txt`
- `primitives/PRIM-2201.md` through `PRIM-2205.md`
- `rejected/REJ-2201.md` through `REJ-2205.md`
