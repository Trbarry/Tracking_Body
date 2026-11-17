#!/usr/bin/env python3
"""F4 — for one proxy, read slots [0, N) plus named slots at the block before and at every signature change
found by F4_impl_history.py, and at HEAD. Emits a per-slot timeline (only slots that were EVER non-zero at a
sampled block) and per-implementation metadata (version(), code size, impl slot 0).

usage: F4_slot_history.py <evidence/F4/hist-X.json> <nslots> [name=slothex ...] > evidence/F4/slots-X.json
"""
import json, sys, os
sys.path.insert(0, os.path.dirname(__file__))
from F4_rpc import HEAD, many, eth_call, call

ZERO = "0x" + "0" * 64


def dec_string(ret):
    try:
        b = bytes.fromhex(ret[2:])
        n = int.from_bytes(b[32:64], "big")
        return b[64:64 + n].decode()
    except Exception:
        return None


def main():
    h = json.load(open(sys.argv[1]))
    n = int(sys.argv[2])
    named = dict(a.split("=") for a in sys.argv[3:])
    proxy = h["proxy"]
    slots = [hex(i) for i in range(n)] + list(named.values())
    labels = [str(i) for i in range(n)] + list(named.keys())
    blocks = sorted(set([c["block"] - 1 for c in h["changes"]] + [c["block"] for c in h["changes"]] + [HEAD]))
    reqs = [("eth_getStorageAt", [proxy, s, hex(b)]) for b in blocks for s in slots]
    res = many(reqs, threads=8)
    k = len(slots)
    table = {b: res[i * k:(i + 1) * k] for i, b in enumerate(blocks)}
    out = {"name": h["name"], "proxy": proxy, "blocks": blocks, "slots": {}, "impls": {}, "changes": h["changes"]}
    for j, lab in enumerate(labels):
        col = [table[b][j] for b in blocks]
        if any(v != ZERO for v in col):
            # compress: list of [block, value] at each point where the sampled value differs from the previous sample
            tl, prev = [], None
            for b, v in zip(blocks, col):
                if v != prev:
                    tl.append([b, v])
                    prev = v
            out["slots"][lab] = {"slot": slots[j], "timeline": tl, "head": col[-1]}
    impls = []
    for c in h["changes"]:
        for side in ("before", "after"):
            a = "0x" + c[side][0][-40:]
            if int(a, 16) and a not in impls:
                impls.append(a)
    for a in impls:
        ver = dec_string(eth_call(a, "0x54fd4d50") or "0x")
        code = call("eth_getCode", [a, hex(HEAD)])
        s0 = call("eth_getStorageAt", [a, "0x0", hex(HEAD)])
        out["impls"][a] = {"version": ver, "codesize": (len(code) - 2) // 2, "impl_slot0_at_head": s0}
    json.dump(out, sys.stdout, indent=1)


if __name__ == "__main__":
    main()
