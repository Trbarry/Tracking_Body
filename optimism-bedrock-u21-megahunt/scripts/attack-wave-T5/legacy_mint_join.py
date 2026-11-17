"""ATK-T5 (reverse-order matching): join legacy L1 ETHDepositInitiated (L1SB, L1 12,686,786..17,423,157) with OVM 2.0 L2 ETH DepositFinalized
(L2 0..105,235,062) as multisets keyed by (L1 sender, amount), in order. Reports L2 mints without an L1 lock and L1
locks never minted in OVM 2.0 (split before/after the first matched deposit = OVM 2.0 start)."""
import json, gzip, collections
E = "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/evidence/attack-wave/T5"
l1 = [(int(l["blockNumber"], 16), int(l["logIndex"], 16), "0x" + l["topics"][1][-40:], int(l["data"][2:66], 16), l["transactionHash"]) for l in [l for i in (1, 2) for l in json.load(gzip.open(E + f"/legacy-l1sb-eth-deposits.part{i}.json.gz"))["logs"]]]
l1.sort()
l2 = json.load(gzip.open(E + "/l2-legacy-eth-mints.json.gz"))["rows"]
q = collections.defaultdict(collections.deque)
for r in l2: q[(r[1].lower(), int(r[3]))].append(r)
matched = []; unl1 = []
for x in reversed(l1):   # newest L1 lock <-> newest L2 mint of the same (sender, amount): OVM 2.0 mints are the latest locks
    k = (x[2].lower(), x[3])
    if q[k]: matched.append((x, q[k].pop()))
    else: unl1.append(x)
unl1.reverse()
unl2 = [r for d in q.values() for r in d]
first_m = min(m[0][0] for m in matched)
# OVM 2.0 L1 start: first L1 deposit block whose mint appears in OVM 2.0 L2 logs
pre = [x for x in unl1 if x[0] < 13596000]; post = [x for x in unl1 if x[0] >= 13596000]
out = dict(l1_deposits=len(l1), l2_mints=len(l2), matched=len(matched), first_matched_l1_block=first_m,
           l2_mints_without_l1=len(unl2), l2_mints_without_l1_wei=str(sum(int(r[3]) for r in unl2)), l2_unmatched=unl2[:50],
           l1_unminted_total=len(unl1), l1_unminted_wei=str(sum(x[3] for x in unl1)),
           l1_unminted_before_13596000=len(pre), wei_before=str(sum(x[3] for x in pre)),
           l1_unminted_after_13596000=len(post), wei_after=str(sum(x[3] for x in post)), after_list=post[:100],
           last_unminted_pre_block=max((x[0] for x in pre), default=None), first_matched_after=min((m[0][0] for m in matched if m[0][0] >= 13500000)))
json.dump(out, open(E + "/legacy-mint-join.json", "w"), indent=1)
for k, v in out.items():
    print(k, v if not isinstance(v, list) else (len(v), v[:8]))
