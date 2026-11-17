#!/usr/bin/env python3
"""F4 — initializer / upgrade event history: for every signature-change block of a proxy (hist-X.json), fetch the logs
the proxy itself emitted in that block (single-block eth_getLogs, served for old blocks) and classify them:
Upgraded(address), AdminChanged, Initialized(uint8), Initialized(uint64), OwnershipTransferred, AddressSet (AddressManager).
Shows whether StorageSetter-reset + re-initialise happened inside ONE transaction.

usage: F4_init_events.py evidence/F4/hist-X.json [extra_address ...] > evidence/F4/events-X.json
"""
import json, sys, os
sys.path.insert(0, os.path.dirname(__file__))
from F4_rpc import call

T = {
    "0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b": "Upgraded",
    "0x7e644d79422f17c01e4894b5f4f588d331ebfa28653d42ae832dc59e38c9798f": "AdminChanged",
    "0x7f26b83ff96e1f2b6a682f133852f6798a09c465da95921460cefb3847402498": "Initialized(uint8)",
    "0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2": "Initialized(uint64)",
    "0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0": "OwnershipTransferred",
    "0x9416a153a346f93d95f94b064ae3f148b6460473c6e82b3f9fc2521b873fcd6c": "AddressSet",
}


def main():
    h = json.load(open(sys.argv[1]))
    addrs = [h["proxy"]] + sys.argv[2:]
    out = {"name": h["name"], "proxy": h["proxy"], "blocks": []}
    for c in h["changes"]:
        b = c["block"]
        logs = call("eth_getLogs", [{"address": addrs, "fromBlock": hex(b), "toBlock": hex(b)}])
        txs = {}
        for l in logs:
            name = T.get(l["topics"][0])
            if not name:
                continue
            arg = ("0x" + l["topics"][1][-40:]) if len(l["topics"]) > 1 else l["data"]
            if name.startswith("Initialized"):
                arg = int(l["data"], 16)
            if name == "AddressSet":
                arg = "new=0x" + l["data"][2 + 64 + 24:2 + 128] + " old=0x" + l["data"][2 + 128 + 24:2 + 192]
            txs.setdefault(l["transactionHash"], []).append(
                [int(l["logIndex"], 16), l["address"][-6:], name, arg])
        out["blocks"].append({"block": b, "timestamp": c["timestamp"], "txs": txs,
                              "init_before": c["before"][1], "init_after": c["after"][1]})
    json.dump(out, sys.stdout, indent=1)


if __name__ == "__main__":
    main()
