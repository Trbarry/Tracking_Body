"""ATK-T5: value of every OP portal WithdrawalFinalized (L1 17,365,000..26,433,900) from the L2 MessagePassed
(Bedrock era) and the recomputed v0 migrated withdrawals (legacy). Outputs sums by era and success flag."""
import gzip, json, collections
T2 = "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/evidence/attack-wave/T2"
OUT = "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/evidence/attack-wave/T5"
mp = json.load(gzip.open(T2 + "/raw/l2-messagepassed.json.gz"))["logs"]
val = {}
for l in mp:
    d = l["data"][2:]; val["0x" + d[192:256].lower()] = ("bedrock", int(d[0:64], 16), int(l["blockNumber"], 16))
for f in ("legacy-v0-census.json.gz", "ovm1-v0-census.json.gz"):
    for r in json.load(gzip.open(T2 + "/" + f)): val[r["withdrawalHash"].lower()] = ("legacy", r["value"], None)
fin = json.load(gzip.open(T2 + "/raw/op-portal-finalized.json.gz"))["logs"]
s = collections.defaultdict(lambda: [0, 0]); unknown = []; seen = collections.Counter(); byblock = []
for l in fin:
    h = l["topics"][1].lower(); ok = int(l["data"][2:], 16) == 1; seen[h] += 1
    if h not in val: unknown.append(h); continue
    era, v, _ = val[h]; s[(era, ok)][0] += 1; s[(era, ok)][1] += v
    byblock.append((int(l["blockNumber"], 16), v if ok else 0))
init = sum(v for e, v, _ in val.values() if e == "bedrock")
finBE = set(h for h in seen if h in val and val[h][0] == "bedrock")
pendBE = sum(v for h, (e, v, _) in val.items() if e == "bedrock" and h not in finBE)
res = dict(sums={f"{k[0]}_{'success' if k[1] else 'failed'}": {"n": n, "wei": str(w)} for k, (n, w) in s.items()},
           unknown_finalized_hashes=unknown, duplicates=[h for h, c in seen.items() if c > 1],
           bedrock_initiated_wei=str(init), bedrock_pending_wei=str(pendBE),
           paid_success_wei=str(sum(w for k, (n, w) in s.items() if k[1])))
json.dump(res, open(OUT + "/finalized-join.json", "w"), indent=1)
json.dump(sorted(byblock), gzip.open(OUT + "/finalized-paid-by-block.json.gz", "wt"))
for k, v in res.items(): print(k, v if not isinstance(v, list) else (len(v), v[:5]))
