import json, sys, time, urllib.request
RPC="http://127.0.0.1:7545"
def rpc(m,p):
    r=urllib.request.Request(RPC,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"content-type":"application/json"})
    return json.loads(urllib.request.urlopen(r,timeout=120).read())
from hashlib import sha3_256
# keccak via eth_call-free: precomputed topics
T_SET="0xff513d80e2c7fa487608f70a618dfbc0cf415699dc69588c747e8c71566c88de"  # ImplementationSet(address,uint32)
dgfs={"op":"0xe5965Ab5962eDc7477C8520243A95517CD252fA9","ink":"0x10d7B35078d3baabB96Dd45a9143B94be65b12CD","soneium":"0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0","unichain":"0x2F12d621a16e2d3285929C9996f478508951dFe4"}
start=int(sys.argv[1]); end=int(sys.argv[2]); step=int(sys.argv[3])
out={}
for name,a in dgfs.items():
    logs=[]
    b=start
    while b<=end:
        e=min(end,b+step-1)
        r=rpc("eth_getLogs",[{"address":a,"fromBlock":hex(b),"toBlock":hex(e),"topics":[["0xff513d80e2c7fa487608f70a618dfbc0cf415699dc69588c747e8c71566c88de","0xa47fcdf075d680d3817bfca7973b373e1a5f6cfc3b444748299cc2b83d8348f9","0x74d6665c4b26d5596a5aa13d3014e0c06af4d322075a797f87b03cd4c5bc91ca"]]}])
        if "error" in r:
            print(name,b,e,r["error"]); step=step//2; continue
        for l in r["result"]:
            logs.append({"block":int(l["blockNumber"],16),"tx":l["transactionHash"],"topics":l["topics"],"data":l["data"][:200]})
        b=e+1; time.sleep(0.2)
    out[name]=[l for l in logs if l["topics"][0]!="0x5b565efe82411da98814f356d0e7bcb8f0219b8d970307c5afb4a6903a8b2e35"]
    print(name,len(logs),"logs; non-create:",len(out[name]))
json.dump(out,open(sys.argv[4],"w"),indent=1)
