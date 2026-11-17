import json, urllib.request, sys, subprocess
RPC="http://127.0.0.1:7545"
D=sys.argv[1]
d=json.load(open(D+"/scan-failures-all-chains.json"))
def rpc(m,p):
    r=urllib.request.Request(RPC,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"content-type":"application/json"})
    j=json.load(urllib.request.urlopen(r,timeout=300)); 
    if "error" in j: raise Exception(j["error"])
    return j["result"]
CDM={v:k for k,v in d["addrs"].items()}
RELAY="0xd764ad0b"
def walk(c,acc,depth=0):
    acc.append((depth,c))
    for s in c.get("calls",[]) or []: walk(s,acc,depth+1)
def dec(sig,data):
    out=subprocess.run(["cast","decode-calldata",sig,data],capture_output=True,text=True).stdout.strip().split("\n")
    return out
def call(to,sig,args,blk=26433900):
    return subprocess.run(["cast","call",to,sig]+args+["-r",RPC,"-b",str(blk)],capture_output=True,text=True).stdout.strip()
rows=[]
traces={}
for h in d["hits"]:
    if h["tx"] not in traces:
        traces[h["tx"]]=rpc("debug_traceTransaction",[h["tx"],{"tracer":"callTracer"}])
    tr=traces[h["tx"]]; acc=[]; walk(tr,acc)
    chain=h["who"].split("-")[0]
    cdm=CDM[chain+"-cdm"]; portal=CDM[chain+"-portal"]
    row=dict(h); row["outer_to"]=tr["to"]; row["outer_from"]=tr["from"]; row["tx_status"]=("reverted" if tr.get("error") else "ok")
    rel=[c for dp,c in acc if c.get("to","").lower()==cdm and c.get("input","").startswith(RELAY)]
    fin=[c for dp,c in acc if c.get("to","").lower()==portal and c.get("input","")[:10] in ("0x8c3152e9","0x2a40bd7b","0x55ac6a8c")]
    row["n_relay_calls"]=len(rel); row["n_portal_finalize"]=len(fin)
    if h["ev"]=="FRM":
        for c in rel:
            a=dec("relayMessage(uint256,address,address,uint256,uint256,bytes)",c["input"])
            hv=subprocess.run(["cast","keccak",subprocess.run(["cast","calldata","relayMessage(uint256,address,address,uint256,uint256,bytes)"]+[x.split(" ")[0] for x in a],capture_output=True,text=True).stdout.strip()],capture_output=True,text=True).stdout.strip()
            if hv.lower()==h["hash"].lower():
                row.update(nonce=a[0].split(" ")[0],sender=a[1],target=a[2],value_wei=a[3].split(" ")[0],minGas=a[4].split(" ")[0],msg=a[5][:200],call_value=int(c.get("value","0x0"),16),caller=c["from"],relay_error=c.get("error"))
        row["successful_now"]=call(cdm,"successfulMessages(bytes32)(bool)",[h["hash"]])
        row["failed_now"]=call(cdm,"failedMessages(bytes32)(bool)",[h["hash"]])
    else:
        for c in fin:
            row["fin_input"]=c["input"][:1000]; row["fin_error"]=c.get("error")
            try:
                a=dec("finalizeWithdrawalTransaction((uint256,address,address,uint256,uint256,bytes))","0x8c3152e9"+c["input"][10:]) if c["input"][:10]=="0x8c3152e9" else dec("finalizeWithdrawalTransactionExternalProof((uint256,address,address,uint256,uint256,bytes),address)","0x"+c["input"][2:])
                row["wtx"]=a
            except Exception as e: row["wtx"]=str(e)
            sub=[]; walk(c,sub)
            row["subcalls"]=[(dp,s.get("to"),s.get("input","")[:10],int(s.get("value","0x0"),16),s.get("error")) for dp,s in sub[:12]]
    rows.append(row); print(json.dumps({k:row.get(k) for k in ["who","ev","block","hash","sender","target","value_wei","call_value","caller","successful_now","failed_now","outer_to","n_relay_calls"]}),flush=True)
json.dump(rows,open(D+"/census-decoded.json","w"),indent=1)
