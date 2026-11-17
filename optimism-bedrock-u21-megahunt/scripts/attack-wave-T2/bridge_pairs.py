"""ATK-T2 (c): every (l1Token,l2Token) pair seen in L1StandardBridge ERC20DepositInitiated / ERC20WithdrawalFinalized
(L1 12.6M..26,433,900, legacy and Bedrock events), event-sum vs on-chain deposits(l1,l2), and how the v9 bridge
classifies each L1 token (ERC165 ILegacyMintableERC20 0x1d1d8b63 / IOptimismMintableERC20 0xec4fc8e3)."""
import json, os, sys, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rpc
R = "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/evidence/attack-wave/T2"
dep = collections.Counter(); wd = collections.Counter(); ndep = collections.Counter(); nwd = collections.Counter(); firstBlk = {}
for name, ctr, n in (("l1sb-erc20-deposits.json", dep, ndep), ("l1sb-erc20-withdrawals.json", wd, nwd)):
    for l in json.load(open(f"{R}/raw/{name}"))["logs"]:
        k = ("0x" + l["topics"][1][-40:], "0x" + l["topics"][2][-40:]); amt = int(l["data"][66:130], 16)
        ctr[k] += amt; n[k] += 1; firstBlk[k] = min(firstBlk.get(k, 10**9), int(l["blockNumber"], 16))
pairs = sorted(set(dep) | set(wd)); B = hex(26433900); BR = "0x99c9fc46f92e8a1c0dec1b1747d010903e884be1"
pad = lambda x: x[2:].rjust(64, "0")
onchain = rpc.batch(rpc.L1, [("eth_call", [{"to": BR, "data": "0x8f601f66" + pad(a) + pad(b)}, B]) for a, b in pairs])
toks = sorted({a for a, _ in pairs})
def si(t, iid): return ("eth_call", [{"to": t, "data": "0x01ffc9a7" + iid + "0"*56, "gas": hex(30000)}, B])
reqs = []
for t in toks: reqs += [si(t, "1d1d8b63"), si(t, "ec4fc8e3")]
out = []
for i in range(0, len(reqs), 50):
    try: out += rpc.batch(rpc.L1, reqs[i:i+50])
    except Exception:
        for q in reqs[i:i+50]:
            try: out.append(rpc.call(rpc.L1, q[0], q[1], retries=2))
            except Exception: out.append("0x")
cls = {}
for j, t in enumerate(toks):
    a, b = out[2*j], out[2*j+1]
    f = lambda x: len(x) >= 66 and int(x[2:66], 16) == 1
    cls[t] = ("legacyMintable" if f(a) else "") + ("+" if f(a) and f(b) else "") + ("optimismMintable" if f(b) else "")
rows = []
for (k, oc) in zip(pairs, onchain):
    d = int(oc, 16); rows.append(dict(l1=k[0], l2=k[1], deposited=dep[k], withdrawn=wd[k], nDep=ndep[k], nWd=nwd[k], depositsAtPin=d,
        eventNet=dep[k]-wd[k], mismatch=d-(dep[k]-wd[k]), l1Class=cls[k[0]], firstBlock=firstBlk[k]))
json.dump(rows, open(f"{R}/l1sb-pairs.json", "w"))
print("pairs", len(pairs), "l1 tokens", len(toks), "classes", collections.Counter(cls.values()))
mm = [r for r in rows if r["mismatch"] != 0]
print("pairs with deposits(l1,l2) != sum(dep)-sum(wd):", len(mm))
for r in sorted(mm, key=lambda r: -abs(r["mismatch"]))[:15]: print(r)
mint = [r for r in rows if r["l1Class"] and r["depositsAtPin"] > 0]
print("L1 tokens the v9 bridge treats as mintable while deposits[l1][l2] > 0:", len(mint))
for r in mint[:20]: print(r)
print("withdrawn > deposited (event sums):", sum(1 for r in rows if r["withdrawn"] > r["deposited"]))
