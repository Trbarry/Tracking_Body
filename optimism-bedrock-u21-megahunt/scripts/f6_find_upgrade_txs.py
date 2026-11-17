#!/usr/bin/env python3
"""F6: for every implementation-change block in evidence/F6-op-upgrade-blocks.json find the
transaction(s) that performed it and save the replay inputs.

For each distinct change block: eth_getBlockReceipts -> transactions whose logs contain
  Upgraded(address)            0xbc7cd75a...  emitted by a tracked EIP-1967 proxy, or
  AddressSet(string,address,address) emitted by the AddressManager,
then eth_getTransactionByHash for from/to/input/gas/value/index.
The L1ChugSplashProxy (L1StandardBridge) emits no event; it is attributed to the tx of its block
when exactly one upgrade tx exists there (verified later by the forge replay, which compares
the implementation pointers after replay with the real post-block state).

Output: evidence/F6-op-upgrade-txs.json  (+ test/fixtures/upgrades/<label>.json with calldata)
"""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from f6_rpc import call

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
UPGRADED = "0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b"
ADDRESS_MANAGER = "0xde1fcfb0851916ca5101820a69b13a4e276bd81f"

def main():
    hist = json.load(open(os.path.join(ROOT, "evidence", "F6-op-upgrade-blocks.json")))
    proxies = {c["proxy"].lower(): n for n, c in hist["contracts"].items()}
    by_block = {}
    for n, c in hist["contracts"].items():
        for ch in c["changes"]:
            by_block.setdefault(ch["block"], []).append({"contract": n, **ch})
    out = {"meta": {"source": "evidence/F6-op-upgrade-blocks.json", "rpc": "http://127.0.0.1:7545"}, "blocks": []}
    for blk in sorted(by_block):
        receipts = call("eth_getBlockReceipts", [hex(blk)])
        cands = {}
        for r in receipts:
            for lg in r["logs"]:
                a = lg["address"].lower()
                if (a in proxies and lg["topics"][0] == UPGRADED) or a == ADDRESS_MANAGER:
                    cands.setdefault(r["transactionHash"], {"status": r["status"], "gasUsed": int(r["gasUsed"], 16), "emitters": set(), "nlogs": len(r["logs"])})
                    cands[r["transactionHash"]]["emitters"].add(proxies.get(a, "AddressManager"))
        txs = []
        for h, info in cands.items():
            tx = call("eth_getTransactionByHash", [h])
            txs.append({"hash": h, "from": tx["from"], "to": tx["to"], "value": tx["value"], "gas": int(tx["gas"], 16),
                        "txIndex": int(tx["transactionIndex"], 16), "selector": tx["input"][:10], "inputLen": (len(tx["input"]) - 2) // 2,
                        "status": info["status"], "gasUsed": info["gasUsed"], "nlogs": info["nlogs"],
                        "emitters": sorted(info["emitters"]), "input": tx["input"]})
        txs.sort(key=lambda t: t["txIndex"])
        out["blocks"].append({"block": blk, "timestamp": by_block[blk][0]["timestamp"], "changes": by_block[blk], "txs": txs})
        print(blk, [(t["hash"], t["txIndex"], t["emitters"]) for t in txs], file=sys.stderr)
    json.dump(out, open(os.path.join(ROOT, "evidence", "F6-op-upgrade-txs.json"), "w"), indent=1)

if __name__ == "__main__":
    main()
