# W0 report — PASS A primitive ingest and semantic ancestry (Track A, blind)

Worker W0, 2026-11-17. No audit material was read (no `docs/security-reviews`, no `audits-txt`, no `audit/`,
no web search). Nothing under `optimism-u21-novel-hunt/` was modified. No transaction was sent to any network;
all chain access was `eth_call` / `eth_getLogs` / `cast` reads and one in-process `forge test` fork.

## 1. Files written (all under `optimism-bedrock-u21-megahunt/`)

| File | Content |
|---|---|
| `PRIMITIVES.json` | 93 records `A-001..A-093` for the 112 PASS A primitives (19 lane/Codex-mirror pairs merged, PRIM-3301..3303 dropped) |
| `PRIMITIVE-COMPATIBILITY-MATRIX.csv` | 30 x 30: the 28 P0/P1 records plus PRIM-W0-01/02; 88 non-empty cells, each naming the shared state |
| `DEAD-ENDS-NO-REDO.md` | the 180 PASS A rejections in 15 families, killing fact, evidence path, state dependence, reopen edge |
| `SEMANTIC-LINEAGE.md` / `.json` | 23 lineage entries, v1.0.0 -> v9.0.0, with the 13 requested fields each; semver table per tag; on-chain anchors |
| `primitives/PRIM-W0-01.md`, `PRIM-W0-02.md` | two new primitives from the lineage |
| `rejected/REJ-W0-01.md` | one new dead end (legacy blocked messages) |
| `PRE_U16_BACKTRACE_QUEUE.md` | appended section "Rows appended by W0": BW0-01..BW0-11 + status update (existing rows untouched) |
| `test/W0/W0Lineage.t.sol` | fork test on deployed bytecode (2 tests, pass; harness `/home/user/u21-work/W0`) |
| `evidence/W0/` | `dgf-implementation-set-logs-19800000-26433900.json`, `dgf-implementation-registry-binding.json`, `l1cdm-messageblocked-scan-12686000-17430000.json`, `W0Lineage-forge-output.txt`, `matrix-state-vocabulary.json`, `src2id.json` |
| `scripts/W0-lin.py`, `W0-scan-*.py`, `W0-analyze-*.py`, `scripts/W0-gen/` | lineage tracer, log scanners, generators of every deliverable |

## 2. Method

- **Lineage.** `scripts/W0-lin.py <Contract[,Alt]> <function>` extracts a function per tag (comments stripped,
  formatting normalised to statements) and diffs it tag to tag; v2.1.0, v2.2.0, v3.0.1 are compared with their
  parents (all traced functions identical). Storage layouts were diffed from `snapshots/storageLayout/*.json`
  (available from v1.2.0). A release appears in a lineage entry only when the normalised body changed.
- **Registry.** Every primitive file was read; each record points at an ancestor anchor (first tag + file:line,
  tag of the current form), the v9 consumer, the persistent object, historical branches, the create-at-N /
  consume-at-M pair PASS A did not exercise, and one experiment or a closure id. `AUDIT_COVERAGE_ALREADY_DONE`
  is the literal `TRACK-B` everywhere.
- **Dedupe.** Only lane-vs-mirror duplicates are merged (two `source_files`). The same mechanism found by
  unrelated lanes stays as separate records linked by `same_mechanism_as`; the canonical record carries the
  priority and the experiment, the others are P2.
- **Matrix.** Each P0/P1 primitive was given a `creates` and a `consumes` set over 21 named states
  (`evidence/W0/matrix-state-vocabulary.json`); cell(row, col) = row.creates ∩ col.consumes. No named state, no cell.

## 3. Facts locked by W0

| Fact | Evidence |
|---|---|
| OP Mainnet, Ink, Unichain and Soneium each have THREE AnchorStateRegistry generations behind ONE DisputeGameFactory (OP: 0x18DAc71c… -> 0x1c68ECfb… -> 0x23B2C629…); the v2.0.0 and v4.0.0 registries (and the v4.0.0 DelayedWETH) are not storage-compatible with their predecessors and were shipped as new proxies; the old proxies are still deployed | layout diff v1.8.0/v2.0.0/v4.0.0; v4.0.0 `src/L1/OPContractsManager.sol:675,717,780,819`; `evidence/W0/dgf-implementation-registry-binding.json`; `cast` @26433900 |
| U16 on OP Mainnet = L1 block 22,990,599 (registry `retirementTimestamp` 1753379243); game 9827 is bound to 0x1c68ECfb…, game 9828 to 0x23B2C629… | `cast find-block`, `cast call` |
| Complete implementation history of the four factories (250 logs, blocks 19.8M..26.4339M): only game types 0, 1, 8, 5, 9 ever had an implementation; every live type was re-pointed in the same transaction as each registry switch; first `gameArgs` use is the FaultDisputeGame 2.2.0 registration (v6 layout) on every chain | `evidence/W0/dgf-implementation-set-logs-…json` |
| OP Mainnet respected-implementation boundaries by game index: 9828 FDG 1.7.0, 12805 FDG 1.8.0, 14633 FDG 2.2.0, 17905 type 8 FDG 2.4.2, 20095 type 9 SFDG 0.8.0; no retirement since U16 | bisection with `cast` |
| The current registry returns `isGameRegistered == true` for a game bound to the previous registry (binding check added v4.0.0, removed v7.0.0) | `test/W0/W0Lineage.t.sol::test_W0_01_…` |
| The superseded registry 0x1c68ECfb… (v2.0.0 code) returns the LIVE respected type, treats current games as claim-valid, and lets any caller move its `anchorGame` with a current type-8 game | `test/W0/W0Lineage.t.sol::test_W0_02_…` |
| No legacy message was ever blocked on the OP Mainnet L1CDM before Bedrock (0 `MessageBlocked`/`MessageAllowed` logs, blocks 12,686,000..17,430,000, positive control passes) | `evidence/W0/l1cdm-messageblocked-scan-…json` |
| `finalizedWithdrawals` (slot 51), `hashWithdrawal`, the V0/V1 message hashes, the messenger replay/re-entrancy branch, the Merkle trie logic and `donateETH` are textually unchanged since v1.0.0 | lineage tracer |
| Every removed field of the in-place-upgraded proxies (portal, L1CDM, bridges, SystemConfig, factory) became a same-size spacer from v1.2.0 to v9.0.0; no slot was reused | layout diff |

## 4. Registry summary

- 93 records: P0 8, P1 20, P2 65. Status: benign 85, open-lead 6, rejected-by-lane 2.
- Families: proof-lifecycle 14, messenger-replay 12, dispute-game 10, gas-budget 10, pause 9, identity-binding 8,
  custody 8, migration 7, upgrade-engine 7, storage-init 3, tooling 3, bond-credit 2.
- P0 (could change a PASS A closure): A-001 (claim-valid old-type games, four implementation generations),
  A-002 (prestate generations), A-011 (U16 sweep merged pre-lockbox surplus into the lockbox),
  A-012 (forced failedMessages / ETH parked in the L1CDM across releases), A-014 (authorisation history of every
  lockbox any OPCM generation could deploy), A-021 (deleteProvenWithdrawal on pre-U16 proof cells),
  A-041 (version-0 legacy withdrawals vs pre-Bedrock success records), A-068 (portal-finalized /
  messenger-unaware withdrawals created Bedrock..v8).
- Closed by W0 during ingest: A-044 (registry binding), A-061 (gameArgs layout shift), A-085 (omitted game types).

## 5. Lineage headlines (details and file:line in SEMANTIC-LINEAGE.md)

1. `proveWithdrawalTransaction` kept its selector while its second argument changed from an L2OutputOracle index
   to a factory game index (v1.4.0); proofs moved from slot 52 (one per hash) to slot 57 (per submitter).
2. Withdrawal validity moved from portal storage (v1.4.0..v3.x) to the registry (v4.0.0); the old portal blacklist
   was not copied — it was subsumed by the new registry retiring everything older than its initialisation.
3. Retirement was decoupled twice: `setRespectedGameType` stopped retiring at v2.0.0; `AnchorStateRegistry.initialize`
   stopped retiring at v6.0.0. Result on OP Mainnet: two type switches and four implementation generations since
   U16 with one retirement timestamp.
4. `isGameRegistered`: factory only (v2.0.0) -> factory AND registry binding (v4.0.0) -> factory only (v7.0.0).
5. Pause source: portal bool (v1.0.0) -> global SuperchainConfig bool (v1.2.0) -> per-identifier timestamps with
   expiry, resolved by SystemConfig (v4.0.0; identifier = lockbox or portal from v4.1.0) -> ETHLockbox (v9).
   `SuperchainConfig.upgrade()` at v4.0.0 zeroes the legacy paused slot.
6. Bad-target rule: prove-time `target != portal` (v1.0.0..v3.x) -> `{portal, current lockbox}` at prove and
   finalize (v4.0.0, unchanged since); the L1CDM list `{L1CDM, portal}` is unchanged since v1.0.0.
7. Custody: portal balance (v1.0.0) -> mandatory lockbox + `migrateLiquidity()` sweep inside the v4.0.0 OPCM
   upgrade -> optional lockbox (v4.1.0) -> mandatory again (v9). `donateETH` became the lockbox unlock callback.
8. Depositor aliasing: `msg.sender != tx.origin` -> `EOA.isSenderEOA()` with the EIP-7702 designator (v2.0.0).
9. `DisputeGameFactory.create` clone layout changed at v1.4.0, v5.0.0 and v6.0.0 (+4 byte shift); deterministic
   clones and check-before-deploy from v7.0.0.
10. `SuperPermissionedDisputeGame.initialize()`: real game (v6/v7) -> born `DEFENDER_WINS` (v8.0.0).

## 6. New primitives and dead end

- **PRIM-W0-01** — registry binding of games is gone since v7.0.0; with three registry generations per factory the
  retirement timestamp is the only separator. Mechanism reproduced on deployed bytecode; historical precondition
  absent on all four chains (implementation history). Latent for future registry replacements.
- **PRIM-W0-02** — superseded registries are live mirrors (blacklist, retirement, respected type, finality delay via
  the portal getters, no pause) and their anchor is permissionlessly movable with current games. Reproduced.
  Consumers today: pre-U16 game clones only (bond-only).
- **REJ-W0-01** — blocked legacy messages replayable under Bedrock: killed, no message was ever blocked.

No candidate. Nothing here is a vulnerability claim.

## 7. Limits

- Upgrade numbers are asserted only where the code names them (v4.0.0 "U16", v4.1.0 "U16a"); the release DAG is F2's.
- v1.0.0 and v1.1.0 have no storage-layout snapshot; v1.1.0/v1.2.0/v1.3.0 are not a linear code history.
- The per-game exhaustive read of `anchorStateRegistry()` (11.5k games on OP) was abandoned as too slow through the
  shared fork; the implementation-history scan answers the same question for all games at once.
- Legacy registries of Ink / Unichain / Soneium were identified from logs but their predicates were not read.
- `eth_getLogs` old ranges were served by the archive proxy with 10k-block windows and zero errors; completeness
  rests on that proxy (one positive control per scan family).
- L2-side lineage (predeploy generations) was traced in source only, not on chain.
- Matrix cells are structural (shared named state); none was executed.

## 8. Edges that most deserve the next wave

1. **A-068 / BW0-03** — withdrawals finalized in the portal under <= v8 while the L1CDM recorded nothing: scan
   `WithdrawalFinalized(success=false)` from Bedrock to block 25.9M on all four portals and price the stranded value.
2. **A-021 + A-001** — real pre-U16 proof cells and the ~10.2k claim-valid type-0/8 games of four implementation
   generations: push old cells through v9 `checkWithdrawal`/`deleteProvenWithdrawal`, and recompute the claim-valid
   roots per prestate generation (with B05).
3. **A-011 / A-014** — custody and authorisation history: portal balance at U16-1 == lockbox balance at U16 per
   chain, liability reconciliation since Bedrock, and every lockbox address any OPCM generation could have created.
