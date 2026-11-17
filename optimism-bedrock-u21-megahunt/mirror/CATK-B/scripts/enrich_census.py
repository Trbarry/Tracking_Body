#!/usr/bin/env python3
"""Reconstruct CATK-B failure cases from passive RPC reads.

The script decodes the fixed ABI shapes used by OptimismPortal2 and
CrossDomainMessenger, checks both replay mappings at the pinned post-U21
block, and records only summarized call frames. It never sends a transaction.
"""

from __future__ import annotations

import json
import subprocess
import time
import urllib.error
import urllib.request
from collections import defaultdict
from pathlib import Path


RPC = "http://127.0.0.1:7545"
PINNED_BLOCK = 26_433_900
ROOT = Path(
    "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/mirror/CATK-B/evidence"
)
WITHDRAWAL_RAW = ROOT / "withdrawal_finalized-raw.json"
FAILED_RAW = ROOT / "failed_relayed_message-raw.json"
OUT = ROOT / "failure-census-enriched.json"

ZERO_WORD = "0x" + "00" * 32
PORTAL_SELECTOR = "8c3152e9"
RELAY_SELECTOR = "d764ad0b"
SUCCESSFUL_SELECTOR = "b1b1b209"
FAILED_SELECTOR = "a4e7f8bd"
V0_RELAY_SELECTOR = "cbd4ece9"

CHAINS = {
    "op": {
        "portal": "0xbeb5fc579115071764c7423a4f12edde41f106ed",
        "l1cdm": "0x25ace71c97b33cc4729cf772ae268934f7ab5fa1",
    },
    "ink": {
        "portal": "0x5d66c1782664115999c47c9fa5cd031f495d3e4f",
        "l1cdm": "0x69d3cf86b2bf1a9e99875b7e2d9b6a84426c171f",
    },
    "soneium": {
        "portal": "0x88e529a6ccd302c948689cd5156c83d4614fae92",
        "l1cdm": "0x9cf951e3f74b644e621b36ca9cea147a78d4c39f",
    },
    "unichain": {
        "portal": "0x0bd48f6b86a26d3a217d0fa6ffe2b491b956a7a2",
        "l1cdm": "0x9a3d64e386c18cb1d6d5179a9596a4b5736e98a6",
    },
}
PORTAL_TO_CHAIN = {v["portal"]: k for k, v in CHAINS.items()}
MESSENGER_TO_CHAIN = {v["l1cdm"]: k for k, v in CHAINS.items()}


def rpc(method: str, params: list, request_id: int = 1):
    payload = json.dumps(
        {"jsonrpc": "2.0", "id": request_id, "method": method, "params": params}
    ).encode()
    req = urllib.request.Request(
        RPC, data=payload, headers={"Content-Type": "application/json"}
    )
    last_error = None
    for attempt in range(7):
        try:
            with urllib.request.urlopen(req, timeout=120) as response:
                body = json.load(response)
            if "error" in body:
                raise RuntimeError(json.dumps(body["error"], sort_keys=True))
            return body["result"]
        except (urllib.error.URLError, TimeoutError, RuntimeError) as exc:
            last_error = exc
            time.sleep(min(0.25 * 2**attempt, 8))
    raise RuntimeError(f"RPC failed: {last_error}")


def word(data: bytes, offset: int) -> int:
    return int.from_bytes(data[offset : offset + 32], "big")


def address_word(data: bytes, offset: int) -> str:
    return "0x" + data[offset + 12 : offset + 32].hex()


def dynamic_bytes(data: bytes, base: int, offset_word_pos: int) -> bytes:
    rel = word(data, offset_word_pos)
    start = base + rel
    length = word(data, start)
    return data[start + 32 : start + 32 + length]


def decode_relay(calldata_hex: str) -> dict:
    raw = bytes.fromhex(calldata_hex.removeprefix("0x"))
    if raw[:4].hex() != RELAY_SELECTOR:
        raise ValueError("not relayMessage v1 calldata")
    args = raw[4:]
    message = dynamic_bytes(args, 0, 5 * 32)
    return {
        "nonce": word(args, 0),
        "nonce_hex": hex(word(args, 0)),
        "version": word(args, 0) >> 240,
        "sender": address_word(args, 32),
        "target": address_word(args, 64),
        "value_wei": word(args, 96),
        "min_gas_limit": word(args, 128),
        "message": "0x" + message.hex(),
        "message_selector": "0x" + message[:4].hex() if len(message) >= 4 else "0x",
    }


def decode_withdrawal(calldata_hex: str) -> dict:
    raw = bytes.fromhex(calldata_hex.removeprefix("0x"))
    if raw[:4].hex() != PORTAL_SELECTOR:
        raise ValueError("not finalizeWithdrawalTransaction calldata")
    args = raw[4:]
    tuple_start = word(args, 0)
    tx = args[tuple_start:]
    payload = dynamic_bytes(tx, 0, 5 * 32)
    return {
        "nonce": word(tx, 0),
        "nonce_hex": hex(word(tx, 0)),
        "sender": address_word(tx, 32),
        "target": address_word(tx, 64),
        "value_wei": word(tx, 96),
        "gas_limit": word(tx, 128),
        "data": "0x" + payload.hex(),
    }


def encode_word(value: int) -> bytes:
    return value.to_bytes(32, "big")


def encode_address(value: str) -> bytes:
    return bytes(12) + bytes.fromhex(value.removeprefix("0x"))


def encode_v0_relay(relay: dict) -> bytes:
    message = bytes.fromhex(relay["message"].removeprefix("0x"))
    padding = bytes((32 - len(message) % 32) % 32)
    return b"".join(
        [
            bytes.fromhex(V0_RELAY_SELECTOR),
            encode_address(relay["target"]),
            encode_address(relay["sender"]),
            encode_word(128),
            encode_word(relay["nonce"]),
            encode_word(len(message)),
            message,
            padding,
        ]
    )


def keccak(data: bytes) -> str:
    return subprocess.check_output(
        ["cast", "keccak", "0x" + data.hex()], text=True
    ).strip()


def bool_mapping(contract: str, selector: str, key: str, block: int) -> bool:
    result = rpc(
        "eth_call",
        [{"to": contract, "data": "0x" + selector + key.removeprefix("0x")}, hex(block)],
        block,
    )
    return int(result, 16) != 0


def all_frames(frame: dict):
    yield frame
    for child in frame.get("calls", []):
        yield from all_frames(child)


def find_frame(trace: dict, to: str, selector: str) -> dict | None:
    to = to.lower()
    prefix = "0x" + selector
    for frame in all_frames(trace):
        if frame.get("to", "").lower() == to and frame.get("input", "").startswith(prefix):
            return frame
    return None


def summarized_frame(frame: dict) -> dict:
    return {
        key: frame[key]
        for key in (
            "from",
            "to",
            "type",
            "gas",
            "gasUsed",
            "value",
            "output",
            "error",
            "revertReason",
        )
        if key in frame
    }


def enrich_false_finalizations(withdrawal_raw: dict) -> list[dict]:
    out = []
    false_logs = [log for log in withdrawal_raw["logs"] if log["data"] == ZERO_WORD]
    for log in false_logs:
        portal = log["address"].lower()
        chain = PORTAL_TO_CHAIN[portal]
        messenger = CHAINS[chain]["l1cdm"]
        tx_hash = log["transactionHash"]
        block = int(log["blockNumber"], 16)
        trace = rpc("debug_traceTransaction", [tx_hash, {"tracer": "callTracer", "timeout": "60s"}], block)
        portal_frame = find_frame(trace, portal, PORTAL_SELECTOR)
        relay_frame = find_frame(trace, messenger, RELAY_SELECTOR)
        if portal_frame is None or relay_frame is None:
            raise RuntimeError(f"missing portal/relay frame in {tx_hash}")
        withdrawal = decode_withdrawal(portal_frame["input"])
        relay = decode_relay(relay_frame["input"])
        v1_hash = keccak(bytes.fromhex(relay_frame["input"].removeprefix("0x")))
        v0_hash = keccak(encode_v0_relay(relay))
        out.append(
            {
                "chain": chain,
                "block": block,
                "tx": tx_hash,
                "withdrawal_hash": log["topics"][1],
                "withdrawal": withdrawal,
                "relay": relay,
                "v1_message_hash": v1_hash,
                "v0_message_hash": v0_hash,
                "mapping_at_block_minus_1": {
                    "v0_successful": bool_mapping(messenger, SUCCESSFUL_SELECTOR, v0_hash, block - 1),
                    "v1_successful": bool_mapping(messenger, SUCCESSFUL_SELECTOR, v1_hash, block - 1),
                    "v1_failed": bool_mapping(messenger, FAILED_SELECTOR, v1_hash, block - 1),
                },
                "mapping_at_pinned_block": {
                    "v0_successful": bool_mapping(messenger, SUCCESSFUL_SELECTOR, v0_hash, PINNED_BLOCK),
                    "v1_successful": bool_mapping(messenger, SUCCESSFUL_SELECTOR, v1_hash, PINNED_BLOCK),
                    "v1_failed": bool_mapping(messenger, FAILED_SELECTOR, v1_hash, PINNED_BLOCK),
                },
                "portal_frame": summarized_frame(portal_frame),
                "relay_frame": summarized_frame(relay_frame),
            }
        )
        print(f"false finalization {tx_hash}: {relay_frame.get('revertReason')}", flush=True)
    return out


def enrich_failed_messages(failed_raw: dict) -> list[dict]:
    groups: dict[tuple[str, str], list[dict]] = defaultdict(list)
    for log in failed_raw["logs"]:
        groups[(log["address"].lower(), log["topics"][1])].append(log)
    out = []
    for (messenger, msg_hash), logs in sorted(groups.items()):
        chain = MESSENGER_TO_CHAIN[messenger]
        first = logs[0]
        tx_hash = first["transactionHash"]
        block = int(first["blockNumber"], 16)
        trace = rpc("debug_traceTransaction", [tx_hash, {"tracer": "callTracer", "timeout": "60s"}], block)
        candidates = []
        for frame in all_frames(trace):
            if (
                frame.get("to", "").lower() == messenger
                and frame.get("input", "").startswith("0x" + RELAY_SELECTOR)
            ):
                candidate_hash = keccak(bytes.fromhex(frame["input"].removeprefix("0x")))
                if candidate_hash.lower() == msg_hash.lower():
                    candidates.append(frame)
        if not candidates:
            raise RuntimeError(f"no relay frame hashes to {msg_hash} in {tx_hash}")
        frame = candidates[0]
        relay = decode_relay(frame["input"])
        event_rows = [
            {
                "block": int(log["blockNumber"], 16),
                "tx": log["transactionHash"],
                "log_index": int(log["logIndex"], 16),
            }
            for log in logs
        ]
        out.append(
            {
                "chain": chain,
                "messenger": messenger,
                "message_hash": msg_hash,
                "events": event_rows,
                "relay": relay,
                "mapping_at_pinned_block": {
                    "successful": bool_mapping(messenger, SUCCESSFUL_SELECTOR, msg_hash, PINNED_BLOCK),
                    "failed": bool_mapping(messenger, FAILED_SELECTOR, msg_hash, PINNED_BLOCK),
                },
                "first_failure_frame": summarized_frame(frame),
            }
        )
        print(f"failed message {chain} {msg_hash}: {relay['value_wei']} wei", flush=True)
    return out


def main() -> None:
    withdrawal_raw = json.loads(WITHDRAWAL_RAW.read_text())
    failed_raw = json.loads(FAILED_RAW.read_text())
    false_finalizations = enrich_false_finalizations(withdrawal_raw)
    failed_messages = enrich_failed_messages(failed_raw)
    balances = {
        chain: int(rpc("eth_getBalance", [addresses["l1cdm"], hex(PINNED_BLOCK)]), 16)
        for chain, addresses in CHAINS.items()
    }
    result = {
        "meta": {
            "rpc": RPC,
            "pinned_block": PINNED_BLOCK,
            "passive_reads_only": True,
        },
        "counts": {
            "withdrawal_finalized_all": len(withdrawal_raw["logs"]),
            "withdrawal_finalized_false": len(false_finalizations),
            "failed_relay_events": len(failed_raw["logs"]),
            "failed_relay_unique_messages": len(failed_messages),
        },
        "l1cdm_balances_wei": balances,
        "false_finalizations": false_finalizations,
        "failed_messages": failed_messages,
    }
    OUT.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
