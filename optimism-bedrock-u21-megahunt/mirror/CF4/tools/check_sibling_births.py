#!/usr/bin/env python3
"""Read sibling-chain portal versions at each registry-pinned L1 genesis block."""

from __future__ import annotations

import json
import tomllib
import urllib.request
from pathlib import Path


RPC = "http://127.0.0.1:7545"
IMPL_SLOT = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
ROOT = Path(__file__).resolve().parents[1]
REGISTRY = Path("/home/user/ethereum-optimism/ext/superchain-registry/superchain/configs/mainnet")
OUT = ROOT / "evidence/sibling-portal-births.json"


def rpc(method: str, params: list):
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    request = urllib.request.Request(RPC, data=payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=90) as response:
        decoded = json.load(response)
    if "error" in decoded:
        raise RuntimeError(decoded["error"])
    return decoded["result"]


def decode_string(raw: str) -> str:
    data = bytes.fromhex(raw[2:])
    offset = int.from_bytes(data[:32], "big")
    length = int.from_bytes(data[offset:offset + 32], "big")
    return data[offset + 32:offset + 32 + length].decode()


def main() -> None:
    records = []
    for chain in ("ink", "soneium", "unichain"):
        path = REGISTRY / f"{chain}.toml"
        config = tomllib.loads(path.read_text())
        block = config["genesis"]["l1"]["number"]
        portal = config["addresses"]["OptimismPortalProxy"]
        version = decode_string(rpc("eth_call", [{"to": portal, "data": "0x54fd4d50"}, hex(block)]))
        implementation_word = rpc("eth_getStorageAt", [portal, IMPL_SLOT, hex(block)])
        records.append({
            "chain": chain,
            "registry_file": str(path),
            "l1_genesis_block": block,
            "portal_proxy": portal.lower(),
            "portal_version_at_l1_genesis": version,
            "implementation_at_l1_genesis": "0x" + implementation_word[-40:],
            "classification": "Fault-proof OptimismPortal2 (nested provenWithdrawals at base slot 57)",
        })
    OUT.write_text(json.dumps({"rpc": RPC, "records": records}, indent=2) + "\n")
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
