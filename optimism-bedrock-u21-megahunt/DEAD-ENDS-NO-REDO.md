# DEAD ENDS — DO NOT REDO (PASS A rejections condensed)

Worker W0. Source: the 180 files in `/home/user/Tracking_Body/optimism-u21-novel-hunt/rejected/` (paths below are relative to that workspace). Each family lists the single killing fact, where the evidence is, and whether the kill rests on **current state only**. A family marked CURRENT-STATE-ONLY, PARTLY CURRENT-STATE, BOUNDARY-SPECIFIC or EXTENDED-BY-W0 says nothing (or only something bounded) about objects created under older releases: those are **reopenable by PASS B**, and the last column says exactly along which edge. INVARIANT families are killed by code that W0 traced through the historical trees; do not re-walk them without a new precondition.

| Family | PASS A rejections | Reopenable by PASS B? |
|---|---|---|
| D01 Upgrade 21 execution left a wrong, stale, partial or re-initialisable … | 23 | CURRENT-STATE-ONLY |
| D02 A legacy storage slot or struct written by an older implementation is … | 8 | EXTENDED-BY-W0 |
| D03 Double execution / double unlock of one withdrawal (alternate submitte… | 15 | INVARIANT (not state-dependent) |
| D04 A messenger withdrawal is finalized in the portal while the messenger … | 10 | PARTLY CURRENT-STATE |
| D05 Freeze or poison a victim's messenger withdrawal using the new v9 reve… | 8 | PARTLY CURRENT-STATE |
| D06 Gas-budget mismatches make in-flight withdrawals unfinalizable or loss… | 17 | RULE-SET-DEPENDENT |
| D07 ETH conservation between portal, lockbox and messenger breaks (donatio… | 15 | CURRENT-STATE-ONLY (0305, 0407, 2303, 2906); rest INVARIANT |
| D08 Lockbox authority abuse (portal unlocking another chain's ETH, withdra… | 13 | CURRENT-STATE-ONLY (0308, 0901); rest INVARIANT |
| D09 Proof deletion or proof bookkeeping harms an honest withdrawal (delete… | 16 | CURRENT-STATE-ONLY (0507, 2506, 2510); rest INVARIANT |
| D10 Proofs or failed messages created under v8 are lost, corrupted or doub… | 3 | BOUNDARY-SPECIFIC |
| D11 The pause-identifier move to the lockbox drops an active pause, resurr… | 14 | CURRENT-STATE-ONLY |
| D12 A feature flag, l2ChainId or resource config can be moved by a non-pri… | 8 | INVARIANT (value provenance is historical) |
| D13 Dispute-game domain: proof-type confusion, cross-factory or cross-regi… | 17 | CURRENT-STATE-ONLY (0704, 2703, 2704, 2706); rest INVARIANT |
| D14 Pre-positioning against the planned migrate (CREATE2 squatting, pre-re… | 10 | FUTURE-ACTION |
| D15 Scope claims: the live registry, DelayedWETH or sibling-chain proxies … | 3 | SCOPE FACT |

## D01 — Upgrade 21 execution left a wrong, stale, partial or re-initialisable state (incl. direct calls into the OPCM family, a proxy left on StorageSetter, unlocked implementations, validator/mutation mismatch, hidden library changes)

**Rejections (23):** REJ-0101, REJ-0102, REJ-0103, REJ-0104, REJ-0105, REJ-0106, REJ-0110, REJ-0111, REJ-0202, REJ-0203, REJ-0206, REJ-0208, REJ-0209, REJ-1001, REJ-1206, REJ-2101, REJ-2102, REJ-2103, REJ-2104, REJ-2106, REJ-2107, REJ-2202, REJ-3006

**Killing fact:** Replaying the real U21 transaction on block N-1 reproduces block N on all 339 written slots; every one of the 41 proxies ends with `_initialized == initVersion()` and every implementation is locked; `upgrade/upgradeSuperchain/migrate` start with `_onlyDelegateCall()` (v9 src/L1/opcm/OPContractsManagerV2.sol:198,245,294,1074-1078) and a foreign delegatecaller fails at `ProxyAdmin.onlyOwner`.

**Evidence:** evidence/lane01-*.json, lanes/LANE-01-report.md, mirror/lane-21/, test/poc/lane01/, U21_INITIALIZER_CALLS.md, U21_PROXY_IMPLEMENTATION_MAP.md

**State dependence:** CURRENT-STATE-ONLY

**What it does not cover / reopen edge:** True for the U21 transaction applied to the four chains' actual N-1 state. It says nothing about earlier upgrade transactions (U13, U16, U16a, U17..U20), chains that reached v8 through a different sequence, or proxies created by older OPCM generations. Closure C1.

## D02 — A legacy storage slot or struct written by an older implementation is reinterpreted by v9 (portal spacers, proof structs, SystemConfig re-initialisation, packed registry slot, gameArgs bytes)

**Rejections (8):** REJ-0201, REJ-0204, REJ-0205, REJ-0504, REJ-0606, REJ-2201, REJ-2203, REJ-2205

**Killing fact:** Portal/L1CDM/registry/WETH/factory layout snapshots are identical v7 = v8 = v9 except the new lockbox pointers written into previously-zero bytes; overwriting every legacy spacer with junk leaves 16 getters and a live deposit unchanged on all four chains (`test_legacySpacerSlotsAreDeadStorage`).

**Evidence:** test/poc/lane02/U21StorageReinit.t.sol, U21_STORAGE_LAYOUT_DIFF.md, evidence/lane02/, mirror/lane-22/

**State dependence:** EXTENDED-BY-W0

**What it does not cover / reopen edge:** PASS A compared v7..v9 only. W0 diffed the layout snapshots tag by tag from v1.2.0: for every proxy upgraded in place (portal, L1CDM, bridges, SystemConfig, factory) each removed field became a same-size spacer and no slot was reused. Registries and DelayedWETH DID break layout (v2.0.0, v4.0.0) and were re-proxied, so their old proxies are separate live objects, not reinterpreted ones. v1.0.0/v1.1.0 have no snapshot (F4). Closure C2.

## D03 — Double execution / double unlock of one withdrawal (alternate submitters or games, re-prove, delete-then-re-prove, nested finalize, replay after failure, persistent failed bit, sender == 0xdEaD)

**Rejections (15):** REJ-0301, REJ-0309, REJ-0402, REJ-0404, REJ-0802, REJ-1105, REJ-2301, REJ-2308, REJ-2402, REJ-2403, REJ-2410, REJ-2508, REJ-3104, REJ-3105, REJ-2408

**Killing fact:** `finalizedWithdrawals[withdrawalHash]` is keyed by the hash only, written before the unlock and the external call (v9 src/L1/OptimismPortal2.sol:610) and checked first in `checkWithdrawal` (:677); nested finalize reverts `OptimismPortal_NoReentrancy` (:594); the messenger requires `successfulMessages[hash] == false` on every relay (src/universal/CrossDomainMessenger.sol:254).

**Evidence:** test/poc/lane03, lane04 (Fab.t.sol, Fab2.t.sol), lane11 PortalInvariants.t.sol, mirror/lane-24/tests/WithdrawalFinalization24.t.sol

**State dependence:** INVARIANT (not state-dependent)

**What it does not cover / reopen edge:** The barrier is code that W0 traced back unchanged to v1.0.0 (slot 51, flag-before-call, V1 message hash). It can only be reopened by a hash-domain argument: one economic withdrawal under two hashes (legacy version-0 migration, queue B02). Closure C5.

## D04 — A messenger withdrawal is finalized in the portal while the messenger records neither success nor failure (any gas value, any message shape); unlock without finalization

**Rejections (10):** REJ-0302, REJ-0306, REJ-0401, REJ-0804, REJ-1004, REJ-1101, REJ-2404, REJ-3101, REJ-3201, REJ-2409

**Killing fact:** Every non-reverting exit of v9 `relayMessage` writes `failedMessages` or `successfulMessages` (src/universal/CrossDomainMessenger.sol:269,292,295); a revert makes the portal revert with `OptimismPortal_L1CDMCallFailed` (src/L1/OptimismPortal2.sol:651-653). 51,316 + 192 gas probes on real fixtures: 0 "neither" outcomes.

**Evidence:** evidence/lane11/gas-boundary-l1.json, evidence/lane08/measure_tables.md, mirror/lane-31/GAS_BOUNDARY_RESULTS.md, test/poc/lane12/Lane12.t.sol

**State dependence:** PARTLY CURRENT-STATE

**What it does not cover / reopen edge:** The v9 statement is an invariant. The HISTORICAL half is not closed: v8 and earlier did produce "finalized, unknown to messenger" objects (v8 reproduces it for 100 kB payloads) and REJ-2409 scanned `WithdrawalFinalized(success=false)` only for blocks 25,900,000..26,430,858 (one hit, no stranded value). Bedrock..25.9M on all four chains is open (PRIMITIVES A-068). Closure C6.

## D05 — Freeze or poison a victim's messenger withdrawal using the new v9 revert (pre-set failed/successful bit, sender-only check with a different target, L2CDM made to withdraw to an arbitrary target)

**Rejections (8):** REJ-0403, REJ-0405, REJ-0803, REJ-0806, REJ-0808, REJ-1203, REJ-2405, REJ-3108

**Killing fact:** The first write to either messenger mapping for hash h needs `msg.sender == portal && portal.l2Sender() == L2CDM`, i.e. the victim's own withdrawal; the live L2CDM (2.2.1) hard-wires the withdrawal target to the L1CDM and refuses to relay to itself or the message passer.

**Evidence:** test/poc/lane04 Fab.t.sol::test_cond_*, L2Side.t.sol; lanes/LANE-08-report.md; mirror/lane-24

**State dependence:** PARTLY CURRENT-STATE

**What it does not cover / reopen edge:** "sender == L2CDM implies target == L1CDM" was checked against the LIVE L2CDM only. Withdrawals created by earlier L2CDM versions and legacy withdrawals re-encoded by the Bedrock migration were not enumerated (PRIMITIVES A-017). Closure C7.

## D06 — Gas-budget mismatches make in-flight withdrawals unfinalizable or lossy (old L2 baseGas vs v9 L1 reserves, 183,600 new-account reserve, payload copied before the gas check, deeper pause resolution, 63/64 starvation, large-calldata deposit regression)

**Rejections (17):** REJ-0304, REJ-0406, REJ-0408, REJ-0605, REJ-0801, REJ-0805, REJ-0807, REJ-1102, REJ-1103, REJ-1201, REJ-1209, REJ-2401, REJ-2406, REJ-3005, REJ-3106, REJ-3107, REJ-3206

**Killing fact:** `SafeCall.callWithMinGas` forwards `gas()` (v9 src/libraries/SafeCall.sol:162): the withdrawal gasLimit is a floor, so more transaction gas always reaches the callee; every under-gassed path reverts (retry) or records a replayable failure; measured margins stay positive up to minGasLimit 5.76M (old budget) / 7.3M (live budget).

**Evidence:** evidence/lane08/measure_tables.md, evidence/lane04-forge-isolate-output.txt, evidence/lane11/injected-gas-*.json, mirror/lane-31/DIFFERENTIAL_RESULTS.md

**State dependence:** RULE-SET-DEPENDENT

**What it does not cover / reopen edge:** Not historical: holds under today's L1 gas rules. Open only for the EIP-7825 per-transaction cap band (lead L5) and for Amsterdam activation before the L2 messenger is upgraded; older budget generations (pre-v3.0.0 formula, version-0 withdrawals) are the same question (PRIMITIVES A-018).

## D07 — ETH conservation between portal, lockbox and messenger breaks (donations spent, relock skipped or over-swept, pause duplicates/strands value, deposit mints more than it locks, CGT mode, pre-meter lockbox call, U21 left value in the wrong contract, unbacked ETH before pooling)

**Rejections (15):** REJ-0303, REJ-0305, REJ-0307, REJ-0310, REJ-0311, REJ-0407, REJ-1005, REJ-1208, REJ-2302, REJ-2303, REJ-2304, REJ-2306, REJ-2307, REJ-2906, REJ-3002

**Killing fact:** Finalization unlocks and forwards exactly `_tx.value` and re-locks exactly `_tx.value` on a failed non-messenger call (v9 src/L1/OptimismPortal2.sol:614,627,661-665); the only read of `address(this).balance` is owner-only `migrateLiquidity`; from the U21 block to the fork block lockbox delta == sum(ETHLocked) - sum(ETHUnlocked).

**Evidence:** test/poc/lane03 (test_A_*, test_D_*, testFuzz_F_sequenceConservation), evidence/lane03/reconcile_u21_window.json, mirror/lane-23/

**State dependence:** CURRENT-STATE-ONLY (0305, 0407, 2303, 2906); rest INVARIANT

**What it does not cover / reopen edge:** The four state-based rejections only show that portals hold 0 and lockboxes are funded at N-1/N/26433900. They do not show that each lockbox balance covers the chain's L2 liability: the U16 sweep (`portal.migrateLiquidity()`, v4.0.0 src/L1/OPContractsManager.sol:736) merged all pre-lockbox surplus and deficits into one number (PRIMITIVES A-011, lead L9). Closure C3.

## D08 — Lockbox authority abuse (portal unlocking another chain's ETH, withdrawal targeting a lockbox or sibling portal, fake same-owner proxy, sibling-path bypass, shared-pool drain, proof reuse across portals, portal alias on L2)

**Rejections (13):** REJ-0308, REJ-0410, REJ-0901, REJ-0902, REJ-0903, REJ-1003, REJ-2305, REJ-2901, REJ-2902, REJ-2904, REJ-2905, REJ-3003, REJ-3203

**Killing fact:** `unlockETH` requires an authorised portal whose `l2Sender()` is the default, i.e. it cannot be reached from a withdrawal callback (v9 src/L1/ETHLockbox.sol:157-178); `_isUnsafeTarget` blocks the portal and its current lockbox; the authorisation cross product over 4 chains + Base is diagonal; super-root proofs are bound by `rootClaimByChainId(systemConfig.l2ChainId())`.

**Evidence:** test/poc/lane09/, evidence/lane09-lockbox-auth-events-22990500-26433904.json, mirror/lane-29/LIVE_STATE.md

**State dependence:** CURRENT-STATE-ONLY (0308, 0901); rest INVARIANT

**What it does not cover / reopen edge:** The diagonal matrix is a read of today's mappings plus one public RPC's event history for the four current lockboxes. Lockboxes that older OPCM generations could have deployed ("ETHLockbox-U16a", "-Interop") and a second log source were not checked (PRIMITIVES A-014). Closure C9.

## D09 — Proof deletion or proof bookkeeping harms an honest withdrawal (delete a proof that could finalize, front-run finalize, delete while paused, array desync/DoS, attacker proof selected, non-game address stored, retired proofs undeletable, existing exploitable proof/game pairs)

**Rejections (16):** REJ-0501, REJ-0502, REJ-0503, REJ-0506, REJ-0507, REJ-1204, REJ-2501, REJ-2502, REJ-2503, REJ-2504, REJ-2506, REJ-2507, REJ-2509, REJ-2510, REJ-3102, REJ-3202

**Killing fact:** Delete predicate = `game.status() == CHALLENGER_WINS || currentRegistry.isGameBlacklisted(game)` (v9 src/L1/OptimismPortal2.sol:718-723); both are permanent and disjoint from `isGameClaimValid`; proofs are keyed by (hash, submitter), finalization names the submitter, nothing iterates `proofSubmitters`.

**Evidence:** test/poc/lane05/Lifecycle.t.sol, mirror/lane-25/ ProofLifecycle.t.sol, evidence/lane05-*.json

**State dependence:** CURRENT-STATE-ONLY (0507, 2506, 2510); rest INVARIANT

**What it does not cover / reopen edge:** The survey covered 44 proofs from blocks 26,425,493+ and assumed every stored game is a current-ABI factory clone. Proof cells written under v1.4.0..v3.x (games of registries 0x18DAc71c… / 0x1c68ECfb…) were never read or pushed through v9 (PRIMITIVES A-021, A-074). Closure C4.

## D10 — Proofs or failed messages created under v8 are lost, corrupted or double-usable under v9; current registry change strands old proofs

**Rejections (3):** REJ-0409, REJ-2407, REJ-2505

**Killing fact:** A withdrawal proven under v8 (block 26,377,651) finalized under v9 on chain (block 26,432,294); a v8 failed message replays exactly once after the real U21 transaction is replayed in-process.

**Evidence:** test/poc/lane04/CrossVersion.t.sol, mirror/lane-24/REAL_WITHDRAWAL_EVIDENCE.md, mirror/lane-25/CHAIN_READS.md

**State dependence:** BOUNDARY-SPECIFIC

**What it does not cover / reopen edge:** Proves v8 -> v9 only. Every older boundary (v1.3 -> v1.4 portal swap, v3 -> v4 registry move, v6 -> v7 registry-binding removal) is PASS B.

## D11 — The pause-identifier move to the lockbox drops an active pause, resurrects an old one, leaves a value path un-paused, or breaks an un-upgraded dependent

**Rejections (14):** REJ-0107, REJ-0108, REJ-0207, REJ-0601, REJ-0602, REJ-0906, REJ-1104, REJ-1202, REJ-1205, REJ-2204, REJ-2601, REJ-2605, REJ-2606, REJ-3103

**Killing fact:** On all four chains ETH_LOCKBOX was already true and `portal.ethLockbox()` already the same address at N-1, so the effective identifier did not change; `pauseTimestamps` is 0 for address(0), the four portals and the four lockboxes; with the lockbox identifier paused every prove/finalize/relay/bridge-finalize/unlock/WETH-withdraw reverts.

**Evidence:** test/poc/lane06/PauseMatrix.t.sol, evidence/lane06/state-pre-26430858.txt, mirror/lane-22/PAUSE_AND_AUTHORIZATION_MAPPINGS.md, mirror/lane-26/

**State dependence:** CURRENT-STATE-ONLY

**What it does not cover / reopen edge:** All of it rests on "nothing is paused now and the identifier was already the lockbox". Past Paused events, expired-not-reset timestamps, chains that used the portal identifier (v4.1.0..v8.0.0 without lockbox) and consumers that never left the generation-1 global pause (legacy DelayedWETH; registry 0x1c68ECfb… has no pause check) are untouched (PRIMITIVES A-005, A-028). Closure C8.

## D12 — A feature flag, l2ChainId or resource config can be moved by a non-privileged actor, or re-migration / chain-id aliasing corrupts the shared set

**Rejections (8):** REJ-0603, REJ-0604, REJ-1207, REJ-2602, REJ-2603, REJ-2604, REJ-3204, REJ-3205

**Killing fact:** `setFeature` starts with `_assertOnlyProxyAdminOrProxyAdminOwner()` (v9 src/L1/SystemConfig.sol:534); `l2ChainId` and the resource config are written only by the gated reinitializer; the migrator rejects zero/duplicate/unordered chain ids and an already-set INTEROP flag.

**Evidence:** test/poc/lane06/FeatureMachine.t.sol, mirror/lane-26/, mirror/lane-32/ NegativeSpace.t.sol

**State dependence:** INVARIANT (value provenance is historical)

**What it does not cover / reopen edge:** Authorization is code. The VALUE of l2ChainId was written once by the v4.0.0 `upgrade()` from the permissioned game's immutable (PRIMITIVES A-031): correct on the four chains today, never checked for other OPCM-upgraded chains.

## D13 — Dispute-game domain: proof-type confusion, cross-factory or cross-registry game reuse, duplicate/foreign chain ids winning, old or unset-type games usable, anchor injection, tx.origin hijack, liveness cliff, in-flight games or bonds broken by the singleton swap, retroactive prestate change, ZK parent omission

**Rejections (17):** REJ-0109, REJ-0701, REJ-0702, REJ-0703, REJ-0704, REJ-0706, REJ-0707, REJ-1002, REJ-2105, REJ-2701, REJ-2702, REJ-2703, REJ-2704, REJ-2706, REJ-3001, REJ-3004, REJ-3207

**Killing fact:** One prove function branches on the registered game's own `gameType()`; games are taken by index from the portal's own factory and re-checked by `isGameClaimValid`; the kona program copies the chain list from the agreed pre-state; clone args are fixed at creation; 60/60 sampled in-flight games resolve and pay after U21; the full OP Mainnet census (11,629 games) has one third-party claim-valid game whose root matches the L2 header.

**Evidence:** test/poc/Lane07_Probes.t.sol, evidence/op-mainnet-games-census.txt, mirror/lane-27/, mirror/lane-30/, lanes/LANE-07-report.md

**State dependence:** CURRENT-STATE-ONLY (0704, 2703, 2704, 2706); rest INVARIANT

**What it does not cover / reopen edge:** "Today's factory args point at the same registry" and "sampled roots match" are reads of the present OP Mainnet state. History matters here: the registry-binding check was removed at v7.0.0 and every factory holds games of three registries (PRIM-W0-01). W0 closed that half for OP/Ink/Unichain/Soneium (implementation history: no implementation bound to a superseded registry was live after the current registry's retirement). Still open: game census of Ink/Soneium/Unichain and recomputation of the ~10.2k official claim-valid roots per implementation generation (PRIMITIVES A-001, A-002). Closures C11, C12, C13.

## D14 — Pre-positioning against the planned migrate (CREATE2 squatting, pre-registered games, surviving proofs, ETH donations, non-atomic or permissionless migration, missing code-length check)

**Rejections (10):** REJ-0505, REJ-0705, REJ-0708, REJ-0904, REJ-0905, REJ-2108, REJ-2309, REJ-2705, REJ-2903, REJ-3208

**Killing fact:** The real flow runs by DELEGATECALL from the ProxyAdmin-owner Safe (v9 src/L1/opcm/OPContractsManagerUtilsCaller.sol:257), so the CREATE2 deployer is the Safe and the salt mixes `block.timestamp`; migrate deploys a net-new factory and registry whose `retirementTimestamp` is the migration time; everything happens in one transaction.

**Evidence:** test/poc/lane09/, test/poc/Lane07_Migration.t.sol, evidence/lane09-migrate-op-unichain-trace.txt, mirror/lane-27/MIGRATION_MODEL.md

**State dependence:** FUTURE-ACTION

**What it does not cover / reopen edge:** Depends on the planned calldata, not on history. Only residue reopens it: pre-U16 objects (legacy registries that mirror portal getters, legacy WETH) crossing the migration (PRIMITIVES A-035, PRIM-W0-02). Closures C10, C14.

## D15 — Scope claims: the live registry, DelayedWETH or sibling-chain proxies are explicitly listed Immunefi assets

**Rejections (3):** REJ-3301, REJ-3302, REJ-3303

**Killing fact:** The listed registry is 0x18DAc71c… and the listed DelayedWETH is 0xE497B094…; the live proxies are 0x23B2C629… and 0x1b6dBF05…; no Ink/Soneium/Unichain row exists.

**Evidence:** mirror/lane-33/SCOPE_SNAPSHOT.md, SCOPE.md

**State dependence:** SCOPE FACT

**What it does not cover / reopen edge:** W0 lineage note: the two LISTED addresses are exactly the generation-1 registry (version() "2.0.0", still deployed) and the generation-1 DelayedWETH (1.0.0, still holding bonds) — legacy objects in the lineage, not typos.

## Dead ends added by W0

- **REJ-W0-01** (`rejected/REJ-W0-01.md`): "a legacy message blocked before Bedrock becomes relayable because Bedrock dropped `blockedMessages`" — killed: zero `MessageBlocked`/`MessageAllowed` logs on the OP Mainnet L1CDM over its whole pre-Bedrock life (L1 blocks 12,686,000..17,430,000).

