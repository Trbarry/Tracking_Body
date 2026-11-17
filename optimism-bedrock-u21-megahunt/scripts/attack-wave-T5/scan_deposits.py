"""ATK-T5: chunked read-only scan of OP portal TransactionDeposited (all portal generations share the proxy
0xbEb5Fc57...). Keeps per-log: block, tx, logIndex, from, to, version, mint, value, gasLimit, isCreation, dataLen.
Usage: scan_deposits.py <from> <to> <step> <out.json.gz> [portal]"""
import sys, os, json, gzip
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rpc
PORTAL = "0xbEb5Fc579115071764c7423A4f12eDde41f106Ed"
T0 = "0xb3813568d9991fc951961fcb4c784893574240a28925604d09fc577c55bb7c32"
a, b, step, out = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
if len(sys.argv) > 5: PORTAL = sys.argv[5]
rows = []; cur = a; calls = 0; total_mint = 0
while cur <= b:
    s = step
    while True:
        e = min(cur + s - 1, b)
        try:
            r = rpc.call(rpc.L1, "eth_getLogs", [{"fromBlock": hex(cur), "toBlock": hex(e), "address": PORTAL, "topics": [T0]}], retries=2); calls += 1; break
        except Exception as ex:
            s = max(s // 4, 500); print("shrink", cur, s, str(ex)[:120], flush=True)
    for l in r:
        d = bytes.fromhex(l["data"][2:])
        off = int.from_bytes(d[0:32], "big"); ln = int.from_bytes(d[off:off+32], "big"); op = d[off+32:off+32+ln]
        mint = int.from_bytes(op[0:32], "big"); val = int.from_bytes(op[32:64], "big")
        gas = int.from_bytes(op[64:72], "big"); cre = op[72]
        rows.append([int(l["blockNumber"], 16), l["transactionHash"], int(l["logIndex"], 16), "0x" + l["topics"][1][-40:], "0x" + l["topics"][2][-40:],
                     int(l["topics"][3], 16), str(mint), str(val), gas, cre, len(op) - 73])
        total_mint += mint
    print(cur, e, len(r), len(rows), total_mint / 1e18, flush=True); cur = e + 1
json.dump({"from": a, "to": b, "calls": calls, "cols": ["block","tx","logIndex","from","to","version","mint","value","gasLimit","isCreation","dataLen"], "rows": rows}, gzip.open(out, "wt"))
print("done", len(rows), "calls", calls, "sum_mint_wei", total_mint)
