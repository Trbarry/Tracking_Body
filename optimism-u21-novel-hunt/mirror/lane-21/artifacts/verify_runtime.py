#!/usr/bin/env python3
"""Compare deployed U21 implementation runtimes with the pinned v9 build.

Immutable byte ranges are zeroed in both inputs before comparison. This script
performs only eth_getCode-style reads through `cast code`.
"""

import json
import subprocess
from pathlib import Path


ROOT = Path("/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/forge-artifacts")
RPC = "http://127.0.0.1:8547"

TARGETS = [
    ("SuperchainConfig", "SuperchainConfig.sol/SuperchainConfig.json", "0xA303a644cfbC0c34f6a9dBEaFdebA4C967EA01e7"),
    ("SystemConfig", "SystemConfig.sol/SystemConfig.json", "0xADe27248542c0F3E89b49e4eB76155e267F14377"),
    ("OptimismPortal2", "OptimismPortal2.sol/OptimismPortal2.json", "0xb20B23af6071405C37dDDA0C0640e8eBb7899645"),
    ("ETHLockbox", "ETHLockbox.sol/ETHLockbox.json", "0xDF75E6b07E98873E36BA5c05508F80c1454e0aFe"),
    ("L1CrossDomainMessenger", "L1CrossDomainMessenger.sol/L1CrossDomainMessenger.json", "0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448"),
    ("L1StandardBridge", "L1StandardBridge.sol/L1StandardBridge.json", "0xB37a11AadF167B2F0b8dD85372De4bC66CD4A891"),
    ("L1ERC721Bridge", "L1ERC721Bridge.sol/L1ERC721Bridge.json", "0x9F164f1d02A81e06D639E55F65a87f0070E3Cb2e"),
    ("OptimismMintableERC20Factory", "OptimismMintableERC20Factory.sol/OptimismMintableERC20Factory.json", "0xaAbEA75Da509fA518Fd8a91Eae4BE5813B829b12"),
    ("DisputeGameFactory", "DisputeGameFactory.sol/DisputeGameFactory.json", "0x72B971717E088B59F26d4236BE222ADB6ACD393b"),
    ("DelayedWETH", "DelayedWETH.sol/DelayedWETH.json", "0xF024e96317907C3b8d8CB346B9FD9034c8640e15"),
    ("AnchorStateRegistry", "AnchorStateRegistry.sol/AnchorStateRegistry.json", "0x2b27299C577d4720100e2735b652444DcEa652D0"),
    ("StorageSetter", "StorageSetter.sol/StorageSetter.json", "0x2476c911e6d4d9411e677d8faf15a64ac1fdeee8"),
]


def zero_ranges(code: bytearray, refs: dict) -> None:
    for entries in refs.values():
        for ref in entries:
            start = ref["start"]
            end = start + ref["length"]
            code[start:end] = b"\x00" * ref["length"]


results = []
for name, artifact_rel, address in TARGETS:
    artifact = json.loads((ROOT / artifact_rel).read_text())
    built = bytearray.fromhex(artifact["deployedBytecode"]["object"].removeprefix("0x"))
    deployed_hex = subprocess.check_output(
        ["cast", "code", address, "--rpc-url", RPC], text=True
    ).strip()
    deployed = bytearray.fromhex(deployed_hex.removeprefix("0x"))
    refs = artifact["deployedBytecode"].get("immutableReferences", {})
    zero_ranges(built, refs)
    zero_ranges(deployed, refs)
    mismatch = next((i for i, (a, b) in enumerate(zip(built, deployed)) if a != b), None)
    if mismatch is None and len(built) != len(deployed):
        mismatch = min(len(built), len(deployed))
    results.append(
        {
            "contract": name,
            "address": address,
            "artifact": str(ROOT / artifact_rel),
            "built_length": len(built),
            "deployed_length": len(deployed),
            "immutable_ranges": sum(len(v) for v in refs.values()),
            "match_ignoring_immutables": mismatch is None,
            "first_mismatch_byte": mismatch,
        }
    )

print(json.dumps(results, indent=2))
