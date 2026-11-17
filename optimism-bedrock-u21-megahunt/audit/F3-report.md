# F3 report — audit-corpus miner (Track B)

Date 2026-11-17. Everything F3 wrote is under `optimism-bedrock-u21-megahunt/audit/`. No transaction was sent;
chain access was limited to passive `cast call` reads on the local fork `:8545` (L1 block 26433900).

## 1. Deliverables

| File | Content |
|---|---|
| `AUDIT-FINDINGS.json` | 348 finding records (21 fields + page reference) from 39 reports, per-report metadata (commit, scope, exclusions, pages, items not recorded), vocabulary, counts for 11 non-mandatory reports, list of sources not retrieved |
| `AUDIT-COVERAGE-MATRIX.csv` | 44 components x 21 release columns; cell = reports (with audited commit) that reviewed the component at that release |
| `AUDIT-EDGE-GRAPH.md` | 19 release edges with auditor, commit, scope, exclusions; 15 transitive paths (T1–T15) that no single report covers; ranked gap list |
| `KNOWN-FINDINGS-BLACKLIST.md` | 9 root-cause families with exploit condition and fix; 18 items live by design at v9; note on unvalidated public submissions |
| `FIX-CLOSURE-MATRIX.md` | 35 fixes x 8 closure questions with file:line evidence at later tags; top 15 mutation targets |
| `F3-report.md` | this file |
| `_work/` | fragment scripts that generate the JSON and CSV (`build.py`, `matrix.py`, `0*.py`) |

Status of the 348 records: fixed 99, acknowledged 180, won't fix 3, disputed 17, not stated 49.

## 2. Corpus ingested

Text source `/home/user/ethereum-optimism/audits-txt/*.txt` (pdftotext -layout), page numbers taken from form feeds.
Severity key in the third column: C critical, H high, M medium, L low, I informational, U undetermined,
fam = submission family not in a final report, ctx/int = advisory or internal finding described by a fix review.

| Report | Pages | Findings recorded | Not recorded individually |
|---|---|---|---|
| 2022_05-Bedrock_Contracts-Zeppelin | 19 | 15 (C:1, H:2, L:6, M:6) | Low L-01 and Notes N-01..N-10 (10) not recorded |
| 2022_08-Bedrock_GoLang-SigmaPrime | 29 | 11 (C:1, H:2, L:1, M:7) | Informational 3 (OPB-12..OPB-14) not recorded |
| 2022_09-Bedrock_and_Periphery-Zeppelin | 29 | 14 (I:1, L:5, M:8) | L:8 not recorded individually (L-01,02,03,06,07,09,10,11,13), N:11 |
| 2022_11-Invariant_Testing-TrailOfBits | 35 | 1 (U:1) | 1 finding; invariant tables p11-24 not recorded |
| 2022_12-DepositTransaction-RuntimeVerification | 13 | 0 (—) | formal verification report: 0 severity-rated findings; 2 minor spec deviations in the metered modifier (p11) and gas notes |
| 2023_01-Bedrock-Sherlock-contest | external repo (README.md 3814 lines) | 18 (H:3, L:2, M:13) | 25 "S" (specification) issues: 2 recorded (S-7, S-24), 23 counted only |
| 2023_01-Bedrock_Updates-TrailOfBits | 26 | 1 (H:1) | single finding |
| 2023_03-Bedrock-Sherlock-fix-review | external repo (README.md) | 9 (H:3, M:6) | all 9 final issues recorded |
| 2023_12-SuperchainConfigUpgrade-Trust | 23 | 13 (H:1, I:1, L:8, M:3) | 1 additional recommendation not recorded |
| 2024_02-Kontrol-pausability-RuntimeVerification | external README (raw.githubusercontent.com, commit 876e16ad04968f0bb641eb76f98eb77e7e1a3e16) | 0 (—) | verification artefact, no findings |
| 2024_02-MCP_L1-Cantina | 11 | 5 (I:1, L:4) | Low not recorded: 3.1.3 (FeeVault gaps, L2), 3.1.5 (version numbers), 3.1.6 (tests); Informational: 7 (3.2.7 recorded for relevance) |
| 2024_03-FaultProofs-Sherlock-contest | 60 | 20 (M:4, fam:16) | 4 final Mediums recorded; 16 of 31 excluded submission families recorded as fam-*; 15 families by title only (see ext/2024-02-optimism-2024-judging) |
| 2024_08-Fault-Proofs-MIPS-Cantina | 11 | 13 (C:1, H:1, L:3, M:8) | Gas 1, Info 19 |
| 2024_08-Fault-Proofs-No-MIPS-Spearbit | 24 | 10 (L:6, M:4) | Gas 1, Info 12 |
| 2024_10-Cannon-FGETFD-3DocSecurity | md | 0 (—) | 0 findings; 1 false positive (challenger docker embeds) |
| 2024_12-DPM-MiloTruck | 11 | 3 (L:3) | Info 2 |
| 2024_12-DPM-RadiantLabs | 8 | 1 (L:1) | Low 3.1.2 (key rotation doc), Info 2 |
| 2025_01-IRI-OffbeatLabs | 9 | 4 (I:3, L:1) | — |
| 2025_01-MT-Cannon-Base | 7 | 1 (M:1) | Info 6 |
| 2025_01-MT-Cannon-Spearbit | 11 | 3 (H:1, L:1, M:1) | Gas 5, Info 8 |
| 2025_02-Upgrade13-Spearbit | 16 | 10 (I:2, L:6, M:2) | Info not recorded: 5.3.1-5.3.9 (5.3.3 FDG unlock timing change noted in blacklist) |
| 2025_03-Interop-Contracts-Spearbit | 21 | 6 (H:2, L:1, M:3) | Low not recorded: 5.3.1 (sendETH invalid chain id), 5.3.3 (addDependency chain id), 5.3.4 (isDeposit bypass); Gas 3; Info 8 |
| 2025_03-Interop-Portal-Wonderland | 8 | 5 (I:2, L:3) | Info I-0,I-2,I-3 not recorded |
| 2025_04-Interop-Portal-Cantina-contest | 38 | 26 (I:19, L:7) | all 26 recorded |
| 2025_04-op-program-blob-handling-aleph_v | 2 | 1 (ctx:1) | notes only |
| 2025_05-Cannon-Go-Updates-Coinbase | 3 | 0 (—) | 0 findings |
| 2025_05-Interop-Portal-Spearbit | 13 | 8 (I:3, L:5) | Gas 1; Info not recorded: 5.3.2,5.3.3,5.3.4,5.3.5,5.3.8 |
| 2025_05-Upgrade16-Spearbit | 14 | 8 (I:3, L:5) | same 14 findings as 2025_05-Interop-Portal-Spearbit; 8 cross-referenced |
| 2025_06-Cannon-3DOC | 9 | 2 (L:1, M:1) | Info 1 |
| 2025_06-Cannon-fix-review-Spearbit | 6 | 2 (int:2) | closing remark only |
| 2025_07-VerifyOPCM-Spearbit | 6 | 3 (I:1, L:1, M:1) | all 3 recorded |
| 2025_09-U16a-Spearbit | 12 | 7 (I:4, L:3) | Info not recorded: 5.2.2, 5.2.4, 5.2.7 |
| 2025_10-U17-Spearbit | 8 | 3 (I:3) | 3 info all recorded |
| 2025_11-Custom-Gas-Token-Spearbit | 14 | 3 (I:1, L:2) | Low not recorded: 3.1.1 (Go predeploy mirrors), 3.1.3, 3.1.5, 3.1.6 (L2 CGT predeploys); Gas 2; Info 8 others |
| 2026_01-U18-Cantina | 9 | 6 (I:2, L:4) | Gas 1 |
| 2026_03-Kona-Cantina | 50 | 37 (C:2, H:1, L:32, M:2) | Info 18 |
| 2026_05-U19-Cantina | 13 | 15 (I:2, L:10, M:3) | Info 3.3.3 not recorded |
| 2026_06-Interop-L2-Contracts-Cantina | 18 | 6 (I:2, L:4) | Info 23 not recorded (L2 interop) |
| 2026_06-OPCMv2-Cantina | 13 | 15 (I:8, L:6, M:1) | Info not recorded: 3.3.1,3.3.3,3.3.4,3.3.7,3.3.8,3.3.9,3.3.11 |
| 2026_08-U20-Cantina | 14 | 12 (I:6, L:6) | Info not recorded: 3.2.6, 3.2.8 |
| 2026_11-U21-Cantina | 26 | 31 (I:12, L:19) | Info not recorded: 3.2.4 (stale docs, fixed), 3.2.6, 3.2.15 |

Non-mandatory reports (counts only):

| Report | Counts |
|---|---|
| 2020_10-Rollup-TrailOfBits | OVM v1 (pre-Bedrock). 20 findings: High 9, Medium 4, Low 5, Informational 2 (table p14-15). Not recorded individually (code retired at Bedrock). Root-cause echoes kept in blacklist: AddressManager owner can backdoor any contract (#2), re-entrancy in message passing (#6), Lib_MerkleUtils.verify accepts empty proofs (#8). |
| 2020_11-Dapphub-ECDSA_Wallet | OVM ECDSA wallet. Table lists B/G/I/Q items: High 9, Low 3 among bugs (+ improvements). Not recorded (retired). |
| 2021_03-OVM_and_Rollup-OpenZeppelin | OVM v2. Headings: Critical 4, High 5 (summary text says 4), Medium 5, Low 20, Notes 32. Not recorded (retired). |
| 2021_03-SafetyChecker-ConsenSysDiligence | OVM SafetyChecker review; no severity table extracted. Not recorded (retired). |
| 2022_05-OpNode-TrailOfBits | op-node fix review, commits 05136a32b9828b595dde47f767218dec53f19aa4 / a7423f3a3167d20e93b6d60e648fbe9fec17f380: High 2, Medium 1, Informational 2. Go node only; not recorded individually. |
| 2022_10-Drippie-Spearbit | Drippie.sol: Medium 1 (multiple drip calls per block), Low 11, Gas 5, Info 17. Periphery; not recorded. |
| 2024_05_SafeLivenessExtensions-Cantina | Safe LivenessGuard/LivenessModule contest: Medium 6 (listed in report), Low 93, Info 44 (only Mediums printed). Security Council Safe tooling; not recorded. |
| 2025_10-Rev-Sharing-Spearbit | FeeSplitter/FeeVaults: Low 10 (7 fixed), Gas 3, Info 29. L2 fee vaults (carved out); not recorded. |
| 2025_11-Rev-Sharing-Contracts-Upgrader | Info 2 (fixed). |
| 2025_11-SaferSafes-Spearbit | SaferSafes/TimelockGuard: Medium 1 (same signatures usable for scheduleTransaction and execTransaction), Low 2, Info 5. Safe tooling; not recorded. |
| 2026_03-PolicyEngineStaking-Cantina | PolicyEngineStaking: Low 1 (fixed), Info 9. Unrelated contract; not recorded. |

### Unreadable or externally hosted material

- `2022_05-Bedrock_Contracts-Zeppelin`: the PDF text layer is a substitution cipher (three fonts, three offsets).
  It was decoded programmatically (offsets +31 / +29 / +25) for the body and identifiers; the audited commits
  (0c05488, e2da9e2, 8cbaf02) were read from the PDF page image (page 5). Headings remain garbled in the text
  file; all 26 issue titles were recovered from the table of contents.
- Sherlock Bedrock contest and fix review: not in the PDF set. Cloned `sherlock-audit/2023-01-optimism-judging`
  and `2023-03-optimism-judging` into `/home/user/ethereum-optimism/ext/`; the final issue lists are in each
  `README.md`. Fix commits are not stated there; fixes were recorded "as observed in the v1.0.0 tree".
- Sherlock fault-proof contest: the PDF is in the corpus (`2024_05-FaultProofs-Sherlock.txt`, 60 pages, 4 Mediums).
  `sherlock-audit/2024-02-optimism-2024-judging` was cloned for the 31 submission families excluded from the
  final report; 11 family files were read, the rest by title only.
- Kontrol pausability verification: README fetched from raw.githubusercontent.com at commit 876e16ad; the proof
  files were listed by function name only.
- Not retrieved: Sherlock contest web pages; the three Sherlock source snapshots; the Spearbit portfolio copies of
  the May and July 2025 reports (the in-repository PDFs were used instead).
- Reports that print no per-finding status: Cantina MCP 2024-02, Wonderland 2025-03, most of the Cantina contest
  2025-04, Cantina U19 2026-05. Their records carry status "not stated".
- `2025_05-Upgrade16-Spearbit` and `2025_05-Interop-Portal-Spearbit` are the same engagement with the same 14
  findings at two commits; the U16 copies are marked as duplicates in the JSON.
- The kona repository is not available locally, so no kona fix could be checked against later code.

## 3. Root-cause vocabulary

- `ACCESS_CONTROL_MISSING` — a state-changing or value-releasing entrypoint lacks (or mis-resolves) its caller check
- `INPUT_VALIDATION_MISSING` — attacker- or operator-supplied value is not range/format/identity checked on-chain (includes validator-script gaps)
- `INVERTED_OR_WRONG_CONDITION` — a comparison, ordering or boolean predicate is wrong
- `REENTRANCY_STATE_CLOBBER` — re-entry (or nested finalize/relay) clobbers a sentinel such as l2Sender / xDomainMsgSender or uses it as a guard incorrectly
- `GAS_ACCOUNTING` — min-gas / 63-64 / reserve / base-gas computations that decide whether a non-replayable step records its outcome
- `REPLAY_OR_DOUBLE_SPEND` — one economic object can be proven/relayed/finalized more than once or re-armed
- `INITIALIZATION` — initializer / reinitializer / implementation-initialisation problems, including re-running initialize on live state
- `UPGRADE_STORAGE_LAYOUT` — slot layout, gaps, spacers, immutables<->storage moves
- `UPGRADE_SEQUENCING` — ordering, atomicity, skip paths and tooling (OPCM / scripts / validators) of an upgrade or migration
- `PAUSE_COVERAGE` — what the pause covers, which identifier/pointer decides it, and paths that escape or silently lift it
- `PROOF_VERIFICATION` — binding between a withdrawal proof, an output/super root, a chain id, a game and a registry
- `DISPUTE_GAME_LOGIC` — clock, bond, move/step/resolve mechanics inside a game
- `ANCHOR_STATE` — what the anchor is, who can set it and how it is (re)interpreted
- `GAME_TYPE_LIFECYCLE` — respected game type, retirement timestamp, blacklist and their cut-overs
- `VM_SEMANTICS` — on-chain MIPS/MIPS64 step vs spec vs off-chain Cannon divergence
- `PREIMAGE_ORACLE` — PreimageOracle key/part integrity
- `DERIVATION_CONSENSUS` — op-node / op-geth / kona derivation or execution divergence, including proof-program panics
- `DOS_RESOURCE` — griefing, unbounded work, liveness of nodes or of a function
- `ACCOUNTING_CONSERVATION` — ETH/token custody not matching liabilities, stranded or duplicated value
- `CROSS_DOMAIN_IDENTITY` — who the sender/creator is across domains or call layers (aliasing, tx.origin, msg.sender through factories)
- `TOKEN_SEMANTICS` — non-standard tokens, token-pair identity, mint/burn vs escrow branch
- `SIGNATURE_REPLAY` — signed-message domain separation
- `STALE_STATE_AFTER_MIGRATION` — an object created under release N keeps living and is read, mis-read or orphaned by release N+k
- `CONFIG_TRUST` — safety delegated to a privileged/off-chain input (deploy input, anchor, prestate, guardian, dependency set)
- `SPEC_MISMATCH` — code vs specification/documentation difference without a direct exploit

Severity mapping (`severity_current_mapping`) uses the three Immunefi tiers in `../SCOPE.md` (Critical / High /
Medium) plus `None`. It classifies the impact of the finding as reported; all of them are known issues.

## 4. Main results

1. **A contract-level fix was later removed.** The registry-binding check added after the 2025-04 contest
   (`isGameRegistered` requires the game's registry to be the caller's) exists at v4.0.0–v6.0.0 and is absent at
   v7.0.0–v9.0.0; a 2026 report records the removal as Informational and the v8 report re-adds the binding only in
   the off-chain validator. File:line evidence in `FIX-CLOSURE-MATRIX.md` row 1.
2. **Three other 2022–2025 fixes rest on conditions that later releases replaced**: the v1.0.0 re-prove gate
   (gone at v1.4.0), the "messenger never reverts for a portal relay" rule (pause revert at v1.2.0, portal revert at
   v9.0.0), and the single-function pause-pointer fix (identifier made flag-dependent at v4.1.0, lockbox-only at v9.0.0).
3. **The U21 report acknowledges all 19 of its Low findings without a fix.** Several PASS A open leads are
   restatements of them (gas ceiling of withdrawals, permanent portal authorizations in the lockbox, uncleared game
   types, L2 messenger constants lagging the L1 messenger, pause recorded under the retired portal identifier).
   They are listed in `KNOWN-FINDINGS-BLACKLIST.md` Part 2.
4. **Coverage holes**: no report for v1.1.0, v1.5.0 or the v2.1.0–v3.0.1 line; `ProxyAdmin`, `AddressManager` and
   `ResolvedDelegateProxy` in no scope list since 2022; `DisputeGameFactory` and the game implementations absent from
   the v8 and v9 file lists; kona reviewed at one commit with 34 of 37 Low+ items unfixed.
5. **Only one report (U16a) fork-tested an upgrade from more than one source version.** Later reports test from a
   fresh deployment of the previous release or not at all.
6. One chain fact collected to rank the first target: on OP Mainnet at block 26433900 the factory registers only game
   types 5 and 9, both bound to the portal's registry; the registry's retirement timestamp is 1753379243
   (2025-07-24) and its respected type is 9. Ink, Soneium and Unichain were not read.

## 5. Ranked gap list (detail in `AUDIT-EDGE-GRAPH.md` section 2 and `FIX-CLOSURE-MATRIX.md` section B)

| Rank | Path | Object | Why no report covers it |
|---|---|---|---|
| 1 | T1 + T2 | game <-> registry binding and the respected-type / retirement timeline | registry, factory arguments, game implementations, upgrade path and pre-existing games are never in one scope; the on-chain check was removed at v7 |
| 2 | T3 | proof records written under one portal/registry generation and read under a later one | every report reviews the record shape of its own release |
| 3 | T4 | in-flight messenger withdrawals and failed-message entries under the v9 revert rule and reserves | U21 covers new withdrawals; older objects are in no scope |
| 4 | T5 | pause identifier and its writers per release and per chain history | each report fixed or acknowledged one writer |
| 5 | T8 | games created under a proof-program or VM version that later received a soundness fix | VM reviews are PR-scoped; no report looks at live games across a prestate switch |
| 6 | T7 | the anchor a chain carried through the switch to super-root games | all anchor findings are "if the operator supplies X" |
| 7 | T6 + T14 | custody and upgrade behaviour for chains whose history differs from OP Mainnet | only U16a tested a second history |
| 8 | T10 + T13 | pointers and chain ids rewritten by initializers on every upgrade | idempotence reviewed per contract per release |
| 9 | T9, T11, T12, T15 | bond-escrow generations; config events vs three derivation implementations; AddressManager path; OVM-era objects | unreviewed since their introduction |

## 6. Limits

- Fix commits are recorded only where a report prints them; for the 2023 Sherlock issues the fix is what the
  v1.0.0 tree shows.
- "Not fixed at v9" statements were verified for seven items (listed in the JSON with the word VERIFIED); other
  acknowledged items were not re-checked line by line.
- Upgrade numbers before U13 and for the v3.x line are not established by the corpus; the matrix uses tags.
- The mapping of a report to a release column follows the README "Subsequent Release" column or, where empty, the
  first tag after the audited commit date; F2's DAG should replace it.
- Informational items were recorded individually when they touch portal, lockbox, registry, factory, games, OPCM or
  validators, and counted otherwise.

## 7. SANITISED — safe to share with the blind track

Structural hints only. No finding, fix, report name or severity is given here.

- The lineage "dispute game -> the registry that vouches for it -> the portal that consumes it" crosses
  v1.4.0, v2.0.0, v4.0.0, v4.1.0, v6.0.0, v7.0.0, v8.0.0 and v9.0.0, and no single review has all of registry,
  factory-stored game arguments, game implementations and upgrade path in scope. Reconstruct it per chain,
  including which registry each registered game type points to and when each chain last retired old games.
- The lineage of a withdrawal-proof record (Bedrock single record -> per-submitter record -> registry-validated
  record -> v9 deletion path) has no review covering a record created under one generation and consumed under a later one.
- The lineage "portal finalization <-> messenger outcome recording" changed character at v1.2.0 and again at v9.0.0;
  objects created before each change (failed messages, withdrawals initiated on L2 under older constants,
  OVM-era migrated withdrawals) are worth a dedicated pass.
- The pause identity has four generations (v1.0.0, v1.2.0, v4.0.0/v4.1.0, v9.0.0). Enumerate every writer of the
  pointer(s) that decide the identifier at each release, and every contract that reads pause through a different
  pointer chain.
- Releases with no review in the corpus: v1.1.0, v1.5.0, v2.1.0, v2.2.0, v3.0.0, v3.0.1.
- Components absent from every scope list after 2022: ProxyAdmin, AddressManager, ResolvedDelegateProxy.
  Components absent from the v8 and v9 scope lists: DisputeGameFactory, all game implementations, MIPS64,
  PreimageOracle, both L1 bridges, the ERC20 factory.
- Only one review exercised an upgrade from two different source versions. Chains whose history differs from
  OP Mainnet's (skipped releases, no lockbox until late, more than one registry generation) are the least covered.
- Initializers are re-run on every upgrade from v7.0.0 onward; which fields each initializer overwrites, and from
  which input, is a lineage of its own.
- Delays (proof maturity, game finality, bond withdrawal) are implementation constants, so each implementation
  swap re-evaluates objects created earlier.
- Proof-program and VM generations: games keep the program version they were created with; map which versions
  had live games across each version switch.
