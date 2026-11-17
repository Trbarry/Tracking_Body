import json, sys, subprocess, urllib.request
L1="http://127.0.0.1:8545"
PORTAL="0xbEb5Fc579115071764c7423A4f12eDde41f106Ed"
def call(to,data,block="latest"):
    req=urllib.request.Request(L1,data=json.dumps({"jsonrpc":"2.0","id":1,"method":"eth_call","params":[{"to":to,"data":data},block]}).encode(),headers={"Content-Type":"application/json"})
    import time
    for a in range(6):
        out=json.loads(urllib.request.urlopen(req,timeout=120).read())
        if "error" in out:
            e=out["error"]
            if "Fork Error" in str(e) or e.get("code")==-32603 and not e.get("data"):
                time.sleep(2+2*a); continue
            return None, e
        return out["result"], None
    raise Exception(str(out))
def sel(sig): return subprocess.check_output(["cast","sig",sig]).decode().strip()
S_FIN=sel("finalizedWithdrawals(bytes32)"); S_NUM=sel("numProofSubmitters(bytes32)"); S_SUB=sel("proofSubmitters(bytes32,uint256)"); S_PW=sel("provenWithdrawals(bytes32,address)"); S_CHK=sel("checkWithdrawal(bytes32,address)")
logs=json.load(open("data/l2_withdrawals.json"))
out=[]
for l in logs:
    t=l["topics"]; d=bytes.fromhex(l["data"][2:])
    nonce=int(t[1],16); sender="0x"+t[2][-40:]; target="0x"+t[3][-40:]
    value=int.from_bytes(d[0:32],"big"); gas=int.from_bytes(d[32:64],"big"); off=int.from_bytes(d[64:96],"big"); wh="0x"+d[96:128].hex()
    ln=int.from_bytes(d[off:off+32],"big"); data="0x"+d[off+32:off+32+ln].hex()
    fin,_=call(PORTAL,S_FIN+wh[2:]); fin=int(fin,16)
    n,_=call(PORTAL,S_NUM+wh[2:]); n=int(n,16)
    subs=[]
    for i in range(n):
        s,_=call(PORTAL,S_SUB+wh[2:]+hex(i)[2:].rjust(64,"0")); s="0x"+s[-40:]
        pw,_=call(PORTAL,S_PW+wh[2:]+s[2:].rjust(64,"0")); game="0x"+pw[26:66]; ts=int(pw[66:130],16)
        chk,err=call(PORTAL,S_CHK+wh[2:]+s[2:].rjust(64,"0"))
        subs.append({"submitter":s,"game":game,"ts":ts,"check_ok":err is None,"err":(err or {}).get("data") if err else None})
    rec={"l2block":int(l["blockNumber"],16),"nonce":hex(nonce),"sender":sender,"target":target,"value":str(value),"gasLimit":gas,"data":data,"hash":wh,"finalized":fin,"subs":subs}
    out.append(rec)
json.dump(out,open("data/classified.json","w"),indent=1)
import collections
c=collections.Counter()
for r in out:
    k=("fin" if r["finalized"] else ("unproven" if not r["subs"] else ("ready" if any(s["check_ok"] for s in r["subs"]) else "proven-notready")))
    c[k]+=1
print(len(out),c)
