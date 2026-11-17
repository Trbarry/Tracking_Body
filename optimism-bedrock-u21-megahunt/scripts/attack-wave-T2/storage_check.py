"""ATK-T2: (1) for every legacy message relayed pre-Bedrock (per RelayedMessage events), read
L1CDM.successfulMessages(v0Hash) at L1 26,433,900 -- the exact slot the v9 legacy branch reads;
(2) for every never-relayed legacy message with value>0 and a random sample of the rest, read
L2ToL1MessagePasser.sentMessages(migratedWithdrawalHash) at L2 159,654,093 (is the object live?)."""
import json, os, sys, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rpc
from keccak import keccak
E = "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/evidence/attack-wave/T2"
rows = json.load(open(f"{E}/ovm1-v0-census.json")) + json.load(open(f"{E}/legacy-v0-census.json"))
for r in rows: r.setdefault("era", "ovm2" if r["nonce"] >= 100000 else "ovm1")
L1B = hex(26433900); L2B = hex(159654093)
rel = [r for r in rows if r["legacyRelayed"]]
res = rpc.batch(rpc.L1, [("eth_call", [{"to": "0x25ace71c97b33cc4729cf772ae268934f7ab5fa1", "data": "0xb1b1b209" + r["v0Hash"][2:]}, L1B]) for r in rel])
bad = [r for r, x in zip(rel, res) if int(x, 16) != 1]
print("relayed-pre-bedrock checked", len(rel), "successfulMessages(v0)!=true:", len(bad))
random.seed(7)
nr = [r for r in rows if not r["legacyRelayed"] and not r["portalFinalized"]]
sample = [r for r in nr if r["value"] > 0] + random.sample([r for r in nr if r["value"] == 0], 300)
slots = ["0x" + keccak(bytes.fromhex(r["withdrawalHash"][2:]) + b"\x00"*32).hex() for r in sample]
res2 = rpc.batch(rpc.L2, [("eth_getStorageAt", ["0x4200000000000000000000000000000000000016", s, L2B]) for s in slots])
live = [r for r, x in zip(sample, res2) if int(x, 16) == 1]
print("never-relayed sample", len(sample), "(value>0:", sum(1 for r in sample if r["value"] > 0), ") live in sentMessages:", len(live))
miss = [r for r, x in zip(sample, res2) if int(x, 16) != 1]
json.dump({"relayedChecked": len(rel), "relayedNotSuccessful": bad, "sampleSize": len(sample), "live": len(live), "missing": miss}, open(f"{E}/legacy-storage-check.json", "w"), indent=1)
for r in miss[:10]: print("missing", r["era"], r["nonce"], r["value"], r["withdrawalHash"])
