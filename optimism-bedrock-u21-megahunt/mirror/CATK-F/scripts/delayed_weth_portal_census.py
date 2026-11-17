#!/usr/bin/env python3
"""Read-only portal balance/allowance census over every DelayedWETH generation."""

import glob
import json
import urllib.request
from pathlib import Path


ROOT = Path("/home/user/Tracking_Body/optimism-bedrock-u21-megahunt")
RPC_URL = "http://127.0.0.1:7545"
PIN = 26_433_900
START = 17_000_000
OUT = ROOT / "mirror/CATK-F/evidence/delayed-weth-portal-census.json"
APPROVAL = "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925"
TRANSFER = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
BALANCE_OF = "70a08231"
ALLOWANCE = "dd62ed3e"

PORTALS = {
    "OP": "0xbeb5fc579115071764c7423a4f12edde41f106ed",
    "INK": "0x5d66c1782664115999c47c9fa5cd031f495d3e4f",
    "SONEIUM": "0x88e529a6ccd302c948689cd5156c83d4614fae92",
    "UNICHAIN": "0x0bd48f6b86a26d3a217d0fa6ffe2b491b956a7a2",
}


class RPC:
    def __init__(self):
        self.ident = 0
        self.calls = 0

    def call(self, method, params):
        self.ident += 1
        self.calls += 1
        request = urllib.request.Request(
            RPC_URL,
            json.dumps({"jsonrpc": "2.0", "id": self.ident, "method": method, "params": params}).encode(),
            {"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(request, timeout=120) as response:
            obj = json.load(response)
        if "error" in obj:
            raise RuntimeError(obj["error"])
        return obj["result"]


def word(address):
    return "0" * 24 + address[2:].lower()


def eth_call(rpc, to, data):
    raw = rpc.call("eth_call", [{"to": to, "data": "0x" + data}, hex(PIN)])
    return int(raw, 16)


def compact_log(log):
    return {
        "address": log["address"].lower(),
        "block": int(log["blockNumber"], 16),
        "transaction_hash": log["transactionHash"].lower(),
        "log_index": int(log["logIndex"], 16),
        "topics": [topic.lower() for topic in log["topics"]],
        "value": int(log["data"], 16),
    }


def main():
    weths = {}
    for filename in glob.glob(str(ROOT / "evidence/F4/hist-*DelayedWETH*.json")):
        obj = json.loads(Path(filename).read_text())
        address = obj["proxy"].lower()
        weths[address] = Path(filename).name
    addresses = sorted(weths)
    rpc = RPC()
    rows = []
    approvals = []
    transfers_to = []
    transfers_from = []

    for chain, portal in PORTALS.items():
        for weth in addresses:
            balance = eth_call(rpc, weth, BALANCE_OF + word(portal))
            rows.append({"chain_identity": chain, "portal": portal, "delayed_weth": weth, "balance": balance})

        padded = "0x" + word(portal)
        approval_logs = rpc.call(
            "eth_getLogs",
            [{"fromBlock": hex(START), "toBlock": hex(PIN), "address": addresses, "topics": [APPROVAL, None, padded]}],
        )
        for log in approval_logs:
            item = compact_log(log)
            owner = "0x" + item["topics"][1][-40:]
            item.update(
                {
                    "chain_identity": chain,
                    "portal": portal,
                    "owner": owner,
                    "allowance_at_pin": eth_call(rpc, item["address"], ALLOWANCE + word(owner) + word(portal)),
                }
            )
            approvals.append(item)

        for topic_index, destination in ((2, transfers_to), (1, transfers_from)):
            topics = [TRANSFER, None, None]
            topics[topic_index] = padded
            logs = rpc.call(
                "eth_getLogs",
                [{"fromBlock": hex(START), "toBlock": hex(PIN), "address": addresses, "topics": topics}],
            )
            for log in logs:
                item = compact_log(log)
                item.update({"chain_identity": chain, "portal": portal})
                destination.append(item)

    result = {
        "method": {
            "safety": "read-only eth_call and eth_getLogs at explicit L1 pin",
            "rpc": RPC_URL,
            "pin": PIN,
            "event_range_inclusive": [START, PIN],
            "delayed_weth_source": "evidence/F4/hist-*DelayedWETH*.json",
            "rpc_calls": rpc.calls,
        },
        "delayed_weth_contracts": [{"address": address, "source": weths[address]} for address in addresses],
        "portal_balances": rows,
        "nonzero_portal_balances": [row for row in rows if row["balance"] != 0],
        "approval_events_to_portals": approvals,
        "nonzero_allowances_at_pin": [item for item in approvals if item["allowance_at_pin"] != 0],
        "transfer_events_to_portals": transfers_to,
        "transfer_events_from_portals": transfers_from,
    }
    OUT.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(
        f"weths={len(addresses)} balances={len(rows)} nonzero_balances={len(result['nonzero_portal_balances'])} "
        f"approvals={len(approvals)} live_allowances={len(result['nonzero_allowances_at_pin'])} "
        f"transfers_to={len(transfers_to)} transfers_from={len(transfers_from)} rpc_calls={rpc.calls}"
    )
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
