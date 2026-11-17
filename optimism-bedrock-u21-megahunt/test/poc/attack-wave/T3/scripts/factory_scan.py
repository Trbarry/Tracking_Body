import json,sys
from rpc import *
L1="http://127.0.0.1:7545"
FACT={"OP":"0x75505a97BD334E7BD3C476893285569C4136Fa0F","Ink":"0xA8B389A82e088b164cD03230e900980CcED34d29","Soneium":"0xc1047e30EFC9E172cFe7aa0219895B6a43fC415F","Unichain":"0xA2B597EaeAcb6F627e088cbEaD319e934ED5edad"}
T_NEW="0x52fe89dd5930f343d25650b62fd367bae47088bcddffd2a88350a6ecdd620cdb"
END=26433900
res={}
for ch,a in FACT.items():
    start=17000000
    L=logs(L1,a,[T_NEW],start,END,chunk=500000)
    res[ch]=[{"local":"0x"+l["topics"][1][26:],"remote":"0x"+l["topics"][2][26:],"block":int(l["blockNumber"],16),"tx":l["transactionHash"]} for l in L]
    print(ch,len(res[ch]),file=sys.stderr)
json.dump(res,open("../out/l1_factory_tokens.json","w"),indent=1)
