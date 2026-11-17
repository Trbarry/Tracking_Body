import json, urllib.request, time, sys
def rpc(url, method, params, retries=5):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    for i in range(retries):
        try:
            req = urllib.request.Request(url, data=body, headers={"content-type":"application/json"})
            r = json.loads(urllib.request.urlopen(req, timeout=120).read())
            if "error" in r: raise Exception(str(r["error"]))
            return r["result"]
        except Exception as e:
            last = e; time.sleep(1.5*(i+1))
    raise last
def logs(url, addr, topics, start, end, chunk=100000, sleep=0.2):
    out=[]; b=start
    while b<=end:
        e=min(b+chunk-1,end)
        try:
            r=rpc(url,"eth_getLogs",[{"address":addr,"topics":topics,"fromBlock":hex(b),"toBlock":hex(e)}],retries=2)
            out+=r; b=e+1; time.sleep(sleep)
        except Exception as ex:
            if chunk<=1000: raise
            chunk//=4; print("shrink",chunk,str(ex)[:100],file=sys.stderr)
    return out
