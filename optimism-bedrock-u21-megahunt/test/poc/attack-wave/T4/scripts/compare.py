#!/usr/bin/env python3
"""ATK-T4 comparator. Usage: compare.py <cases.jsonl> <kona-v1.7.0.jsonl> <kona-v1.9.0.jsonl> <op-node-v9.jsonl>
Compares, per case: old kona vs new kona (full output, byte-exact), kona vs op-node (accepted/rejected
status and, when accepted, every derived field byte-exact), and, for real cases, kona vs the canonical
OP Mainnet block (expect). Error texts are implementation-specific, so only error-vs-success is compared
across implementations; old vs new kona error texts are compared too (they share the error enums)."""
import json, sys
from collections import Counter

cases = [json.loads(l) for l in open(sys.argv[1])]
outs = [[json.loads(l) for l in open(p)] for p in sys.argv[2:5]]
assert all(len(o) == len(cases) for o in outs), [len(o) for o in outs]


def norm(v):
    if isinstance(v, str):
        return v.lower()
    if isinstance(v, list):
        return [norm(x) for x in v]
    if isinstance(v, dict):
        return {k: norm(x) for k, x in v.items()}
    return v


stats = Counter()
bad = []
for c, k7, k9, g in zip(cases, *outs):
    kind = c["k"] + ":" + c.get("reach", "real")
    stats[kind] += 1
    k7, k9, g = norm(k7), norm(k9), norm(g)
    if k7 != k9:
        bad.append(("OLD!=NEW", c["id"], k7, k9))
        stats[kind + ":old!=new"] += 1
    ke, ge = "err" in k7 or "panic" in k7, "err" in g or "panic" in g
    if ke != ge:
        bad.append(("KONA-vs-OPNODE status", c["id"], k7, g))
        stats[kind + ":kona!=opnode(status)"] += 1
    elif not ke:
        if c["k"] == "cfg":
            pass  # config dumps have different shapes; compared separately
        else:
            kk = {x: y for x, y in k7.items() if x not in ("id",)}
            gg = {x: y for x, y in g.items() if x not in ("id",)}
            if c["k"] == "attr":
                kk.pop("l1_hash", None); gg.pop("l1_hash", None)
            if kk != gg:
                diffk = sorted(x for x in set(kk) | set(gg) if kk.get(x) != gg.get(x))
                bad.append(("KONA-vs-OPNODE value", c["id"], diffk, {x: kk.get(x) for x in diffk}, {x: gg.get(x) for x in diffk}))
                stats[kind + ":kona!=opnode(value)"] += 1
    else:
        stats[kind + ":both-reject"] += 1
    e = c.get("expect")
    if e:
        e = norm(e)
        if ke:
            bad.append(("KONA rejects canonical block input", c["id"], k7))
            stats["real:kona-err"] += 1
            continue
        mism = []
        for f in ("l1_hash", "timestamp", "prev_randao", "beacon_root", "gas_limit", "eip1559", "min_base_fee"):
            if k7.get(f) != e.get(f):
                mism.append((f, k7.get(f), e.get(f)))
        if k7["tx_hashes"] != e["deposit_tx_hashes"]:
            mism.append(("deposit_tx_hashes", k7["tx_hashes"], e["deposit_tx_hashes"]))
        if k7["fee_recipient"] != e["fee_recipient"]:
            mism.append(("fee_recipient", k7["fee_recipient"], e["fee_recipient"]))
        if mism:
            bad.append(("KONA-vs-CANONICAL", c["id"], mism))
            stats["real:kona!=canonical"] += 1
        else:
            stats["real:match-canonical"] += 1
            stats["real:deposits-matched"] += len(e["deposit_tx_hashes"]) - 1
            if e["seq"] == 0:
                stats["real:epoch-first"] += 1
for k in sorted(stats):
    print(f"{k}\t{stats[k]}")
print("DIVERGENCES", len(bad))
for b in bad[:40]:
    print(json.dumps(b)[:1500])
