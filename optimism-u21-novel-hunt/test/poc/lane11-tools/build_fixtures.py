import json, subprocess, sys, time
from concurrent.futures import ThreadPoolExecutor
A=json.load(open("analysis.json")); proven=A["proven"]; fin=A["fin"]
P="0xbEb5Fc579115071764c7423A4f12eDde41f106Ed"; L1="http://127.0.0.1:8545"; U21=26430859
SEL="4870496f"
def rpc(url,method,params):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params})
    for i in range(4):
        r=subprocess.run(["curl","-sS","-m","60","-X","POST","-H","content-type: application/json","--data",body,url],capture_output=True,text=True)
        try:
            j=json.loads(r.stdout)
            if "result" in j and j["result"] is not None: return j["result"]
        except Exception: pass
        time.sleep(1)
    raise Exception("rpc fail %s %s %s"%(method,params,r.stdout[:200]))
UP=["https://rpc.mevblocker.io","https://ethereum-rpc.publicnode.com","https://eth.drpc.org"]
CACHE={}
def rpc2(method,params):
    k=method+json.dumps(params)
    if k in CACHE: return CACHE[k]
    for i in range(6):
        for u in UP:
            try:
                r=rpc1(u,method,params); CACHE[k]=r; return r
            except Exception as e: err=e
        time.sleep(1.5)
    raise err
def rpc1(url,method,params):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params})
    r=subprocess.run(["curl","-sS","-m","60","-X","POST","-H","content-type: application/json","--data",body,url],capture_output=True,text=True)
    j=json.loads(r.stdout)
    if j.get("result") is None: raise Exception(r.stdout[:200])
    return j["result"]
def cast(*a):
    r=subprocess.run(["cast",*a,"--rpc-url",L1],capture_output=True,text=True)
    if r.returncode: raise Exception(r.stderr[:300])
    return r.stdout.strip()
def w(b,i): return int(b[i*64:(i+1)*64],16)
def decode(inp):
    h=inp[2:] if inp.startswith("0x") else inp
    pos=h.find(SEL)
    cands=[]
    while pos!=-1:
        if pos%2==0: cands.append(pos)
        pos=h.find(SEL,pos+1)
    for pos in cands:
        try:
            b=h[pos+8:]
            off=w(b,0)//32
            t=b[off*64:]
            nonce=w(t,0); sender="0x"+t[64+24:128]; target="0x"+t[128+24:192]; value=w(t,3); gl=w(t,4); doff=w(t,5)
            d=t[doff*2:]; dl=int(d[:64],16); data="0x"+d[64:64+dl*2]
            if len(data)!=2+dl*2: continue
            gi=w(b,1)
            # compute total length of call: proof array
            poff=w(b,6)*2; pa=b[poff:]; n=int(pa[:64],16); end=poff+64
            maxend=end+n*64
            for k in range(n):
                eo=int(pa[64+k*64:128+k*64],16)*2+64; el=int(pa[eo:eo+64],16); e=poff+eo+64+((el+31)//32)*64
                maxend=max(maxend,e)
            calldata="0x"+SEL+b[:maxend]
            return dict(nonce=str(nonce),sender=sender,target=target,value=str(value),gasLimit=str(gl),data=data,gameIndex=gi,proveCalldata=calldata)
        except Exception as e:
            continue
    return None
def one(item):
    h,plist=item
    out=[]
    for p in plist:
        tx=rpc2("eth_getTransactionByHash",[p["tx"]])
        d=decode(tx["input"])
        if d is None: out.append(dict(hash=h,err="decode",tx=p["tx"])); continue
        blk=rpc2("eth_getBlockByNumber",[hex(p["bn"]),False])
        d.update(hash=h,proveTx=p["tx"],proveBlock=p["bn"],proveTimestamp=int(blk["timestamp"],16),proofSubmitter=p.get("submitter"),proveTxTo=tx["to"],proveTxFrom=tx["from"],postU21=p["bn"]>U21)
        out.append(d)
    return out
items=[(h,p) for h,p in proven.items()]
res=[]
with ThreadPoolExecutor(3) as ex:
    for r in ex.map(one,items): res+=r
json.dump(res,open("decoded.json","w"))
print(len(res),"decoded;",sum(1 for r in res if "err" in r),"errors")
