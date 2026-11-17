import os,re
OUT='/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/'
PA='/home/user/Tracking_Body/optimism-u21-novel-hunt/'
allr=sorted(f[4:8] for f in os.listdir(PA+'rejected'))
F=[]
def fam(code,title,ids,kill,evidence,reopen,why):
    F.append(dict(code=code,title=title,ids=ids.split(),kill=kill,evidence=evidence,reopen=reopen,why=why))
fam('D01','Upgrade 21 execution left a wrong, stale, partial or re-initialisable state (incl. direct calls into the OPCM family, a proxy left on StorageSetter, unlocked implementations, validator/mutation mismatch, hidden library changes)',
 '0101 0102 0103 0104 0105 0106 0110 0111 0202 0203 0206 0208 0209 1001 1206 2101 2102 2103 2104 2106 2107 2202 3006',
 'Replaying the real U21 transaction on block N-1 reproduces block N on all 339 written slots; every one of the 41 proxies ends with `_initialized == initVersion()` and every implementation is locked; `upgrade/upgradeSuperchain/migrate` start with `_onlyDelegateCall()` (v9 src/L1/opcm/OPContractsManagerV2.sol:198,245,294,1074-1078) and a foreign delegatecaller fails at `ProxyAdmin.onlyOwner`.',
 'evidence/lane01-*.json, lanes/LANE-01-report.md, mirror/lane-21/, test/poc/lane01/, U21_INITIALIZER_CALLS.md, U21_PROXY_IMPLEMENTATION_MAP.md',
 'CURRENT-STATE-ONLY','True for the U21 transaction applied to the four chains\' actual N-1 state. It says nothing about earlier upgrade transactions (U13, U16, U16a, U17..U20), chains that reached v8 through a different sequence, or proxies created by older OPCM generations. Closure C1.')
fam('D02','A legacy storage slot or struct written by an older implementation is reinterpreted by v9 (portal spacers, proof structs, SystemConfig re-initialisation, packed registry slot, gameArgs bytes)',
 '0201 0204 0205 0504 0606 2201 2203 2205',
 'Portal/L1CDM/registry/WETH/factory layout snapshots are identical v7 = v8 = v9 except the new lockbox pointers written into previously-zero bytes; overwriting every legacy spacer with junk leaves 16 getters and a live deposit unchanged on all four chains (`test_legacySpacerSlotsAreDeadStorage`).',
 'test/poc/lane02/U21StorageReinit.t.sol, U21_STORAGE_LAYOUT_DIFF.md, evidence/lane02/, mirror/lane-22/',
 'EXTENDED-BY-W0','PASS A compared v7..v9 only. W0 diffed the layout snapshots tag by tag from v1.2.0: for every proxy upgraded in place (portal, L1CDM, bridges, SystemConfig, factory) each removed field became a same-size spacer and no slot was reused. Registries and DelayedWETH DID break layout (v2.0.0, v4.0.0) and were re-proxied, so their old proxies are separate live objects, not reinterpreted ones. v1.0.0/v1.1.0 have no snapshot (F4). Closure C2.')
fam('D03','Double execution / double unlock of one withdrawal (alternate submitters or games, re-prove, delete-then-re-prove, nested finalize, replay after failure, persistent failed bit, sender == 0xdEaD)',
 '0301 0309 0402 0404 0802 1105 2301 2308 2402 2403 2410 2508 3104 3105 2408',
 '`finalizedWithdrawals[withdrawalHash]` is keyed by the hash only, written before the unlock and the external call (v9 src/L1/OptimismPortal2.sol:610) and checked first in `checkWithdrawal` (:677); nested finalize reverts `OptimismPortal_NoReentrancy` (:594); the messenger requires `successfulMessages[hash] == false` on every relay (src/universal/CrossDomainMessenger.sol:254).',
 'test/poc/lane03, lane04 (Fab.t.sol, Fab2.t.sol), lane11 PortalInvariants.t.sol, mirror/lane-24/tests/WithdrawalFinalization24.t.sol',
 'INVARIANT (not state-dependent)','The barrier is code that W0 traced back unchanged to v1.0.0 (slot 51, flag-before-call, V1 message hash). It can only be reopened by a hash-domain argument: one economic withdrawal under two hashes (legacy version-0 migration, queue B02). Closure C5.')
fam('D04','A messenger withdrawal is finalized in the portal while the messenger records neither success nor failure (any gas value, any message shape); unlock without finalization',
 '0302 0306 0401 0804 1004 1101 2404 3101 3201 2409',
 'Every non-reverting exit of v9 `relayMessage` writes `failedMessages` or `successfulMessages` (src/universal/CrossDomainMessenger.sol:269,292,295); a revert makes the portal revert with `OptimismPortal_L1CDMCallFailed` (src/L1/OptimismPortal2.sol:651-653). 51,316 + 192 gas probes on real fixtures: 0 "neither" outcomes.',
 'evidence/lane11/gas-boundary-l1.json, evidence/lane08/measure_tables.md, mirror/lane-31/GAS_BOUNDARY_RESULTS.md, test/poc/lane12/Lane12.t.sol',
 'PARTLY CURRENT-STATE','The v9 statement is an invariant. The HISTORICAL half is not closed: v8 and earlier did produce "finalized, unknown to messenger" objects (v8 reproduces it for 100 kB payloads) and REJ-2409 scanned `WithdrawalFinalized(success=false)` only for blocks 25,900,000..26,430,858 (one hit, no stranded value). Bedrock..25.9M on all four chains is open (PRIMITIVES A-068). Closure C6.')
fam('D05','Freeze or poison a victim\'s messenger withdrawal using the new v9 revert (pre-set failed/successful bit, sender-only check with a different target, L2CDM made to withdraw to an arbitrary target)',
 '0403 0405 0803 0806 0808 1203 2405 3108',
 'The first write to either messenger mapping for hash h needs `msg.sender == portal && portal.l2Sender() == L2CDM`, i.e. the victim\'s own withdrawal; the live L2CDM (2.2.1) hard-wires the withdrawal target to the L1CDM and refuses to relay to itself or the message passer.',
 'test/poc/lane04 Fab.t.sol::test_cond_*, L2Side.t.sol; lanes/LANE-08-report.md; mirror/lane-24',
 'PARTLY CURRENT-STATE','"sender == L2CDM implies target == L1CDM" was checked against the LIVE L2CDM only. Withdrawals created by earlier L2CDM versions and legacy withdrawals re-encoded by the Bedrock migration were not enumerated (PRIMITIVES A-017). Closure C7.')
fam('D06','Gas-budget mismatches make in-flight withdrawals unfinalizable or lossy (old L2 baseGas vs v9 L1 reserves, 183,600 new-account reserve, payload copied before the gas check, deeper pause resolution, 63/64 starvation, large-calldata deposit regression)',
 '0304 0406 0408 0605 0801 0805 0807 1102 1103 1201 1209 2401 2406 3005 3106 3107 3206',
 '`SafeCall.callWithMinGas` forwards `gas()` (v9 src/libraries/SafeCall.sol:162): the withdrawal gasLimit is a floor, so more transaction gas always reaches the callee; every under-gassed path reverts (retry) or records a replayable failure; measured margins stay positive up to minGasLimit 5.76M (old budget) / 7.3M (live budget).',
 'evidence/lane08/measure_tables.md, evidence/lane04-forge-isolate-output.txt, evidence/lane11/injected-gas-*.json, mirror/lane-31/DIFFERENTIAL_RESULTS.md',
 'RULE-SET-DEPENDENT','Not historical: holds under today\'s L1 gas rules. Open only for the EIP-7825 per-transaction cap band (lead L5) and for Amsterdam activation before the L2 messenger is upgraded; older budget generations (pre-v3.0.0 formula, version-0 withdrawals) are the same question (PRIMITIVES A-018).')
fam('D07','ETH conservation between portal, lockbox and messenger breaks (donations spent, relock skipped or over-swept, pause duplicates/strands value, deposit mints more than it locks, CGT mode, pre-meter lockbox call, U21 left value in the wrong contract, unbacked ETH before pooling)',
 '0303 0305 0307 0310 0311 0407 1005 1208 2302 2303 2304 2306 2307 2906 3002',
 'Finalization unlocks and forwards exactly `_tx.value` and re-locks exactly `_tx.value` on a failed non-messenger call (v9 src/L1/OptimismPortal2.sol:614,627,661-665); the only read of `address(this).balance` is owner-only `migrateLiquidity`; from the U21 block to the fork block lockbox delta == sum(ETHLocked) - sum(ETHUnlocked).',
 'test/poc/lane03 (test_A_*, test_D_*, testFuzz_F_sequenceConservation), evidence/lane03/reconcile_u21_window.json, mirror/lane-23/',
 'CURRENT-STATE-ONLY (0305, 0407, 2303, 2906); rest INVARIANT','The four state-based rejections only show that portals hold 0 and lockboxes are funded at N-1/N/26433900. They do not show that each lockbox balance covers the chain\'s L2 liability: the U16 sweep (`portal.migrateLiquidity()`, v4.0.0 src/L1/OPContractsManager.sol:736) merged all pre-lockbox surplus and deficits into one number (PRIMITIVES A-011, lead L9). Closure C3.')
fam('D08','Lockbox authority abuse (portal unlocking another chain\'s ETH, withdrawal targeting a lockbox or sibling portal, fake same-owner proxy, sibling-path bypass, shared-pool drain, proof reuse across portals, portal alias on L2)',
 '0308 0410 0901 0902 0903 1003 2305 2901 2902 2904 2905 3003 3203',
 '`unlockETH` requires an authorised portal whose `l2Sender()` is the default, i.e. it cannot be reached from a withdrawal callback (v9 src/L1/ETHLockbox.sol:157-178); `_isUnsafeTarget` blocks the portal and its current lockbox; the authorisation cross product over 4 chains + Base is diagonal; super-root proofs are bound by `rootClaimByChainId(systemConfig.l2ChainId())`.',
 'test/poc/lane09/, evidence/lane09-lockbox-auth-events-22990500-26433904.json, mirror/lane-29/LIVE_STATE.md',
 'CURRENT-STATE-ONLY (0308, 0901); rest INVARIANT','The diagonal matrix is a read of today\'s mappings plus one public RPC\'s event history for the four current lockboxes. Lockboxes that older OPCM generations could have deployed ("ETHLockbox-U16a", "-Interop") and a second log source were not checked (PRIMITIVES A-014). Closure C9.')
fam('D09','Proof deletion or proof bookkeeping harms an honest withdrawal (delete a proof that could finalize, front-run finalize, delete while paused, array desync/DoS, attacker proof selected, non-game address stored, retired proofs undeletable, existing exploitable proof/game pairs)',
 '0501 0502 0503 0506 0507 1204 2501 2502 2503 2504 2506 2507 2509 2510 3102 3202',
 'Delete predicate = `game.status() == CHALLENGER_WINS || currentRegistry.isGameBlacklisted(game)` (v9 src/L1/OptimismPortal2.sol:718-723); both are permanent and disjoint from `isGameClaimValid`; proofs are keyed by (hash, submitter), finalization names the submitter, nothing iterates `proofSubmitters`.',
 'test/poc/lane05/Lifecycle.t.sol, mirror/lane-25/ ProofLifecycle.t.sol, evidence/lane05-*.json',
 'CURRENT-STATE-ONLY (0507, 2506, 2510); rest INVARIANT','The survey covered 44 proofs from blocks 26,425,493+ and assumed every stored game is a current-ABI factory clone. Proof cells written under v1.4.0..v3.x (games of registries 0x18DAc71c… / 0x1c68ECfb…) were never read or pushed through v9 (PRIMITIVES A-021, A-074). Closure C4.')
fam('D10','Proofs or failed messages created under v8 are lost, corrupted or double-usable under v9; current registry change strands old proofs',
 '0409 2407 2505',
 'A withdrawal proven under v8 (block 26,377,651) finalized under v9 on chain (block 26,432,294); a v8 failed message replays exactly once after the real U21 transaction is replayed in-process.',
 'test/poc/lane04/CrossVersion.t.sol, mirror/lane-24/REAL_WITHDRAWAL_EVIDENCE.md, mirror/lane-25/CHAIN_READS.md',
 'BOUNDARY-SPECIFIC','Proves v8 -> v9 only. Every older boundary (v1.3 -> v1.4 portal swap, v3 -> v4 registry move, v6 -> v7 registry-binding removal) is PASS B.')
fam('D11','The pause-identifier move to the lockbox drops an active pause, resurrects an old one, leaves a value path un-paused, or breaks an un-upgraded dependent',
 '0107 0108 0207 0601 0602 0906 1104 1202 1205 2204 2601 2605 2606 3103',
 'On all four chains ETH_LOCKBOX was already true and `portal.ethLockbox()` already the same address at N-1, so the effective identifier did not change; `pauseTimestamps` is 0 for address(0), the four portals and the four lockboxes; with the lockbox identifier paused every prove/finalize/relay/bridge-finalize/unlock/WETH-withdraw reverts.',
 'test/poc/lane06/PauseMatrix.t.sol, evidence/lane06/state-pre-26430858.txt, mirror/lane-22/PAUSE_AND_AUTHORIZATION_MAPPINGS.md, mirror/lane-26/',
 'CURRENT-STATE-ONLY','All of it rests on "nothing is paused now and the identifier was already the lockbox". Past Paused events, expired-not-reset timestamps, chains that used the portal identifier (v4.1.0..v8.0.0 without lockbox) and consumers that never left the generation-1 global pause (legacy DelayedWETH; registry 0x1c68ECfb… has no pause check) are untouched (PRIMITIVES A-005, A-028). Closure C8.')
fam('D12','A feature flag, l2ChainId or resource config can be moved by a non-privileged actor, or re-migration / chain-id aliasing corrupts the shared set',
 '0603 0604 1207 2602 2603 2604 3204 3205',
 '`setFeature` starts with `_assertOnlyProxyAdminOrProxyAdminOwner()` (v9 src/L1/SystemConfig.sol:534); `l2ChainId` and the resource config are written only by the gated reinitializer; the migrator rejects zero/duplicate/unordered chain ids and an already-set INTEROP flag.',
 'test/poc/lane06/FeatureMachine.t.sol, mirror/lane-26/, mirror/lane-32/ NegativeSpace.t.sol',
 'INVARIANT (value provenance is historical)','Authorization is code. The VALUE of l2ChainId was written once by the v4.0.0 `upgrade()` from the permissioned game\'s immutable (PRIMITIVES A-031): correct on the four chains today, never checked for other OPCM-upgraded chains.')
fam('D13','Dispute-game domain: proof-type confusion, cross-factory or cross-registry game reuse, duplicate/foreign chain ids winning, old or unset-type games usable, anchor injection, tx.origin hijack, liveness cliff, in-flight games or bonds broken by the singleton swap, retroactive prestate change, ZK parent omission',
 '0109 0701 0702 0703 0704 0706 0707 1002 2105 2701 2702 2703 2704 2706 3001 3004 3207',
 'One prove function branches on the registered game\'s own `gameType()`; games are taken by index from the portal\'s own factory and re-checked by `isGameClaimValid`; the kona program copies the chain list from the agreed pre-state; clone args are fixed at creation; 60/60 sampled in-flight games resolve and pay after U21; the full OP Mainnet census (11,629 games) has one third-party claim-valid game whose root matches the L2 header.',
 'test/poc/Lane07_Probes.t.sol, evidence/op-mainnet-games-census.txt, mirror/lane-27/, mirror/lane-30/, lanes/LANE-07-report.md',
 'CURRENT-STATE-ONLY (0704, 2703, 2704, 2706); rest INVARIANT','"Today\'s factory args point at the same registry" and "sampled roots match" are reads of the present OP Mainnet state. History matters here: the registry-binding check was removed at v7.0.0 and every factory holds games of three registries (PRIM-W0-01). W0 closed that half for OP/Ink/Unichain/Soneium (implementation history: no implementation bound to a superseded registry was live after the current registry\'s retirement). Still open: game census of Ink/Soneium/Unichain and recomputation of the ~10.2k official claim-valid roots per implementation generation (PRIMITIVES A-001, A-002). Closures C11, C12, C13.')
fam('D14','Pre-positioning against the planned migrate (CREATE2 squatting, pre-registered games, surviving proofs, ETH donations, non-atomic or permissionless migration, missing code-length check)',
 '0505 0705 0708 0904 0905 2108 2309 2705 2903 3208',
 'The real flow runs by DELEGATECALL from the ProxyAdmin-owner Safe (v9 src/L1/opcm/OPContractsManagerUtilsCaller.sol:257), so the CREATE2 deployer is the Safe and the salt mixes `block.timestamp`; migrate deploys a net-new factory and registry whose `retirementTimestamp` is the migration time; everything happens in one transaction.',
 'test/poc/lane09/, test/poc/Lane07_Migration.t.sol, evidence/lane09-migrate-op-unichain-trace.txt, mirror/lane-27/MIGRATION_MODEL.md',
 'FUTURE-ACTION','Depends on the planned calldata, not on history. Only residue reopens it: pre-U16 objects (legacy registries that mirror portal getters, legacy WETH) crossing the migration (PRIMITIVES A-035, PRIM-W0-02). Closures C10, C14.')
fam('D15','Scope claims: the live registry, DelayedWETH or sibling-chain proxies are explicitly listed Immunefi assets',
 '3301 3302 3303',
 'The listed registry is 0x18DAc71c… and the listed DelayedWETH is 0xE497B094…; the live proxies are 0x23B2C629… and 0x1b6dBF05…; no Ink/Soneium/Unichain row exists.',
 'mirror/lane-33/SCOPE_SNAPSHOT.md, SCOPE.md',
 'SCOPE FACT','W0 lineage note: the two LISTED addresses are exactly the generation-1 registry (version() "2.0.0", still deployed) and the generation-1 DelayedWETH (1.0.0, still holding bonds) — legacy objects in the lineage, not typos.')
assigned=[i for f in F for i in f['ids']]
dup=[i for i in set(assigned) if assigned.count(i)>1]
missing=sorted(set(allr)-set(assigned)); extra=sorted(set(assigned)-set(allr))
print(len(allr),len(assigned),'dup',dup,'missing',missing,'extra',extra)
m=['# DEAD ENDS — DO NOT REDO (PASS A rejections condensed)\n',
'Worker W0. Source: the 180 files in `/home/user/Tracking_Body/optimism-u21-novel-hunt/rejected/` (paths below are relative to that workspace). '
'Each family lists the single killing fact, where the evidence is, and whether the kill rests on **current state only**. '
'A family marked CURRENT-STATE-ONLY, PARTLY CURRENT-STATE, BOUNDARY-SPECIFIC or EXTENDED-BY-W0 says nothing (or only something bounded) about objects created under older releases: those are **reopenable by PASS B**, and the last column says exactly along which edge. '
'INVARIANT families are killed by code that W0 traced through the historical trees; do not re-walk them without a new precondition.\n',
'| Family | PASS A rejections | Reopenable by PASS B? |','|---|---|---|']
for f in F: m.append(f"| {f['code']} {f['title'][:70]}… | {len(f['ids'])} | {f['reopen']} |")
m.append('')
for f in F:
    m.append(f"## {f['code']} — {f['title']}\n")
    m.append('**Rejections ('+str(len(f['ids']))+'):** '+', '.join('REJ-'+i for i in f['ids'])+'\n')
    m.append('**Killing fact:** '+f['kill']+'\n')
    m.append('**Evidence:** '+f['evidence']+'\n')
    m.append('**State dependence:** '+f['reopen']+'\n')
    m.append('**What it does not cover / reopen edge:** '+f['why']+'\n')
m.append('## Dead ends added by W0\n')
m.append('- **REJ-W0-01** (`rejected/REJ-W0-01.md`): "a legacy message blocked before Bedrock becomes relayable because Bedrock dropped `blockedMessages`" — killed: zero `MessageBlocked`/`MessageAllowed` logs on the OP Mainnet L1CDM over its whole pre-Bedrock life (L1 blocks 12,686,000..17,430,000).\n')
open(OUT+'DEAD-ENDS-NO-REDO.md','w').write('\n'.join(m)+'\n')
