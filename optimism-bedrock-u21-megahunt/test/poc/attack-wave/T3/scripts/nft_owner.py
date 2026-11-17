# Read-only eth_call ownerOf(id) for every outstanding escrow key at L1 26433900 (passive context only).
import json,time
from nft_census import batch, BLK, BR
keys=json.load(open("../out/erc721_outstanding.json"))
res={}
for o in range(0,len(keys),50):
    ch=keys[o:o+50]
    reqs=[{"jsonrpc":"2.0","id":o+j,"method":"eth_call","params":[{"to":k[0],"data":"0x6352211e"+int(k[2]).to_bytes(32,'big').hex()},BLK]} for j,k in enumerate(ch)]
    r=batch(reqs)
    for j,k in enumerate(ch):
        v=r.get(o+j); res[",".join(k)]=("0x"+v[26:66]) if v and len(v)>=66 else None
    time.sleep(0.2)
from collections import Counter
c=Counter("bridge" if (v or "").lower()==BR.lower() else ("revert/none" if v is None else "other") for v in res.values())
print(c)
json.dump(res,open("../out/erc721_owners.json","w"))
