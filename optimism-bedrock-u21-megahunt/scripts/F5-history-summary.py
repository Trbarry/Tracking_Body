#!/usr/bin/env python3
"""Compact timeline from evidence/F5/<CHAIN>-history-raw.json (+ impl version lookups, cached)."""
import json, sys, datetime, os, collections
sys.path.insert(0, "scripts")
from F5_lib import *
CACHE = "evidence/F5/impl-version-cache.json"
vc = json.load(open(CACHE)) if os.path.exists(CACHE) else {}
def ver(a):
    a = a.lower()
    if a not in vc:
        v = as_str(call(a, "version()"))
        vc[a] = v if v else ("<no version(); codeSize %d>" % ((len(code(a)) - 2) // 2))
    return vc[a]
d = lambda t: datetime.datetime.fromtimestamp(t, datetime.UTC).strftime('%Y-%m-%d')
tsc = {}
def bts(b):
    if b not in tsc: tsc[b] = block_ts(b)
    return tsc[b]
chain = sys.argv[1]
raw = json.load(open(f"evidence/F5/{chain}-history-raw.json"))
out = dict(chain=chain, proxies={})
for n, r in raw["contracts"].items():
    print(f"\n== {n} {r['address']} born L1 block {r['firstCodeBlock']} ({d(r['firstCodeTs'])}) implAtBirth {r.get('implSlotAtBirth')} adminAtBirth {r.get('adminSlotAtBirth')}")
    rec = dict(address=r["address"], bornBlock=r["firstCodeBlock"], bornDate=d(r["firstCodeTs"]), upgrades=[], otherEvents=[])
    cnt = collections.Counter()
    last = None
    for e in r["events"]:
        name = e["event"].split("(")[0]
        if name == "Upgraded":
            impl = "0x" + e["topics"][0][-40:]
            u = dict(block=e["block"], date=d(bts(e["block"])), tx=e["tx"], impl=impl, version=ver(impl))
            rec["upgrades"].append(u)
            print(f"   {u['block']} {u['date']} {e['tx'][:12]} Upgraded -> {impl} {u['version']}")
        elif name in ("AnchorUpdated", "ConfigUpdate", "Initialized"):
            cnt[name] += 1
            if name == "Initialized":
                print(f"   {e['block']} {d(bts(e['block']))} {e['tx'][:12]} Initialized {int(e['data'],16) if e['data']!='0x' else e['topics']}")
                rec["otherEvents"].append(dict(block=e["block"], tx=e["tx"], event=e["event"], value=int(e['data'],16) if e['data']!='0x' else None))
        else:
            tt = [("0x"+t[-40:] if t[2:26]=="0"*24 and int(t,16)>2**40 else str(int(t,16)) if int(t,16)<2**64 else t) for t in e["topics"]]
            print(f"   {e['block']} {d(bts(e['block']))} {e['tx'][:12]} {e['event']} {tt} {e['data'][:194] if len(e['data'])>2 else ''}")
            rec["otherEvents"].append(dict(block=e["block"], date=d(bts(e["block"])), tx=e["tx"], event=e["event"], topics=tt, data=e["data"][:514]))
    if cnt: print("   [counted]", dict(cnt))
    if "implSlotHistory" in r:
        rec["implSlotHistory"] = [dict(block=b, date=d(bts(b)), impl=a, version=ver(a) if a and int(a,16) else None) for b, a in r["implSlotHistory"]]
        for x in rec["implSlotHistory"]: print("   implSlot", x)
    out["proxies"][n] = rec
    json.dump(vc, open(CACHE, "w"), indent=1)
json.dump(out, open(f"evidence/F5/{chain}-history-summary.json", "w"), indent=1)
