#!/usr/bin/env python3
"""Read-only OP MessagePassed builder census at the engagement's pinned L2 block.

The script uses only eth_getLogs, eth_getCode, and eth_getTransactionByHash against
the passive :7546 proxy. It never invokes a state-changing RPC method.
"""

import json
import urllib.request
from collections import Counter, defaultdict
from pathlib import Path


RPC_URL = "http://127.0.0.1:7546"
START = 105_235_063
PIN = 159_654_093
PASSER = "0x4200000000000000000000000000000000000016"
MESSENGER = "0x4200000000000000000000000000000000000007"
L1_MESSENGER = "0x25ace71c97b33cc4729cf772ae268934f7ab5fa1"
TOPIC = "0x02a52367d10742d8032712c1bb8e0144ff1ec5ffda1ed7d70bb05a2744955054"
OUT = Path("/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/mirror/CATK-CMP2/evidence/builder-census.json")


class Rpc:
    def __init__(self):
        self.ident = 0
        self.calls = Counter()

    def call(self, method, params):
        self.ident += 1
        self.calls[method] += 1
        body = json.dumps({"jsonrpc": "2.0", "id": self.ident, "method": method, "params": params}).encode()
        req = urllib.request.Request(RPC_URL, body, {"Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=180) as response:
            obj = json.load(response)
        if "error" in obj:
            raise RuntimeError(obj["error"])
        return obj["result"]

    def batch(self, method, params):
        if not params:
            return []
        requests = []
        ids = []
        for item in params:
            self.ident += 1
            self.calls[method] += 1
            ids.append(self.ident)
            requests.append({"jsonrpc": "2.0", "id": self.ident, "method": method, "params": item})
        req = urllib.request.Request(RPC_URL, json.dumps(requests).encode(), {"Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=180) as response:
            objects = json.load(response)
        by_id = {obj["id"]: obj for obj in objects}
        result = []
        for ident in ids:
            obj = by_id[ident]
            if "error" in obj:
                raise RuntimeError(obj["error"])
            result.append(obj["result"])
        return result


def logs(rpc, low, high):
    params = {"fromBlock": hex(low), "toBlock": hex(high), "address": PASSER, "topics": [TOPIC]}
    try:
        rows = rpc.call("eth_getLogs", [params])
        if len(rows) >= 19_999 and low < high:
            raise RuntimeError("possible provider cap")
        return rows
    except Exception:
        if low == high:
            raise
        middle = (low + high) // 2
        return logs(rpc, low, middle) + logs(rpc, middle + 1, high)


def decode(log):
    raw = log["data"][2:]
    offset = int(raw[128:192], 16) * 2
    length = int(raw[offset : offset + 64], 16) * 2
    payload = raw[offset + 64 : offset + 64 + length]
    return {
        "block": int(log["blockNumber"], 16),
        "tx": log["transactionHash"].lower(),
        "sender": "0x" + log["topics"][2][-40:].lower(),
        "target": "0x" + log["topics"][3][-40:].lower(),
        "gas": int(raw[64:128], 16),
        "bytes": len(payload) // 2,
        "payload": payload,
    }


def relay(item):
    raw = item["payload"]
    if not raw.startswith("d764ad0b") or len(raw) < 8 + 384:
        return None
    args = raw[8:]
    offset = int(args[320:384], 16) * 2
    length = int(args[offset : offset + 64], 16) * 2
    message = args[offset + 64 : offset + 64 + length]
    return {
        "block": item["block"],
        "tx": item["tx"],
        "sender": "0x" + args[64:128][-40:].lower(),
        "target": "0x" + args[128:192][-40:].lower(),
        "min_gas": int(args[256:320], 16),
        "message_bytes": len(message) // 2,
        "selector": "0x" + message[:8] if len(message) >= 8 else "0x",
    }


def summarize(rows, code_by_sender, tx_by_hash, gas_key, bytes_key):
    grouped = defaultdict(list)
    for row in rows:
        grouped[row["sender"]].append(row)
    result = []
    for sender, items in grouped.items():
        code = code_by_sender[sender]
        if code == "0x":
            continue
        representatives = {}
        for item in items:
            tx = tx_by_hash.get(item["tx"])
            if tx is None:
                continue
            selector = tx.get("input", "0x")[:10]
            key = (tx.get("to") or "create").lower() + ":" + selector
            representatives.setdefault(key, {"tx_to": tx.get("to"), "tx_selector": selector, "tx": item["tx"]})
        result.append(
            {
                "sender": sender,
                "current_code_bytes": (len(code) - 2) // 2,
                "events": len(items),
                "max_gas": max(item[gas_key] for item in items),
                "max_payload_bytes": max(item[bytes_key] for item in items),
                "targets": dict(Counter(item["target"] for item in items).most_common()),
                "message_selectors": dict(Counter(item.get("selector", "direct") for item in items).most_common()),
                "representative_entrypoints": list(representatives.values())[:12],
            }
        )
    return sorted(result, key=lambda item: (-item["events"], item["sender"]))


def main():
    rpc = Rpc()
    raw = []
    cursor = START
    while cursor <= PIN:
        end = min(cursor + 1_999_999, PIN)
        raw.extend(logs(rpc, cursor, end))
        print(f"blocks {cursor}-{end}: total={len(raw)}", flush=True)
        cursor = end + 1
    messages = [decode(item) for item in raw]
    direct = [item for item in messages if item["target"] != L1_MESSENGER]
    canonical = [item for item in messages if item["target"] == L1_MESSENGER and item["sender"] == MESSENGER]
    inner = [parsed for item in canonical if (parsed := relay(item)) is not None]

    senders = sorted({item["sender"] for item in direct + inner})
    codes = rpc.batch("eth_getCode", [[sender, hex(PIN)] for sender in senders])
    code_by_sender = dict(zip(senders, codes))

    # Fetch only representative transactions: first, maximum-gas and maximum-payload per sender.
    selected = set()
    for population, gas_key, bytes_key in ((direct, "gas", "bytes"), (inner, "min_gas", "message_bytes")):
        grouped = defaultdict(list)
        for item in population:
            grouped[item["sender"]].append(item)
        for sender, items in grouped.items():
            if code_by_sender[sender] == "0x":
                continue
            selected.add(items[0]["tx"])
            selected.add(max(items, key=lambda item: item[gas_key])["tx"])
            selected.add(max(items, key=lambda item: item[bytes_key])["tx"])
    tx_hashes = sorted(selected)
    txs = rpc.batch("eth_getTransactionByHash", [[tx_hash] for tx_hash in tx_hashes])
    tx_by_hash = dict(zip(tx_hashes, txs))

    direct_contracts = summarize(direct, code_by_sender, tx_by_hash, "gas", "bytes")
    inner_contracts = summarize(inner, code_by_sender, tx_by_hash, "min_gas", "message_bytes")
    result = {
        "method": {
            "safety": "read-only RPC methods only; passive :7546 proxy; explicit pinned block",
            "rpc": RPC_URL,
            "range": [START, PIN],
            "rpc_calls": dict(rpc.calls),
        },
        "population": {
            "message_passed": len(messages),
            "canonical_relay_messages": len(inner),
            "direct_messages": len(direct),
            "distinct_inner_senders": len({item["sender"] for item in inner}),
            "current_contract_inner_senders": len(inner_contracts),
            "current_contract_inner_events": sum(item["events"] for item in inner_contracts),
            "distinct_direct_senders": len({item["sender"] for item in direct}),
            "current_contract_direct_senders": len(direct_contracts),
            "max_inner_min_gas": max(item["min_gas"] for item in inner),
            "max_inner_message_bytes": max(item["message_bytes"] for item in inner),
            "max_direct_gas": max(item["gas"] for item in direct),
            "max_direct_payload_bytes": max(item["bytes"] for item in direct),
        },
        "inner_contract_senders": inner_contracts,
        "direct_contract_senders": direct_contracts,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(json.dumps(result["population"], indent=2, sort_keys=True))
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
