#!/usr/bin/env python3
"""Condense raw pre/post upgrade dumps into direct-slot liveness and initializer histories."""

from __future__ import annotations

import json
import math
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
HISTORY_PATH = ROOT / "evidence/op-mainnet-storage-history.json"
LINEAGE_PATH = ROOT / "storage-lineage.json"
OUT = ROOT / "evidence/direct-slot-liveness.json"
ZERO_WORD = "0x" + "00" * 32
ZERO_ADDRESS = "0x" + "00" * 20


def source_family(deployment: str) -> str:
    name = deployment.split(".")[0]
    if name == "OptimismPortal":
        return "OptimismPortal2"
    return name


def v9_meanings(lineage: dict, deployment: str, slot: int) -> list[dict]:
    family = source_family(deployment)
    contract = lineage["contracts"].get(family)
    if not contract:
        return []
    release = contract["releases"].get("v9.0.0")
    if not release or not release.get("exists"):
        return []
    meanings = []
    for field in release["fields"]:
        start = int(field["slot"])
        span = max(1, math.ceil(int(field["bytes"]) / 32))
        if start <= slot < start + span:
            meanings.append({
                "label": field["label"],
                "type": field["type"],
                "offset": int(field["offset"]) if slot == start else 0,
                "array_or_gap_slot_delta": slot - start,
            })
    return meanings


def checkpoints(dumps: list[dict]) -> list[dict]:
    out = []
    for item in dumps:
        transition = item["transition"]
        out.append({"block": item["before"]["block"], "phase": "before", "transition_block": transition["block"], "state": item["before"]})
        out.append({"block": item["after"]["block"], "phase": "after", "transition_block": transition["block"], "state": item["after"]})
    return out


def main() -> None:
    history = json.loads(HISTORY_PATH.read_text())
    lineage = json.loads(LINEAGE_PATH.read_text())
    deployments = {}
    initializer_histories = {}

    for deployment, dumps in history["pre_post_slot_dumps"].items():
        points = checkpoints(dumps)
        slots = sorted({int(slot) for point in points for slot in point["state"]["slots"]})
        liveness = []
        for slot in slots:
            observations = []
            previous = None
            ever_nonzero = False
            for point in points:
                value = point["state"]["slots"].get(str(slot), ZERO_WORD)
                ever_nonzero |= value != ZERO_WORD
                if value != previous:
                    observations.append({
                        "block": point["block"],
                        "phase": point["phase"],
                        "transition_block": point["transition_block"],
                        "value": value,
                        "classification": (
                            "first_observation" if previous is None else
                            "cleared" if value == ZERO_WORD else
                            "written_or_changed"
                        ),
                    })
                    previous = value
            if ever_nonzero:
                liveness.append({
                    "slot": slot,
                    "v9_meanings": v9_meanings(lineage, deployment, slot),
                    "observed_changes": observations,
                    "value_at_last_upgrade_checkpoint": previous,
                })
        deployments[deployment] = {
            "upgrade_boundary_checkpoint_count": len(points),
            "ever_nonzero_numbered_slots_at_upgrade_boundaries": liveness,
            "special_slots_each_boundary": [
                {
                    "block": point["block"],
                    "phase": point["phase"],
                    **point["state"]["special_slots"],
                }
                for point in points
            ],
        }

        initializer_offset = 20 if deployment == "L1CrossDomainMessenger" else 0
        initializer_histories[deployment] = [
            {
                "block": item["transition"]["block"],
                "transaction_hashes": item["transition"].get("transactions", []),
                "implementation_before": item["transition"]["before"],
                "implementation_after": item["transition"]["after"],
                "version_before": item["before"].get("version"),
                "version_after": item["after"].get("version"),
                "initializer_slot": 0,
                "initializer_offset": initializer_offset,
                "initializer_before": item["before"]["initializer_bytes"][f"offset_{initializer_offset}"],
                "initializer_after": item["after"]["initializer_bytes"][f"offset_{initializer_offset}"],
                "zero_at_expected_later_initializer_byte_post_block": (
                    item["transition"]["after"] != ZERO_ADDRESS
                    and item["after"]["initializer_bytes"][f"offset_{initializer_offset}"] == 0
                ),
            }
            for item in dumps
        ]

    zero_implementation_windows = []
    for deployment, transitions in history["persistent_implementation_transitions"].items():
        creation = history["creation_blocks"].get(deployment)
        if creation is not None and transitions:
            first = transitions[0]
            if first["block"] > creation and first["before"] == ZERO_ADDRESS:
                zero_implementation_windows.append({
                    "deployment": deployment,
                    "from_block_inclusive": creation,
                    "to_block_inclusive": first["block"] - 1,
                    "next_implementation_block": first["block"],
                    "kind": "staged_initial_proxy",
                    "assessment": "No implementation target: proxy calls revert rather than delegatecall into uninitialized logic.",
                })
        for index, transition in enumerate(transitions):
            if transition["after"] == ZERO_ADDRESS:
                next_nonzero = next(
                    (item for item in transitions[index + 1:] if item["after"] != ZERO_ADDRESS), None
                )
                zero_implementation_windows.append({
                    "deployment": deployment,
                    "from_block_inclusive": transition["block"],
                    "to_block_inclusive": next_nonzero["block"] - 1 if next_nonzero else history["block_cutoff"],
                    "next_implementation_block": next_nonzero["block"] if next_nonzero else None,
                    "kind": "implementation_removed_then_restored_later",
                    "assessment": "No implementation target: proxy calls revert rather than delegatecall into uninitialized logic.",
                })

    OUT.write_text(json.dumps({
        "method": {
            "scope": "Numbered direct slots in the first 80 plus contract-specific high slots, at every pre/post implementation-change boundary.",
            "caveat": "'Ever non-zero' here is exact for the requested upgrade-boundary snapshots. Runtime writes and clears wholly between two upgrades require event/mapping archaeology and are not inferred from checkpoints.",
        },
        "deployments": deployments,
        "initializer_histories": initializer_histories,
        "zero_implementation_windows": zero_implementation_windows,
        "direct_nonproxied_current": history["direct_and_special"],
    }, indent=2) + "\n")
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
