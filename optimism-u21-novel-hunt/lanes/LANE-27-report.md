# Lane 27 report — AnchorStateRegistry and dispute migration

Date: 2026-11-17. Independent mirror of lane 07. Source pin: `/home/user/ethereum-optimism/op-v9.0.0` at the v9.0.0 commit specified by `LANE_CONTEXT.md` (`ba6f...`); comparison pin `/home/user/ethereum-optimism/op-v8.0.0`. Chain evidence is from the pinned passive forks and the allowed OP Mainnet read endpoint. No public-network transaction was sent.

## Result

No reportable candidate survived falsification, so lane 27 writes no `CAND-27xx.md`.

The strongest reusable primitive is real but currently contained: a permissionless type-9 creator can register a hash-consistent super root containing duplicate or unsorted chain IDs; Solidity, Go and Kona raw decoders accept that shape, and portal/tooling lookup selects the first duplicate. On the real fork this created a proper, respected game, but it remained `IN_PROGRESS` and claim-invalid. The canonical fault-proof transition derives the next root from the existing chain universe and uses a sorting constructor. No consumer disagreement or path to an erroneous `DEFENDER_WINS` was found.

Five primitives and six precise rejections are recorded separately.

Selected raw call/storage results are preserved in `mirror/lane-27/ONCHAIN_READS.md`.

## 1. Deployed game identities and configuration

`GameTypes` names type 5 `SUPER_PERMISSIONED` and type 9 `SUPER_CANNON_KONA` (`packages/contracts-bedrock/src/dispute/lib/Types.sol:68-82`). At Ethereum block 26430859, OP's DGF `0xe5965Ab5962eDc7477C8520243A95517CD252fA9` had only these implementations:

| type | implementation | version | bond | role |
|---:|---|---:|---:|---|
| 5 | `0x5C3eb47cB0174aea522a2a9Ae79487139A53D691` | 1.1.0 | 0 | proposer-authenticated, instant defender |
| 9 | `0x19AF533Cc2A2A55786DCB8672aA5717e64213208` | 0.8.0 | 0.08 ETH | permissionless interactive super fault game |

Other queried production types (0, 1, 4, 6, 7, 8, 10) were zero. OP ASR `0x23B2...D113` respected type 9. Soneium's separate ASR `0x4890...F473` respected type 5 and its separate DGF registered the same type-5 implementation with proposer `0x00c164...e1b8`; type 9 was unset.

Bare implementation `gameType()` calls return zero because the getter reads clone immutable args. Factory registration keys and deployed clone getters establish the identities: every inspected recent OP clone reports type 9. Runtime validation is detailed in `mirror/lane-27/U21_PROXY_IMPLEMENTATION_MAP.md`: type 5 exactly matches v9 deployed runtime; type 9 matches after substituting its four constructor immutables (depth 73, split 30, max clock 302400, extension 10800).

### Packed clone args

The DGF is permissionless at `create`, checks implementation/exact bond/fresh UUID, builds a deterministic CWIA clone, calls `initialize`, then records it (`DisputeGameFactory.sol:142-225`). For configured games the immutable payload is:

```text
creator[20] || rootClaim[32] || parent L1 block hash[32] || gameType[4]
|| extraData[n] || implementationArgs[m]
```

The UUID is `keccak256(abi.encode(gameType, rootClaim, extraData))` (`:228-245`). Only the owner sets implementations, args and bonds (`:298-326`).

`LibGameArgs` defines 124-byte permissionless args and 40-byte super-permissioned args (`dispute/lib/LibGameArgs.sol:9-23,61-103,116-143`). OP's values are:

- Type 5: ASR `0x23B2...D113`; proposer `0xc27ba3E0Fc01567a5E57Ae0c391AA98cECBA5bE0`.
- Type 9: prestate `0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9`; VM `0xaCc005DCd857B401e4732E6F7837135A22825cfA`; OP ASR; DelayedWETH `0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162`; legacy chain ID field zero.

At U21, type-5 proposer changed from `0x473300...3A33` to `0xc27b...5bE0` and type-9 prestate from `0x031ac6...e1df` to `0x03e5...37c9`; implementation addresses and bonds did not change.

### Recent games

At block 26433900 the last 30 games (indices 21359-21388) were all type 9, `IN_PROGRESS`, unresolved, respect-snapshotted, and bound to the OP ASR. Each had exactly one `(chainId=10, outputRoot)` entry. Nineteen were created by `0x473300...3A33`, eleven by `0xc27ba3...5bE0`; the switch was not perfectly monotone (index 21378 returned once to the former). Full proxies, roots, extra-data components, sequence numbers and timestamps are in `mirror/lane-27/GAME_INVENTORY.md`.

Creator identity is not an authorization boundary for type 9: source has no allowlist, and the fork test created a live clone from the test contract by paying the bond. Type 5 is different: initialization requires `tx.origin == proposer()` (`SuperPermissionedDisputeGame.sol:51-73`).

## 2. v8 -> v9 review

The super-root commitment core did not change: `SuperFaultDisputeGame.sol`, `Encoding.sol` and `Hashing.sol` are byte-for-byte source-identical across the selected pins. The portal's type-selected `rootClaimByChainId` proof path is also unchanged.

Material changes:

- ASR 3.9.0 -> 4.0.0 replaces its stored SystemConfig dependency with an ETHLockbox dependency for pause, guardian and SuperchainConfig resolution while preserving the legacy slot as a spacer (`AnchorStateRegistry.sol:25-60,89-144`).
- Portal 5.8.0 -> 6.1.0 hardens lockbox/pause behavior and adds shared-dispute migration checks (`OptimismPortal2.sol:528-572`).
- The v9 migrator adds fresh shared infrastructure, re-migration protection, chain-ID order/uniqueness, game-config validation, old-liquidity/factory cleanup and atomic portal cutover (`OPContractsManagerMigrator.sol:129-285,287-410,475-555`).
- `GameTypes.clearedGameTypes` includes old and new proof types 0, 1, 8, 4, 5, 9 and 10 (`dispute/lib/Types.sol:97-110`).

Exact N-1/N/later state is in `mirror/lane-27/N1_N_STATE_DIFF.md`.

## 3. State machines and invariants

### Factory registration

The DGF chooses the implementation and args solely by game-type key, requires the exact bond, enforces one address per UUID, and initializes before recording (`DisputeGameFactory.sol:147-225`). Clone immutables bind creator, root, parent L1 head, type, complete extraData and configuration args.

### Game initialization

Type 9 requires exact calldata shape, rejects the conventional invalid claim, decodes extraData, checks `keccak256(canonical re-encoding) == rootClaim`, snapshots the current anchor, requires implementation chain ID zero, requires proposed timestamp above the anchor, deposits the bond, and snapshots respect (`SuperFaultDisputeGame.sol:251-341`). Its args expose prestate, VM, ASR, WETH and zero chain ID (`:792-875`).

Type 5 requires zero value, the same super-root hash binding, configured `tx.origin`, and a timestamp above the anchor. It immediately sets `resolvedAt=createdAt` and `DEFENDER_WINS`, then snapshots respect (`SuperPermissionedDisputeGame.sol:51-73`).

### ASR propriety and validity

The current ASR's decision ladder is:

1. `isGameRegistered`: reconstruct game type/root/extraData and demand address equality with its configured DGF UUID mapping (`AnchorStateRegistry.sol:215-237`). The former explicit embedded-ASR equality check is intentionally absent.
2. `isGameRespected`: read the game's creation-time snapshot, not current `respectedGameType` (`:239-247`).
3. `isGameRetired`: games with `createdAt <= retirementTimestamp` are retired (`:256-263`).
4. `isGameProper`: registered, unblacklisted, non-retired, and system not paused (`:273-308`). It explicitly does **not** mean the root is correct.
5. `isGameFinalized`: resolved and more than the 302400-second game-finality delay past `resolvedAt` (`:310-326`).
6. `isGameClaimValid`: proper, respect-snapshotted, finalized, and `DEFENDER_WINS` (`:328-353`).

Guardian-only actions change the respected type, advance the retirement cutoff, and blacklist a game (`:156-186`). Blacklisting and retirement therefore invalidate both finalization and anchoring through `isGameProper`.

Anyone may call `setAnchorState`, but the candidate must be claim-valid and have a strictly higher sequence (`:355-372`). There is one anchor across game types; legacy `anchors(type)` ignores type and returns the same root (`:188-213`). This makes the factory/ASR domain boundary important (PRIM-2704), but current args and the planned fresh-DGF migration close the cross-registry route.

### Old types

Implementation removal/current-type changes do not invalidate an existing game's respect snapshot. The concrete cutoff is precise:

- Index 9827: created 1753378031, before retirement 1753379243; `DEFENDER_WINS` but current-ASR-invalid.
- Index 9828: created 1753381655, type 0; implementation now zero; `DEFENDER_WINS`, respected, unblacklisted, claim-valid.

Index 9828's root exactly matches OP L2 block 138890875. Eight spaced samples through the last type-0 game (index 17904) and last type-8 game (index 20094) were also defender-valid and canonical. This establishes that old disabled games can still prove/finalize, but found no invalid root. It is not an exhaustive historical proof; the archive upstream rate-limited the broader scan. See REJ-2703.

## 4. Super-root withdrawal proof path

### Encoding and binding

The super preimage is:

```text
version 0x01 [1] || timestamp [8, big endian]
|| (chainId [32] || outputRoot [32])+
```

Solidity requires version 1, at least one entry, and a remaining length divisible by 64 (`libraries/Encoding.sol:282-345`). It does **not** require ascending or unique IDs. The game creator supplies this preimage as immutable extraData. Both game initializers decode/re-encode it and require its keccak to equal the root claim (`SuperFaultDisputeGame.sol:277-280`; `SuperPermissionedDisputeGame.sol:56-59`; hashing at `libraries/Hashing.sol:150-155`). Thus a caller cannot later substitute a different preimage.

The timestamp is within the root commitment and is the game's `l2SequenceNumber` (`SuperFaultDisputeGame.sol:648-651`). L1 initialization checks only that it advances the anchor. The portal does not independently compare that timestamp to a withdrawal block; semantic “output at this timestamp” correctness belongs to the fault-proof program.

### Per-chain extraction

At prove time, the portal fetches the game by factory index, requires current-ASR propriety and respect, and rejects only an already known challenger win (`OptimismPortal2.sol:411-435`). It then branches on the **game's type**:

- super type: `game.rootClaimByChainId(systemConfig.l2ChainId())`
- legacy type: `game.rootClaim()`

(`OptimismPortal2.sol:437-450`; type classification at `dispute/lib/Types.sol:112-117`). The caller cannot select the branch and the INTEROP flag is irrelevant. Therefore OP, although currently INTEROP=false, correctly extracts chain 10 from a type-9 super root. This kills the proposed legacy/super type confusion.

The caller supplies a normal four-field output-root preimage. Its hash must equal the extracted per-chain root, and the withdrawal storage proof must verify against its message-passer storage root (`OptimismPortal2.sol:447-478`). Proving may use an unresolved game; finalization after proof maturity calls current-ASR `isGameClaimValid` (`:671-704`).

### Duplicate/order analysis

Both super game implementations linearly scan entries and return the first matching ID (`SuperFaultDisputeGame.sol:806-819`; `SuperPermissionedDisputeGame.sol:80-89`). The fork test proved duplicates are accepted and first-match.

Off-chain comparison:

- Go `NewSuperV1` sorts IDs, but `UnmarshalSuperRoot` only validates version/shape (`op-service/eth/super_root.go:51-58,103-135`).
- Go withdrawal tooling also scans and returns first-match (`op-node/withdrawals/utils.go:248-288`).
- Kona `SuperRoot::new` sorts; raw `decode` accepts order/duplicates (`rust/kona/crates/protocol/interop/src/root.rs:22-85`). The transition from the existing prestate emits its next root through `SuperRoot::new` (`rust/kona/crates/proof/proof-interop/src/pre_state.rs:70-100`).

Consequently, a duplicate/unsorted proposed root is structurally registered but differs from the canonical trace unless the canonical chain universe itself contains that arrangement. The live OP anchor has one chain-10 entry. No last-match/sort-before-lookup discrepancy was found in the consumers examined.

Other malformed cases are contained: wrong version, empty entries or non-multiple length revert; root/preimage mismatch reverts; missing chain 10 makes only that voluntarily selected game unusable; a very long entry list is creator-funded and does not block selection of other games.

## 5. Planned OP Mainnet + Unichain migration

Current state satisfies the chain-side prerequisites:

- IDs 10 and 130 are nonzero, distinct and ascending.
- ProxyAdmins differ but both are owned by Safe `0x5a0A...3d2A`.
- Both use SuperchainConfig `0x9570...4a4C`, last OPCM `0x2d91...331f` version 9.0.3, and the same SystemConfig owner.
- Both are non-interop today and use separate portals, ASRs, DGFs, lockboxes and DelayedWETH contracts.

The full matrix is in `mirror/lane-27/MIGRATION_MODEL.md`.

`migrate` accepts only starting types 5/9, validates a nonzero bounded anchor, chain commonality/order/uniqueness, release floor and super-game configs (`OPContractsManagerMigrator.sol:129-166,287-410`). It derives proxy salts using execution `block.timestamp`, always deploys fresh lockbox/DGF/ASR, initializes them together, processes both chains, then registers shared super games (`:168-285`). Game args for super types force chain ID zero because IDs live in the super root (`OPContractsManagerUtils.sol:445-490`).

Per chain, `_migratePortal` checks pause state, authorizes the new lockbox, enables required features, attaches and sweeps liquidity, clears all old factory implementations, switches the portal to the fresh ASR, and reinitializes the old ASR against the new lockbox (`OPContractsManagerMigrator.sol:475-555`). Portal migration itself requires INTEROP, unpaused state, ProxyAdmin-owner caller, distinct/nonzero ASR, and portal authorization (`OptimismPortal2.sol:528-572`).

The entry point must execute by delegatecall (`OPContractsManagerV2.sol:293-313,1073-1077`). A malicious delegatecaller is not a target ProxyAdmin owner, so downstream privileged calls revert and roll back even its fresh deployments. The governance/Safe execution context is also the CREATE2 deployer, preventing an attacker from occupying the same address; prefunding is harmless. The future DGF cannot be pre-registered because it is deployed, initialized and configured within the atomic transaction.

Stored pre-migration withdrawal proofs deliberately fail after cutover: finalization asks the portal's current ASR about the recorded old game, and that game is absent from the fresh DGF domain. `OPContractsManagerV2.sol:278-287` documents reproving. This is suppressed by the engagement rules and not a finding.

No current game/proof/predicted-address action survives into the new shared proof domain. No chain-ID collision exists; the migrator explicitly rejects duplicates/order failures (`OPContractsManagerMigrator.sol:313-326`). Re-migration is rejected once INTEROP is enabled (`:305-311`).

## 6. Test evidence

Copied PoCs are under `mirror/lane-27/test/`; exact runs are in `mirror/lane-27/TEST_RESULTS.md`.

- `SuperRootPrimitivesTest`: 3/3 pass against deployed factory/implementations at block N. Covers permissionless type-9 creation with duplicate IDs/first-match, whole-preimage binding, and type-5 proposer auth.
- `HistoricalGamesTest`: 3/3 pass. Covers disabled-type persistence, exact retirement boundary root, and latest type-0/type-8 canonical roots.
- `GameInventoryTest`: 1/1 pass against block 26433900 and dumps all requested recent fields.

No test broadcasts. The only cheatcode storage write sets a fresh UUID mapping slot to its true expected zero to avoid lazy archive fetching; it does not alter a nonzero value or bypass contract logic.

## 7. Candidate ledger and residual work

No candidate score is reported because no hypothesis met the candidate threshold. The key kill facts are in REJ-2701 through REJ-2706.

Compositions worth independent follow-up:

1. Exhaustively compare every production consumer of super-root entries for first/last-match, ordering, chain-ID width and hash canonicalization. Lane 27 covered the portal, Go withdrawal helper and Kona root/transition code only.
2. Run an all-games historical semantic-root scan with a non-rate-limited archive source, concentrating on claim-valid defender games created after retirement and around type/prestate transitions. The nine concrete roots plus transition endpoints checked here were canonical.
3. Treat PRIM-2704 as a regression invariant: any future migration that reuses a DGF while changing its embedded ASR args must restore explicit domain binding or prove atomic retirement. The documented v9 migration correctly uses a fresh DGF/ASR pair.
