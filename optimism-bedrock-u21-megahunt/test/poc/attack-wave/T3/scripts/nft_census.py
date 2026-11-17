# Read-only: for every outstanding escrow key (init without later fin) on OP L1ERC721Bridge,
# read deposits[local][remote][id] (slot 49) at L1 26433900 via JSON-RPC batch on the read-only proxy.
import json,sys,time,urllib.request
from keccak import keccak256
URL="http://127.0.0.1:7545"; BR="0x5a7749f83b81B301cAb5f48EB8516B986DAef23D"; BLK=hex(26433900)
def w(x): return int(x,16).to_bytes(32,'big') if isinstance(x,str) else x.to_bytes(32,'big')
def slot(l,r,i):
    s1=keccak256(w(l)+w(49)); s2=keccak256(w(r)+s1); s3=keccak256(int(i).to_bytes(32,'big')+s2)
    return "0x"+s3.hex()
def batch(reqs):
    body=json.dumps(reqs).encode()
    for k in range(5):
        try:
            r=json.loads(urllib.request.urlopen(urllib.request.Request(URL,data=body,headers={"content-type":"application/json"}),timeout=120).read())
            if isinstance(r,list): return {x["id"]:x.get("result") for x in r}
        except Exception as e: time.sleep(2*(k+1))
    raise Exception("batch failed")
if __name__=="__main__":
    keys=json.load(open("../out/erc721_outstanding.json"))
    res={}
    for o in range(0,len(keys),50):
        ch=keys[o:o+50]
        reqs=[{"jsonrpc":"2.0","id":o+j,"method":"eth_getStorageAt","params":[BR,slot(*k),BLK]} for j,k in enumerate(ch)]
        r=batch(reqs)
        for j,k in enumerate(ch): res[",".join(k)]=int(r[o+j],16)
        time.sleep(0.2)
    from collections import Counter
    print(Counter(res.values()))
    json.dump(res,open("../out/erc721_flags.json","w"))
