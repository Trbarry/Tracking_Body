#!/usr/bin/env python3
"""Discover OP Mainnet L1 implementation changes from read-only archive state.

The scan never submits a transaction. It samples every implementation locator at
most 10,000 blocks apart, then binary-searches every interval whose endpoint
changes. One-block log reads only enrich the resulting blocks with transaction
hashes; logs are not the discovery mechanism. This intentionally reports block-end
state: transient implementations installed and removed in one transaction are not
separate fork points.

Round trips A -> B -> A entirely inside one 10,000-block interval cannot be
detected from endpoint state alone.  The output records that limitation.  OP
upgrade transitions are also checked against upgrade logs by the Foundry suite.
"""

from __future__ import annotations

import argparse
import json
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any


EIP1967_IMPLEMENTATION = (
    "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
)
MESSENGER_ADDRESS_MANAGER_SLOT = (
    "0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e"
)
UPGRADED_TOPIC = "0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b"
ADDRESS_SET_TOPIC = "0x9416a153a346f93d95f94b064ae3f148b6460473c6e82b3f9fc2521b873fcd6c"
MESSENGER_NAME_TOPIC = "0x3b4a6791a6879d27c0ceeea3f78f8ebe66a01905f4a1290a8c6aff3e85f4665a"


@dataclass(frozen=True)
class Target:
    name: str
    proxy: str
    storage_address: str
    storage_slot: str
    proxy_kind: str


TARGETS = (
    Target(
        "OptimismPortal",
        "0xbEb5Fc579115071764c7423A4f12eDde41f106Ed",
        "0xbEb5Fc579115071764c7423A4f12eDde41f106Ed",
        EIP1967_IMPLEMENTATION,
        "EIP-1967",
    ),
    Target(
        "SystemConfig",
        "0x229047fed2591dbec1eF1118d64F7aF3dB9EB290",
        "0x229047fed2591dbec1eF1118d64F7aF3dB9EB290",
        EIP1967_IMPLEMENTATION,
        "EIP-1967",
    ),
    Target(
        "L1CrossDomainMessenger",
        "0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1",
        "0xdE1FCfB0851916CA5101820A69b13a4E276bd81F",
        MESSENGER_ADDRESS_MANAGER_SLOT,
        "ResolvedDelegateProxy / AddressManager",
    ),
    Target(
        "L1StandardBridge",
        "0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1",
        "0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1",
        EIP1967_IMPLEMENTATION,
        "L1ChugSplashProxy / EIP-1967 slot",
    ),
    Target(
        "DisputeGameFactory",
        "0xe5965Ab5962eDc7477C8520243A95517CD252fA9",
        "0xe5965Ab5962eDc7477C8520243A95517CD252fA9",
        EIP1967_IMPLEMENTATION,
        "EIP-1967",
    ),
    Target(
        "AnchorStateRegistry",
        "0x23B2C62946350F4246f9f9D027e071f0264FD113",
        "0x23B2C62946350F4246f9f9D027e071f0264FD113",
        EIP1967_IMPLEMENTATION,
        "EIP-1967",
    ),
    Target(
        "ETHLockbox",
        "0x322b47Ff1FA8D5611F761e3E275C45B71b294D43",
        "0x322b47Ff1FA8D5611F761e3E275C45B71b294D43",
        EIP1967_IMPLEMENTATION,
        "EIP-1967",
    ),
)


class Rpc:
    def __init__(self, url: str) -> None:
        self.url = url
        self.next_id = 1

    def _post(self, payload: Any) -> Any:
        raw = json.dumps(payload).encode()
        request = urllib.request.Request(
            self.url, raw, {"Content-Type": "application/json"}, method="POST"
        )
        last: Exception | None = None
        for attempt in range(8):
            try:
                with urllib.request.urlopen(request, timeout=120) as response:
                    return json.load(response)
            except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
                last = exc
                time.sleep(min(8, 2**attempt))
        raise RuntimeError(f"RPC failed after retries: {last}")

    def call(self, method: str, params: list[Any]) -> Any:
        request_id = self.next_id
        self.next_id += 1
        response = self._post(
            {"jsonrpc": "2.0", "id": request_id, "method": method, "params": params}
        )
        if "error" in response:
            raise RuntimeError(f"{method}: {response['error']}")
        return response["result"]

    def batch(self, calls: list[tuple[str, list[Any]]], chunk: int = 100) -> list[Any]:
        results: list[Any] = []
        for offset in range(0, len(calls), chunk):
            part = calls[offset : offset + chunk]
            payload = []
            ids = []
            for method, params in part:
                request_id = self.next_id
                self.next_id += 1
                ids.append(request_id)
                payload.append(
                    {"jsonrpc": "2.0", "id": request_id, "method": method, "params": params}
                )
            response = self._post(payload)
            by_id = {entry["id"]: entry for entry in response}
            for request_id in ids:
                entry = by_id[request_id]
                if "error" in entry:
                    raise RuntimeError(f"batch RPC: {entry['error']}")
                results.append(entry["result"])
        return results


def block_tag(block: int) -> str:
    return hex(block)


def normalized_address(word: str) -> str:
    return "0x" + word[-40:].lower()


def find_deployments(rpc: Rpc, targets: tuple[Target, ...], head: int) -> dict[str, int]:
    """Binary-search all proxy deployments in parallel JSON-RPC batches."""

    head_codes = rpc.batch(
        [("eth_getCode", [target.proxy, block_tag(head)]) for target in targets]
    )
    for target, code in zip(targets, head_codes):
        if code == "0x":
            raise RuntimeError(f"no code at head: {target.proxy}")

    bounds = {target.name: [0, head] for target in targets}
    while any(low < high for low, high in bounds.values()):
        active = [target for target in targets if bounds[target.name][0] < bounds[target.name][1]]
        calls: list[tuple[str, list[Any]]] = []
        middles: list[int] = []
        for target in active:
            low, high = bounds[target.name]
            middle = (low + high) // 2
            middles.append(middle)
            calls.append(("eth_getCode", [target.proxy, block_tag(middle)]))
        codes = rpc.batch(calls)
        for target, middle, code in zip(active, middles, codes):
            if code == "0x":
                bounds[target.name][0] = middle + 1
            else:
                bounds[target.name][1] = middle
    return {name: low for name, (low, _) in bounds.items()}


def storage_call(target: Target, block: int) -> tuple[str, list[Any]]:
    return (
        "eth_getStorageAt",
        [target.storage_address, target.storage_slot, block_tag(block)],
    )


def find_first_change(
    rpc: Rpc, target: Target, low: int, high: int, old_word: str, cache: dict[int, str]
) -> int:
    """Return first block with a value different from old_word in [low + 1, high]."""

    left, right = low + 1, high
    while left < right:
        middle = (left + right) // 2
        word = cache.get(middle)
        if word is None:
            word = rpc.call(*storage_call(target, middle))
            cache[middle] = word
        if word == old_word:
            left = middle + 1
        else:
            right = middle
    return left


def scan_target(
    rpc: Rpc, target: Target, deployment: int, head: int, step: int
) -> dict[str, Any]:
    # Begin two blocks before proxy deployment. The resolved messenger's AddressManager entry was
    # first set one block before the proxy itself was deployed on OP Mainnet.
    start = max(0, deployment - 2)
    checkpoints = list(range(start, head, step))
    if not checkpoints or checkpoints[-1] != head:
        checkpoints.append(head)
    words = rpc.batch([storage_call(target, block) for block in checkpoints])
    cache = dict(zip(checkpoints, words))
    transitions: list[dict[str, Any]] = []

    for left, right in zip(checkpoints, checkpoints[1:]):
        cursor = left
        current = cache[left]
        end_word = cache[right]
        while cursor < right and current != end_word:
            change = find_first_change(rpc, target, cursor, right, current, cache)
            after = cache.get(change)
            if after is None:
                after = rpc.call(*storage_call(target, change))
                cache[change] = after
            transitions.append(
                {
                    "beforeBlock": change - 1,
                    "afterBlock": change,
                    "beforeImplementation": normalized_address(current),
                    "afterImplementation": normalized_address(after),
                }
            )
            cursor, current = change, after

    # De-duplicate transitions that coincide with a checkpoint boundary.
    unique = {(entry["afterBlock"], entry["afterImplementation"]): entry for entry in transitions}
    return {
        "proxy": target.proxy,
        "proxyKind": target.proxy_kind,
        "storageAddress": target.storage_address,
        "storageSlot": target.storage_slot,
        "proxyDeploymentBlock": deployment,
        "transitions": sorted(unique.values(), key=lambda item: item["afterBlock"]),
    }


def fetch_upgrade_logs(rpc: Rpc, head: int) -> list[dict[str, Any]]:
    eip1967_addresses = [
        target.proxy
        for target in TARGETS
        if target.proxy_kind == "EIP-1967"
    ]
    logs = rpc.call(
        "eth_getLogs",
        [
            {
                "fromBlock": "0x0",
                "toBlock": block_tag(head),
                "address": eip1967_addresses,
                "topics": [UPGRADED_TOPIC],
            }
        ],
    )
    messenger = next(target for target in TARGETS if target.name == "L1CrossDomainMessenger")
    logs += rpc.call(
        "eth_getLogs",
        [
            {
                "fromBlock": "0x0",
                "toBlock": block_tag(head),
                "address": messenger.storage_address,
                "topics": [ADDRESS_SET_TOPIC, MESSENGER_NAME_TOPIC],
            }
        ],
    )
    return logs


def fetch_upgrade_logs_at_blocks(rpc: Rpc, blocks: list[int]) -> list[dict[str, Any]]:
    """Read only exact transition blocks, avoiding wide historical log ranges."""

    eip1967_addresses = [
        target.proxy
        for target in TARGETS
        if target.proxy_kind == "EIP-1967"
    ]
    messenger = next(target for target in TARGETS if target.name == "L1CrossDomainMessenger")
    calls: list[tuple[str, list[Any]]] = []
    for block in blocks:
        tag = block_tag(block)
        calls.append(
            (
                "eth_getLogs",
                [
                    {
                        "fromBlock": tag,
                        "toBlock": tag,
                        "address": eip1967_addresses,
                        "topics": [UPGRADED_TOPIC],
                    }
                ],
            )
        )
        calls.append(
            (
                "eth_getLogs",
                [
                    {
                        "fromBlock": tag,
                        "toBlock": tag,
                        "address": messenger.storage_address,
                        "topics": [ADDRESS_SET_TOPIC, MESSENGER_NAME_TOPIC],
                    }
                ],
            )
        )
    return [entry for result in rpc.batch(calls) for entry in result]


def event_guided_target(
    rpc: Rpc,
    target: Target,
    deployment: int,
    logs: list[dict[str, Any]],
) -> dict[str, Any]:
    log_address = (
        target.storage_address
        if target.name == "L1CrossDomainMessenger"
        else target.proxy
    ).lower()
    relevant = [entry for entry in logs if entry["address"].lower() == log_address]
    by_block: dict[int, set[str]] = {}
    for entry in relevant:
        by_block.setdefault(int(entry["blockNumber"], 16), set()).add(entry["transactionHash"])
    blocks = sorted(by_block)
    calls: list[tuple[str, list[Any]]] = []
    for block in blocks:
        calls.append(storage_call(target, block - 1))
        calls.append(storage_call(target, block))
    words = rpc.batch(calls) if calls else []
    transitions = []
    for i, block in enumerate(blocks):
        before, after = words[2 * i], words[2 * i + 1]
        if before == after:
            continue
        transitions.append(
            {
                "beforeBlock": block - 1,
                "afterBlock": block,
                "beforeImplementation": normalized_address(before),
                "afterImplementation": normalized_address(after),
                "transactionHashes": sorted(by_block[block]),
            }
        )
    return {
        "proxy": target.proxy,
        "proxyKind": target.proxy_kind,
        "storageAddress": target.storage_address,
        "storageSlot": target.storage_slot,
        "proxyDeploymentBlock": deployment,
        "discovery": "upgrade-event blocks verified by storage at block-1 and block",
        "transitions": transitions,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--rpc-url", default="http://127.0.0.1:7545")
    parser.add_argument("--head", type=int)
    parser.add_argument("--step", type=int, default=10_000)
    parser.add_argument("--out", type=Path, default=Path("op-upgrade-blocks.json"))
    args = parser.parse_args()
    if args.step <= 0 or args.step > 10_000:
        raise SystemExit("--step must be in 1..10000")

    rpc = Rpc(args.rpc_url)
    head = args.head if args.head is not None else int(rpc.call("eth_blockNumber", []), 16)
    deployments = find_deployments(rpc, TARGETS, head)
    contracts: dict[str, Any] = {
        target.name: scan_target(rpc, target, deployments[target.name], head, args.step)
        for target in TARGETS
    }
    for result in contracts.values():
        result["discovery"] = "<=10,000-block slot checkpoints plus binary search"

    transition_blocks = sorted(
        {
            transition["afterBlock"]
            for contract in contracts.values()
            for transition in contract["transitions"]
        }
    )
    logs = fetch_upgrade_logs_at_blocks(rpc, transition_blocks)

    transaction_hashes_by_block: dict[int, set[str]] = {}
    for entry in logs:
        transaction_hashes_by_block.setdefault(int(entry["blockNumber"], 16), set()).add(
            entry["transactionHash"]
        )
    for contract in contracts.values():
        for transition in contract["transitions"]:
            hashes = transaction_hashes_by_block.get(transition["afterBlock"])
            if hashes:
                transition["transactionHashes"] = sorted(hashes)

    chronology = []
    for name, contract in contracts.items():
        for transition in contract["transitions"]:
            chronology.append({"contract": name, **transition})
    chronology.sort(key=lambda entry: (entry["afterBlock"], entry["contract"]))
    output = {
        "chainId": int(rpc.call("eth_chainId", []), 16),
        "rpcUsed": args.rpc_url,
        "headBlock": head,
        "checkpointStep": args.step,
        "method": (
            "every locator is sampled at <=10,000-block intervals and each changed interval is "
            "refined by binary search; one-block event reads only attach transaction hashes"
        ),
        "limitation": (
            "an A->B->A round trip wholly inside one checkpoint interval is invisible; "
            "same-transaction transient implementations are intentionally excluded"
        ),
        "contracts": contracts,
        "chronology": chronology,
    }
    args.out.write_text(json.dumps(output, indent=2) + "\n")


if __name__ == "__main__":
    main()
