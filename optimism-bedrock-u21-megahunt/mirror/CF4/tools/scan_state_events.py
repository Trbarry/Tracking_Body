#!/usr/bin/env python3
"""Full-range, chunked event census for mapping archaeology.

Retains exact boundary samples and counts rather than every high-volume log.
All eth_getLogs ranges are <=10,000 blocks.
"""

from __future__ import annotations

import concurrent.futures
import json
import time
import urllib.request
from collections import defaultdict
from pathlib import Path


RPC = "http://127.0.0.1:7545"
START, END, STEP = 12_600_000, 26_433_900, 10_000
BEDROCK = 17_422_590
FAULT_PROOFS = 20_062_696
BASE = Path(__file__).resolve().parents[1]
OUT = BASE / "evidence/state-event-census.json"

ADDRESSES = {
    "OptimismPortal": "0xbeb5fc579115071764c7423a4f12edde41f106ed",
    "L1CrossDomainMessenger": "0x25ace71c97b33cc4729cf772ae268934f7ab5fa1",
    "L1StandardBridge": "0x99c9fc46f92e8a1c0dec1b1747d010903e884be1",
    "AnchorStateRegistry.gen0": "0x18dac71c228d1c32c99489b7323d441e1175e443",
    "AnchorStateRegistry.gen1": "0x1c68ecfbf9c8b1e6c0677965b3b9ecf9a104305b",
    "AnchorStateRegistry.current": "0x23b2c62946350f4246f9f9d027e071f0264fd113",
}

TOPICS = {
    "WithdrawalProven": "0x67a6208cfcc0801d50f6cbe764733f4fddf66ac0b04442061a8a8c0cb6b63f62",
    "WithdrawalProvenExtension1": "0x798f9f13695f8f045aa5f80ed8efebb695f3c7fe65da381969f2f28bf3c60b97",
    "WithdrawalFinalized": "0xdb5c7652857aa163daadd670e116628fb42e869d8ac4251ef8971d9e5727df1b",
    "WithdrawalProofDeleted": "0xc52e609801931c8dcad3132b8a92414d2199941e6e09c85b117df31b6bda682a",
    "DisputeGameBlacklisted": "0x192c289026d59a41a27f5aea08f3969b57931b0589202d14f4368cded95d3cda",
    "PortalRespectedGameTypeSet": "0x049fe9dd413cdf037cce27011cc1790c753118272f3630e6e8bdfa5e82081760",
    "ASRRespectedGameTypeSet": "0xcee0703b5e4bad4efededab85c9fd1aec17dee7c5f6c584330e0509b677745a2",
    "SentMessage": "0xcb0f7ffd78f9aee47a248fae8db181db6eee833039123e026dcbff529522e52a",
    "SentMessageExtension1": "0x8ebb2ec2465bdb2a06a66fc37a0963af8a2a6a1479d81d56fdb8cbb98096d546",
    "RelayedMessage": "0x4641df4a962071e12719d8c8c8e5ac7fc4d97b927346a3d7a335b1f7517e133c",
    "FailedRelayedMessage": "0x99d0e048484baa1b1540b1367cb128acd7ab2946d1ed91ec10e3c85e4bf51b8f",
    "ERC20DepositInitiated": "0x718594027abd4eaed59f95162563e0cc6d0e8d5b86b1c7be8b1b0ac3343d0396",
    "ERC20WithdrawalFinalized": "0x3ceee06c1e37648fcbb6ed52e17b3e1f275a1f8c7b22a84b2b84732431e046b3",
    "ERC20BridgeInitiated": "0x7ff126db8024424bbfd9826e8ab82ff59136289ea440b04b39a0df1b03b9cabf",
    "ERC20BridgeFinalized": "0xd59c65b35445225835c83f50b6ede06a7be047d22e357073e250d9af537518cd",
}


def rpc_logs(lo: int, hi: int):
    payload = json.dumps({
        "jsonrpc": "2.0", "id": lo, "method": "eth_getLogs", "params": [{
            "fromBlock": hex(lo), "toBlock": hex(hi),
            "address": list(ADDRESSES.values()), "topics": [list(TOPICS.values())],
        }],
    }).encode()
    for attempt in range(5):
        try:
            req = urllib.request.Request(RPC, data=payload, headers={"Content-Type": "application/json"})
            with urllib.request.urlopen(req, timeout=90) as response:
                decoded = json.load(response)
            if "error" in decoded:
                raise RuntimeError(decoded["error"])
            return decoded["result"]
        except Exception:
            if attempt == 4:
                raise
            time.sleep(0.5 * (attempt + 1))


def key(log: dict):
    return int(log["blockNumber"], 16), int(log["logIndex"], 16)


def capped(items: list[dict], log: dict, n: int, take_last: bool) -> list[dict]:
    items.append(log)
    items.sort(key=key)
    return items[-n:] if take_last else items[:n]


def main() -> None:
    chunks = [(lo, min(lo + STEP - 1, END)) for lo in range(START, END + 1, STEP)]
    reverse_address = {value: name for name, value in ADDRESSES.items()}
    reverse_topic = {value: name for name, value in TOPICS.items()}
    state = defaultdict(lambda: {
        "count": 0, "first": [], "last": [],
        "pre_bedrock_last": [], "post_bedrock_first": [],
        "pre_fault_proofs_last": [], "post_fault_proofs_first": [],
    })
    completed = 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        futures = [pool.submit(rpc_logs, lo, hi) for lo, hi in chunks]
        for future in concurrent.futures.as_completed(futures):
            for log in future.result():
                address_name = reverse_address[log["address"].lower()]
                topic_name = reverse_topic[log["topics"][0].lower()]
                bucket = state[f"{address_name}:{topic_name}"]
                bucket["count"] += 1
                bucket["first"] = capped(bucket["first"], log, 10, False)
                bucket["last"] = capped(bucket["last"], log, 10, True)
                block = int(log["blockNumber"], 16)
                if block < BEDROCK:
                    bucket["pre_bedrock_last"] = capped(bucket["pre_bedrock_last"], log, 20, True)
                else:
                    bucket["post_bedrock_first"] = capped(bucket["post_bedrock_first"], log, 20, False)
                if block < FAULT_PROOFS:
                    bucket["pre_fault_proofs_last"] = capped(bucket["pre_fault_proofs_last"], log, 20, True)
                else:
                    bucket["post_fault_proofs_first"] = capped(bucket["post_fault_proofs_first"], log, 20, False)
            completed += 1
            if completed % 100 == 0:
                print(f"completed {completed}/{len(chunks)} chunks", flush=True)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps({
        "rpc": RPC,
        "coverage": {"from_block": START, "to_block": END, "chunk_size": STEP, "complete": True},
        "cutoffs": {"bedrock": BEDROCK, "fault_proofs": FAULT_PROOFS},
        "addresses": ADDRESSES,
        "topics": TOPICS,
        "buckets": state,
    }, indent=2) + "\n")
    print(f"wrote {OUT} with {sum(v['count'] for v in state.values())} matched logs", flush=True)


if __name__ == "__main__":
    main()
