#!/usr/bin/env python3
"""ATK-T4: sysfrom cases (parent L2 block -> SystemConfig) from the cache only, plus comparator.
Usage: build_sysfrom.py <dir> <real-cases.jsonl> <out.jsonl>"""
import json, os, sys, importlib.util, hashlib
OUT = sys.argv[1]
spec = importlib.util.spec_from_file_location("fr", os.path.join(os.path.dirname(os.path.abspath(__file__)), "fetch_real.py"))
args = sys.argv; sys.argv = [sys.argv[0], OUT]
fr = importlib.util.module_from_spec(spec); spec.loader.exec_module(fr)
def cache_only(url, method, params):
    key = hashlib.sha256(json.dumps([url, method, params]).encode()).hexdigest()
    return json.load(open(os.path.join(fr.CACHE, key + ".json")))
fr.rpc = cache_only
with open(args[3], "w") as f:
    for c in (json.loads(l) for l in open(args[2])):
        p = fr.l2block(c["parent"]["number"])
        t0 = p["transactions"][0]
        f.write(json.dumps({"k": "sysfrom", "id": c["id"], "chain": 10, "header": fr.hdr(p), "hash": p["hash"],
                            "tx0": {k: t0.get(k) for k in ("sourceHash", "from", "to", "mint", "value", "gas", "isSystemTx", "input", "hash")},
                            "expect_sys": c["sys"]}) + "\n")
