#!/usr/bin/env python3
"""Heuristically scan observed relay targets for portal-vs-messenger sender coupling."""

import json
import pathlib
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
RPC = "http://127.0.0.1:7545"
BLOCK = hex(26_433_900)
IMPL_SLOT = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
PORTAL = "beb5fc579115071764c7423a4f12edde41f106ed"
MESSENGER = "25ace71c97b33cc4729cf772ae268934f7ab5fa1"
NEEDLES = {
    "l2Sender_selector": "9bf62d82",
    "xDomainMessageSender_selector": "6e296e45",
    "portal_address": PORTAL,
    "messenger_address": MESSENGER,
}


def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    request = urllib.request.Request(RPC, data=body, headers={"content-type": "application/json"})
    with urllib.request.urlopen(request, timeout=120) as response:
        reply = json.load(response)
    if "error" in reply:
        raise RuntimeError(reply["error"])
    return reply["result"]


def opcode_counts(code_hex):
    code = bytes.fromhex(code_hex)
    counts = {"BLOCKHASH": 0, "TIMESTAMP": 0, "NUMBER": 0}
    names = {0x40: "BLOCKHASH", 0x42: "TIMESTAMP", 0x43: "NUMBER"}
    cursor = 0
    while cursor < len(code):
        opcode = code[cursor]
        if opcode in names:
            counts[names[opcode]] += 1
        cursor += 1
        if 0x60 <= opcode <= 0x7F:
            cursor += opcode - 0x5F
    return counts


def inspect(address):
    code = rpc("eth_getCode", [address, BLOCK])[2:].lower()
    slot = rpc("eth_getStorageAt", [address, IMPL_SLOT, BLOCK])[2:].lower().rjust(64, "0")
    implementation = "0x" + slot[-40:]
    impl_code = ""
    if int(implementation, 16):
        impl_code = rpc("eth_getCode", [implementation, BLOCK])[2:].lower()
    combined = code + impl_code
    return {
        "address": address,
        "code_bytes": len(code) // 2,
        "eip1967_implementation": implementation if int(implementation, 16) else None,
        "implementation_code_bytes": len(impl_code) // 2,
        "contains": {name: needle in combined for name, needle in NEEDLES.items()},
        "context_opcodes": opcode_counts(combined),
    }


def main():
    census = json.loads((ROOT / "evidence" / "failure-census-enriched.json").read_text())
    proves = json.loads((ROOT / "evidence" / "prove-target-census.json").read_text())
    targets = {item["relay"]["target"].lower() for item in census["failed_messages"]}
    for item in proves["withdrawals"]:
        if item["relay"]:
            targets.add(item["relay"]["target"].lower())
        else:
            targets.add(item["withdrawal"]["target"].lower())
    rows = [inspect(target) for target in sorted(targets)]
    output = {
        "meta": {
            "rpc": RPC,
            "passive_reads_only": True,
            "block": int(BLOCK, 16),
            "note": "Literal bytecode scan is a heuristic; absence is not a proof of no indirect call.",
        },
        "targets": rows,
    }
    path = ROOT / "evidence" / "observed-target-bytecode-scan.json"
    path.write_text(json.dumps(output, indent=2) + "\n")
    print(json.dumps(rows, indent=2))


if __name__ == "__main__":
    main()
