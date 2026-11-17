#!/usr/bin/env python3
"""Fetch two real v7-era in-flight-object fixtures using passive RPC methods only."""

from __future__ import annotations

import argparse
import json
import urllib.request
from pathlib import Path
from typing import Any


PORTAL = "0xbEb5Fc579115071764c7423A4f12eDde41f106Ed"
MESSENGER = "0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1"
WITHDRAWAL_PROVEN = "0x67a6208cfcc0801d50f6cbe764733f4fddf66ac0b04442061a8a8c0cb6b63f62"
FAILED_RELAYED_MESSAGE = "0x99d0e048484baa1b1540b1367cb128acd7ab2946d1ed91ec10e3c85e4bf51b8f"

FIXTURES = {
    "prove-v7": {
        "hash": "0xb88907b5de5ab604eb8a82a7a9af14c33cee8d702b75c1c25e6b1031e203badc",
        "eventAddress": PORTAL,
        "eventTopic0": WITHDRAWAL_PROVEN,
        "scanFrom": 25_397_812,
        "scanTo": 25_407_811,
    },
    "failed-message-v7": {
        "hash": "0x8c899957c12979b99a02e680e8d695386056ec968fea0cc5d07405b809d27622",
        "eventAddress": MESSENGER,
        "eventTopic0": FAILED_RELAYED_MESSAGE,
        "scanFrom": 25_470_000,
        "scanTo": 25_479_999,
    },
    "prove-v7-carry": {
        "hash": "0x2a1b15e0ed21bc5d50cd75dd749740173c23e2d29171fdc4b79f942b785d0d1c",
        "eventAddress": PORTAL,
        "eventTopic0": WITHDRAWAL_PROVEN,
        "scanFrom": 25_790_000,
        "scanTo": 25_799_999,
    },
}


def rpc(url: str, method: str, params: list[Any]) -> Any:
    payload = json.dumps(
        {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}
    ).encode()
    request = urllib.request.Request(
        url, payload, {"Content-Type": "application/json"}, method="POST"
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        body = json.load(response)
    if "error" in body:
        raise RuntimeError(body["error"])
    return body["result"]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--rpc-url", default="http://127.0.0.1:7545")
    parser.add_argument("--out-dir", type=Path, default=Path("fixtures"))
    args = parser.parse_args()
    args.out_dir.mkdir(parents=True, exist_ok=True)

    for name, definition in FIXTURES.items():
        # The discovery range is exactly 10,000 blocks, satisfying upstream limits.
        logs = rpc(
            args.rpc_url,
            "eth_getLogs",
            [
                {
                    "fromBlock": hex(definition["scanFrom"]),
                    "toBlock": hex(definition["scanTo"]),
                    "address": definition["eventAddress"],
                    "topics": [definition["eventTopic0"]],
                }
            ],
        )
        matching = [entry for entry in logs if entry["transactionHash"] == definition["hash"]]
        if len(matching) != 1:
            raise RuntimeError(f"{name}: expected one matching event, got {len(matching)}")
        tx = rpc(args.rpc_url, "eth_getTransactionByHash", [definition["hash"]])
        block = rpc(args.rpc_url, "eth_getBlockByNumber", [tx["blockNumber"], False])
        fixture = {
            "name": name,
            "hash": definition["hash"],
            "block": int(tx["blockNumber"], 16),
            "blockTimestamp": int(block["timestamp"], 16),
            "transactionIndex": int(tx["transactionIndex"], 16),
            "from": tx["from"],
            "to": tx["to"],
            "value": int(tx["value"], 16),
            "gas": int(tx["gas"], 16),
            "input": tx["input"],
            "event": matching[0],
            "scan": {
                "fromBlock": definition["scanFrom"],
                "toBlock": definition["scanTo"],
                "chunkSize": 10_000,
            },
        }
        (args.out_dir / f"{name}.json").write_text(json.dumps(fixture, indent=2) + "\n")


if __name__ == "__main__":
    main()
