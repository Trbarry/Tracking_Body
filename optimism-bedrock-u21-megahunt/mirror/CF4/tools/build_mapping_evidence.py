#!/usr/bin/env python3
"""Resolve retained OP Mainnet event samples into their physical storage slots.

This is deliberately read-only.  Log discovery was performed separately with ranges no
larger than 10,000 blocks; this script only issues eth_getStorageAt/eth_call and uses
`cast index` locally for Solidity's mapping-key derivation.
"""

from __future__ import annotations

import json
import subprocess
import urllib.request
from pathlib import Path


RPC = "http://127.0.0.1:7545"
CUTOFF = 26_433_900
ROOT = Path(__file__).resolve().parents[1]
CENSUS = ROOT / "evidence/state-event-census.json"
OUT = ROOT / "evidence/mapping-archaeology.json"

PORTAL = "0xbeb5fc579115071764c7423a4f12edde41f106ed"
MESSENGER = "0x25ace71c97b33cc4729cf772ae268934f7ab5fa1"
BRIDGE = "0x99c9fc46f92e8a1c0dec1b1747d010903e884be1"
ASR_CURRENT = "0x23b2c62946350f4246f9f9d027e071f0264fd113"


def rpc(method: str, params: list):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    request = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=90) as response:
        decoded = json.load(response)
    if "error" in decoded:
        raise RuntimeError(decoded["error"])
    return decoded["result"]


def storage(address: str, slot: str | int, block: int) -> str:
    slot_hex = slot if isinstance(slot, str) and slot.startswith("0x") else hex(int(slot))
    return rpc("eth_getStorageAt", [address, slot_hex, hex(block)])


def index(key_type: str, key: str, slot: str | int) -> str:
    return subprocess.check_output(
        ["cast", "index", key_type, key, str(slot)], text=True
    ).strip().lower()


def keccak_word(word: str) -> str:
    return subprocess.check_output(["cast", "keccak", word], text=True).strip().lower()


def plus(slot: str, amount: int = 1) -> str:
    return "0x" + (int(slot, 16) + amount).to_bytes(32, "big").hex()


def event_hash(log: dict) -> str:
    # The earliest L1 messenger emitted the bytes32 non-indexed; later versions indexed it.
    return log["topics"][1] if len(log["topics"]) > 1 else "0x" + log["data"][2:66]


def event_meta(log: dict) -> dict:
    return {
        "block": int(log["blockNumber"], 16),
        "transaction_hash": log["transactionHash"],
        "log_index": int(log["logIndex"], 16),
    }


def values_around(address: str, slots: list[str], block: int) -> dict:
    return {
        "before_event_block": {slot: storage(address, slot, block - 1) for slot in slots},
        "after_event_block": {slot: storage(address, slot, block) for slot in slots},
        "at_cutoff": {slot: storage(address, slot, CUTOFF) for slot in slots},
    }


def portal_legacy(log: dict) -> dict:
    withdrawal_hash = event_hash(log)
    base = index("bytes32", withdrawal_hash, 52)
    slots = [base, plus(base)]
    block = int(log["blockNumber"], 16)
    return {
        **event_meta(log),
        "withdrawal_hash": withdrawal_hash,
        "layout": {
            "base_slot": 52,
            "entry_word_0": base,
            "entry_word_1": plus(base),
            "shape": "{bytes32 outputRoot; uint128 timestamp; uint128 l2OutputIndex}",
        },
        "storage": values_around(PORTAL, slots, block),
    }


def portal_fault_proof(log: dict) -> dict:
    withdrawal_hash = event_hash(log)
    submitter = "0x" + log["topics"][2][-40:]
    outer = index("bytes32", withdrawal_hash, 57)
    entry = index("address", submitter, outer)
    submitters_length = index("bytes32", withdrawal_hash, 60)
    first_element = keccak_word(submitters_length)
    block = int(log["blockNumber"], 16)
    slots = [entry, submitters_length, first_element]
    return {
        **event_meta(log),
        "withdrawal_hash": withdrawal_hash,
        "proof_submitter": submitter,
        "layout": {
            "outer_base_slot": 57,
            "outer_slot": outer,
            "entry_slot": entry,
            "shape": "[withdrawalHash][proofSubmitter] => {address disputeGameProxy; uint64 timestamp}",
            "proof_submitters_base_slot": 60,
            "proof_submitters_length_slot": submitters_length,
            "proof_submitters_element_0_slot": first_element,
        },
        "storage": values_around(PORTAL, slots, block),
    }


def finalized(log: dict) -> dict:
    withdrawal_hash = event_hash(log)
    entry = index("bytes32", withdrawal_hash, 51)
    block = int(log["blockNumber"], 16)
    return {
        **event_meta(log),
        "withdrawal_hash": withdrawal_hash,
        "layout": {"base_slot": 51, "entry_slot": entry, "shape": "bytes32 => bool"},
        "storage": values_around(PORTAL, [entry], block),
    }


def messenger(log: dict) -> dict:
    message_hash = event_hash(log)
    block = int(log["blockNumber"], 16)
    entries = {str(slot): index("bytes32", message_hash, slot) for slot in (201, 202, 203, 206)}
    return {
        **event_meta(log),
        "message_hash": message_hash,
        "entry_slots": entries,
        "slot_meanings_v9": {
            "201": "legacy spacer: blockedMessages",
            "202": "legacy spacer: relayedMessages",
            "203": "successfulMessages",
            "206": "failedMessages",
        },
        "storage": values_around(MESSENGER, list(entries.values()), block),
    }


def bridge_deposit(log: dict) -> dict:
    local = "0x" + log["topics"][1][-40:]
    remote = "0x" + log["topics"][2][-40:]
    outer = index("address", local, 2)
    entry = index("address", remote, outer)
    block = int(log["blockNumber"], 16)
    return {
        **event_meta(log),
        "local_token": local,
        "remote_token": remote,
        "layout": {
            "base_slot": 2,
            "outer_slot": outer,
            "entry_slot": entry,
            "shape": "[localToken][remoteToken] => uint256 escrowed amount",
        },
        "storage": values_around(BRIDGE, [entry], block),
    }


def main() -> None:
    census = json.loads(CENSUS.read_text())
    buckets = census["buckets"]

    legacy_logs = buckets["OptimismPortal:WithdrawalProven"]["pre_fault_proofs_last"][-3:]
    fault_logs = buckets["OptimismPortal:WithdrawalProvenExtension1"]["post_fault_proofs_first"][:3]
    finalized_logs = buckets["OptimismPortal:WithdrawalFinalized"]["last"][-3:]

    relayed = buckets["L1CrossDomainMessenger:RelayedMessage"]
    failed = buckets["L1CrossDomainMessenger:FailedRelayedMessage"]
    messenger_logs = [relayed["first"][0], relayed["pre_bedrock_last"][-1], relayed["post_bedrock_first"][0], failed["first"][0]]

    old_deposits = buckets["L1StandardBridge:ERC20DepositInitiated"]["pre_bedrock_last"]
    new_deposits = buckets["L1StandardBridge:ERC20BridgeInitiated"]["post_bedrock_first"]
    bridge_logs = [old_deposits[-1], new_deposits[0]]

    portal_respected = buckets["OptimismPortal:PortalRespectedGameTypeSet"]
    respected_samples = []
    for log in portal_respected["first"]:
        block = int(log["blockNumber"], 16)
        respected_samples.append({
            **event_meta(log),
            "game_type": int(log["topics"][1], 16),
            "updated_at": int(log["topics"][2], 16),
            "portal_slot_59": {
                "before_event_block": storage(PORTAL, 59, block - 1),
                "after_event_block": storage(PORTAL, 59, block),
                "at_cutoff_stale_spacer": storage(PORTAL, 59, CUTOFF),
            },
        })

    output = {
        "method": {
            "rpc": RPC,
            "cutoff_block": CUTOFF,
            "log_coverage": census["coverage"],
            "note": "Every retained sample is tied to an event transaction and read before/after its block and at the cutoff.",
        },
        "event_counts": {name: value["count"] for name, value in buckets.items()},
        "portal": {
            "legacy_proven_withdrawals_slot_52": [portal_legacy(log) for log in legacy_logs],
            "fault_proof_proven_withdrawals_slot_57": [portal_fault_proof(log) for log in fault_logs],
            "finalized_withdrawals_slot_51": [finalized(log) for log in finalized_logs],
            "respected_game_type_portal_slot_59": respected_samples,
            "current_anchor_state_registry": {
                "address": ASR_CURRENT,
                "blacklist_base_slot": 5,
                "respected_game_type_packed_slot": 6,
                "slot_6_at_cutoff": storage(ASR_CURRENT, 6, CUTOFF),
                "blacklist_event_count_all_asr_generations": sum(
                    value["count"] for name, value in buckets.items()
                    if name.startswith("AnchorStateRegistry") and name.endswith(":DisputeGameBlacklisted")
                ),
            },
        },
        "messenger": {
            "samples": [messenger(log) for log in messenger_logs],
            "xDomainMsgSender_slot_204_at_cutoff": storage(MESSENGER, 204, CUTOFF),
            "msgNonce_slot_205_at_cutoff": storage(MESSENGER, 205, CUTOFF),
        },
        "bridge": {"deposits_slot_2_samples": [bridge_deposit(log) for log in bridge_logs]},
        "negative_census": {
            "withdrawal_proof_deleted": buckets.get("OptimismPortal:WithdrawalProofDeleted", {"count": 0})["count"],
            "portal_blacklist_events": buckets.get("OptimismPortal:DisputeGameBlacklisted", {"count": 0})["count"],
            "asr_blacklist_events": sum(
                value["count"] for name, value in buckets.items()
                if name.startswith("AnchorStateRegistry") and name.endswith(":DisputeGameBlacklisted")
            ),
        },
    }
    OUT.write_text(json.dumps(output, indent=2) + "\n")
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
