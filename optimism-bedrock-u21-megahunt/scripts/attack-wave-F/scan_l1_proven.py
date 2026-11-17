# ATK-F: WithdrawalProven logs on the 4 portals whose `to` (topic3) is a system-contract address
import json, sys, urllib.request
RPC = "http://127.0.0.1:7545"
BASE = "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/"
PROVEN = "0x67a6208cfcc0801d50f6cbe764733f4fddf66ac0b04442061a8a8c0cb6b63f62"
PORTALS = {"OP": "0xbEb5Fc579115071764c7423A4f12eDde41f106Ed", "INK": "0x5d66C1782664115999C47c9fA5cd031f495D3e4F",
           "SONEIUM": "0x88e529A6ccd302c948689Cd5156C83D4614FAE92", "UNICHAIN": "0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2"}
TO_BLOCK = 26433900
def rpc(m, p):
    r = urllib.request.Request(RPC, json.dumps({"jsonrpc": "2.0", "id": 1, "method": m, "params": p}).encode(), {"content-type": "application/json"})
    out = json.load(urllib.request.urlopen(r, timeout=600))
    if "error" in out: raise RuntimeError(out["error"])
    return out["result"]
addrs = json.load(open(BASE + "evidence/attack-wave/F/system-address-set-raw.json"))
# exclude the L2CDM->L1CDM normal path: L1CDMs are kept (we report them separately)
topics = ["0x" + "0" * 24 + a[2:] for a in addrs]
hits = []
for name, portal in PORTALS.items():
    for i in range(0, len(topics), 60):
        chunk = topics[i:i + 60]
        frm = 17000000
        while frm <= TO_BLOCK:
            to = min(frm + 3000000, TO_BLOCK)
            logs = rpc("eth_getLogs", [{"fromBlock": hex(frm), "toBlock": hex(to), "address": portal, "topics": [PROVEN, None, None, chunk]}])
            for l in logs:
                hits.append({"chain": name, "portal": portal, "block": int(l["blockNumber"], 16), "tx": l["transactionHash"],
                             "withdrawalHash": l["topics"][1], "from": "0x" + l["topics"][2][26:], "to": "0x" + l["topics"][3][26:]})
            frm = to + 1
    print(name, "hits so far", len(hits), file=sys.stderr)
json.dump(hits, open(BASE + "evidence/attack-wave/F/l1-proven-to-system-raw.json", "w"), indent=1)
from collections import Counter
c = Counter((h["chain"], h["from"], h["to"]) for h in hits)
for k, v in c.most_common(): print(v, k, addrs.get(k[2]))
