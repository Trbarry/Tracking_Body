#!/usr/bin/env python3
"""Read every zero-argument address getter on the 41 U21 proxy contracts.

The contract list and initializer-derived expectations come only from this lane's
decoded execution trace.  Reads are made at block N and at the later comparison
block; no state-changing RPC method is used.
"""

import json
import subprocess
from pathlib import Path


ROOT = Path("/home/user/Tracking_Body/optimism-u21-novel-hunt")
INIT_PATH = ROOT / "mirror/lane-21/artifacts/decoded-initializers.json"
ARTIFACT_ROOT = Path(
    "/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/forge-artifacts"
)

SAFE = "0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a"
SUPERCHAIN_CONFIG = "0x95703e0982140d16f8eba6d158fccede42f04a4c"
GUARDIAN = "0x09f7150d8c019bef34450d6920f6b3608cefdaf2"
OPCM = "0x2d91e6f2bcf6cd1df90e1faf9714e18705ea331f"
DEAD = "0x000000000000000000000000000000000000dead"
L2_XDM = "0x4200000000000000000000000000000000000007"
L2_STANDARD_BRIDGE = "0x4200000000000000000000000000000000000010"
L2_ERC721_BRIDGE = "0x4200000000000000000000000000000000000014"

ENDPOINTS = {
    "N": ("http://127.0.0.1:8547", 26430859),
    "later": ("http://127.0.0.1:8545", 26433900),
}


def call(address: str, signature: str, endpoint: str, block: int) -> str:
    proc = subprocess.run(
        [
            "cast",
            "call",
            address,
            signature,
            "--rpc-url",
            endpoint,
            "--block",
            str(block),
        ],
        check=False,
        text=True,
        capture_output=True,
    )
    if proc.returncode:
        return "ERROR: " + (proc.stderr.strip() or proc.stdout.strip())
    return proc.stdout.strip().split()[0]


def address_getters(contract: str) -> list[str]:
    artifact = ARTIFACT_ROOT / f"{contract}.sol/{contract}.json"
    abi = json.loads(artifact.read_text())["abi"]
    names = {
        item["name"]
        for item in abi
        if item.get("type") == "function"
        and len(item.get("inputs", [])) == 0
        and len(item.get("outputs", [])) > 0
        and item["outputs"][0].get("type") == "address"
    }
    return sorted(names)


def build_expected(chain: str, contract: str, contracts: dict, proxy_admin: str, init: dict) -> dict:
    own = lambda name: contracts[name].lower()
    common = {"proxyAdmin": proxy_admin.lower(), "proxyAdminOwner": SAFE}
    if contract == "SuperchainConfig":
        return {**common, "guardian": GUARDIAN}
    if contract == "SystemConfig":
        return {
            **common,
            "delayedWETH": own("DelayedWETH"),
            "disputeGameFactory": own("DisputeGameFactory"),
            "guardian": GUARDIAN,
            "l1CrossDomainMessenger": own("L1CrossDomainMessenger"),
            "l1ERC721Bridge": own("L1ERC721Bridge"),
            "l1StandardBridge": own("L1StandardBridge"),
            "lastUsedOPCM": OPCM,
            "optimismMintableERC20Factory": own("OptimismMintableERC20Factory"),
            "optimismPortal": own("OptimismPortal2"),
            "owner": init["initializer_args"][0].lower(),
            "superchainConfig": SUPERCHAIN_CONFIG,
            "unsafeBlockSigner": init["initializer_args"][5].lower(),
        }
    if contract == "OptimismPortal2":
        return {
            **common,
            "anchorStateRegistry": own("AnchorStateRegistry"),
            "disputeGameFactory": own("DisputeGameFactory"),
            "ethLockbox": own("ETHLockbox"),
            "guardian": GUARDIAN,
            "l2Sender": DEAD,
            "superchainConfig": SUPERCHAIN_CONFIG,
            "systemConfig": own("SystemConfig"),
        }
    if contract == "ETHLockbox":
        return {**common, "guardian": GUARDIAN, "superchainConfig": SUPERCHAIN_CONFIG}
    if contract == "L1CrossDomainMessenger":
        return {
            **common,
            "OTHER_MESSENGER": L2_XDM,
            "PORTAL": own("OptimismPortal2"),
            "otherMessenger": L2_XDM,
            "portal": own("OptimismPortal2"),
            "superchainConfig": SUPERCHAIN_CONFIG,
            "systemConfig": own("SystemConfig"),
            "xDomainMessageSender": DEAD,
        }
    if contract == "L1StandardBridge":
        return {
            **common,
            "MESSENGER": own("L1CrossDomainMessenger"),
            "OTHER_BRIDGE": L2_STANDARD_BRIDGE,
            "l2TokenBridge": L2_STANDARD_BRIDGE,
            "messenger": own("L1CrossDomainMessenger"),
            "otherBridge": L2_STANDARD_BRIDGE,
            "superchainConfig": SUPERCHAIN_CONFIG,
            "systemConfig": own("SystemConfig"),
        }
    if contract == "L1ERC721Bridge":
        return {
            **common,
            "MESSENGER": own("L1CrossDomainMessenger"),
            "OTHER_BRIDGE": L2_ERC721_BRIDGE,
            "messenger": own("L1CrossDomainMessenger"),
            "otherBridge": L2_ERC721_BRIDGE,
            "superchainConfig": SUPERCHAIN_CONFIG,
            "systemConfig": own("SystemConfig"),
        }
    if contract == "OptimismMintableERC20Factory":
        return {
            **common,
            "BRIDGE": own("L1StandardBridge"),
            "bridge": own("L1StandardBridge"),
        }
    if contract == "DisputeGameFactory":
        return {**common, "owner": SAFE}
    if contract == "DelayedWETH":
        return {**common, "config": SUPERCHAIN_CONFIG, "ethLockbox": own("ETHLockbox")}
    if contract == "AnchorStateRegistry":
        return {
            **common,
            "anchorGame": None,
            "disputeGameFactory": own("DisputeGameFactory"),
            "ethLockbox": own("ETHLockbox"),
            "superchainConfig": SUPERCHAIN_CONFIG,
        }
    raise AssertionError((chain, contract))


def main() -> None:
    initializers = json.loads(INIT_PATH.read_text())
    by_chain: dict[str, dict[str, str]] = {}
    init_by_key: dict[tuple[str, str], dict] = {}
    proxy_admins: dict[str, str] = {}
    for row in initializers:
        by_chain.setdefault(row["chain"], {})[row["contract"]] = row["target"]
        init_by_key[(row["chain"], row["contract"])] = row
        proxy_admins[row["chain"]] = row["proxy_admin"]

    result = {
        "method": "all zero-input ABI functions whose first output is address",
        "blocks": {name: block for name, (_, block) in ENDPOINTS.items()},
        "contracts": [],
        "summary": {},
    }

    failures = []
    changed = []
    for row in initializers:
        chain = row["chain"]
        contract = row["contract"]
        contracts = by_chain[chain] if chain != "Superchain" else by_chain["Superchain"]
        if chain == "Superchain":
            contracts = {"SuperchainConfig": SUPERCHAIN_CONFIG}
        expected = build_expected(chain, contract, contracts, row["proxy_admin"], row)
        out = {
            "chain": chain,
            "contract": contract,
            "address": row["target"],
            "getters": {},
        }
        for getter in address_getters(contract):
            values = {
                name: call(row["target"], f"{getter}()(address)", endpoint, block)
                for name, (endpoint, block) in ENDPOINTS.items()
            }
            want = expected[getter]
            n_lower = values["N"].lower()
            status = "semantic-check" if want is None else ("ok" if n_lower == want else "mismatch")
            stable = values["N"].lower() == values["later"].lower()
            if status == "mismatch":
                failures.append(f"{chain}/{contract}.{getter}")
            if not stable:
                changed.append(f"{chain}/{contract}.{getter}")
            out["getters"][getter] = {
                "expected": want,
                "N": values["N"],
                "later": values["later"],
                "status": status,
                "stable_to_later": stable,
            }

        if contract == "AnchorStateRegistry":
            anchor = out["getters"]["anchorGame"]["N"]
            if anchor.lower() == "0x0000000000000000000000000000000000000000":
                anchor_semantic = "zero: registry uses initialized startingAnchorRoot"
            else:
                registered = call(
                    row["target"],
                    f"isGameRegistered(address)(bool) {anchor}",
                    ENDPOINTS["N"][0],
                    ENDPOINTS["N"][1],
                )
                anchor_semantic = f"nonzero; isGameRegistered={registered}"
            out["anchor_game_semantic"] = anchor_semantic
        result["contracts"].append(out)

    getter_count = sum(len(c["getters"]) for c in result["contracts"])
    result["summary"] = {
        "contract_count": len(result["contracts"]),
        "getter_count": getter_count,
        "expectation_mismatches": failures,
        "changes_N_to_later": changed,
    }
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
