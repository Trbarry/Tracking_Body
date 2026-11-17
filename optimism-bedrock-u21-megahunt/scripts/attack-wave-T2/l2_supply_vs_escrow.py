"""ATK-T2 (c'): for every escrowed L1StandardBridge pair, compare L1 deposits[l1][l2] (26,433,900) with the OP L2 token's
totalSupply (159,654,093) when the L2 token is a bridge-mintable token whose l1Token()/remoteToken() is that l1 token."""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rpc
E = "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/evidence/attack-wave/T2"
rows = [r for r in json.load(open(f"{E}/l1sb-pairs.json")) if r["depositsAtPin"] > 0]
B = hex(159654093)
def c(to, data):
    try: return rpc.call(rpc.L2, "eth_call", [{"to": to, "data": data, "gas": hex(200000)}, B], retries=1)
    except Exception: return "0x"
out = []
for r in rows:
    l1t = c(r["l2"], "0xc01e1bd6"); rt = c(r["l2"], "0xd6c0b2c4"); ts = c(r["l2"], "0x18160ddd")
    link = None
    for x in (l1t, rt):
        if len(x) >= 66 and "0x" + x[-40:] == r["l1"]: link = True
    sup = int(ts[:66], 16) if len(ts) >= 66 else None
    out.append(dict(r, l2Linked=bool(link), l2TotalSupply=sup, l2MinusEscrow=(sup - r["depositsAtPin"]) if (link and sup is not None) else None))
json.dump(out, open(f"{E}/l2-supply-vs-escrow.json", "w"), indent=1)
lk = [o for o in out if o["l2Linked"]]
print("escrowed pairs", len(out), "linked L2 mintable tokens", len(lk))
over = sorted([o for o in lk if o["l2MinusEscrow"] > 0], key=lambda o: -o["l2MinusEscrow"] / max(o["depositsAtPin"], 1))
print("pairs with L2 supply > L1 escrow:", len(over))
for o in over[:12]: print(o["l1"], o["l2"], "escrow", o["depositsAtPin"], "l2supply", o["l2TotalSupply"], "ratio", round(o["l2TotalSupply"]/o["depositsAtPin"], 6))
