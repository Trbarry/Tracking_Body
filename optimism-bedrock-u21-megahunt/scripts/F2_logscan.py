#!/usr/bin/env python3
"""F2 — chunked eth_getLogs scan (<=10k blocks per call) for one address. Read-only.
usage: F2_logscan.py <rpc> <address> <from_block> <to_block> <out.json> [topic0]
Records every log (block, tx, topics, data). Failed chunks are retried, then split; any chunk
that still fails is listed under "failed_ranges" so gaps are explicit."""
import json, sys, time, urllib.request
rpc, addr, lo, hi, out = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), sys.argv[5]
topic0 = sys.argv[6] if len(sys.argv) > 6 else None

def call(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(rpc, data=body, headers={"content-type": "application/json"})
    with urllib.request.urlopen(req, timeout=120) as r:
        res = json.loads(r.read())
    if "error" in res:
        raise RuntimeError(str(res["error"])[:200])
    return res["result"]

logs, failed = [], []
def scan(a, b, depth=0):
    f = {"fromBlock": hex(a), "toBlock": hex(b), "address": addr}
    if topic0:
        f["topics"] = [topic0]
    for attempt in range(5):
        try:
            logs.extend(call("eth_getLogs", [f]))
            return
        except Exception as e:
            err = str(e)
            time.sleep(1 + attempt)
    if b - a >= 2000 and depth < 3:
        m = (a + b) // 2
        scan(a, m, depth + 1); scan(m + 1, b, depth + 1)
    else:
        failed.append([a, b, err])

CH = 10000
n = 0
for a in range(lo, hi + 1, CH):
    scan(a, min(a + CH - 1, hi))
    n += 1
    if n % 50 == 0:
        print(a, len(logs), len(failed), flush=True)
blocks = sorted({int(l["blockNumber"], 16) for l in logs})
ts = {}
for b in blocks:
    for _ in range(6):
        try:
            ts[b] = int(call("eth_getBlockByNumber", [hex(b), False])["timestamp"], 16); break
        except Exception:
            time.sleep(1)
rows = [{"block": int(l["blockNumber"], 16), "utc": time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime(ts.get(int(l["blockNumber"], 16), 0))),
         "tx": l["transactionHash"], "logIndex": int(l["logIndex"], 16), "topics": l["topics"], "data": l["data"]} for l in logs]
rows.sort(key=lambda r: (r["block"], r["logIndex"]))
json.dump({"rpc": rpc, "address": addr, "from": lo, "to": hi, "topic0": topic0, "chunk": CH,
           "failed_ranges": failed, "logs": rows}, open(out, "w"), indent=1)
print("done", len(rows), "logs", len(failed), "failed ranges")
