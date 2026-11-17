import json,csv
OUT='/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/'
S={
'S1':'provenWithdrawals[hash][submitter] (portal slot 57)',
'S2':'finalizedWithdrawals[hash] (portal slot 51)',
'S3':'failedMessages[msg] + ETH held by L1CDM (slot 206)',
'S4':'successfulMessages[msg] incl. legacy V0 hashes (slot 203)',
'S5':'resolved game clone registered in the factory (_disputeGames/_disputeGameList)',
'S5b':'in-progress game clone holding bonds',
'S6':'anchorGame (registry slot 2)',
'S7':'respectedGameType/retirementTimestamp (registry slot 6)',
'S8':'disputeGameBlacklist (registry slot 5)',
'S9':'SuperchainConfig.pauseTimestamps[identifier]',
'S10':'ETHLockbox balance (backing + surplus)',
'S11':'portal ETH balance',
'S12':'authorizedPortals/authorizedLockboxes',
'S13':'portal.anchorStateRegistry / portal.ethLockbox pointers (slots 62/63)',
'S14':'gameImpls/gameArgs (factory slots 101/105)',
'S15':'L2ToL1MessagePasser.sentMessages entry (withdrawal incl. gasLimit budget, sender, target)',
'S16':'SystemConfig.l2ChainId / isFeatureEnabled',
'S17':'OZ _initialized byte + initializer-written fields',
'S18':'DelayedWETH balances/withdrawal requests (legacy or current proxy)',
'S19':'L2 account/authority at alias(L1 system contract)',
'S20':'legacy registry 0x1c68ECfb… anchorGame',
}
# id -> (creates, consumes)
M={
'A-001':(['S1'],['S5','S7']),
'A-002':(['S5','S6'],['S14','S5b']),
'A-004':(['S5'],['S14','S7']),
'A-005':([],['S9','S13']),
'A-009':(['S2','S3','S10'],['S1','S5','S15']),
'A-010':(['S11','S1'],[]),
'A-011':(['S11'],['S11','S10']),
'A-012':(['S3','S2'],['S3','S1','S15']),
'A-014':(['S10'],['S12','S13']),
'A-016':(['S2','S10'],['S1','S15']),
'A-017':([],['S15','S4']),
'A-018':(['S3'],['S15']),
'A-021':([],['S1','S8','S5']),
'A-023':(['S5','S1'],['S16','S7']),
'A-027':([],['S18','S9','S7','S20']),
'A-028':([],['S9']),
'A-031':([],['S16','S5']),
'A-035':(['S13','S12','S7','S10'],['S1','S5','S11','S10','S12','S18','S14']),
'A-038':([],['S15','S4']),
'A-041':(['S4'],['S4','S15']),
'A-044':([],['S5','S7','S14','S6']),
'A-048':([],['S5b','S18']),
'A-051':([],[]),
'A-057':(['S17','S13','S7','S6','S16'],['S17']),
'A-061':(['S14'],['S14']),
'A-068':(['S2','S3','S4'],['S2','S3','S4','S15']),
'A-069':([],['S1','S13','S7','S8','S9','S16']),
'A-074':([],['S1']),
'A-081':(['S19','S10'],['S15']),
'A-085':(['S5'],['S14']),
'PRIM-W0-01':([],['S5','S7','S14']),
'PRIM-W0-02':(['S20'],['S5','S7','S8','S13']),
}
P=json.load(open(OUT+'PRIMITIVES.json'))['primitives']
want=[r['id'] for r in P if r['priority'] in('P0','P1')]
assert set(want)<=set(M), set(want)-set(M)
ids=want+['PRIM-W0-01','PRIM-W0-02']
with open(OUT+'PRIMITIVE-COMPATIBILITY-MATRIX.csv','w',newline='') as f:
    w=csv.writer(f)
    w.writerow(['row CREATES \\ column CONSUMES']+ids)
    n=0
    for r in ids:
        row=[r]
        for c in ids:
            if r==c: row.append(''); continue
            sh=[s for s in M[r][0] if s in M[c][1]]
            row.append(' + '.join(f'{s} {S[s]}' for s in sh)); n+=bool(sh)
        w.writerow(row)
print('ids',len(ids),'nonempty cells',n)
json.dump({'states':S,'creates_consumes':{k:{'creates':v[0],'consumes':v[1]} for k,v in M.items()}},open(OUT+'evidence/W0/matrix-state-vocabulary.json','w'),indent=1)
