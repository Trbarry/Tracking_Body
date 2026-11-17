#!/usr/bin/env python3
"""F4 — read REAL withdrawal entries created under each portal era through today's (v9) layout at block 26433900.

Input : evidence/F4/op-portal-withdrawal-events.jsonl (full census, F4_scan_logs.py)
Reads : legacy single-level mapping (slot 52)  keccak(hash . 52)       -> {outputRoot, timestamp|l2OutputIndex<<128}
        v9 two-level mapping (slot 57)         keccak(submitter . keccak(hash . 57)) -> {timestamp<<160 | game}
        finalizedWithdrawals (slot 51)         keccak(hash . 51)
        proofSubmitters (slot 60)              keccak(hash . 60) = array length
        and the v9 public getters for the same keys.
Output: evidence/F4/op-withdrawal-entries-by-era.json
"""
import json, sys, os, random, collections
sys.path.insert(0, os.path.dirname(__file__))
from F4_rpc import many, HEAD, eth_call
from concurrent.futures import ThreadPoolExecutor
import subprocess

PORTAL = "0xbEb5Fc579115071764c7423A4f12eDde41f106Ed"
BASE = "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/evidence/F4/"
ERAS = [(17423158, "v1.0.0 portal 1.6.0"), (19314493, "v1.2.0 portal 2.4.0"), (19634866, "v1.3.0 portal 2.5.0"),
        (20062696, "v1.4.0 portal2 3.10.0"), (22182531, "v2.0.0 3.13.0"), (22339996, "v3.0.0 3.14.0"),
        (22990599, "v4.0.0 4.6.0"), (23491328, "v4.1.0 5.0.0"), (23877377, "v5.0.0 5.1.1"), (24421512, "v6.0.0 5.2.0"),
        (25397811, "v7.0.0 5.6.1"), (26048619, "v8.0.0 5.8.0"), (26430859, "v9.0.0 6.1.0")]


def era(b):
    r = None
    for s, n in ERAS:
        if b >= s:
            r = n
    return r


def keccaks(datas):
    # batch keccak through one `cast` process per item is slow; use pycryptodome-free pure python fallback via cast --
    with ThreadPoolExecutor(8) as ex:
        return list(ex.map(lambda d: subprocess.check_output(["cast", "keccak", d]).decode().strip(), datas))


def pad(x):
    return x[2:].rjust(64, "0")


def main():
    random.seed(4)
    E = [json.loads(l) for l in open(BASE + "op-portal-withdrawal-events.jsonl")]
    proven, ext, fin = collections.defaultdict(list), collections.defaultdict(list), {}
    for b, ti, li, t, tp, data, tx in E:
        if t == 0:
            proven[tp[0]].append(b)
        elif t == 1:
            ext[tp[0]].append((b, "0x" + tp[1][-40:]))
        else:
            fin[tp[0]] = b
    per = int(sys.argv[1]) if len(sys.argv) > 1 else 12
    sample = []
    by_era = collections.defaultdict(list)
    for h, bs in proven.items():
        by_era[era(min(bs))].append(h)
    for e, hs in by_era.items():
        unf = [h for h in hs if h not in fin]
        f = [h for h in hs if h in fin]
        pick = random.sample(unf, min(per, len(unf))) + random.sample(f, min(per, len(f)))
        sample += [(e, h) for h in pick]
    out = {"block": HEAD, "portal": PORTAL, "per_era_sample": per, "entries": [],
           "census": {e: {"proven_hashes": len(hs), "never_finalized": sum(1 for h in hs if h not in fin)}
                      for e, hs in by_era.items()}}
    hs = [h for _, h in sample]
    k52 = keccaks(["0x" + pad(h) + pad(hex(52)) for h in hs])
    k57 = keccaks(["0x" + pad(h) + pad(hex(57)) for h in hs])
    k51 = keccaks(["0x" + pad(h) + pad(hex(51)) for h in hs])
    k60 = keccaks(["0x" + pad(h) + pad(hex(60)) for h in hs])
    subs = [(ext[h][-1][1] if ext.get(h) else None) for h in hs]
    k57s = keccaks(["0x" + pad(s or "0x0") + k[2:] for s, k in zip(subs, k57)])
    reqs = []
    for i, h in enumerate(hs):
        w1 = hex(int(k52[i], 16) + 1)
        for s in (k52[i], w1, k57s[i], k51[i], k60[i]):
            reqs.append(("eth_getStorageAt", [PORTAL, s, hex(HEAD)]))
    res = many(reqs, threads=8)
    for i, (e, h) in enumerate(sample):
        r = res[i * 5:(i + 1) * 5]
        ent = {"era_first_proven": e, "hash": h, "first_proven_block": min(proven[h]), "finalized_block": fin.get(h),
               "legacy_slot52_entry": k52[i], "legacy_outputRoot": r[0],
               "legacy_timestamp": int(r[1][34:], 16), "legacy_l2OutputIndex": int(r[1][2:34], 16),
               "v9_submitter": subs[i], "v9_slot57_entry": k57s[i], "v9_raw": r[2],
               "v9_game": "0x" + r[2][-40:], "v9_timestamp": int(r[2][2:26] or "0", 16) if r[2] else 0,
               "finalizedWithdrawals_raw": int(r[3], 16), "numProofSubmitters_raw": int(r[4], 16)}
        out["entries"].append(ent)
    json.dump(out, open(BASE + "op-withdrawal-entries-by-era.json", "w"), indent=1)
    # summary
    agg = collections.defaultdict(lambda: collections.Counter())
    for en in out["entries"]:
        a = agg[en["era_first_proven"]]
        a["n"] += 1
        a["legacy_nonzero"] += en["legacy_outputRoot"] != "0x" + "0" * 64
        a["v9_nonzero"] += int(en["v9_raw"], 16) != 0
        a["finalized_flag"] += en["finalizedWithdrawals_raw"]
        a["submitters>0"] += en["numProofSubmitters_raw"] > 0
    for e, _ in [(n, 0) for _, n in ERAS]:
        if e in agg:
            print(e, dict(agg[e]), out["census"][e])


if __name__ == "__main__":
    main()
