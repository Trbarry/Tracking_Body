import sys, json, csv, importlib, collections
sys.path.insert(0,'.')
import h
MODS=['01_bedrock_early','02_bedrock_tob_sherlock','03_scc_mcp_fp','04_fault_proofs','05_pause_u13_interop','06_u16_to_u20','07_u21_interopl2_misc']
mods=[importlib.import_module(m) for m in MODS]
R=h.RECS
def rec(rep,fid):
    for r in R:
        if r['report']==rep and r['finding_id']==fid and 'duplicate of' not in r['title']: return r
    raise KeyError((rep,fid))
# ---- patches / code-verified annotations ----
for r in R:
    for k in ('later_releases_that_retouch_root_cause','residual_assumptions','fix_strategy'):
        r[k]=r[k].replace('150k reserve','135k reserve + 15k check buffer (op-v9.0.0 GasConstants.sol:60,75)').replace('raises reserve to 150k','raises L1 reserve to 135k + 15k buffer')
    if r['report']=='2023_01-Bedrock-Sherlock-contest' and r['status']=='fixed':
        r['fix_strategy']+=' [fix as OBSERVED in hist/v1.0.0 code, not quoted from the judging README]'
rec('2023_01-Bedrock-Sherlock-contest','M-10')['status']='disputed'
rec('2023_01-Bedrock-Sherlock-contest','M-10')['fix_strategy']='sponsor: known/expected; v1.0.0 L2OutputOracle.deleteL2Outputs nevertheless requires "cannot delete outputs that have already been finalized" (hist/v1.0.0 contracts/L1/L2OutputOracle.sol deleteL2Outputs)'
rec('2025_03-Interop-Portal-Wonderland','I-4')['residual_assumptions']='at v9 ETHLockbox.unlockETH requires sender.l2Sender()==DEFAULT_L2_SENDER (op-v9.0.0 ETHLockbox.sol:169) i.e. portal not mid-withdrawal; lockETH (ETHLockbox.sol:144-147) has no such guard, so a deposit can be made from inside a withdrawal'
rec('2025_03-Interop-Portal-Wonderland','L-2')['later_releases_that_retouch_root_cause']='VERIFIED fixed by v4.0.0: hist/v4.0.0 OptimismPortal2.sol:679 re-locks on failed call; kept at op-v8.0.0:622 and op-v9.0.0:663'
rec('2025_03-Interop-Portal-Wonderland','L-2')['status']='fixed'
rec('2025_03-Interop-Portal-Wonderland','L-2')['fix_strategy']='re-lock ETH on failed call (status not stated in report; fix OBSERVED in hist/v4.0.0 OptimismPortal2.sol:679)'
a=rec('2025_04-Interop-Portal-Cantina-contest','3.2.9')
a['later_releases_that_retouch_root_cause']='VERIFIED IN CODE: asr==address(this) check present in hist/v4.0.0, v4.1.0, v5.0.0 AnchorStateRegistry.sol:182-200 and hist/v6.0.0:196-214 (ASR 3.5.0-3.7.0); ABSENT in op-v7.0.0:216-226, op-v8.0.0:216-226 (ASR 3.9.0) and op-v9.0.0:227-237 (ASR 4.0.0; removal documented in the NatSpec at :217-222). Games snapshot wasRespectedGameTypeWhenCreated from THEIR OWN registry (op-v9.0.0 FaultDisputeGame.sol:318-319, SuperFaultDisputeGame.sol:339-340, SuperPermissionedDisputeGame.sol:69); ASR.isGameRespected only reads that flag (op-v9.0.0 AnchorStateRegistry.sol:242-247).'
b=rec('2026_06-OPCMv2-Cantina','3.3.12')
b['later_releases_that_retouch_root_cause']=a['later_releases_that_retouch_root_cause']+' On-chain at L1 block 26433900 (local fork :8545): OP Mainnet DGF 0xe5965Ab5… registers only types 5 and 9, both gameArgs embed ASR 0x23B2C629…D113 == portal.anchorStateRegistry(); ASR.retirementTimestamp = 1753379243 (2025-07-24) i.e. never advanced since.'
c=rec('2026_05-U19-Cantina','3.3.1')
c['later_releases_that_retouch_root_cause']+=' VERIFIED: op-v9.0.0 AnchorStateRegistry.initialize writes respectedGameType on EVERY re-initialize (:109) but sets retirementTimestamp only when it is 0 (:130-132); OPCMv2 accepts instruction overrides.cfg.startingRespectedGameType (op-v9.0.0 OPContractsManagerV2.sol:370,663-667,957). OP Mainnet: respectedGameType()=9, retirementTimestamp()=1753379243 at block 26433900.'
rec('2023_12-SuperchainConfigUpgrade-Trust','TRST-H-1')['later_releases_that_retouch_root_cause']+=' VERIFIED at v9: guard kept (op-v9.0.0 CrossDomainMessenger.sol __CrossDomainMessenger_init: "if (xDomainMsgSender == address(0))"; relayMessage asserts successfulMessages==false after the call); portal l2Sender written only if zero (op-v9.0.0 OptimismPortal2.sol:297-299).'
rec('2023_12-SuperchainConfigUpgrade-Trust','TRST-L-2')['later_releases_that_retouch_root_cause']+=' VERIFIED at v9: op-v9.0.0 ResourceMetering.sol:168-172 only initialises when params.prevBlockNum == 0.'
rec('2023_12-SuperchainConfigUpgrade-Trust','TRST-M-1')['later_releases_that_retouch_root_cause']='VERIFIED at v9: reentrant-relay branch unchanged (op-v9.0.0 CrossDomainMessenger.sol relayMessage: "|| xDomainMsgSender != Constants.DEFAULT_L2_SENDER" => failedMessages=true, return); portal NoReentrancy (OptimismPortal2.sol:594-596) blocks only finalize-inside-finalize, not finalize-inside-a-direct-replay on L1CDM. Griefing remains live by design.'
rec('2023_01-Bedrock-Sherlock-contest','H-3')['later_releases_that_retouch_root_cause']+=' VERIFIED: v1.0.0 relayMessage has no nonReentrant and no pause (hist/v1.0.0 contracts/universal/CrossDomainMessenger.sol relayMessage; PausableUpgradable reduced to spacers :61-71); v1.2.0 adds require(paused()==false) (hist/v1.2.0 src/universal/CrossDomainMessenger.sol:224); v9 portal REVERTS when the messenger call fails for L2CDM-originated withdrawals (op-v9.0.0 OptimismPortal2.sol:638-653) — the Bedrock rule "portal always finalizes" is inverted for messenger withdrawals.'
rec('2023_01-Bedrock_Updates-TrailOfBits','TOB-OPTCW-1')['later_releases_that_retouch_root_cause']+=' VERIFIED: v1.0.0 gate at hist/v1.0.0 contracts/L1/OptimismPortal.sol:277-280; v1.4.0 OptimismPortal2 stores provenWithdrawals[withdrawalHash][msg.sender] (hist/v1.4.0 src/L1/OptimismPortal2.sol:318-327) with no re-prove gate; same at op-v9.0.0 OptimismPortal2.sol:483-487. Legacy single-key mapping is spacer_52_0_32 at v9 (:67).'
rec('2024_08-Fault-Proofs-No-MIPS-Spearbit','5.1.1')['later_releases_that_retouch_root_cause']+=' VERIFIED: no _requiredGas in hist/v1.4.0 PreimageOracle.sol; present from hist/v1.6.0; op-v9.0.0 PreimageOracle.sol:402-432.'
rec('2024_08-Fault-Proofs-No-MIPS-Spearbit','5.2.2')['later_releases_that_retouch_root_cause']+=' VERIFIED NOT FIXED at v9: op-v9.0.0 FaultDisputeGame.sol challengeRootL2Block (:655-691) checks only status==IN_PROGRESS and !l2BlockNumberChallenged; no resolvedSubgames[0] check.'
rec('2026_05-U19-Cantina','3.2.10')['later_releases_that_retouch_root_cause']+=' VERIFIED NOT FIXED at v9: op-v9.0.0 PermissionedDisputeGame.sol has no challengeRootL2Block override (only step/move carry onlyAuthorized :46,:65; initialize tx.origin check :75).'
rec('2026_01-U18-Cantina','3.1.1')['later_releases_that_retouch_root_cause']+=' VERIFIED NOT FIXED at v9: op-v9.0.0 DisputeGameFactory.sol:302 (2-arg overload) does not touch gameArgs; :312-314 (3-arg) sets them.'
rec('2025_09-U16a-Spearbit','5.1.3')['later_releases_that_retouch_root_cause']='VERIFIED: v4.1.0 setFeature has no pause check (hist/v4.1.0 SystemConfig.sol setFeature); v5.0.0-v8.0.0 revert when paused() ("Lockbox can\'t be set or unset if the system is currently paused"); v9 forbids disabling ETH_LOCKBOX and refuses enabling while superchainConfig.paused(optimismPortal()) (op-v9.0.0 SystemConfig.sol setFeature). paused(): v4.0.0 = paused(lockbox)||paused(0); v4.1.0-v8.0.0 = paused(0)||paused(feature? lockbox : portal); v9 = portal.ethLockbox().paused().'
rec('2025_09-U16a-Spearbit','5.1.3')['status']='acknowledged'
rec('2025_05-Interop-Portal-Spearbit','5.1.3')['later_releases_that_retouch_root_cause']+=' VERIFIED at v9: migrateToSharedDisputeGame calls _assertNotPaused() (op-v9.0.0 OptimismPortal2.sol:537); initialize() (:273-302) can still replace ethLockbox when a non-zero value is passed and is NOT pause-gated (access: proxy admin / owner).'
rec('2025_04-Interop-Portal-Cantina-contest','3.1.5')['later_releases_that_retouch_root_cause']+=' VERIFIED NOT FIXED at v9: proveWithdrawalTransaction (op-v9.0.0 OptimismPortal2.sol:390-490) never reads finalizedWithdrawals.'
rec('2026_05-U19-Cantina','3.3.2')['later_releases_that_retouch_root_cause']+=' VERIFIED at v8/v9: rootClaimByChainId only for super games (op-v8.0.0 OptimismPortal2.sol:422-427, op-v9.0.0:437-442).'
rec('2024_03-FaultProofs-Sherlock-contest','M-1')['later_releases_that_retouch_root_cause']+=' VERIFIED: raw() returns uint32 at hist/v1.4.0 LibUDT.sol:231 and op-v9.0.0 LibUDT.sol:224.'
rec('2023_03-Bedrock-Sherlock-fix-review','H-2')['later_releases_that_retouch_root_cause']+=' VERIFIED at v9: legacy spacers kept (op-v9.0.0 CrossDomainMessenger.sol:21-78), successfulMessages :122, v0-hash check in relayMessage (:229-232).'
rec('2025_05-Interop-Portal-Spearbit','5.3.6')['later_releases_that_retouch_root_cause']+=' VERIFIED at v9: spacer_52_0_32 (legacy provenWithdrawals), spacer_53_*, spacer_54, spacer_56_0_20 (disputeGameFactory), spacer_58_0_32 (blacklist mapping), spacer_59_0_4/59_4_8 (respectedGameType/UpdatedAt), spacer_61, spacer_63_20_1 (superRootsActive) remain reserved (op-v9.0.0 OptimismPortal2.sol:67-132).'
VOCAB={
 'ACCESS_CONTROL_MISSING':'a state-changing or value-releasing entrypoint lacks (or mis-resolves) its caller check',
 'INPUT_VALIDATION_MISSING':'attacker- or operator-supplied value is not range/format/identity checked on-chain (includes validator-script gaps)',
 'INVERTED_OR_WRONG_CONDITION':'a comparison, ordering or boolean predicate is wrong',
 'REENTRANCY_STATE_CLOBBER':'re-entry (or nested finalize/relay) clobbers a sentinel such as l2Sender / xDomainMsgSender or uses it as a guard incorrectly',
 'GAS_ACCOUNTING':'min-gas / 63-64 / reserve / base-gas computations that decide whether a non-replayable step records its outcome',
 'REPLAY_OR_DOUBLE_SPEND':'one economic object can be proven/relayed/finalized more than once or re-armed',
 'INITIALIZATION':'initializer / reinitializer / implementation-initialisation problems, including re-running initialize on live state',
 'UPGRADE_STORAGE_LAYOUT':'slot layout, gaps, spacers, immutables<->storage moves',
 'UPGRADE_SEQUENCING':'ordering, atomicity, skip paths and tooling (OPCM / scripts / validators) of an upgrade or migration',
 'PAUSE_COVERAGE':'what the pause covers, which identifier/pointer decides it, and paths that escape or silently lift it',
 'PROOF_VERIFICATION':'binding between a withdrawal proof, an output/super root, a chain id, a game and a registry',
 'DISPUTE_GAME_LOGIC':'clock, bond, move/step/resolve mechanics inside a game',
 'ANCHOR_STATE':'what the anchor is, who can set it and how it is (re)interpreted',
 'GAME_TYPE_LIFECYCLE':'respected game type, retirement timestamp, blacklist and their cut-overs',
 'VM_SEMANTICS':'on-chain MIPS/MIPS64 step vs spec vs off-chain Cannon divergence',
 'PREIMAGE_ORACLE':'PreimageOracle key/part integrity',
 'DERIVATION_CONSENSUS':'op-node / op-geth / kona derivation or execution divergence, including proof-program panics',
 'DOS_RESOURCE':'griefing, unbounded work, liveness of nodes or of a function',
 'ACCOUNTING_CONSERVATION':'ETH/token custody not matching liabilities, stranded or duplicated value',
 'CROSS_DOMAIN_IDENTITY':'who the sender/creator is across domains or call layers (aliasing, tx.origin, msg.sender through factories)',
 'TOKEN_SEMANTICS':'non-standard tokens, token-pair identity, mint/burn vs escrow branch',
 'SIGNATURE_REPLAY':'signed-message domain separation',
 'STALE_STATE_AFTER_MIGRATION':'an object created under release N keeps living and is read, mis-read or orphaned by release N+k',
 'CONFIG_TRUST':'safety delegated to a privileged/off-chain input (deploy input, anchor, prestate, guardian, dependency set)',
 'SPEC_MISMATCH':'code vs specification/documentation difference without a direct exploit',
}
used=set(r['root_cause_class'] for r in R); assert used<=set(VOCAB), used-set(VOCAB)
PAGES={'2022_05-Bedrock_Contracts-Zeppelin':19,'2022_08-Bedrock_GoLang-SigmaPrime':29,'2022_09-Bedrock_and_Periphery-Zeppelin':29,'2022_11-Invariant_Testing-TrailOfBits':35,'2022_12-DepositTransaction-RuntimeVerification':13,'2023_01-Bedrock_Updates-TrailOfBits':26,
'2023_12-SuperchainConfigUpgrade-Trust':23,'2024_02-MCP_L1-Cantina':11,'2024_03-FaultProofs-Sherlock-contest':60,'2024_08-Fault-Proofs-MIPS-Cantina':11,'2024_08-Fault-Proofs-No-MIPS-Spearbit':24,'2024_10-Cannon-FGETFD-3DocSecurity':'md','2024_12-DPM-MiloTruck':11,'2024_12-DPM-RadiantLabs':8,
'2025_01-IRI-OffbeatLabs':9,'2025_01-MT-Cannon-Base':7,'2025_01-MT-Cannon-Spearbit':11,'2025_02-Upgrade13-Spearbit':16,'2025_03-Interop-Contracts-Spearbit':21,'2025_03-Interop-Portal-Wonderland':8,'2025_04-Interop-Portal-Cantina-contest':38,'2025_04-op-program-blob-handling-aleph_v':2,
'2025_05-Cannon-Go-Updates-Coinbase':3,'2025_05-Interop-Portal-Spearbit':13,'2025_05-Upgrade16-Spearbit':14,'2025_06-Cannon-3DOC':9,'2025_06-Cannon-fix-review-Spearbit':6,'2025_07-VerifyOPCM-Spearbit':6,'2025_09-U16a-Spearbit':12,'2025_10-U17-Spearbit':8,'2025_11-Custom-Gas-Token-Spearbit':14,
'2026_01-U18-Cantina':9,'2026_03-Kona-Cantina':50,'2026_05-U19-Cantina':13,'2026_06-Interop-L2-Contracts-Cantina':18,'2026_06-OPCMv2-Cantina':13,'2026_08-U20-Cantina':14,'2026_11-U21-Cantina':26,
'2023_01-Bedrock-Sherlock-contest':'external repo (README.md 3814 lines)','2023_03-Bedrock-Sherlock-fix-review':'external repo (README.md)'}
INFO={}
for m in mods:
    INFO.update(getattr(m,'INFO',{}))
INFO.update({'2022_05-Bedrock_Contracts-Zeppelin':'Low L-01 and Notes N-01..N-10 (10) not recorded','2022_08-Bedrock_GoLang-SigmaPrime':'Informational 3 (OPB-12..OPB-14) not recorded',
 '2023_01-Bedrock-Sherlock-contest':'25 "S" (specification) issues: 2 recorded (S-7, S-24), 23 counted only','2023_03-Bedrock-Sherlock-fix-review':'all 9 final issues recorded','2023_12-SuperchainConfigUpgrade-Trust':'1 additional recommendation not recorded',
 '2024_02-MCP_L1-Cantina':mods[2].MC_INFO,'2024_03-FaultProofs-Sherlock-contest':'4 final Mediums recorded; 16 of 31 excluded submission families recorded as fam-*; 15 families by title only (see ext/2024-02-optimism-2024-judging)',
 '2022_11-Invariant_Testing-TrailOfBits':'1 finding; invariant tables p11-24 not recorded','2023_01-Bedrock_Updates-TrailOfBits':'single finding','2025_03-Interop-Contracts-Spearbit':mods[4].IC_INFO,'2025_11-Custom-Gas-Token-Spearbit':mods[5].CG2_INFO,
 '2025_05-Upgrade16-Spearbit':'same 14 findings as 2025_05-Interop-Portal-Spearbit; 8 cross-referenced','2025_09-U16a-Spearbit':'Info not recorded: 5.2.2, 5.2.4, 5.2.7','2025_07-VerifyOPCM-Spearbit':'all 3 recorded'})
rec('2025_01-IRI-OffbeatLabs','L-01')['tests_added']='fuzz test that closeGame() either reverts or updates the anchor state; semgrep rule forcing try/catch blocks to be marked EIP-150 safe (PR 14144)'
rec('2025_02-Upgrade13-Spearbit','5.2.6')['tests_added']='fuzz test + semgrep rule (PR 14144)'
rec('2026_11-U21-Cantina','3.1.17')['tests_added']='planned ("tests are to be added next to the existing ASR-RGT cases"), not part of the audited release'
INFO.setdefault('2022_12-DepositTransaction-RuntimeVerification','formal verification report: 0 severity-rated findings; 2 minor spec deviations in the metered modifier (p11) and gas notes')
cnt=collections.Counter(r['report'] for r in R)
reports=[]
for k,v in h.REPORTS.items():
    reports.append(dict(report=k,pages=PAGES.get(k,'?'),audited_commit=v.get('commit'),scope=v.get('scope'),explicit_out_of_scope=v.get('oos'),findings_recorded=cnt.get(k,0),not_recorded_individually=INFO.get(k,'')))
reports.append(dict(report='2022_12-DepositTransaction-RuntimeVerification',pages=13,audited_commit='not stated (README: -> op-contracts/v1.0.0)',scope='KEVM/Foundry proof that OptimismPortal.depositTransaction always emits the correct TransactionDeposited event (p4-10)',explicit_out_of_scope='metered modifier excluded from the proofs; deployment process; "excluding a number of components critical to the correct operation of this system" (p3,10)',findings_recorded=0,not_recorded_individually=INFO['2022_12-DepositTransaction-RuntimeVerification']))
reports.append(dict(report='2024_02-Kontrol-pausability-RuntimeVerification',pages='external README (raw.githubusercontent.com, commit 876e16ad04968f0bb641eb76f98eb77e7e1a3e16)',audited_commit='876e16ad04968f0bb641eb76f98eb77e7e1a3e16 (test/kontrol)',scope='Kontrol proofs prove_*_paused: OptimismPortal.proveWithdrawalTransaction / finalizeWithdrawalTransaction and L1CrossDomainMessenger.relayMessage (and bridge finalize functions) revert when SuperchainConfig is paused; bounded: bytes[] proof length 0..10 of 600 bytes; KontrolDeployment must stay in sync with Deploy.s.sol',explicit_out_of_scope='everything except "reverts when paused" for the listed entrypoints at that commit (L2OutputOracle-era portal); no OptimismPortal2, no lockbox, no identifier-based pause',findings_recorded=0,not_recorded_individually='verification artefact, no findings'))
for k in ('2024_10-Cannon-FGETFD-3DocSecurity','2025_05-Cannon-Go-Updates-Coinbase'):
    pass
NON=mods[-1].NONMAND
out=dict(
 meta=dict(worker='F3',generated='2026-11-17',corpus='/home/user/ethereum-optimism/audits-txt (49 PDFs as text + README.md + 2024_10 md) and ext/2023-01-optimism-judging, ext/2023-03-optimism-judging, ext/2024-02-optimism-2024-judging',
  severity_current_mapping_legend={'Critical':'would map to an Immunefi Critical impact (theft / permanent freeze / insolvency, excluding bonds and fee vaults) IF it were live and unknown','High':'Immunefi High (temporary freeze; incorrectly proven withdrawal mitigated by delay; incorrectly resolved game not detected by op-dispute-mon allowing invalid withdrawal; DLT: sequencer theft / total shutdown / freeze needing hardfork)','Medium':'Immunefi Medium (incorrectly resolved game detected / not allowing withdrawal; bond withdrawal; fee-vault theft; L2 tx confirmation halt with forced inclusion)','None':'below the programme threshold, privileged-only, self-harm, bond-only griefing, tooling/validator-only, or an explicitly known/out-of-scope class. NOTE: the mapping describes the impact class of the finding AS REPORTED; every finding here is KNOWN and therefore not reportable.'},
  root_cause_vocabulary=VOCAB,
  status_values=['fixed','acknowledged',"won't fix",'disputed','not stated'],
  reports=reports, non_mandatory_reports_counts_only=NON,
  not_retrieved=['Sherlock contest web pages audits.sherlock.xyz/contests/38, /63, /205 (not fetched; the judging repositories were cloned instead)','sherlock-audit/2023-01-optimism, 2023-03-optimism, 2024-02-optimism-2024 source snapshots (not cloned; only the *-judging repos)','Spearbit portfolio PDFs (May 2025, July 2025): not fetched from github.com (403 per MEGA_CONTEXT); the in-repo copies 2025_05-Upgrade16-Spearbit.pdf and 2025_07-VerifyOPCM-Spearbit.pdf were used','individual submission files inside the judging repos were only read for 11 families (titles for all)']),
 findings=R)
json.dump(out,open('../AUDIT-FINDINGS.json','w'),indent=1,ensure_ascii=False)
print('findings',len(R),'reports',len(reports))
print(collections.Counter(r['status'] for r in R))
print(collections.Counter(r['severity_current_mapping'] for r in R))
print(collections.Counter(r['root_cause_class'] for r in R).most_common())
