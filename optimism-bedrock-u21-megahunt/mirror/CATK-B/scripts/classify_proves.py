#!/usr/bin/env python3
"""Decode PASS-A prove inputs into withdrawal and relay targets for composition triage."""

import json
import pathlib

SOURCE = pathlib.Path("/home/user/Tracking_Body/optimism-u21-novel-hunt/test/poc/lane04/proves.json")
OUTPUT = pathlib.Path(__file__).resolve().parents[1] / "evidence" / "prove-target-census.json"
L1_CDM = "0x25ace71c97b33cc4729cf772ae268934f7ab5fa1"
RELAY = "d764ad0b"


def word(blob, offset):
    return int.from_bytes(blob[offset:offset + 32], "big")


def address(blob, offset):
    return "0x" + blob[offset + 12:offset + 32].hex()


def dynamic_bytes(blob, base, relative_offset):
    start = base + relative_offset
    size = word(blob, start)
    return blob[start + 32:start + 32 + size]


def decode_relay(data):
    if len(data) < 4 + 6 * 32 or data[:4].hex() != RELAY:
        return None
    args = data[4:]
    message = dynamic_bytes(args, 0, word(args, 5 * 32))
    return {
        "nonce_hex": hex(word(args, 0)),
        "sender": address(args, 32),
        "target": address(args, 64),
        "value_wei": word(args, 96),
        "min_gas_limit": word(args, 128),
        "message_selector": "0x" + message[:4].hex() if len(message) >= 4 else "0x",
        "message": "0x" + message.hex(),
    }


def main():
    source = json.loads(SOURCE.read_text())
    rows = []
    for item in source["txs"]:
        calldata = bytes.fromhex(item["input"][2:])
        args = calldata[4:]
        base = word(args, 0)
        nonce = word(args, base)
        sender = address(args, base + 32)
        target = address(args, base + 64)
        value = word(args, base + 96)
        gas_limit = word(args, base + 128)
        data = dynamic_bytes(args, base, word(args, base + 160))
        rows.append({
            "prove_tx": item["hash"],
            "block": int(item["blockNumber"], 16) if isinstance(item["blockNumber"], str) else item["blockNumber"],
            "withdrawal_hash": item["wdHash"],
            "withdrawal": {
                "nonce_hex": hex(nonce),
                "sender": sender,
                "target": target,
                "value_wei": value,
                "gas_limit": gas_limit,
                "data_selector": "0x" + data[:4].hex() if len(data) >= 4 else "0x",
            },
            "relay": decode_relay(data) if target == L1_CDM else None,
        })
    OUTPUT.write_text(json.dumps({
        "meta": {"source": str(SOURCE), "count": len(rows)},
        "withdrawals": rows,
    }, indent=2) + "\n")
    summary = {}
    for row in rows:
        relay = row["relay"]
        key = (relay or {}).get("target", row["withdrawal"]["target"])
        selector = (relay or {}).get("message_selector", row["withdrawal"]["data_selector"])
        summary[(key, selector)] = summary.get((key, selector), 0) + 1
    print(json.dumps([
        {"target": key[0], "selector": key[1], "count": count}
        for key, count in sorted(summary.items())
    ], indent=2))


if __name__ == "__main__":
    main()
