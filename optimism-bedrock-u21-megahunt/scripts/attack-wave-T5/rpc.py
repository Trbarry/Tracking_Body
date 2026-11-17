"""Read-only JSON-RPC helper for lane ATK-T2. Only local proxies :7545 (L1) / :7546 (OP L2).
Methods used: eth_getLogs, eth_getStorageAt, eth_call, eth_getProof, eth_getBlockByNumber, eth_getTransactionByHash."""
import json, time, urllib.request
L1 = "http://127.0.0.1:7545"
L2 = "http://127.0.0.1:7546"
ALLOWED = {"eth_getBalance","eth_getLogs","eth_getStorageAt","eth_call","eth_getProof","eth_getBlockByNumber","eth_getTransactionByHash","eth_blockNumber","eth_getCode","eth_getTransactionReceipt"}
def call(url, method, params, retries=6):
    assert url in (L1, L2) and method in ALLOWED
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    for k in range(retries):
        try:
            req = urllib.request.Request(url, body, {"content-type":"application/json"})
            r = json.load(urllib.request.urlopen(req, timeout=300))
            if "error" in r: raise RuntimeError(r["error"])
            time.sleep(0.05)
            return r["result"]
        except Exception as e:
            if k == retries-1: raise
            time.sleep(2*(k+1))
def batch(url, reqs):
    """reqs: list of (method, params); sequential JSON-RPC batch of at most 50."""
    out=[]
    for i in range(0,len(reqs),50):
        chunk=reqs[i:i+50]
        for m,_ in chunk: assert m in ALLOWED
        body=json.dumps([{"jsonrpc":"2.0","id":j,"method":m,"params":p} for j,(m,p) in enumerate(chunk)]).encode()
        for k in range(6):
            try:
                r=json.load(urllib.request.urlopen(urllib.request.Request(url,body,{"content-type":"application/json"}),timeout=300))
                if isinstance(r,dict): raise RuntimeError(r)
                r=sorted(r,key=lambda x:x["id"])
                if any("error" in x for x in r): raise RuntimeError([x for x in r if "error" in x][0])
                out.extend(x["result"] for x in r); break
            except Exception as e:
                if k==5: raise
                time.sleep(2*(k+1))
        time.sleep(0.1)
    return out
