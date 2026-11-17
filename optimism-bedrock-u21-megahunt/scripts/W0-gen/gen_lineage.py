import json,sys
sys.path.insert(0,'/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/scripts/W0-gen')
from lineage_data import E
OUT='/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/'
ORDER=['v1.0.0','v1.1.0','v1.2.0','v1.3.0','v1.4.0','v1.5.0','v1.6.0','v1.8.0','v2.0.0','v3.0.0','v4.0.0','v4.1.0','v5.0.0','v6.0.0','v7.0.0','v8.0.0','v9.0.0']
SEMVER={
'OptimismPortal':['1.6.0','1.10.0','2.4.0','2.5.0','2.6.0','2.8.0','2.8.1-beta.1','2.8.1-beta.4','-','-','-','-','-','-','-','-','-'],
'OptimismPortal2':['-','-','-','-','3.10.0','3.10.0','3.11.0-beta.2','3.11.0-beta.6','3.13.0','3.14.0','4.6.0','5.0.0','5.1.1','5.2.0','5.6.1','5.8.0','6.1.0'],
'L1CrossDomainMessenger':['1.4.0','1.7.0','2.2.0','2.3.0','2.3.0','2.4.0','2.4.0','2.4.1-beta.2','2.5.0','2.6.0','2.9.0','2.10.0','2.11.0','2.11.0','2.11.1','2.11.1','2.13.0'],
'L1StandardBridge':['1.1.0','1.4.0','2.0.0','2.1.0','2.1.0','2.2.0','2.2.0','2.2.1-beta.2','2.2.2','2.3.0','2.6.0','2.7.0','2.8.0','2.8.0','2.8.2','2.8.2','2.8.2'],
'SystemConfig':['1.3.0','1.10.0','1.11.0','1.12.0','2.2.0','2.2.0','2.3.0-beta.2','2.3.0','2.4.0','2.5.0','3.4.0','3.7.0','3.11.0','3.13.1','3.14.2','4.0.0','4.3.0'],
'SuperchainConfig':['-','-','1.1.0','1.1.0','1.1.0','1.1.0','1.1.0','1.1.1-beta.1','1.2.0','1.2.0','2.3.0','2.3.0','2.4.0','2.4.0','2.4.2','2.4.3','2.5.0'],
'L2OutputOracle':['1.3.0','1.6.0','1.7.0','1.8.0','1.8.0','1.8.0','1.8.0','1.8.1-beta.2','-','-','-','-','-','-','-','-','-'],
'AnchorStateRegistry':['-','-','-','-','1.0.0','1.0.0','2.0.0','2.0.1-beta.4','2.2.2','2.2.2','3.5.0','3.5.0','3.5.0','3.7.0','3.9.0','3.9.0','4.0.0'],
'DisputeGameFactory':['?','0.0.6','0.0.8','0.0.8','1.0.0','1.0.0','1.0.0','1.0.1-beta.3','1.0.1','1.0.1','1.2.0','1.2.0','1.3.0','1.4.0','1.6.1','1.6.1','1.6.1'],
'DelayedWETH':['-','-','-','-','1.0.0','1.0.0','1.1.0','1.2.0-beta.3','1.3.0','1.3.0','1.5.0','1.5.0','1.5.0','1.5.0','1.5.1','1.5.1','2.0.0'],
'ETHLockbox':['-','-','-','-','-','-','-','-','-','-','1.2.0','1.2.0','1.2.0','1.2.0','1.3.1','1.3.1','2.0.0'],
'FaultDisputeGame':['-','0.0.11','0.0.24','0.0.24','1.2.0','1.2.0','1.3.0','1.3.1','1.4.1','1.4.1','1.7.0','1.7.0','1.8.0','1.8.0 (V2: 2.2.0)','2.4.2','2.4.2','2.4.2'],
'SuperFaultDisputeGame':['-','-','-','-','-','-','-','-','0.1.0-beta.0','0.1.0-beta.1','0.4.0','0.4.0','0.5.0','0.6.0','0.7.2','0.8.0','0.8.0'],
'L2CrossDomainMessenger':['1.4.0','1.6.0','1.9.0','2.0.0','2.0.0','2.1.0','2.1.0','2.1.1-beta.4','2.1.1-beta.8','2.2.0','2.2.0','2.2.0','2.2.0','2.2.0','2.2.1','2.2.1','2.4.0'],
'OPContractsManager(+V2)':['-','-','-','-','-','-','-','1.0.0-beta.20','1.6.0','1.9.0','2.4.0','3.2.0','4.2.0','6.0.0','V2 7.1.17','V2 8.0.1','V2 9.0.3'],
}
META={
 'worker':'W0','track':'A (blind)','generated':'2026-11-17',
 'method':'function bodies extracted per tag with comments stripped and whitespace/formatting normalised, then diffed tag-to-tag (scripts/W0-lin.py); storage layouts diffed from snapshots/storageLayout/*.json (present from v1.2.0); on-chain reads via cast at L1 block 26433900 (fork :8545) and the archive proxy :7545',
 'release_order_used':ORDER,
 'maintenance_tags':{'v2.1.0':'identical to v2.0.0 for every traced function (OPCM 1.6.0-no-superchain-upgrade)','v2.2.0':'identical to v2.0.0 for every traced function (OPCM 1.7.0)','v3.0.1':'identical to v3.0.0 for every traced function'},
 'tag_notes':['v1.0.0 keeps sources under contracts/, later tags under src/','v1.1.0 and v1.3.0 carry the "immutables -> storage" (MCP) form; v1.2.0 carries immutables + SuperchainConfig: the three tags are NOT a linear code history (v1.1.0 code looks like an early MCP branch, v1.2.0 like the extended-pause branch). Which of them was deployed where is F2/F5 territory.','OPCM source at v4.0.0 names its new proxies "…-U16" and v4.1.0 "…-U16a" (src/L1/OPContractsManager.sol:675,717,780,819 / :787,856,895): v4.0.0 = Upgrade 16, v4.1.0 = Upgrade 16a by the code\'s own labels. Other tag -> upgrade numbers are not asserted here.'],
 'semver_by_tag':{'columns':ORDER,'rows':SEMVER},
 'onchain_timeline_op_mainnet':[
  'L1CDM proxy 0x25ace71c… has no code at L1 block 12,686,000 and code at 12,690,000; version() == "1.4.0" (v1.0.0 Bedrock) from block <= 17,425,000',
  'ASR retirementTimestamp 1753379243 <-> L1 block 22,990,599 (cast find-block): U16 execution',
  'DisputeGameFactory 0xe5965Ab5… game 9827 (created 1753378031): FaultDisputeGame 1.4.1, anchorStateRegistry() = 0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b',
  'game 9828 (1753381655): FaultDisputeGame 1.7.0, anchorStateRegistry() = 0x23B2C62946350F4246f9f9D027e071f0264FD113 (current)',
  'respected implementation boundaries (bisection over indices 9828..21388): 12805 -> FDG 1.8.0 (1764096407, 2025-11-25); 14633 -> FDG 2.2.0 (1770668867, 2026-02-09, first gameArgs-based clone); 17905 -> type 8, FDG 2.4.2 (1782429263, 2026-06-26); 20095 -> type 9, SuperFaultDisputeGame 0.8.0 (1790269415, 2026-09-25)',
  'legacy registries still deployed: 0x18DAc71c228D1C32c99489B7323d441E1175e443 version() "2.0.0" (impl 0x1b5cc028…); 0x1c68ECfb… version() "2.2.2" (impl 0x7b465370…), portal() = 0xbEb5Fc57…, disputeGameFactory() = 0xe5965Ab5…, respectedGameType() = 9 (live value, resolved through the v9 portal getter), anchorGame() = 0x9C9ac0A342D68040fe44d61de897E30Ad1c57bC3',
  'ImplementationSet/ImplementationArgsSet history of the four factories, L1 blocks 19,800,000..26,433,900 (250 logs, 0 errors; evidence/W0/dgf-implementation-set-logs-19800000-26433900.json). OP Mainnet factory transactions (block, respected implementation version, registry the implementation is bound to): 19884592 FDG 1.2.0 -> 0x18DAc71c…; 20270847 1.2.0; 20723924 1.3.0; 21580854 1.3.1; 22182531 1.4.1 -> 0x1c68ECfb… (registry #2); 22339996 1.4.1; 22432368 1.4.1; 22990599 1.7.0 -> 0x23B2C629… (registry #3, the v4.0.0 "…-U16" proxies); 23491328 1.7.0; 23877377 1.8.0; 24421512 2.2.0 with gameArgs, type 8 first registered; 25397811 type 0 unset, type 8 FDG 2.4.2; 26048619 types 0/1/8 unset, type 5 SuperPermissioned 1.1.0 + type 9 SuperFault 0.8.0; 26430859 (U21) types 5 and 9 re-registered',
  'registry generations per chain (first implementation bound to each): Ink 0xde744491… -> 0x2fc99fd1… (22182531) -> 0xEe018bAf… (22990599); Unichain 0x318A642d… -> 0xD5D0e176… (22254924) -> 0x27Cf508E… (22990722); Soneium 0x61f89A38… -> 0x190B6ecE… (22182531) -> 0x48909289… (22990670). Only game types 0, 1, 8, 5, 9 were ever given an implementation on any of the four factories; implementations active at or after each current registry\'s retirement that are bound to another registry: 0 (evidence/W0/dgf-implementation-registry-binding.json)',
  'chain-specific extra transactions: Ink re-registered type 1 alone at block 25674914; Unichain re-registered type 5 alone at 26299517; Soneium never registered types 0, 8 or 9 (type 1 until 26048619, then type 5)',
  'fork test test/W0/W0Lineage.t.sol (deployed bytecode, block 26433900, no privileged prank): current registry isGameRegistered(game 9827 bound to 0x1c68ECfb…) == true; an arbitrary EOA moves the superseded registry\'s anchorGame with a current type-8 game',
  'eth_getLogs for MessageBlocked(bytes32) / MessageAllowed(bytes32) on 0x25ace71c… over L1 blocks 12,686,000..17,430,000 (475 calls of 10k blocks, positive control: 42 RelayedMessage logs in 14,000,000..14,009,999): 0 logs, 0 errors (evidence/W0/l1cdm-messageblocked-scan-12686000-17430000.json)'],
 'same_selector_changed_meaning':[
  'proveWithdrawalTransaction(tx, uint256, proof, bytes[]): 2nd argument L2OutputOracle index -> DisputeGameFactory index (v1.4.0)',
  'finalizeWithdrawalTransaction(tx): self-contained -> wrapper over any-submitter ExternalProof (v1.4.0); failed call consumes (<= v8) -> reverts for messenger withdrawals (v9)',
  'depositTransaction: aliasing predicate tx.origin -> EOA.isSenderEOA incl. EIP-7702 (v2.0.0); ETH sink portal -> lockbox (v4.0.0)',
  'donateETH(): donation sink -> lockbox unlock callback (v4.0.0)',
  'paused()/guardian() on portal, messenger, bridges, registry, WETH: four different resolution chains over time',
  'SuperchainConfig.paused(): named bool -> paused(address(0)) with expiry (v4.0.0)',
  'AnchorStateRegistry.anchors(GameType): per-type root -> type-agnostic alias (v2.0.0)',
  'AnchorStateRegistry.isGameRegistered: factory-only (v2.0.0) -> factory AND registry binding (v4.0.0) -> factory-only (v7.0.0)',
  'AnchorStateRegistry.initialize: always retires (v4.0.0) -> retires only when never initialised (v6.0.0)',
  'setRespectedGameType: always retires (v1.4.0) -> never retires unless sentinel (v2.0.0) -> separate updateRetirementTimestamp (v4.0.0)',
  'DisputeGameFactory.create: clone-argument layout changed at v1.4.0, v5.0.0, v6.0.0; deterministic address from v7.0.0',
  'SuperPermissionedDisputeGame.initialize: real game (v6/v7) -> born resolved (v8.0.0)',
  'DelayedWETH.hold: allowance only -> allowance + transferFrom (v2.0.0)',
  'SafeCall.callWithMinGas: pure floor -> floor depends on target codehash (v9.0.0)',
  'CrossDomainMessenger.baseGas: +TX_BASE_GAS/floor (v3.0.0); relay reserve 40k/5k -> 135k/15k on L1 only (v9.0.0)',
  'SystemConfig.disputeGameFactory(): named slot -> derived through portal and registry (v4.0.0)'],
 'storage_layout_breaks_requiring_new_proxies':[
  'AnchorStateRegistry v1.8.0 -> v2.0.0 (slot 1 anchors mapping -> disputeGameFactory; slot 2 superchainConfig -> portal)',
  'AnchorStateRegistry v2.0.0 -> v4.0.0 (slot 2 portal -> anchorGame; slots 3-5 shifted; new 5/6)',
  'DelayedWETH v2.0.0 -> v4.0.0 (Ownable gaps removed: balances 101 -> 1, allowance 102 -> 2, withdrawals 103 -> 3)',
  'OptimismPortal -> OptimismPortal2 at v1.4.0 was done IN PLACE: provenWithdrawals moved 52 -> 57 with a spacer; all later portal changes are spacer-compatible (v1.2.0..v9.0.0 snapshots)']}
json.dump({'meta':META,'lineage':E},open(OUT+'SEMANTIC-LINEAGE.json','w'),indent=1)
F=['FIRST_INTRODUCED','ORIGINAL_MEANING','ORIGINAL_INVARIANT','ALL_SEMANTIC_CHANGES','ALL_CALL_ORDER_CHANGES','ALL_REVERT_SEMANTIC_CHANGES','ALL_IDENTITY_SOURCE_CHANGES','ALL_AUTHORIZATION_CHANGES','ALL_PAUSE_SOURCE_CHANGES','OBJECTS_CREATED_UNDER_OLD_MEANING','MIGRATION_OR_INVALIDATION_EVENTS','CURRENT_CONSUMERS','UNREVIEWED_TRANSITIVE_PATHS']
m=[]
m.append('# SEMANTIC LINEAGE — Bedrock (op-contracts/v1.0.0) -> Upgrade 21 (v9.0.0)\n')
m.append('Worker W0, Track A (blind: no audit material read). Machine-readable twin: `SEMANTIC-LINEAGE.json`.\n')
m.append('All `file:line` references are relative to `packages/contracts-bedrock/` at the named tag '
         '(`/home/user/ethereum-optimism/hist/<tag>/…` for v1.0.0–v6.0.0, `/home/user/ethereum-optimism/op-v{7,8,9}.0.0/…` for v7–v9). '
         'Line ranges are the extent of the function at that tag.\n')
m.append('**Method.** '+META['method']+'. A release is listed under a function only when its normalised body differs from the previous tag; '
         '"unchanged" statements were checked by that diff, not assumed.\n')
m.append('## 1. Tag notes\n')
for t in META['tag_notes']: m.append('- '+t)
for k,v in META['maintenance_tags'].items(): m.append(f'- `{k}`: {v}.')
m.append('\n## 2. Contract versions per tag\n')
m.append('| contract | '+' | '.join(ORDER)+' |'); m.append('|---|'+'---|'*len(ORDER))
for k,v in SEMVER.items(): m.append(f'| {k} | '+' | '.join(v)+' |')
m.append('\n## 3. On-chain anchors read for this lineage (OP Mainnet, L1)\n')
for t in META['onchain_timeline_op_mainnet']: m.append('- '+t)
m.append('\n## 4. Same selector / same storage type, different meaning (priority list)\n')
for t in META['same_selector_changed_meaning']: m.append('- '+t)
m.append('\n## 5. Layout breaks that forced new proxies (old proxies remain deployed and reachable)\n')
for t in META['storage_layout_breaks_requiring_new_proxies']: m.append('- '+t)
m.append('\n## 6. Per-function / per-field lineage\n')
for e in E:
    m.append(f"### {e['key']}\n")
    for f in F:
        v=e[f]
        if isinstance(v,list):
            m.append(f'**{f}**'); 
            for x in v: m.append(f'- {x}')
        else: m.append(f'**{f}:** {v}')
        m.append('')
open(OUT+'SEMANTIC-LINEAGE.md','w').write('\n'.join(m)+'\n')
print(len(E),'entries')
