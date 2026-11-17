import json,subprocess,sys,collections
R='http://127.0.0.1:8545'
E='/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/evidence/W0/'
d=json.load(open(E+'dgf-implementation-set-logs-19800000-26433900.json'))
print('logs',len(d['logs']),'errors',len(d['errors']))
CH={'0xe5965ab5962edc7477c8520243a95517cd252fa9':('op','0x23B2C62946350F4246f9f9D027e071f0264FD113'),
    '0x10d7b35078d3baabb96dd45a9143b94be65b12cd':('ink','0xEe018bAf058227872540AC60eFbd38b023d9dAe2'),
    '0x2f12d621a16e2d3285929c9996f478508951dfe4':('unichain','0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9'),
    '0x512a3d2c7a43bd9261d2b8e8c9c70d4bd4d503c0':('soneium','0x4890928941e62e273dA359374b105F803329F473')}
TS='0xff513d80e2c7fa487608f70a618dfbc0cf415699dc69588c747e8c71566c88de'
def call(to,sig,*a,block=None):
    cmd=['cast','call',to,sig,*a,'--rpc-url',R]
    o=subprocess.run(cmd,capture_output=True,text=True)
    return o.stdout.strip().split('\n')[0] if o.returncode==0 else 'ERR'
def blk_ts(b):
    o=subprocess.run(['cast','block',str(b),'--field','timestamp','--rpc-url','http://127.0.0.1:7545'],capture_output=True,text=True).stdout.strip()
    return int(o) if o.isdigit() else None
res={}
for fac,(name,asr) in CH.items():
    logs=sorted([l for l in d['logs'] if l['address'].lower()==fac],key=lambda l:(l['block'],))
    ret=int(call(asr,'retirementTimestamp()(uint64)').split()[0])
    tl=[];args={}
    for l in logs:
        if l['topics'][0]==TS:
            impl='0x'+l['topics'][1][-40:]; gt=int(l['topics'][2],16)
            tl.append(dict(block=l['block'],tx=l['tx'],type=gt,impl=impl))
        else:
            gt=int(l['topics'][1],16); args[(l['block'],gt)]=l['data']
    # annotate
    implinfo={}
    for e in tl:
        i=e['impl']
        if i=='0x'+'0'*40: e['registry']='(unset)'; e['version']=''; continue
        if i not in implinfo:
            implinfo[i]=(call(i,'anchorStateRegistry()(address)'),call(i,'version()(string)'))
        reg,ver=implinfo[i]
        a=args.get((e['block'],e['type']))
        e['version']=ver
        if a and len(a)>130:
            e['args_contain_current_registry']= asr[2:].lower() in a.lower()
            e['registry']='from gameArgs: '+('current' if e['args_contain_current_registry'] else 'NOT current')
        else:
            e['registry']=reg
    # state of gameImpls over time: after retirement, which (type -> impl) were ever active?
    tsb={}
    def ts(b):
        if b not in tsb: tsb[b]=blk_ts(b)
        return tsb[b]
    active={}  # type -> entry
    flagged=[]
    for e in tl:
        t=ts(e['block'])
        e['timestamp']=t
    # entries active at retirement moment = last set per type with timestamp <= ret ; plus all set later
    last_before={}
    for e in tl:
        if e['timestamp'] is not None and e['timestamp']<=ret: last_before[e['type']]=e
    post=[e for e in tl if e['timestamp'] is not None and e['timestamp']>ret]
    cand=list(last_before.values())+post
    for e in cand:
        if e['registry']=='(unset)': continue
        ok = (e['registry'].lower()==asr.lower()) or e['registry']=='from gameArgs: current'
        if not ok: flagged.append(e)
    res[name]=dict(factory=fac,current_registry=asr,retirementTimestamp=ret,implementation_set_events=len(tl),timeline=tl,
                   implementations_active_after_retirement_not_bound_to_current_registry=flagged)
    print('==',name,'events',len(tl),'ret',ret,'flagged',len(flagged))
    for e in tl: print('  ',e['block'],e.get('timestamp'),'type',e['type'],e['impl'][:10],e.get('version'),e.get('registry'))
    for e in flagged: print('  FLAG',e)
json.dump(res,open(E+'dgf-implementation-registry-binding.json','w'),indent=1)
