#!/usr/bin/env python3
"""Extract and decode every ProxyAdmin.upgradeAndCall from the U21 call trace."""

import json
import subprocess
from pathlib import Path


TRACE = Path("/home/user/Tracking_Body/optimism-u21-novel-hunt/mirror/lane-21/traces/u21-call-trace-upstream.json")

GROUPS = {
    "SuperchainConfig": ["95703e0982140d16f8eba6d158fccede42f04a4c"],
    "SystemConfig": [
        "229047fed2591dbec1ef1118d64f7af3db9eb290", "62c0a111929fa32cec2f76adba54c16afb6e8364",
        "7a8ed66b319911a0f3e7288bddab30d9c0c875c3", "c407398d063f942febbcc6f80a156b47f3f1bda6",
    ],
    "OptimismPortal2": [
        "beb5fc579115071764c7423a4f12edde41f106ed", "5d66c1782664115999c47c9fa5cd031f495d3e4f",
        "88e529a6ccd302c948689cd5156c83d4614fae92", "0bd48f6b86a26d3a217d0fa6ffe2b491b956a7a2",
    ],
    "ETHLockbox": [
        "322b47ff1fa8d5611f761e3e275c45b71b294d43", "bd4abb321138e8eddc399ce64e66451294325a14",
        "67b4de6ffa66ef201ea6099a89ca397d56622e31", "08ba0023ed60c7bd040716dd13c45fa0062df5c5",
    ],
    "L1CrossDomainMessenger": [
        "25ace71c97b33cc4729cf772ae268934f7ab5fa1", "69d3cf86b2bf1a9e99875b7e2d9b6a84426c171f",
        "9cf951e3f74b644e621b36ca9cea147a78d4c39f", "9a3d64e386c18cb1d6d5179a9596a4b5736e98a6",
    ],
    "L1StandardBridge": [
        "99c9fc46f92e8a1c0dec1b1747d010903e884be1", "88ff1e5b602916615391f55854588efcbb7663f0",
        "eb9bf100225c214efc3e7c651ebbadcf85177607", "81014f44b0a345033bb2b3b21c7a1a308b35feea",
    ],
    "L1ERC721Bridge": [
        "5a7749f83b81b301cab5f48eb8516b986daef23d", "661235a238b11191211fa95d4dd9e423d521e0be",
        "5933e323be8896dfacd1cd671442f27daa10a053", "d04d0d87e0bd4d2e50286760a3ef323fea6849cf",
    ],
    "OptimismMintableERC20Factory": [
        "75505a97bd334e7bd3c476893285569c4136fa0f", "a8b389a82e088b164cd03230e900980cced34d29",
        "c1047e30efc9e172cfe7aa0219895b6a43fc415f", "a2b597eaeacb6f627e088cbead319e934ed5edad",
    ],
    "DisputeGameFactory": [
        "e5965ab5962edc7477c8520243a95517cd252fa9", "10d7b35078d3baabb96dd45a9143b94be65b12cd",
        "512a3d2c7a43bd9261d2b8e8c9c70d4bd4d503c0", "2f12d621a16e2d3285929c9996f478508951dfe4",
    ],
    "DelayedWETH": [
        "1b6dbf05eaf22d4e70dc993e8a19dd9f3dcb3162", "57b4c29daee99a28e6e86778b499361294c134ea",
        "18fbb58c366e21f395ddec7cba0510a2d9116b47", "74ad145ac900f1dd5551f0c9e143314dc4022fcf",
    ],
    "AnchorStateRegistry": [
        "23b2c62946350f4246f9f9d027e071f0264fd113", "ee018baf058227872540ac60efbd38b023d9dae2",
        "4890928941e62e273da359374b105f803329f473", "27cf508e4e3aa8d30b3226ac3b5ea0e8bcacaff9",
    ],
}

NAMES = {address: name for name, addresses in GROUPS.items() for address in addresses}
CHAINS = {
    GROUPS[name][i]: chain
    for name in GROUPS
    if name != "SuperchainConfig"
    for i, chain in enumerate(["OP Mainnet", "Ink", "Soneium", "Unichain"])
}
CHAINS[GROUPS["SuperchainConfig"][0]] = "Superchain"

SIGS = {
    "SuperchainConfig": "initialize(address)",
    "SystemConfig": "initialize(address,uint32,uint32,bytes32,uint64,address,(uint32,uint8,uint8,uint32,uint32,uint128),(address,address,address,address,address,address,address),uint256,address)",
    "OptimismPortal2": "initialize(address,address,address)",
    "ETHLockbox": "initialize(address,address[])",
    "L1CrossDomainMessenger": "initialize(address,address)",
    "L1StandardBridge": "initialize(address,address)",
    "L1ERC721Bridge": "initialize(address,address)",
    "OptimismMintableERC20Factory": "initialize(address)",
    "DisputeGameFactory": "initialize(address)",
    "DelayedWETH": "initialize(address)",
    "AnchorStateRegistry": "initialize(address,address,(bytes32,uint256),uint32)",
}


def calls(node):
    if isinstance(node, dict):
        if node.get("input", "").startswith("0x9623609d"):
            yield node
        for child in node.get("calls", []):
            yield from calls(child)


def decode(signature, calldata):
    out = subprocess.check_output(
        ["cast", "calldata-decode", "--json", signature, calldata], text=True
    )
    return json.loads(out)


trace = json.loads(TRACE.read_text())
decoded = []
for index, call in enumerate(calls(trace)):
    target, implementation, initializer = decode("upgradeAndCall(address,address,bytes)", call["input"])
    target_key = target.lower().removeprefix("0x")
    name = NAMES[target_key]
    decoded.append(
        {
            "sequence": index,
            "chain": CHAINS[target_key],
            "proxy_admin": call["to"],
            "contract": name,
            "target": target,
            "implementation": implementation,
            "initializer_selector": initializer[:10],
            "initializer_signature": SIGS[name],
            "initializer_args": decode(SIGS[name], initializer),
            "initializer_calldata": initializer,
        }
    )

assert len(decoded) == 41, len(decoded)
print(json.dumps(decoded, indent=2))
