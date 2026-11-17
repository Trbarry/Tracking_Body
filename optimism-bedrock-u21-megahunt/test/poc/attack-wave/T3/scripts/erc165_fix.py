# Proper ERC165Checker semantics (supportsERC165 = si(0x01ffc9a7) && !si(0xffffffff)) for L1 and L2 tokens of every census pair.
import json,time
from pair_census_lib import batch, call, SI, B1, B2, L1, L2
rows=json.load(open("../out/op_pair_census.json"))
t=lambda x:(x is not None and len(x)>=66 and int(x[2:66],16)==1)
for r in rows:
    a=batch(L1,[call(0,r["l1"],SI("01ffc9a7"),B1),call(1,r["l1"],SI("ffffffff"),B1)])
    b=batch(L2,[call(0,r["l2"],SI("01ffc9a7"),B2),call(1,r["l2"],SI("ffffffff"),B2)])
    r["l1_erc165"]=t(a[0]) and not t(a[1]); r["l2_erc165"]=t(b[0]) and not t(b[1])
    r["l1_mintable_bridge"]=r["l1_mintable"] and r["l1_erc165"]
    r["l2_mintable_bridge"]=(r["l2_legacyIface"] or r["l2_newIface"]) and r["l2_erc165"]
    time.sleep(0.05)
json.dump(rows,open("../out/op_pair_census.json","w"),indent=1)
from collections import Counter
print("l1 mintable (bridge semantics)",Counter(r["l1_mintable_bridge"] for r in rows))
print("l2 mintable (bridge semantics)",Counter(r["l2_mintable_bridge"] for r in rows))
for r in rows:
    if r["l1_mintable"]!=r["l1_mintable_bridge"] or (r["l2_legacyIface"] or r["l2_newIface"])!=r["l2_mintable_bridge"]: print("diff",r["l1"],r["l2"],r["cls"])
