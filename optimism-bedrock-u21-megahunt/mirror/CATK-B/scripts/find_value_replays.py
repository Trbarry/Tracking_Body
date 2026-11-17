#!/usr/bin/env python3
"""Find the first RelayedMessage event after each value-bearing failure.

All requests are passive eth_getLogs/eth_getTransactionByHash reads against the
engagement's read-only proxy. Ranges never exceed 10,000 blocks.
"""

import json
import pathlib
import urllib.request

RPC = "http://127.0.0.1:7545"
PINNED = 26_433_900
TOPIC = "0x4641df4a962071e12719d8c8c8e5ac7fc4d97b927346a3d7a335b1f7517e133c"
ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "evidence" / "failure-census-enriched.json"
OUTPUT = ROOT / "evidence" / "value-message-replays.json"


def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(RPC, data=body, headers={"content-type": "application/json"})
    with urllib.request.urlopen(req, timeout=120) as response:
        reply = json.load(response)
    if "error" in reply:
        raise RuntimeError(reply["error"])
    return reply["result"]


def first_relay(messenger, message_hash, start):
    cursor = start
    while cursor <= PINNED:
        end = min(cursor + 9_999, PINNED)
        logs = rpc("eth_getLogs", [{
            "address": messenger,
            "fromBlock": hex(cursor),
            "toBlock": hex(end),
            "topics": [TOPIC, message_hash],
        }])
        if logs:
            log = min(logs, key=lambda item: (int(item["blockNumber"], 16), int(item["logIndex"], 16)))
            tx = rpc("eth_getTransactionByHash", [log["transactionHash"]])
            return {
                "block": int(log["blockNumber"], 16),
                "log_index": int(log["logIndex"], 16),
                "tx": log["transactionHash"],
                "caller": tx["from"],
                "to": tx["to"],
                "transaction_value_wei": int(tx["value"], 16),
            }
        cursor = end + 1
    return None


def main():
    census = json.loads(SOURCE.read_text())
    rows = []
    for message in census["failed_messages"]:
        relay = message["relay"]
        if relay["value_wei"] == 0:
            continue
        first_failure = min(event["block"] for event in message["events"])
        rows.append({
            "chain": message["chain"],
            "message_hash": message["message_hash"],
            "message_value_wei": relay["value_wei"],
            "first_failure_block": first_failure,
            "replay": first_relay(message["messenger"], message["message_hash"], first_failure),
        })
    OUTPUT.write_text(json.dumps({
        "meta": {
            "rpc": RPC,
            "passive_reads_only": True,
            "max_log_range": 10_000,
            "pinned_block": PINNED,
        },
        "messages": rows,
    }, indent=2) + "\n")
    print(json.dumps(rows, indent=2))


if __name__ == "__main__":
    main()
