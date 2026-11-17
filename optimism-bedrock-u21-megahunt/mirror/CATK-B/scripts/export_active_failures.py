#!/usr/bin/env python3
"""Export compact replay vectors for currently unsuccessful zero-value messages."""

import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "evidence" / "failure-census-enriched.json"
OUTPUT = ROOT / "evidence" / "active-zero-value-replays.json"


def main():
    census = json.loads(SOURCE.read_text())
    messages = []
    for row in census["failed_messages"]:
        relay = row["relay"]
        state = row["mapping_at_pinned_block"]
        if relay["value_wei"] != 0 or state["successful"]:
            continue
        messages.append({
            "chain": row["chain"],
            "messenger": row["messenger"],
            "message_hash": row["message_hash"],
            "first_failure_block": min(event["block"] for event in row["events"]),
            "nonce": relay["nonce"],
            "sender": relay["sender"],
            "target": relay["target"],
            "value": relay["value_wei"],
            "min_gas_limit": relay["min_gas_limit"],
            "message": relay["message"],
            "message_selector": relay["message_selector"],
        })
    messages.sort(key=lambda item: (item["first_failure_block"], item["message_hash"]))
    OUTPUT.write_text(json.dumps({
        "meta": {
            "source": str(SOURCE),
            "count": len(messages),
            "selection": "failed=true, successful=false, relay value=0 at block 26433900",
        },
        "messages": messages,
    }, indent=2) + "\n")
    print(json.dumps({
        "count": len(messages),
        "by_chain": {chain: sum(1 for item in messages if item["chain"] == chain) for chain in sorted({m["chain"] for m in messages})},
        "by_selector": {
            selector: sum(1 for item in messages if item["message_selector"] == selector)
            for selector in sorted({m["message_selector"] for m in messages})
        },
    }, indent=2))


if __name__ == "__main__":
    main()
