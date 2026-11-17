import json, sys, time, urllib.request, os
RPC = "https://mainnet.optimism.io"
MP = "0x4200000000000000000000000000000000000016"
TOPIC = "0x02a52367d10742d8032712c1bb8e0144ff1ec5ffda1ed7d70bb05a2744955054"
def rpc(method, params):
    req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(), headers={"Content-Type":"application/json","User-Agent":"research-client"})
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                out = json.loads(r.read())
            if "error" in out: raise Exception(out["error"])
            return out["result"]
        except Exception as e:
            err = e; time.sleep(2+attempt*2)
    raise err
start, end, step = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3])
outp = sys.argv[4]
res = []
b = start
while b <= end:
    t = min(b+step-1, end)
    logs = rpc("eth_getLogs", [{"fromBlock":hex(b),"toBlock":hex(t),"address":MP,"topics":[TOPIC]}])
    res.extend(logs)
    print(b, t, len(logs), file=sys.stderr)
    b = t+1
    time.sleep(0.3)
json.dump(res, open(outp,"w"))
print(len(res))
