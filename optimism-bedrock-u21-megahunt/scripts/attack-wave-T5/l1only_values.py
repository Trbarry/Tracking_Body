"""ATK-T5: L1-only withdrawal values for a portal. For every WithdrawalFinalized(hash, success) fetch the L1 tx
(eth_getTransactionByHash, batches of 50, :7545) and locate an ABI-encoded WithdrawalTransaction tuple anywhere in the
calldata whose keccak(abi.encode(nonce,sender,target,value,gasLimit,data)) equals the event hash.
Usage: l1only_values.py <finalized.json> <out.json>"""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rpc
from keccak import keccak
fin = json.load(open(sys.argv[1]))["logs"]
txs = sorted(set(l["transactionHash"] for l in fin)); inp = {}
res = rpc.batch(rpc.L1, [("eth_getTransactionByHash", [h]) for h in txs])
for h, t in zip(txs, res): inp[h] = bytes.fromhex(t["input"][2:])
def find(cd, want):
    n = len(cd)
    for i in range(0, n - 224 + 1):
        if cd[i + 160:i + 192] != (0xc0).to_bytes(32, "big"): continue
        if any(cd[i + 32:i + 44]) or any(cd[i + 64:i + 76]): continue
        ln = int.from_bytes(cd[i + 192:i + 224], "big")
        if ln > n: continue
        pad = (ln + 31) // 32 * 32
        enc = bytes(32 * 5) if False else cd[i:i + 160] + (0xc0).to_bytes(32, "big") + ln.to_bytes(32, "big") + cd[i + 224:i + 224 + ln] + bytes(pad - ln)
        # abi.encode of the 6 params: head (6 words, data offset 0xc0) + len + data padded
        if len(cd[i + 224:i + 224 + ln]) != ln: continue
        if keccak(enc) == want: return int.from_bytes(cd[i + 96:i + 128], "big")
    return None
rows = []; miss = []
for l in fin:
    h = bytes.fromhex(l["topics"][1][2:]); v = find(inp[l["transactionHash"]], h)
    ok = int(l["data"][2:], 16) == 1
    if v is None: miss.append(l["topics"][1])
    rows.append(dict(block=int(l["blockNumber"], 16), tx=l["transactionHash"], hash=l["topics"][1], success=ok, value=None if v is None else str(v)))
json.dump(dict(rows=rows, undecoded=miss), open(sys.argv[2], "w"))
print("finalized", len(rows), "txs", len(txs), "undecoded", len(miss), "success=false", sum(1 for r in rows if not r["success"]),
      "sum value success", sum(int(r["value"]) for r in rows if r["value"] and r["success"]) / 1e18)
