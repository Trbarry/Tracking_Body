#!/usr/bin/env python3
"""Decode all 307 U21 receipt logs and attribute each to its OPCMv2 instruction."""

import json
import subprocess
from collections import defaultdict
from pathlib import Path


RECEIPT = Path("/home/user/Tracking_Body/optimism-u21-novel-hunt/evidence/u21-upgrade-receipt.json")
INITS = Path("/home/user/Tracking_Body/optimism-u21-novel-hunt/mirror/lane-21/artifacts/decoded-initializers.json")

TOPICS = {
    "0x1d2b0bda21d56b8bd12d4f94ebacffdfb35f5e226f84b461103bb8beab6353be": "SystemConfig.ConfigUpdate",
    "0x442e715f626346e8c54381002da614f62bee8d27386535b2521ec8540898556e": "Safe.ExecutionSuccess",
    "0x74d6665c4b26d5596a5aa13d3014e0c06af4d322075a797f87b03cd4c5bc91ca": "DisputeGameFactory.InitBondUpdated",
    "0x7b743789cff01dafdeae47739925425aab5dfd02d0c8229e4a508bcd2b9f42bb": "SuperchainConfig.ConfigUpdate",
    "0x7f26b83ff96e1f2b6a682f133852f6798a09c465da95921460cefb3847402498": "Initialized",
    "0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0": "OwnershipTransferred",
    "0x90a7fac2e56aebe4889351fb04eda5efb28b19dedf288bdbfd3cfd817c79630f": "ETHLockbox.PortalAuthorized",
    "0x9416a153a346f93d95f94b064ae3f148b6460473c6e82b3f9fc2521b873fcd6c": "AddressManager.AddressSet",
    "0xa47fcdf075d680d3817bfca7973b373e1a5f6cfc3b444748299cc2b83d8348f9": "DisputeGameFactory.ImplementationArgsSet",
    "0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b": "Proxy.Upgraded",
    "0xff513d80e2c7fa487608f70a618dfbc0cf415699dc69588c747e8c71566c88de": "DisputeGameFactory.ImplementationSet",
}

SYSTEM_UPDATE_TYPES = {0: "BATCHER", 1: "FEE_SCALARS", 2: "GAS_LIMIT", 3: "UNSAFE_BLOCK_SIGNER",
                       4: "EIP_1559_PARAMS", 5: "OPERATOR_FEE_PARAMS", 6: "MIN_BASE_FEE",
                       7: "DA_FOOTPRINT_GAS_SCALAR"}

ADDRESS_MANAGERS = {
    "0xde1fcfb0851916ca5101820a69b13a4e276bd81f": "OP Mainnet",
    "0x9b7c9bbd6d540a8a4dedd935819fc4408ba71153": "Ink",
    "0xb24bfeece1b3b7a44559f4cbc21bed312b130b70": "Soneium",
    "0x8098f676033a377b9defe302e9fe6877cd63d575": "Unichain",
}


def address(word):
    return "0x" + word[-40:]


def abi_decode(outputs, data):
    raw = subprocess.check_output(
        ["cast", "abi-decode", "--json", f"f()({outputs})", data], text=True
    )
    return json.loads(raw)


initializers = json.loads(INITS.read_text())
targets = {
    item["target"].lower(): {"chain": item["chain"], "contract": item["contract"]}
    for item in initializers
}
targets["0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a"] = {"chain": "governance", "contract": "Safe"}

receipt = json.loads(RECEIPT.read_text())
occurrences = defaultdict(int)
decoded = []
for log in receipt["logs"]:
    emitter = log["address"].lower()
    topic0 = log["topics"][0]
    event = TOPICS[topic0]
    info = targets.get(emitter, {})
    chain = info.get("chain") or ADDRESS_MANAGERS.get(emitter)
    contract = info.get("contract") or ("AddressManager" if emitter in ADDRESS_MANAGERS else None)
    args = {}
    instruction = ""

    if event == "Proxy.Upgraded":
        args = {"implementation": address(log["topics"][1])}
        phase = occurrences[(emitter, event)] % 4
        instruction = [
            "OPContractsManagerUtils.upgrade: ProxyAdmin.upgrade to StorageSetter",
            "OPContractsManagerUtils.upgrade: ProxyAdmin.upgradeAndCall to real implementation",
            "OPContractsManagerUtils.upgrade: ProxyAdmin.upgrade to StorageSetter for post-init OZ-v5 check",
            "OPContractsManagerUtils.upgrade: ProxyAdmin.upgrade restores real implementation",
        ][phase]
    elif event == "AddressManager.AddressSet":
        new_address, old_address = abi_decode("address,address", log["data"])
        args = {"name_hash": log["topics"][1], "newAddress": new_address, "oldAddress": old_address}
        phase = occurrences[(emitter, event)] % 4
        instruction = [
            "OPContractsManagerUtils.upgrade: resolved proxy implementation -> StorageSetter",
            "OPContractsManagerUtils.upgrade: resolved proxy implementation -> real implementation before initializer",
            "OPContractsManagerUtils.upgrade: resolved proxy implementation -> StorageSetter for post-init OZ-v5 check",
            "OPContractsManagerUtils.upgrade: resolved proxy implementation restored to real implementation",
        ][phase]
        contract = "L1CrossDomainMessenger via AddressManager"
    elif event == "Initialized":
        args = {"version": int(log["data"], 16)}
        instruction = f"{contract}.initialize inside ProxyAdmin.upgradeAndCall"
    elif event == "OwnershipTransferred":
        args = {"previousOwner": address(log["topics"][1]), "newOwner": address(log["topics"][2])}
        instruction = f"{contract}.initialize: __Ownable_init / transferOwnership"
    elif event == "SystemConfig.ConfigUpdate":
        update_type = int(log["topics"][2], 16)
        args = {"version": int(log["topics"][1], 16), "updateType": update_type,
                "updateTypeName": SYSTEM_UPDATE_TYPES.get(update_type), "data": abi_decode("bytes", log["data"])[0]}
        instruction = "SystemConfig.initialize: ordered _setBatcherHash/_setGasConfigEcotone/_setGasLimit"
    elif event == "SuperchainConfig.ConfigUpdate":
        args = {"updateType": int(log["topics"][1], 16), "updateTypeName": "GUARDIAN",
                "data": abi_decode("bytes", log["data"])[0]}
        instruction = "SuperchainConfig.initialize: _setGuardian"
    elif event == "ETHLockbox.PortalAuthorized":
        args = {"portal": address(log["topics"][1])}
        instruction = "ETHLockbox.initialize: authorize portal"
    elif event == "DisputeGameFactory.ImplementationSet":
        args = {"impl": address(log["topics"][1]), "gameType": int(log["topics"][2], 16)}
        instruction = "OPContractsManagerV2._apply: DisputeGameFactory.setImplementation"
    elif event == "DisputeGameFactory.ImplementationArgsSet":
        args = {"gameType": int(log["topics"][1], 16), "args": abi_decode("bytes", log["data"])[0]}
        instruction = "OPContractsManagerV2._apply: DisputeGameFactory.setImplementation arguments"
    elif event == "DisputeGameFactory.InitBondUpdated":
        args = {"gameType": int(log["topics"][1], 16), "newBond": int(log["topics"][2], 16)}
        instruction = "OPContractsManagerV2._apply: DisputeGameFactory.setInitBond"
    elif event == "Safe.ExecutionSuccess":
        tx_hash, payment = abi_decode("bytes32,uint256", log["data"])
        args = {"txHash": tx_hash, "payment": payment}
        instruction = "Safe.execTransaction completion"

    occurrences[(emitter, event)] += 1
    decoded.append({
        "receipt_position": len(decoded),
        "log_index": int(log["logIndex"], 16),
        "emitter": log["address"],
        "chain": chain,
        "contract": contract,
        "event": event,
        "args": args,
        "instruction": instruction,
        "raw_topics": log["topics"],
        "raw_data": log["data"],
    })

assert len(decoded) == 307, len(decoded)
assert all(item["instruction"] for item in decoded)
print(json.dumps(decoded, indent=2))
