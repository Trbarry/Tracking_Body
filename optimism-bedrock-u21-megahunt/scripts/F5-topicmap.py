#!/usr/bin/env python3
"""Build topic0 -> {event signature, contracts, versions} from every ABI snapshot of every pinned release."""
import json, glob, os, subprocess, collections
roots = sorted(glob.glob("/home/user/ethereum-optimism/hist/v*/packages/contracts-bedrock/snapshots/abi")) + \
        ["/home/user/ethereum-optimism/op-v%d.0.0/packages/contracts-bedrock/snapshots/abi" % i for i in (7, 8, 9)]
def ty(i):
    t = i["type"]
    if t.startswith("tuple"):
        return "(" + ",".join(ty(c) for c in i["components"]) + ")" + t[5:]
    return t
sigs = collections.defaultdict(lambda: dict(contracts=set(), versions=set(), indexed=None))
for r in roots:
    ver = r.split("/hist/")[1].split("/")[0] if "/hist/" in r else r.split("/")[4]
    for f in glob.glob(r + "/*.json"):
        try:
            abi = json.load(open(f))
        except Exception:
            continue
        for e in abi:
            if e.get("type") != "event":
                continue
            s = e["name"] + "(" + ",".join(ty(i) for i in e["inputs"]) + ")"
            sigs[s]["contracts"].add(os.path.basename(f)[:-5])
            sigs[s]["versions"].add(ver)
            sigs[s]["indexed"] = [bool(i.get("indexed")) for i in e["inputs"]]
            sigs[s]["names"] = [i.get("name") for i in e["inputs"]]
# extra legacy events
for s, idx in [("AddressSet(string,address,address)", [True, False, False])]:
    sigs[s]["contracts"].add("AddressManager"); sigs[s]["indexed"] = idx; sigs[s]["names"] = ["name", "newAddress", "oldAddress"]
out = {}
allsigs = sorted(sigs)
for i in range(0, len(allsigs), 1):
    s = allsigs[i]
    t = subprocess.run(["cast", "keccak", s], capture_output=True, text=True).stdout.strip()
    out[t] = dict(sig=s, contracts=sorted(sigs[s]["contracts"])[:12], versions=sorted(sigs[s]["versions"]), indexed=sigs[s]["indexed"], names=sigs[s].get("names"))
json.dump(out, open("evidence/F5/topicmap.json", "w"), indent=1)
print(len(out), "event topics")
