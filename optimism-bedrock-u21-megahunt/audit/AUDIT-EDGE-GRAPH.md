# AUDIT-EDGE-GRAPH — which release edges were audited, and which transitive paths no report covers

Worker F3 (Track B). Source: the 49-report corpus + three Sherlock judging repositories + Kontrol README
(see `AUDIT-FINDINGS.json` -> `meta.reports` for commit, scope and exclusions of every report).
Code facts are cited as `tag path:line` (trees under `/home/user/ethereum-optimism/hist/<ver>/packages/contracts-bedrock/`
and `/home/user/ethereum-optimism/op-v{7,8,9}.0.0/packages/contracts-bedrock/`).
Upgrade numbers are used only where a report states them (U13=v2.0.0, U16=v4.0.0, U16a=v4.1.0, U17=v5.0.0,
U18=v6.0.0, U19=v7.0.0, U20=v8.0.0, U21=v9.0.0; "U15" = the release before U16, i.e. the v3.x line). F2 owns the
authoritative numbering; `RELEASE-DAG.md` did not exist when this file was written.

## 1. Release edges (N -> N+1): audited or not

"Edge audit" = the report's scope statement is the DIFF or the UPGRADE between two releases. "State audit" =
the report reviews the code at N+1 (a snapshot) without claiming the transition. Most reports are state audits.

| Edge | Reports | Audited commit | Kind | Stated scope | Stated exclusions / limits |
|---|---|---|---|---|---|
| OVM -> v1.0.0 (Bedrock migration) | Sherlock Bedrock contest (2023-01), Sherlock fix review (2023-03) | 3f4b3c32, 9b9f78c6 | state + migration tooling | contracts-bedrock, op-node, op-geth, op-chain-ops migration | privileged roles trusted; LES unsupported |
| (pre-v1.0.0 development) | Zeppelin 2022-05, SigmaPrime 2022-08, Zeppelin 2022-09, ToB 2022-11, RV 2022-12, ToB 2023-01 | 0c05488/e2da9e2/8cbaf02, b708721, 93d3bd41, b31d35b6, n/s, 1bfe79f2/ee96ff85/991120f6 | state | bridge, portal, L2OO, messenger, SystemConfig, two-step withdrawals | Zeppelin 2022-05: rewrite not exhaustively reviewed; ToB 2022-11: no concurrent deposit/withdrawal testing; RV: metered modifier excluded; ToB 2023-01: late commits "not evaluated in the context of the larger system" |
| v1.0.0 -> v1.1.0 | none | — | — | — | — |
| v1.1.0 -> v1.2.0 (SuperchainConfig) | Trust 2023-12; Kontrol pausability 2024-02 | d1651bb2 (mitigation 81b56fee); 876e16ad | **edge** (Trust: "all changes ... since the Sherlock contest commit") + property proof | 8 files: SuperchainConfig, L1CDM, L1ERC721Bridge, L1StandardBridge, OptimismPortal, CrossDomainMessenger, ERC721Bridge, StandardBridge; upgrade procedure side effects | SystemConfig, L2OO, factory, ProxyAdmin, AddressManager not in the list. Kontrol proves only "reverts when paused" for prove/finalize/relay with proofs of <= 10 nodes |
| v1.2.0 -> v1.3.0 (MCP L1: immutables -> storage) | Cantina MCP 2024-02 | e6ef3a90 | **edge** incl. `op-chain-ops/upgrades/l1.go` | 7 L1 contracts + upgrade script | no fix status printed; SuperchainConfig not re-reviewed |
| v1.3.0 -> v1.4.0 (fault proofs: OptimismPortal2, DGF, ASR, DelayedWETH, FDG, MIPS) | Sherlock FP contest 2024-03; Cantina MIPS 2024-08 | 5137f3b7 (develop); 71b93116 | state | safeguards (portal2, factory, ASR, WETH) under the premise "the game is buggy"; MIPS.sol | **game/MIPS/oracle root causes OUT OF SCOPE unless the air-gap is bypassed**; the L2OO-portal -> OptimismPortal2 state transition (existing `provenWithdrawals`) is in no scope |
| v1.4.0 -> v1.5.0 | none | — | — | — | — |
| v1.5.0 -> v1.6.0 | Spearbit No-MIPS 2024-08 | 1f708179 | state | `src/dispute/*`, PreimageOracle | OptimismPortal2 not in `src/dispute`; 0 fixes at report time |
| v1.6.0 -> v1.8.0 | 3DOC FGETFD 2024-10 | 52d0e60c (PR 12050) | PR | one syscall | everything else |
| v1.8.0 -> v2.0.0 (U13: OPCM upgrade(), incident-response changes, MT-Cannon) | Offbeat IRI 2025-01; Spearbit U13 2025-02; Spearbit + Base MT-Cannon 2025-01; DPM x2 2024-12 | 984bae91 + ce2ce43; 7d6d1543; cc2715c3; b8c011f1; 2f17e6b6 | IRI = **edge (two diffs)**; others state | portal2/ASR/FDG/WETH diffs; OPCM, SystemConfig, ASR, FDG, portal2, DGF; MIPS64; DeputyPauseModule | no statement on games/proofs created under v1.x; MT-Cannon reports assume a correct compiler and op-program |
| v2.0.0 -> v2.1.0 / v2.2.0 / v3.0.0 / v3.0.1 | **none** | — | — | — | whole v2.1–v3.0.1 line unaudited in the corpus |
| v3.x -> v4.0.0 (U16: ETHLockbox, super roots, identifier pause, ReinitializableBase) | Wonderland 2025-03; Cantina contest 2025-04; Spearbit interop-portal + U16 2025-05; VerifyOPCM 2025-07; Cannon Go/fix/3DOC 2025-05/06; aleph_v blob 2025-04 | 9df1fc15; e4b921c9; 7cd84fed; 54c19f6a; 731280c6; 4c68444b; ffe3d5fe/7f7b9abb; 689111fc; 08d81d98 | state (U16: "OPCM only the changes for Upgrade 16") | lockbox, portal2, ASR, SystemConfig, SuperchainConfig, OPCM, super games, DPM | contest: SuperFaultDisputeGame out of scope; U16 list omits FaultDisputeGame/PermissionedDisputeGame, factory ERC20, ProxyAdmin, AddressManager; most contest items carry no response |
| v4.0.0 -> v4.1.0 (U16a: lockbox behind a feature flag, super roots moved to PortalInterop) | Spearbit U16a 2025-09 (2 days) | 47580169 | **edge, fork-tested from two sources (U15 and U16) + fresh deploy** | MIPS64*, L1CDM, bridges, portal2, SystemConfig, OPCM | lockbox, ASR, DGF, games, WETH not in the file list; interop path "did not occur in the test run" |
| v4.1.0 -> v5.0.0 (U17: V2 dispute games / gameArgs behind a dev flag) | Spearbit U17 2025-10 | aeed7033 + PR 17998 | edge, fork-tested from "a freshly deployed U16" only | L1CDM, bridges, OPCM, portal2, SuperchainConfig, SystemConfig, MIPS64, DGF, FDG, PDG, ERC20 factory | ASR, lockbox, WETH not listed; U16a and U15 sources not tested |
| v5.0.0 -> v6.0.0 (U18: gameArgs default, ZK game, CGT v2, fee split) | Spearbit CGT 2025-11; Cantina U18 2026-01 | 1f888ede; 87d406db | state | ASR, DGF, LibGameArgs, V2 games, super games, ZK, OPCM, validator, portal2, SystemConfig, L2 fee/CGT | lockbox, L1CDM, bridges, WETH, MIPS64 not listed; **all 7 U18 findings acknowledged, 0 fixed** |
| v6.0.0 -> v7.0.0 (U19: OPCMv2, migrator, validators) | Cantina OPCMv2 (Feb 2026); Cantina Kona (Jan–Feb 2026); Cantina U19 2026-05 | a00b3972; kona 86910c91; 7cbcb58f | state | OPCMv2 family + VerifyOPCM; kona client; U19 release | migrator "not production-ready"; several OPCMv2 "fixes" are documentation; kona: 34 of 37 Low+ unfixed; U19 prints no responses |
| v7.0.0 -> v8.0.0 (U20: super-root games on by default, validator hardening) | Cantina U20 2026-08; Cantina Interop L2 2026-06 | 7799a246; fa9974a2 | state | OPCMv2, validators, portal2, super games, SuperchainConfig, SystemConfig | **ASR, DGF, lockbox, L1CDM, bridges, WETH, FDG, MIPS64, PreimageOracle, migrator not in the file list**; "migrate will not be called as part of U20" |
| v8.0.0 -> v9.0.0 (U21: lockbox-only pause, new gas constants, portal reverts on messenger failure, deleteProvenWithdrawal, migrateToSharedDisputeGame) | Cantina U21 2026-11 | 8fdb2775 (optimism-private) | state | ASR, CrossDomainMessenger, L1CDM, WETH, lockbox, migrator, validators, OPCMv2, portal2, SuperchainConfig, SystemConfig | **DGF, every game implementation, MIPS64, PreimageOracle, both L1 bridges, ERC20 factory, ProxyAdmin, AddressManager, the kona prestate change not in the file list**; all 19 Lows acknowledged |

Observations that follow directly from the table:

1. Only four reports state a transition as their scope (Trust v1.1->v1.2, Cantina MCP v1.2->v1.3, IRI diffs,
   U16a). Only U16a tested more than one SOURCE version, and only U16a and U17 ran fork upgrades at all.
2. No report after 2023 has `ProxyAdmin`, `AddressManager` or `ResolvedDelegateProxy` in its scope list, although
   every OPCM upgrade writes through them (`AddressManager` is how L1CDM is upgraded) and both are listed assets.
3. The dispute contracts are reviewed in alternating halves: registry/portal in one report, factory/games in
   another, validators in a third; never all at one commit after v4.0.0.
4. The v2.1.0–v3.0.1 line (four tags) has no report.

## 2. Transitive paths no single report's scope covers (primary research gap)

Format: **object** — created at / transformed at / consumed at — reports that touch a segment — why the full
path is outside every scope statement — code or chain evidence. Ranked by how directly the gap bears on a
value-exit decision at v9.

### T1. Game <-> registry binding ("which registry vouched for this game")
- Created v1.4.0: portal compares `game.gameType()` with its own `respectedGameType`; ASR keeps per-type anchors.
- Transformed v2.0.0: game snapshots `wasRespectedGameTypeWhenCreated` (IRI); validity = ASR predicates.
- Transformed v4.0.0: contest finding 3.2.9 fixed by `asr == address(this)` in `isGameRegistered`
  (`hist/v4.0.0 src/dispute/AnchorStateRegistry.sol:182-200`; still there at `hist/v6.0.0 …:196-214`).
- Transformed v4.1.0: U15->U16a deploys a NEW ASR proxy and leaves the legacy one alive (U16a 5.2.6).
- Transformed v6.0.0: the ASR address moves from a game-implementation immutable to per-type `gameArgs` stored in the factory.
- Transformed v7.0.0: the binding check is REMOVED (`op-v7.0.0 …AnchorStateRegistry.sol:216-226`; `op-v9.0.0 …:227-237`,
  rationale in NatSpec `:217-222`). The game still snapshots "respected" from ITS OWN registry
  (`op-v9.0.0 FaultDisputeGame.sol:318-319`, `SuperFaultDisputeGame.sol:339-340`, `SuperPermissionedDisputeGame.sol:69`),
  and the portal's registry only reads that flag (`op-v9.0.0 AnchorStateRegistry.sol:242-247`).
- Consumed v8/v9: `checkWithdrawal` -> `isGameClaimValid`; the U20 fix (3.1.6, ANCHORP-70) lives in the off-chain validator only.
- Reports: contest 2025-04 (v4 code), OPCMv2 3.3.12 (scope = OPCM files; notes the removal as Informational),
  U19 3.2.7 and U20 3.1.6 (validator), U21 (ASR in scope, DGF and games not).
- Why uncovered: no report has ASR + DGF `gameArgs` + game implementations + the OPCM upgrade path + pre-existing
  games in one scope. The removal was justified by "retirementTimestamp is set at initialize", which is true
  only for the FIRST initialisation of a NEW proxy (`op-v9.0.0 AnchorStateRegistry.sol:130-132`).
- Chain fact (L1 block 26433900, local fork): OP Mainnet factory registers only types 5 and 9 and both `gameArgs`
  embed the portal's ASR `0x23B2C629…D113`. Ink, Soneium, Unichain not read.

### T2. Respected-type / retirement timeline of a chain
- Created v1.4.0 (`respectedGameType`, `respectedGameTypeUpdatedAt` in the portal; legacy slots are spacers at v9,
  `op-v9.0.0 OptimismPortal2.sol:99-107`) -> v2.0.0 (creation-time snapshot) -> v4.0.0 (moved to the ASR; new ASR retires
  everything at first init) -> v7.0.0 (retirement at init "no longer required behavior", set only if zero) ->
  v7+ OPCMv2 can change the respected type through `initialize` (`overrides.cfg.startingRespectedGameType`,
  `op-v9.0.0 src/L1/opcm/OPContractsManagerV2.sol:370,663-667,957`) without touching the retirement timestamp.
- Reports: IRI (naming), contest 3.2.5, U19 3.3.1 (guardian two-call cutover only, Informational), U21 3.1.17.
- Why uncovered: U19 3.3.1 analyses the guardian path; the upgrade path that rewrites `respectedGameType` in
  `initialize` is in no finding, and no report enumerates the games that stay claim-valid across a type switch.
- Chain fact: OP Mainnet `respectedGameType() = 9`, `retirementTimestamp() = 1753379243` (2025-07-24) at block 26433900:
  the retirement cut-off has not moved across U16a, U17, U18, U19, U20 (switch to super-root games) and U21.

### T3. `provenWithdrawals` records across portal generations
- Created v1.0.0 (`hash -> {outputRoot, timestamp, l2OutputIndex}`, re-prove gated: `hist/v1.0.0 contracts/L1/OptimismPortal.sol:277-280`)
  -> v1.4.0 (new mapping `hash -> submitter -> {disputeGameProxy, timestamp}`, no re-prove gate:
  `hist/v1.4.0 src/L1/OptimismPortal2.sol:318-327`; old mapping becomes `spacer_52_0_32`) -> v2.0.0 (legacy games
  rejected by try/catch) -> v4.0.0 (ASR pointer replaced at upgrade; super-root proofs) -> v4.1.0 (super roots moved out)
  -> v8.0.0 (`rootClaimByChainId`) -> v9.0.0 (`deleteProvenWithdrawal` calls `status()` on the STORED address and
  consults the CURRENT registry: `op-v9.0.0 OptimismPortal2.sol:711-727`; proof maturity is an implementation immutable
  applied to all old records, U21 3.1.9).
- Reports: ToB 2023-01 (v1.0.0 object), Sherlock FP (v1.4.0), contest 3.1.5 and 3.2.7, U21 3.1.9 and 3.2.1.
- Why uncovered: each report looks at the record shape of its own release. A record written at N and read at N+k after
  one or more registry replacements is nobody's scope; U21 3.2.1 mentions the "previous registry" case in one sentence.

### T4. "A messenger withdrawal is either recorded or not finalized" (portal <-> L1CDM gas contract)
- Created v1.0.0 after both Sherlock rounds: portal always finalizes; messenger must record success/failure with a
  40k reserve (`hist/v1.0.0 contracts/universal/CrossDomainMessenger.sol:153-159`, `libraries/SafeCall.sol:91-121`).
- Transformed v1.2.0: `require(paused()==false)` added to `relayMessage` (`hist/v1.2.0 src/universal/CrossDomainMessenger.sol:224`);
  Trust M-3 (>50 kB messages lost) acknowledged and left open through v8.
- Transformed v4.0.0: lockbox unlock before the call, re-lock on failure (`hist/v4.0.0 src/L1/OptimismPortal2.sol:655,679`).
- Transformed v9.0.0: L1 reserve 135k + 15k (`op-v9.0.0 src/libraries/GasConstants.sol:60,75`); portal REVERTS when a
  withdrawal whose sender is the L2 messenger fails (`op-v9.0.0 OptimismPortal2.sol:638-653`); deployed L2 messenger
  still computes `baseGas` with 40k/5k (U21 3.1.3).
- Reports: Sherlock 2023-01/03, Trust, U21 (3.1.3, 3.1.4, 3.1.10, 3.1.14, 3.1.16).
- Why uncovered: U21 describes the v9 rule for NEW withdrawals. In-flight objects are outside every scope:
  withdrawals initiated under earlier L2 constants, `failedMessages` entries written under v1–v8 semantics and
  replayed under v9, OVM-era migrated withdrawals with synthetic gas limits (Sherlock 2023-03 H-1), and the
  acknowledged forced-fail griefing (Trust M-1) combined with the v9 revert.

### T5. Pause identity
- v1.0.0 portal `paused` bool + messenger owner pause (spacers at v9) -> v1.2.0 global SuperchainConfig ->
  v4.0.0 `paused(lockbox) || paused(0)` -> v4.1.0–v8.0.0 `paused(0) || paused(feature ? lockbox : portal)` ->
  v5.0.0 `setFeature` refuses while paused -> v9.0.0 `portal.ethLockbox().paused()`; portal identifier retired
  (all quoted from `SystemConfig.sol` `paused()`/`setFeature` at each tag; see FIX-CLOSURE-MATRIX row 6).
- Reports: Trust (v1.2), Kontrol (v1.2 property), Spearbit U16 5.1.3, U16a 5.1.3, OPCMv2 3.3.2, U21 3.1.2 / 3.2.14.
- Why uncovered: each report fixes or acknowledges ONE writer of the identifier. No report enumerates every
  writer of `ethLockbox` / `optimismPortal` / the feature flag per release, nor what a pause recorded under an old
  identifier means after the next upgrade, nor the contracts that read pause through another pointer chain
  (L1StandardBridge and L1ERC721Bridge are not in the U21 file list although U21 changes how they resolve pause).

### T6. ETH custody per chain history
- Portal balance (v1.0.0–v3.x) -> lockbox at v4.0.0 -> feature-flagged at v4.1.0 (chains that skipped v4.0.0 have
  `ethLockbox == 0`, U16a 5.2.5) -> v5.0.0 upgrader "neither flips the flag nor sweeps funds" (U17 3.1.3) ->
  v9.0.0 upgrade deploys a lockbox, enables the feature and migrates portal ETH for lockbox-less chains (U21 3.1.12).
  Side pockets: ETH of failed messages held by L1CDM (since v1.0.0), ETH of failed direct withdrawals left in the
  portal before the v4.0.0 re-lock, donations (`donateETH`).
- Reports: Wonderland L-2, contest 3.2.8, U16a 5.2.1, U17 3.1.3, U21 3.1.12 / 3.2.2.
- Why uncovered: every report describes one step for a generic chain; none reconciles liabilities with custody for
  a concrete history (lockbox at v4.0.0 vs flag-off until v9).

### T7. Anchor object
- Per-type `anchors[]` (v1.4.0) -> single `anchorGame` + `startingAnchorRoot`, seeded from the respected type's
  anchor (v2.0.0/v4.0.0, contest 3.2.15 and 3.2.18) -> new ASR proxies (v4.0.0, v4.1.0) -> v7.0.0 `initialize` clears
  `anchorGame` only when the starting root CHANGES (`op-v9.0.0 AnchorStateRegistry.sol:112-121`) -> v8.0.0 super-root
  games read a legacy output-root anchor unless an operator instruction replaces it (U20 3.1.4, acknowledged) -> v9.0.0.
- Reports: Sherlock FP M-2, U13 5.1.2 (blacklist check removed from `getAnchorRoot`), contest, U19 3.2.1, U20 3.1.1 /
  3.1.4, U21 3.1.19 / 3.2.11.
- Why uncovered: all are "what if the operator supplies X". None traces the actual anchor of a chain through the
  U20 switch to a super game type, and none covers a blacklisted-or-retired game remaining the anchor after a
  registry re-initialisation.

### T8. Absolute prestate / VM generation of live games
- MIPS 32-bit (v1.4.0; Cantina: 1 Critical + 1 High + 8 Medium, none fixed at report time) -> MIPS64 state versions
  (futex High, shift bugs) -> Go 1.23/1.24 support (internal syscall-error register swap, eventfd) -> kona (2 Critical,
  1 High fixed; 2 Medium + 32 Low acknowledged) -> v8.0.0 kona super games respected -> v9.0.0 new kona prestate.
- Why uncovered: each VM review is PR-scoped and assumes a correct compiler/program. No report asks which games
  created under a pre-fix prestate are still in progress or claim-valid after the switch, although clones keep their
  prestate for life (implementation immutable up to v5, per-type `gameArgs` from v6). The kona prestate change in
  U21 is not in the U21 scope list at all.

### T9. DelayedWETH generations
- One proxy per game type (v1.4.0) -> a new proxy on every U16->U16a upgrade until PR 17406 -> v9.0.0
  `initialize(lockbox)` replaces the per-chain SystemConfig authority; `migrate` re-initialises every old proxy and
  reuses member 0's proxy for all shared games (OPCMv2 3.1.1, U21 3.1.15); delays are implementation immutables (U21 3.1.5).
- Reports: Sherlock FP family 008-M, IRI I-02 (unbounded `unlock`, acknowledged), U16a 5.1.2, OPCMv2 3.1.1, U21.
- Why uncovered: old proxies holding bonds of old games are re-pointed by later releases; no report follows a credit
  created under generation k through the re-pointings.

### T10. Initializer generations vs live state
- v1.2.0 guard (Trust H-1, L-2) -> v1.3.0 single `initialize` for deploy and upgrade (Cantina MCP 3.2.7) -> v2.0.0
  StorageSetter-zero-then-initialize in OPCM -> v4.0.0 `upgrade()` functions + ReinitializableBase (initialize callable
  in place of upgrade: acknowledged) -> v7.0.0 OPCMv2 re-runs `initialize()` on every upgrade with values loaded from
  the live chain plus override instructions -> v9.0.0.
- Why uncovered: idempotence was reviewed per contract per release for the fields that existed then. v9 initializers
  write pointers that decide trust (`ethLockbox`, `anchorStateRegistry`, `disputeGameFactory`, `respectedGameType`,
  `l2ChainId`); OPCMv2 3.3.13 was answered with "review rules", not a contract check.

### T11. SystemConfig events at upgrade time x three derivation implementations
- U13 5.1.1 (EIP-1559 params unset = chain defaults, acknowledged), U20 3.2.3 / 3.2.7 (scalar canonicalised, overhead
  reset during upgrade), every OPCMv2 upgrade re-runs `SystemConfig.initialize`; kona 3.3.2 (pipeline reset uses the
  safe-head config instead of the config one channel-timeout back, acknowledged "very low risk").
- Why uncovered: contract reviews stop at the event; the kona review never considers an upgrade-time burst of
  ConfigUpdate events; no report covers op-node + kona + contracts for the same L1 block.

### T12. AddressManager -> ResolvedDelegateProxy -> L1CDM -> initializer authorization
- v4.0.0 `ProxyAdminOwnedBase.proxyAdmin()` special-cases the messenger by reading the proxy's name and AddressManager
  slots (Spearbit 2025-05 5.1.5, "documented"); U13 5.3.10 (silent no-op if the proxy is missing, won't fix).
- Why uncovered: neither AddressManager nor ResolvedDelegateProxy has been in a scope list since 2022.

### T13. Chain-id binding of a proof
- Game `l2ChainId` immutable (v1.4.0) -> `gameArgs` (v6.0.0) -> super games store 0 and the portal selects the member
  root with `systemConfig.l2ChainId()` (`op-v8.0.0 OptimismPortal2.sol:422-427`, `op-v9.0.0 …:437-442`); for legacy games
  the portal never checks a chain id (U19 3.3.2). `SystemConfig.l2ChainId` is storage written by OPCM at upgrade.
- Reports: U19 3.2.8 / 3.3.2, U20 3.1.3 / 3.2.5, U21 3.1.1 / 3.1.18 / 3.2.10 — all validator- or operator-framed.
- Why uncovered: the value was first written long before it was first consumed for proofs; no report checks the
  stored value per chain history against the moment it became consensus-critical.

### T14. Skipped-upgrade histories reaching v9
- U16a tested U15->U16a; U17 tested only a fresh U16; U19–U21 tested no historical source. The OPCM sequencing
  predicate accepts the same manager again, any higher minor of the same major, or the next major (U21 3.1.6).
- Why uncovered: no report runs the v9 upgrade from a state produced by a non-standard history (no lockbox, two ASR
  generations, per-type anchors, bespoke implementations deployed between MCP and OPCM — Cantina MCP 3.1.4).

### T15. OVM-era objects
- Legacy withdrawals migrated at Bedrock with synthetic gas limits; version-0 message hashes guarded by the legacy
  `successfulMessages` slot (`op-v9.0.0 src/universal/CrossDomainMessenger.sol:21-78,122,229-232`).
- Why uncovered: last reviewed in 2023; the v9 comment "legacy message that was already relayed ... can be proven but
  never finalized" (`op-v9.0.0 OptimismPortal2.sol:642-646`) changes their terminal state without a report.

## 3. Ranked gap list (what the next wave should attack first)

1. T1 + T2 together: a game that is registered in a chain's factory, was created after the chain's unchanged
   retirement cut-off, and whose "respected" snapshot or anchor came from a different registry generation or from a
   since-de-respected type. Needs per-chain reads of factory `gameImpls`/`gameArgs`, portal ASR, ASR history, and a
   census of DEFENDER_WINS games per type since each chain's `retirementTimestamp`.
2. T3: proofs written before a registry replacement, finalize/delete behaviour at v9 (including stored addresses
   that are not games of the current factory).
3. T4: in-flight messenger objects under the v9 revert rule and new reserves.
4. T5: every writer of the pause identifier per release and per chain history; pause recorded under a retired identifier.
5. T8: games still open or claim-valid that were created under a prestate with a later soundness fix.
6. T7: the anchor each chain actually carried through the U20 game-type switch.
7. T6 / T14: custody and upgrade behaviour for chains whose history differs from OP Mainnet's.
8. T10 / T13: pointers and chain ids rewritten by initializers.
9. T9, T11, T12, T15.
