#!/usr/bin/env python3
"""ATK-T4: explain every kona-vs-op-node divergence of a synthetic run with a named root cause.
Usage: classify.py <cases> <kona7> <kona9> <go>. Prints counts per cause; any divergence that no rule
explains is printed as UNEXPLAINED (the run is then not clean)."""
import json, sys
from collections import Counter

cases = [json.loads(l) for l in open(sys.argv[1])]
k7s = [json.loads(l) for l in open(sys.argv[2])]
k9s = [json.loads(l) for l in open(sys.argv[3])]
gos = [json.loads(l) for l in open(sys.argv[4])]
CANCUN, BLOBFRAC = 1710338135, None


def low(v):
    return json.dumps(v, sort_keys=True).lower()


def strip(o, extra=()):
    return {k: v for k, v in o.items() if k not in ("id", "l1_hash") + tuple(extra)}


cnt = Counter()
unexpl = []
for c, a, a9, g in zip(cases, k7s, k9s, gos):
    if low(a) != low(a9):
        unexpl.append(("old!=new", c["id"]))
    if c["k"] == "cfg":
        continue
    ae, ge = ("err" in a or "panic" in a), ("err" in g or "panic" in g)
    if ae == ge and (ae or low(strip(a)) == low(strip(g))):
        continue
    reach = c.get("reach")
    why = None
    if c["k"] == "dep":
        kid = c["id"].split("#")[0]
        if reach != "none":
            why = None
        elif kid == "dep-malformed1" and ae and not ge:
            why = "padding bytes non-zero: kona rejects (InvalidOpaqueDataPadding), op-node ignores padding"
        elif kid in ("dep-malformed2", "dep-malformed3") and ge and not ae:
            why = "trailing data after padded opaqueData: kona accepts, op-node rejects (length check)"
        elif kid == "dep-malformed8" and ae and not ge:
            why = "non-zero high 12 bytes in from topic: kona rejects (FromDecode), op-node truncates"
        elif kid == "dep-malformed5":
            why = "mint >= 2^128: kona keeps only the low 128 bits (u128), op-node keeps the full big.Int mint"
        elif kid == "dep-malformed7" and not ae and not ge:
            why = "isCreation byte not in {0,1}: kona and op-node map it differently"
        elif kid == "dep-malformed7" and ae != ge:
            why = "isCreation byte not in {0,1}: one side rejects"
        elif kid == "dep-malformed0" and ae != ge:
            why = "abi offset != 32: acceptance differs"
        elif kid == "dep-malformed10" and ae != ge:
            why = "abi length field inconsistent with data: acceptance differs"
        elif kid == "dep-malformed6" and ae != ge:
            why = "opaqueData shorter than 73 bytes: acceptance differs"
        elif kid == "dep-bound" and ae != ge:
            why = "mint/gas beyond the contract's emit domain"
    elif c["k"] == "attr":
        cid = c["id"].split("#")[0]
        if cid == "sys":
            sc = int(c["sys"]["scalar"])
            if sc >> 248 == 0 and sc >> 32 != 0:
                why = "bedrock-version scalar with non-zero padding: op-node baseFeeScalar=MaxUint32 (spec), kona truncates to bytes 28..32 — dead post-Ecotone on both update paths"
        elif cid.startswith("l1hdr"):
            hd = c["l1_header"]
            ts = int(hd["timestamp"], 16)
            if ts < CANCUN and "excessBlobGas" in hd:
                why = "pre-Cancun L1 header carrying blob fields (cannot exist): op-node panics in CalcBlobFee, kona computes"
            elif int(hd.get("excessBlobGas", "0x0"), 16) >= 2**29:
                why = "L1 blob base fee >= 2^128 (excess blob gas >= ~1e9): kona saturates u128, op-node exact big.Int / >2^256 error"
        elif cid.startswith("fork-") and "holocene+0" in cid:
            d = [k for k in set(strip(a)) | set(strip(g)) if low(a.get(k)) != low(g.get(k))]
            if d == ["eip1559"]:
                why = "Holocene activation block: kona emits zero eip1559 params, op-node forwards SystemConfig value (zero on mainnet at activation)"
    if why is None:
        unexpl.append((c["id"], reach, a, g))
    else:
        cnt[(reach, why)] += 1
for (r, w), n in sorted(cnt.items(), key=lambda x: -x[1]):
    print(f"{n}\t[{r}]\t{w}")
print("UNEXPLAINED", len(unexpl))
for u in unexpl[:20]:
    print(json.dumps(u)[:1200])
