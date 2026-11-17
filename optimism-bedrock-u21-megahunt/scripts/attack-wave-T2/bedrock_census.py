"""ATK-T2 (b): every OP L2ToL1MessagePasser MessagePassed (L2 105,235,063..159,654,093) joined with OP portal
WithdrawalProven / WithdrawalFinalized (L1 17,365,000..26,433,900). Groups never-finalized withdrawals by era."""
import json, os, collections
R = "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/evidence/attack-wave/T2/raw"
OUT = "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/evidence/attack-wave/T2"
def load(n): return json.load(open(os.path.join(R, n)))["logs"]
fin = {l["topics"][1].lower(): (int(l["data"][2:], 16) == 1, int(l["blockNumber"], 16)) for l in load("op-portal-finalized.json")}
prov = collections.defaultdict(list)
for l in load("op-portal-proven.json"): prov[l["topics"][1].lower()].append(int(l["blockNumber"], 16))
# L2 eras (OP Mainnet hardforks by L2 block; timestamps converted with 2 s blocks from Bedrock genesis)
ERAS = [(105235063, "bedrock"), (117387812, "canyon"), (117387812+0, "canyon"), (117387812+2*0, "")]
def era(ts):
    for t, n in [(1746806401, "isthmus+"), (1736445601, "holocene"), (1720627201, "granite"), (1710374401, "ecotone/fjord"), (1704992401, "canyon/delta")]:
        if ts >= t: return n
    return "bedrock(regolith)"
L2CDM = "0x4200000000000000000000000000000000000007"; L1CDM = "0x25ace71c97b33cc4729cf772ae268934f7ab5fa1"
rows = []
for l in load("l2-messagepassed.json"):
    d = bytes.fromhex(l["data"][2:]); w = lambda i: int.from_bytes(d[32*i:32*i+32], "big")
    value, gas, off, wh = w(0), w(1), w(2), "0x" + d[96:128].hex()
    ln = int.from_bytes(d[off:off+32], "big"); data = d[off+32:off+32+ln]
    nonce = int(l["topics"][1], 16); sender = "0x" + l["topics"][2][-40:]; target = "0x" + l["topics"][3][-40:]
    blk = int(l["blockNumber"], 16); ts = 1686068903 + 2*(blk - 105235063)
    inner = {}
    if sender == L2CDM and data[:4].hex() == "d764ad0b":
        iw = lambda i: int.from_bytes(data[4+32*i:4+32*i+32], "big")
        inner = dict(nonce=iw(0), sender="0x" + data[4+44:4+64].hex(), target="0x" + data[4+76:4+96].hex(), value=iw(3), minGas=iw(4), msgLen=int.from_bytes(data[4+iw(5):4+iw(5)+32], "big"), selector="0x" + data[4+iw(5)+32:4+iw(5)+36].hex())
    f = fin.get(wh)
    rows.append(dict(l2Block=blk, l2Tx=l["transactionHash"], era=era(ts), nonceVersion=nonce >> 240, nonce=nonce, sender=sender, target=target, value=value, gasLimit=gas,
                     dataLen=ln, withdrawalHash=wh, provenBlocks=prov.get(wh, []), finalized=f, inner=inner, data="0x" + data.hex()))
json.dump(rows, open(os.path.join(OUT, "bedrock-messagepassed-census.json"), "w"))
g = collections.defaultdict(lambda: [0, 0])
for r in rows:
    st = "finalized" if r["finalized"] else ("proven" if r["provenBlocks"] else "unproven")
    kind = "messenger" if r["sender"] == L2CDM else "direct"
    k = (r["era"], kind, st, r["nonceVersion"]); g[k][0] += 1; g[k][1] += r["value"]
print("rows", len(rows), "nonce versions", collections.Counter(r["nonceVersion"] for r in rows))
print("finalized success=false:", sum(1 for r in rows if r["finalized"] and not r["finalized"][0]))
for k in sorted(g): print(k, g[k][0], round(g[k][1]/1e18, 6), "ETH")
un = [r for r in rows if not r["finalized"]]
print("never finalized", len(un), "value", sum(r["value"] for r in un)/1e18, "ETH; with value", sum(1 for r in un if r["value"]))
print("max gasLimit never-finalized", max(r["gasLimit"] for r in un), "max dataLen", max(r["dataLen"] for r in un))
print("never-finalized messenger with sender L2CDM but target != L1CDM", sum(1 for r in un if r["sender"] == L2CDM and r["target"] != L1CDM))
print("never-finalized inner minGas>2^24", sum(1 for r in un if r["inner"] and r["inner"]["minGas"] > 2**24), "gasLimit>2^24", sum(1 for r in un if r["gasLimit"] > 2**24))
top = sorted(un, key=lambda r: -r["value"])[:12]
for r in top: print(r["l2Block"], r["era"], r["withdrawalHash"], r["sender"], r["target"], r["value"]/1e18, "proven" if r["provenBlocks"] else "unproven", r["inner"].get("target"), r["inner"].get("selector"))
