#!/usr/bin/env python3
"""Decode the Safe -> aggregate3 -> OPCMv2 U21 calldata using cast's ABI decoder."""

import json
import subprocess
from pathlib import Path


ROOT = Path("/home/user/Tracking_Body/optimism-u21-novel-hunt")
TX_PATH = ROOT / "evidence/u21-upgrade-tx.json"
RECEIPT_PATH = ROOT / "evidence/u21-upgrade-receipt.json"

SAFE_SIG = "execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)"
AGG_SIG = "aggregate3((address,bool,bytes)[])"
SUPERCHAIN_SIG = "upgradeSuperchain((address,(string,bytes)[]))"
UPGRADE_SIG = "upgrade((address,(bool,uint256,uint32,bytes)[],(string,bytes)[]))"

CHAIN_BY_SYSTEM_CONFIG = {
    "0x229047fed2591dbec1ef1118d64f7af3db9eb290": "OP Mainnet",
    "0x62c0a111929fa32cec2f76adba54c16afb6e8364": "Ink",
    "0x7a8ed66b319911a0f3e7288bddab30d9c0c875c3": "Soneium",
    "0xc407398d063f942febbcc6f80a156b47f3f1bda6": "Unichain",
}


def decode(signature: str, calldata: str):
    proc = subprocess.run(
        ["cast", "calldata-decode", signature, calldata, "--json"],
        check=True,
        text=True,
        capture_output=True,
    )
    return json.loads(proc.stdout)


def main() -> None:
    tx = json.loads(TX_PATH.read_text())
    receipt = json.loads(RECEIPT_PATH.read_text())
    safe = decode(SAFE_SIG, tx["input"])
    aggregate = decode(AGG_SIG, safe[2])[0]

    calls = []
    for index, (target, allow_failure, calldata) in enumerate(aggregate):
        selector = calldata[:10]
        if index == 0:
            decoded = decode(SUPERCHAIN_SIG, calldata)[0]
            calls.append({
                "index": index,
                "target": target,
                "allowFailure": allow_failure,
                "selector": selector,
                "signature": SUPERCHAIN_SIG,
                "superchainConfig": decoded[0],
                "extraInstructions": [
                    {"key": key, "data": data} for key, data in decoded[1]
                ],
            })
            continue

        decoded = decode(UPGRADE_SIG, calldata)[0]
        system_config, games, instructions = decoded
        calls.append({
            "index": index,
            "chain": CHAIN_BY_SYSTEM_CONFIG[system_config.lower()],
            "target": target,
            "allowFailure": allow_failure,
            "selector": selector,
            "signature": UPGRADE_SIG,
            "systemConfig": system_config,
            "disputeGameConfigs": [
                {
                    "enabled": game[0],
                    "initBondWei": game[1],
                    "gameType": game[2],
                    "gameArgs": game[3],
                }
                for game in games
            ],
            "extraInstructions": [
                {"key": key, "data": data} for key, data in instructions
            ],
        })

    out = {
        "transaction": {
            "hash": tx["hash"],
            "blockNumber": int(tx["blockNumber"], 16),
            "transactionIndex": int(tx["transactionIndex"], 16),
            "from": tx["from"],
            "to": tx["to"],
            "value": int(tx["value"], 16),
            "status": int(receipt["status"], 16),
            "gasUsed": int(receipt["gasUsed"], 16),
            "logCount": len(receipt["logs"]),
        },
        "safeExecTransaction": {
            "selector": tx["input"][:10],
            "signature": SAFE_SIG,
            "to": safe[0],
            "value": safe[1],
            "operation": safe[3],
            "operationName": "DELEGATECALL" if safe[3] == 1 else "CALL",
            "safeTxGas": safe[4],
            "baseGas": safe[5],
            "gasPrice": safe[6],
            "gasToken": safe[7],
            "refundReceiver": safe[8],
            "signatures": safe[9],
        },
        "aggregate3": {
            "selector": safe[2][:10],
            "signature": AGG_SIG,
            "callCount": len(calls),
            "calls": calls,
        },
    }
    print(json.dumps(out, indent=2))


if __name__ == "__main__":
    main()
