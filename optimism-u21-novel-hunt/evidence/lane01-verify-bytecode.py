import json,subprocess,sys
A='/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/forge-artifacts'
R='http://127.0.0.1:8545'
def code(a):
    return subprocess.run(['cast','code','--rpc-url',R,a],capture_output=True,text=True).stdout.strip()[2:]
def verify(name,addr,art=None):
    art=art or f'{A}/{name}.sol/{name}.json'
    j=json.load(open(art))
    exp=j['deployedBytecode']['object'][2:]
    imm=j['deployedBytecode'].get('immutableReferences',{}) or {}
    on=code(addr)
    if len(on)!=len(exp):
        return f'{name} {addr} LENGTH MISMATCH onchain={len(on)//2} artifact={len(exp)//2}'
    eb=bytearray(bytes.fromhex(exp)); ob=bytearray(bytes.fromhex(on))
    vals={}
    for k,refs in imm.items():
        for r in refs:
            s,l=r['start'],r['length']
            vals.setdefault(k,set()).add(bytes(ob[s:s+l]).hex())
            eb[s:s+l]=b'\0'*l; ob[s:s+l]=b'\0'*l
    diff=sum(1 for x,y in zip(eb,ob) if x!=y)
    cons=all(len(v)==1 for v in vals.values())
    return f'{name} {addr} len={len(on)//2} diffBytes={diff} immutables={len(imm)} consistent={cons} ' + ('MATCH' if diff==0 and cons else 'MISMATCH') , vals
if __name__=='__main__':
    for n,a in [x.split('=') for x in sys.argv[1:]]:
        r=verify(n,a)
        if isinstance(r,tuple):
            print(r[0]); 
            for k,v in r[1].items(): print('     imm',k,[x.lstrip('0') or '0' for x in v])
        else: print(r)
