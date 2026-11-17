# ATK-F: OP Mainnet L2 MessagePassed (L2ToL1MessagePasser 0x42..16) whose target (topic3) is an L1 system contract (any chain, any generation).
# The four L1CrossDomainMessengers are excluded from the filter (normal L2CDM path). Also re-runs the L1 WithdrawalProven scan for
# the 9 addresses added during curation (DelayedWETH generations, WETH9).
import json, sys, urllib.request
BASE = "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/"
MP = "0x02a52367d10742d8032712c1bb8e0144ff1ec5ffda1ed7d70bb05a2744955054"
PROVEN = "0x67a6208cfcc0801d50f6cbe764733f4fddf66ac0b04442061a8a8c0cb6b63f62"
L1CDMS = {"0x25ace71c97b33cc4729cf772ae268934f7ab5fa1", "0x69d3cf86b2bf1a9e99875b7e2d9b6a84426c171f", "0x9cf951e3f74b644e621b36ca9cea147a78d4c39f", "0x9a3d64e386c18cb1d6d5179a9596a4b5736e98a6"}
def rpc(url, m, p):
    r = urllib.request.Request(url, json.dumps({"jsonrpc": "2.0", "id": 1, "method": m, "params": p}).encode(), {"content-type": "application/json"})
    out = json.load(urllib.request.urlopen(r, timeout=900))
    if "error" in out: raise RuntimeError(out["error"])
    return out["result"]
sysset = json.load(open(BASE + "evidence/attack-wave/F/system-contract-set.json"))
targets = [a for a in sysset if a not in L1CDMS]
topics = ["0x" + "0" * 24 + a[2:] for a in targets]
hits = []
START, END, STEP = 105235063, 159654093, 6000000
for i in range(0, len(topics), 80):
    chunk = topics[i:i + 80]
    frm = START
    while frm <= END:
        to = min(frm + STEP - 1, END)
        logs = rpc("http://127.0.0.1:7546", "eth_getLogs", [{"fromBlock": hex(frm), "toBlock": hex(to), "address": "0x4200000000000000000000000000000000000016", "topics": [MP, None, None, chunk]}])
        for l in logs:
            d = l["data"][2:]
            hits.append({"l2block": int(l["blockNumber"], 16), "tx": l["transactionHash"], "nonce": l["topics"][1], "sender": "0x" + l["topics"][2][26:],
                         "target": "0x" + l["topics"][3][26:], "value": int(d[0:64], 16), "gasLimit": int(d[64:128], 16), "withdrawalHash": "0x" + d[-64:], "data_head": d[192:192 + 136]})
        frm = to + 1
    print("chunk", i, "hits", len(hits), file=sys.stderr)
json.dump(hits, open(BASE + "evidence/attack-wave/F/l2-op-messagepassed-to-system.json", "w"), indent=1)
# supplementary L1 proven scan for the 9 curated extras
extra = [a for a, v in sysset.items() if v["src"] == ["F4 hist / WETH9"]]
PORTALS = ["0xbEb5Fc579115071764c7423A4f12eDde41f106Ed", "0x5d66C1782664115999C47c9fA5cd031f495D3e4F", "0x88e529A6ccd302c948689Cd5156C83D4614FAE92", "0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2"]
l1 = rpc("http://127.0.0.1:7545", "eth_getLogs", [{"fromBlock": hex(17000000), "toBlock": hex(26433900), "address": PORTALS, "topics": [PROVEN, None, None, ["0x" + "0" * 24 + a[2:] for a in extra]]}])
json.dump({"extra_targets": extra, "logs": l1}, open(BASE + "evidence/attack-wave/F/l1-proven-to-extra.json", "w"), indent=1)
print("L2 hits", len(hits), "L1 extra hits", len(l1))
from collections import Counter
for k, v in Counter((h["sender"], h["target"]) for h in hits).most_common(60): print(v, k, sysset[k[1]]["src"])
