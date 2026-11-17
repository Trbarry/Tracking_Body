"""ATK-T5: L1-only custody ledger and liability bound for a non-OP chain.
predicted(b) = G? no: custody(b) = sum(mint<=b) - sum(paid success<=b) + D(b). Liability(L1-only, upper) = G + sum(mint) - sum(finalized values).
Usage: l1only_reconcile.py <deposits.json.gz> <finalized-values.json> <checkpoints.txt> <genesis_wei> <unlocked.json> <out.json>"""
import sys, json, gzip, bisect
dep = json.load(gzip.open(sys.argv[1]))["rows"]; fv = json.load(open(sys.argv[2]))["rows"]; G = int(sys.argv[4])
unl = json.load(open(sys.argv[5]))["logs"]
db = [r[0] for r in dep]; dm = [0]
for r in dep: dm.append(dm[-1] + int(r[6]))
pv = sorted((r["block"], int(r["value"]) if r["success"] else 0) for r in fv); pb = [p[0] for p in pv]; pm = [0]
for p in pv: pm.append(pm[-1] + p[1])
cps = []
for line in open(sys.argv[3]).read().split("\n")[1:]:
    if not line.strip(): continue
    b, po, lb = map(int, line.split()); act = po + lb
    m = dm[bisect.bisect_right(db, b)]; p = pm[bisect.bisect_right(pb, b)]
    cps.append(dict(block=b, actual=str(act), predicted=str(m - p), residual_wei=str(act - m + p)))
    print(b, act / 1e18, (m - p) / 1e18, "residual", act - m + p)
lb0 = min(int(l["blockNumber"], 16) for l in unl) if unl else None
unl_sum = sum(int(l["data"][2:], 16) for l in unl)
paid_after = sum(v for b, v in pv if lb0 and b >= lb0)
MINT = dm[-1]; FINV = sum(int(r["value"]) for r in fv); CUST = int(cps[-1]["actual"])
liab = G + MINT - FINV
out = dict(deposits=len(dep), sum_mint=str(MINT), finalized=len(fv), sum_finalized_values=str(FINV), failed=sum(1 for r in fv if not r["success"]),
           genesis_alloc_wei=str(G), custody=str(CUST), liability_upper_L1only=str(liab), margin_wei=str(CUST - liab), margin_eth=(CUST - liab) / 1e18,
           lockbox_unlocked_sum=str(unl_sum), paid_from_first_unlock_block=str(paid_after), unlock_vs_paid_diff=str(unl_sum - paid_after), checkpoints=cps)
json.dump(out, open(sys.argv[6], "w"), indent=1)
for k, v in out.items():
    if k != "checkpoints": print(k, v)
