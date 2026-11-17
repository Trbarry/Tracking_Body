# CURRENT WORK INGEST — PASS A (recent cross-upgrade, U20 -> U21) is preserved, not restarted

Ingested 2026-11-17. Nothing in the prior workspace was deleted, moved or overwritten.

- Prior workspace (PASS A): `/home/user/Tracking_Body/optimism-u21-novel-hunt/` (all on branch `ccr-f1cfed3a-k2loia`).
- This workspace (PASS B/C/D): `/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/`.
- PASS A was scoped to `op-contracts/v8.0.0 -> v9.0.0` plus the exact mainnet N-1 -> N transition.
  It did NOT go back to U16/U16a; the historical lower bound it reached is v7.0.0 (storage layouts only).
  So PASS B starts at Bedrock and must cover v1.0.0 -> v7.0.0 in full, not only "pre-U16".

## 1. Facts locked by PASS A (each verified on chain or by fork test)

| Fact | Evidence |
|---|---|
| U21 executed on Ethereum mainnet: tx `0x024770b5…2a99`, block 26430859 (`0x1934d8b`), tx index 358, 2026-11-16 23:23:59 UTC. Safe `0x5a0Aae59…` -> Multicall3 delegatecall -> OPCM v9.0.3 `0x2d91e6F2…`. | `evidence/u21-upgrade-{tx,receipt}.json`, `U21_PROXY_IMPLEMENTATION_MAP.md` |
| One tx upgraded four chains: OP Mainnet (10), Ink (57073), Soneium (1868), Unichain (130). Base was not part of it. | receipt, lane 01 |
| Replaying the tx on a fork of N-1 reproduces block N on all 339 touched slots; 47 slots changed net (21 impl slots, 4 AddressManager entries, 4 OPCM slots, 12 new v9 pointers, 5 gameArgs words, Safe nonce). No ETH moved, no feature flag changed. | lanes 01, 02, 21, 22 (two models) |
| All four chains were ALREADY lockbox chains with empty portals before U21; pause identifier did not move; no pause active at N-1, N, 26433900. | lanes 02, 03, 06, 26 |
| 23 deployed contracts are byte-identical to the local v9 build (immutables masked). Seven "v9" implementations are the unchanged v8 deployments (both bridges, ERC20 factory, DGF, game impls, MIPS64, StorageSetter). | lanes 01, 02 |
| OP Mainnet: respectedGameType 9; gameImpls only for 5 and 9; old type-9 prestate `0x031ac6f1…` -> new `0x03e5a548…` (kona-client v1.9.0). | lane 01, 07 |
| L1 fork Amsterdam (EIP-8037) is NOT active; v9 already ships Amsterdam gas constants. | orchestrator, `eth_config` |
| Interop/Lagoon targeted 2026-12-10 (Sepolia pair) and 2027-01-11 (OP Mainnet + Unichain); `migrate` not executed. Real `OPContractsManagerV2.migrate` for OP+Unichain succeeds on a fork and pools 200,807.23 ETH. | `interop-prep.mdx`, lanes 07, 09 |
| Scope: Immunefi page read live (updated 2026-10-13). ETHLockbox, live ASR, live DelayedWETH, SuperchainConfig, OPCM, game impls are NOT listed; bonds carved out of Critical/High; unused features drop one severity level. | `SCOPE.md` |
| Full census of OP Mainnet games 9760..21388 (11,629 games): the only third-party DEFENDER_WINS + claim-valid game (idx 19206, type 8) has a root that matches the L2 block header. No third-party game is in progress. | `evidence/op-mainnet-games-census.txt` |

## 2. PASS A lanes (25 of 25 analysis lanes returned except one)

| Lane | Model | Topic | Result |
|---|---|---|---|
| 01 / 21 | Mythos / Codex | Upgrade executor | no candidate |
| 02 / 22 | Mythos / Codex | Storage and reinitialization | no candidate |
| 03 / 23 | Mythos / Codex | Portal / ETHLockbox conservation | no candidate |
| 04 / 24 | Mythos / Codex | Withdrawal finalization and replay | no candidate |
| 05 / 25 | Mythos / Codex | Proof lifecycle, `deleteProvenWithdrawal` | no candidate |
| 06 / 26 | Mythos / Codex | SystemConfig features, pause | no candidate |
| 07 / 27 | Mythos / Codex | ASR, dispute migration, super roots | no candidate |
| 08 / 28 | Mythos / Codex | Portal / messenger semantics | no candidate (Codex 28 final message blocked by the provider's cyber filter; report was written) |
| 09 / 29 | Mythos / Codex | Shared lockbox, multi-portal | no candidate |
| 10 / 30 | Mythos / Codex | Historical assumption archaeology (v7..v9 only) | no candidate |
| 11 / 31 | Mythos / Codex | Invariant and differential fuzzing | 31: no candidate; **11 still running at ingest time** |
| 12 / 32 | Mythos / Codex | Omitted-check analysis | no candidate |
| scope / 33 | Mythos / Codex | Scope snapshot | done |

Totals at ingest: 115 primitive files, 180 rejection files, 0 candidates, 0 Mythos escalations.
Composition phase: brief written (`COMPOSER_CONTEXT.md`), four composers were started and stopped
within a minute at the user's request; NOT run. Novelty phase (Phase B) not started.

## 3. Reusable assets

- Local forks behind a read-only failover RPC proxy (`:7545` L1 archive, `:7546` OP Mainnet archive):
  `:8545` L1 @ 26433900, `:8546` L1 @ 26430858 (N-1), `:8547` L1 @ 26430859 (N), `:9545` OP @ 159654093.
- Harness template `/home/user/u21-work/template`; real-withdrawal fixtures
  (`test/poc/lane04/proves.json`, `test/poc/lane05/`, `mirror/lane-31/`); replay of the real U21 tx in-process
  (`test/poc/lane01/`); real `migrate` on a fork (`test/poc/lane09/`, `test/poc/Lane07_Migration.t.sol`).
- Game census script `evidence/op-mainnet-games-scan.py`; output-root check from L2 block headers
  (post-Isthmus `header.withdrawalsRoot` = message-passer storage root).
- Sources: v7/v8/v9 worktrees under `/home/user/ethereum-optimism/op-v{7,8,9}.0.0`; historical contract trees
  v1.0.0..v6.0.0 being extracted to `/home/user/ethereum-optimism/hist/<version>/packages/contracts-bedrock/`.

## 4. Per-primitive ingest records

The seven fields required for every existing primitive (EARLIEST_SEMANTIC_ANCESTOR, CURRENT_U21_CONSUMER,
PERSISTENT_STATE_OR_OBJECT, HISTORICAL_BRANCHES, AUDIT_COVERAGE_ALREADY_DONE, UNREVIEWED_CROSS-UPGRADE_EDGE,
NEXT_EXPERIMENT) are produced by worker W0-INGEST into `PRIMITIVES.json` (one record per PASS A primitive),
because the first field needs the historical trees. AUDIT_COVERAGE_ALREADY_DONE is filled only after the
blind track freezes (Track B owns it).

## 5. Deviations from the megaprompt, stated once

- Workers run on Mythos 5.2, not Opus: the repository's `CLAUDE.md` requires Mythos 5.2 for every agent.
- Codex Daybreak mirrors were used in PASS A at the user's request; they are not launched for PASS B/C/D
  unless asked again.
