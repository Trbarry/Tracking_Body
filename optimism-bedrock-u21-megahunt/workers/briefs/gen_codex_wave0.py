#!/usr/bin/env python3
"""Generate Codex Daybreak mirror prompts for megahunt Wave 0 (mirrors of F2, F3, F4, F5, F6, W0)."""
import sys
from pathlib import Path

M = "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt"

PRE = """You are {cid}, an independent MIRROR of worker {orig} ("{title}") in an authorized security-research engagement.

ENGAGEMENT (honest and complete framing): bug-bounty research under the public Immunefi Optimism
programme on the OP Stack L1 contracts, auditing the cumulative state machine from Bedrock through
Upgrade 21 (op-contracts/v9.0.0, executed on Ethereum mainnet 2026-11-16). The purpose is defensive:
find a genuine vulnerability, prove it on a LOCAL fork, report it privately to the programme.
Nothing is ever exploited on a live network.

HARD RULES: never broadcast a transaction to any public network (no `cast send`, no
`forge script --broadcast`, no `eth_sendRawTransaction` except to a private anvil you started).
Public RPCs are for passive reads only. Do not send state-changing RPC to the shared local forks
(:8545, :8546, :8547, :9545) or proxies (:7545, :7546). No leaked keys, no privileged accounts.
Do not fabricate; an evidenced negative result is a valid deliverable.

FIRST read `{m}/MEGA_CONTEXT.md` in full, then `{m}/CURRENT_WORK_INGEST.md`, `{m}/CLOSURE-MAP.md`
and `{m}/PRE_U16_BACKTRACE_QUEUE.md`, and obey them (tracks, sources, chain access, conventions).

MIRROR RULES (override MEGA_CONTEXT output paths where they differ):
- You replicate worker {orig} INDEPENDENTLY. Do NOT read its outputs or any other worker's:
  stay out of `{m}/workers/` (except your own report), `{m}/primitives`, `{m}/rejected`,
  `{m}/candidates`, `{m}/chains`, `{m}/mirror` (except your own directory), `{m}/evidence`,
  and top-level deliverables other than the four files named above and `SCOPE.md`.{track_rule}
- Write ONLY: `{out}/...` (all artifacts; where the brief names a top-level deliverable, write your
  version under `{out}/` with the same file name), `{m}/workers/{cid}-report.md`{extra_out}.
- Working directory: `/home/user/u21-work/codex-{cid}`. Harness: `cp -r /home/user/u21-work/template ./h`.
  Never build or test inside `/home/user/ethereum-optimism/*` (read-only for you). Do NOT `git fetch`
  into `/home/user/ethereum-optimism/optimism`; if you need another repository or tag, shallow-clone
  it under `/home/user/ethereum-optimism/ext-codex/<name>` (one clone at a time), or read
  `/home/user/ethereum-optimism/ext/<name>` if another worker already cloned it (read-only).
- The machine has 4 cores shared by ~12 workers: forge with `-j 1`, modest fuzz runs.
- Every claim needs file:line at a pinned tag, a `cast` read at a pinned block, or a named test.

FINAL ANSWER: <= 450 words — files written, facts locked, primitives (ID + one line), any candidate
with an honest score, strongest negatives, limits, the 1-3 edges that deserve the next wave.

=========================== WORKER BRIEF ===========================
{brief}
"""

B = {}

B["F2"] = ("Release-DAG archaeologist", "A", """Deliver `RELEASE-DAG.md` and `RELEASE-DAG.json`: the exact release DAG from Bedrock (and targeted legacy-OVM migration residue) through Upgrade 21.

Conceptual lineage to VERIFY and correct (a research index, not ground truth): OVM residue -> U1 Bedrock -> U2 Canyon -> U3 Delta -> U4 SuperchainConfig/pause -> U5 Ecotone -> U6 multi-chain prep (immutables to storage) -> U7 fault proofs -> U8 Stage-1 authority/guardian/L2 ProxyAdmin ownership -> U9 Fjord -> U10 Granite -> U11 Holocene -> U12 L1 Pectra readiness -> U13 OPCM/incident response/deputy pause -> U14 Isthmus L1 contracts/MT-Cannon -> U15 Isthmus hardfork -> U15a maintenance -> U16 interop contracts stage 1 -> U16a maintenance -> U17 Jovian/Fusaka readiness -> U18 custom gas token v2/Kona proofs -> U18a -> U19/U19b Karst and contracts v7 -> U20 super-root games/OPCM v8 -> U21 interop readiness/OPCM v9.

Per node: proposal name/number; classification (maintenance/hardfork/contracts-only); exact tag and full commit (note maintenance tags dated out of order: v2.1.0, v2.2.0, v3.0.1); activation time or L1 execution tx for OP Mainnet (and Ink/Soneium/Unichain where different or skipped); changed contracts and clients; initializer/reinitializer calls; headline storage changes; proxy implementation changes; ownership/guardian/pause role changes; dispute-game and absolute-prestate changes; proofs/messages explicitly invalidated; chain set; audit report TITLES and audited commits from the index table in `docs/security-reviews/README.md` only (do not open reports); skipped or alternate paths.

Sources (blind-safe): monorepo docs at develop (`docs/public-docs/notices/` + `archive/`, hardfork and network-upgrade pages), governance proposals on gov.optimism.io (Discourse JSON `/search.json?q=`, `/t/<slug>/<id>.json`), docs.optimism.io, superchain-registry (standard versions/prestates, per-chain hardfork times), superchain-ops `tasks/eth/NNN-*` (executed tasks with expected state changes), `semver-lock.json` per tag in the hist trees, and ON-CHAIN ground truth: reconstruct the implementation history of the OP Mainnet proxies (Portal, SystemConfig, L1CDM via AddressManager entry `OVM_L1CrossDomainMessenger`, L1StandardBridge via the ChugSplash slot, DGF, ETHLockbox, ASR, SuperchainConfig) by binary search of the implementation slot and `version()` over block height through `http://127.0.0.1:7545`; identify each upgrade transaction. Do the same for the Portal and SystemConfig of Ink, Soneium and Unichain and save raw per-proxy (block, implementation, version) tables as `impl-history-<chain>.json`.

No automatic skipping: mark a release "cannot matter" only with a reason covering persistent state, surviving objects, interpretation of current state, authorizations/dependencies, proof validity, residue, upgrade path, branch-specific history, prestate/game type/root format, L1/L2 relationship. End with: transitive create-at-N / transform-at-N+1 / consume-at-N+2 edges you can name; where the conceptual lineage was wrong; what you could not establish.""")

B["F3"] = ("Audit-corpus miner", "B", """You are a TRACK B worker: you (and only Track B) may read audit findings. Corpus: 49 PDFs as text at `/home/user/ethereum-optimism/audits-txt/*.txt` (originals `/home/user/ethereum-optimism/optimism/docs/security-reviews/*.pdf`), the index `docs/security-reviews/README.md`, `2024_10-Cannon-FGETFD-3DocSecurity.md`. Externally hosted items (Sherlock Bedrock contest + fix review, Sherlock Fault Proofs contest, Kontrol pausability, Spearbit portfolio): fetch what is reachable (raw.githubusercontent.com works; github.com web/API returns 403 - shallow-clone judging repositories instead) and record what was not retrievable.

Deliver (in your mirror directory, which lives under `audit/` so the blind track cannot see it):
1. `AUDIT-FINDINGS.json`: one record per Medium+ finding and per Low touching portal, lockbox, messenger, bridges, SystemConfig, SuperchainConfig, ASR, DGF, games, DelayedWETH, ProxyAdmin, OPCM, validators, proof programs: report, finding_id, severity_original, severity_current_mapping (Immunefi levels in `SCOPE.md`), title, root_cause_class (controlled vocabulary you define), affected_contracts, affected_functions, required_state, attacker_model, impact, exact_commit, fix_commit, fix_strategy, tests_added, scope_assumptions, explicit_out_of_scope, residual_assumptions, sibling_paths_not_reviewed, later_releases_that_retouch_root_cause, status.
2. `AUDIT-COVERAGE-MATRIX.csv`: components x releases (tags in MEGA_CONTEXT), cell = reports that reviewed it at that release with audited commit.
3. `AUDIT-EDGE-GRAPH.md`: which release edges were audited, by whom, at which commit, with what scope and exclusions; then the TRANSITIVE paths (object created at N, transformed at N+1, consumed at N+2 or later) covered by no single report's scope - the primary research gap. Name the object, the releases, and why no scope statement includes the full path.
4. `KNOWN-FINDINGS-BLACKLIST.md`: known root causes by family, with the exact exploit condition and the fix; plus acknowledged / won't-fix items that remain live by design.
5. `FIX-CLOSURE-MATRIX.md`: per Medium+/important-Low fix: root cause or instance fixed; inverse direction; sibling contracts; direct and wrapped entrypoints; pre-existing objects tested; skipped-upgrade histories tested; later reintroduction under a new abstraction; later cleanup removing the condition that made the fix safe - check against the code at later tags (hist trees, op-v7/8/9) with file:line. Rank the top 15 fixes whose safety condition may have been removed or bypassed later.
Record what reports say with page references; never invent a finding, commit or fix. Keep your FINAL ANSWER free of finding specifics beyond counts and structure.""")

B["F4"] = ("Storage and initializer historian", "A", """PASS A already did v7 -> v8 -> v9 layouts and the mainnet N-1 -> N slot delta (`/home/user/Tracking_Body/optimism-u21-novel-hunt/U21_STORAGE_LAYOUT_DIFF.md`, `lanes/LANE-02-report.md` - you may read these two PASS A files). Extend backwards; deliver `STORAGE-ARCHAEOLOGY.md` + `storage-lineage.json`.

1. For each upgradeable L1 contract with live state on OP Mainnet (OptimismPortal v1 and OptimismPortal2, legacy L2OutputOracle, SystemConfig, L1CrossDomainMessenger behind ResolvedDelegateProxy, L1StandardBridge behind L1ChugSplashProxy, L1ERC721Bridge, OptimismMintableERC20Factory, SuperchainConfig, ProtocolVersions, DisputeGameFactory, AnchorStateRegistry old and current, DelayedWETH all generations, ETHLockbox, AddressManager, ProxyAdmin) build the field-by-field layout at EVERY tag v1.0.0..v9.0.0 where it exists (`.storage-layout` / `snapshots/storageLayout` AND the inheritance chain by hand). Per-contract lineage table: slot, offset, type, label per release; mark renames, retypes, deletions to spacers, gap consumption, packed-neighbour changes, inheritance reorders, immutable-to-storage moves, initializer-version changes (slot AND offset of the `_initialized` byte).
2. Read the REAL history of the OP Mainnet proxies through `http://127.0.0.1:7545`: for each slot (first ~80, plus EIP-1967, ChugSplash and ResolvedDelegateProxy special slots) the value just before and after each implementation change (find change blocks by binary search on the implementation slot). Record every slot EVER non-zero, when written, when cleared, and how v9 reads it now. A slot written under meaning X at release N, never cleared, now occupied by a v9 field or packed neighbour with meaning Y is a P0 primitive; so is a `spacer_*` whose value v9, an OPCM, a validator or a migrator still reads (grep v9 `src/L1/opcm`, the StandardValidator, StorageSetter flows and scripts for raw slot access).
3. Mapping archaeology: layout position and key/value shape at every release of portal `provenWithdrawals` (legacy `{outputRoot,timestamp,l2OutputIndex}` keyed by hash vs later `[hash][submitter]` `{disputeGameProxy,timestamp}`), `finalizedWithdrawals`, `proofSubmitters`, blacklist, respected type; messenger `successfulMessages`, `failedMessages`, legacy relayed/sent mappings, `xDomainMsgSender`, `msgNonce`; bridge `deposits`. Sample REAL entries from each era (chunked `eth_getLogs` <=10k blocks; report coverage honestly) and read them through today's layout at block 26433900. Answer: do legacy-format `provenWithdrawals` entries still exist in live storage, at which slot, is that slot reachable by any v9 path (including `deleteProvenWithdrawal`, which calls `status()` on the stored address), and what about Ink/Soneium/Unichain (which portal version were they born with)?
4. Initializer history per proxy: `_initialized` after every upgrade, the mechanism used (StorageSetter zeroing, `reinitializer(n)`, `initVersion`), any moment a proxy sat uninitialised and whether within one transaction; any implementation contract (current or historical, still deployed) initialisable by anyone in a way that matters.
5. Stress PASS A closures C1/C2: a pre-v7 non-zero slot not covered by PASS A's junk-overwrite test gets a fork test.""")

B["F5"] = ("Chain-history differential mapper", "A", """Thesis: the SAME v9 implementation runs over DIFFERENT storage, custody, game, pause, feature and ownership histories on OP Mainnet (10), Ink (57073), Soneium (1868), Unichain (130). Every security-relevant behavioural divergence caused by history is a primitive candidate.

Deliver `chains/<CHAIN>/{HISTORY.md,DEPLOYMENT.json,STATE-U21.json,UPGRADE-PATH.json}` for OP, INK, SONEIUM, UNICHAIN (under your mirror directory) and `CHAIN-HISTORY-DIFFERENTIAL.md` answering: can two chains on the same current implementation behave differently because their historical states differ?

Per chain, from chain state (`http://127.0.0.1:7545`, pinned forks; you may read the PASS A artifacts `/home/user/Tracking_Body/optimism-u21-novel-hunt/{U21_PROXY_IMPLEMENTATION_MAP.md,PRE_UPGRADE_STATE.json,POST_UPGRADE_STATE.json}`), the superchain-registry and superchain-ops task history: deployment block/date of each proxy and the contract versions it was BORN with (which historical objects can exist at all); every actual upgrade (implementation-slot history by binary search), skipped upgrades, manual vs OPCM, `lastUsedOPCM` history; ProxyAdmin, owner Safe and owner history, SystemConfig owner, guardian, SuperchainConfig used; custody over time (portal balance at each upgrade block, lockbox creation, when liquidity moved, ETH left in portal / L1CDM / bridge, current balances); pause identifier history and historical pauses (SuperchainConfig events; chunk logs, report coverage); every DisputeGameFactory, AnchorStateRegistry and DelayedWETH proxy the chain has EVER used incl. legacy/orphaned ones and the ETH they hold, game types ever registered, respected-type history, retirement timestamp history, blacklist entries, anchor history, absolute prestate per type over time; a game census for Ink, Unichain and Soneium (the PASS A script `/home/user/Tracking_Body/optimism-u21-novel-hunt/evidence/op-mainnet-games-scan.py` is parameterisable: Multicall3 at a pinned block through the proxy, batches of 20) flagging every claim-valid or in-progress game NOT created by the chain's usual proposer, with output roots verified from the L2 block header where post-Isthmus (`keccak(0x00..00 ++ stateRoot ++ header.withdrawalsRoot ++ blockHash)`; public L2 RPCs, passive reads - name them); custom gas token status, feature flags, interop-set role, chain-specific non-standard parameters (why and since when Soneium respects type 5); legacy slots non-zero on one chain and zero on another.

Then for each divergence: the v9 code path that reads the divergent state, behaviour on chain X vs Y, whether an unprivileged actor reaches it. Where it looks security-relevant, write a fork test running the SAME permissionless call sequence against two chains' real state at block 26433900 and record the different outcomes. State coverage limits.""")

B["F6"] = ("Historical harness engineer", "A", """Build reusable infrastructure for later waves; correctness and documentation over breadth. You may read and reuse these PASS A files: `/home/user/Tracking_Body/optimism-u21-novel-hunt/test/poc/{README.md,U21Fixtures.sol,lane01/,lane09/,Lane07_Migration.t.sol,lane04/proves.json}` and `evidence/withdrawal-fixtures*.json`.

Deliver one self-contained Foundry project under your mirror directory (`test/`, `foundry.toml`, forge-std symlink, `README.md` with exact commands) containing:
1. `HistoricalFork.sol`: named fork points for OP Mainnet L1 - the block before and after EVERY historical implementation change of OptimismPortal, SystemConfig, L1CrossDomainMessenger, L1StandardBridge, DisputeGameFactory, AnchorStateRegistry, ETHLockbox (derive by binary search of the EIP-1967 slot / AddressManager entry / ChugSplash slot through `http://127.0.0.1:7545`; save `op-upgrade-blocks.json`). Forks via `vm.createSelectFork("http://127.0.0.1:7545", block)`.
2. `UpgradeReplay.sol`: given an upgrade tx hash (or raw to/data/from) replay the official upgrade on a fork of the block before it and assert the implementation slots equal the real post-state. Ready-made replays for as many historical OP Mainnet upgrades as you can identify (at least the last five: v5, v6, v7, v8, v9), each verified against real post-upgrade slots.
3. `InFlightObjects.sol`: create real objects on a historical fork through protocol actions only - a deposit; a proven withdrawal (replay a real `proveWithdrawalTransaction` calldata at its block; for older eras find real prove transactions from `WithdrawalProven` logs in <=10k-block chunks and decode the calldata into era fixtures); a failed messenger message (real `FailedRelayedMessage` events and their replay calldata); a dispute game in progress. Document which eras you could populate.
4. `CarryThrough.t.sol`: (a) a withdrawal proven at least two releases before U21 (or proven on a historical fork from real calldata), carried through each official upgrade replay up to U21, then finalized under v9 - record the outcome per stage; (b) same for a failed messenger message replayed after the upgrades; (c) a differential runner executing one permissionless call on two forks (two blocks, or two chains at one block) and diffing success/revert selector, events, balance deltas - table for five representative calls.
5. `MultiChain.sol`: handles for the four chains' L1 contracts so one test body runs against OP, Ink, Soneium, Unichain.
Run forge with `-j 1`, at most one private anvil, no leaked fork snapshots in loops. A dual L1/L2 devstack is out of reach here - say so. Report per piece: what is verified (test names, pass counts), what is partial, and a three-line usage recipe.""")

B["W0"] = ("PASS A primitive ingest and semantic ancestry", "A", """PASS A produced 115+ primitive files and 180+ rejections under `/home/user/Tracking_Body/optimism-u21-novel-hunt/{primitives,rejected}/` (you may read those two directories and `lanes/` there), analysed only against v8 -> v9. Ingest them and trace each to its EARLIEST SEMANTIC ANCESTOR with the historical trees.

Deliver (under your mirror directory):
1. `PRIMITIVES.json`: one record per PASS A primitive (dedupe exact Mythos/Codex duplicates; drop PRIM-3301..3303): id `A-nnn`, source_files, title, family (custody, proof-lifecycle, messenger-replay, pause, storage-init, upgrade-engine, identity-binding, dispute-game, bond-credit, gas-budget, migration, tooling), EARLIEST_SEMANTIC_ANCESTOR (first release where the function/field/behaviour existed in recognisably the same form, file:line, and the release where it took its current form), CURRENT_U21_CONSUMER (file:line at v9), PERSISTENT_STATE_OR_OBJECT, HISTORICAL_BRANCHES, AUDIT_COVERAGE_ALREADY_DONE ("TRACK-B"), UNREVIEWED_CROSS-UPGRADE_EDGE (blind judgement: which create-at-N / consume-at-M pair PASS A never exercised), NEXT_EXPERIMENT (or "closed: <closure id>"), priority P0/P1/P2, pass_a_status.
2. `PRIMITIVE-COMPATIBILITY-MATRIX.csv` for P0/P1 records: a cell is non-empty only when the row primitive CREATES a state the column primitive CONSUMES; write the shared state in the cell.
3. `DEAD-ENDS-NO-REDO.md`: PASS A rejections condensed into families with the single killing fact and evidence path; mark those whose killing fact depends on CURRENT state only (reopenable by a historical pass).
4. `SEMANTIC-LINEAGE.md` + `.json`: release-by-release ancestry of the security-critical surface: OptimismPortal/OptimismPortal2 (deposit, prove, finalize incl. ExternalProof, checkWithdrawal, bad-target lists, `l2Sender`, donateETH, pause source, guardian source, blacklist/respected-type/retirement handling and where it lived, migrateLiquidity, migrateToSuperRoots/migrateToSharedDisputeGame, deleteProvenWithdrawal); `CrossDomainMessenger.relayMessage` (hash versions, replay branch, reserved-gas constants, re-entrancy branch, unsafe-target list, pause source); SafeCall; StandardBridge finalize paths; SystemConfig (initialize arguments, address storage scheme, features, paused, superchainConfig); SuperchainConfig pause generations; AnchorStateRegistry (per-type anchors -> single anchor game, `isGame*` predicates, guardian, retirement); DisputeGameFactory (create, UUID inputs, gameArgs); DelayedWETH; ETHLockbox; ProxyAdmin/ProxyAdminOwnedBase. Per function/field: FIRST_INTRODUCED, ORIGINAL_MEANING, ORIGINAL_INVARIANT, ALL_SEMANTIC_CHANGES (one line per release with file:line), ALL_CALL_ORDER_CHANGES, ALL_REVERT_SEMANTIC_CHANGES, ALL_IDENTITY_SOURCE_CHANGES, ALL_AUTHORIZATION_CHANGES, ALL_PAUSE_SOURCE_CHANGES, OBJECTS_CREATED_UNDER_OLD_MEANING, MIGRATION_OR_INVALIDATION_EVENTS, CURRENT_CONSUMERS, UNREVIEWED_TRANSITIVE_PATHS. Prioritise semantic changes where selector and storage type did NOT change. Use `diff`/`grep` across the hist trees (v1.0.0 keeps sources under `contracts/`; v2.1.0, v2.2.0, v3.0.1 are maintenance branches dated after v3.0.0/v4.0.0).
Add new primitives only where a concrete semantic change meets a persistent object that can still exist on mainnet.""")


def main():
    out = Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)
    for orig, (title, track, brief) in B.items():
        cid = "C" + orig
        if track == "B":
            outdir = f"{M}/audit/mirror-{cid}"
            track_rule = ("\n- You are TRACK B: you may read the audit corpus. Everything you write stays under"
                          f" `{M}/audit/` so the blind track cannot see finding details; your report goes to"
                          f" `{M}/audit/mirror-{cid}/{cid}-report.md` instead of `workers/`.")
            extra = ""
        else:
            outdir = f"{M}/mirror/{cid}"
            track_rule = ("\n- You are TRACK A (blind): do NOT read audit findings (`docs/security-reviews/*` beyond the README"
                          " index table, `/home/user/ethereum-optimism/audits-txt/*`, `" + M + "/audit/*`) and do not"
                          " search the web for findings, contests or disclosures.")
            extra = (f", `{M}/primitives/PRIM-{cid}-nn.md`, `{M}/rejected/REJ-{cid}-nn.md`,"
                     f" `{M}/candidates/CAND-{cid}-nn.md` (candidate only after your own falsification)")
        text = PRE.format(cid=cid, orig=orig, title=title, m=M, out=outdir, track_rule=track_rule,
                          extra_out=extra, brief=brief)
        (out / f"{cid}.prompt.md").write_text(text)
        (out / f"{cid}.outdir").write_text(outdir)
        print(cid, len(text))

if __name__ == "__main__":
    main()
