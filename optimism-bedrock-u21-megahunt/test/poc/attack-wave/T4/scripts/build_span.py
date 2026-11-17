#!/usr/bin/env python3
"""ATK-T4: span-batch cases from the cached OP blocks (no new RPC: cache only).
Usage: build_span.py <cachedir-parent> <real-cases.jsonl> <out.jsonl>"""
import json, os, sys, importlib.util
OUT = sys.argv[1]
spec = importlib.util.spec_from_file_location("fr", os.path.join(os.path.dirname(os.path.abspath(__file__)), "fetch_real.py"))
sys_argv = sys.argv; sys.argv = [sys.argv[0], OUT]
fr = importlib.util.module_from_spec(spec); spec.loader.exec_module(fr)
fr.rpc_orig = fr.rpc
def cache_only(url, method, params):
    import hashlib
    key = hashlib.sha256(json.dumps([url, method, params]).encode()).hexdigest()
    return json.load(open(os.path.join(fr.CACHE, key + ".json")))
fr.rpc = cache_only
real = [json.loads(l) for l in open(sys_argv[2])]
from collections import Counter
types = Counter(); n = 0
with open(sys_argv[3], "w") as f:
    for c in real:
        num = int(c["id"].split(":")[1])
        b = fr.l2block(num)
        txs = [t for t in b["transactions"] if t["type"] != "0x7e"]
        for t in txs:
            types[t["type"]] += 1
        n += len(txs)
        if txs:
            f.write(json.dumps({"k": "span", "id": f"span:{num}", "chain_id": 10, "rpc_txs": txs}) + "\n")
print("user txs", n, dict(types), file=sys.stderr)
