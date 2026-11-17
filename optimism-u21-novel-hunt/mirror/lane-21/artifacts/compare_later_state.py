#!/usr/bin/env python3
"""Compare all zero-input view getters and balances from block N to 26433900."""

import json
import subprocess
from pathlib import Path


ROOT = Path("/home/user/Tracking_Body/optimism-u21-novel-hunt")
INITS = ROOT / "mirror/lane-21/artifacts/decoded-initializers.json"
ARTIFACT_ROOT = Path(
    "/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/forge-artifacts"
)
ENDPOINTS = {
    "N": ("http://127.0.0.1:8547", 26430859),
    "later": ("http://127.0.0.1:8545", 26433900),
}


def run(args: list[str]) -> str:
    proc = subprocess.run(args, check=False, text=True, capture_output=True)
    if proc.returncode:
        return "ERROR: " + (proc.stderr.strip() or proc.stdout.strip())
    return proc.stdout.strip()


def canonical_type(param: dict) -> str:
    typ = param["type"]
    if not typ.startswith("tuple"):
        return typ
    suffix = typ[len("tuple"):]
    inner = ",".join(canonical_type(component) for component in param["components"])
    return f"({inner}){suffix}"


def getter_signatures(contract: str) -> list[str]:
    path = ARTIFACT_ROOT / f"{contract}.sol/{contract}.json"
    abi = json.loads(path.read_text())["abi"]
    signatures = set()
    for item in abi:
        if (
            item.get("type") == "function"
            and not item.get("inputs")
            and item.get("stateMutability") in ("view", "pure")
        ):
            outputs = ",".join(canonical_type(output) for output in item.get("outputs", []))
            signatures.add(f"{item['name']}()({outputs})")
    return sorted(signatures)


def call(address: str, signature: str, endpoint: str, block: int) -> str:
    return run([
        "cast", "call", address, signature,
        "--rpc-url", endpoint, "--block", str(block),
    ])


def balance(address: str, endpoint: str, block: int) -> str:
    return run([
        "cast", "balance", address,
        "--rpc-url", endpoint, "--block", str(block),
    ])


def main() -> None:
    contracts = json.loads(INITS.read_text())
    output = []
    changed_getters = []
    changed_balances = []
    asymmetric_errors = []
    for contract in contracts:
        address = contract["target"]
        row = {
            "chain": contract["chain"],
            "contract": contract["contract"],
            "address": address,
            "changedGetters": [],
        }
        for signature in getter_signatures(contract["contract"]):
            values = {
                label: call(address, signature, endpoint, block)
                for label, (endpoint, block) in ENDPOINTS.items()
            }
            if values["N"] != values["later"]:
                item = {"signature": signature, **values}
                row["changedGetters"].append(item)
                changed_getters.append(
                    f"{contract['chain']}/{contract['contract']}.{signature}"
                )
            if values["N"].startswith("ERROR:") != values["later"].startswith("ERROR:"):
                asymmetric_errors.append(
                    f"{contract['chain']}/{contract['contract']}.{signature}"
                )
        balances = {
            label: balance(address, endpoint, block)
            for label, (endpoint, block) in ENDPOINTS.items()
        }
        if balances["N"] != balances["later"]:
            row["balance"] = balances
            changed_balances.append(f"{contract['chain']}/{contract['contract']}")
        if row["changedGetters"] or "balance" in row:
            output.append(row)

    print(json.dumps({
        "blocks": {label: block for label, (_, block) in ENDPOINTS.items()},
        "changedContracts": output,
        "summary": {
            "contractsCompared": len(contracts),
            "changedGetterCount": len(changed_getters),
            "changedGetters": changed_getters,
            "changedBalanceCount": len(changed_balances),
            "changedBalances": changed_balances,
            "asymmetricGetterErrors": asymmetric_errors,
        },
    }, indent=2))


if __name__ == "__main__":
    main()
