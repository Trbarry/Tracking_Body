import json,sys
from rpc import *
L1="http://127.0.0.1:7545"
SB=sys.argv[1]; name=sys.argv[2]; topic=sys.argv[3]; start=int(sys.argv[4])
L=logs(L1,SB,[topic],start,26433900,chunk=200000,sleep=0.3)
pairs={}
for l in L:
    k=("0x"+l["topics"][1][26:],"0x"+l["topics"][2][26:])
    amt=int(l["data"][2+64:2+128],16)
    p=pairs.setdefault(k[0]+","+k[1],{"n":0,"sum":0})
    p["n"]+=1; p["sum"]+=amt
json.dump({"count":len(L),"pairs":{k:{"n":v["n"],"sum":str(v["sum"])} for k,v in pairs.items()}},open(f"../out/{name}.json","w"),indent=1)
print(name,len(L),len(pairs))
