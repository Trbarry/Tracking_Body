import json,subprocess,sys
sys.path.insert(0,'.')
from gather import *
ABI='/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/snapshots/abi/'
ABI8='/home/user/ethereum-optimism/op-v8.0.0/packages/contracts-bedrock/snapshots/abi/'
def getters(name,base=ABI):
    out=[]
    for f in json.load(open(base+name+'.json')):
        if f['type']=='function' and not f['inputs'] and f['stateMutability'] in('view','pure') and len(f['outputs'])==1:
            t=f['outputs'][0]['type']
            if t in('address','uint256','uint64','uint32','uint8','bool','string','bytes32','uint128','uint16'):
                out.append((f['name'],t))
    return out
ups=json.load(open('upgrades_full.json'))
G={}
for u in ups:
    name=u['name']; t=u['target']
    gs=dict(getters(name)); gs8=dict(getters(name,ABI8))
    allg=sorted(set(gs)|set(gs8))
    for g in allg:
        ty=gs.get(g) or gs8.get(g)
        vals=[]
        for r in ['pre','n','post']:
            vals.append(call(r,t,f'{g}()({ty})'))
        G.setdefault(u['chain'],{}).setdefault(name,{})[g]=vals
    print(u['chain'],name,'done',file=sys.stderr,flush=True)
json.dump(G,open('graph.json','w'),indent=1)
