#!/usr/bin/env python3
"""F5 — passive census of every dispute game of a DisputeGameFactory at a pinned L1 block.

Parameterised re-implementation of PASS A `evidence/op-mainnet-games-scan.py` (same Multicall3
aggregate3 technique, batches of 20 games, same pinned block, same archive proxy) but with raw
JSON-RPC instead of one `cast` subprocess per call, plus extra per-game lineage fields
(game's own ASR / WETH / absolutePrestate / version / wasRespectedGameTypeWhenCreated / resolvedAt).

Read-only: eth_call only.   usage: F5-games-scan.py <DGF> <ASR> <start> <end> <out.json> [block]
"""
import json, sys, time, urllib.request, collections

RPC = "http://127.0.0.1:7545"
MC = "0xcA11bde05977b3631167028862bE2a173976CA11"
DGF, ASR = sys.argv[1], sys.argv[2]
START, END, OUT = int(sys.argv[3]), int(sys.argv[4]), sys.argv[5]
BLOCK = int(sys.argv[6]) if len(sys.argv) > 6 else 26433900
B = 20

SEL = dict(aggregate3="82ad56cb", gameAtIndex="bb8aa1fc", gameCreator="37b1b229", status="200d2ed2",
           rootClaim="bcef3b55", l2SequenceNumber="99735e32", l2BlockNumber="8b85902b",
           isGameBlacklisted="34a346ea", isGameRetired="5958a193", isGameClaimValid="6c4f4467",
           wasRespected="250e69bd", resolvedAt="19effeb4", asr="5c0cba33", weth="3fc8cef3",
           absolutePrestate="8d450a95", version="54fd4d50", isGameProper="496b9c16",
           isGameRegistered="ee658e45", isGameFinalized="0314d2b3", isGameRespected="04e50fed")

def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    err = None
    for attempt in range(8):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json"})
            with urllib.request.urlopen(req, timeout=60) as r:
                j = json.loads(r.read())
            if "result" in j and j["result"] is not None:
                return j["result"]
            err = j.get("error")
        except Exception as e:  # noqa
            err = str(e)
        time.sleep(1 + attempt)
    raise RuntimeError(f"rpc failed {method}: {err}")

def w(n):  # uint256 word
    return f"{n:064x}"

def enc_aggregate3(calls):
    """calls: [(target_hex, calldata_hex_without_0x)] with allowFailure = true."""
    n = len(calls)
    elems = []
    for t, d in calls:
        blen = len(d) // 2
        pad = (32 - blen % 32) % 32
        elems.append(w(int(t, 16)) + w(1) + w(0x60) + w(blen) + d + "00" * pad)
    offs, cur = [], 32 * n
    for e in elems:
        offs.append(cur)
        cur += len(e) // 2
    return "0x" + SEL["aggregate3"] + w(0x20) + w(n) + "".join(w(o) for o in offs) + "".join(elems)

def dec_aggregate3(raw):
    h = raw[2:]
    base = int(h[0:64], 16) * 2
    n = int(h[base:base + 64], 16)
    arr = base + 64
    out = []
    for i in range(n):
        o = arr + int(h[arr + 64 * i: arr + 64 * (i + 1)], 16) * 2
        ok = int(h[o:o + 64], 16) == 1
        bo = o + int(h[o + 64:o + 128], 16) * 2
        bl = int(h[bo:bo + 64], 16)
        out.append((ok, h[bo + 64: bo + 64 + 2 * bl]))
    return out

def multicall(calls):
    raw = rpc("eth_call", [{"to": MC, "data": enc_aggregate3(calls)}, hex(BLOCK)])
    res = dec_aggregate3(raw)
    assert len(res) == len(calls)
    return res

def addr_arg(a):
    return w(int(a, 16))

GAME_CALLS = ["gameCreator", "status", "rootClaim", "l2SequenceNumber", "l2BlockNumber", "wasRespected",
              "resolvedAt", "asr", "weth", "absolutePrestate", "version"]
ASR_CALLS = ["isGameBlacklisted", "isGameRetired", "isGameClaimValid", "isGameProper", "isGameRegistered",
             "isGameFinalized", "isGameRespected"]
NC = len(GAME_CALLS) + len(ASR_CALLS)

def word(x):
    return x[:64] if x and len(x) >= 64 else None

def dec_string(x):
    try:
        ln = int(x[64:128], 16)
        return bytes.fromhex(x[128:128 + 2 * ln]).decode()
    except Exception:
        return None

games = []
try:
    games = json.load(open(OUT))
    games = [g for g in games if START <= g["index"] < END]
except Exception:
    games = []
done = {g["index"] for g in games}

for lo in range(START, END, B):
    idx = [i for i in range(lo, min(lo + B, END))]
    if all(i in done for i in idx):
        continue
    r1 = multicall([(DGF, SEL["gameAtIndex"] + w(i)) for i in idx])
    meta = []
    for i, (ok, h) in zip(idx, r1):
        assert ok, f"gameAtIndex({i}) failed"
        meta.append((i, int(h[0:64], 16), int(h[64:128], 16), "0x" + h[128 + 24:192]))
    calls = []
    for (_, _, _, g) in meta:
        calls += [(g, SEL[c]) for c in GAME_CALLS]
        calls += [(ASR, SEL[c] + addr_arg(g)) for c in ASR_CALLS]
    r2 = multicall(calls)
    for k, (i, gt, ts, g) in enumerate(meta):
        c = r2[NC * k: NC * (k + 1)]
        v = {name: (word(c[j][1]) if c[j][0] else None) for j, name in enumerate(GAME_CALLS + ASR_CALLS)}
        ver = dec_string(c[GAME_CALLS.index("version")][1]) if c[GAME_CALLS.index("version")][0] else None
        A = lambda x: ("0x" + x[24:]) if x else None
        I = lambda x: int(x, 16) if x else None
        Bo = lambda x: bool(int(x, 16)) if x else None
        games.append(dict(index=i, type=gt, createdAt=ts, game=g, creator=A(v["gameCreator"]), status=I(v["status"]),
                          rootClaim=("0x" + v["rootClaim"]) if v["rootClaim"] else None,
                          l2Seq=I(v["l2SequenceNumber"]), l2Block=I(v["l2BlockNumber"]),
                          wasRespected=Bo(v["wasRespected"]), resolvedAt=I(v["resolvedAt"]),
                          gameAsr=A(v["asr"]), weth=A(v["weth"]),
                          prestate=("0x" + v["absolutePrestate"]) if v["absolutePrestate"] else None, version=ver,
                          blacklisted=Bo(v["isGameBlacklisted"]), retired=Bo(v["isGameRetired"]),
                          claimValid=Bo(v["isGameClaimValid"]), proper=Bo(v["isGameProper"]),
                          registered=Bo(v["isGameRegistered"]), finalized=Bo(v["isGameFinalized"]),
                          respected=Bo(v["isGameRespected"])))
    if (lo // B) % 10 == 0:
        print(f"scanned {lo}..{idx[-1]}", flush=True)
        games.sort(key=lambda g: g["index"])
        json.dump(games, open(OUT, "w"))

games.sort(key=lambda g: g["index"])
json.dump(games, open(OUT, "w"))
cnt = collections.Counter((g["type"], g["creator"], g["status"], g["claimValid"], g["blacklisted"], g["retired"]) for g in games)
print(f"\nDGF {DGF} ASR {ASR} block {BLOCK} games {START}..{END - 1} ({len(games)})")
print("(type, creator, status, claimValid, blacklisted, retired) -> count")
for k, n in sorted(cnt.items(), key=lambda x: -x[1]):
    print(k, n)
