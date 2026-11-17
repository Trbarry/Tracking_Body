"""ATK-T2 (a'): census of the 17,924 pre-regenesis (OVM 1.0) messages that the Bedrock migration imported from
packages/migration-data/data/ovm-messages.json, migrated with MigrateWithdrawal, joined with L1 status."""
import json, os, sys, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from keccak import keccak
from legacy_census_lib import *
MD = "/home/user/ethereum-optimism/ext-codex/sherlock-bedrock-fix-CF3/optimism/packages/migration-data/data/ovm-messages.json"
msgs = json.load(open(MD))
legacy_relayed, bedrock_relayed, failed, rb, fin, prov = l1_status()
rows = []; whos = collections.Counter()
for m in msgs:
    whos[m["who"].lower()] += 1
    c = bytes.fromhex(m["msg"][2:]); assert c[:4].hex() == "cbd4ece9"
    target = c[4+12:4+32]; sender = c[4+44:4+64]; off = dec_word(c[4:], 2); nonce = dec_word(c[4:], 3)
    ln = dec_word(c[4:], off//32); msg = c[4+off+32:4+off+32+ln]
    value, v0, v1, wh, gas, data = migrate(target, sender, msg, nonce)
    assert v0 == "0x" + keccak(c).hex()
    rows.append(dict(who=m["who"].lower(), nonce=nonce, sender="0x"+sender.hex(), target="0x"+target.hex(), value=value, msgLen=len(msg),
        selector="0x"+msg[:4].hex(), v0Hash=v0, v1Hash=v1, withdrawalHash=wh, migratedGasLimit=gas,
        legacyRelayed=v0 in legacy_relayed, legacyRelayBlock=rb.get(v0), bedrockRelayed=v1 in bedrock_relayed,
        bedrockFailed=v1 in failed, portalProvenEvents=prov.get(wh, 0), portalFinalized=fin.get(wh)))
json.dump(rows, open(os.path.join("/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/evidence/attack-wave/T2", "ovm1-v0-census.json"), "w"))
print("rows", len(rows), "who", whos.most_common(5))
print("nonce range", min(r["nonce"] for r in rows), max(r["nonce"] for r in rows), "dup v0", len(rows)-len({r['v0Hash'] for r in rows}))
print("targets", collections.Counter(r["target"] for r in rows).most_common(8))
print("senders", collections.Counter(r["sender"] for r in rows).most_common(8))
g = collections.defaultdict(lambda: [0, 0])
for r in rows:
    k = ("legacyRelayed" if r["legacyRelayed"] else "notLegacyRelayed", "portalFinalized" if r["portalFinalized"] else ("proven" if r["portalProvenEvents"] else "-"), "v1relayed" if r["bedrockRelayed"] else "", "who=L2CDM" if r["who"] == "0x4200000000000000000000000000000000000007" else "who=other")
    g[k][0] += 1; g[k][1] += r["value"]
for k in sorted(g): print(k, g[k][0], g[k][1]/1e18, "ETH")
