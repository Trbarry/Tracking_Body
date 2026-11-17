#!/usr/bin/env python3
"""Normalize op-contracts storage-layout snapshots from v1.0.0 through v9.0.0.

v1.0.0/v1.1.0 store all layouts in a Markdown file named .storage-layout.
Later releases store one JSON array per contract under snapshots/storageLayout.
The output retains every field, slot, offset, byte width and type and derives
position-level transition labels without consulting any audit material.
"""

from __future__ import annotations

import json
import re
from pathlib import Path


TAGS = [
    "v1.0.0", "v1.1.0", "v1.2.0", "v1.3.0", "v1.4.0", "v1.5.0",
    "v1.6.0", "v1.8.0", "v2.0.0", "v2.1.0", "v2.2.0", "v3.0.0",
    "v3.0.1", "v4.0.0", "v4.1.0", "v5.0.0", "v6.0.0", "v7.0.0",
    "v8.0.0", "v9.0.0",
]

COMMITS = {
    "v1.0.0": "a12a09f7", "v1.1.0": "c383eb88", "v1.2.0": "856c08bf",
    "v1.3.0": "e6ef3a90", "v1.4.0": "547ea72d", "v1.5.0": "9047beb5",
    "v1.6.0": "33f06d2d", "v1.8.0": "2073f405", "v2.0.0": "8d0dd96e",
    "v2.1.0": "e45b33a0", "v2.2.0": "7fe5151a", "v3.0.0": "ef7a933c",
    "v3.0.1": "48e36d5c", "v4.0.0": "54c19f6a", "v4.1.0": "594bc933",
    "v5.0.0": "d09c836f", "v6.0.0": "018f5ae9", "v7.0.0": "a7c88c8d",
    "v8.0.0": "f45a5ccf", "v9.0.0": "ba6fcadb",
}

CONTRACTS = [
    "OptimismPortal", "OptimismPortal2", "L2OutputOracle", "SystemConfig",
    "L1CrossDomainMessenger", "L1StandardBridge", "L1ERC721Bridge",
    "OptimismMintableERC20Factory", "SuperchainConfig", "ProtocolVersions",
    "DisputeGameFactory", "AnchorStateRegistry", "DelayedWETH", "ETHLockbox",
    "AddressManager", "ProxyAdmin", "ResolvedDelegateProxy", "L1ChugSplashProxy",
]

OUT = Path(__file__).resolve().parents[1] / "storage-lineage.json"

# The early snapshot allow-list omitted several compiled contracts. These
# layouts are reconstructed directly from the named release's inheritance and
# declarations (and cross-checked against the first later compiler snapshot).
EARLY_MANUAL_LAYOUTS = {
    ("v1.0.0", "AddressManager"): [
        {"slot": 0, "offset": 0, "bytes": 20, "type": "address", "label": "_owner"},
        {"slot": 1, "offset": 0, "bytes": 32, "type": "mapping(bytes32 => address)", "label": "addresses"},
    ],
    ("v1.1.0", "AddressManager"): [
        {"slot": 0, "offset": 0, "bytes": 20, "type": "address", "label": "_owner"},
        {"slot": 1, "offset": 0, "bytes": 32, "type": "mapping(bytes32 => address)", "label": "addresses"},
    ],
    ("v1.0.0", "ResolvedDelegateProxy"): [
        {"slot": 0, "offset": 0, "bytes": 32, "type": "mapping(address => string)", "label": "implementationName"},
        {"slot": 1, "offset": 0, "bytes": 32, "type": "mapping(address => contract AddressManager)", "label": "addressManager"},
    ],
    ("v1.1.0", "ResolvedDelegateProxy"): [
        {"slot": 0, "offset": 0, "bytes": 32, "type": "mapping(address => string)", "label": "implementationName"},
        {"slot": 1, "offset": 0, "bytes": 32, "type": "mapping(address => contract AddressManager)", "label": "addressManager"},
    ],
    ("v1.0.0", "L1ERC721Bridge"): [
        {"slot": 0, "offset": 0, "bytes": 1568, "type": "uint256[49]", "label": "__gap"},
        {"slot": 49, "offset": 0, "bytes": 32, "type": "mapping(address => mapping(address => mapping(uint256 => bool)))", "label": "deposits"},
    ],
    ("v1.0.0", "DisputeGameFactory"): [
        {"slot": 0, "offset": 0, "bytes": 20, "type": "address", "label": "_owner"},
        {"slot": 1, "offset": 0, "bytes": 32, "type": "mapping(GameType => contract IDisputeGame)", "label": "gameImpls"},
        {"slot": 2, "offset": 0, "bytes": 32, "type": "mapping(Hash => contract IDisputeGame)", "label": "disputeGames"},
    ],
    ("v1.1.0", "ProtocolVersions"): [
        {"slot": 0, "offset": 0, "bytes": 1, "type": "uint8", "label": "_initialized"},
        {"slot": 0, "offset": 1, "bytes": 1, "type": "bool", "label": "_initializing"},
        {"slot": 1, "offset": 0, "bytes": 1600, "type": "uint256[50]", "label": "__gap"},
        {"slot": 51, "offset": 0, "bytes": 20, "type": "address", "label": "_owner"},
        {"slot": 52, "offset": 0, "bytes": 1568, "type": "uint256[49]", "label": "__gap"},
    ],
}


def tag_root(tag: str) -> Path:
    if int(tag[1:].split(".")[0]) <= 6:
        return Path(f"/home/user/ethereum-optimism/hist/{tag}/packages/contracts-bedrock")
    return Path(f"/home/user/ethereum-optimism/op-{tag}/packages/contracts-bedrock")


def clean_field(raw: dict) -> dict:
    return {
        "slot": int(raw["slot"]),
        "offset": int(raw["offset"]),
        "bytes": int(raw["bytes"]),
        "type": raw["type"].strip(),
        "label": raw.get("label", raw.get("Name", "")).strip(),
    }


def parse_markdown(path: Path) -> dict[str, list[dict]]:
    layouts: dict[str, list[dict]] = {}
    current: str | None = None
    heading = re.compile(r"^➡\s+.+:([A-Za-z0-9_]+)\s*$")
    for line in path.read_text().splitlines():
        match = heading.match(line)
        if match:
            current = match.group(1)
            layouts.setdefault(current, [])
            continue
        if current is None or not line.startswith("|"):
            continue
        cols = [col.strip() for col in line.strip().strip("|").split("|")]
        if len(cols) < 6 or cols[0] in {"Name", ""} or set(cols[0]) == {"-"}:
            continue
        if not cols[2].isdigit() or not cols[3].isdigit() or not cols[4].isdigit():
            continue
        layouts[current].append(clean_field({
            "label": cols[0], "type": cols[1], "slot": cols[2],
            "offset": cols[3], "bytes": cols[4],
        }))
    return layouts


def layouts_for(tag: str) -> tuple[dict[str, list[dict]], str]:
    root = tag_root(tag)
    if tag in {"v1.0.0", "v1.1.0"}:
        source = root / ".storage-layout"
        layouts = parse_markdown(source)
        for (manual_tag, contract), fields in EARLY_MANUAL_LAYOUTS.items():
            if manual_tag == tag:
                layouts.setdefault(contract, fields)
        return layouts, str(source)
    directory = root / "snapshots/storageLayout"
    layouts: dict[str, list[dict]] = {}
    for contract in CONTRACTS:
        path = directory / f"{contract}.json"
        if path.exists():
            layouts[contract] = [clean_field(item) for item in json.loads(path.read_text())]
    return layouts, str(directory)


def pos(field: dict) -> str:
    return f'{field["slot"]}:{field["offset"]}'


def slot_signature(fields: list[dict], slot: int) -> list[dict]:
    return [
        {key: field[key] for key in ("offset", "bytes", "type", "label")}
        for field in fields if field["slot"] == slot
    ]


def transition(old_tag: str, new_tag: str, old: list[dict], new: list[dict]) -> dict:
    before = {pos(field): field for field in old}
    after = {pos(field): field for field in new}
    changes: list[dict] = []
    touched_slots: set[int] = set()
    for position in sorted(set(before) | set(after), key=lambda p: tuple(map(int, p.split(":")))):
        left, right = before.get(position), after.get(position)
        if left == right:
            continue
        if left is None:
            kind = "added"
        elif right is None:
            kind = "deleted"
        elif left["label"].startswith("spacer_") and not right["label"].startswith("spacer_"):
            kind = "spacer_consumed"
        elif not left["label"].startswith("spacer_") and right["label"].startswith("spacer_"):
            kind = "deleted_to_spacer"
        elif left["type"] != right["type"] and left["label"] != right["label"]:
            kind = "renamed_and_retyped"
        elif left["type"] != right["type"]:
            kind = "retyped"
        elif left["label"] != right["label"]:
            kind = "renamed"
        elif left["bytes"] != right["bytes"]:
            kind = "resized"
        else:
            kind = "changed"
        slot = (right or left)["slot"]
        touched_slots.add(slot)
        changes.append({"position": position, "kind": kind, "before": left, "after": right})

    packed_changes = []
    for slot in sorted(touched_slots):
        old_sig = slot_signature(old, slot)
        new_sig = slot_signature(new, slot)
        if old_sig != new_sig and (len(old_sig) > 1 or len(new_sig) > 1):
            packed_changes.append({"slot": slot, "before": old_sig, "after": new_sig})
    return {
        "from": old_tag,
        "to": new_tag,
        "changes": changes,
        "packed_neighbour_changes": packed_changes,
    }


def main() -> None:
    per_tag: dict[str, dict[str, list[dict]]] = {}
    sources: dict[str, str] = {}
    for tag in TAGS:
        per_tag[tag], sources[tag] = layouts_for(tag)

    result = {
        "schema": "CF4 storage-lineage v1",
        "generated_utc": "2026-11-17",
        "method": (
            "Compiler storage snapshots normalized from .storage-layout (v1.0/v1.1) "
            "and snapshots/storageLayout JSON (v1.2-v9); transitions compare exact slot:offset positions."
        ),
        "tags": [{"tag": tag, "commit": COMMITS[tag], "source": sources[tag]} for tag in TAGS],
        "contracts": {},
    }
    for contract in CONTRACTS:
        releases = {}
        present_tags = []
        for tag in TAGS:
            fields = per_tag[tag].get(contract)
            if fields is None:
                releases[tag] = {"exists": False, "fields": []}
                continue
            present_tags.append(tag)
            init = next((field for field in fields if field["label"] == "_initialized"), None)
            releases[tag] = {
                "exists": True,
                "layout_origin": (
                    "manual inheritance reconstruction"
                    if (tag, contract) in EARLY_MANUAL_LAYOUTS else "compiler snapshot"
                ),
                "initializer_position": None if init is None else {
                    "slot": init["slot"], "offset": init["offset"], "bytes": init["bytes"]
                },
                "fields": fields,
            }
        transitions = []
        for left, right in zip(present_tags, present_tags[1:]):
            item = transition(left, right, per_tag[left][contract], per_tag[right][contract])
            if item["changes"]:
                transitions.append(item)
        result["contracts"][contract] = {
            "first_snapshot": present_tags[0] if present_tags else None,
            "last_snapshot": present_tags[-1] if present_tags else None,
            "releases": releases,
            "transitions": transitions,
        }

    OUT.write_text(json.dumps(result, indent=2) + "\n")
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
