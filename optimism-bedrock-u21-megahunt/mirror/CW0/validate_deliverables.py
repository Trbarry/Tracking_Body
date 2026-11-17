#!/usr/bin/env python3
"""Named validation: CW0DeliverablesValidation."""

import csv
import json
import re
from collections import Counter
from pathlib import Path


OUT = Path("/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/mirror/CW0")
SRC = Path("/home/user/Tracking_Body/optimism-u21-novel-hunt/primitives")
EXCLUDED = {"PRIM-3301.md", "PRIM-3302.md", "PRIM-3303.md"}
REQUIRED_PRIMITIVE = {
    "id", "source_files", "title", "family", "EARLIEST_SEMANTIC_ANCESTOR",
    "CURRENT_U21_CONSUMER", "PERSISTENT_STATE_OR_OBJECT", "HISTORICAL_BRANCHES",
    "AUDIT_COVERAGE_ALREADY_DONE", "UNREVIEWED_CROSS_UPGRADE_EDGE", "NEXT_EXPERIMENT",
    "priority", "pass_a_status",
}
REQUIRED_LINEAGE = {
    "SURFACE", "FUNCTION_OR_FIELD", "FIRST_INTRODUCED", "ORIGINAL_MEANING",
    "ORIGINAL_INVARIANT", "ALL_SEMANTIC_CHANGES", "ALL_CALL_ORDER_CHANGES",
    "ALL_REVERT_SEMANTIC_CHANGES", "ALL_IDENTITY_SOURCE_CHANGES",
    "ALL_AUTHORIZATION_CHANGES", "ALL_PAUSE_SOURCE_CHANGES",
    "OBJECTS_CREATED_UNDER_OLD_MEANING", "MIGRATION_OR_INVALIDATION_EVENTS",
    "CURRENT_CONSUMERS", "UNREVIEWED_TRANSITIVE_PATHS",
}


def fail(message: str) -> None:
    raise AssertionError(message)


records = json.loads((OUT / "PRIMITIVES.json").read_text())
if len(records) != 89:
    fail(f"expected 89 conservatively deduplicated records, got {len(records)}")
if [r["id"] for r in records] != [f"A-{i:03d}" for i in range(1, 90)]:
    fail("A identifiers are not unique/sequential")
for record in records:
    if set(record) != REQUIRED_PRIMITIVE:
        fail(f"primitive schema mismatch: {record['id']}")
    if record["family"] not in {"custody", "proof-lifecycle", "messenger-replay", "pause", "storage-init", "upgrade-engine", "identity-binding", "dispute-game", "bond-credit", "gas-budget", "migration", "tooling"}:
        fail(f"invalid family: {record['id']}")
    if record["priority"] not in {"P0", "P1", "P2"} or record["AUDIT_COVERAGE_ALREADY_DONE"] != "TRACK-B":
        fail(f"priority/coverage mismatch: {record['id']}")

actual_sources = [Path(p).name for r in records for p in r["source_files"]]
expected_sources = sorted(p.name for p in SRC.glob("PRIM-*.md") if p.name not in EXCLUDED)
if sorted(actual_sources) != expected_sources:
    fail("primitive source coverage is not exact")
dupes = [name for name, count in Counter(actual_sources).items() if count != 1]
if dupes:
    fail(f"source file repeated across records: {dupes}")
if EXCLUDED & set(actual_sources):
    fail("excluded 3301..3303 entered PRIMITIVES.json")

dead_ends = (OUT / "DEAD-ENDS-NO-REDO.md").read_text()
covered_rejections = re.findall(r"/rejected/(REJ-\d+\.md)", dead_ends)
expected_rejections = sorted(p.name for p in (SRC.parent / "rejected").glob("REJ-*.md"))
if sorted(covered_rejections) != expected_rejections or len(covered_rejections) != len(set(covered_rejections)):
    fail("dead-end rejection coverage is not exact/unique")

matrix_records = [r["id"] for r in records if r["priority"] in {"P0", "P1"}]
with (OUT / "PRIMITIVE-COMPATIBILITY-MATRIX.csv").open(newline="") as fh:
    matrix = list(csv.reader(fh))
if matrix[0][1:] != matrix_records or [row[0] for row in matrix[1:]] != matrix_records:
    fail("matrix axes do not exactly equal ordered P0/P1 records")
if any(len(row) != len(matrix[0]) for row in matrix):
    fail("ragged compatibility matrix")

lineage_payload = json.loads((OUT / "SEMANTIC-LINEAGE.json").read_text())
lineage = lineage_payload["records"]
if len(lineage) != 21:
    fail(f"expected 21 curated lineage records, got {len(lineage)}")
for record in lineage:
    if set(record) != REQUIRED_LINEAGE:
        fail(f"lineage schema mismatch: {record.get('SURFACE')}")
surfaces = " ".join(r["SURFACE"] for r in lineage)
for required in ["OptimismPortal", "CrossDomainMessenger", "SafeCall", "StandardBridge", "SystemConfig", "SuperchainConfig", "AnchorStateRegistry", "DisputeGameFactory", "DelayedWETH", "ETHLockbox", "ProxyAdmin"]:
    if required not in surfaces:
        fail(f"missing lineage surface: {required}")

# Resolve every explicitly tag-qualified Solidity citation and verify that its line exists.
texts = [(OUT / name).read_text() for name in ["PRIMITIVES.json", "SEMANTIC-LINEAGE.json", "SEMANTIC-LINEAGE.md"]]
texts.append(Path("/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/workers/CW0-report.md").read_text())
refs = set()
for text in texts:
    bare = re.findall(r"(?<![:\w/])(?:contracts|src)/[^` ;|]+?\.sol:\d+", text)
    if bare:
        fail(f"untagged Solidity citations remain: {sorted(set(bare))[:5]}")
    refs.update(re.findall(r"(v\d+\.\d+\.\d+):((?:contracts|src)/[^` ;,]+?\.sol):(\d+(?:-\d+)?(?:,\d+(?:-\d+)?)*)", text))
bad_refs = []
for tag, rel, line_spec in sorted(refs):
    release = "op-" + tag if tag in {"v7.0.0", "v8.0.0", "v9.0.0"} else "hist/" + tag
    path = Path("/home/user/ethereum-optimism") / release / "packages/contracts-bedrock" / rel
    if not path.is_file():
        bad_refs.append(f"missing pinned source: {tag}:{rel}")
        continue
    line_count = sum(1 for _ in path.open(errors="ignore"))
    cited_max = max(map(int, re.findall(r"\d+", line_spec)))
    if cited_max > line_count:
        bad_refs.append(f"citation beyond EOF: {tag}:{rel}:{cited_max}>{line_count}")
if bad_refs:
    fail("invalid pinned citations:\n" + "\n".join(bad_refs))

for required in ["PRIMITIVES.json", "PRIMITIVE-COMPATIBILITY-MATRIX.csv", "DEAD-ENDS-NO-REDO.md", "SEMANTIC-LINEAGE.md", "SEMANTIC-LINEAGE.json"]:
    if not (OUT / required).is_file() or (OUT / required).stat().st_size == 0:
        fail(f"missing/empty deliverable: {required}")

print(f"CW0DeliverablesValidation: PASS — {len(actual_sources)} sources -> {len(records)} records; {len(covered_rejections)} rejections covered; {len(matrix_records)} P0/P1 matrix axes; {len(lineage)} lineage records; {len(refs)} pinned citations checked")
