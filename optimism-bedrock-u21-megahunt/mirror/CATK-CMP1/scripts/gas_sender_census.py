#!/usr/bin/env python3
"""Read-only, pinned census of OP withdrawals and committed relay gas metadata."""

import json
import urllib.request
from collections import Counter, defaultdict
from pathlib import Path

RPC_URL = "http://127.0.0.1:7546"
START = 105_235_063
PIN = 159_654_093
MESSAGE_PASSER = "0x4200000000000000000000000000000000000016"
L2_MESSENGER = "0x4200000000000000000000000000000000000007"
L1_MESSENGER = "0x25ace71c97b33cc4729cf772ae268934f7ab5fa1"
TOPIC = "0x02a52367d10742d8032712c1bb8e0144ff1ec5ffda1ed7d70bb05a2744955054"
OUT = Path("/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/mirror/CATK-CMP1/evidence/gas-sender-census.json")


class RPC:
    def __init__(self):
        self.ident = 0
        self.calls = 0

    def call(self, method, params):
        self.ident += 1
        self.calls += 1
        body = json.dumps({"jsonrpc": "2.0", "id": self.ident, "method": method, "params": params}).encode()
        request = urllib.request.Request(RPC_URL, body, {"Content-Type": "application/json"})
        with urllib.request.urlopen(request, timeout=120) as response:
            result = json.load(response)
        if "error" in result:
            raise RuntimeError(result["error"])
        return result["result"]

    def batch(self, method, params_list):
        body = []
        ids = []
        for params in params_list:
            self.ident += 1
            self.calls += 1
            ids.append(self.ident)
            body.append({"jsonrpc": "2.0", "id": self.ident, "method": method, "params": params})
        request = urllib.request.Request(RPC_URL, json.dumps(body).encode(), {"Content-Type": "application/json"})
        with urllib.request.urlopen(request, timeout=120) as response:
            results = json.load(response)
        by_id = {item["id"]: item for item in results}
        return [by_id[ident]["result"] for ident in ids]


def get_logs(rpc, start, end):
    params = {
        "fromBlock": hex(start),
        "toBlock": hex(end),
        "address": MESSAGE_PASSER,
        "topics": [TOPIC],
    }
    try:
        rows = rpc.call("eth_getLogs", [params])
        if len(rows) >= 19_999 and start < end:
            raise RuntimeError("possible provider truncation")
        return rows
    except Exception:
        if start == end:
            raise
        midpoint = (start + end) // 2
        return get_logs(rpc, start, midpoint) + get_logs(rpc, midpoint + 1, end)


def decode_outer(log):
    raw = log["data"][2:]
    offset = int(raw[128:192], 16) * 2
    length = int(raw[offset:offset + 64], 16) * 2
    payload = raw[offset + 64:offset + 64 + length]
    return {
        "block": int(log["blockNumber"], 16),
        "transaction_hash": log["transactionHash"].lower(),
        "sender": "0x" + log["topics"][2][-40:].lower(),
        "target": "0x" + log["topics"][3][-40:].lower(),
        "value": int(raw[:64], 16),
        "gas_limit": int(raw[64:128], 16),
        "withdrawal_hash": "0x" + raw[192:256].lower(),
        "payload": payload,
    }


def decode_relay(payload):
    if not payload.startswith("d764ad0b"):
        return None
    args = payload[8:]
    offset = int(args[320:384], 16) * 2
    length = int(args[offset:offset + 64], 16) * 2
    message = args[offset + 64:offset + 64 + length]
    return {
        "nonce": int(args[:64], 16),
        "sender": "0x" + args[64:128][-40:].lower(),
        "target": "0x" + args[128:192][-40:].lower(),
        "value": int(args[192:256], 16),
        "min_gas_limit": int(args[256:320], 16),
        "message_bytes": len(message) // 2,
        "selector": "0x" + message[:8] if len(message) >= 8 else "0x",
    }


def compact(item):
    return {
        "block": item["block"],
        "transaction_hash": item["transaction_hash"],
        "withdrawal_hash": item["withdrawal_hash"],
        "outer_sender": item["sender"],
        "outer_gas_limit": item["gas_limit"],
        **item["relay"],
    }


def main():
    rpc = RPC()
    logs = []
    step = 2_000_000
    for start in range(START, PIN + 1, step):
        end = min(start + step - 1, PIN)
        chunk = get_logs(rpc, start, end)
        logs.extend(chunk)
        print(f"{start}-{end}: {len(chunk)}; cumulative {len(logs)}", flush=True)

    outer = [decode_outer(log) for log in logs]
    canonical = [item for item in outer if item["target"] == L1_MESSENGER]
    parse_failures = 0
    records = []
    for item in canonical:
        relay = decode_relay(item["payload"])
        if relay is None:
            parse_failures += 1
            continue
        item["relay"] = relay
        records.append(item)

    senders = sorted({item["relay"]["sender"] for item in records})
    codes = rpc.batch("eth_getCode", [[sender, hex(PIN)] for sender in senders])
    code_bytes = {sender: (len(code) - 2) // 2 for sender, code in zip(senders, codes)}
    sender_rows = []
    grouped = defaultdict(list)
    for item in records:
        grouped[item["relay"]["sender"]].append(item)
    for sender, items in grouped.items():
        max_gas = max(row["relay"]["min_gas_limit"] for row in items)
        max_bytes = max(row["relay"]["message_bytes"] for row in items)
        sender_rows.append({
            "sender": sender,
            "code_bytes_at_pin": code_bytes[sender],
            "message_count": len(items),
            "max_min_gas_limit": max_gas,
            "max_message_bytes": max_bytes,
            "targets": dict(Counter(row["relay"]["target"] for row in items).most_common()),
        })
    sender_rows.sort(key=lambda row: (-row["max_min_gas_limit"], -row["max_message_bytes"], row["sender"]))

    by_gas = sorted(records, key=lambda row: (-row["relay"]["min_gas_limit"], row["block"]))
    by_size = sorted(records, key=lambda row: (-row["relay"]["message_bytes"], row["block"]))
    high_gas_all = [row for row in by_gas if row["relay"]["min_gas_limit"] >= 1_000_000]
    high_gas_groups = Counter(
        (
            row["relay"]["sender"],
            row["relay"]["target"],
            row["relay"]["min_gas_limit"],
            row["relay"]["selector"],
        )
        for row in high_gas_all
    )
    result = {
        "method": {
            "safety": "read-only eth_getLogs and eth_getCode at explicit OP L2 pin",
            "rpc": RPC_URL,
            "range_inclusive": [START, PIN],
            "message_passer": MESSAGE_PASSER,
            "rpc_calls": rpc.calls,
        },
        "totals": {
            "message_passed": len(outer),
            "canonical_l1_messenger": len(canonical),
            "canonical_outer_l2_messenger": sum(item["sender"] == L2_MESSENGER for item in canonical),
            "relay_decode_failures": parse_failures,
            "distinct_inner_senders": len(senders),
            "contract_inner_senders_at_pin": sum(size > 0 for size in code_bytes.values()),
            "distinct_inner_targets": len({item["relay"]["target"] for item in records}),
        },
        "maxima": {
            "min_gas_limit": compact(by_gas[0]),
            "message_bytes": compact(by_size[0]),
            "outer_gas_limit": compact(max(records, key=lambda row: row["gas_limit"])),
        },
        "high_gas_at_least_1m_count": len(high_gas_all),
        "high_gas_at_least_1m_groups": [
            {
                "sender": key[0],
                "target": key[1],
                "min_gas_limit": key[2],
                "selector": key[3],
                "count": count,
            }
            for key, count in high_gas_groups.most_common()
        ],
        "highest_gas_100_rows": [compact(row) for row in high_gas_all[:100]],
        "inner_senders": sender_rows,
    }
    OUT.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(f"wrote {OUT}", flush=True)


if __name__ == "__main__":
    main()
