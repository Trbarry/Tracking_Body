#!/usr/bin/env python3
"""Read-only allowance census for every in-scope L1 execution surface.

The scan covers the four chains' current portal, messenger, standard bridge and
ETH lockbox proxies, plus every historical OptimismPortal implementation found
by the engagement's independent implementation-history census.  Only passive
JSON-RPC methods are used against :7545 and every state read is pinned.
"""

import json
import urllib.request
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path("/home/user/Tracking_Body/optimism-bedrock-u21-megahunt")
RPC_URL = "http://127.0.0.1:7545"
PIN = 26_433_900
CHAINS = ("OP", "INK", "SONEIUM", "UNICHAIN")
ROLES = ("OptimismPortal", "L1CrossDomainMessenger", "L1StandardBridge", "ETHLockbox")
APPROVAL = "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925"
APPROVAL_FOR_ALL = "0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31"
OUT = ROOT / "mirror/CATK-CMP2/evidence/executor-allowance-census.json"


class Rpc:
    def __init__(self):
        self.ident = 0
        self.calls = Counter()

    def call(self, method, params):
        self.ident += 1
        self.calls[method] += 1
        payload = {"jsonrpc": "2.0", "id": self.ident, "method": method, "params": params}
        req = urllib.request.Request(
            RPC_URL,
            json.dumps(payload).encode(),
            {"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=180) as response:
            obj = json.load(response)
        if "error" in obj:
            raise RuntimeError(obj["error"])
        return obj["result"]

    def batch(self, requests, batch_size=100):
        output = []
        for cursor in range(0, len(requests), batch_size):
            chunk = requests[cursor : cursor + batch_size]
            body = []
            ids = []
            for method, params in chunk:
                self.ident += 1
                self.calls[method] += 1
                ids.append(self.ident)
                body.append({"jsonrpc": "2.0", "id": self.ident, "method": method, "params": params})
            req = urllib.request.Request(
                RPC_URL,
                json.dumps(body).encode(),
                {"Content-Type": "application/json"},
            )
            with urllib.request.urlopen(req, timeout=180) as response:
                objects = json.load(response)
            by_id = {obj["id"]: obj for obj in objects}
            for ident in ids:
                obj = by_id[ident]
                output.append({"result": obj.get("result"), "error": obj.get("error")})
        return output


def padded(address):
    return "0x" + address.lower().removeprefix("0x").rjust(64, "0")


def address_from_topic(topic):
    return "0x" + topic[-40:].lower()


def collect_spenders():
    metadata = defaultdict(list)
    for chain in CHAINS:
        deployment = json.loads((ROOT / f"chains/{chain}/DEPLOYMENT.json").read_text())
        for role in ROLES:
            address = deployment["proxies"][role]["address"].lower()
            metadata[address].append({"chain": chain, "role": role, "kind": "proxy"})

        history_name = "op-mainnet" if chain == "OP" else chain.lower()
        history_path = ROOT / f"evidence/F2-impl-history-{history_name}.json"
        history = json.loads(history_path.read_text())
        target = next(item for item in history["targets"] if item["name"] == "OptimismPortal")
        for item in target["history"]:
            address = item["implementation"].lower()
            if address == "0x" + "0" * 40:
                continue
            metadata[address].append(
                {
                    "chain": chain,
                    "role": "OptimismPortal",
                    "kind": "historical-implementation",
                    "first_seen_block": item["block"],
                    "version": item.get("version"),
                }
            )
    return dict(sorted(metadata.items()))


def get_logs(rpc, topic0, spender_topics, low, high):
    query = {
        "fromBlock": hex(low),
        "toBlock": hex(high),
        "topics": [topic0, None, spender_topics],
    }
    try:
        rows = rpc.call("eth_getLogs", [query])
        if len(rows) >= 19_999 and low < high:
            raise RuntimeError("possible provider result cap")
        return rows
    except Exception:
        if low == high:
            raise
        middle = (low + high) // 2
        return get_logs(rpc, topic0, spender_topics, low, middle) + get_logs(
            rpc, topic0, spender_topics, middle + 1, high
        )


def scan_logs(rpc, topic0, spender_topics):
    rows = []
    cursor = 0
    while cursor <= PIN:
        end = min(cursor + 499_999, PIN)
        part = get_logs(rpc, topic0, spender_topics, cursor, end)
        rows.extend(part)
        print(f"{topic0[:10]} blocks {cursor}-{end}: +{len(part)} total={len(rows)}", flush=True)
        cursor = end + 1
    unique = {(row["transactionHash"].lower(), int(row["logIndex"], 16)): row for row in rows}
    return list(unique.values())


def uint_call(token, selector, first, second=None):
    data = selector + first.lower().removeprefix("0x").rjust(64, "0")
    if second is not None:
        data += second.lower().removeprefix("0x").rjust(64, "0")
    return ("eth_call", [{"to": token, "data": data}, hex(PIN)])


def decode_uint(response):
    raw = response.get("result")
    if response.get("error") or not isinstance(raw, str) or len(raw) < 66:
        return None
    try:
        return int(raw, 16)
    except ValueError:
        return None


def main():
    rpc = Rpc()
    metadata = collect_spenders()
    spender_topics = [padded(address) for address in metadata]
    erc20_logs = scan_logs(rpc, APPROVAL, spender_topics)
    operator_logs = scan_logs(rpc, APPROVAL_FOR_ALL, spender_topics)

    approvals = sorted(
        {
            (row["address"].lower(), address_from_topic(row["topics"][1]), address_from_topic(row["topics"][2]))
            for row in erc20_logs
        }
    )
    operators = sorted(
        {
            (row["address"].lower(), address_from_topic(row["topics"][1]), address_from_topic(row["topics"][2]))
            for row in operator_logs
        }
    )

    approval_requests = []
    for token, owner, spender in approvals:
        approval_requests.append(uint_call(token, "0xdd62ed3e", owner, spender))
        approval_requests.append(uint_call(token, "0x70a08231", owner))
    approval_responses = rpc.batch(approval_requests)
    active_approvals = []
    failed_approval_reads = 0
    for index, (token, owner, spender) in enumerate(approvals):
        allowance = decode_uint(approval_responses[index * 2])
        balance = decode_uint(approval_responses[index * 2 + 1])
        if allowance is None:
            failed_approval_reads += 1
        if allowance:
            active_approvals.append(
                {
                    "token": token,
                    "owner": owner,
                    "spender": spender,
                    "allowance": str(allowance),
                    "owner_balance": None if balance is None else str(balance),
                    "spender_roles": metadata[spender],
                }
            )

    operator_requests = [uint_call(token, "0xe985e9c5", owner, spender) for token, owner, spender in operators]
    operator_responses = rpc.batch(operator_requests)
    active_operators = []
    failed_operator_reads = 0
    for response, (token, owner, spender) in zip(operator_responses, operators):
        approved = decode_uint(response)
        if approved is None:
            failed_operator_reads += 1
        if approved:
            active_operators.append(
                {
                    "token": token,
                    "owner": owner,
                    "operator": spender,
                    "spender_roles": metadata[spender],
                }
            )

    codes = rpc.batch([("eth_getCode", [address, hex(PIN)]) for address in metadata])
    code_bytes = {}
    for address, response in zip(metadata, codes):
        code = response.get("result") or "0x"
        code_bytes[address] = max(0, (len(code) - 2) // 2)

    event_counts = Counter()
    for row in erc20_logs:
        event_counts[(address_from_topic(row["topics"][2]), "Approval")] += 1
    for row in operator_logs:
        event_counts[(address_from_topic(row["topics"][2]), "ApprovalForAll")] += 1

    spenders = []
    for address, roles in metadata.items():
        spenders.append(
            {
                "address": address,
                "code_bytes_at_pin": code_bytes[address],
                "roles": roles,
                "approval_events": event_counts[(address, "Approval")],
                "approval_for_all_events": event_counts[(address, "ApprovalForAll")],
                "active_erc20_allowances": sum(item["spender"] == address for item in active_approvals),
                "active_operator_approvals": sum(item["operator"] == address for item in active_operators),
            }
        )

    result = {
        "method": {
            "safety": "read-only eth_getLogs/eth_call/eth_getCode only; passive :7545 proxy; explicit pinned block",
            "rpc": RPC_URL,
            "pin": PIN,
            "scope": "four current portal/messenger/standard-bridge/lockbox proxies plus all historical portal implementations",
            "rpc_calls": dict(rpc.calls),
        },
        "summary": {
            "distinct_spenders": len(metadata),
            "approval_events": len(erc20_logs),
            "approval_for_all_events": len(operator_logs),
            "distinct_erc20_approval_tuples": len(approvals),
            "distinct_operator_tuples": len(operators),
            "active_erc20_allowances": len(active_approvals),
            "active_operator_approvals": len(active_operators),
            "failed_erc20_state_reads": failed_approval_reads,
            "failed_operator_state_reads": failed_operator_reads,
        },
        "spenders": spenders,
        "active_erc20_allowances": active_approvals,
        "active_operator_approvals": active_operators,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(json.dumps(result["summary"], indent=2, sort_keys=True))
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
