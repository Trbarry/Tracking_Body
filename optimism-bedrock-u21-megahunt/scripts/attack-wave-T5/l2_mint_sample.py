"""ATK-T5: Bedrock-era derivation spot check. For the N largest-mint and N random OP portal deposits, recompute the
L2 deposit tx hash from the L1 log (sourceHash = keccak(0x00..00 || keccak(l1BlockHash || logIndex))) and read it on
OP L2 (eth_getTransactionByHash via :7546); assert mint/value/from/to/gas match. Read-only.
Usage: l2_mint_sample.py <deposits.json.gz> <N> <out.json>"""
import sys, os, json, gzip, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rpc
from keccak import keccak
def rlp_b(b):
    if len(b) == 1 and b[0] < 0x80: return b
    if len(b) < 56: return bytes([0x80 + len(b)]) + b
    l = len(b).to_bytes((len(b).bit_length() + 7) // 8, "big"); return bytes([0xb7 + len(l)]) + l + b
def rlp_l(items):
    p = b"".join(items)
    if len(p) < 56: return bytes([0xc0 + len(p)]) + p
    l = len(p).to_bytes((len(p).bit_length() + 7) // 8, "big"); return bytes([0xf7 + len(l)]) + l + p
def ib(i): return i.to_bytes((i.bit_length() + 7) // 8, "big") if i else b""
dep = json.load(gzip.open(sys.argv[1]))["rows"]; N = int(sys.argv[2])
random.seed(5); pick = sorted(dep, key=lambda r: -int(r[6]))[:N] + random.sample(dep, N)
out = []; bad = 0
for r in pick:
    blk, txh, li = r[0], r[1], r[2]
    logs = rpc.call(rpc.L1, "eth_getLogs", [{"fromBlock": hex(blk), "toBlock": hex(blk), "address": "0xbEb5Fc579115071764c7423A4f12eDde41f106Ed"}])
    l = [x for x in logs if int(x["logIndex"], 16) == li][0]
    d = bytes.fromhex(l["data"][2:]); off = int.from_bytes(d[:32], "big"); ln = int.from_bytes(d[off:off + 32], "big"); op = d[off + 32:off + 32 + ln]
    mint, val, gas, cre, data = int.from_bytes(op[:32], "big"), int.from_bytes(op[32:64], "big"), int.from_bytes(op[64:72], "big"), op[72], op[73:]
    frm = bytes.fromhex(l["topics"][1][-40:]); to = b"" if cre else bytes.fromhex(l["topics"][2][-40:])
    src = keccak(bytes(32) + keccak(bytes.fromhex(l["blockHash"][2:]) + li.to_bytes(32, "big")))
    h = "0x" + keccak(b"\x7e" + rlp_l([rlp_b(src), rlp_b(frm), rlp_b(to), rlp_b(ib(mint)), rlp_b(ib(val)), rlp_b(ib(gas)), rlp_b(b""), rlp_b(data)])).hex()
    t = rpc.call(rpc.L2, "eth_getTransactionByHash", [h])
    ok = bool(t) and int(t.get("mint", "0x0"), 16) == mint and int(t["value"], 16) == val and t["from"].lower() == "0x" + frm.hex() and int(t["gas"], 16) == gas
    bad += not ok
    out.append(dict(l1Block=blk, l1Tx=txh, logIndex=li, mint=str(mint), l2Tx=h, l2Block=int(t["blockNumber"], 16) if t else None, match=ok))
json.dump(dict(n=len(out), mismatches=bad, rows=out), open(sys.argv[3], "w"), indent=1)
print("sampled", len(out), "mismatches", bad, "largest mint", max(int(o["mint"]) for o in out) / 1e18)
