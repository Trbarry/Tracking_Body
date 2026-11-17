#!/usr/bin/env python3
"""Passive L1 log scan that rules out a suspected Karst deposit gas-cap trigger.

The direct v1.7.0 tree already exempts deposits from the EIP-7825 cap. This scan is retained as
negative evidence for the two live third-party old-prestate games, not as evidence of a version
delta.
"""

import json
import sys
import urllib.request


RPC = "http://127.0.0.1:7545"
DEPOSIT_TOPIC = "0xb3813568d9991fc951961fcb4c784893574240a28925604d09fc577c55bb7c32"
EIP_7825_CAP = 1 << 24
START_SLACK_SECONDS = 86_400
LOG_CHUNK = 2_000

CASES = {
    "ink-game-2638": {
        "portal": "0x5d66C1782664115999C47c9fA5cd031f495D3e4F",
        "game": "0x40bec00713a38ee5fd697764d50f0055ba4942cc",
        "anchor_timestamp": 1_794_244_697,
        "claim_timestamp": 1_794_857_590,
        "l1_head_block": 26_429_706,
    },
    "unichain-game-17586": {
        "portal": "0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2",
        "game": "0xa41214c2851f0d538b7c6b37fa66e35472ff6f0e",
        "anchor_timestamp": 1_793_923_307,
        "claim_timestamp": 1_794_531_731,
        "l1_head_block": 26_402_621,
    },
}


def rpc(method, params):
    request = urllib.request.Request(
        RPC,
        data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        reply = json.load(response)
    if "error" in reply:
        raise RuntimeError(f"{method}: {reply['error']}")
    return reply["result"]


def block_timestamp(number):
    block = rpc("eth_getBlockByNumber", [hex(number), False])
    return int(block["timestamp"], 16)


def first_block_at_or_after(timestamp, high):
    low = 0
    while low < high:
        middle = (low + high) // 2
        if block_timestamp(middle) < timestamp:
            low = middle + 1
        else:
            high = middle
    return low


def decode_opaque_data(log_data):
    encoded = bytes.fromhex(log_data[2:])
    offset = int.from_bytes(encoded[0:32], "big")
    length = int.from_bytes(encoded[offset:offset + 32], "big")
    payload = encoded[offset + 32:offset + 32 + length]
    if len(payload) < 73:
        raise ValueError(f"short opaqueData payload: {len(payload)}")
    return {
        "mint": int.from_bytes(payload[0:32], "big"),
        "value": int.from_bytes(payload[32:64], "big"),
        "gas_limit": int.from_bytes(payload[64:72], "big"),
        "is_creation": bool(payload[72]),
        "calldata_bytes": len(payload) - 73,
    }


def main():
    evidence = {
        "rpc_mode": "passive eth_getLogs/eth_getBlockByNumber only",
        "eip_7825_transaction_gas_limit_cap": EIP_7825_CAP,
        "start_slack_seconds": START_SLACK_SECONDS,
        "cases": {},
    }
    for name, case in CASES.items():
        start_timestamp = case["anchor_timestamp"] - START_SLACK_SECONDS
        start_block = first_block_at_or_after(start_timestamp, case["l1_head_block"])
        deposits = []
        for first in range(start_block, case["l1_head_block"] + 1, LOG_CHUNK):
            last = min(first + LOG_CHUNK - 1, case["l1_head_block"])
            logs = rpc("eth_getLogs", [{
                "fromBlock": hex(first),
                "toBlock": hex(last),
                "address": case["portal"],
                "topics": [DEPOSIT_TOPIC],
            }])
            for log in logs:
                decoded = decode_opaque_data(log["data"])
                deposits.append({
                    "l1_block": int(log["blockNumber"], 16),
                    "l1_block_timestamp": int(log.get("blockTimestamp", "0x0"), 16),
                    "transaction_hash": log["transactionHash"],
                    "log_index": int(log["logIndex"], 16),
                    "from": "0x" + log["topics"][1][-40:],
                    "to": "0x" + log["topics"][2][-40:],
                    **decoded,
                })
        deposits.sort(key=lambda item: (item["l1_block"], item["log_index"]))
        over_cap = [item for item in deposits if item["gas_limit"] > EIP_7825_CAP]
        evidence["cases"][name] = {
            **case,
            "scan_start_timestamp": start_timestamp,
            "scan_start_block": start_block,
            "scan_end_block": case["l1_head_block"],
            "deposit_count": len(deposits),
            "maximum_gas_limit": max((item["gas_limit"] for item in deposits), default=None),
            "over_cap_count": len(over_cap),
            "over_cap_deposits": over_cap,
            "top_five_gas_limits": sorted(
                deposits, key=lambda item: item["gas_limit"], reverse=True
            )[:5],
        }
    json.dump(evidence, sys.stdout, indent=2, sort_keys=True)
    print()


if __name__ == "__main__":
    main()
