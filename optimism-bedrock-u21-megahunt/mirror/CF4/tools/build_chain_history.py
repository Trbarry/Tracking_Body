#!/usr/bin/env python3
"""Build block-state implementation and raw-slot history for OP Mainnet L1 contracts.

Read-only RPC methods only. Implementation-changing event blocks are independently
verified from storage at block-1/block. The ChugSplash bridge, which emits no
Upgraded event, is discovered by 10k sampling followed by binary search.
"""

from __future__ import annotations

import json
import urllib.request
import concurrent.futures
from collections import defaultdict
from pathlib import Path


BASE = Path(__file__).resolve().parents[1]
EVENTS = json.loads((BASE / "evidence/proxy-upgrade-events.json").read_text())
LINEAGE = json.loads((BASE / "storage-lineage.json").read_text())
OUT = BASE / "evidence/op-mainnet-storage-history.json"
RPC = "http://127.0.0.1:7545"
END = 26_433_900
IMPL_SLOT = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
ADMIN_SLOT = "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103"
OZV5_INIT_SLOT = "0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00"
L1CDM_NAME_TOPIC = "0x3b4a6791a6879d27c0ceeea3f78f8ebe66a01905f4a1290a8c6aff3e85f4665a"
L1CDM_ADDRESS_MANAGER_SLOT = "0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e"
RESOLVED_NAME_SLOT = "0x453da090ce3606b5b38b21d12b645cde48a017a5b14a6e51116f2991c345cf3f"
RESOLVED_MANAGER_SLOT = "0x0ae0ec7fe2be5ad9ff4a2be6686fdb9afb8ff3e683e9a82ede75059805059d5d"

PROXIES = EVENTS["addresses"]
ADDRESS_MANAGER = EVENTS["address_manager"]
L1CDM = "0x25ace71c97b33cc4729cf772ae268934f7ab5fa1"
PROXY_ADMIN = "0x543ba4aadbab8f9025686bd03993043599c6fb04"
BRIDGE = PROXIES["L1StandardBridge"]

EXTRAS = {
    "SystemConfig": list(range(101, 111)),
    "L1CrossDomainMessenger": [101, 151, 201, 202, 203, 204, 205, 206, 207, 208, 249, 250, 251, 252, 253, 254],
    "DisputeGameFactory": list(range(101, 106)),
    "AnchorStateRegistry": list(range(101, 105)),
    "DelayedWETH": list(range(101, 105)),
}


def rpc(method: str, params: list, request_id: int = 1):
    payload = json.dumps({"jsonrpc": "2.0", "id": request_id, "method": method, "params": params}).encode()
    req = urllib.request.Request(RPC, data=payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=90) as response:
        decoded = json.load(response)
    if "error" in decoded:
        raise RuntimeError(decoded["error"])
    return decoded["result"]


def rpc_batch(calls: list[tuple[str, list]]) -> list:
    if len(calls) > 25:
        out = []
        for start in range(0, len(calls), 25):
            out.extend(rpc_batch(calls[start:start + 25]))
        return out
    payload = [
        {"jsonrpc": "2.0", "id": i, "method": method, "params": params}
        for i, (method, params) in enumerate(calls)
    ]
    req = urllib.request.Request(
        RPC, data=json.dumps(payload).encode(), headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req, timeout=180) as response:
        decoded = json.load(response)
    by_id = {item["id"]: item for item in decoded}
    results = []
    for i in range(len(calls)):
        item = by_id[i]
        if "error" in item:
            raise RuntimeError(item["error"])
        results.append(item["result"])
    return results


def storage(address: str, slot: int | str, block: int) -> str:
    slot_arg = hex(slot) if isinstance(slot, int) else slot
    return rpc("eth_getStorageAt", [address, slot_arg, hex(block)])


def code(address: str, block: int) -> str:
    return rpc("eth_getCode", [address, hex(block)])


def creation_block(address: str) -> int:
    lo, hi = 0, END
    if code(address, hi) == "0x":
        return -1
    while lo < hi:
        mid = (lo + hi) // 2
        if code(address, mid) == "0x":
            lo = mid + 1
        else:
            hi = mid
    return lo


def decode_address(word: str) -> str:
    return "0x" + word[-40:]


def decode_version(raw: str) -> str | None:
    try:
        data = bytes.fromhex(raw.removeprefix("0x"))
        if len(data) < 64:
            return None
        offset = int.from_bytes(data[:32], "big")
        length = int.from_bytes(data[offset:offset + 32], "big")
        return data[offset + 32:offset + 32 + length].decode(errors="replace")
    except Exception:
        return None


def version_at(address: str, block: int) -> str | None:
    try:
        raw = rpc("eth_call", [{"to": address, "data": "0x54fd4d50"}, hex(block)])
        return decode_version(raw)
    except Exception:
        return None


def initializer_bytes(slot0: str) -> dict:
    value = int(slot0, 16)
    return {"offset_0": value & 0xFF, "offset_20": (value >> 160) & 0xFF}


def slot_numbers(name: str) -> list[int]:
    family = name.split(".")[0]
    if family.startswith("AnchorStateRegistry"):
        family = "AnchorStateRegistry"
    if family.startswith("DelayedWETH"):
        family = "DelayedWETH"
    return sorted(set(range(80)) | set(EXTRAS.get(family, [])))


def dump_slots(address: str, name: str, block: int) -> dict:
    numbered = slot_numbers(name)
    special_keys = [IMPL_SLOT, ADMIN_SLOT, OZV5_INIT_SLOT]
    keys = ["0x" + slot.to_bytes(32, "big").hex() for slot in numbered] + special_keys
    try:
        proof = rpc("eth_getProof", [address, keys, hex(block)])
        values = {int(item["key"], 16): "0x" + int(item["value"], 16).to_bytes(32, "big").hex()
                  for item in proof["storageProof"]}
        proof_method = "eth_getProof"
    except RuntimeError as error:
        # Some failover backends expose archive storage but cap historical
        # Merkle proofs. Storage reads remain available at the same block.
        calls = [("eth_getStorageAt", [address, key, hex(block)]) for key in keys]
        raw_values = rpc_batch(calls)
        values = {int(key, 16): value for key, value in zip(keys, raw_values)}
        proof_method = f"eth_getStorageAt fallback ({error})"
    all_slots = {str(slot): values[slot] for slot in numbered}
    specials = {
        "eip1967.implementation": values[int(IMPL_SLOT, 16)],
        "eip1967.admin": values[int(ADMIN_SLOT, 16)],
        "openzeppelin.v5.initializable": values[int(OZV5_INIT_SLOT, 16)],
    }
    return {
        "block": block,
        "slots": all_slots,
        "nonzero_slots": {key: value for key, value in all_slots.items() if int(value, 16) != 0},
        "special_slots": specials,
        "initializer_bytes": initializer_bytes(all_slots["0"]),
        "version": version_at(address, block),
        "read_method": proof_method,
    }


def grouped_event_transitions() -> tuple[dict[str, list[dict]], dict[str, list[dict]]]:
    grouped: dict[str, dict[int, list[dict]]] = defaultdict(lambda: defaultdict(list))
    for log in EVENTS["upgraded"]:
        grouped[log["contract"]][int(log["blockNumber"], 16)].append(log)
    persistent: dict[str, list[dict]] = defaultdict(list)
    transient: dict[str, list[dict]] = defaultdict(list)
    for name, blocks in grouped.items():
        address = PROXIES[name]
        for block, logs in sorted(blocks.items()):
            before = storage(address, IMPL_SLOT, max(block - 1, 0))
            after = storage(address, IMPL_SLOT, block)
            sequence = [decode_address(log["topics"][1]) for log in logs]
            item = {
                "block": block,
                "transactions": list(dict.fromkeys(log["transactionHash"] for log in logs)),
                "event_sequence": sequence,
                "before": decode_address(before),
                "after": decode_address(after),
            }
            if before != after:
                persistent[name].append(item)
            else:
                transient[name].append(item)
    return persistent, transient


def binary_first_change(address: str, old_value: str, lo: int, hi: int) -> int:
    # Preconditions: value(lo) == old_value and value(hi) != old_value.
    while lo + 1 < hi:
        mid = (lo + hi) // 2
        if storage(address, IMPL_SLOT, mid) == old_value:
            lo = mid
        else:
            hi = mid
    return hi


def discover_chugsplash() -> list[dict]:
    start = creation_block(BRIDGE)
    # Include every observed system upgrade block as a boundary, plus coarse
    # checkpoints. Each changed interval is then resolved by binary search.
    event_blocks = {int(log["blockNumber"], 16) for log in EVENTS["upgraded"]}
    points = sorted({start, END, *range(start, END + 1, 250_000), *event_blocks})
    calls = [("eth_getStorageAt", [BRIDGE, IMPL_SLOT, hex(block)]) for block in points]
    values = rpc_batch(calls)
    transitions = []
    last_block, last_value = points[0], values[0]
    for high_block, high_value in zip(points[1:], values[1:]):
        cursor_block, cursor_value = last_block, last_value
        while cursor_value != high_value:
            changed = binary_first_change(BRIDGE, cursor_value, cursor_block, high_block)
            next_value = storage(BRIDGE, IMPL_SLOT, changed)
            transitions.append({
                "block": changed,
                "before": decode_address(cursor_value),
                "after": decode_address(next_value),
                "method": f"system-event/coarse sampling plus binary search in ({cursor_block},{high_block}]",
            })
            cursor_block, cursor_value = changed, next_value
        last_block, last_value = high_block, high_value
    # Deduplicate boundaries that appear in adjacent point intervals.
    unique = {(item["block"], item["before"], item["after"]): item for item in transitions}
    return sorted(unique.values(), key=lambda item: item["block"])


def resolved_transitions() -> list[dict]:
    logs = [log for log in EVENTS["address_set"] if log["topics"][1].lower() == L1CDM_NAME_TOPIC]
    grouped: dict[int, list[dict]] = defaultdict(list)
    for log in logs:
        grouped[int(log["blockNumber"], 16)].append(log)
    out = []
    for block, items in sorted(grouped.items()):
        before = storage(ADDRESS_MANAGER, L1CDM_ADDRESS_MANAGER_SLOT, max(block - 1, 0))
        after = storage(ADDRESS_MANAGER, L1CDM_ADDRESS_MANAGER_SLOT, block)
        out.append({
            "block": block,
            "transactions": list(dict.fromkeys(item["transactionHash"] for item in items)),
            "event_new_old": [
                {
                    "new": "0x" + item["data"][26:66],
                    "old": "0x" + item["data"][90:130],
                }
                for item in items
            ],
            "before": decode_address(before),
            "after": decode_address(after),
        })
    return [item for item in out if item["before"] != item["after"]]


def main() -> None:
    creation_targets = {
        **PROXIES,
        "L1CrossDomainMessenger": L1CDM,
        "AddressManager": ADDRESS_MANAGER,
        "ProxyAdmin": PROXY_ADMIN,
    }
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        futures = {pool.submit(creation_block, address): name for name, address in creation_targets.items()}
        creations = {futures[future]: future.result() for future in concurrent.futures.as_completed(futures)}
    print("creation blocks resolved", flush=True)

    persistent, transient = grouped_event_transitions()
    persistent["L1StandardBridge"] = discover_chugsplash()
    persistent["L1CrossDomainMessenger"] = resolved_transitions()
    print("implementation transitions resolved", flush=True)

    snapshots = defaultdict(list)
    for name, transitions in persistent.items():
        address = L1CDM if name == "L1CrossDomainMessenger" else PROXIES[name]
        for item in transitions:
            block = item["block"]
            snapshots[name].append({
                "transition": item,
                "before": dump_slots(address, name, max(block - 1, 0)),
                "after": dump_slots(address, name, block),
            })
            print(f"dumped {name} @ {block}", flush=True)

    direct = {
        "AddressManager": dump_slots(ADDRESS_MANAGER, "AddressManager", END),
        "ProxyAdmin": dump_slots(PROXY_ADMIN, "ProxyAdmin", END),
        "ResolvedDelegateProxy.special": {
            "block": END,
            "implementationName[address(this)]": storage(L1CDM, RESOLVED_NAME_SLOT, END),
            "addressManager[address(this)]": storage(L1CDM, RESOLVED_MANAGER_SLOT, END),
            "resolved_implementation_address_manager_entry": storage(
                ADDRESS_MANAGER, L1CDM_ADDRESS_MANAGER_SLOT, END
            ),
        },
    }
    document = {
        "rpc": RPC,
        "block_cutoff": END,
        "method": (
            "Upgraded/AddressSet logs scanned in <=10k chunks; every persistent event transition "
            "verified at block-1/block. L1StandardBridge discovered via slot samples and binary search."
        ),
        "creation_blocks": creations,
        "persistent_implementation_transitions": persistent,
        "transient_same_block_event_sequences": transient,
        "pre_post_slot_dumps": snapshots,
        "direct_and_special": direct,
    }
    OUT.write_text(json.dumps(document, indent=2) + "\n")
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
