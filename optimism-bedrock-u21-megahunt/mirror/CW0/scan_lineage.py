#!/usr/bin/env python3
"""Index security-surface Solidity functions across pinned op-contracts releases.

This is an archaeology helper, not a Solidity parser. It strips comments/space only for
change detection, while preserving exact source line ranges for manual verification.
"""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path


VERSIONS = [
    "v1.0.0", "v1.1.0", "v1.2.0", "v1.3.0", "v1.4.0", "v1.5.0",
    "v1.6.0", "v1.8.0", "v2.0.0", "v2.1.0", "v2.2.0", "v3.0.0",
    "v3.0.1", "v4.0.0", "v4.1.0", "v5.0.0", "v6.0.0", "v7.0.0",
    "v8.0.0", "v9.0.0",
]

HIST = Path("/home/user/ethereum-optimism/hist")
ETH = Path("/home/user/ethereum-optimism")
OUT = Path("/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/mirror/CW0")

TARGET_BASENAMES = {
    "OptimismPortal.sol", "OptimismPortal2.sol", "OptimismPortalInterop.sol",
    "CrossDomainMessenger.sol", "L1CrossDomainMessenger.sol", "SafeCall.sol",
    "StandardBridge.sol", "L1StandardBridge.sol", "SystemConfig.sol",
    "SuperchainConfig.sol", "AnchorStateRegistry.sol", "DisputeGameFactory.sol",
    "DelayedWETH.sol", "ETHLockbox.sol", "ProxyAdmin.sol", "ProxyAdminOwnedBase.sol",
    "OPContractsManagerV2.sol", "OPContractsManagerMigrator.sol",
    "OPContractsManagerUtils.sol", "StorageSetter.sol", "Types.sol",
}


def root_for(version: str) -> Path:
    if version in {"v7.0.0", "v8.0.0", "v9.0.0"}:
        return ETH / f"op-{version}" / "packages/contracts-bedrock"
    return HIST / version / "packages/contracts-bedrock"


def strip_comments(text: str) -> str:
    # Preserve byte offsets and line structure so declarations map back to exact source.
    text = re.sub(
        r"/\*.*?\*/",
        lambda m: re.sub(r"[^\n]", " ", m.group(0)),
        text,
        flags=re.S,
    )
    text = re.sub(r"//[^\n]*", lambda m: " " * len(m.group(0)), text)
    return text


def semantic_hash(text: str) -> str:
    normalized = re.sub(r"\s+", "", strip_comments(text))
    return hashlib.sha256(normalized.encode()).hexdigest()[:16]


def find_end(text: str, start: int) -> int:
    semi = text.find(";", start)
    brace = text.find("{", start)
    if semi >= 0 and (brace < 0 or semi < brace):
        return semi + 1
    if brace < 0:
        return len(text)
    depth = 0
    in_str: str | None = None
    escaped = False
    i = brace
    while i < len(text):
        ch = text[i]
        if in_str:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == in_str:
                in_str = None
        elif ch in {'"', "'"}:
            in_str = ch
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    return len(text)


DECL_RE = re.compile(
    r"(?m)^[ \t]*(?:(?:function)[ \t]+(?P<function>[A-Za-z_]\w*)[ \t]*\(|"
    r"(?P<special>receive|fallback)[ \t]*\(|"
    r"(?:modifier)[ \t]+(?P<modifier>[A-Za-z_]\w*)[ \t]*(?:\(|\{))"
)


def line_no(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def signature(block: str) -> str:
    head = block.split("{", 1)[0].split(";", 1)[0]
    return re.sub(r"\s+", " ", strip_comments(head)).strip()


def functions(text: str) -> list[dict]:
    found = []
    clean = strip_comments(text)
    for match in DECL_RE.finditer(clean):
        start_line = line_no(clean, match.start())
        start = match.start()
        end = find_end(text, start)
        block = text[start:end]
        name = match.group("function") or match.group("special") or match.group("modifier")
        found.append({
            "name": name,
            "kind": "modifier" if match.group("modifier") else "function",
            "start": start_line,
            "end": line_no(text, end),
            "signature": signature(block),
            "hash": semantic_hash(block),
        })
    return found


def main() -> None:
    records: list[dict] = []
    for version in VERSIONS:
        root = root_for(version)
        for path in sorted(root.rglob("*.sol")):
            if not path.is_file():
                continue
            if path.name not in TARGET_BASENAMES:
                continue
            rel = path.relative_to(root).as_posix()
            if rel.startswith(("test/", "contracts/test/", "lib/")):
                continue
            text = path.read_text(errors="replace")
            records.append({
                "version": version,
                "root": str(root),
                "path": rel,
                "file_hash": semantic_hash(text),
                "functions": functions(text),
            })
    (OUT / "SOURCE-FUNCTION-INDEX.json").write_text(json.dumps(records, indent=2) + "\n")

    # A compact human-readable list of only first appearance or semantic hash changes.
    previous: dict[tuple[str, str, str], str] = {}
    lines = ["# Semantic function change index", ""]
    for rec in records:
        for fn in rec["functions"]:
            key = (Path(rec["path"]).name, fn["name"], fn["signature"])
            old = previous.get(key)
            if old != fn["hash"]:
                change = "FIRST" if old is None else f"CHANGED from {old}"
                lines.append(
                    f"- {rec['version']} `{rec['path']}:{fn['start']}` "
                    f"`{fn['signature']}` {change} -> `{fn['hash']}`"
                )
            previous[key] = fn["hash"]
    (OUT / "SOURCE-FUNCTION-CHANGES.md").write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
