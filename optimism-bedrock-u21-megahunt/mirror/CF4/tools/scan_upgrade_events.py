#!/usr/bin/env python3
"""Chunked, read-only L1 log scan for implementation-change events.

The archive proxy enforces a 10,000-block maximum, so every query is exactly
within that limit. This script never issues a state-changing RPC method.
"""

from __future__ import annotations

import concurrent.futures
import json
import time
import urllib.request
from pathlib import Path


RPC = "http://127.0.0.1:7545"
START = 12_600_000
END = 26_433_900
STEP = 10_000
UPGRADED = "0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b"
ADDRESS_SET = "0x9416a153a346f93d95f94b064ae3f148b6460473c6e82b3f9fc2521b873fcd6c"

PROXIES = {
    "OptimismPortal": "0xbeb5fc579115071764c7423a4f12edde41f106ed",
    "L2OutputOracle": "0xdfe97868233d1aa22e815a266982f2cf17685a27",
    "SystemConfig": "0x229047fed2591dbec1ef1118d64f7af3db9eb290",
    "L1StandardBridge": "0x99c9fc46f92e8a1c0dec1b1747d010903e884be1",
    "L1ERC721Bridge": "0x5a7749f83b81b301cab5f48eb8516b986daef23d",
    "OptimismMintableERC20Factory": "0x75505a97bd334e7bd3c476893285569c4136fa0f",
    "SuperchainConfig": "0x95703e0982140d16f8eba6d158fccede42f04a4c",
    "ProtocolVersions": "0x8062abc286f5e7d9428a0ccb9abd71e50d93b935",
    "DisputeGameFactory": "0xe5965ab5962edc7477c8520243a95517cd252fa9",
    "AnchorStateRegistry.gen0": "0x18dac71c228d1c32c99489b7323d441e1175e443",
    "AnchorStateRegistry.gen1": "0x1c68ecfbf9c8b1e6c0677965b3b9ecf9a104305b",
    "AnchorStateRegistry.current": "0x23b2c62946350f4246f9f9d027e071f0264fd113",
    "DelayedWETH.gen0": "0xe497b094d6dbb3d5e4caac9a14696d7572588d14",
    "DelayedWETH.gen1": "0x323dfc63c9b83cb83f40325aab74b245937cbdf0",
    "DelayedWETH.current": "0x1b6dbf05eaf22d4e70dc993e8a19dd9f3dcb3162",
    "ETHLockbox": "0x322b47ff1fa8d5611f761e3e275c45b71b294d43",
}

ADDRESS_MANAGER = "0xde1fcfb0851916ca5101820a69b13a4e276bd81f"
OUT = Path(__file__).resolve().parents[1] / "evidence/proxy-upgrade-events.json"


def rpc(method: str, params: list, request_id: int, retries: int = 5):
    payload = json.dumps({"jsonrpc": "2.0", "id": request_id, "method": method, "params": params}).encode()
    for attempt in range(retries):
        try:
            request = urllib.request.Request(RPC, data=payload, headers={"Content-Type": "application/json"})
            with urllib.request.urlopen(request, timeout=90) as response:
                decoded = json.load(response)
            if "error" in decoded:
                raise RuntimeError(decoded["error"])
            return decoded["result"]
        except Exception:
            if attempt + 1 == retries:
                raise
            time.sleep(0.5 * (attempt + 1))


def get_logs(task: tuple[int, int, str]) -> tuple[str, int, list]:
    lo, hi, kind = task
    if kind == "upgraded":
        filt = {
            "fromBlock": hex(lo), "toBlock": hex(hi),
            "address": list(PROXIES.values()), "topics": [UPGRADED],
        }
    else:
        filt = {
            "fromBlock": hex(lo), "toBlock": hex(hi),
            "address": ADDRESS_MANAGER, "topics": [ADDRESS_SET],
        }
    return kind, lo, rpc("eth_getLogs", [filt], lo + (0 if kind == "upgraded" else 100_000_000))


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    chunks = [(lo, min(lo + STEP - 1, END)) for lo in range(START, END + 1, STEP)]
    tasks = [(lo, hi, kind) for lo, hi in chunks for kind in ("upgraded", "address_set")]
    results = {"upgraded": [], "address_set": []}
    completed = 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        futures = [pool.submit(get_logs, task) for task in tasks]
        for future in concurrent.futures.as_completed(futures):
            kind, _, logs = future.result()
            results[kind].extend(logs)
            completed += 1
            if completed % 100 == 0:
                print(f"completed {completed}/{len(tasks)} chunks", flush=True)
    reverse = {address: name for name, address in PROXIES.items()}
    for log in results["upgraded"]:
        log["contract"] = reverse.get(log["address"].lower(), "UNKNOWN")
    for kind in results:
        results[kind].sort(key=lambda item: (int(item["blockNumber"], 16), int(item["logIndex"], 16)))
    document = {
        "rpc": RPC,
        "range": [START, END],
        "chunk_size": STEP,
        "addresses": PROXIES,
        "address_manager": ADDRESS_MANAGER,
        **results,
    }
    OUT.write_text(json.dumps(document, indent=2) + "\n")
    print(f"wrote {OUT}: {len(results['upgraded'])} Upgraded, {len(results['address_set'])} AddressSet")


if __name__ == "__main__":
    main()
