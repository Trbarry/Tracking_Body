#!/usr/bin/env python3
"""ATK-T4: OP Mainnet receipts-root and output/super-root real-data cases (passive reads via :7546/:7545).
Usage: fetch_rcpt.py <outdir> <real-cases.jsonl> <stride> <game_addr,...>
Writes <outdir>/rcpt-cases.jsonl (kind rroot, expect = header receiptsRoot) and
<outdir>/oroot-cases.jsonl (kind oroot for each game's claimed L2 block; expect = game rootClaim)."""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib.util
spec = importlib.util.spec_from_file_location("fr", os.path.join(os.path.dirname(os.path.abspath(__file__)), "fetch_real.py"))

OUT = sys.argv[1]
real_path, stride, games = sys.argv[2], int(sys.argv[3]), sys.argv[4].split(",")
sys.argv = [sys.argv[0], OUT]  # fetch_real reads argv[1] as its cache dir; its main is guarded
fr = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fr)

real = [json.loads(l) for l in open(real_path)]
blocks = sorted({int(c["id"].split(":")[1]) for c in real if c["expect"]["seq"] == 0}
                | {int(c["id"].split(":")[1]) for i, c in enumerate(real) if i % stride == 0})
with open(os.path.join(OUT, "rcpt-cases.jsonl"), "w") as f:
    for n in blocks:
        b = fr.l2block(n)
        rs = fr.rpc(fr.L2, "eth_getBlockReceipts", [hex(n)])
        rr = []
        for r in rs:
            rr.append({"type": int(r["type"], 16), "status": int(r["status"], 16),
                       "cgu": int(r["cumulativeGasUsed"], 16),
                       "logs": [{"address": l["address"], "topics": l["topics"], "data": l["data"]} for l in r["logs"]],
                       "deposit_nonce": int(r["depositNonce"], 16) if r.get("depositNonce") else None,
                       "deposit_receipt_version": int(r["depositReceiptVersion"], 16) if r.get("depositReceiptVersion") else None})
        types = sorted({x["type"] for x in rr})
        fails = sum(1 for x in rr if x["type"] == 0x7e and x["status"] == 0)
        f.write(json.dumps({"k": "rroot", "id": f"rroot:{n}:types{types}:failed_deposits{fails}", "receipts": rr,
                            "expect": {"root": b["receiptsRoot"]}}) + "\n")
SEL_SEQ, SEL_ROOT = "0x99735e32", "0xbcef3b55"  # l2SequenceNumber(), rootClaim()
with open(os.path.join(OUT, "oroot-cases.jsonl"), "w") as f:
    for g in games:
        ts = int(fr.rpc(fr.L1, "eth_call", [{"to": g, "data": SEL_SEQ}, "latest"]), 16)
        root = fr.rpc(fr.L1, "eth_call", [{"to": g, "data": SEL_ROOT}, "latest"])
        n = 105235063 + (ts - 1686068903) // 2
        b = fr.l2block(n)
        assert int(b["timestamp"], 16) == ts
        f.write(json.dumps({"k": "oroot", "id": f"game:{g}:ts{ts}:l2{n}", "state": b["stateRoot"],
                            "storage": b["withdrawalsRoot"], "block": b["hash"], "ts": ts,
                            "expect": {"rootClaim": root}}) + "\n")
print("rroot", len(blocks), "games", len(games), file=sys.stderr)
