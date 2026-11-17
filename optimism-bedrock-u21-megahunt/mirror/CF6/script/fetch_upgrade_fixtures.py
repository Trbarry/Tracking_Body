#!/usr/bin/env python3
"""Fetch passive OP Mainnet upgrade transaction fixtures from the local archive proxy."""

from __future__ import annotations

import argparse
import json
import urllib.request
from pathlib import Path
from typing import Any

from discover_upgrades import (
    EIP1967_IMPLEMENTATION,
    MESSENGER_ADDRESS_MANAGER_SLOT,
    TARGETS,
)


UPGRADES = {
    "v5": "0xf556934cb4de1ab40a4cfba17856cd601cbc8b875b96a9ccd8ee32bcd363abf5",
    "v6": "0x8808cd53114e4cf07bfde30daf24f2984d4a40ab09c5ca67bd171ac29d6dbf37",
    "v7": "0xbfdac60c9687a2e469159bf2458e73de2915a0a5eb53c4991a7ecde2b1fb3f15",
    "v8": "0x0a0fe86f7b1a3d3d2d0be990e3f8b15628b885363ae527fa9548cb2c2375741a",
    "v9": "0x024770b5fba87683ee1466562eefb1bcb408c29c764e24abd07c7d4050a82a99",
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


def as_int(value: str) -> int:
    return int(value, 16)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--rpc-url", default="http://127.0.0.1:7545")
    parser.add_argument("--out-dir", type=Path, default=Path("fixtures"))
    args = parser.parse_args()
    args.out_dir.mkdir(parents=True, exist_ok=True)

    manifest: dict[str, Any] = {
        "source": args.rpc_url,
        "safety": "eth_getTransactionByHash, eth_getBlockByNumber and eth_getStorageAt only",
        "upgrades": {},
    }
    for release, tx_hash in UPGRADES.items():
        tx = rpc(args.rpc_url, "eth_getTransactionByHash", [tx_hash])
        block = rpc(args.rpc_url, "eth_getBlockByNumber", [tx["blockNumber"], False])
        expected = {}
        for target in TARGETS:
            word = rpc(
                args.rpc_url,
                "eth_getStorageAt",
                [target.storage_address, target.storage_slot, tx["blockNumber"]],
            )
            expected[target.name] = "0x" + word[-40:]

        fixture = {
            "release": release,
            "hash": tx_hash,
            "block": as_int(tx["blockNumber"]),
            "blockHash": tx["blockHash"],
            "blockTimestamp": as_int(block["timestamp"]),
            "transactionIndex": as_int(tx["transactionIndex"]),
            "from": tx["from"],
            "to": tx["to"],
            "value": as_int(tx["value"]),
            "gas": as_int(tx["gas"]),
            "input": tx["input"],
            "expected": expected,
            "locators": {
                "defaultSlot": EIP1967_IMPLEMENTATION,
                "L1CrossDomainMessengerStorageAddress": next(
                    target.storage_address
                    for target in TARGETS
                    if target.name == "L1CrossDomainMessenger"
                ),
                "L1CrossDomainMessengerSlot": MESSENGER_ADDRESS_MANAGER_SLOT,
            },
        }
        path = args.out_dir / f"upgrade-{release}.json"
        path.write_text(json.dumps(fixture, indent=2) + "\n")
        manifest["upgrades"][release] = {
            "hash": tx_hash,
            "block": fixture["block"],
            "fixture": str(path),
        }
    (args.out_dir / "upgrade-manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n"
    )


if __name__ == "__main__":
    main()
