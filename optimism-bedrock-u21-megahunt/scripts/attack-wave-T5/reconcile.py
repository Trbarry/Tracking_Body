"""ATK-T5 (c): OP custody ledger. predicted(b) = B0 + sum(mint, <=b) - sum(paid success, <=b); residual = actual - predicted.
Liability at (L1 26,433,900 / L2 159,654,093) and the Bedrock checkpoint."""
import gzip, json, bisect
E = "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/evidence/attack-wave/T5"
dep = json.load(gzip.open(E + "/op-portal-deposits.json.gz"))["rows"]
paid = json.load(gzip.open(E + "/finalized-paid-by-block.json.gz"))
fj = json.load(open(E + "/finalized-join.json"))
B0 = 293288256836040170934313          # L1SB -> portal at L1 17,423,158 (balance read)
TS = 285751404305961746468821          # OVM_ETH totalSupply at L2 105,235,062
DELTA = 1627270011999999992            # op-chain-ops crossdomain/params.go ExpectedSupplyDelta (chain 1)
S0 = TS - DELTA
LEG_PENDING = 464218395751203965589 + 24094902114734129434 + 1235685621896291858 + 2346196751563751938
LEG_PAID = int(fj["sums"]["legacy_success"]["wei"])
INIT = int(fj["bedrock_initiated_wei"]); PEND_BE = int(fj["bedrock_pending_wei"])
print("deposits", len(dep), "first block", dep[0][0], "before B0 block:", sum(1 for r in dep if r[0] < 17423158))
print("versions", set(r[5] for r in dep), "mint>value rows", sum(1 for r in dep if int(r[6]) > 0))
db = [r[0] for r in dep]; dm = [0]
for r in dep: dm.append(dm[-1] + int(r[6]))
pb = [p[0] for p in paid]; pm = [0]
for p in paid: pm.append(pm[-1] + p[1])
out = []
for line in open(E + "/custody-checkpoints.txt").read().split("\n")[1:]:
    if not line.strip(): continue
    b, po, lb = map(int, line.split()); act = po + lb
    m = dm[bisect.bisect_right(db, b)]; p = pm[bisect.bisect_right(pb, b)]
    pred = B0 + m - p
    out.append(dict(block=b, actual=str(act), sum_mint=str(m), sum_paid=str(p), predicted=str(pred), residual_wei=str(act - pred), residual_eth=(act - pred) / 1e18))
    print(b, "actual", act / 1e18, "pred", pred / 1e18, "residual", (act - pred), (act - pred) / 1e18)
MINT = dm[-1]; CUST = int(out[-1]["actual"])
# liability (upper bound; L2 self-destruct burns ignored): circulating + pending
circ = S0 + MINT - INIT   # includes deposits locked on L1 not yet minted by L2 159,654,093 (origin 26,433,801)
liab = circ + PEND_BE + LEG_PENDING
res = dict(B0=str(B0), TS=str(TS), S0=str(S0), bedrock_check_wei=str(B0 - S0 - LEG_PENDING - LEG_PAID - 0),
           sum_mint_L1=str(MINT), sum_initiated_L2=str(INIT), circulating_L2_upper=str(circ), pending_bedrock=str(PEND_BE),
           pending_legacy=str(LEG_PENDING), liability_upper=str(liab), custody=str(CUST), surplus_wei=str(CUST - liab), surplus_eth=(CUST - liab) / 1e18,
           checkpoints=out)
json.dump(res, open(E + "/reconcile.json", "w"), indent=1)
for k in ("bedrock_check_wei", "sum_mint_L1", "circulating_L2_upper", "pending_bedrock", "pending_legacy", "liability_upper", "custody", "surplus_wei", "surplus_eth"):
    v = res[k]; print(k, v, (int(v) / 1e18 if isinstance(v, str) else ""))
