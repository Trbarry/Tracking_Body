#!/usr/bin/env python3
"""Build chains/<CHAIN>/UPGRADE-PATH.json: per upgrade tx, per proxy, the final implementation + version."""
import json, sys, collections, datetime, os
sys.path.insert(0, "scripts")
from F5_lib import *
vc = json.load(open("evidence/F5/impl-version-cache.json"))
def ver(a):
    a = a.lower()
    if a not in vc:
        v = as_str(call(a, "version()")); vc[a] = v if v else "<none>"
    return vc[a]
d = lambda t: datetime.datetime.fromtimestamp(t, datetime.UTC).strftime('%Y-%m-%d %H:%M:%S')
STORAGE_SETTERS = {"0x2476c911e6d4d9411e677d8faf15a64ac1fdeee8", "0xd81f43edbcacb4c29a9ba38a13ee5d79278270cc"}
for chain in sys.argv[1:]:
    s = json.load(open(f"evidence/F5/{chain}-history-raw.json"))
    txs = collections.OrderedDict()
    def add(block, tx, proxy, impl, viaSS=False):
        k = (block, tx)
        txs.setdefault(k, collections.OrderedDict())
        e = txs[k].setdefault(proxy, dict(impls=[], storageSetter=False))
        if impl.lower() in STORAGE_SETTERS:
            e["storageSetter"] = True
        else:
            e["impls"].append(impl.lower())
    am = s["contracts"]["AddressManager"]
    for name, r in s["contracts"].items():
        for e in r["events"]:
            n = e["event"].split("(")[0]
            if n == "Upgraded":
                add(e["block"], e["tx"], name, "0x" + e["topics"][0][-40:])
            if name == "AddressManager" and n == "AddressSet":
                add(e["block"], e["tx"], "L1CrossDomainMessenger(AddressManager)", "0x" + e["data"][26:66])
        if "implSlotHistory" in r:
            for b, a in r["implSlotHistory"]:
                if a and int(a, 16):
                    add(b, None, "L1StandardBridge(slot)", a)
    # merge L1SB slot history (tx None) into the tx of the same block
    merged = collections.OrderedDict()
    byblock = collections.defaultdict(list)
    for (b, tx) in txs:
        byblock[b].append(tx)
    for (b, tx), v in sorted(txs.items(), key=lambda z: (z[0][0], z[0][1] is None)):
        if tx is None:
            real = [t for t in byblock[b] if t]
            tgt = (b, real[0]) if len(real) == 1 else (b, None)
            merged.setdefault(tgt, collections.OrderedDict()).update(v)
        else:
            merged.setdefault((b, tx), collections.OrderedDict()).update(v)
    out = []
    for (b, tx), v in sorted(merged.items(), key=lambda z: z[0][0]):
        ts = block_ts(b)
        row = dict(block=b, time=d(ts), tx=tx, proxies={})
        for p, e in v.items():
            fin = e["impls"][-1] if e["impls"] else None
            row["proxies"][p] = dict(impl=fin, version=ver(fin) if fin else None, storageSetterCycle=e["storageSetter"], upgradedEvents=len(e["impls"]))
        out.append(row)
        print(f"{b} {d(ts)[:10]} {str(tx)[:12]} " + ", ".join(f"{p.replace('(AddressManager)','').replace('(slot)','')}={x['version']}{'*' if x['storageSetterCycle'] else ''}" for p, x in row["proxies"].items()))
    os.makedirs(f"chains/{chain}", exist_ok=True)
    json.dump(out, open(f"evidence/F5/{chain}-upgrade-txs.json", "w"), indent=1)
    json.dump(vc, open("evidence/F5/impl-version-cache.json", "w"), indent=1)
    print()
