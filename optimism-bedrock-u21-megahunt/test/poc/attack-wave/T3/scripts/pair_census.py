# Read-only census: for each distinct (l1,l2) withdrawal pair on the OP L1StandardBridge, read
# deposits[l1][l2] (L1 @26433900), L1 ERC165 mintable detection, and on OP (@159654093) the L2 token's
# code, totalSupply, legacy/new interface and remoteToken()/l1Token(). Batched eth_call / getStorageAt
# on the read-only proxies (:7545 L1, :7546 OP).
import json,sys,time,urllib.request
from keccak import keccak256
L1="http://127.0.0.1:7545"; L2="http://127.0.0.1:7546"; B1=hex(26433900); B2=hex(159654093)
SB="0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1"
def w(x): return int(x,16).to_bytes(32,'big')
def depslot(l1,l2): return "0x"+keccak256(w(l2)+keccak256(w(l1)+(2).to_bytes(32,'big'))).hex()
def batch(url,reqs):
    body=json.dumps(reqs).encode()
    for k in range(5):
        try:
            r=json.loads(urllib.request.urlopen(urllib.request.Request(url,data=body,headers={"content-type":"application/json"}),timeout=120).read())
            if isinstance(r,list): return {x["id"]:x.get("result") for x in r}
        except Exception as e: time.sleep(2*(k+1))
    raise Exception("batch failed")
def call(id,to,data,blk): return {"jsonrpc":"2.0","id":id,"method":"eth_call","params":[{"to":to,"data":data},blk]}
SI=lambda iid:"0x01ffc9a7"+iid.ljust(64,"0")
d=json.load(open(sys.argv[1]))["pairs"]
rows=[]
for k,v in d.items():
    l1,l2=k.split(",")
    r1=batch(L1,[{"jsonrpc":"2.0","id":0,"method":"eth_getStorageAt","params":[SB,depslot(l1,l2),B1]},call(1,l1,SI("1d1d8b63"),B1),call(2,l1,SI("ec4fc8e3"),B1),call(3,l1,"0x95d89b41",B1)])
    r2=batch(L2,[{"jsonrpc":"2.0","id":0,"method":"eth_getCode","params":[l2,B2]},call(1,l2,"0x18160ddd",B2),call(2,l2,SI("1d1d8b63"),B2),call(3,l2,SI("ec4fc8e3"),B2),call(4,l2,"0xd6c0b2c4",B2),call(5,l2,"0xc01e1bd6",B2)])
    t=lambda x:(x is not None and len(x)>=66 and int(x[2:66],16)==1)
    a=lambda x:("0x"+x[26:66]) if x and len(x)>=66 else None
    n=lambda x:int(x[2:66],16) if x and len(x)>=66 else None
    rows.append(dict(l1=l1,l2=l2,withdrawals=v["n"],withdrawn=v["sum"],deposits=str(int(r1[0],16)),
        l1_mintable=t(r1[1]) or t(r1[2]),l2_code=(r2[0] or "0x")!="0x",l2_totalSupply=(str(n(r2[1])) if n(r2[1]) is not None else None),
        l2_legacyIface=t(r2[2]),l2_newIface=t(r2[3]),l2_remoteToken=a(r2[4]),l2_l1Token=a(r2[5])))
    time.sleep(0.1)
json.dump(rows,open(sys.argv[2],"w"),indent=1)
print(len(rows))
