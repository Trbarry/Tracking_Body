# CF4 report — Storage and initializer historian mirror

## Verdict

No reportable vulnerability survived. Candidate score: **0/10; no candidate filed**. The strongest
apparent P0—the first word of a live legacy portal proof being treated as a dispute-game address—
is unreachable because v9 uses a disjoint nested mapping and checks its timestamp before `status()`.

## Completed scope

- Normalized field-by-field layouts for 18 contract families across all 20 releases v1.0.0–v9.0.0,
  including slot, offset, width, type, label, initializer byte, renames/retypes/spacers/gaps/packing.
  Early snapshot omissions were reconstructed from declarations/inheritance.
- Reconstructed OP Mainnet proxy history through block 26433900: 170 `Upgraded` logs, 70
  AddressManager changes, 101 persistent implementation boundaries, ChugSplash binary searches,
  ResolvedDelegateProxy mappings, first 80 plus contract-specific slots, and EIP-1967/admin/OZ-v5
  slots before/after each change.
- Full mapping-event census over blocks 12600000–26433900 in <=10,000-block chunks: 1,217,983
  matched logs. Exact samples were resolved into current raw storage.
- Read initializer state at every implementation boundary and all 102 observed bare
  implementation/helper addresses.
- Ran two named block-26433900 fork tests (`forge -j 1`): 2 passed, 0 failed.

## Facts locked

1. Legacy portal proofs persist. Sample hash `0x90f452...f89b`, written at block 20061894, retains
   both slot-52 struct words unchanged at 26433900. V9 marks base 52 as a spacer and uses
   `[hash][submitter]` at base 57 (`OptimismPortal2.sol:64-67,94-116`). `deleteProvenWithdrawal`
   reverts `Unproven` before `status()` (`:711-725`).
2. `finalizedWithdrawals` remains base 51; `proofSubmitters` is base 60. Portal blacklist/respected
   state moved from 58/59 to current ASR bases 5/6. Two old respected-type events explain stale
   slot 59; the full census found zero blacklist and zero proof-deletion events.
3. Messenger replay mappings remain successful=203, failed=206; legacy 201/202 are spacers. A
   2021 production relay remains one under 203. Current slots 204/205 are `0xdead` / nonce 273005.
4. StandardBridge deposits remain nested base 2 across every release; real pre- and post-Bedrock
   token-pair entries read correctly through today's layout.
5. Non-zero stale direct words exist (portal 53/54/56/59, messenger 151/251, bridge 1/50,
   ERC721 50, current WETH 4), but each remains a v9 spacer. OPCM/validator/migrator grep found no
   reader; StandardValidator uses typed getters.
6. Portal/SystemConfig/messenger/bridges initialized 1→2 at block 22990599 and 2→3 at 23491328;
   messenger's byte is slot 0 offset 20, all others offset 0. ProtocolVersions correctly starts at
   3. U20/U21 StorageSetter reset/initialize/verify/restore is atomic; no live post-block zero.
7. All current material implementations are locked; historical zero-byte cases are helper or
   constructor-only code. No material bare-implementation initialization path was found.
8. ASR/WETH layout reorders are generation-isolated. Live games independently pin gen0, gen1, or
   current proxies. Ink, Soneium and Unichain were all born on Portal 3.10.0 (nested slot 57).

## Primitives

- **PRIM-CF4-01:** live immutable slot-52 proof tombstones, currently namespace-isolated.
- **PRIM-CF4-02:** atomic privileged StorageSetter initializer-reset critical section.
- **PRIM-CF4-03:** live games pin all three ASR/WETH generations.

## Strongest negatives

- Exact junk in both real legacy proof words cannot affect the v9 getter/delete path.
- Exact junk in messenger 201/202 cannot affect successful/failed mappings.
- No observed X→Y production slot collision; every stale changed-meaning word is a spacer.
- No block boundary exposes a real implementation with a callable zero initializer.

## Deliverables

Primary: `mirror/CF4/STORAGE-ARCHAEOLOGY.md`, `mirror/CF4/storage-lineage.json`.
Evidence: `mirror/CF4/evidence/{op-mainnet-storage-history,direct-slot-liveness,state-event-census,
mapping-archaeology,implementation-initializer-locks,game-generation-samples,
sibling-portal-births}.json` and `fork-test-results.md`. Reproducers are in `mirror/CF4/tools/` and
`/home/user/u21-work/codex-CF4/h/test/CF4StorageArchaeology.t.sol`.

## Limits and next wave

Mapping keys written without named events cannot be enumerated; runtime direct-slot write+clear
cycles wholly between upgrade checkpoints are not reconstructible from boundary snapshots; token
balances were not exhaustively enumerated for every historical implementation.

Next edges: (1) exercise future/raw migrators against real slot-52 tombstones; (2) model any new
external callback introduced while StorageSetter is active; (3) run retirement/bond/lockbox flows
against all three live game generations, not only current getters.
