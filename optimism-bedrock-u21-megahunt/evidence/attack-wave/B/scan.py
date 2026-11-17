import json, urllib.request, sys, os, concurrent.futures as cf
RPC="http://127.0.0.1:7545"
OUT=sys.argv[1]
ADDRS={"0xbeb5fc579115071764c7423a4f12edde41f106ed":"OP-portal","0x5d66c1782664115999c47c9fa5cd031f495d3e4f":"INK-portal",
"0x88e529a6ccd302c948689cd5156c83d4614fae92":"SON-portal","0x0bd48f6b86a26d3a217d0fa6ffe2b491b956a7a2":"UNI-portal",
"0x25ace71c97b33cc4729cf772ae268934f7ab5fa1":"OP-cdm","0x69d3cf86b2bf1a9e99875b7e2d9b6a84426c171f":"INK-cdm",
"0x9cf951e3f74b644e621b36ca9cea147a78d4c39f":"SON-cdm","0x9a3d64e386c18cb1d6d5179a9596a4b5736e98a6":"UNI-cdm"}
WF="0xdb5c7652857aa163daadd670e116628fb42e869d8ac4251ef8971d9e5727df1b"
FRM="0x99d0e048484baa1b1540b1367cb128acd7ab2946d1ed91ec10e3c85e4bf51b8f"
def rpc(m,p):
    r=urllib.request.Request(RPC,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"content-type":"application/json"})
    for i in range(6):
        try:
            j=json.load(urllib.request.urlopen(r,timeout=120))
            if "error" in j: raise Exception(j["error"])
            return j["result"]
        except Exception as e:
            err=e
    raise err
def chunk(a):
    b=min(a+9999,END)
    logs=rpc("eth_getLogs",[{"fromBlock":hex(a),"toBlock":hex(b),"address":list(ADDRS),"topics":[[WF,FRM]]}])
    res=[]
    for l in logs:
        t=l["topics"][0]
        if t==WF:
            ok=int(l["data"],16)
            if ok: continue
        res.append({"who":ADDRS[l["address"].lower()],"ev":"WF_false" if t==WF else "FRM","hash":l["topics"][1],"block":int(l["blockNumber"],16),"tx":l["transactionHash"],"logIndex":int(l["logIndex"],16)})
    return res
START=17422444; END=26433900
starts=list(range(START,END+1,10000))
allr=[]
with cf.ThreadPoolExecutor(4) as ex:
    for i,r in enumerate(ex.map(chunk,starts)):
        allr+=r
        if i%100==0: print(i,len(starts),len(allr),flush=True)
json.dump({"range":[START,END],"addrs":ADDRS,"hits":allr},open(OUT,"w"),indent=1)
print("done",len(allr))
