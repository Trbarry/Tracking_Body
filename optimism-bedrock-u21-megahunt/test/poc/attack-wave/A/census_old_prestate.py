#!/usr/bin/env python3
"""ATK-A census: type-9 games on OP/Ink/Unichain whose absolutePrestate is the pre-U21
kona-client v1.7.0 prestate, with status/clock at a pinned L1 block. Read-only eth_call."""
import json, sys, urllib.request
RPC = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:7545"
BLOCK = sys.argv[2] if len(sys.argv) > 2 else "latest"
OLD = "0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df"
NEW = "0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9"
U21_TS = 1794871439
DGF = {"op": "0xe5965Ab5962eDc7477C8520243A95517CD252fA9",
       "ink": "0x10d7B35078d3baabB96Dd45a9143B94be65b12CD",
       "unichain": "0x2F12d621a16e2d3285929C9996f478508951dFe4"}
_id = 0
def batch(calls):
    global _id
    reqs = []
    for to, data in calls:
        _id += 1
        reqs.append({"jsonrpc": "2.0", "id": _id, "method": "eth_call",
                     "params": [{"to": to, "data": data}, BLOCK]})
    out = []
    for i in range(0, len(reqs), 50):
        chunk = reqs[i:i+50]
        r = urllib.request.Request(RPC, json.dumps(chunk).encode(), {"content-type": "application/json"})
        res = json.loads(urllib.request.urlopen(r, timeout=120).read())
        m = {x["id"]: x.get("result") for x in res}
        out += [m[q["id"]] for q in chunk]
    return out
def u(x): return int(x, 16) if x and x != "0x" else None
def word(x, i): return x[2+64*i:2+64*(i+1)]
blk = json.loads(urllib.request.urlopen(urllib.request.Request(RPC, json.dumps(
    {"jsonrpc":"2.0","id":0,"method":"eth_getBlockByNumber","params":[BLOCK, False]}).encode(),
    {"content-type":"application/json"})).read())["result"]
now = int(blk["timestamp"], 16)
print(f"# L1 block {int(blk['number'],16)} ts {now}")
summary = {}
for chain, dgf in DGF.items():
    n = u(batch([(dgf, "0x4d1975b4")])[0])
    # walk back from the newest index until creation < U21_TS - 8 days
    games, i = [], n - 1
    while i >= 0:
        idxs = list(range(i, max(-1, i - 50), -1))
        res = batch([(dgf, "0xbb8aa1fc" + f"{j:064x}") for j in idxs])
        stop = False
        for j, r in zip(idxs, res):
            gt, ts, proxy = u(word(r, 0)), u(word(r, 1)), "0x" + word(r, 2)[24:]
            if ts < U21_TS - 8 * 86400: stop = True; break
            games.append((j, gt, ts, proxy))
        if stop: break
        i -= 50
    t9 = [g for g in games if g[1] == 9]
    pres = batch([(g[3], "0x8d450a95") for g in t9])
    sts = batch([(g[3], "0x200d2ed2") for g in t9])
    cdl = batch([(g[3], "0x8980e0cc") for g in t9])
    mcd = batch([(g[3], "0xdabd396d") for g in t9])
    chd = batch([(g[3], "0xbd8da956" + "0"*64) for g in t9])
    rows = []
    for g, p, s, c, m, cd in zip(t9, pres, sts, cdl, mcd, chd):
        rows.append(dict(idx=g[0], created=g[2], proxy=g[3], prestate="old" if p == OLD else ("new" if p == NEW else p),
                         status=u(s), claims=u(c), maxClock=u(m), rootChallengerDur=u(cd)))
    old = [r for r in rows if r["prestate"] == "old"]
    old_ip = [r for r in old if r["status"] == 0]
    summary[chain] = dict(gameCount=n, type9_scanned=len(rows), old_prestate=len(old),
                          old_in_progress=len(old_ip),
                          old_in_progress_multi_claim=[r for r in old_ip if r["claims"] > 1],
                          newest_old_created=max([r["created"] for r in old], default=None),
                          oldest_old_in_progress_created=min([r["created"] for r in old_ip], default=None),
                          last_possible_resolution=(max([r["created"] for r in old_ip], default=0) + 2*rows[0]["maxClock"]) if old_ip else None,
                          non_old_non_new=[r for r in rows if r["prestate"] not in ("old", "new")])
    print(f"## {chain}: gameCount {n}, type9 in window {len(rows)}, old-prestate {len(old)}, old IN_PROGRESS {len(old_ip)}")
    for r in old_ip:
        print(f"  idx {r['idx']} {r['proxy']} created {r['created']} claims {r['claims']} rootChallengerDur {r['rootChallengerDur']}/{r['maxClock']}")
print("SUMMARY " + json.dumps(summary, default=str))
