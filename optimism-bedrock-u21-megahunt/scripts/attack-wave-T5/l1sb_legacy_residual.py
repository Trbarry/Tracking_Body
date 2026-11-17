"""ATK-T5: pre-Bedrock L1StandardBridge ETH ledger. residual(b) = balance(b) - (sum ETHDepositInitiated - sum ETHWithdrawalFinalized)(<=b).
Bisects every block where the residual changes (eventless inflow/outflow). Read-only balance reads via :7545."""
import json, bisect, sys, os, gzip
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rpc
E = "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/evidence/attack-wave/T5"
A = "0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1"
ev = [(int(l["blockNumber"], 16), int(l["data"][2:66], 16)) for l in [l for i in (1, 2) for l in json.load(gzip.open(E + f"/legacy-l1sb-eth-deposits.part{i}.json.gz"))["logs"]]]
ev += [(int(l["blockNumber"], 16), -int(l["data"][2:66], 16)) for l in json.load(gzip.open(E + "/legacy-l1sb-eth-withdrawals.json.gz"))["logs"]]
ev.sort(); eb = [e[0] for e in ev]; cum = [0]
for e in ev: cum.append(cum[-1] + e[1])
def net(b): return cum[bisect.bisect_right(eb, b)]
cache = {}
def bal(b):
    if b not in cache: cache[b] = int(rpc.call(rpc.L1, "eth_getBalance", [A, hex(b)]), 16)
    return cache[b]
def res(b): return bal(b) - net(b)
jumps = []
def search(lo, hi, rlo, rhi):
    if rlo == rhi: return
    if hi - lo <= 1: jumps.append((hi, rhi - rlo)); return
    m = (lo + hi) // 2; rm = res(m); search(lo, m, rlo, rm); search(m, hi, rm, rhi)
pts = list(range(12686786, 17423157, 250000)) + [17423157]
rs = [res(p) for p in pts]
for i in range(len(pts) - 1): search(pts[i], pts[i + 1], rs[i], rs[i + 1])
out = dict(checkpoints=[(p, str(r)) for p, r in zip(pts, rs)], jumps=[(b, str(d), d / 1e18) for b, d in jumps], total=str(sum(d for _, d in jumps)), reads=len(cache))
json.dump(out, open(E + "/legacy-l1sb-residual.json", "w"), indent=1)
print(json.dumps(out["jumps"]), out["total"], "reads", len(cache))
