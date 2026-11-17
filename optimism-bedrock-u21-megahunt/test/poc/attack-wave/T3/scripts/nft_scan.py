import json,sys
from rpc import *
L1="http://127.0.0.1:7545"
B={"OP":"0x5a7749f83b81B301cAb5f48EB8516B986DAef23D","Ink":"0x661235a238B11191211fa95D4Dd9E423d521E0Be","Soneium":"0x5933e323bE8896DfaCd1cD671442F27dAA10a053","Unichain":"0xD04D0D87E0bd4D2E50286760a3EF323FeA6849Cf"}
TI="0xb7460e2a880f256ebef3406116ff3eee0cee51ebccdc2a40698f87ebb2e9c1a5"
TF="0x1f39bf6707b5d608453e0ae4c067b562bcc4c85c0f562ef5d2c774d2e7f131ac"
out={}
for ch,a in B.items():
    L=logs(L1,a,[[TI,TF]],15000000,26433900,chunk=1000000)
    ev=[]
    for l in L:
        d=l["data"][2:]
        ev.append({"kind":"init" if l["topics"][0]==TI else "fin","local":"0x"+l["topics"][1][26:],"remote":"0x"+l["topics"][2][26:],"from":"0x"+l["topics"][3][26:],"to":"0x"+d[24:64],"tokenId":str(int(d[64:128],16)),"block":int(l["blockNumber"],16),"tx":l["transactionHash"]})
    out[ch]=ev
    print(ch,len(ev),sum(e["kind"]=="init" for e in ev),sum(e["kind"]=="fin" for e in ev))
json.dump(out,open("../out/l1_erc721_events.json","w"),indent=1)
