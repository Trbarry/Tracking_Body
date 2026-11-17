"""ATK-T5: legacy OP L2 (OVM 2.0, L2 0..105,235,062) L2StandardBridge DepositFinalized with l1Token = 0 (ETH mints),
chunked read-only via :7546. Keeps (l2Block, l1From, l2To, amount, l2Tx)."""
import sys, os, json, gzip
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rpc
T = "0xb0444523268717a02698be47d0803aa7468c00acbed2f8bd93a0459cde61dd89"
Z = "0x" + "0" * 64
a, b, step, out = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
rows = []; cur = a; calls = 0
while cur <= b:
    s = step
    while True:
        e = min(cur + s - 1, b)
        try:
            r = rpc.call(rpc.L2, "eth_getLogs", [{"fromBlock": hex(cur), "toBlock": hex(e), "address": "0x4200000000000000000000000000000000000010", "topics": [T, Z]}], retries=2); calls += 1; break
        except Exception as ex:
            s = max(s // 4, 1000); print("shrink", cur, s, str(ex)[:120], flush=True)
    for l in r:
        rows.append([int(l["blockNumber"], 16), "0x" + l["topics"][3][-40:], "0x" + l["data"][26:66], str(int(l["data"][66:130], 16)), l["transactionHash"]])
    print(cur, e, len(r), len(rows), flush=True); cur = e + 1
json.dump({"from": a, "to": b, "calls": calls, "cols": ["l2Block", "l1From", "l2To", "amount", "l2Tx"], "rows": rows}, gzip.open(out, "wt"))
print("done", len(rows), "calls", calls)
