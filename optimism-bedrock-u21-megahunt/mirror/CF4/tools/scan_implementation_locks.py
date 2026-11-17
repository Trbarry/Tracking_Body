#!/usr/bin/env python3
"""Read initializer-lock state of every implementation observed in OP Mainnet history."""

from __future__ import annotations

import json
import urllib.request
import concurrent.futures
from collections import defaultdict
from pathlib import Path


RPC = "http://127.0.0.1:7545"
CUTOFF = 26_433_900
ROOT = Path(__file__).resolve().parents[1]
HISTORY = ROOT / "evidence/op-mainnet-storage-history.json"
OUT = ROOT / "evidence/implementation-initializer-locks.json"
OZ_V5_INITIALIZABLE_SLOT = "0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00"
ZERO = "0x0000000000000000000000000000000000000000"


def rpc(method: str, params: list):
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    request = urllib.request.Request(RPC, data=payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=90) as response:
        decoded = json.load(response)
    if "error" in decoded:
        raise RuntimeError(decoded["error"])
    return decoded["result"]


def decode_string(raw: str) -> str | None:
    try:
        data = bytes.fromhex(raw[2:])
        offset = int.from_bytes(data[:32], "big")
        length = int.from_bytes(data[offset:offset + 32], "big")
        return data[offset + 32:offset + 32 + length].decode()
    except Exception:
        return None


def eth_call(address: str, data: str) -> str | None:
    try:
        return rpc("eth_call", [{"to": address, "data": data}, hex(CUTOFF)])
    except RuntimeError:
        return None


def main() -> None:
    history = json.loads(HISTORY.read_text())
    uses: dict[str, set[str]] = defaultdict(set)

    def add(family: str, address: str | None) -> None:
        if address and address.lower() != ZERO:
            uses[address.lower()].add(family)

    for family, transitions in history["persistent_implementation_transitions"].items():
        for transition in transitions:
            add(family, transition.get("before"))
            add(family, transition.get("after"))
            for address in transition.get("event_sequence", transition.get("event_new_old", [])):
                if isinstance(address, str):
                    add(family, address)
    for family, transitions in history["transient_same_block_event_sequences"].items():
        for transition in transitions:
            add(family, transition.get("before"))
            add(family, transition.get("after"))
            for address in transition.get("event_sequence", []):
                add(family, address)

    def inspect(item: tuple[str, set[str]]) -> dict:
        address, families = item
        word0 = rpc("eth_getStorageAt", [address, "0x0", hex(CUTOFF)])
        oz_v5 = rpc("eth_getStorageAt", [address, OZ_V5_INITIALIZABLE_SLOT, hex(CUTOFF)])
        code = rpc("eth_getCode", [address, hex(CUTOFF)])
        balance = rpc("eth_getBalance", [address, hex(CUTOFF)])
        value = int(word0, 16)
        relevant_offsets = sorted({20 if family == "L1CrossDomainMessenger" else 0 for family in families})
        bytes_at_offsets = {str(offset): (value >> (offset * 8)) & 0xff for offset in relevant_offsets}
        raw_version = eth_call(address, "0x54fd4d50")  # version()
        raw_init_version = eth_call(address, "0x38d38c97")  # initVersion()
        return {
            "address": address,
            "families": sorted(families),
            "code_bytes": (len(code) - 2) // 2,
            "balance_wei": int(balance, 16),
            "slot_0": word0,
            "initializer_bytes": bytes_at_offsets,
            "all_relevant_legacy_initializer_bytes_locked_255": all(v == 255 for v in bytes_at_offsets.values()),
            "oz_v5_initializable_slot": oz_v5,
            "version": decode_string(raw_version) if raw_version else None,
            "initVersion_raw": raw_init_version,
        }

    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        records = list(pool.map(inspect, sorted(uses.items())))

    OUT.write_text(json.dumps({
        "rpc": RPC,
        "block": CUTOFF,
        "method": "Historical implementation addresses from independently reconstructed proxy transitions; direct implementation storage reads.",
        "records": records,
        "summary": {
            "unique_implementations": len(records),
            "locked_legacy_byte_255": sum(r["all_relevant_legacy_initializer_bytes_locked_255"] for r in records),
            "not_locked_by_relevant_legacy_byte": sum(not r["all_relevant_legacy_initializer_bytes_locked_255"] for r in records),
            "nonzero_oz_v5_slot": sum(int(r["oz_v5_initializable_slot"], 16) != 0 for r in records),
            "nonzero_balance": sum(r["balance_wei"] != 0 for r in records),
        },
    }, indent=2) + "\n")
    print(f"wrote {OUT} ({len(records)} implementations)")


if __name__ == "__main__":
    main()
