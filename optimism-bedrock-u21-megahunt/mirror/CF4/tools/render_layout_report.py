#!/usr/bin/env python3
"""Render the normalized CF4 layout lineage as compact Markdown epochs."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


BASE = Path(__file__).resolve().parents[1]
DATA = json.loads((BASE / "storage-lineage.json").read_text())
OUT = BASE / "STORAGE-ARCHAEOLOGY.md"


def digest(fields: list[dict]) -> str:
    return hashlib.sha256(json.dumps(fields, sort_keys=True).encode()).hexdigest()[:10]


def ranges(tags: list[str]) -> str:
    return tags[0] if len(tags) == 1 else f"{tags[0]}–{tags[-1]}"


def esc(value: object) -> str:
    return str(value).replace("|", "\\|")


lines = [
    "# CF4 storage archaeology: Bedrock through op-contracts/v9.0.0",
    "",
    "Worker: CF4 (independent Track A mirror). Chain-state cutoff: Ethereum block `26433900`.",
    "The companion `storage-lineage.json` is canonical for every per-release field. This document",
    "groups consecutive releases with byte-identical layouts; therefore every named release is still",
    "covered field-by-field. Commits and source paths are embedded in the JSON.",
    "",
    "## Method and coverage",
    "",
    "- v1.0.0/v1.1.0: compiler table `.storage-layout`; six early omissions reconstructed from",
    "  inheritance and declarations and marked `manual inheritance reconstruction` in JSON.",
    "- v1.2.0–v9.0.0: `snapshots/storageLayout/<Contract>.json`; inheritance chains checked by hand",
    "  at every layout-changing epoch.",
    "- A field position is `(slot, byte offset)`. `bytes` is compiler width; arrays/gaps occupy the",
    "  stated number of bytes from their starting slot. Mappings list their base slot only.",
    "- Hashed/unstructured slots and production values are catalogued separately below.",
    "",
]

for contract, record in DATA["contracts"].items():
    lines.extend([f"## {contract}", ""])
    epochs: list[tuple[list[str], list[dict], str]] = []
    for tag_info in DATA["tags"]:
        tag = tag_info["tag"]
        release = record["releases"][tag]
        if not release["exists"]:
            continue
        fields = release["fields"]
        origin = release.get("layout_origin", "compiler snapshot")
        if epochs and epochs[-1][1] == fields and epochs[-1][2] == origin:
            epochs[-1][0].append(tag)
        else:
            epochs.append(([tag], fields, origin))
    init_positions = sorted({
        (release["initializer_position"]["slot"], release["initializer_position"]["offset"])
        for release in record["releases"].values()
        if release.get("exists") and release.get("initializer_position")
    })
    lines.append(
        f"Exists in snapshots `{record['first_snapshot']}` through `{record['last_snapshot']}`; "
        + ("no `_initialized` field." if not init_positions else
           "`_initialized` position(s): " + ", ".join(f"slot {s} offset {o}" for s, o in init_positions) + ".")
    )
    lines.append("")
    for tags, fields, origin in epochs:
        lines.extend([
            f"### Layout epoch `{ranges(tags)}` (`{digest(fields)}`, {origin})",
            "",
            "| slot | off | bytes | label | type |",
            "|---:|---:|---:|---|---|",
        ])
        if fields:
            for field in fields:
                lines.append(
                    f"| {field['slot']} | {field['offset']} | {field['bytes']} | "
                    f"`{esc(field['label'])}` | `{esc(field['type'])}` |"
                )
        else:
            lines.append("| — | — | — | *(no compiler-managed storage)* | — |")
        lines.append("")
    if record["transitions"]:
        lines.extend([
            "### Position transitions",
            "",
            "| release edge | position | classification | before | after |",
            "|---|---:|---|---|---|",
        ])
        for edge in record["transitions"]:
            for change in edge["changes"]:
                before = change.get("before")
                after = change.get("after")
                left = "—" if before is None else f"`{esc(before['label'])}: {esc(before['type'])}`"
                right = "—" if after is None else f"`{esc(after['label'])}: {esc(after['type'])}`"
                lines.append(
                    f"| `{edge['from']}→{edge['to']}` | `{change['position']}` | "
                    f"{change['kind']} | {left} | {right} |"
                )
        lines.append("")

lines.extend([
    "## Analytical production history",
    "",
    "The source tables above are complete. The remainder of this report binds them to deployed",
    "OP Mainnet state, mapping entries, initializer transitions, raw-slot consumers and fork tests.",
    "",
    "<!-- CF4_ANALYSIS_APPEND -->",
])

OUT.write_text("\n".join(lines) + "\n")
print(f"wrote {OUT} ({len(lines)} lines)")
