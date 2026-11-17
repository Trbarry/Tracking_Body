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
