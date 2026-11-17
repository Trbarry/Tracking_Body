import json, sys, time, urllib.request
RPC="http://127.0.0.1:7545"
def rpc(m,p):
    r=urllib.request.Request(RPC,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"content-type":"application/json"})
    return json.loads(urllib.request.urlopen(r,timeout=120).read())
TOP={"0x192c289026d59a41a27f5aea08f3969b57931b0589202d14f4368cded95d3cda":"DisputeGameBlacklisted","0x6e5b1ba771e8e484f741ed085f039ff4e5c6e882eaf68f550fb390922d0ae4a7":"RetirementTimestampSet","0xcee0703b5e4bad4efededab85c9fd1aec17dee7c5f6c584330e0509b677745a2":"RespectedGameTypeSet"}
asrs={"op":"0x23B2C62946350F4246f9f9D027e071f0264FD113","ink":"0xEe018bAf058227872540AC60eFbd38b023d9dAe2","soneium":"0x4890928941e62e273dA359374b105F803329F473","unichain":"0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9"}
start,end,step=22980000,26433900,500000
out={}
for n,a in asrs.items():
    res=[]; b=start
    while b<=end:
        e=min(end,b+step-1)
        r=rpc("eth_getLogs",[{"address":a,"fromBlock":hex(b),"toBlock":hex(e),"topics":[list(TOP.keys())]}])
        if "error" in r: print(r); step//=2; continue
        for l in r["result"]:
            res.append({"event":TOP[l["topics"][0]],"block":int(l["blockNumber"],16),"tx":l["transactionHash"],"topics":l["topics"][1:],"data":l["data"]})
        b=e+1; time.sleep(0.2)
    out[n]=res
    print(n,[ (x["event"],x["block"]) for x in res])
json.dump(out,open(sys.argv[1],"w"),indent=1)
