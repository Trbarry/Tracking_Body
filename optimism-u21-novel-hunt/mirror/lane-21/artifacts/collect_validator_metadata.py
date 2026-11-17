#!/usr/bin/env python3
"""Capture lastUsedOPCM transitions and StandardValidator output at block N."""

import json
import subprocess
from pathlib import Path


ROOT = Path("/home/user/Tracking_Body/optimism-u21-novel-hunt")
TX = ROOT / "mirror/lane-21/artifacts/decoded-transaction.json"
OPCM = "0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f"
ZERO32 = "0x" + "00" * 32
RPC = {
    "pre": ("http://127.0.0.1:8546", 26430858),
    "post": ("http://127.0.0.1:8547", 26430859),
    "later": ("http://127.0.0.1:8545", 26433900),
}
CHAIN_IDS = {"OP Mainnet": 10, "Ink": 57073, "Soneium": 1868, "Unichain": 130}


def call(address: str, signature: str, args: list[str], endpoint: str, block: int) -> str:
    proc = subprocess.run(
        ["cast", "call", address, signature, *args, "--rpc-url", endpoint, "--block", str(block)],
        check=False,
        text=True,
        capture_output=True,
    )
    if proc.returncode:
        return "ERROR: " + (proc.stderr.strip() or proc.stdout.strip())
    return proc.stdout.strip()


def main() -> None:
    tx = json.loads(TX.read_text())
    validator = call(OPCM, "opcmStandardValidator()(address)", [], *RPC["post"]).split()[0]
    bitmap = call(validator, "devFeatureBitmap()(bytes32)", [], *RPC["post"]).split()[0]
    rows = []
    for upgrade in tx["aggregate3"]["calls"][1:]:
        name = upgrade["chain"]
        system = upgrade["systemConfig"]
        game5 = next(game for game in upgrade["disputeGameConfigs"] if game["gameType"] == 5)
        game9 = next(game for game in upgrade["disputeGameConfigs"] if game["gameType"] == 9)
        proposer = "0x" + game5["gameArgs"][-40:]
        kona_prestate = game9["gameArgs"] if game9["enabled"] else ZERO32
        metadata = {}
        for label, (endpoint, block) in RPC.items():
            metadata[label] = {
                "lastUsedOPCM": call(system, "lastUsedOPCM()(address)", [], endpoint, block).split()[0],
                "lastUsedOPCMVersion": call(
                    system, "lastUsedOPCMVersion()(string)", [], endpoint, block
                ),
            }
        validator_input = (
            f"({system},{ZERO32},{kona_prestate},{CHAIN_IDS[name]},{proposer})"
        )
        validation = call(
            validator,
            "validate((address,bytes32,bytes32,uint256,address),bool)(string)",
            [validator_input, "true"],
            *RPC["post"],
        )
        rows.append({
            "chain": name,
            "systemConfig": system,
            "proposer": proposer,
            "cannonKonaPrestate": kona_prestate,
            "metadata": metadata,
            "standardValidatorAllowFailureResult": validation,
        })
    print(json.dumps({
        "opcm": OPCM,
        "standardValidator": validator,
        "standardValidatorDevFeatureBitmap": bitmap,
        "chains": rows,
    }, indent=2))


if __name__ == "__main__":
    main()
