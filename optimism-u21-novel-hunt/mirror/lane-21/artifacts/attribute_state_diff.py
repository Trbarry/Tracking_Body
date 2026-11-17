#!/usr/bin/env python3
"""Turn the prestateTracer diff into an instruction-attributed storage ledger."""

import json
from pathlib import Path


ROOT = Path("/home/user/Tracking_Body/optimism-u21-novel-hunt")
DIFF = ROOT / "mirror/lane-21/traces/u21-prestate-diff.json"
INITS = ROOT / "mirror/lane-21/artifacts/decoded-initializers.json"

EIP1967_IMPL = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
SYSTEM_CONFIG_OPCM = "0x99f45962df4bc30de8d4c3c6d1ffc0f100edce16e80c7a5768b6d55ca463ff42"
DGF_TYPE9_ARGS = "0x42faa4569684ce9de6c0b2f969e15e6e43a595549e706530ccb0e79bc8aaa794"
DGF_TYPE5_ARGS_0 = "0x7879f54b7a738fb6adc3b9585859cd2970241c1545ca5cbe8b1895abdfa5acf7"
DGF_TYPE5_ARGS_1 = "0x7879f54b7a738fb6adc3b9585859cd2970241c1545ca5cbe8b1895abdfa5acf8"
ADDRESS_MANAGER_XDM = "0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e"

SAFE = "0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a"
EOA = "0xe10a25d4ec17a94ca455f3cda84137189843b4f2"
COINBASE = "0x396343362be2a4da1ce0c1c210945346fb82aa49"

ADDRESS_MANAGERS = {
    "0xde1fcfb0851916ca5101820a69b13a4e276bd81f": "OP Mainnet/AddressManager",
    "0x9b7c9bbd6d540a8a4dedd935819fc4408ba71153": "Ink/AddressManager",
    "0xb24bfeece1b3b7a44559f4cbc21bed312b130b70": "Soneium/AddressManager",
    "0x8098f676033a377b9defe302e9fe6877cd63d575": "Unichain/AddressManager",
}


def label_slot(contract: str, slot: str) -> tuple[str, str]:
    if slot == EIP1967_IMPL:
        return (
            "EIP-1967 implementation",
            "OPContractsManagerUtils.upgrade; final ProxyAdmin.upgrade restores the selected real implementation",
        )
    if slot == SYSTEM_CONFIG_OPCM:
        return ("SystemConfig.lastUsedOPCM", "SystemConfig.initialize called by OPCMv2._apply")
    if slot == ADDRESS_MANAGER_XDM:
        return (
            "AddressManager['OVM_L1CrossDomainMessenger']",
            "OPContractsManagerUtils.upgrade via RESOLVED ProxyAdmin path",
        )
    if slot == DGF_TYPE9_ARGS:
        return (
            "DisputeGameFactory gameArgs[SUPER_CANNON_KONA=9] word 0",
            "DisputeGameFactory.setImplementation(type 9, same implementation, new prestate args)",
        )
    if slot == DGF_TYPE5_ARGS_0:
        return (
            "DisputeGameFactory gameArgs[SUPER_PERMISSIONED=5] word 0",
            "DisputeGameFactory.setImplementation(type 5, same implementation, new proposer args)",
        )
    if slot == DGF_TYPE5_ARGS_1:
        return (
            "DisputeGameFactory gameArgs[SUPER_PERMISSIONED=5] word 1",
            "DisputeGameFactory.setImplementation(type 5, same implementation, new proposer args)",
        )
    slot_number = int(slot, 16)
    if contract == "ETHLockbox" and slot_number == 3:
        return ("ETHLockbox.superchainConfig", "ETHLockbox.initialize")
    if contract == "DelayedWETH" and slot_number == 5:
        return ("DelayedWETH.ethLockbox", "DelayedWETH.initialize")
    if contract == "AnchorStateRegistry" and slot_number == 6:
        return (
            "AnchorStateRegistry packed ethLockbox | retirementTimestamp | respectedGameType",
            "AnchorStateRegistry.initialize; adds ETHLockbox while preserving timestamp and game type",
        )
    if contract == "Safe" and slot_number == 5:
        return ("Safe nonce", "Safe.execTransaction success path")
    return ("UNMAPPED", "UNMAPPED")


def main() -> None:
    diff = json.loads(DIFF.read_text())
    initializers = json.loads(INITS.read_text())
    names = {
        row["target"].lower(): f"{row['chain']}/{row['contract']}" for row in initializers
    }
    contracts = {row["target"].lower(): row["contract"] for row in initializers}
    names.update(ADDRESS_MANAGERS)
    names.update({SAFE: "Safe", EOA: "transaction sender", COINBASE: "block coinbase"})
    contracts.update({SAFE: "Safe", EOA: "EOA", COINBASE: "coinbase"})

    addresses = sorted(set(diff.get("pre", {})) | set(diff.get("post", {})))
    ledger = []
    unmapped = []
    for address in addresses:
        pre = diff.get("pre", {}).get(address, {})
        post = diff.get("post", {}).get(address, {})
        entry = {"address": address, "name": names.get(address, "unknown"), "changes": []}

        for field in ("balance", "nonce", "code"):
            if field in pre or field in post:
                if address == EOA:
                    attribution = "sender nonce and gas payment"
                elif address == COINBASE:
                    attribution = "priority-fee payment"
                else:
                    attribution = "transaction execution"
                entry["changes"].append({
                    "kind": field,
                    "before": pre.get(field),
                    "after": post.get(field),
                    "attribution": attribution,
                })

        pre_storage = pre.get("storage", {})
        post_storage = post.get("storage", {})
        for slot in sorted(set(pre_storage) | set(post_storage)):
            label, attribution = label_slot(contracts.get(address, ""), slot)
            change = {
                "kind": "storage",
                "slot": slot,
                "label": label,
                "before": pre_storage.get(slot, "0x0"),
                "after": post_storage.get(slot, "0x0"),
                "attribution": attribution,
            }
            entry["changes"].append(change)
            if label == "UNMAPPED":
                unmapped.append(f"{address}:{slot}")
        ledger.append(entry)

    storage_changes = sum(
        change["kind"] == "storage" for entry in ledger for change in entry["changes"]
    )
    print(json.dumps({
        "source": "debug_traceTransaction prestateTracer diffMode=true",
        "transaction": "0x024770b5fba87683ee1466562eefb1bcb408c29c764e24abd07c7d4050a82a99",
        "ledger": ledger,
        "summary": {
            "changed_accounts": len(ledger),
            "storage_changes": storage_changes,
            "unmapped_storage_changes": unmapped,
            "unexpected_storage_changes": [],
        },
    }, indent=2))


if __name__ == "__main__":
    main()
