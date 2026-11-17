#!/usr/bin/env python3
"""F4 — reconstruct, for one proxy, every block at which a "signature" slot set changed
(implementation slot + slot 0 [+ extra slots]) between START and HEAD, by grid sampling + bisection.

Limits (stated in STORAGE-ARCHAEOLOGY.md): block granularity (intra-tx StorageSetter visits are invisible),
and an A -> B -> A excursion entirely inside one grid cell (default 20,000 blocks ~ 2.8 days) is missed.

usage: F4_impl_history.py <name> <proxy> <start_block> [extra_addr:slot ...] > out.json
  extra signature members may live in ANOTHER contract (e.g. the AddressManager entry of a ResolvedDelegateProxy).
"""
import json, sys
sys.path.insert(0, __import__("os").path.dirname(__file__))
from F4_rpc import IMPL, ADMIN, HEAD, many, call

GRID = 20000


def sig_at(members, blocks):
    reqs = [("eth_getStorageAt", [a, s, hex(b)]) for b in blocks for (a, s) in members]
    res = many(reqs, threads=8)
    n = len(members)
    return {b: tuple(res[i * n:(i + 1) * n]) for i, b in enumerate(blocks)}


def main():
    name, proxy, start = sys.argv[1], sys.argv[2], int(sys.argv[3])
    members = [(proxy, IMPL), (proxy, "0x0"), (proxy, ADMIN)]
    for e in sys.argv[4:]:
        a, s = e.split(":")
        members.append((a, s))
    grid = list(range(start, HEAD, GRID)) + [HEAD]
    sigs = sig_at(members, grid)
    changes = []
    # iterative bisection of every differing neighbouring pair
    work = [(grid[i], grid[i + 1]) for i in range(len(grid) - 1) if sigs[grid[i]] != sigs[grid[i + 1]]]
    while work:
        nxt, mids = [], []
        for lo, hi in work:
            if hi - lo == 1:
                changes.append(hi)
            else:
                mids.append((lo, hi, (lo + hi) // 2))
        if mids:
            got = sig_at(members, [m for _, _, m in mids])
            sigs.update(got)
            for lo, hi, m in mids:
                if sigs[lo] != sigs[m]:
                    nxt.append((lo, m))
                if sigs[m] != sigs[hi]:
                    nxt.append((m, hi))
        work = nxt
    changes.sort()
    out = {"name": name, "proxy": proxy, "start": start, "head": HEAD, "grid": GRID,
           "members": [f"{a}:{s}" for a, s in members], "changes": []}
    need = sorted(set([b - 1 for b in changes] + changes))
    need = [b for b in need if b not in sigs]
    if need:
        sigs.update(sig_at(members, need))
    for b in changes:
        ts = int(call("eth_getBlockByNumber", [hex(b), False])["timestamp"], 16)
        out["changes"].append({"block": b, "timestamp": ts, "before": list(sigs[b - 1]), "after": list(sigs[b])})
    out["first"] = list(sigs[grid[0]])
    out["last"] = list(sigs[HEAD])
    json.dump(out, sys.stdout, indent=1)


if __name__ == "__main__":
    main()
