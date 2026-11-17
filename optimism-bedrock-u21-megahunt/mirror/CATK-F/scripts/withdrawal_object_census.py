#!/usr/bin/env python3
"""Pinned, read-only census for CATK-F unsafe withdrawal targets.

Only eth_getLogs/eth_getBlockByNumber/eth_getCode are used. The two local
archive proxies are read at explicit block numbers; no state-changing RPC is
issued.
"""

import glob
import json
import re
import sys
import urllib.request
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path("/home/user/Tracking_Body/optimism-bedrock-u21-megahunt")
OUT = ROOT / "mirror/CATK-F/evidence/withdrawal-object-census.json"
L1_EVENTS = ROOT / "evidence/F4/op-portal-withdrawal-events.jsonl"
L1_RPC = "http://127.0.0.1:7545"
L2_RPC = "http://127.0.0.1:7546"
L1_PIN = 26_433_900
L2_START = 105_235_063
L2_PIN = 159_654_093
MESSAGE_PASSER = "0x4200000000000000000000000000000000000016"
L2_MESSENGER = "0x4200000000000000000000000000000000000007"
OP_L1_MESSENGER = "0x25ace71c97b33cc4729cf772ae268934f7ab5fa1"
MESSAGE_PASSED_TOPIC = "0x02a52367d10742d8032712c1bb8e0144ff1ec5ffda1ed7d70bb05a2744955054"
ADDRESS_RE = re.compile(r"0x[0-9a-fA-F]{40}")


class RPC:
    def __init__(self, url):
        self.url = url
        self.ident = 0
        self.calls = 0
        self.block_cache = {}

    def call(self, method, params):
        self.ident += 1
        self.calls += 1
        payload = json.dumps({"jsonrpc": "2.0", "id": self.ident, "method": method, "params": params}).encode()
        req = urllib.request.Request(self.url, payload, {"Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=120) as response:
            obj = json.load(response)
        if "error" in obj:
            raise RuntimeError(f"{method}: {obj['error']}")
        return obj["result"]

    def block(self, number):
        if number not in self.block_cache:
            self.block_cache[number] = self.call("eth_getBlockByNumber", [hex(number), False])
        return self.block_cache[number]


def addresses_in(path):
    try:
        return {m.group(0).lower() for m in ADDRESS_RE.finditer(path.read_text(errors="replace"))}
    except FileNotFoundError:
        return set()


def inventory():
    curated_sources = []
    broad_sources = [ROOT / "SCOPE.md"]
    for chain in ("OP", "INK", "SONEIUM", "UNICHAIN"):
        curated_sources.append(ROOT / f"chains/{chain}/DEPLOYMENT.json")
        broad_sources.extend(
            [
                ROOT / f"chains/{chain}/HISTORY.md",
                ROOT / f"chains/{chain}/STATE-U21.json",
            ]
        )
    curated_sources.extend(Path(p) for p in glob.glob(str(ROOT / "evidence/F2-impl-history-*.json")))
    curated = set()
    broad = set()
    origins = defaultdict(list)
    for path in curated_sources:
        for address in addresses_in(path):
            curated.add(address)
            origins[address].append(str(path.relative_to(ROOT)))
    broad |= curated
    for path in broad_sources:
        for address in addresses_in(path):
            broad.add(address)
            origins[address].append(str(path.relative_to(ROOT)))
    broad.discard("0x0000000000000000000000000000000000000000")
    curated.discard("0x0000000000000000000000000000000000000000")
    return curated, broad, origins


def get_logs(rpc, start, end):
    params = {
        "fromBlock": hex(start),
        "toBlock": hex(end),
        "address": MESSAGE_PASSER,
        "topics": [MESSAGE_PASSED_TOPIC],
    }
    try:
        result = rpc.call("eth_getLogs", [params])
        # Defensive against providers that silently cap rather than error.
        if len(result) >= 19_999 and start < end:
            raise RuntimeError("possible silent result cap")
        return result
    except Exception:
        if start == end:
            raise
        middle = (start + end) // 2
        return get_logs(rpc, start, middle) + get_logs(rpc, middle + 1, end)


def decode_message(log):
    raw = log["data"][2:]
    return {
        "block": int(log["blockNumber"], 16),
        "transaction_hash": log["transactionHash"].lower(),
        "log_index": int(log["logIndex"], 16),
        "nonce": int(log["topics"][1], 16),
        "sender": "0x" + log["topics"][2][-40:].lower(),
        "target": "0x" + log["topics"][3][-40:].lower(),
        "value": int(raw[0:64], 16),
        "gas_limit": int(raw[64:128], 16),
        "withdrawal_hash": "0x" + raw[192:256].lower(),
    }


def l1_event_census(broad, curated):
    proven = {}
    proof_events = 0
    proof_event_targets = Counter()
    finalized = set()
    with L1_EVENTS.open() as stream:
        for line in stream:
            row = json.loads(line)
            kind = row[3]
            topics = row[4]
            if kind == 0:
                proof_events += 1
                withdrawal_hash = topics[0].lower()
                sender = "0x" + topics[1][-40:].lower()
                target = "0x" + topics[2][-40:].lower()
                proof_event_targets[target] += 1
                proven.setdefault(
                    withdrawal_hash,
                    {
                        "sender": sender,
                        "target": target,
                        "first_proof_block": row[0],
                        "proof_events": 0,
                    },
                )["proof_events"] += 1
            elif kind == 2:
                finalized.add(topics[0].lower())
    unfinalized = {h: item for h, item in proven.items() if h not in finalized}
    noncanonical = [
        {
            "withdrawal_hash": h,
            **item,
            "finalized": h in finalized,
            "curated_system_match": item["target"] in curated,
            "broad_system_match": item["target"] in broad,
        }
        for h, item in proven.items()
        if item["target"] != OP_L1_MESSENGER
    ]
    return {
        "proof_events": proof_events,
        "distinct_proven": len(proven),
        "distinct_finalized": len(finalized),
        "distinct_proven_never_finalized": len(unfinalized),
        "canonical_messenger_proof_events": proof_event_targets[OP_L1_MESSENGER],
        "noncanonical_proof_events": proof_events - proof_event_targets[OP_L1_MESSENGER],
        "noncanonical_distinct": len(noncanonical),
        "noncanonical_curated_system_matches": sum(1 for item in noncanonical if item["curated_system_match"]),
        "noncanonical_broad_system_matches": sum(1 for item in noncanonical if item["broad_system_match"]),
        "unfinalized_by_target": dict(Counter(item["target"] for item in unfinalized.values()).most_common()),
        "noncanonical_withdrawals": sorted(noncanonical, key=lambda item: (item["first_proof_block"], item["withdrawal_hash"])),
        "_proven": proven,
        "_finalized": finalized,
    }


def l1_block_at_or_after(rpc, timestamp):
    low = 0
    high = L1_PIN
    while low < high:
        middle = (low + high) // 2
        block = rpc.block(middle)
        if block is None or int(block["timestamp"], 16) < timestamp:
            low = middle + 1
        else:
            high = middle
    return low


def code_chronology(l1, l2, direct):
    first_by_target = {}
    for item in direct:
        first_by_target.setdefault(item["target"], item)
        if item["block"] < first_by_target[item["target"]]["block"]:
            first_by_target[item["target"]] = item
    rows = []
    for index, (target, item) in enumerate(sorted(first_by_target.items()), 1):
        l2_block = l2.block(item["block"])
        timestamp = int(l2_block["timestamp"], 16)
        l1_block = l1_block_at_or_after(l1, timestamp)
        then_code = l1.call("eth_getCode", [target, hex(l1_block)])
        now_code = l1.call("eth_getCode", [target, hex(L1_PIN)])
        rows.append(
            {
                "target": target,
                "first_l2_message_block": item["block"],
                "first_l2_message_timestamp": timestamp,
                "corresponding_l1_block": l1_block,
                "code_bytes_then": (len(then_code) - 2) // 2,
                "code_bytes_at_pin": (len(now_code) - 2) // 2,
                "became_code_later": then_code == "0x" and now_code != "0x",
            }
        )
        if index % 20 == 0:
            print(f"code chronology {index}/{len(first_by_target)}", flush=True)
    return rows


def main():
    curated, broad, origins = inventory()
    print(f"inventory curated={len(curated)} broad={len(broad)}", flush=True)
    l1_events = l1_event_census(broad, curated)
    print(
        "L1 events "
        f"proven={l1_events['distinct_proven']} "
        f"never_finalized={l1_events['distinct_proven_never_finalized']} "
        f"noncanonical={l1_events['noncanonical_distinct']}",
        flush=True,
    )

    l1 = RPC(L1_RPC)
    l2 = RPC(L2_RPC)
    logs = []
    step = 2_000_000
    cursor = L2_START
    while cursor <= L2_PIN:
        end = min(cursor + step - 1, L2_PIN)
        chunk = get_logs(l2, cursor, end)
        logs.extend(chunk)
        print(f"L2 blocks {cursor}-{end}: {len(chunk)} logs; cumulative={len(logs)}", flush=True)
        cursor = end + 1

    messages = [decode_message(log) for log in logs]
    direct = [item for item in messages if item["target"] != OP_L1_MESSENGER]
    canonical = [item for item in messages if item["target"] == OP_L1_MESSENGER]
    canonical_wrong_sender = [item for item in canonical if item["sender"] != L2_MESSENGER]
    proven = l1_events.pop("_proven")
    finalized = l1_events.pop("_finalized")
    for item in direct:
        item["proven_on_l1"] = item["withdrawal_hash"] in proven
        item["finalized_on_l1"] = item["withdrawal_hash"] in finalized
        item["curated_system_match"] = item["target"] in curated
        item["broad_system_match"] = item["target"] in broad
        if item["broad_system_match"]:
            item["inventory_origins"] = origins[item["target"]]

    chronology = None
    if OUT.exists():
        try:
            cached = json.loads(OUT.read_text())["target_code_chronology"]["rows"]
            if {item["target"] for item in cached} == {item["target"] for item in direct}:
                chronology = cached
                print(f"reused {len(cached)} pinned target-code chronology rows", flush=True)
        except (KeyError, TypeError, json.JSONDecodeError):
            pass
    if chronology is None:
        chronology = code_chronology(l1, l2, direct)
    code_later = [item for item in chronology if item["became_code_later"]]
    result = {
        "method": {
            "safety": "read-only JSON-RPC only; explicit pinned blocks",
            "l2_rpc": L2_RPC,
            "l2_range_inclusive": [L2_START, L2_PIN],
            "l1_rpc": L1_RPC,
            "l1_pin": L1_PIN,
            "message_passer": MESSAGE_PASSER,
            "event_topic": MESSAGE_PASSED_TOPIC,
            "inventory_sources": "four chain DEPLOYMENT/STATE/HISTORY files, SCOPE, and F2 implementation histories; forbidden attack-wave and mirror outputs were not read",
            "l1_rpc_calls": l1.calls,
            "l2_rpc_calls": l2.calls,
        },
        "inventory": {
            "curated_address_count": len(curated),
            "broad_address_count": len(broad),
            "curated_addresses": sorted(curated),
            "broad_addresses": sorted(broad),
        },
        "l1_portal_events": l1_events,
        "l2_message_passed": {
            "total": len(messages),
            "canonical_l1_messenger_target": len(canonical),
            "canonical_target_wrong_sender": len(canonical_wrong_sender),
            "canonical_wrong_sender_messages": canonical_wrong_sender,
            "direct_nonmessenger": len(direct),
            "direct_distinct_targets": len({item["target"] for item in direct}),
            "direct_proven_on_l1": sum(1 for item in direct if item["proven_on_l1"]),
            "direct_finalized_on_l1": sum(1 for item in direct if item["finalized_on_l1"]),
            "direct_curated_system_matches": sum(1 for item in direct if item["curated_system_match"]),
            "direct_broad_system_matches": sum(1 for item in direct if item["broad_system_match"]),
            "direct_messages": direct,
        },
        "target_code_chronology": {
            "rows": chronology,
            "became_code_later_count": len(code_later),
            "became_code_later": code_later,
        },
    }
    OUT.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(f"wrote {OUT}", flush=True)
    print(
        "summary "
        f"total={len(messages)} direct={len(direct)} "
        f"broad_system={result['l2_message_passed']['direct_broad_system_matches']} "
        f"code_later={len(code_later)}",
        flush=True,
    )


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"fatal: {exc}", file=sys.stderr, flush=True)
        raise
