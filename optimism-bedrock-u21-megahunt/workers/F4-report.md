# F4 report — Storage and initializer historian (Track A, blind)

Worker F4, 2026-11-17. Resumed from a previous instance that hit a model rate limit; nothing was restarted.
**Model: Opus 5.5 (`claude-opus-5-5`)**, not Mythos 5.2. The Mythos 5.2 quota was exhausted. The user told us to continue
on Opus 5.5 in their own words ("Continue avec opus 5.5", 11:59:46 UTC, seen in the session transcript), and
`/home/user/Tracking_Body/CLAUDE.md` now records that exception. No audit material was read.

## Deliverables

| File | Content |
|---|---|
| `STORAGE-ARCHAEOLOGY.md` | genealogy of the OP Mainnet proxies; every layout event v1.0.0..v9.0.0 and what happened to it on chain (§3.0); per-contract slot/offset/type/label lineage for 20 contracts (§3.1); every slot that was ever non-zero, with the block it was written / cleared and its v9 reader (§4); raw slot readers in v9 (§5); mapping archaeology (§6); initializer history (§7); Ink / Soneium / Unichain (§8); C1/C2 stress (§9) |
| `evidence/F4-storage-lineage.json`, `evidence/F4/*` | layouts, lineage, 48 implementation histories, slot timelines, 15 traced upgrade txs, event censuses |
| `test/poc/F4/F4_LegacyStorage.t.sol` (harness `/home/user/u21-work/f4`) | 3 fork tests @26433900 against deployed bytecode; re-run this session: 3/3 PASS (`-j 1`) |
| `primitives/PRIM-F4-01..03.md`, `rejected/REJ-F4-01..06.md` | below |

## Facts locked (re-checked on chain in this run)

- B01: **12,338** OP Mainnet withdrawal hashes were first proven in the L2OutputOracle era, and **3,281** of them were never finalized. Their legacy entries `{outputRoot,timestamp,l2OutputIndex}` are still at `keccak(hash,52)` (+1). No v9 path reads them. `deleteProvenWithdrawal` reverts `Unproven` before it calls `status()`. Every slot-57 entry holds a clone from the factory. Ink, Soneium and Unichain were **born on OptimismPortal2 3.10.0** (`0xe2f82632…`).
- B10 / B02 (storage side): `successfulMessages` 203, `xDomainMsgSender` 204, `msgNonce` 205 and `failedMessages` 206 have the same slots at every tag. 88/88 sampled relayed hashes from 2021 to 2026 read 1. The OVM `blockedMessages` / `relayedMessages` slots (201 / 202) are 0 for those hashes.
- B08: `_initialized` is at slot 0 offset 20 only on the L1CDM. Bedrock never re-initialised the L1CDM; its OVM value 1 lasted until U16. Every StorageSetter reset was atomic (one transaction). The previous instance found 236 `Upgraded`/`Initialized` logs and traced all 49 Safe executions; I re-ran the tests and re-read the key slots but did not re-trace those 49 executions. ProtocolVersions is the only proxy holding the v1.1.0 value 3.
- B07: the slots that held immutables-moved-to-storage were written once at MCP (19634866) and kept their meaning. The dead ones (portal 53/54/56/59, messenger 251, bridges 50) are unread.
- Every source-level layout hazard (the incompatible v1.1.0 orders, the ASR and DelayedWETH re-layouts, the DGF insertion) is avoided on chain in one of three ways: the hazardous code was never deployed, a new proxy was used instead, or the slot was rewritten atomically.

## Primitives

- PRIM-F4-01: U20 changed the unit of ASR slot 4 in place (L2 block number to timestamp) and did not bump the retirement timestamp. The two units meet in the permissionless `setAnchorState`. Closed on OP and Ink: no claim-valid output-root game is above the anchor (4 + 3 such games exist, all CHALLENGER_WINS), and no output-root game type is registered on any of the four chains.
- PRIM-F4-02: U19 (v7 OPCMv2) wrote the derived default batch inbox into SystemConfig on OP Mainnet and Unichain. It was wrong until U20. Past-only.
- PRIM-F4-03: at 26309074 the OP portal went through a hidden implementation cycle that ran `forceDeposit()` (an un-aliased L2 OP-token transfer to the Safe's alias). Privileged. Block samplers cannot see this kind of cycle.
- Not re-filed: the old-ASR mirror getters (= PRIM-W0-02).

## Candidates

None. No P0 primitive (a slot written under meaning X and now read under meaning Y) exists on the four chains.

## Limits

- The L1CDM `RelayedMessage` history was sampled (11 windows), not scanned in full.
- The L1StandardBridge and L1CDM were traced only from 2024-02-26 on.
- "Ever non-zero" means non-zero at a sampled block or recovered from events.
- Unichain and Soneium output-root games were not censused for PRIM-F4-01.

## Next-wave edges

1. Census of Unichain and Soneium output-root games against PRIM-F4-01.
2. Full L1CDM `RelayedMessage` / `FailedRelayedMessage` scan, 2021 to 2026 (B02/B10 entry level).
3. Any future OPCM re-init that recomputes a chain value (the PRIM-F4-02 pattern) or reuses slot 52/58/59 in a new portal layout.
