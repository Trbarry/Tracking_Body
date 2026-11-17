import json,collections
S=json.load(open("state.json")); E=S["entries"]; G=S["games"]; D=json.load(open("decoded.json")); A=json.load(open("analysis.json"))
NOW=1794908075; U21=26430859
CDM="0x4200000000000000000000000000000000000007"
def inner(d):
    h=d["data"][2:]
    if d["sender"]!=CDM or not h.startswith("d764ad0b"): return None
    b=h[8:]; w=lambda i:int(b[i*64:(i+1)*64],16)
    off=w(5)*2; ln=int(b[off:off+64],16)
    return dict(msgNonce=str(w(0)),msgSender="0x"+b[64+24:128],msgTarget="0x"+b[128+24:192],msgValue=str(w(3)),minGasLimit=str(w(4)),messageLength=ln,messageSelector="0x"+b[off+64:off+72] if ln>=4 else "0x")
def mk(d,cls):
    g=G.get(d.get("game",""),{})
    o=dict(hash=d["hash"],**{"class":cls},kind="messenger" if d["sender"]==CDM else "plain",hasValue=int(d["value"])>0,
        nonce=d["nonce"],sender=d["sender"],target=d["target"],value=d["value"],gasLimit=d["gasLimit"],data=d["data"],
        proofSubmitter=d["proofSubmitter"],proveTx=d["proveTx"],proveTxFrom=d["proveTxFrom"],proveTxTo=d["proveTxTo"],proveBlock=d["proveBlock"],
        proofTimestamp=d.get("provenTimestampOnChain",d["proveTimestamp"]),proveTxTimestamp=d["proveTimestamp"],postU21=d["postU21"],
        gameIndex=d["gameIndex"],game=d.get("game","0x0000000000000000000000000000000000000000"),
        gameType=g.get("gameType",0),gameStatusAtPin=g.get("status",0),gameCreatedAt=g.get("createdAt",0),gameResolvedAt=g.get("resolvedAt",0),
        gameClaimValidAtPin=g.get("isGameClaimValid",False),matureAtPin=(NOW-d.get("provenTimestampOnChain",d["proveTimestamp"]))>604800,
        finalizedAtPin=d.get("finalizedAtPin",True),proveCalldata=d["proveCalldata"])
    i=inner(d)
    if i: o["inner"]=i
    return o
def cls(d):
    g=G[d["game"]]; mature=(NOW-d["provenTimestampOnChain"])>604800
    if g["status"]==1: return "pre_challenger_wins"
    if d["postU21"]: return "post_inprogress" if g["status"]==0 else "post_resolved"
    if mature and g["isGameClaimValid"]: return "pre_mature_valid"
    if g["isGameClaimValid"]: return "pre_immature_gamefinal"
    if g["status"]==2: return "pre_immature_resolved"
    return "pre_immature_inprogress"
allf=[mk(d,cls(d)) for d in E]
# stale entries: provenTimestampOnChain differs from prove tx timestamp => superseded by a later re-prove by same submitter
for f in allf: f["supersededByReprove"]=f["proofTimestamp"]!=f["proveTxTimestamp"]
# finalized between l1pre pin and l1 pin (real v9 finalizations): useful for differential
finpost=[h for h,f in A["fin"].items() if f["bn"]>U21]
ref=[]
for d in D:
    if d["hash"] in finpost:
        o=mk(d,"finalized_post_u21_onchain"); o["finalizeTx"]=A["fin"][d["hash"]]["tx"]; o["finalizeBlock"]=A["fin"][d["hash"]]["bn"]; o["supersededByReprove"]=False; ref.append(o)
print(collections.Counter((f["class"],f["kind"],f["hasValue"]) for f in allf))
print("ref finalized post U21:",[(r["hash"][:10],r["kind"],r["hasValue"],r["proofSubmitter"],r["finalizeTx"]) for r in ref])
json.dump(dict(meta=dict(l1Pin=26433900,l1PinTimestamp=NOW,l1prePin=26430858,u21Block=U21,portal="0xbEb5Fc579115071764c7423A4f12eDde41f106Ed",window=[26363900,26433900],note="all withdrawals proven in window and NOT finalized at the l1 pin; proveCalldata is the exact proveWithdrawalTransaction calldata recorded on mainnet"),fixtures=allf,finalizedPostU21=ref),open("withdrawal-fixtures-all.json","w"),indent=1)
# curated
pick=[]; seen=collections.Counter()
quota={("pre_mature_valid","messenger",False):4,("pre_mature_valid","messenger",True):4,("pre_immature_gamefinal","messenger",False):2,("pre_immature_gamefinal","messenger",True):1,
       ("pre_immature_resolved","messenger",False):2,("pre_immature_resolved","messenger",True):2,("pre_immature_inprogress","messenger",False):2,("pre_immature_inprogress","messenger",True):2}
multi=collections.Counter(f["hash"] for f in allf)
subs=collections.defaultdict(set)
for f in allf: subs[f["hash"]].add(f["proofSubmitter"])
for f in sorted(allf,key=lambda f:(-(f["proveTxTo"].lower()!="0xbeb5fc579115071764c7423a4f12edde41f106ed"), -int(f["value"]), -len(f["data"]))):
    k=(f["class"],f["kind"],f["hasValue"])
    force=f["kind"]=="plain" or f["postU21"] or len(subs[f["hash"]])>1
    if f["supersededByReprove"] and not force: continue
    if force or seen[k]<quota.get(k,0):
        seen[k]+=1; pick.append(f)
for f in pick: f["multiSubmitter"]=len(subs[f["hash"]])>1
print(len(pick),"curated"); 
for i,f in enumerate(pick): print(i,f["class"],f["kind"],f["hasValue"],f["hash"][:10],f["proofSubmitter"][:8],"multi" if f["multiSubmitter"] else "", "viaContract" if f["proveTxTo"].lower()!="0xbeb5fc579115071764c7423a4f12edde41f106ed" else "", f.get("inner",{}).get("msgTarget","")[:10], f.get("inner",{}).get("minGasLimit",""), f["gasLimit"], len(f["proveCalldata"])//2)
json.dump(dict(meta=dict(l1Pin=26433900,l1PinTimestamp=NOW,l1prePin=26430858,l1prePinTimestamp=1794871427,u21Block=U21,portal="0xbEb5Fc579115071764c7423A4f12eDde41f106Ed",count=len(pick),refCount=len(ref)),fixtures=pick,finalizedPostU21=ref),open("withdrawal-fixtures.json","w"),indent=1)
import os
os.makedirs("withdrawal-fixtures",exist_ok=True)
slim=lambda f:{k:v for k,v in f.items() if k not in("data","proveCalldata")}
json.dump(dict(meta=dict(l1Pin=26433900,l1PinTimestamp=NOW,l1prePin=26430858,l1prePinTimestamp=1794871427,u21Block=U21,count=len(pick),refCount=len(ref)),fixtures=[slim(f) for f in pick],finalizedPostU21=[slim(f) for f in ref]),open("withdrawal-fixtures/index.json","w"),indent=1)
for i,f in enumerate(pick): json.dump(f,open("withdrawal-fixtures/f%d.json"%i,"w"),indent=1)
for i,f in enumerate(ref): json.dump(f,open("withdrawal-fixtures/ref%d.json"%i,"w"),indent=1)
