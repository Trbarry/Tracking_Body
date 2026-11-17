#!/usr/bin/env python3
"""Extract target errors from the original zero-ETH failed-message traces.

Uses only debug_traceTransaction passive reads against the engagement proxy.
Current replay success/failure is tested separately on the local Foundry fork.
"""

import json
import pathlib
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
RPC = "http://127.0.0.1:7545"
RELAY_SELECTOR = "0xd764ad0b"


def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    request = urllib.request.Request(RPC, data=body, headers={"content-type": "application/json"})
    with urllib.request.urlopen(request, timeout=180) as response:
        reply = json.load(response)
    if "error" in reply:
        raise RuntimeError({"method": method, "error": reply["error"]})
    return reply["result"]


def walk(frame):
    yield frame
    for child in frame.get("calls", []):
        yield from walk(child)


def decode_error(output):
    if not output or output == "0x":
        return None
    raw = bytes.fromhex(output[2:])
    if len(raw) >= 68 and raw[:4].hex() == "08c379a0":
        offset = int.from_bytes(raw[4:36], "big")
        start = 4 + offset
        size = int.from_bytes(raw[start:start + 32], "big")
        return raw[start + 32:start + 32 + size].decode(errors="replace")
    if len(raw) >= 4:
        return "custom/panic selector 0x" + raw[:4].hex()
    return output


def original_trace_for(message, census_by_hash):
    original_tx = census_by_hash[message["message_hash"]]["events"][0]["tx"]
    trace = rpc("debug_traceTransaction", [original_tx, {"tracer": "callTracer"}])
    messenger = message["messenger"].lower()
    candidates = [
        frame.get("input", "")
        for frame in walk(trace)
        if frame.get("to", "").lower() == messenger and frame.get("input", "").startswith(RELAY_SELECTOR)
    ]
    if not candidates:
        raise RuntimeError(f"no relay calldata in {original_tx}")
    return candidates[-1], original_tx, trace


def main():
    vectors = json.loads((ROOT / "evidence" / "active-zero-value-replays.json").read_text())["messages"]
    census = json.loads((ROOT / "evidence" / "failure-census-enriched.json").read_text())
    census_by_hash = {item["message_hash"]: item for item in census["failed_messages"]}
    rows = []
    for message in vectors:
        relay_input, original_tx, trace = original_trace_for(message, census_by_hash)
        target = message["target"].lower()
        target_frames = [frame for frame in walk(trace) if frame.get("to", "").lower() == target]
        errors = []
        for frame in walk(trace):
            if frame.get("error") or frame.get("revertReason"):
                errors.append({
                    "type": frame.get("type"),
                    "from": frame.get("from"),
                    "to": frame.get("to"),
                    "error": frame.get("error"),
                    "revert_reason": frame.get("revertReason") or decode_error(frame.get("output")),
                    "output": frame.get("output"),
                })
        rows.append({
            "message_hash": message["message_hash"],
            "message_selector": message["message_selector"],
            "target": message["target"],
            "original_failure_tx": original_tx,
            "relay_calldata": relay_input,
            "top_call_error": trace.get("error"),
            "target_call_count": len(target_frames),
            "target_call_succeeded": any(not frame.get("error") for frame in target_frames),
            "errors": errors,
        })
        print(message["message_hash"], errors[-1]["revert_reason"] if errors else "SUCCESS")
    output = {
        "meta": {
            "rpc": RPC,
            "passive_reads_only": True,
            "note": "Errors are from each original failed relay; current outcomes are asserted by CATK_B.t.sol.",
        },
        "replays": rows,
    }
    (ROOT / "evidence" / "active-zero-value-replay-traces.json").write_text(json.dumps(output, indent=2) + "\n")


if __name__ == "__main__":
    main()
