#!/usr/bin/env python3
"""Collect pre/post implementation, version, proxy type, and initializer state."""

import json
import subprocess
from pathlib import Path


ROOT = Path("/home/user/Tracking_Body/optimism-u21-novel-hunt")
INITIALIZERS = ROOT / "mirror/lane-21/artifacts/decoded-initializers.json"
RPC = {
    "pre": ("http://127.0.0.1:8546", 26430858),
    "post": ("http://127.0.0.1:8547", 26430859),
    "later": ("http://127.0.0.1:8545", 26433900),
}
TYPE_NAME = {0: "ERC1967", 1: "CHUGSPLASH", 2: "RESOLVED"}


def run(*args: str) -> str:
    proc = subprocess.run(args, check=False, text=True, capture_output=True)
    if proc.returncode:
        return "ERROR: " + (proc.stderr.strip() or proc.stdout.strip())
    return proc.stdout.strip()


def call(address: str, signature: str, arg: str | None, endpoint: str, block: int) -> str:
    cmd = ["cast", "call", address, signature]
    if arg is not None:
        cmd.append(arg)
    cmd.extend(["--rpc-url", endpoint, "--block", str(block)])
    return run(*cmd).splitlines()[0]


def storage(address: str, slot: int, endpoint: str, block: int) -> str:
    return run(
        "cast", "storage", address, hex(slot), "--rpc-url", endpoint, "--block", str(block)
    ).splitlines()[0]


def initialized_byte(word: str, offset: int) -> int | str:
    if word.startswith("ERROR"):
        return word
    return (int(word, 16) >> (offset * 8)) & 0xFF


def main() -> None:
    rows = json.loads(INITIALIZERS.read_text())
    result = []
    for row in rows:
        target = row["target"]
        admin = row["proxy_admin"]
        ptype_raw = call(admin, "proxyType(address)(uint8)", target, *RPC["post"])
        ptype = int(ptype_raw.split()[0])
        offset = 20 if row["contract"] == "L1CrossDomainMessenger" else 0

        record = {
            "chain": row["chain"],
            "contract": row["contract"],
            "proxy": target,
            "proxy_admin": admin,
            "proxy_type": TYPE_NAME[ptype],
            "initializer_byte_offset": offset,
        }
        for label, (endpoint, block) in RPC.items():
            impl = call(admin, "getProxyImplementation(address)(address)", target, endpoint, block)
            raw0 = storage(target, 0, endpoint, block)
            record[label] = {
                "block": block,
                "implementation": impl,
                "proxy_version": call(target, "version()(string)", None, endpoint, block),
                "slot0": raw0,
                "initialized_version": initialized_byte(raw0, offset),
            }
        post_impl = record["post"]["implementation"]
        impl_slot0 = storage(post_impl, 0, *RPC["post"])
        record["post_implementation_slot0"] = impl_slot0
        record["post_implementation_initialized_version"] = initialized_byte(impl_slot0, offset)
        record["implementation_changed"] = (
            record["pre"]["implementation"].lower() != record["post"]["implementation"].lower()
        )
        record["stable_to_later"] = (
            record["post"]["implementation"].lower() == record["later"]["implementation"].lower()
            and record["post"]["proxy_version"] == record["later"]["proxy_version"]
            and record["post"]["initialized_version"] == record["later"]["initialized_version"]
        )
        result.append(record)

    print(json.dumps({
        "blocks": {name: block for name, (_, block) in RPC.items()},
        "proxies": result,
        "summary": {
            "count": len(result),
            "implementation_changes": sum(r["implementation_changed"] for r in result),
            "initializer_version_changes": [
                f"{r['chain']}/{r['contract']}"
                for r in result
                if r["pre"]["initialized_version"] != r["post"]["initialized_version"]
            ],
            "unlocked_post_implementations": [
                f"{r['chain']}/{r['contract']}"
                for r in result
                if r["post_implementation_initialized_version"] != 255
            ],
            "not_stable_to_later": [
                f"{r['chain']}/{r['contract']}" for r in result if not r["stable_to_later"]
            ],
        },
    }, indent=2))


if __name__ == "__main__":
    main()
