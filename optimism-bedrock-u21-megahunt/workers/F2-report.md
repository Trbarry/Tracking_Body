# F2 report — Release-DAG archaeologist (Track A, blind)

**Model**: the first part of this work ran on Mythos 5.2 and stopped on a quota error (HTTP 429). The resume ran on **Opus 5.5 (`claude-opus-5-5`)** under the exception the user approved on 2026-11-17, which is recorded in `/home/user/Tracking_Body/CLAUDE.md` line 6 and lasts until the quota resets on 2026-11-22 00:00 UTC.
**Blindness**: I read only the index-table columns of `docs/security-reviews/README.md` (Date, Reviewer, Focus and Scope, Commit, Subsequent Release). I did not open any report, finding or contest, and did not run any web search for findings.
**Chain access**: passive reads only, through `http://127.0.0.1:7545` (L1 archive) and `:7546` (OP Mainnet L2). No transactions were sent.

## Files

| File | What |
|---|---|
| `RELEASE-DAG.md`, `RELEASE-DAG.json` | The deliverable: 32 nodes (30 on the OP Mainnet line + chain-local GENESIS and CHAIN-FP-ENABLE), 37 edges, 12 lineage edges, per-chain paths, implementation timelines, game/prestate tables, invalidation boundaries |
| `scripts/F2_dag_data.py` | Hand-curated node data (written by the previous instance; on resume I corrected its audit-index note) |
| `scripts/F2_build_dag.py` | New renderer. It joins the node data with the evidence files and adds the facts read on resume |
| `evidence/F2-game-impls-unichain.json` | New. 22 Unichain game registrations (the previous instance never produced it) |
| `evidence/F2-audit-index.json` | New. 50 index rows (title, commit, release) |
| `evidence/F2-op-contracts-tags.txt` | New. `git ls-remote --tags origin 'op-contracts/*'` (112 refs) |
| `evidence/F2-impl-history-*`, `F2-call-history-*`, `F2-game-impls-{op-mainnet,ink,soneium}`, `F2-superchain-ops-tasks`, logs, semver | From the previous instance. All histories are complete up to L1 block 26433900; I checked every target and none recorded an error |

## Facts locked on resume (all read on chain)

- **U16 ETH custody move**: each portal's whole ETH balance moved to its new lockbox, in the same block on each chain. Readings with `cast balance`, block before and the execution block (OP/Ink at 22990598/22990599; Soneium and Unichain one block before their execution block):
  - OP Mainnet: 236,752.243071584240518225 ETH, block 22990599.
  - Ink: 6,020.610509607786200086 ETH, block 22990599.
  - Soneium: 8,877.050938229307093797 ETH, block 22990670.
  - Unichain: 133,613.248268096507106891 ETH, block 22990722.
- **At U21 (block 26430859)** all four portals hold 0. The lockboxes hold:

  | Lockbox | ETH |
  |---|---|
  | OP Mainnet | 182,420.5112 |
  | Ink | 23,088.7583 |
  | Soneium | 2,195.5602 |
  | Unichain | 18,222.3470 |

- **Unichain's genesis permissioned game** (`0xb2872ec9`, version 1.3.0) carried a placeholder prestate `0x00000000deaddead…` from 2024-11-04 to 2025-01-17.
- **Chain-specific prestates.** Ink used `0x03c50b9f…` ("1.3.1-ink") and Unichain used `0x0336751a…` ("1.4.0-unichain-mainnet"). Both names come from `standard-prestates.toml` (lines 292 and 264).
- **Ink and Unichain switched to permissionless proofs (respected game type 1 → 0)** through transactions from the Foundation Operations Safe `0x9BA6e03D`:

  | Chain | Tx | Date |
  |---|---|---|
  | Ink | `0x20fdc1a4…` | 2025-01-22 |
  | Unichain | `0xc378e442…` | 2025-01-23 |

  The superchain-ops README for `ink-002` still says "READY TO SIGN".
- **Ink skipped U11 (Holocene)'s SystemConfig re-initialisation.** From U13 (block 22182531) until block 22924007 (2025-07-15), Ink's SystemConfig storage held `basefeeScalar = blobbasefeeScalar = 0` while `scalar()` was 801949 in the version-0 encoding. The owner then set 4424 / 810831, 9 days before U16.
- **SystemConfig owner changes with no superchain-ops task**:
  - Ink: changed at block 25573527 (tx `0x22893758…`).
  - Unichain: changed to the Foundation Upgrade Safe at block 26286838 (tx `0x5453bf98…`).
  - Soneium: still owned by its operator (`0x509182eC`) at block 26433900.

## Create-at-N / transform-at-N+1 / consume-at-N+2 edges

These are in RELEASE-DAG section 8.

| Edge | Object | Create | Transform | Consume |
|---|---|---|---|---|
| L01 | L1 messenger/bridge proxy slot 0, OVM era | OVM | U4 slot rewrite | U16 reinitializer(2), then a StorageSetter reset at every OPCM upgrade |
| L02 | Portal slot 53 | U1 `paused` | PAUSE-2024-02 / U4 packing | U16+ spacer |
| L03 | `respectedGameTypeUpdatedAt` | U7 | INC / U10 / U13 | U16 ASR `retirementTimestamp` |
| L04 | `wasRespectedGameTypeWhenCreated` | U13 | U19 respected type 0 → 8 | U20/U21 portals proving old output-root games |
| L05 | ASR anchor | U16 | U20 unit change: block number → super-root timestamp | U21 ASR 4.0.0 |
| L06 | ETH custody | portal | U16 lockbox | U16a feature flag / U21 lockbox 2.0.0 |
| L07 | DelayedWETH (bond custody) | U7 | generations 2–5 | U19 shared proxy / U21 |
| L08 | SystemConfig `batchInbox` | U6 | U19 | U20 |
| L09 | SystemConfig fee scalars | U5 | U11 (skipped on Ink) | U14/U17 |
| L10 | DGF `gameArgs` | U18 | U19 / proposer rotations | U20/U21 |
| L11 | Pause authority | U4 | U8 / U13 | U16 / U21 |
| L12 | OP Mainnet L2 bridge predeploys | U1 | U15 `withdrawalsRoot` | U19 Karst (first code change since Bedrock) |

## Where the conceptual lineage was wrong

Full list in RELEASE-DAG section 10.

**Missing nodes**:
- the v1.1.0 tag (ProtocolVersions only);
- Security Council Phase 0, which predates U4;
- the 2024-02 pause rehearsal;
- the 2024-08 permissioned fallback;
- chain genesis and the permissionless-proof switch on Ink and Unichain;
- the Unichain ProxyAdmin transfer.

**Wrong as stated**:
- U12 has no OP Mainnet L1 transaction; only Ink executed a U12 step.
- The deputy pause arrived 5 weeks after U13.
- U15a was skipped on Soneium.
- Ink never ran U11's SystemConfig step.
- "U18a" is Arena-Z only.
- Only "19b" exists as a proposal.
- Unichain upgraded separately from OP Mainnet until U20.

**Tag, commit and execution order disagree**: U4's v1.2.0 commit is newer than U6's v1.3.0 commit. The maintenance tags v2.1.0, v2.2.0 and v3.0.1 are dated after v3.0.0 and v4.0.0. The v6.0.0 tag was created after execution, and v8.0.0-rc.1 points at the same commit as v7.0.0-rc.1.

**Audit index**: the table does have a Commit column; an earlier F2 draft said otherwise. The audited commit matches the shipped tag commit only for MCP L1 and U16. U13, U16a, U17, U18, U19, U20 and U21 were audited at release-candidate or untagged commits.

## Could not be established

- Changes that revert inside one 20k-block sampling window (log scans cover only the portal pause and SuperchainConfig events).
- The block of the 2024-02 unpause.
- Diffs between audited and released commits (the clone is shallow).
- L2 predeploy history for Ink, Soneium and Unichain (no local L2 archive).
- Exact slot layouts (F4's job).
- I did not re-fetch the governance forum text.

## Edges for the next wave

1. **L04 + L05**: type-0 and type-8 output-root games created between U16 and U20, read by ASR 4.0.0 and portal 6.1.0 after the anchor changed units (block number → timestamp). The only third-party DEFENDER_WINS game found, idx 19206, is type 8.
2. **L01**: OVM-era L1CrossDomainMessenger storage and legacy (v0) message hashes under L1CDM 2.13.0, together with the StorageSetter reset done at every OPCM upgrade.
3. **L07**: residual bond credit in orphaned DelayedWETH generations 1 to 5. Bonds are carved out of Critical/High, so this ranks below the other two.
