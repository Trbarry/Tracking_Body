import json, subprocess, sys, time
from concurrent.futures import ThreadPoolExecutor
D=json.load(open("decoded.json")); A=json.load(open("analysis.json")); fin=A["fin"]
P="0xbEb5Fc579115071764c7423A4f12eDde41f106Ed"; ASR="0x23B2C62946350F4246f9f9D027e071f0264FD113"
def cast(url,*a):
    for i in range(5):
        r=subprocess.run(["cast","call",*a,"--rpc-url",url],capture_output=True,text=True)
        if r.returncode==0: return r.stdout.strip()
        if "revert" in r.stderr.lower(): return "REVERT:"+r.stderr.strip()[:120]
        time.sleep(2)
    raise Exception(r.stderr[:300])
L1="http://127.0.0.1:8545"; PRE="http://127.0.0.1:8546"
hashes=sorted(set(d["hash"] for d in D))
def fz(h): return h,cast(L1,P,"finalizedWithdrawals(bytes32)(bool)",h)=="true"
with ThreadPoolExecutor(3) as ex: finalized=dict(ex.map(fz,hashes))
print("on-chain finalized at l1 pin:",sum(finalized.values()),"of",len(hashes))
todo=[d for d in D if not finalized[d["hash"]]]
def pw(d):
    o=cast(L1,P,"provenWithdrawals(bytes32,address)(address,uint64)",d["hash"],d["proofSubmitter"]).split("\n")
    d["game"]=o[0]; d["provenTimestampOnChain"]=int(o[1].split()[0]); d["finalizedAtPin"]=False
    return d
with ThreadPoolExecutor(3) as ex: todo=list(ex.map(pw,todo))
games=sorted(set(d["game"] for d in todo))
def g(a):
    r=dict(game=a)
    r["gameType"]=int(cast(L1,a,"gameType()(uint32)").split()[0]); r["status"]=int(cast(L1,a,"status()(uint8)")); 
    r["createdAt"]=int(cast(L1,a,"createdAt()(uint64)").split()[0]); r["resolvedAt"]=int(cast(L1,a,"resolvedAt()(uint64)").split()[0])
    r["rootClaim"]=cast(L1,a,"rootClaim()(bytes32)"); r["l2SequenceNumber"]=int(cast(L1,a,"l2SequenceNumber()(uint256)").split()[0])
    for f in ["isGameProper","isGameRespected","isGameResolved","isGameFinalized","isGameClaimValid","isGameRetired","isGameBlacklisted"]:
        r[f]=cast(L1,ASR,f+"(address)(bool)",a)=="true"
    return r
with ThreadPoolExecutor(3) as ex: G={x["game"]:x for x in ex.map(g,games)}
json.dump(dict(entries=todo,games=G,finalized=finalized),open("state.json","w"),indent=1)
import collections
print("unfinalized entries",len(todo),"distinct hashes",len(set(d["hash"] for d in todo)),"games",len(G))
print(collections.Counter((x["gameType"],x["status"],x["isGameFinalized"],x["isGameClaimValid"]) for x in G.values()))
