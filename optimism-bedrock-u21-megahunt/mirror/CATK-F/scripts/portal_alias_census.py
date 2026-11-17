#!/usr/bin/env python3
"""Read-only cross-chain identity census for sibling-portal deposits."""

import json
import urllib.request
from pathlib import Path


ROOT = Path("/home/user/Tracking_Body/optimism-bedrock-u21-megahunt")
OUT = ROOT / "mirror/CATK-F/evidence/portal-alias-census.json"
ALIAS_OFFSET = int("1111000000000000000000000000000000001111", 16)
L2_PROXY_ADMIN = "0x4200000000000000000000000000000000000018"
L1_BLOCK = "0x4200000000000000000000000000000000000015"
DEPOSITOR = "0xdeaddeaddeaddeaddeaddeaddeaddeaddead0001"
OWNER_SELECTOR = "0x8da5cb5b"
PROXY_ADMIN_OWNER_SELECTOR = "0xdad544e0"

CHAINS = {
    "OP": {
        "rpc": "http://127.0.0.1:7546",
        "block": 159_654_093,
        "portal": "0xbeb5fc579115071764c7423a4f12edde41f106ed",
    },
    "INK": {
        "rpc": "https://rpc-gel.inkonchain.com",
        "block": None,
        "portal": "0x5d66c1782664115999c47c9fa5cd031f495d3e4f",
    },
    "SONEIUM": {
        "rpc": "https://rpc.soneium.org",
        "block": None,
        "portal": "0x88e529a6ccd302c948689cd5156c83d4614fae92",
    },
    "UNICHAIN": {
        "rpc": "https://mainnet.unichain.org",
        "block": None,
        "portal": "0x0bd48f6b86a26d3a217d0fa6ffe2b491b956a7a2",
    },
}


def rpc(url, method, params, ident):
    request = urllib.request.Request(
        url,
        json.dumps({"jsonrpc": "2.0", "id": ident, "method": method, "params": params}).encode(),
        {"Content-Type": "application/json", "User-Agent": "CATK-F-read-only-census/1"},
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        obj = json.load(response)
    if "error" in obj:
        raise RuntimeError(f"{url} {method}: {obj['error']}")
    return obj["result"]


def alias(address):
    return "0x" + format((int(address, 16) + ALIAS_OFFSET) % (1 << 160), "040x")


def decode_address(raw):
    return "0x" + raw[-40:].lower()


def main():
    aliases = {chain: alias(config["portal"]) for chain, config in CHAINS.items()}
    identities = []
    destinations = []
    calls = 0
    for destination, config in CHAINS.items():
        url = config["rpc"]
        calls += 1
        chain_id = int(rpc(url, "eth_chainId", [], calls), 16)
        if config["block"] is None:
            calls += 1
            block = int(rpc(url, "eth_blockNumber", [], calls), 16)
        else:
            block = config["block"]
        tag = hex(block)
        calls += 1
        owner = decode_address(
            rpc(url, "eth_call", [{"to": L2_PROXY_ADMIN, "data": OWNER_SELECTOR}, tag], calls)
        )
        calls += 1
        recorded_owner = decode_address(
            rpc(url, "eth_call", [{"to": L1_BLOCK, "data": PROXY_ADMIN_OWNER_SELECTOR}, tag], calls)
        )
        destinations.append(
            {
                "destination": destination,
                "rpc": url,
                "block": block,
                "chain_id": chain_id,
                "l2_proxy_admin_owner": owner,
                "l1_block_proxy_admin_owner": recorded_owner,
                "depositor_account": DEPOSITOR,
            }
        )
        for source, address in aliases.items():
            calls += 1
            balance = int(rpc(url, "eth_getBalance", [address, tag], calls), 16)
            calls += 1
            code = rpc(url, "eth_getCode", [address, tag], calls)
            identities.append(
                {
                    "source_portal": source,
                    "destination_l2": destination,
                    "alias": address,
                    "balance": balance,
                    "code_bytes": (len(code) - 2) // 2,
                    "is_proxy_admin_owner": address == owner,
                    "is_recorded_proxy_admin_owner": address == recorded_owner,
                    "is_depositor": address == DEPOSITOR,
                    "is_proxy_admin": address == L2_PROXY_ADMIN,
                }
            )

    result = {
        "method": {
            "safety": "read-only eth_chainId/eth_blockNumber/eth_call/eth_getBalance/eth_getCode",
            "op_block_is_pinned": True,
            "other_blocks_are_recorded_latest": True,
            "alias_offset": hex(ALIAS_OFFSET),
            "rpc_calls": calls,
        },
        "portal_aliases": aliases,
        "destinations": destinations,
        "identity_matrix": identities,
        "nonzero_balance_count": sum(item["balance"] != 0 for item in identities),
        "code_present_count": sum(item["code_bytes"] != 0 for item in identities),
        "privileged_identity_count": sum(
            item["is_proxy_admin_owner"]
            or item["is_recorded_proxy_admin_owner"]
            or item["is_depositor"]
            or item["is_proxy_admin"]
            for item in identities
        ),
    }
    OUT.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(
        f"matrix={len(identities)} nonzero_balance={result['nonzero_balance_count']} "
        f"code={result['code_present_count']} privileged={result['privileged_identity_count']} calls={calls}"
    )
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
