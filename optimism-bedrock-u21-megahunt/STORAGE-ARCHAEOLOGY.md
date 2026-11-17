# STORAGE ARCHAEOLOGY — Bedrock (and OVM residue) → Upgrade 21 (worker F4, Track A, blind)

Scope: every upgradeable L1 contract with live state on OP Mainnet, field by field at every `op-contracts` tag
v1.0.0 .. v9.0.0, **and** the real storage history of the OP Mainnet proxies read at the block before / after every
implementation change, with Ink / Soneium / Unichain as comparison chains. PASS A (`optimism-u21-novel-hunt/
U21_STORAGE_LAYOUT_DIFF.md`, lane 02) covered v7 → v8 → v9 and the exact N-1 → N delta; this file extends it backwards and
does not repeat it. No audit report, contest finding or disclosure was read (Track A).

Model: this run was completed on **Opus 5.5** (`claude-opus-5-5`), not Mythos 5.2, on the user's explicit instruction
("Continue avec opus 5.5", 2026-11-17 11:59 UTC) after the Mythos 5.2 quota was exhausted. Every number below that is
not a source-tree fact was re-read on chain or re-derived from the evidence files in this run unless stated.

Machine-readable companion: `evidence/F4-storage-lineage.json` (layouts per tag, per-slot lineage, implementation
histories of 48 proxies, slot timelines, per-upgrade events). Raw material: `evidence/F4/` (see §10). Fork tests:
`test/poc/F4/F4_LegacyStorage.t.sol` (3 tests, all PASS, `evidence/F4/forge_test_output.txt`).

## 0. Result in one page

**No candidate. No P0 primitive** (no slot written under meaning X, never cleared, and read by v9 under meaning Y).
What the archaeology establishes, with the facts that carry it:

| # | Fact | Evidence |
|---|---|---|
| 1 | OP Mainnet proxies went through 15 implementation generations (portal): v1.0.0 Bedrock 17423158 → "v1.2.0-era" 19314493 → MCP v1.3.0 19634866 → fault proofs v1.4.0 20062696 → (Holocene SystemConfig only 21695024) → U13 22182531 → U14 22339996 → U16 22990599 → U16a 23491328 → U17 23877377 → U18 24421512 → U19 25397811 → U20 26048619 → U21 26430859. v1.1.0, v1.5.0, v1.6.0 portal code never ran on OP Mainnet. | `evidence/F4/hist-*.json`, `slots-*.json` |
| 2 | **Every** layout hazard that exists in the source lineage (table §3.0) is defused on OP Mainnet by one of: the hazardous tag was never deployed there (v1.1.0), a *new proxy* was deployed instead of an in-place upgrade (AnchorStateRegistry at U13 and U16, DelayedWETH at every generation, ETHLockbox), or the upgrade tx zeroed / rewrote the slot inside the same transaction (L1CDM slot 0, L1StandardBridge slot 0, SuperchainConfig hashed slots, SystemConfig hashed slots). | §3, §4 |
| 3 | Legacy `provenWithdrawals` entries (portal v1, single-level mapping at slot 52, `{outputRoot, timestamp, l2OutputIndex}`) **still exist in live storage**: 12,338 distinct withdrawal hashes were first proven in the L2OutputOracle era, 3,281 of them were never finalized; 72 / 72 sampled entries are non-zero at block 26433900. No v9 code path reads them: `checkWithdrawal`, both `finalize*`, `deleteProvenWithdrawal`, the getters and `numProofSubmitters` never touch slot 52 or its entries (fork test with `vm.record`). `deleteProvenWithdrawal` reverts `OptimismPortal_Unproven` on them before reaching `status()`. | §6.1, `F4_LegacyStorage.t.sol` |
| 4 | Ink, Soneium and Unichain were **born with OptimismPortal2 3.10.0** (the same implementation `0xe2f826…` as OP Mainnet's fault-proof launch): they never ran portal v1, the L2OutputOracle or a slot-52 mapping. | §8 |
| 5 | The complete privileged history of the ProxyAdminOwner Safe `0x5a0Aae59…` is 49 executions (= Safe nonce). All 49 were traced: 14 are the OP Mainnet upgrades, and **two are not visible in an implementation-pointer history**: a StorageSetter cycle on SuperchainConfig at 20063224 (guardian rewrite) and an A → B → A cycle on the **OptimismPortal at 26309074 (2026-10-31)** that installed a one-off implementation `0x6d971b07…` for one call, `forceDeposit()`, which made the portal emit a `TransactionDeposited` event with an arbitrary un-aliased `from` (PRIM-F4-03). Net L1 storage delta of that tx on the portal: zero. | §7.3, `evidence/F4/op-proxyadminowner-safe-exec-classified.json`, `trace/26309074-*` |
| 6 | At U20 (26048619) the AnchorStateRegistry was re-initialised in place: `anchorGame` cleared, `startingAnchorRoot.l2SequenceNumber` changed **unit** in the same slot 4 (L2 block number 138,585,637 → timestamp 1,788,842,855), `respectedGameType` 8 → 9, `retirementTimestamp` **not** bumped. Pre-U20 output-root games stay claim-valid; the only cross-unit comparison (`setAnchorState`) is closed by census: the claim-valid output-root games with the highest sequence numbers are at L2 block 157,333,888 (OP) / 56,762,732 (Ink), and the only output-root games above 1,788,842,855 (4 on OP, 3 on Ink, all type 8) are CHALLENGER_WINS; no output-root type is registered on any of the four factories at 26433900. | §4.11, PRIM-F4-01 |
| 7 | At U19 (25397811) `SystemConfig.batchInbox` (hashed slot) on OP Mainnet was overwritten with `0x00c65A7b…9c98` (= `0x00 ‖ keccak256(chainId)[0:19]`, the deployer default) instead of the live inbox `0xFF00…0010`; it stayed wrong until U20 zeroed the slot and removed the getter. Unichain likewise (`0xff00…0130` → `0x00b2244e…8fc5`, 25475307 .. 26048619); Ink and Soneium unaffected (their real inbox already is the derived default). Past-only. | §4.2, PRIM-F4-02 |
| 8 | No proxy ever sat with a callable implementation and `_initialized == 0` across a transaction boundary. All StorageSetter resets and re-initialisations are atomic (one tx). The Bedrock L1CrossDomainMessenger was **never re-initialised** (the SystemDictator's `initialize()` reverted "already initialized" and was caught): its `_initialized = 1` at slot 0 **offset 20**, `xDomainMsgSender = 0xdead` and every `successfulMessages` entry date from the OVM deployment of 2021. | §7 |

## 1. Method and limits

* Layouts: `.storage-layout` (v1.0.0 from `hist/v1.0.0`, v1.1.0 from `git show op-contracts/v1.1.0:…/.storage-layout`,
  saved as `evidence/F4/v1.1.0.storage-layout`) and `snapshots/storageLayout/*.json` for v1.2.0 .. v9.0.0, parsed by
  `scripts/F4_build_lineage.py`; inheritance chains and state declarations re-read by hand at the tags where a slot
  changes (§3 notes). Contracts absent from the v1.0.0 / v1.1.0 snapshot (L1ERC721Bridge v1.0.0, ProtocolVersions
  v1.1.0, AddressManager, SuperchainConfig) were derived from source.
* Implementation history: `scripts/F4_impl_history.py` samples a signature (EIP-1967 implementation slot, slot 0,
  EIP-1967 admin slot, plus extra members such as the AddressManager entry of the L1CDM) every 20,000 blocks through the
  read-only archive proxy `:7545` and bisects every differing pair. Block granularity. **An A → B → A excursion inside one
  transaction is invisible to this method** — it is what hides the 26309074 portal cycle — so it was complemented by
  (a) a full `Upgraded` / `Initialized` event census for 15 OP Mainnet proxies over 17,300,000 .. 26,433,900
  (`op-all-proxies-upgraded-initialized.jsonl`, 236 logs, 0 failed chunks) and (b) a trace of **all 49** executions of
  the ProxyAdminOwner Safe (`prestateTracer` diff mode). L1StandardBridge (L1ChugSplashProxy, `setStorage` emits no
  event) and the L1CDM (ResolvedDelegateProxy) are covered by (b) from 2024-02-26 on; for 2023-06-06 .. 2024-02-26 (owner
  = old multisig `0x9BA6e03D…`) only the 20k-block grid and the `Initialized` census cover them.
* Slot history: `scripts/F4_slot_history.py` reads slots `[0, N)` + named/hashed slots at `block-1` and `block` of every
  signature change and at 26433900 (N = 72 portal, 112 SystemConfig, 260 L1CDM, 60 bridges, 110 DGF/DelayedWETH …).
  "Ever non-zero" therefore means *at a sampled block*; values set and cleared between two upgrades (the portal's
  Bedrock-era `paused` flag) were recovered from events instead (§4.1).
* Exact per-upgrade writes: `debug_traceTransaction` (`prestateTracer{diffMode}` + `callTracer`) of the 14 upgrade txs
  and the hidden cycle (`evidence/F4/trace/<block>-{diff,calls}.json`).
* Logs: `eth_getLogs` in ≤ 10k-block chunks was served for **all** ranges back to 2021 by the proxy upstreams (0 failed
  chunks in every scan). Full portal census of `WithdrawalProven` / `WithdrawalProvenExtension1` / `WithdrawalFinalized`
  from 17,420,000 to 26,433,900: 77,340 logs. The L1CDM `RelayedMessage` history was only **sampled** (11 windows of
  20,000 blocks, 2021 → 2026), not scanned in full.
* Other chains' L1 contracts live on Ethereum, so Ink / Soneium / Unichain were read through the same proxy.

## 2. OP Mainnet genealogy (block, date, implementation `version()`)

| Block (UTC date) | What | Portal | SystemConfig | L1CDM | L1StandardBridge | L1ERC721Bridge | ERC20Factory | Others |
|---|---|---|---|---|---|---|---|---|
| 12686756-89 (2021-06-22) | OVM 1 deployment | — | — | OVM `0x16393737…` | OVM `0x9091dda4…` | — | — | AddressManager `0xdE1FCfB0…` |
| 13596294 .. 13596915 (2021-11-11) | OVM 2 regenesis | — | — | `0xd9166833…` | `0x40e0c049…` | — | — | |
| 15677648 (2022-10-04) | L1ERC721Bridge proxy | — | — | | | 1.0.0 `0x3268ed09…` | — | |
| 17365800-04 (2023-05-29) | Bedrock proxies created (no implementation) | proxy | proxy | | | | proxy | ProxyAdmin `0x543bA4AA…`, L2OO proxy |
| 17422444 (2023-06-06) | SystemDictator step 1 | — | 1.3.0 | → `address(0)` | | | | ProxyAdmin/AddressManager owner → dictator |
| 17423158 (2023-06-06) | **Bedrock v1.0.0** | 1.6.0 | | 1.4.0 | 1.1.0 | (unchanged 1.0.0) | 1.1.0 | L2OO 1.3.0; 293,288.26 ETH moved L1SB → portal |
| 18367320 (2023-10-17) | ProtocolVersions 1.0.0 (v1.1.0, `_initialized = 3`) | | | | | | | |
| 19064589 (2024-01-22) | SuperchainConfig 1.1.0 | | | | | | | |
| 19193284 (2024-02-09) | ProxyAdmin owner → Safe `0x5a0Aae59…` | | | | | | | |
| 19314493 (2024-02-26) | "v1.2.0-era" (SuperchainConfig pause) | 2.4.0 | 1.11.0 | 2.2.0 | 2.0.0 | 2.0.0 | 1.8.0 | L2OO 1.7.0 |
| 19634866 (2024-04-11) | **MCP L1, v1.3.0** (immutables → storage) | 2.5.0 | 1.12.0 | 2.3.0 | 2.1.0 | 2.1.0 | 1.9.0 | L2OO 1.8.0 |
| 19884570 (2024-05-16) | DGF 1.0.0, ASR `0x18DAc71c…` 1.0.0, DelayedWETH g1 | | | | | | | |
| 20062696 (2024-06-10) | **Fault proofs, v1.4.0** | **OptimismPortal2 3.10.0** | 2.2.0 | | | | | |
| 20063224 (2024-06-10) | SuperchainConfig guardian rewrite (StorageSetter cycle) | | | | | | | hidden from impl history |
| 20723924 (2024-09-11) | ASR-old → 2.0.0, new game impls, `respectedGameTypeUpdatedAt` bump | | | | | | | portal impl untouched |
| 21695024 (2025-01-24) | Holocene (v1.8.0) | | 2.3.0 | | | | | |
| 22182531 (2025-04-02) | **U13, v2.0.0** | 3.13.0 | 2.4.0 | 2.5.0 | 2.2.2 | 2.3.1 | 1.10.1 | new ASR `0x1c68ECfb…` 2.2.2, DGF 1.0.1 |
| 22339996 (2025-04-24) | **U14, v3.0.0** | 3.14.0 | 2.5.0 | 2.6.0 | 2.3.0 | 2.4.0 | | |
| 22990599 (2025-07-24) | **U16, v4.0.0** | 4.6.0 | 3.4.0 | 2.9.0 | 2.6.0 | 2.7.0 | | new ASR `0x23B2C629…` 3.5.0, ETHLockbox 1.2.0 (236,752.24 ETH portal → lockbox), new DelayedWETHs |
| 23491328 (2025-10-02) | **U16a, v4.1.0** | 5.0.0 | 3.7.0 | 2.10.0 | 2.7.0 | 2.8.0 | | |
| 23877377 (2025-11-25) | **U17, v5.0.0** | 5.1.1 | 3.11.0 | 2.11.0 | 2.8.0 | 2.9.0 | 1.10.2 | DGF 1.3.0 |
| 24421512 (2026-02-09) | **U18, v6.0.0** | 5.2.0 | 3.13.1 | | | | | ASR 3.7.0, DGF 1.4.0 (gameArgs) |
| 25397811 (2026-06-25) | **U19, v7.0.0** | 5.6.1 | 3.14.2 | 2.11.1 | 2.8.2 | 2.9.1 | 1.11.0 | new DelayedWETH `0x1B6DBF05…` 1.5.1, ASR 3.9.0, DGF 1.6.1 |
| 26048619 (2026-09-24) | **U20, v8.0.0** | 5.8.0 | 4.0.0 | | | | | ASR re-initialised (super roots, type 9) |
| 26309074 (2026-10-31) | hidden portal cycle `forceDeposit()` | 5.8.0 → `0x6d971b07…` → 5.8.0 | | | | | | PRIM-F4-03 |
| 26430859 (2026-11-16) | **U21, v9.0.0** | 6.1.0 | 4.3.0 | 2.13.0 | (2.8.2) | (2.9.1) | (1.11.0) | ASR 4.0.0, lockbox 2.0.0, DelayedWETH 2.0.0 |

The release ↔ upgrade-number mapping above is my reading of versions and dates; F2 owns the authoritative numbering.

## 3. Source lineage, every tag v1.0.0 .. v9.0.0

### 3.0 Every layout event in the source lineage and its fate on chain

| # | Contract.slot | Event (tags) | Class | Fate on OP Mainnet | Ink / Soneium / Unichain |
|---|---|---|---|---|---|
| a | Portal 53[0] | `paused` (v1.0.0-v1.1.0) → `spacer_53_0_1` (v1.2.0+) | deletion-to-spacer | set once 19233786, cleared 19234082 (Bedrock-era pause drill); 0 since | never existed |
| b | Portal 53[1:21] | — → `l2Oracle` (v1.1.0) → `superchainConfig` (v1.2.0) → `spacer_53_1_20` (v4.0.0) | retype in place v1.1.0→v1.2.0 | v1.1.0 never deployed; `superchainConfig` written 19314493, never cleared, dead | written at genesis, dead |
| c | Portal 54 | — → `systemConfig` (v1.1.0) → — (v1.2.0) → `l2Oracle` (v1.3.0) → `spacer_54_0_20` (v1.4.0 Portal2) | retype v1.1.0→v1.3.0; immutable→storage (MCP) | written 19634866 = L2OO `0xdfe97868…`, never cleared, dead | 0 |
| d | Portal 55 | — → `guardian` (v1.1.0) → — → `systemConfig` (v1.3.0+) | **retype of a live field** v1.1.0→v1.3.0; immutable→storage | v1.1.0 never deployed; written 19634866, live | written at genesis |
| e | Portal 52 | `provenWithdrawals` mapping (v1) → `spacer_52_0_32` (Portal2) | mapping abandoned in place | base 0; **12,338 entries live** (§6.1) | none |
| f | Portal 56-60 | `spacer_56..60` in portal **v1** (v1.5.0-v1.8.0) vs `disputeGameFactory`, `provenWithdrawals`, `disputeGameBlacklist`, `respectedGameType(+UpdatedAt)`, `proofSubmitters` in Portal2 (v1.4.0+) | forward reservation | portal v1 ≥ v1.5.0 never deployed | — |
| g | Portal 61 | `spacer_61` (v1.4.0) → `_balance` (v1.6.0-v1.8.0, custom gas token) → `spacer_61_0_32` (v2.0.0) | add / delete | never written (0) | 0 |
| h | Portal 56, 58, 59 | `disputeGameFactory`, `disputeGameBlacklist`, `respectedGameType`, `respectedGameTypeUpdatedAt` → spacers (v4.0.0, moved to the ASR) | state moved to another contract | 56 = DGF, 59 = `0x66e1c083 00000000` never cleared; 58: **no entry ever written** (no `DisputeGameBlacklisted` event) | 56 / 59 stale (Soneium type 1) |
| i | Portal 62, 63 | `anchorStateRegistry`, `ethLockbox`, `superRootsActive` (v4.0.0) → `spacer_63_20_1` (v4.1.0) | append; delete | written 22990599; `superRootsActive` never set | same |
| j | SystemConfig 106 | `startBlock` (v1.1.0 only) → — (v1.2.0, moved to hashed slot) → `eip1559Denominator`/`Elasticity` (v1.8.0) → + `operatorFeeScalar`/`Constant` (v3.0.0) → + `daFootprintGasScalar` (v5.0.0) | **retype** v1.1.0→v1.8.0; packed neighbours | v1.1.0 never deployed: slot 0 until the owner set 250 / 2 after Holocene | 0 at birth (born on 2.2.0) |
| k | SystemConfig 104 | `gasLimit` + `basefeeScalar`, `blobbasefeeScalar` (v1.6.0) | packed neighbours added | upper bytes 0 until 21695024, written by `initialize` from `scalar` | consistent with slot 102 on all four (read at 26433900) |
| l | SystemConfig 107-109, 108[20:28] | `l2ChainId`, `superchainConfig` (v4.0.0), `isFeatureEnabled` (v4.1.0), `minBaseFee` (v5.0.0) | append; packed neighbour | written 22990599 / 23491328 | same |
| m | SystemConfig hashed | `l2outputoracle` (v1.3.0-v1.x), `disputegamefactory` (v1.4.0-v3), `batchinbox` (v1.3.0-v7), `startBlock`, gas-paying-token (v1.5.0-v1.8.0) | hashed slots added / retired | `l2outputoracle` set 19634866, zeroed 20062696; `disputegamefactory` set 20062696, zeroed 22990599; `batchinbox` see fact 7; gas token never written | all 0 |
| n | L1CDM 0[0:20] | OVM `libAddressManager` = `spacer_0_0_20` | legacy spacer sharing the `_initialized` slot | held `0xdE1FCfB0…` 2021 → 19314493, then zeroed by StorageSetter | 0 from birth |
| o | L1CDM 207 | `__gap[42]` (v1.0.0) → `__gap[44]` (v1.2.0) → `otherMessenger` + `__gap[43]` (v1.3.0) | gap consumption; immutable→storage | 0 before, written 19634866 | genesis |
| p | L1CDM 249 | `PORTAL` (v1.1.0 only) → inside `__gap` | add / delete | never written | 0 |
| q | L1CDM 251-254 | `superchainConfig` (v1.2.0) → `spacer_251` (v4.0.0); `portal` 252 (v1.3.0); `systemConfig` 253 (v1.5.0-v1.8.0) → `spacer_253` (v2.0.0); `systemConfig` 254 (v4.0.0) | append / spacer / re-add at a new slot | 251 written 19314493 dead; 252 live; 253 never written; 254 written 22990599 | 253 = 0 |
| r | L1StandardBridge 0 | OVM `messenger` = `spacer_0_0_20` (v1.0.0) → `_initialized`,`_initializing`,`spacer_0_2_20` (v1.1.0) → `spacer_0_2_30` (v1.3.0) | **retype of slot 0 into the initializer slot** | held `0x25ace71c…` (low byte `0xa1`, i.e. `_initialized` would read 161 and `_initializing` true) until 19314493; the StorageSetter zeroed the whole slot in the same tx before `initialize` | 1 from birth |
| s | L1StandardBridge 3, 4 | `__gap` → `messenger` (v1.1.0) → `__gap` (v1.2.0) → `messenger`, `otherBridge` (v1.3.0) | gap consumption; immutable→storage | 0 before, written 19634866 | genesis |
| t | L1StandardBridge 50-52 | `superchainConfig` (v1.2.0) → spacer (v4.0.0); `systemConfig` 51 (v1.5.0-v1.8.0) → spacer (v2.0.0); `systemConfig` 52 (v4.0.0) | as q | 50 dead since 19314493, 51 never written, 52 written 22990599 | same |
| u | L1ERC721Bridge 0[2:22] | `messenger` (v1.1.0) → — (v1.2.0) → `spacer_0_2_30` (v1.3.0) | add / delete beside `_initialized` | v1.1.0 never deployed; always 0 | 0 |
| v | L1ERC721Bridge 1, 2, 50, 51 | `messenger`, `otherBridge` (v1.3.0, gap consumption); `superchainConfig` 50 → spacer (v4.0.0); `systemConfig` 51 (v4.0.0) | as s, t | 1, 2 written 19634866; 50 written 19314493, dead; 51 written 22990599 | same |
| w | ERC20Factory 0[2:22], 1, 2 | `bridge` at 0[2:22] (v1.1.0) → — (v1.2.0) → `bridge` at 1 (v1.3.0); `deployments` at 2 (v1.8.0, gap consumption) | add / delete; relocation | v1.1.0 never deployed; `bridge` written 19634866 | genesis |
| x | L2OutputOracle 4, 5 | `challenger`, `proposer` (v1.1.0) → — (v1.2.0) → `submissionInterval`, `l2BlockTime` + 6, 7, 8 (v1.3.0) | **retype** v1.1.0→v1.3.0 | v1.1.0 never deployed; 4-8 written 19634866; proxy still alive at 1.8.0 with 8,879 outputs, unread by v9 | no L2OO |
| y | DGF 102-104 | `_disputeGames` 102, `_disputeGameList` 103 (v1.1.0) → `initBonds` 102, `_disputeGames` 103, `_disputeGameList` 104 (v1.2.0); `gameArgs` 105 (v5.0.0) | **mid-layout insertion** v1.1.0→v1.2.0; append | proxy created 2024-05-16 under 1.0.0 (v1.4.0 layout): never held the v1.1.0 layout | born ≥ v1.4.0 layout |
| z | ASR 1-6 | `anchors` mapping at 1 (v1.4.0-v1.8.0) → `disputeGameFactory` 1, `portal` 2, `anchorGame` 3, `startingAnchorRoot` 4-5 (v2.0.0) → `anchorGame` 2, `startingAnchorRoot` 3-4, `disputeGameBlacklist` 5, `respectedGameType`/`retirementTimestamp` 6 (v4.0.0) → + `ethLockbox` 6[12:32] (v9.0.0) | **two incompatible re-layouts** | **three separate proxies**: `0x18DAc71c…` (v1.4-v1.8 layout, frozen at 2.0.0), `0x1c68ECfb…` (v2 layout, frozen at 2.2.2), `0x23B2C629…` (v4+ layout). No proxy crossed a re-layout. | same pattern (U16 ASR proxies created 22990599 / 22990670 / 22990722) |
| aa | ASR 0[2:22] | — → `superchainConfig` (v2.0.0) → `systemConfig` (v4.0.0) → `spacer_0_2_20` (v9.0.0) | retype beside `_initialized` | per-proxy: only the v4+ proxy, holds SystemConfig, dead in v9 (PASS A) | same |
| ab | DelayedWETH | OwnableUpgradeable layout: `_owner` 51, `balanceOf` 101, `allowance` 102, `withdrawals` 103, `config` 104 (v1.4.0-v3.0.1) → `_balanceOf` 1, `_allowance` 2, `withdrawals` 3, `systemConfig` 4 (v4.0.0) → `spacer_4`, `ethLockbox` 5 (v9.0.0) | **inheritance reorder** (OwnableUpgradeable dropped, v4.0.0) | **ten proxies, none crossed the reorder**: g1 `0xE497B094…` (1.0.0), g2 `0x82511d49…`/`0x9F9b897e…` (1.1.0), g3 `0x323dFC63…`/`0x21429aF6…` (1.1.0 → 1.3.0 at U13) keep the old layout forever; g4 `0xe214879a…`/`0xc5f54F93…` and g5 `0xD061AB95…`/`0xe03F4d1D…` (1.5.0) and the live `0x1B6DBF05…` were born on the new one | live DelayedWETH proxies created at U19 |
| ac | SuperchainConfig | hashed `superchainConfig.guardian` / `.paused` (v1.2.0-v3.0.1) → `guardian` at 0[2:22], `pauseTimestamps` at 1 (v4.0.0) | hashed slot → packed neighbour of `_initialized` | `upgrade()` at 22990599 copied the guardian and zeroed the hashed slot in the same tx; hashed `paused` was 1 only between 22482108 and 22482160 | shared contract |
| ad | ETHLockbox 0[2:22], 3 | `systemConfig` → `spacer_0_2_20`; `superchainConfig` at 3 (v9.0.0) | PASS A | PASS A | PASS A |
| ae | ProxyAdmin 2 | `implementationName` not in the v1.0.0 / v1.1.0 snapshot, present from v1.2.0 | snapshot artefact (the variable exists in v1.0.0 source: slots 1, 2, 3 are `proxyType`, `implementationName`, `addressManager`) | `addressManager` written 17422444 | — |
| af | `_initialized` | plain `initializer` (v1.0.0) → `reinitializer(Constants.INITIALIZER = 3)` (v1.1.0) → `initializer` + StorageSetter reset (v1.2.0-v3.0.1) → `ReinitializableBase(2)` (v4.0.0) → `(3)` (v4.1.0 .. v9.0.0) | initializer-version change | 1 → 2 (22990599) → 3 (23491328); ProtocolVersions is the only proxy that carries the v1.1.0 value 3 | 1 → 2 → 3 at their own U16 / U16a blocks |

`_initialized` is **not** at slot 0 offset 0 in exactly one contract: L1CrossDomainMessenger, slot 0 **offset 20**
(`CrossDomainMessengerLegacySpacer0.spacer_0_0_20` occupies bytes 0-19), at every tag. Contracts whose slot 0 also packs a
live or dead neighbour above the two initializer bytes: SuperchainConfig (`guardian`, v4+), ETHLockbox and ASR
(`spacer_0_2_20`), L1StandardBridge / L1ERC721Bridge / ERC20Factory (`spacer_0_2_30`).

Hand cross-checks of the snapshot tool (file:line at the tag):

* v1.0.0 portal: `contract OptimismPortal is Initializable, ResourceMetering, Semver` with `L2_ORACLE`, `SYSTEM_CONFIG`,
  `GUARDIAN` immutable and `l2Sender`, `finalizedWithdrawals`, `provenWithdrawals`, `bool paused`
  (`contracts/L1/OptimismPortal.sol:23` ff.); `initialize(bool _paused) public initializer` (:165).
* v1.1.0: the three immutables become storage `l2Oracle`, `systemConfig`, `guardian` right after `paused`
  (`src/L1/OptimismPortal.sol:22` ff.), `reinitializer(Constants.INITIALIZER)` (:127), `INITIALIZER = 3`
  (`src/libraries/Constants.sol:49`); eight contracts use it. v1.2.0 goes back to immutables + `superchainConfig`
  (`initialize(SuperchainConfig) public initializer`, :110); v1.3.0 is storage again in a **different order**
  (`superchainConfig`, `l2Oracle`, `systemConfig`). The v1.1.0 ↔ v1.3.0 orders are mutually incompatible (rows b-d, j, x).
* v1.0.0 L1ERC721Bridge: `ERC721Bridge` has two immutables and `uint256[49] __gap`, `deposits` at slot 49
  (`contracts/universal/ERC721Bridge.sol:11-25`, `contracts/L1/L1ERC721Bridge.sol:20`): same slot as today.
* v1.0.0 messenger spacers: `spacer_201_0_32` = OVM `blockedMessages`, `spacer_202_0_32` = OVM `relayedMessages`,
  `successfulMessages` at 203 (`contracts/universal/CrossDomainMessenger.sol`, legacy spacer contracts).
* ASR: v1.4.0 `mapping(GameType => OutputRoot) anchors` + immutable `DISPUTE_GAME_FACTORY`; v2.0.0
  `superchainConfig, disputeGameFactory, portal, anchorGame, startingAnchorRoot`; v4.0.0
  `systemConfig, disputeGameFactory, anchorGame, startingAnchorRoot, disputeGameBlacklist, respectedGameType,
  retirementTimestamp` (`src/dispute/AnchorStateRegistry.sol` at each tag).
* SuperchainConfig v4.0.0 `upgrade()` reads the hashed guardian slot, calls `_setGuardian`, zeroes both hashed slots
  (`src/L1/SuperchainConfig.sol:81-99`).

### 3.1 Per-contract lineage tables (generated from the per-tag layouts)

A cell is `tag range: label type [bytes]`; `—` = no field at that position at that tag; **CHANGED** marks every position
whose label, type or existence changed at least once.

### OptimismPortal

Tags with this contract: v1.0.0 .. v1.8.0 (8 tags).

| slot | off | lineage (tag range: `label` type [bytes]) |
|---|---|---|
| 0 | 0 | v1.0.0..v1.8.0: `_initialized` uint8 [1] |
| 0 | 1 | v1.0.0..v1.8.0: `_initializing` bool [1] |
| 1 | 0 | v1.0.0..v1.8.0: `params` struct ResourceMetering.ResourceParams [32] |
| 2 | 0 | v1.0.0..v1.8.0: `__gap` uint256[48] [1536] |
| 50 | 0 | v1.0.0..v1.8.0: `l2Sender` address [20] |
| 51 | 0 | v1.0.0..v1.8.0: `finalizedWithdrawals` mapping(bytes32 => bool) [32] |
| 52 | 0 | v1.0.0..v1.8.0: `provenWithdrawals` mapping(bytes32 => struct OptimismPortal.ProvenWithdrawal) [32] |
| 53 | 0 | v1.0.0..v1.1.0: `paused` bool [1] → v1.2.0..v1.8.0: `spacer_53_0_1` bool [1] **CHANGED** |
| 53 | 1 | v1.0.0: — → v1.1.0: `l2Oracle` contract L2OutputOracle [20] → v1.2.0..v1.6.0: `superchainConfig` contract SuperchainConfig [20] → v1.8.0: `superchainConfig` contract ISuperchainConfig [20] **CHANGED** |
| 54 | 0 | v1.0.0: — → v1.1.0: `systemConfig` contract SystemConfig [20] → v1.2.0: — → v1.3.0..v1.6.0: `l2Oracle` contract L2OutputOracle [20] → v1.8.0: `l2Oracle` contract IL2OutputOracle [20] **CHANGED** |
| 55 | 0 | v1.0.0: — → v1.1.0: `guardian` address [20] → v1.2.0: — → v1.3.0..v1.6.0: `systemConfig` contract SystemConfig [20] → v1.8.0: `systemConfig` contract ISystemConfig [20] **CHANGED** |
| 56 | 0 | v1.0.0..v1.4.0: — → v1.5.0..v1.8.0: `spacer_56_0_20` address [20] **CHANGED** |
| 57 | 0 | v1.0.0..v1.4.0: — → v1.5.0..v1.8.0: `spacer_57_0_32` bytes32 [32] **CHANGED** |
| 58 | 0 | v1.0.0..v1.4.0: — → v1.5.0..v1.8.0: `spacer_58_0_32` bytes32 [32] **CHANGED** |
| 59 | 0 | v1.0.0..v1.4.0: — → v1.5.0..v1.8.0: `spacer_59_0_32` bytes32 [32] **CHANGED** |
| 60 | 0 | v1.0.0..v1.4.0: — → v1.5.0..v1.8.0: `spacer_60_0_32` bytes32 [32] **CHANGED** |
| 61 | 0 | v1.0.0..v1.4.0: — → v1.5.0..v1.8.0: `_balance` uint256 [32] **CHANGED** |

### OptimismPortal2

Tags with this contract: v1.4.0 .. v9.0.0 (16 tags).

| slot | off | lineage (tag range: `label` type [bytes]) |
|---|---|---|
| 0 | 0 | v1.4.0..v9.0.0: `_initialized` uint8 [1] |
| 0 | 1 | v1.4.0..v9.0.0: `_initializing` bool [1] |
| 1 | 0 | v1.4.0..v9.0.0: `params` struct ResourceMetering.ResourceParams [32] |
| 2 | 0 | v1.4.0..v9.0.0: `__gap` uint256[48] [1536] |
| 50 | 0 | v1.4.0..v9.0.0: `l2Sender` address [20] |
| 51 | 0 | v1.4.0..v9.0.0: `finalizedWithdrawals` mapping(bytes32 => bool) [32] |
| 52 | 0 | v1.4.0..v9.0.0: `spacer_52_0_32` bytes32 [32] |
| 53 | 0 | v1.4.0..v9.0.0: `spacer_53_0_1` bool [1] |
| 53 | 1 | v1.4.0..v1.6.0: `superchainConfig` contract SuperchainConfig [20] → v1.8.0..v3.0.1: `superchainConfig` contract ISuperchainConfig [20] → v4.0.0..v9.0.0: `spacer_53_1_20` address [20] **CHANGED** |
| 54 | 0 | v1.4.0..v9.0.0: `spacer_54_0_20` address [20] |
| 55 | 0 | v1.4.0..v1.6.0: `systemConfig` contract SystemConfig [20] → v1.8.0..v9.0.0: `systemConfig` contract ISystemConfig [20] **CHANGED** |
| 56 | 0 | v1.4.0..v1.6.0: `disputeGameFactory` contract DisputeGameFactory [20] → v1.8.0..v3.0.1: `disputeGameFactory` contract IDisputeGameFactory [20] → v4.0.0..v9.0.0: `spacer_56_0_20` address [20] **CHANGED** |
| 57 | 0 | v1.4.0..v9.0.0: `provenWithdrawals` mapping(bytes32 => mapping(address => struct OptimismPortal2.ProvenWithdrawal)) [32] |
| 58 | 0 | v1.4.0..v3.0.1: `disputeGameBlacklist` mapping(contract IDisputeGame => bool) [32] → v4.0.0..v9.0.0: `spacer_58_0_32` bytes32 [32] **CHANGED** |
| 59 | 0 | v1.4.0..v3.0.1: `respectedGameType` GameType [4] → v4.0.0..v9.0.0: `spacer_59_0_4` GameType [4] **CHANGED** |
| 59 | 4 | v1.4.0..v3.0.1: `respectedGameTypeUpdatedAt` uint64 [8] → v4.0.0..v9.0.0: `spacer_59_4_8` uint64 [8] **CHANGED** |
| 60 | 0 | v1.4.0..v9.0.0: `proofSubmitters` mapping(bytes32 => address[]) [32] |
| 61 | 0 | v1.4.0..v1.5.0: `spacer_61_0_32` bytes32 [32] → v1.6.0..v1.8.0: `_balance` uint256 [32] → v2.0.0..v9.0.0: `spacer_61_0_32` uint256 [32] **CHANGED** |
| 62 | 0 | v1.4.0..v3.0.1: — → v4.0.0..v9.0.0: `anchorStateRegistry` contract IAnchorStateRegistry [20] **CHANGED** |
| 63 | 0 | v1.4.0..v3.0.1: — → v4.0.0..v9.0.0: `ethLockbox` contract IETHLockbox [20] **CHANGED** |
| 63 | 20 | v1.4.0..v3.0.1: — → v4.0.0: `superRootsActive` bool [1] → v4.1.0..v9.0.0: `spacer_63_20_1` bool [1] **CHANGED** |

### L2OutputOracle

Tags with this contract: v1.0.0 .. v1.8.0 (8 tags).

| slot | off | lineage (tag range: `label` type [bytes]) |
|---|---|---|
| 0 | 0 | v1.0.0..v1.8.0: `_initialized` uint8 [1] |
| 0 | 1 | v1.0.0..v1.8.0: `_initializing` bool [1] |
| 1 | 0 | v1.0.0..v1.8.0: `startingBlockNumber` uint256 [32] |
| 2 | 0 | v1.0.0..v1.8.0: `startingTimestamp` uint256 [32] |
| 3 | 0 | v1.0.0..v1.8.0: `l2Outputs` struct Types.OutputProposal[] [32] |
| 4 | 0 | v1.0.0: — → v1.1.0: `challenger` address [20] → v1.2.0: — → v1.3.0..v1.8.0: `submissionInterval` uint256 [32] **CHANGED** |
| 5 | 0 | v1.0.0: — → v1.1.0: `proposer` address [20] → v1.2.0: — → v1.3.0..v1.8.0: `l2BlockTime` uint256 [32] **CHANGED** |
| 6 | 0 | v1.0.0..v1.2.0: — → v1.3.0..v1.8.0: `challenger` address [20] **CHANGED** |
| 7 | 0 | v1.0.0..v1.2.0: — → v1.3.0..v1.8.0: `proposer` address [20] **CHANGED** |
| 8 | 0 | v1.0.0..v1.2.0: — → v1.3.0..v1.8.0: `finalizationPeriodSeconds` uint256 [32] **CHANGED** |

### SystemConfig

Tags with this contract: v1.0.0 .. v9.0.0 (20 tags).

| slot | off | lineage (tag range: `label` type [bytes]) |
|---|---|---|
| 0 | 0 | v1.0.0..v9.0.0: `_initialized` uint8 [1] |
| 0 | 1 | v1.0.0..v9.0.0: `_initializing` bool [1] |
| 1 | 0 | v1.0.0..v9.0.0: `__gap` uint256[50] [1600] |
| 51 | 0 | v1.0.0..v9.0.0: `_owner` address [20] |
| 52 | 0 | v1.0.0..v9.0.0: `__gap` uint256[49] [1568] |
| 101 | 0 | v1.0.0..v9.0.0: `overhead` uint256 [32] |
| 102 | 0 | v1.0.0..v9.0.0: `scalar` uint256 [32] |
| 103 | 0 | v1.0.0..v9.0.0: `batcherHash` bytes32 [32] |
| 104 | 0 | v1.0.0..v9.0.0: `gasLimit` uint64 [8] |
| 104 | 8 | v1.0.0..v1.5.0: — → v1.6.0..v9.0.0: `basefeeScalar` uint32 [4] **CHANGED** |
| 104 | 12 | v1.0.0..v1.5.0: — → v1.6.0..v9.0.0: `blobbasefeeScalar` uint32 [4] **CHANGED** |
| 105 | 0 | v1.0.0..v1.6.0: `_resourceConfig` struct ResourceMetering.ResourceConfig [32] → v1.8.0..v9.0.0: `_resourceConfig` struct IResourceMetering.ResourceConfig [32] **CHANGED** |
| 106 | 0 | v1.0.0: — → v1.1.0: `startBlock` uint256 [32] → v1.2.0..v1.6.0: — → v1.8.0..v9.0.0: `eip1559Denominator` uint32 [4] **CHANGED** |
| 106 | 4 | v1.0.0..v1.6.0: — → v1.8.0..v9.0.0: `eip1559Elasticity` uint32 [4] **CHANGED** |
| 106 | 8 | v1.0.0..v2.2.0: — → v3.0.0..v9.0.0: `operatorFeeScalar` uint32 [4] **CHANGED** |
| 106 | 12 | v1.0.0..v2.2.0: — → v3.0.0..v9.0.0: `operatorFeeConstant` uint64 [8] **CHANGED** |
| 106 | 20 | v1.0.0..v4.1.0: — → v5.0.0..v9.0.0: `daFootprintGasScalar` uint16 [2] **CHANGED** |
| 107 | 0 | v1.0.0..v3.0.1: — → v4.0.0..v9.0.0: `l2ChainId` uint256 [32] **CHANGED** |
| 108 | 0 | v1.0.0..v3.0.1: — → v4.0.0..v9.0.0: `superchainConfig` contract ISuperchainConfig [20] **CHANGED** |
| 108 | 20 | v1.0.0..v4.1.0: — → v5.0.0..v9.0.0: `minBaseFee` uint64 [8] **CHANGED** |
| 109 | 0 | v1.0.0..v4.0.0: — → v4.1.0..v9.0.0: `isFeatureEnabled` mapping(bytes32 => bool) [32] **CHANGED** |

### L1CrossDomainMessenger

Tags with this contract: v1.0.0 .. v9.0.0 (20 tags).

| slot | off | lineage (tag range: `label` type [bytes]) |
|---|---|---|
| 0 | 0 | v1.0.0..v9.0.0: `spacer_0_0_20` address [20] |
| 0 | 20 | v1.0.0..v9.0.0: `_initialized` uint8 [1] |
| 0 | 21 | v1.0.0..v9.0.0: `_initializing` bool [1] |
| 1 | 0 | v1.0.0..v9.0.0: `spacer_1_0_1600` uint256[50] [1600] |
| 51 | 0 | v1.0.0..v9.0.0: `spacer_51_0_20` address [20] |
| 52 | 0 | v1.0.0..v9.0.0: `spacer_52_0_1568` uint256[49] [1568] |
| 101 | 0 | v1.0.0..v9.0.0: `spacer_101_0_1` bool [1] |
| 102 | 0 | v1.0.0..v9.0.0: `spacer_102_0_1568` uint256[49] [1568] |
| 151 | 0 | v1.0.0..v9.0.0: `spacer_151_0_32` uint256 [32] |
| 152 | 0 | v1.0.0..v9.0.0: `spacer_152_0_1568` uint256[49] [1568] |
| 201 | 0 | v1.0.0..v9.0.0: `spacer_201_0_32` mapping(bytes32 => bool) [32] |
| 202 | 0 | v1.0.0..v9.0.0: `spacer_202_0_32` mapping(bytes32 => bool) [32] |
| 203 | 0 | v1.0.0..v9.0.0: `successfulMessages` mapping(bytes32 => bool) [32] |
| 204 | 0 | v1.0.0..v9.0.0: `xDomainMsgSender` address [20] |
| 205 | 0 | v1.0.0..v9.0.0: `msgNonce` uint240 [30] |
| 206 | 0 | v1.0.0..v9.0.0: `failedMessages` mapping(bytes32 => bool) [32] |
| 207 | 0 | v1.0.0..v1.1.0: `__gap` uint256[42] [1344] → v1.2.0: `__gap` uint256[44] [1408] → v1.3.0..v9.0.0: `otherMessenger` contract CrossDomainMessenger [20] **CHANGED** |
| 208 | 0 | v1.0.0..v1.2.0: — → v1.3.0..v9.0.0: `__gap` uint256[43] [1376] **CHANGED** |
| 249 | 0 | v1.0.0: — → v1.1.0: `PORTAL` contract OptimismPortal [20] → v1.2.0..v9.0.0: — **CHANGED** |
| 251 | 0 | v1.0.0..v1.1.0: — → v1.2.0..v1.6.0: `superchainConfig` contract SuperchainConfig [20] → v1.8.0..v3.0.1: `superchainConfig` contract ISuperchainConfig [20] → v4.0.0..v9.0.0: `spacer_251_0_20` address [20] **CHANGED** |
| 252 | 0 | v1.0.0..v1.2.0: — → v1.3.0..v1.6.0: `portal` contract OptimismPortal [20] → v1.8.0: `portal` contract IOptimismPortal [20] → v2.0.0..v9.0.0: `portal` contract IOptimismPortal2 [20] **CHANGED** |
| 253 | 0 | v1.0.0..v1.4.0: — → v1.5.0..v1.6.0: `systemConfig` contract SystemConfig [20] → v1.8.0: `systemConfig` contract ISystemConfig [20] → v2.0.0..v9.0.0: `spacer_253_0_20` address [20] **CHANGED** |
| 254 | 0 | v1.0.0..v3.0.1: — → v4.0.0..v9.0.0: `systemConfig` contract ISystemConfig [20] **CHANGED** |

### L1StandardBridge

Tags with this contract: v1.0.0 .. v9.0.0 (20 tags).

| slot | off | lineage (tag range: `label` type [bytes]) |
|---|---|---|
| 0 | 0 | v1.0.0: `spacer_0_0_20` address [20] → v1.1.0..v9.0.0: `_initialized` uint8 [1] **CHANGED** |
| 0 | 1 | v1.0.0: — → v1.1.0..v9.0.0: `_initializing` bool [1] **CHANGED** |
| 0 | 2 | v1.0.0: — → v1.1.0..v1.2.0: `spacer_0_2_20` address [20] → v1.3.0..v9.0.0: `spacer_0_2_30` bytes30 [30] **CHANGED** |
| 1 | 0 | v1.0.0..v9.0.0: `spacer_1_0_20` address [20] |
| 2 | 0 | v1.0.0..v9.0.0: `deposits` mapping(address => mapping(address => uint256)) [32] |
| 3 | 0 | v1.0.0: `__gap` uint256[47] [1504] → v1.1.0: `messenger` contract CrossDomainMessenger [20] → v1.2.0: `__gap` uint256[47] [1504] → v1.3.0..v1.6.0: `messenger` contract CrossDomainMessenger [20] → v1.8.0..v9.0.0: `messenger` contract ICrossDomainMessenger [20] **CHANGED** |
| 4 | 0 | v1.0.0: — → v1.1.0: `__gap` uint256[46] [1472] → v1.2.0: — → v1.3.0..v9.0.0: `otherBridge` contract StandardBridge [20] **CHANGED** |
| 5 | 0 | v1.0.0..v1.2.0: — → v1.3.0..v9.0.0: `__gap` uint256[45] [1440] **CHANGED** |
| 50 | 0 | v1.0.0..v1.1.0: — → v1.2.0..v1.6.0: `superchainConfig` contract SuperchainConfig [20] → v1.8.0..v3.0.1: `superchainConfig` contract ISuperchainConfig [20] → v4.0.0..v9.0.0: `spacer_50_0_20` address [20] **CHANGED** |
| 51 | 0 | v1.0.0..v1.4.0: — → v1.5.0..v1.6.0: `systemConfig` contract SystemConfig [20] → v1.8.0: `systemConfig` contract ISystemConfig [20] → v2.0.0..v9.0.0: `spacer_51_0_20` address [20] **CHANGED** |
| 52 | 0 | v1.0.0..v3.0.1: — → v4.0.0..v9.0.0: `systemConfig` contract ISystemConfig [20] **CHANGED** |

### L1ERC721Bridge

Tags with this contract: v1.1.0 .. v9.0.0 (19 tags).

| slot | off | lineage (tag range: `label` type [bytes]) |
|---|---|---|
| 0 | 0 | v1.1.0..v9.0.0: `_initialized` uint8 [1] |
| 0 | 1 | v1.1.0..v9.0.0: `_initializing` bool [1] |
| 0 | 2 | v1.1.0: `messenger` contract CrossDomainMessenger [20] → v1.2.0: — → v1.3.0..v9.0.0: `spacer_0_2_30` bytes30 [30] **CHANGED** |
| 1 | 0 | v1.1.0..v1.2.0: `__gap` uint256[48] [1536] → v1.3.0..v1.6.0: `messenger` contract CrossDomainMessenger [20] → v1.8.0..v9.0.0: `messenger` contract ICrossDomainMessenger [20] **CHANGED** |
| 2 | 0 | v1.1.0..v1.2.0: — → v1.3.0..v1.5.0: `otherBridge` contract StandardBridge [20] → v1.6.0..v9.0.0: `otherBridge` contract ERC721Bridge [20] **CHANGED** |
| 3 | 0 | v1.1.0..v1.2.0: — → v1.3.0..v9.0.0: `__gap` uint256[46] [1472] **CHANGED** |
| 49 | 0 | v1.1.0..v9.0.0: `deposits` mapping(address => mapping(address => mapping(uint256 => bool))) [32] |
| 50 | 0 | v1.1.0: — → v1.2.0..v1.6.0: `superchainConfig` contract SuperchainConfig [20] → v1.8.0..v3.0.1: `superchainConfig` contract ISuperchainConfig [20] → v4.0.0..v9.0.0: `spacer_50_0_20` address [20] **CHANGED** |
| 51 | 0 | v1.1.0..v3.0.1: — → v4.0.0..v9.0.0: `systemConfig` contract ISystemConfig [20] **CHANGED** |

### OptimismMintableERC20Factory

Tags with this contract: v1.0.0 .. v9.0.0 (20 tags).

| slot | off | lineage (tag range: `label` type [bytes]) |
|---|---|---|
| 0 | 0 | v1.0.0: — → v1.1.0: `_initialized` uint8 [1] → v1.2.0: — → v1.3.0..v9.0.0: `_initialized` uint8 [1] **CHANGED** |
| 0 | 1 | v1.0.0: — → v1.1.0: `_initializing` bool [1] → v1.2.0: — → v1.3.0..v9.0.0: `_initializing` bool [1] **CHANGED** |
| 0 | 2 | v1.0.0: — → v1.1.0: `bridge` address [20] → v1.2.0: — → v1.3.0..v9.0.0: `spacer_0_2_30` bytes30 [30] **CHANGED** |
| 1 | 0 | v1.0.0..v1.2.0: — → v1.3.0..v9.0.0: `bridge` address [20] **CHANGED** |
| 2 | 0 | v1.0.0..v1.2.0: — → v1.3.0..v1.6.0: `__gap` uint256[49] [1568] → v1.8.0..v9.0.0: `deployments` mapping(address => address) [32] **CHANGED** |
| 3 | 0 | v1.0.0..v1.6.0: — → v1.8.0..v9.0.0: `__gap` uint256[48] [1536] **CHANGED** |

### SuperchainConfig

Tags with this contract: v1.2.0 .. v9.0.0 (18 tags).

| slot | off | lineage (tag range: `label` type [bytes]) |
|---|---|---|
| 0 | 0 | v1.2.0..v9.0.0: `_initialized` uint8 [1] |
| 0 | 1 | v1.2.0..v9.0.0: `_initializing` bool [1] |
| 0 | 2 | v1.2.0..v3.0.1: — → v4.0.0..v9.0.0: `guardian` address [20] **CHANGED** |
| 1 | 0 | v1.2.0..v3.0.1: — → v4.0.0..v9.0.0: `pauseTimestamps` mapping(address => uint256) [32] **CHANGED** |

### ProtocolVersions

Tags with this contract: v1.2.0 .. v7.0.0 (16 tags).

| slot | off | lineage (tag range: `label` type [bytes]) |
|---|---|---|
| 0 | 0 | v1.2.0..v7.0.0: `_initialized` uint8 [1] |
| 0 | 1 | v1.2.0..v7.0.0: `_initializing` bool [1] |
| 1 | 0 | v1.2.0..v7.0.0: `__gap` uint256[50] [1600] |
| 51 | 0 | v1.2.0..v7.0.0: `_owner` address [20] |
| 52 | 0 | v1.2.0..v7.0.0: `__gap` uint256[49] [1568] |

### DisputeGameFactory

Tags with this contract: v1.1.0 .. v9.0.0 (19 tags).

| slot | off | lineage (tag range: `label` type [bytes]) |
|---|---|---|
| 0 | 0 | v1.1.0..v9.0.0: `_initialized` uint8 [1] |
| 0 | 1 | v1.1.0..v9.0.0: `_initializing` bool [1] |
| 1 | 0 | v1.1.0..v9.0.0: `__gap` uint256[50] [1600] |
| 51 | 0 | v1.1.0..v9.0.0: `_owner` address [20] |
| 52 | 0 | v1.1.0..v9.0.0: `__gap` uint256[49] [1568] |
| 101 | 0 | v1.1.0..v9.0.0: `gameImpls` mapping(GameType => contract IDisputeGame) [32] |
| 102 | 0 | v1.1.0: `_disputeGames` mapping(Hash => GameId) [32] → v1.2.0..v9.0.0: `initBonds` mapping(GameType => uint256) [32] **CHANGED** |
| 103 | 0 | v1.1.0: `_disputeGameList` GameId[] [32] → v1.2.0..v9.0.0: `_disputeGames` mapping(Hash => GameId) [32] **CHANGED** |
| 104 | 0 | v1.1.0: — → v1.2.0..v9.0.0: `_disputeGameList` GameId[] [32] **CHANGED** |
| 105 | 0 | v1.1.0..v4.1.0: — → v5.0.0..v9.0.0: `gameArgs` mapping(GameType => bytes) [32] **CHANGED** |

### AnchorStateRegistry

Tags with this contract: v1.4.0 .. v9.0.0 (16 tags).

| slot | off | lineage (tag range: `label` type [bytes]) |
|---|---|---|
| 0 | 0 | v1.4.0..v9.0.0: `_initialized` uint8 [1] |
| 0 | 1 | v1.4.0..v9.0.0: `_initializing` bool [1] |
| 0 | 2 | v1.4.0..v1.8.0: — → v2.0.0..v3.0.1: `superchainConfig` contract ISuperchainConfig [20] → v4.0.0..v8.0.0: `systemConfig` contract ISystemConfig [20] → v9.0.0: `spacer_0_2_20` address [20] **CHANGED** |
| 1 | 0 | v1.4.0..v1.8.0: `anchors` mapping(GameType => struct OutputRoot) [32] → v2.0.0..v9.0.0: `disputeGameFactory` contract IDisputeGameFactory [20] **CHANGED** |
| 2 | 0 | v1.4.0..v1.5.0: — → v1.6.0: `superchainConfig` contract SuperchainConfig [20] → v1.8.0: `superchainConfig` contract ISuperchainConfig [20] → v2.0.0..v3.0.1: `portal` contract IOptimismPortal2 [20] → v4.0.0..v6.0.0: `anchorGame` contract IFaultDisputeGame [20] → v7.0.0..v9.0.0: `anchorGame` contract IDisputeGame [20] **CHANGED** |
| 3 | 0 | v1.4.0..v1.8.0: — → v2.0.0..v3.0.1: `anchorGame` contract IFaultDisputeGame [20] → v4.0.0..v9.0.0: `startingAnchorRoot` struct Proposal [64] **CHANGED** |
| 4 | 0 | v1.4.0..v1.8.0: — → v2.0.0..v3.0.1: `startingAnchorRoot` struct OutputRoot [64] → v4.0.0..v9.0.0: — **CHANGED** |
| 5 | 0 | v1.4.0..v3.0.1: — → v4.0.0..v9.0.0: `disputeGameBlacklist` mapping(contract IDisputeGame => bool) [32] **CHANGED** |
| 6 | 0 | v1.4.0..v3.0.1: — → v4.0.0..v9.0.0: `respectedGameType` GameType [4] **CHANGED** |
| 6 | 4 | v1.4.0..v3.0.1: — → v4.0.0..v9.0.0: `retirementTimestamp` uint64 [8] **CHANGED** |
| 6 | 12 | v1.4.0..v8.0.0: — → v9.0.0: `ethLockbox` contract IETHLockbox [20] **CHANGED** |

### DelayedWETH

Tags with this contract: v1.4.0 .. v9.0.0 (16 tags).

| slot | off | lineage (tag range: `label` type [bytes]) |
|---|---|---|
| 0 | 0 | v1.4.0..v9.0.0: `_initialized` uint8 [1] |
| 0 | 1 | v1.4.0..v9.0.0: `_initializing` bool [1] |
| 1 | 0 | v1.4.0..v3.0.1: `__gap` uint256[50] [1600] → v4.0.0..v9.0.0: `_balanceOf` mapping(address => uint256) [32] **CHANGED** |
| 2 | 0 | v1.4.0..v3.0.1: — → v4.0.0..v9.0.0: `_allowance` mapping(address => mapping(address => uint256)) [32] **CHANGED** |
| 3 | 0 | v1.4.0..v3.0.1: — → v4.0.0..v9.0.0: `withdrawals` mapping(address => mapping(address => struct DelayedWETH.WithdrawalRequest)) [32] **CHANGED** |
| 4 | 0 | v1.4.0..v3.0.1: — → v4.0.0..v8.0.0: `systemConfig` contract ISystemConfig [20] → v9.0.0: `spacer_4_0_20` address [20] **CHANGED** |
| 5 | 0 | v1.4.0..v8.0.0: — → v9.0.0: `ethLockbox` contract IETHLockbox [20] **CHANGED** |
| 51 | 0 | v1.4.0..v3.0.1: `_owner` address [20] → v4.0.0..v9.0.0: — **CHANGED** |
| 52 | 0 | v1.4.0..v3.0.1: `__gap` uint256[49] [1568] → v4.0.0..v9.0.0: — **CHANGED** |
| 101 | 0 | v1.4.0..v1.6.0: `balanceOf` mapping(address => uint256) [32] → v1.8.0..v3.0.1: `_balanceOf` mapping(address => uint256) [32] → v4.0.0..v9.0.0: — **CHANGED** |
| 102 | 0 | v1.4.0..v1.6.0: `allowance` mapping(address => mapping(address => uint256)) [32] → v1.8.0..v3.0.1: `_allowance` mapping(address => mapping(address => uint256)) [32] → v4.0.0..v9.0.0: — **CHANGED** |
| 103 | 0 | v1.4.0..v1.6.0: `withdrawals` mapping(address => mapping(address => struct IDelayedWETH.WithdrawalRequest)) [32] → v1.8.0..v3.0.1: `withdrawals` mapping(address => mapping(address => struct DelayedWETH.WithdrawalRequest)) [32] → v4.0.0..v9.0.0: — **CHANGED** |
| 104 | 0 | v1.4.0..v1.6.0: `config` contract SuperchainConfig [20] → v1.8.0..v3.0.1: `config` contract ISuperchainConfig [20] → v4.0.0..v9.0.0: — **CHANGED** |

### ETHLockbox

Tags with this contract: v4.0.0 .. v9.0.0 (7 tags).

| slot | off | lineage (tag range: `label` type [bytes]) |
|---|---|---|
| 0 | 0 | v4.0.0..v9.0.0: `_initialized` uint8 [1] |
| 0 | 1 | v4.0.0..v9.0.0: `_initializing` bool [1] |
| 0 | 2 | v4.0.0..v8.0.0: `systemConfig` contract ISystemConfig [20] → v9.0.0: `spacer_0_2_20` address [20] **CHANGED** |
| 1 | 0 | v4.0.0..v9.0.0: `authorizedPortals` mapping(contract IOptimismPortal2 => bool) [32] |
| 2 | 0 | v4.0.0..v9.0.0: `authorizedLockboxes` mapping(contract IETHLockbox => bool) [32] |
| 3 | 0 | v4.0.0..v8.0.0: — → v9.0.0: `superchainConfig` contract ISuperchainConfig [20] **CHANGED** |

### AddressManager

Tags with this contract: v1.2.0 .. v9.0.0 (18 tags).

| slot | off | lineage (tag range: `label` type [bytes]) |
|---|---|---|
| 0 | 0 | v1.2.0..v9.0.0: `_owner` address [20] |
| 1 | 0 | v1.2.0..v9.0.0: `addresses` mapping(bytes32 => address) [32] |

### ProxyAdmin

Tags with this contract: v1.0.0 .. v9.0.0 (20 tags).

| slot | off | lineage (tag range: `label` type [bytes]) |
|---|---|---|
| 0 | 0 | v1.0.0..v9.0.0: `_owner` address [20] |
| 1 | 0 | v1.0.0..v9.0.0: `proxyType` mapping(address => enum ProxyAdmin.ProxyType) [32] |
| 2 | 0 | v1.0.0..v1.1.0: — → v1.2.0..v9.0.0: `implementationName` mapping(address => string) [32] **CHANGED** |
| 3 | 0 | v1.0.0..v1.6.0: `addressManager` contract AddressManager [20] → v1.8.0..v9.0.0: `addressManager` contract IAddressManager [20] **CHANGED** |
| 3 | 20 | v1.0.0..v9.0.0: `upgrading` bool [1] |

### ResolvedDelegateProxy

Tags with this contract: v1.2.0 .. v9.0.0 (18 tags).

| slot | off | lineage (tag range: `label` type [bytes]) |
|---|---|---|
| 0 | 0 | v1.2.0..v9.0.0: `implementationName` mapping(address => string) [32] |
| 1 | 0 | v1.2.0..v9.0.0: `addressManager` mapping(address => contract AddressManager) [32] |

### L1ChugSplashProxy

Tags with this contract: v1.0.0 .. v9.0.0 (20 tags).

| slot | off | lineage (tag range: `label` type [bytes]) |
|---|---|---|

### Proxy

Tags with this contract: v1.0.0 .. v9.0.0 (20 tags).

| slot | off | lineage (tag range: `label` type [bytes]) |
|---|---|---|

### StorageSetter

Tags with this contract: v1.2.0 .. v9.0.0 (18 tags).

| slot | off | lineage (tag range: `label` type [bytes]) |
|---|---|---|

## 4. Real storage history of the OP Mainnet proxies

Every slot that was non-zero at any sampled block (block before / at each signature change, and 26433900), when it was
written, when (if ever) it was cleared, and what v9 does with it. Mapping bases read 0 by construction; their entries are
treated in §6. Full timelines: `evidence/F4/slots-<Contract>.json`; exact per-upgrade writes: `evidence/F4/trace/`.

### 4.1 OptimismPortal `0xbEb5Fc57…` (ERC-1967, admin `0x543bA4AA…` since 17365802)

| Slot | Written (block) | Cleared | Value history | v9 reader |
|---|---|---|---|---|
| 0 `_initialized` | 17423158 | — | 1 → 2 (22990599) → 3 (23491328) | `reinitializer(3)` |
| 1 `params` | 17423158 | — | ResourceMetering, live | live |
| 2-49 `__gap` | never | — | 0 | none |
| 50 `l2Sender` | 17423158 | reset to 0 and re-set to `0xdEaD` inside the FP upgrade tx 20062696 (Safe → `portal.setAddress(50, 0)` while the StorageSetter was installed) | `0xdEaD` | live |
| 51 `finalizedWithdrawals` | entries from 17423158 | never | same slot, same key, same value type at every tag | live (hash-global replay protection) |
| 52 legacy `provenWithdrawals` | entries 17423158 .. 20062695 | **never** | 12,338 hashes (§6.1) | **none** |
| 53[0] `paused` | 19233786 (`Paused`) | 19234082 (`Unpaused`) | 1 for 296 blocks on 2024-02-15; `initialize(false)`-equivalent at Bedrock emitted `Unpaused` | none |
| 53[1:21] `superchainConfig` | 19314493 | never | `0x95703e09…` | none (v9: `ethLockbox.superchainConfig()`) |
| 54 `l2Oracle` | 19634866 | never | `0xdfe97868…` | none |
| 55 `systemConfig` | 19634866 | — | `0x229047fe…` | live |
| 56 `disputeGameFactory` | 20062696 | never | `0xe5965Ab5…` | none (v9: `anchorStateRegistry.disputeGameFactory()`) |
| 57 `provenWithdrawals` (2-level) | entries from 20062696 | per entry by `deleteProvenWithdrawal` (v9) | `[timestamp(8) ‖ game(20)]` | live |
| 58 `disputeGameBlacklist` | **no entry ever** (0 `DisputeGameBlacklisted` events 17,420,000 .. 23,000,000) | — | — | none |
| 59 `respectedGameType ‖ UpdatedAt` | 20062696 (`0`, 1718037779) → `RespectedGameTypeSet(1, 1723833359)` at 20543021 → `(0, 1726070915)` at 20728464 | never | `0x66e1c083 00000000` | none (v9 getters return the ASR's values: type 9, 1753379243) |
| 60 `proofSubmitters` | entries from 20062696 | never (not even by `deleteProvenWithdrawal`) | arrays | live |
| 61 `_balance` | never | — | 0 | none |
| 62 `anchorStateRegistry` | 22990599 | — | `0x23B2C629…` | live |
| 63 `ethLockbox` (+ `superRootsActive` bit) | 22990599 | — | `0x322b47Ff…`, bit 160 never set | live |

Custody moves seen in the traces: 293,288.2568 ETH L1StandardBridge → portal at 17423158 (`PortalSender.donate()` through a
temporary L1SB implementation `0x0a893d95…`), 236,752.2431 ETH portal → ETHLockbox at 22990599.

### 4.2 SystemConfig `0x229047fe…`

| Slot | Written | Cleared | Notes | v9 reader |
|---|---|---|---|---|
| 0 | 17422444 | — | 1 → 2 → 3 | |
| 51 `_owner` | 17422444 | — | `0x9BA6e03D…` → `0x847B5c17…` (between 20062696 and 21695023) | live |
| 101 `overhead` | 17422444 (188) | 0 by Ecotone `setGasConfig` before 19634865 | | `overhead()` getter only |
| 102 `scalar` | 17422444 (684,000) | — | versioned (`0x01…`) since Ecotone | live |
| 103 `batcherHash`, 105 `_resourceConfig` | 17422444 | — | | live |
| 104 `gasLimit` (+ scalars) | 17422444 | — | bytes 8-15 first written 21695024 (Holocene `initialize`) | live |
| 106 | first non-zero between 21695024 and 22990598 (owner `setEIP1559Params`: 250 / 2) | — | **never held `startBlock`** | live |
| 107 `l2ChainId`, 108 `superchainConfig` | 22990599 | — | 10; `0x95703e09…` | live |
| 109 `isFeatureEnabled` | entry `0x58e88e94…` = 1 at 23491328 (ETH_LOCKBOX) | — | | live |
| `unsafeblocksigner` | 17422444 | — | | live |
| `l1crossdomainmessenger`, `l1erc721bridge`, `l1standardbridge`, `optimismportal`, `optimismmintableerc20factory`, `startBlock` (= 17422444) | 19634866 | — | written by the MCP `initialize` / StorageSetter | live |
| `l2outputoracle` | 19634866 | **20062696** (Safe → `setAddress(slot, 0)` under StorageSetter) | | none |
| `disputegamefactory` | 20062696 (same tx) | **22990599** | | none |
| `batchinbox` | 19634866 `0xFF00…0010` | **overwritten 25397811 with `0x00c65A7b…9c98`**, zeroed 26048619 | `batchInbox()` returned the wrong address for 650,808 blocks; reverts since U20. Writer: v7 `OPContractsManagerV2` re-init passes `_chainIdToBatchInboxAddress(l2ChainId)` (`op-v7.0.0 src/L1/opcm/OPContractsManagerV2.sol:1011`). Unichain: `0xff00…0130` → `0x00b2244e…8fc5` at 25475307; Ink / Soneium already held the derived value (cast @ 25397810 / 25397811 / 26048618) | none (zeroed by `initialize`, `SystemConfig.sol:242`) |
| `delayedweth`, `opcm` | 25397811 | — | `opcm`: `0x9ce712ff…` → `0x1951828C…` → `0x2d91e6F2…` | live |
| gas-paying-token slots, OZ-v5 slot | never | — | | |

### 4.3 L1CrossDomainMessenger `0x25ace71c…` (ResolvedDelegateProxy, 2021)

| Slot | Written | Cleared | Notes | v9 reader |
|---|---|---|---|---|
| 0[0:20] `libAddressManager` | 12686759 | **19314493** | `0xdE1FCfB0…` for 2.7 years, including the whole v1.0.0 era | none |
| 0[20] `_initialized` | 12686759 (OVM `initialize`) | — | **1 from 2021 to 22990599**, then 2, 3. Bedrock did not re-initialise (trace 17423158: `L1CDM.initialize()` → "execution reverted", swallowed by the SystemDictator) | `reinitializer(3)` |
| 51 OVM `_owner` | 12686759 | never | `0x99965713…` → `0x9BA6e03D…` (OVM-era `transferOwnership`) | none |
| 151 ReentrancyGuard `_status` | 12686759 | never | 1 | none |
| 201 / 202 `blockedMessages` / `relayedMessages` | OVM entries | never | not enumerable; 0 for all 88 sampled message hashes | none |
| 203 `successfulMessages` | entries since 2021 | never | 88 / 88 sampled `RelayedMessage` hashes (2021 .. 2026) read 1 at 26433900 | **live — by design**: the v0 branch requires `successfulMessages[hashCrossDomainMessageV0] == false` (`CrossDomainMessenger.sol:229-231`) |
| 204 `xDomainMsgSender` | 12686759 | — | `0xdEaD` | live |
| 205 `msgNonce` | first Bedrock `sendMessage` | — | 0 at Bedrock → 272,941 | live |
| 206 `failedMessages` | Bedrock entries | — | no `FailedRelayedMessage` in the 11 sampled windows | live |
| 207 `otherMessenger` | 19634866 | — | `0x4200…0007` | live |
| 249, 250, 253 | never | — | | none |
| 251 `superchainConfig` | 19314493 | never | `0x95703e09…` | none |
| 252 `portal` | 19634866 | — | | live |
| 254 `systemConfig` | 22990599 | — | | live |
| `keccak(abi.encode(proxy, 0))`, `keccak(abi.encode(proxy, 1))` (ResolvedDelegateProxy `implementationName`, `addressManager`) | 12686758 | — | `"OVM_L1CrossDomainMessenger"` (short-string encoding `…34`), `0xdE1FCfB0…` | **live raw reads**: `ProxyAdminOwnedBase.proxyAdmin()` (`src/universal/ProxyAdminOwnedBase.sol:60-70`) |
| EIP-1967 admin / impl slots, OZ-v5 slot | never | — | 0 (so `proxyAdmin()` takes the ResolvedDelegateProxy branch) | raw read (:48) |

AddressManager entry `OVM_L1CrossDomainMessenger` (slot `0x51521693…385e`): `0x16393737…` (2021-06-22) → `0xbfba066b…` →
0 (13596294) → `0xd9166833…` (OVM 2) → **0 at 17422444** → `0x2150bc3c…` 1.4.0 at 17423158 → 2.2.0 → 2.3.0 → 2.5.0 → 2.6.0 →
2.9.0 → 2.10.0 → 2.11.0 → 2.11.1 → 2.13.0. For 714 blocks during the Bedrock migration the messenger resolved to
`address(0)` (every call reverted).

### 4.4 L1StandardBridge `0x99C9fc46…` (L1ChugSplashProxy, 2021)

| Slot | Written | Cleared | Notes | v9 reader |
|---|---|---|---|---|
| 0 | 12686789 OVM `messenger` `0x25ace71c…` | **overwritten 19314493** (StorageSetter zero, then `_initialized = 1`) | 1 → 2 → 3 | initializer bytes only |
| 1 OVM `l2TokenBridge` | before 13354114 | never | `0x4200…0010` | none |
| 2 `deposits` | OVM-era entries onward | — | same slot and key shape since OVM (escrow accounting, B11) | live |
| 3 `messenger`, 4 `otherBridge` | 19634866 | — | | live |
| 50 `superchainConfig` | 19314493 | never | | none |
| 51 | never | | | |
| 52 `systemConfig` | 22990599 | — | | live |

### 4.5 L1ERC721Bridge, OptimismMintableERC20Factory, L2OutputOracle

* L1ERC721Bridge `0x5a7749f8…`: implementation 1.0.0 `0x3268ed09…` from 2022-10-04 through Bedrock (no initializer, slot
  0 = 0) until 19314493; slot 0: 1 → 2 → 3; 1, 2 written 19634866; 50 written 19314493 (dead); 51 written 22990599;
  `deposits` at 49 since v1.0.0.
* Factory `0x75505a97…`: no storage until 19634866 (`_initialized = 1`, `bridge` at 1); `deployments` (slot 2) entries
  from U13 on. `_initialized` is still 1 (plain `initializer`; re-run through the StorageSetter at U19, U20, U21).
* L2OutputOracle `0xdfe97868…` **still exists**: implementation 1.8.0 `0xf243bed1…`, `_initialized = 1`,
  `l2Outputs.length = 8,879`, slots 4-8 written at 19634866 (`submissionInterval` 1800, `l2BlockTime` 2, challenger
  `0x9BA6e03D…`, proposer `0x473300df…`, finalization period 604800). Nothing in v9 reads it; the portal's pointer to
  it is the dead spacer at slot 54.

### 4.6 SuperchainConfig `0x95703e09…`, ProtocolVersions `0x8062AbC2…`

* SuperchainConfig: slot 0 = 1 (19064589) → `guardian ‖ 2` at 22990599. Hashed `guardian`: `0x9BA6e03D…` → `0x09f7150D…`
  at **20063224** (StorageSetter cycle, same implementation before and after, tx `0xe361c0d4…`) → 0 at 22990599. Hashed
  `paused`: 1 between `Paused("…")` 22482108 and `Unpaused()` 22482160 (2025-05-14), 0 otherwise. v9 reads neither.
  `Paused(address 0x758e0ee6…)` at 25689317 is an identifier pause for an address that is none of the four chains'
  lockboxes or portals; no matching `Unpaused` (it expired). Hand-off to the pause worker (B06).
* ProtocolVersions: created under v1.1.0 → `_initialized = 3`, never changed; implementation 1.0.0 → 1.1.0 at U13; the
  contract is gone from the v8 / v9 trees and is not upgraded any more.

### 4.7 DisputeGameFactory `0xe5965Ab5…`

One proxy since 2024-05-16, layout stable (101-104, +105 `gameArgs` at U17). `_initialized = 1` throughout. Game
implementation generations (slot `gameImpls[t]`): type 0 / 1 at 19884592, 20270847, 20723924, 21580854, 22182531,
22339996, 22432368, 22990599, 23491328, 23877377, 24421512 (+ type 8); 25397811: type 0 removed, type 8 → CANNON_KONA
2.4.2; 26048619: types 1 and 8 removed, **types 5 and 9 (super roots) registered**. `gameCount` 21,389.

### 4.8 AnchorStateRegistry — three proxies, one per layout

| Proxy | Layout | Life | State today |
|---|---|---|---|
| `0x18DAc71c…` | v1.4.0-v1.8.0 (`anchors` mapping at 1, `superchainConfig` at 2) | 2024-05-16 .. ; 1.0.0 → 2.0.0 at 20723924 | frozen; `anchors(0)` = block 134,004,216; used only by games ≤ 1.3.1 |
| `0x1c68ECfb…` | v2.0.0-v3.0.1 (`superchainConfig` 0[2:22], `disputeGameFactory` 1, `portal` 2, `anchorGame` 3, `startingAnchorRoot` 4-5) | created 22182531, never upgraded (2.2.2 `0x7b465370…`) | frozen, but **its policy getters follow the live ASR through the v9 portal aliases** (already filed as PRIM-W0-02; not re-filed): `respectedGameType()` returns 9 at 26433900 |
| `0x23B2C629…` | v4.0.0+ | created 22990599 | live; slot 6 = `ethLockbox ‖ 1753379243 ‖ 9` |

Live ASR slot history: 0 = `systemConfig ‖ 1` (dead spacer in v9); 1 DGF; 2 `anchorGame` (set by games; **cleared at
26048619**); 3-4 `startingAnchorRoot` = `(0xfce6d556…, 138585637)` → **`(0xbd4aeba9…, 1788842855)` at 26048619**; 5
blacklist: no entry (0 `DisputeGameBlacklisted` events on the live ASR); 6: `respectedGameType` 0 → 8 (25397811) → 9
(26048619) with `retirementTimestamp` = 1753379243 unchanged since 22990599 (0 `RetirementTimestampSet`, 0
`RespectedGameTypeSet` events: both type changes came through OPCM re-initialisation, not through the Guardian).

### 4.9 DelayedWETH — ten proxies

| Proxy | Version | Layout | ETH at 26433900 |
|---|---|---|---|
| g1 `0xE497B094…` (2024-05-16) | 1.0.0 | Ownable (owner Safe at 51, `config` = SuperchainConfig at 104) | 0.16 |
| g2 `0x82511d49…` / `0x9F9b897e…` (2024-08-29) | 1.1.0 | same | 0.08 / 0 |
| g3 `0x323dFC63…` / `0x21429aF6…` (2024-12-11; 1.3.0 at U13) | 1.3.0 | same | 0.08 / 0 |
| g4 `0xe214879a…` / `0xc5f54F93…` (U16) | 1.5.0 | v4 (`systemConfig` at 4) | 0 / 0 |
| g5 `0xD061AB95…` / `0xe03F4d1D…` (U16a, used through U18) | 1.5.0 | v4 | 0 / 0 |
| live `0x1B6DBF05…` (U19) | 2.0.0 | v9 (`spacer_4`, `ethLockbox` at 5) | 20.66 |

The legacy proxies (g1-g3) call `SuperchainConfig.paused()` (no-argument form), which v9 still implements
(`SuperchainConfig.sol:135`). Bond accounting is OPUS-11's (B09); storage-wise nothing is re-interpreted.

### 4.10 ETHLockbox, ProxyAdmin, AddressManager

* ETHLockbox `0x322b47Ff…`: created 22990599; slot 0 `systemConfig ‖ 1` (dead in v9), slot 3 written 26430859 (PASS A).
* ProxyAdmin `0x543bA4AA…` (not a proxy): `_owner` deployer `0x354f3f4e…` (17365800) → `0x9BA6e03D…` (17381274) →
  SystemDictator `0xb4453ceb…` (17422444) → `0x9BA6e03D…` (17423158) → Safe `0x5a0Aae59…` (19193284); slot 3
  `addressManager` written 17422444, `upgrading` false at every sample.
* AddressManager `0xdE1FCfB0…`: owner `0x99965713…` (2021) → `0x9BA6e03D…` → SystemDictator → ProxyAdmin (17423158).
  Sixteen OVM entries were zeroed in the Bedrock tx (trace 17423158); the only entry v9 resolves is
  `OVM_L1CrossDomainMessenger`.

### 4.11 The U20 re-initialisation of the ASR (unit change in place)

Trace `26048619-diff.json`, ASR `0x23B2C629…`: slot 2 `0xe54bc554…` → 0; slot 3 `0xfce6d556…` → `0xbd4aeba9…`; slot 4
`0x842a625` → `0x6a9f9367`; slot 6 `…08` → `…09`. `0x6a9f9367` = 1788842855 = 2026-09-08 04:47:35 UTC: a **timestamp**
(super-root sequence number), where the slot held an L2 block number before. `retirementTimestamp` kept its U16 value,
so every type-0 / type-8 output-root game created since 2025-07-24 remains proper and respected. The one place where the
two units meet is `AnchorStateRegistry.setAnchorState` (`_game.l2SequenceNumber() <= anchorL2BlockNumber`,
`AnchorStateRegistry.sol:365`, permissionless). See PRIM-F4-01. Census (PASS A / F5 game scans `evidence/F5/op-games-0-21388.json`, `ink-games-0-2639.json`, re-counted in this run):
highest claim-valid output-root `l2SequenceNumber` 157,333,888 (OP) and 56,762,732 (Ink); output-root games above the
super-root anchor: 4 (OP) and 3 (Ink), all type 8, all CHALLENGER_WINS (final). At 26433900 `gameImpls(0|1|8) = 0` on the
OP, Ink, Soneium and Unichain factories and the respected types are 9 / 9 / 5 / 9, so no new output-root game can be
respected; the other chains' anchors have already advanced to super-root timestamps (Ink 1,794,288,067, Soneium
1,794,596,679, Unichain 1,794,300,387). Not censused: Unichain and Soneium output-root games (limit).

## 5. Raw slot readers and writers in v9

`grep` over `src/L1`, `src/L1/opcm`, `src/universal`, `src/dispute`, `src/legacy`, `scripts/` at `ba6fcadb` for `sload`,
`sstore`, `Storage.get*/set*`, `setBytes32`, `getBytes32`, `vm.load`, `vm.store`, hard-coded slot numbers:

| Reader / writer | Slot | Historical value it meets on the four chains | Verdict |
|---|---|---|---|
| `SystemConfig` hashed getters / setters (`SystemConfig.sol:187-349, 489`) | `systemconfig.*`, `START_BLOCK_SLOT` | all written by the same field under the same meaning since MCP; `LEGACY_BATCH_INBOX_SLOT` only zeroed (:242) | no reinterpretation |
| `ProxyAdminOwnedBase.proxyAdmin()` (:48-70) | EIP-1967 admin slot; `keccak(abi.encode(this,0))`, `keccak(abi.encode(this,1))` | L1CDM: admin slot 0 (never written), mapping slots written by the ResolvedDelegateProxy in 2021 and never changed | intended |
| `OPContractsManagerUtils.upgrade` (:359-380) | `_initialized` slot + offset (0/0; L1CDM 0/20), OZ-v5 `0xf0c57e16…a00` | clears exactly one byte; OZ-v5 slot is 0 on every sampled proxy at every sampled block | no legacy read |
| `StorageSetter` (no access control) | any | only ever the implementation inside one transaction (all 14 upgrade traces + the full `Upgraded` census: every `Upgraded(StorageSetter)` is followed by `Upgraded(real impl)` in the same tx) | atomic |
| `scripts/deploy/ChainAssertions.sol:135, 287` (`vm.load` slot 204 of the messenger, slot 61 of the portal), `FetchChainInfo.s.sol:562`, `DeployOwnership.s.sol:287`, `ForgeArtifacts.sol:211-220` | deployment-time assertions | scripts only; not part of the deployed system | out of scope |
| `OPContractsManagerStandardValidator`, `opcm/*Validator` | none raw (getters only; `l2SequenceNumber()` read at `StandardValidator.sol:1218`) | — | — |

No v9 production code reads a `spacer_*` slot. The only historical-value-meets-current-reader cases are the three
intended ones: `finalizedWithdrawals` (slot 51), `successfulMessages` v0 hashes (slot 203), ResolvedDelegateProxy slots.

## 6. Mapping archaeology (B01, B02, B10)

### 6.1 Portal

| Mapping | v1.0.0 .. v1.3.0 (portal v1) | v1.4.0 .. v3.0.1 (Portal2) | v4.0.0 .. v9.0.0 |
|---|---|---|---|
| `finalizedWithdrawals` | slot 51, `mapping(bytes32 => bool)` | same | same |
| `provenWithdrawals` | slot 52, `mapping(bytes32 => {bytes32 outputRoot; uint128 timestamp; uint128 l2OutputIndex})`, entry at `keccak(hash . 52)` (2 words) | slot 57, `mapping(bytes32 => mapping(address => {IDisputeGame disputeGameProxy; uint64 timestamp}))`, entry at `keccak(submitter . keccak(hash . 57))` (1 word); slot 52 = `spacer_52_0_32` | same |
| `proofSubmitters` | — | slot 60, `mapping(bytes32 => address[])` | same |
| `disputeGameBlacklist` | — | slot 58, `mapping(IDisputeGame => bool)` | portal slot 58 = spacer; ASR slot 5 |
| `respectedGameType`, `…UpdatedAt` | — | slot 59 (4 + 8 bytes) | portal spacers; ASR slot 6 (`retirementTimestamp`) |

Census of the OP Mainnet portal (77,340 logs, `op-portal-withdrawal-events.jsonl`): 30,093 distinct proven hashes,
26,000 finalized (4 with `success = false`, all under v6 / v8), 0 double-finalized, 0 finalized-without-proof.

| Era of first proof | Portal | Proven hashes | Never finalized |
|---|---|---|---|
| 17423158 .. | v1 1.6.0 | 9,746 | 3,184 |
| 19314493 .. | v1 2.4.0 | 1,133 | 18 |
| 19634866 .. | v1 2.5.0 | 1,459 | 79 |
| 20062696 .. | Portal2 3.10.0 | 6,319 | 348 |
| 22182531 .. | 3.13.0 | 483 | 14 |
| 22339996 .. | 3.14.0 | 1,853 | 68 |
| 22990599 .. | 4.6.0 | 1,467 | 22 |
| 23491328 .. | 5.0.0 | 949 | 28 |
| 23877377 .. | 5.1.1 | 1,296 | 15 |
| 24421512 .. | 5.2.0 | 2,138 | 45 |
| 25397811 .. | 5.6.1 | 1,062 | 54 |
| 26048619 .. | 5.8.0 | 2,185 | 215 |
| 26430859 .. | 6.1.0 | 3 | 3 |

Proof-era → finalization-era crossings (latest proof before the finalization): v1 1.6.0 → 2.4.0: 212, → 2.5.0: 23;
2.4.0 → 2.5.0: 213; **none across 20062696** (213 legacy proofs were finalized later, all after a re-proof);
**none from 3.10.0 into 3.13.0** (U13 invalidated every earlier proof: the 3.13.0 portal calls
`wasRespectedGameTypeWhenCreated()` on the stored game, which pre-U13 games do not implement); 3.13.0 → 3.14.0: 178;
**none across 22990599** (U16: new ASR, retirement timestamp); 4.6.0 → 5.0.0: 158, → later: 26; 5.0.0 → 5.1.1: 137; 5.1.1 →
5.2.0: 175; 5.2.0 → 5.6.1: 88; 5.6.1 → 5.8.0: 126; 5.8.0 → 6.1.0: 4. So proofs have crossed every boundary since U16
(including U19 and U20, where the respected game type changed).

Real entries read through today's layout at 26433900 (`op-withdrawal-entries-by-era.json`, 291 entries, 12 unfinalized +
12 finalized per era): legacy eras 72 / 72 have a non-zero slot-52 entry and (except 3 re-proven ones) a zero slot-57
entry and `numProofSubmitters == 0`; fault-proof eras 219 / 219 have a zero slot-52 entry and a non-zero slot-57 word.

**Answers (B01).** (1) Legacy-format entries exist in live storage: yes, ~12.3k hashes, e.g.
`0xb27dc039…9cb3` → slot `0xd17642e6…13b2` = output root `0x968563fb…52a2`, timestamp 1689146939, L2OO index 852.
(2) Slot: `keccak256(abi.encode(hash, 52))` and `+1`. (3) Reachable by v9: **no** — `spacer_52_0_32` is private and
unreferenced (`OptimismPortal2.sol:67`); `test_legacyProvenEntriesExistButAreUnreachable` records every SLOAD of
`provenWithdrawals`, `numProofSubmitters`, `finalizedWithdrawals`, `checkWithdrawal`, `deleteProvenWithdrawal` for 24
real legacy hashes × 3 submitters and finds neither slot 52 nor the entry; `deleteProvenWithdrawal` reverts
`OptimismPortal_Unproven` at the `timestamp == 0` check (`:713-715`) **before** `status()` is called, so no call is ever
made to a legacy address; `test_fabricatedLegacyProofGivesNothing` writes a mature legacy proof for a fresh hash and gets
`Unproven` from both finalizers. (4) Every slot-57 entry was written by `proveWithdrawalTransaction` with a proxy taken
from the portal's own DisputeGameFactory (`gameAtIndex`), so the stored address is always a DGF clone (`status()` exists
on every generation since 1.2.0): C4's reopen condition ("a stored proof references a non-game / legacy address") is
false. Proofs stored against pre-U16 games cannot finalize (retired) and can be deleted only if that game is
CHALLENGER_WINS or blacklisted in the live ASR. (5) Ink / Soneium / Unichain: born on Portal2 3.10.0, so no legacy
entry can exist (§8).

### 6.2 Messenger (B10, storage side)

`successfulMessages` 203, `xDomainMsgSender` 204, `msgNonce` 205, `failedMessages` 206 at every tag v1.0.0 .. v9.0.0;
OVM `blockedMessages` 201 and `relayedMessages` 202 are spacers since v1.0.0. `sentMessages` never existed on L1 (OVM kept
L1 → L2 messages in the CanonicalTransactionChain queue). Sampled `RelayedMessage` hashes read through the v9 layout
(`op-l1cdm-message-entries-by-era.json`): 8 per window, windows starting 12,900,000 (OVM 1, hash in `data`, not indexed),
14,500,000 and 16,800,000 (OVM 2), 17,500,000 (v1.0.0), 19,400,000, 19,700,000, 21,000,000, 22,400,000, 23,600,000,
25,000,000, 26,300,000: **88 / 88** have `successfulMessages = 1`, `failedMessages = 0`, slots 201 / 202 keyed by the
same hash = 0. OVM entries are keyed by `keccak256(xDomainCalldata)` = `hashCrossDomainMessageV0`, which is exactly the
key the v9 version-0 branch checks. Whether one economic withdrawal can exist under two hashes is OPUS-03's question
(B02); storage-wise the three hash domains (v0 OVM, v1 Bedrock, portal withdrawal hash) live in slots that never moved.

### 6.3 Bridge

`L1StandardBridge.deposits[l1Token][l2Token]` at slot 2 and `L1ERC721Bridge.deposits` at slot 49 at every tag; the OVM
bridge already used slot 2 for the same mapping. Entry-level accounting is B11 (not done here).

## 7. Initializer history (B08)

### 7.1 `_initialized` after every upgrade (OP Mainnet)

| Proxy | Bedrock | 19314493 | 19634866 | 20062696 | U13 / U14 | U16 | U16a | U17 / U18 | U19 | U20 | U21 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Portal | 1 (`upgradeAndCall` `initialize(bool)`) | SS → 1 | SS → 1 | SS → 1 | upgrade only | **2** (`upgrade(...)`) | **3** | upgrade only | SS → 3 | SS → 3 | SS → 3 |
| SystemConfig | 1 (17422444) | SS → 1 | SS → 1 | SS, no init (two `setAddress`) | upgrade only (Holocene 21695024: SS → 1) | 2 | 3 | upgrade only | SS → 3 | SS → 3 | SS → 3 |
| L1CDM (slot 0 **offset 20**) | 1 inherited from OVM, `initialize()` reverted | SS (slot zeroed) → 1 | SS → 1 | — | upgrade only | 2 | 3 | upgrade only | SS → 3 | — | SS → 3 |
| L1StandardBridge | no initializer | SS (slot 0 zeroed) → 1 | SS → 1 | — | upgrade only | 2 | 3 | upgrade only | SS → 3 | — | SS → 3 |
| L1ERC721Bridge | no initializer | SS → 1 | SS → 1 | — | upgrade only | 2 | 3 | upgrade only | SS → 3 | — | SS → 3 |
| ERC20Factory | no initializer | SS, no init | SS → 1 | — | upgrade only | — | — | upgrade only | SS → 1 | — | SS → 1 |
| SuperchainConfig | — | (1 at 19064589) | | 20063224: SS → 1 | upgrade only | 2 | — | upgrade only | SS → 2 | SS → 2 | SS → 2 |
| DGF | — | | | (1 at 19884570) | upgrade only | upgrade only | — | upgrade only | SS → 1 | SS → 1 | SS → 1 |
| ASR (live) | | | | | | 1 (created) | — | upgrade only | SS → 1 | SS → 1 (same impl; state rewritten) | SS → 1 |
| ETHLockbox | | | | | | 1 (created) | — | — | SS → 1 | SS → 1 | SS → 1 |
| DelayedWETH (live) | | | | | | | | | 1 (created) | SS → 1 | SS → 1 |
| L2OutputOracle | 1 | SS → 1 | SS → 1 | frozen | | | | | | | |
| ProtocolVersions | 3 at 18367320 | | | | upgrade only | | | | | | |

SS = StorageSetter installed, `_initialized` zeroed (whole slot before U16; single byte from the OPCM era on), real
implementation re-installed and `initialize` called. Mechanisms by era: v1.0.0 `initializer`; v1.2.0 .. v1.8.0 manual
StorageSetter + `initializer` (superchain-ops tasks, Safe → Multicall3 → ProxyAdmin); U13 / U14 OPCM `upgrade` without
re-initialisation; U16 / U16a `reinitializer(initVersion())` through dedicated `upgrade(...)` functions (2, then 3); U17 /
U18 plain upgrades; U19 on: OPCM StorageSetter byte reset + `initialize` (one extra StorageSetter round-trip for the
OZ-v5 slot check from U20).

### 7.2 Uninitialised windows

* Every `Upgraded(StorageSetter)` and the following `Initialized` are in **one transaction** (census: 236 `Upgraded` /
  `Initialized` logs in 22 blocks; the only multi-transaction blocks are proxy creations).
* Proxy creation: the Bedrock proxies existed from 17365800-04 with an admin and **no implementation** until 17422444 /
  17423158 (8 days; every call reverts in `Proxy._doProxyCall`). DGF / ASR-old / DelayedWETH g1 (19884569 → 19884570),
  ProtocolVersions (18367300 → 18367320) and SuperchainConfig (three txs in block 19064589) likewise had no
  implementation before the `upgradeToAndCall` that initialised them.
* Bedrock L1StandardBridge / L1ERC721Bridge / factory implementations had no initializer at all.
* During the FP upgrade tx the Safe called `portal.setAddress(bytes32(50), address(0))` **directly** (StorageSetter has no
  access control) — still inside the same `execTransaction`.

### 7.3 Implementations

Historical implementations still deployed, slot 0 at 26433900: portal 1.6.0 / 2.4.0 / 2.5.0 / 3.10.0 = 1 (initialised
in the constructor), 3.13.0+ = `0xff`; SystemConfig 1.3.0 .. 2.3.0 = 1, later `0xff`; L1CDM OVM implementations hold the
OVM value, 1.4.0 / 2.2.0 / 2.3.0 = `1 << 160`, later `0xff << 160`; L1StandardBridge 2.0.0 / 2.1.0 = 1, later `0xff`;
SuperchainConfig 1.1.0 = 1; ProtocolVersions 1.0.0 = 3; DGF 1.0.0, ASR 1.0.0, DelayedWETH 1.0.0 / 1.1.0 = 1; the rest
`0xff`. Slot 0 = 0 only on implementations that have **no** initializer (L1StandardBridge 1.1.0 `0xbfb731cd…`,
L1ERC721Bridge 1.0.0 `0x3268ed09…`, factory 1.1.0 / 1.8.0, both StorageSetters, the `PortalSender` `0x0a893d95…`).
None of them holds value, has `delegatecall` or `selfdestruct`. The one-off `forceDeposit` implementation `0x6d971b07…`
reverts with custom error `0x4ba8b214` when called directly. **No implementation is initialisable by anyone in a way
that matters.**

All 49 executions of the ProxyAdminOwner Safe: 14 OP Mainnet upgrade txs; 20063224 (SuperchainConfig guardian);
20270847, 20723924, 21580854, 22432368 (DGF game implementations; 20723924 also ASR-old → 2.0.0); 26309074
(`forceDeposit`); and 29 executions that changed no storage of any tracked OP Mainnet contract (other chains'
ProxyAdmins and non-proxy targets). `op-proxyadminowner-safe-exec-classified.json`.

## 8. Ink, Soneium, Unichain

| | Ink (57073) | Soneium (1868) | Unichain (130) |
|---|---|---|---|
| Portal first implementation | **3.10.0 `0xe2f826…`** at 21344310 (2024-12-06) | **3.10.0** at 21314185 (2024-12-02) | **3.10.0** at 21116362 (2024-11-04) |
| SystemConfig first implementation | 2.2.0 | 2.2.0 (2.3.0 at 21945575) | 2.2.0 (2.3.0 at 22081789) |
| L1CDM / L1StandardBridge first implementation | 2.3.0 / 2.1.0 | 2.3.0 / 2.1.0 | 2.3.0 / 2.1.0 |
| U13 / U14 | 22182531 / 22339996 | 22182531 / 22339996 | 22254924 / 22342667 |
| U16 / U16a | 22990599 / 23491328 | 22990670 / 23491328 | 22990722 / 23492571 |
| U17 / U18 | 23877377 / 24421512 | 23877377 / 24478557 | 23878509 / 24427874 |
| U19 | 25397811 | 25397811 | 25475307 |
| U20 / U21 | 26048619 / 26430859 | same | same |
| Portal `_initialized` | 1 → 2 → 3 | 1 → 2 → 3 | 1 → 2 → 3 |
| Live ASR / DelayedWETH proxy created | U16 / U19 | U16 / U19 | U16 / U19 |

Consequences: no portal v1, no L2OutputOracle, no slot-52 mapping, no OVM spacer values, no v1.1.0 layout; L1CDM slot 0
never held an AddressManager address; L1StandardBridge slot 0 never held a messenger address. The three chains differ from
OP Mainnet by *absence* of legacy state, and from each other only by upgrade blocks (Ink skipped the Holocene
SystemConfig 2.3.0: its slot 106 is still 0, i.e. `eip1559Denominator = eip1559Elasticity = 0`; its slot 102 and slot
104 scalars are nevertheless consistent, as on the other three). Game-level differences are F5's.

## 9. Stress of closures C1 and C2

`test/poc/F4/F4_LegacyStorage.t.sol`, fork of L1 at 26433900 (`l1`), deployed bytecode, no privileged prank:

| Test | What it adds to PASS A's `test_legacySpacerSlotsAreDeadStorage` | Result |
|---|---|---|
| `test_legacyProvenEntriesExistButAreUnreachable` | 24 **real** legacy entries (12 never finalized, 12 finalized) checked against the still-deployed L2OutputOracle, then every v9 entry point exercised under `vm.record()`; no read of slot 52 or of an entry | PASS |
| `test_poisonedPreV7Slots_realWithdrawalAndDepositAreUnchanged` | *semantic* poison instead of junk, in every slot that had another meaning before v7 **and in mapping entries**: portal `paused = 1`, legacy blacklist entry for the very game being used, legacy proof entry for the very withdrawal, `respectedGameType‖UpdatedAt = max`, `superRootsActive = 1`; L1CDM `libAddressManager`, Pausable `_paused = 1`, ReentrancyGuard `_status = 2`, `blockedMessages[hash] = relayedMessages[hash] = 1`, slots 249-253; bridge / 721 / factory spacers; SuperchainConfig hashed `paused = 1`, `guardian = attacker`; six deprecated SystemConfig hashed slots; lockbox / ASR / DelayedWETH spacers. Then a **real** 119.6 ETH withdrawal proven under v8 (portal → lockbox → `L1CDM.relayMessage` → `L1StandardBridge.finalizeBridgeETH`) and a 1 ETH `depositETH` are run on a clean and on a poisoned snapshot | PASS: 60 getters, lockbox delta, recipient gain, `finalizedWithdrawals`, `successfulMessages`, `failedMessages`, deposit and nonce identical |
| `test_fabricatedLegacyProofGivesNothing` | a mature legacy proof written for a fresh withdrawal (mock-only, to locate a reader) | PASS: `Unproven` from both finalizers and from `deleteProvenWithdrawal` |

C1 (wrong / stale / uninitialised state after an upgrade): holds for every historical upgrade of OP Mainnet at
transaction granularity (§7), with the three oddities recorded as primitives (U20 ASR unit change PRIM-F4-01, U19 batch inbox PRIM-F4-02,
hidden `forceDeposit` cycle PRIM-F4-03). C2 (legacy slot reinterpreted by v9): holds for the full pre-v7 history, including mapping entries; the reopen
condition "a pre-v7 field is found at a reused slot" is met only by slots that the upgrade transaction rewrote
atomically (rows n, r, ac of §3.0) or that live on a different proxy (rows z, ab).

## 10. Files

| Path | Content |
|---|---|
| `evidence/F4-storage-lineage.json` | layouts per tag, lineage per slot, implementation histories (48 proxies), slot timelines, events |
| `evidence/F4/hist-*.json`, `slots-*.json`, `events-*.json` | per proxy: signature changes, slot timelines, logs at each change block |
| `evidence/F4/trace/<block>-{diff,calls}.json` | prestate diff + filtered call list of the 14 upgrade txs and of 26309074 |
| `evidence/F4/op-portal-withdrawal-events.jsonl` | full proven / finalized census (77,340 logs) |
| `evidence/F4/op-withdrawal-entries-by-era.json`, `op-legacy-proven-unfinalized.json`, `op-finalized-success-false.json` | real entries through the v9 layout; the 3,281 legacy never-finalized hashes; the 4 failed finalizations |
| `evidence/F4/op-l1cdm-relay-events-*.jsonl`, `op-l1cdm-message-entries-by-era.json` | sampled messenger events and entries |
| `evidence/F4/op-all-proxies-upgraded-initialized.jsonl` | every `Upgraded` / `Initialized` of 15 OP Mainnet proxies |
| `evidence/F4/op-proxyadminowner-safe-exec*.json*` | the 49 Safe executions, classified by traced storage delta |
| `evidence/F4/op-superchainconfig-pause-events.jsonl`, `op-portal-admin-events.jsonl`, `op-asr-admin-events.jsonl` | pause / blacklist / respected-type events |
| `scripts/F4_*.py`, `scripts/F4_init_sigs.txt` | reproduction |
| `test/poc/F4/` | fork tests (harness `/home/user/u21-work/f4`; re-run in this session: 3 / 3 PASS) |
| `primitives/PRIM-F4-01..03.md`, `rejected/REJ-F4-01..06.md`, `workers/F4-report.md` | primitives, killed ideas, report |

Reproduce: `python3 -I scripts/F4_impl_history.py <name> <proxy> <start>`; `F4_slot_history.py`; `F4_init_events.py`;
`F4_trace_upgrades.py evidence/F4/trace <label>=<tx>`; `F4_scan_logs.py`; `F4_legacy_proofs.py 12`;
`cd /home/user/u21-work/f4 && forge test --match-path test/F4_LegacyStorage.t.sol -j 1 -vv`.
