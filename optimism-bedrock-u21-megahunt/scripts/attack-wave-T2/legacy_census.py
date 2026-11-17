"""ATK-T2 (a): census of every legacy (version-0) messenger withdrawal emitted on OVM 2.0 L2
(legacy L2CDM SentMessage, L2 blocks 0..105,235,062), migrated exactly as op-chain-ops
MigrateWithdrawal did, then joined with L1 relay status (legacy RelayedMessage(v0hash),
Bedrock RelayedMessage/FailedRelayedMessage(v1hash)) and portal proven/finalized(withdrawalHash)."""
import json, os, sys, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from keccak import keccak
R = "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/evidence/attack-wave/T2/raw"
OUT = "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/evidence/attack-wave/T2"
L1CDM = bytes.fromhex("25ace71c97b33cc4729cf772ae268934f7ab5fa1")
L2CDM = bytes.fromhex("4200000000000000000000000000000000000007")
L2SB = bytes.fromhex("4200000000000000000000000000000000000010")
L1SB = bytes.fromhex("99c9fc46f92e8a1c0dec1b1747d010903e884be1")
def w(x): return x.to_bytes(32, "big")
def a(x): return b"\x00"*12 + x
def dyn(b): return w(len(b)) + b + b"\x00"*((32 - len(b) % 32) % 32)
def dec_word(d, i): return int.from_bytes(d[32*i:32*i+32], "big")
def migrate_gas(data):
    g = len(data)*16 + 200_000 + (64*1_000_000)//63 + 40_000 + 40_000 + 5_000
    return min(g, 25_000_000)
def load(name): return json.load(open(os.path.join(R, name)))["logs"]

legacy_relayed = set(); bedrock_relayed = set(); failed = set(); relayed_block = {}
for l in load("l1cdm-relayed.json"):
    h = l["topics"][1] if len(l["topics"]) > 1 else l["data"]
    blk = int(l["blockNumber"], 16)
    (legacy_relayed if blk < 17422444 else bedrock_relayed).add(h.lower()); relayed_block.setdefault(h.lower(), blk)
for l in load("l1cdm-failed.json"):
    h = l["topics"][1] if len(l["topics"]) > 1 else l["data"]; failed.add(h.lower())
fin = {}
for l in load("op-portal-finalized.json"):
    fin[l["topics"][1].lower()] = (int(l["data"][2:], 16) == 1, int(l["blockNumber"], 16))
prov = collections.Counter(l["topics"][1].lower() for l in load("op-portal-proven.json"))

rows = []
for l in load("l2-legacy-sentmessage.json"):
    target = bytes.fromhex(l["topics"][1][-40:])
    d = bytes.fromhex(l["data"][2:])
    sender = d[12:32]; off = dec_word(d, 1); nonce = dec_word(d, 2); gl = dec_word(d, 3)
    ln = dec_word(d, off//32); msg = d[off+32: off+32+ln]
    value = 0
    if sender == L2SB and msg[:4] == bytes.fromhex("1532ec34"):
        value = int.from_bytes(msg[4+64:4+96], "big")
    v0 = keccak(bytes.fromhex("cbd4ece9") + a(target) + a(sender) + w(128) + w(nonce) + dyn(msg))
    data = bytes.fromhex("d764ad0b") + w(nonce) + a(sender) + a(target) + w(value) + w(0) + w(192) + dyn(msg)
    v1 = keccak(data)
    gas = migrate_gas(data)
    wh = keccak(w(nonce) + a(L2CDM) + a(L1CDM) + w(value) + w(gas) + w(192) + dyn(data))
    v0h, v1h, whh = "0x"+v0.hex(), "0x"+v1.hex(), "0x"+wh.hex()
    rows.append(dict(l2Block=int(l["blockNumber"], 16), l2Tx=l["transactionHash"], nonce=nonce, sender="0x"+sender.hex(),
        target="0x"+target.hex(), value=value, l2GasLimit=gl, msgLen=len(msg), selector="0x"+msg[:4].hex(),
        v0Hash=v0h, v1Hash=v1h, withdrawalHash=whh, migratedGasLimit=gas, relayDataLen=len(data),
        legacyRelayed=v0h in legacy_relayed, legacyRelayBlock=relayed_block.get(v0h),
        bedrockRelayed=v1h in bedrock_relayed, bedrockFailed=v1h in failed,
        portalProvenEvents=prov.get(whh, 0), portalFinalized=fin.get(whh)))
def cls(r):
    if r["legacyRelayed"] and r["portalFinalized"]: return "relayed_pre_bedrock+portal_finalized(double attempt)"
    if r["legacyRelayed"] and r["portalProvenEvents"]: return "relayed_pre_bedrock+portal_proven_only"
    if r["legacyRelayed"]: return "relayed_pre_bedrock_only"
    if r["portalFinalized"] and r["bedrockRelayed"]: return "bedrock_finalized_relayed"
    if r["portalFinalized"] and r["bedrockFailed"]: return "bedrock_finalized_failed_unreplayed"
    if r["portalFinalized"]: return "bedrock_finalized_other"
    if r["bedrockRelayed"]: return "bedrock_relayed_without_portal_event(replay?)"
    if r["portalProvenEvents"]: return "bedrock_proven_not_finalized"
    return "never_relayed_never_proven"
summ = collections.defaultdict(lambda: dict(n=0, value=0, maxGas=0, maxLen=0))
for r in rows:
    r["class"] = cls(r); s = summ[r["class"]]; s["n"] += 1; s["value"] += r["value"]
    s["maxGas"] = max(s["maxGas"], r["migratedGasLimit"]); s["maxLen"] = max(s["maxLen"], r["msgLen"])
nonces = [r["nonce"] for r in rows]
json.dump(rows, open(os.path.join(OUT, "legacy-v0-census.json"), "w"))
print("legacy SentMessage rows", len(rows), "nonce range", min(nonces), max(nonces), "dup nonces", len(nonces)-len(set(nonces)))
print("dup v0 hashes", len(rows)-len({r['v0Hash'] for r in rows}), "dup withdrawal hashes", len(rows)-len({r['withdrawalHash'] for r in rows}))
for k, s in sorted(summ.items()): print(f"{k:55s} n={s['n']:6d} value={s['value']/1e18:14.6f} ETH maxMigratedGas={s['maxGas']} maxMsgLen={s['maxLen']}")
# portal-level v0 hashes known on L1 but not produced by this OVM2 census (pre-regenesis / OVM1 messages)
mine = {r["withdrawalHash"] for r in rows}
print("legacy relayed v0 hashes on L1 total", len(legacy_relayed), "matched", len(legacy_relayed & {r['v0Hash'] for r in rows}))
