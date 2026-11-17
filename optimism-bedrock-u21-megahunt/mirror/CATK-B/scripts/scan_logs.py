#!/usr/bin/env python3
"""Passive, chunked L1 log census for CATK-B.

All ranges are at most 10,000 blocks and all requests go through the local
read-only failover proxy. The checkpoint file makes interrupted scans
resumable without issuing state-changing RPC methods.
"""

from __future__ import annotations

import concurrent.futures
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path


RPC = "http://127.0.0.1:7545"
END_BLOCK = 26_433_900
STEP = 10_000
OUT_DIR = Path(
    "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/mirror/CATK-B/evidence"
)

CHAINS = {
    "op": {
        "start": 17_365_802,
        "portal": "0xbEb5Fc579115071764c7423A4f12eDde41f106Ed",
        "l1cdm": "0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1",
    },
    "ink": {
        "start": 21_344_310,
        "portal": "0x5d66C1782664115999C47c9fA5cd031f495D3e4F",
        "l1cdm": "0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f",
    },
    "soneium": {
        "start": 21_314_185,
        "portal": "0x88e529A6ccd302c948689Cd5156C83D4614FAE92",
        "l1cdm": "0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f",
    },
    "unichain": {
        "start": 21_116_371,
        "portal": "0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2",
        "l1cdm": "0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6",
    },
}

QUERIES = {
    "withdrawal_finalized": {
        "addresses": [v["portal"] for v in CHAINS.values()],
        "topic0": "0xdb5c7652857aa163daadd670e116628fb42e869d8ac4251ef8971d9e5727df1b",
    },
    "failed_relayed_message": {
        "addresses": [v["l1cdm"] for v in CHAINS.values()],
        "topic0": "0x99d0e048484baa1b1540b1367cb128acd7ab2946d1ed91ec10e3c85e4bf51b8f",
    },
}


def rpc(method: str, params: list, request_id: int) -> object:
    payload = json.dumps(
        {"jsonrpc": "2.0", "id": request_id, "method": method, "params": params}
    ).encode()
    req = urllib.request.Request(
        RPC, data=payload, headers={"Content-Type": "application/json"}
    )
    last_error: Exception | None = None
    for attempt in range(7):
        try:
            with urllib.request.urlopen(req, timeout=90) as response:
                body = json.load(response)
            if "error" in body:
                raise RuntimeError(json.dumps(body["error"], sort_keys=True))
            return body["result"]
        except (urllib.error.URLError, TimeoutError, RuntimeError) as exc:
            last_error = exc
            time.sleep(min(0.25 * (2**attempt), 8.0))
    raise RuntimeError(f"RPC failed after retries: {last_error}")


def write_checkpoint(path: Path, state: dict) -> None:
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(state, indent=2, sort_keys=True) + "\n")
    os.replace(tmp, path)


def scan(name: str) -> None:
    if name not in QUERIES:
        raise SystemExit(f"unknown query {name!r}; choose one of {sorted(QUERIES)}")
    query = QUERIES[name]
    start = min(v["start"] for v in CHAINS.values())
    ranges = [
        (lo, min(lo + STEP - 1, END_BLOCK))
        for lo in range(start, END_BLOCK + 1, STEP)
    ]
    path = OUT_DIR / f"{name}-raw.json"
    if path.exists():
        state = json.loads(path.read_text())
    else:
        state = {
            "meta": {
                "rpc": RPC,
                "start": start,
                "end": END_BLOCK,
                "max_blocks_per_request": STEP,
                "addresses": query["addresses"],
                "topic0": query["topic0"],
                "chain_birth_blocks": {k: v["start"] for k, v in CHAINS.items()},
            },
            "completed_ranges": [],
            "logs": [],
            "errors": [],
        }
    done = {tuple(x) for x in state["completed_ranges"]}
    pending = [r for r in ranges if r not in done]

    def fetch(block_range: tuple[int, int]) -> tuple[tuple[int, int], list]:
        lo, hi = block_range
        params = [
            {
                "fromBlock": hex(lo),
                "toBlock": hex(hi),
                "address": query["addresses"],
                "topics": [query["topic0"]],
            }
        ]
        return block_range, rpc("eth_getLogs", params, lo)

    processed = 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        futures = {pool.submit(fetch, r): r for r in pending}
        for future in concurrent.futures.as_completed(futures):
            block_range = futures[future]
            try:
                completed, logs = future.result()
                state["completed_ranges"].append(list(completed))
                state["logs"].extend(logs)
            except Exception as exc:  # checkpoint exact failed range for deterministic rerun
                state["errors"].append(
                    {"range": list(block_range), "error": str(exc)}
                )
            processed += 1
            if processed % 25 == 0:
                write_checkpoint(path, state)
                print(
                    f"{name}: {processed}/{len(pending)} new ranges, "
                    f"{len(state['logs'])} logs, {len(state['errors'])} errors",
                    flush=True,
                )
    state["completed_ranges"].sort()
    state["logs"].sort(
        key=lambda x: (
            int(x["blockNumber"], 16),
            int(x["transactionIndex"], 16),
            int(x["logIndex"], 16),
        )
    )
    write_checkpoint(path, state)
    print(
        f"complete {name}: {len(state['completed_ranges'])}/{len(ranges)} ranges, "
        f"{len(state['logs'])} logs, {len(state['errors'])} errors"
    )


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit(f"usage: {sys.argv[0]} <{'|'.join(QUERIES)}>")
    scan(sys.argv[1])
