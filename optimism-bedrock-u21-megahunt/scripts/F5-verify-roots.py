#!/usr/bin/env python3
"""F5: recompute the output root of every NON-RETIRED dispute game from the L2 block header and compare with the
game's claim.  Post-Isthmus: outputRoot = keccak(bytes32(0) ++ stateRoot ++ header.withdrawalsRoot ++ blockHash).
Legacy types (0,1,8): l2BlockNumber -> header.  Super types (4,5,9): extraData = 0x01 ++ uint64 timestamp ++ (chainId ++ outputRoot)*,
checked for exactly one entry with the chain's id, block = genesisNumber + (timestamp - genesisTime) / blockTime.
Passive reads only: L1 eth_call (Multicall3 @ pinned block) + L2 eth_getBlockByNumber on a public RPC.
usage: F5-verify-roots.py <census.json> <chainId> <l2rpc> <genesisTime> <genesisNumber> <blockTime> <out.json>"""
import json, sys, time, urllib.request, collections
sys.path.insert(0, "scripts")
from F5_keccak import keccak256
from F5_lib import rpc as l1rpc, PIN, w, sig
census, chain_id, L2, gtime, gnum, btime, OUT = sys.argv[1], int(sys.argv[2]), sys.argv[3], int(sys.argv[4]), int(sys.argv[5]), int(sys.argv[6]), sys.argv[7]
ISTHMUS = 1746806401
MC = "0xcA11bde05977b3631167028862bE2a173976CA11"
games = [g for g in json.load(open(census)) if not g["retired"]]
print(f"non-retired games: {len(games)}", flush=True)

def post(url, body, tries=8):
    for a in range(tries):
        try:
            req = urllib.request.Request(url, data=json.dumps(body).encode(), headers={"Content-Type": "application/json", "User-Agent": "rpc-client"})
            with urllib.request.urlopen(req, timeout=60) as r:
                j = json.loads(r.read())
            if isinstance(body, list):
                if isinstance(j, list) and len(j) == len(body) and all("result" in x for x in j):
                    return {x["id"]: x["result"] for x in j}
            elif "result" in j:
                return j["result"]
        except Exception as e:  # noqa
            pass
        time.sleep(1 + a)
    raise RuntimeError("l2 rpc failed")

def enc_aggregate3(calls):
    n = len(calls); elems = []
    for t, d in calls:
        bl = len(d) // 2; pad = (32 - bl % 32) % 32
        elems.append(w(int(t, 16)) + w(1) + w(0x60) + w(bl) + d + "00" * pad)
    offs, cur = [], 32 * n
    for e in elems:
        offs.append(cur); cur += len(e) // 2
    return "0x82ad56cb" + w(0x20) + w(n) + "".join(w(o) for o in offs) + "".join(elems)
def dec_aggregate3(raw):
    h = raw[2:]; base = int(h[0:64], 16) * 2; n = int(h[base:base + 64], 16); arr = base + 64; out = []
    for i in range(n):
        o = arr + int(h[arr + 64 * i: arr + 64 * (i + 1)], 16) * 2
        ok = int(h[o:o + 64], 16) == 1
        bo = o + int(h[o + 64:o + 128], 16) * 2; bl = int(h[bo:bo + 64], 16)
        out.append((ok, h[bo + 64: bo + 64 + 2 * bl]))
    return out

# 1. super games: fetch extraData at the pinned L1 block
SUPER = {4, 5, 7, 9, 10}
sg = [g for g in games if g["type"] in SUPER]
XD = sig("extraData()")[2:]
for i in range(0, len(sg), 40):
    part = sg[i:i + 40]
    res = dec_aggregate3(l1rpc("eth_call", [{"to": MC, "data": enc_aggregate3([(g["game"], XD) for g in part])}, hex(PIN)]))
    for g, (ok, ret) in zip(part, res):
        ln = int(ret[64:128], 16); xd = ret[128:128 + 2 * ln]
        g["extraData"] = "0x" + xd
        ver = int(xd[0:2], 16); ts = int(xd[2:18], 16); body = xd[18:]
        ents = [(int(body[k:k + 64], 16), "0x" + body[k + 64:k + 128]) for k in range(0, len(body), 128)]
        g["super"] = dict(version=ver, timestamp=ts, entries=ents)
        g["superHashOk"] = ("0x" + keccak256(bytes.fromhex(xd)).hex()) == g["rootClaim"]
        g["claimedOutput"] = next((r for c, r in ents if c == chain_id), None)
        g["l2Block"] = gnum + (ts - gtime) // btime
        g["tsAligned"] = (ts - gtime) % btime == 0
for g in games:
    if g["type"] not in SUPER:
        g["claimedOutput"] = g["rootClaim"]

# 2. headers
need = sorted({g["l2Block"] for g in games if g["l2Block"] is not None})
hdr = {}
HB = int(__import__("os").environ.get("F5_HDR_BATCH", "10"))
for i in range(0, len(need), HB):
    part = need[i:i + HB]
    r = post(L2, [{"jsonrpc": "2.0", "id": n, "method": "eth_getBlockByNumber", "params": [hex(n), False]} for n in part])
    for n in part:
        b = r[n]
        if b is None:
            hdr[n] = None
            continue
        hdr[n] = dict(ts=int(b["timestamp"], 16), stateRoot=b["stateRoot"], wr=b.get("withdrawalsRoot"), hash=b["hash"])
    if (i // HB) % 50 == 0:
        print(f"headers {i}/{len(need)}", flush=True)

ST = {0: "IN_PROGRESS", 1: "CHALLENGER_WINS", 2: "DEFENDER_WINS"}
tab = collections.Counter(); bad = []
for g in games:
    h = hdr[g["l2Block"]]
    if h is None:
        g["match"] = "NO_SUCH_L2_BLOCK"
    elif h["ts"] < ISTHMUS or not h["wr"]:
        g["match"] = None
    else:
        comp = "0x" + keccak256(bytes(32) + bytes.fromhex(h["stateRoot"][2:]) + bytes.fromhex(h["wr"][2:]) + bytes.fromhex(h["hash"][2:])).hex()
        g["computedOutput"] = comp
        g["match"] = comp == g["claimedOutput"]
        if g["type"] in SUPER:
            g["match"] = g["match"] and g["superHashOk"] and len(g["super"]["entries"]) == 1 and g["super"]["version"] == 1 and h["ts"] == g["super"]["timestamp"]
    tab[(g["type"], ST[g["status"]], g["claimValid"], g["match"])] += 1
    if (g["match"] is not True and (g["claimValid"] or g["status"] != 1)) or (g["match"] is True and g["status"] == 1):
        bad.append(g)
json.dump(dict(games=games, table={str(k): v for k, v in tab.items()}), open(OUT, "w"))
print("\n(type, status, claimValid, headerMatch) -> count")
for k, v in sorted(tab.items(), key=lambda z: -z[1]):
    print(" ", k, v)
print(f"\nANOMALIES (non-matching root that is claim-valid / not CHALLENGER_WINS, or matching root that lost): {len(bad)}")
for g in bad[:60]:
    print("  ", g["index"], "type", g["type"], g["game"], "creator", g["creator"], ST[g["status"]], "claimValid", g["claimValid"], "l2Block", g["l2Block"],
          "claimed", g["claimedOutput"], "computed", g.get("computedOutput"), "superHashOk", g.get("superHashOk"), "entries", len(g.get("super", {}).get("entries", [])) if g.get("super") else "-", "tsAligned", g.get("tsAligned"))
