#!/usr/bin/env python3
"""F6: generate test/src/HistoricalForkData.sol and test/fixtures/upgrades/<LABEL>.json from
evidence/F6-op-upgrade-blocks.json + evidence/F6-op-upgrade-txs.json (never hand-edit the outputs).

Labels: the op-contracts tag of each point was established by matching the on-chain version()
strings after the block with the version strings in the tagged source trees
(/home/user/ethereum-optimism/hist/<tag>, op-v7/8/9.0.0). The governance "Upgrade N" numbers in the
labels U13..U21 follow the brief (U17=v5 .. U21=v9) and count back; they are a naming convenience,
the authoritative key is the block number.
"""
import json, os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
blocks = json.load(open(os.path.join(ROOT, "evidence", "F6-op-upgrade-blocks.json")))
txs = json.load(open(os.path.join(ROOT, "evidence", "F6-op-upgrade-txs.json")))

# block -> (label, op-contracts tag / description)
LABELS = {
    17422444: ("BEDROCK_STEP1", "op-contracts/v1.0.0 (Bedrock migration, SystemDictator early step: SystemConfig live, L1CDM entry cleared)"),
    17423158: ("BEDROCK", "op-contracts/v1.0.0 (Bedrock migration final step)"),
    18367320: ("PROTOCOL_VERSIONS_INIT", "ProtocolVersions proxy initialised (not one of the seven core contracts)"),
    19064589: ("SUPERCHAIN_CONFIG_INIT", "SuperchainConfig proxy initialised (not one of the seven core contracts)"),
    19314493: ("V1_2_0", "op-contracts/v1.2.0 (SuperchainConfig / extended pause; portal 2.4.0)"),
    19634866: ("V1_3_0", "op-contracts/v1.3.0 (MCP L1; portal 2.5.0)"),
    19884570: ("FP_PROXIES_INIT", "DisputeGameFactory 1.0.0 + legacy AnchorStateRegistry 1.0.0 proxies initialised (pre fault proofs)"),
    20062696: ("V1_4_0_FP", "op-contracts/v1.4.0 (fault proofs: OptimismPortal2 3.10.0, SystemConfig 2.2.0)"),
    20723924: ("V1_6_0_ASR", "op-contracts/v1.6.0 era (legacy AnchorStateRegistry 2.0.0, Granite prestate)"),
    21695024: ("V1_8_0", "op-contracts/v1.8.0 (Holocene: SystemConfig 2.3.0)"),
    22182531: ("U13_V2", "op-contracts/v2.0.0 (Upgrade 13, first OPCM upgrade; portal 3.13.0)"),
    22339996: ("U14_V3", "op-contracts/v3.0.0 (Upgrade 14; portal 3.14.0)"),
    22990599: ("U16_V4", "op-contracts/v4.0.0 (Upgrade 16: ETHLockbox + new AnchorStateRegistry; portal 4.6.0)"),
    23491328: ("U16A_V4_1", "op-contracts/v4.1.0 (Upgrade 16a; portal 5.0.0)"),
    23877377: ("U17_V5", "op-contracts/v5.0.0 (Upgrade 17; portal 5.1.1)"),
    24421512: ("U18_V6", "op-contracts/v6.0.0 (Upgrade 18; portal 5.2.0)"),
    25397811: ("U19_V7", "op-contracts/v7.0.0 (Upgrade 19; portal 5.6.1)"),
    26048619: ("U20_V8", "op-contracts/v8.0.0 (Upgrade 20; portal 5.8.0)"),
    26430859: ("U21_V9", "op-contracts/v9.0.0 (Upgrade 21; portal 6.1.0)"),
}
CONTRACTS = ["OptimismPortal", "SystemConfig", "L1CrossDomainMessenger", "L1StandardBridge", "DisputeGameFactory",
             "AnchorStateRegistry", "ETHLockbox", "AnchorStateRegistryLegacy", "L1ERC721Bridge", "OptimismMintableERC20Factory",
             "SuperchainConfig", "L2OutputOracle", "ProtocolVersions", "DelayedWETH_0x1b6d"]
CONST = ["PORTAL", "SYSTEM_CONFIG", "L1CDM", "L1_BRIDGE", "DGF", "ASR", "LOCKBOX", "ASR_LEGACY", "ERC721_BRIDGE", "ERC20_FACTORY",
         "SUPERCHAIN_CONFIG", "L2OO", "PROTOCOL_VERSIONS", "DELAYED_WETH"]

def cs(a):
    import subprocess
    return subprocess.check_output(["cast", "to-check-sum-address", a]).decode().strip()

def impl_at(name, blk):
    c = blocks["contracts"][name]
    v = c["first_grid_value"]
    for ch in c["changes"]:
        if ch["block"] <= blk:
            v = ch["to_impl"]
    return v

def changed_at(name, blk):
    return any(ch["block"] == blk for ch in blocks["contracts"][name]["changes"])

points = sorted(txs["blocks"], key=lambda b: b["block"])
assert [p["block"] for p in points] == sorted(LABELS), (set(LABELS) ^ set(p["block"] for p in points))

os.makedirs(os.path.join(ROOT, "test", "fixtures", "upgrades"), exist_ok=True)
summary = []
for i, p in enumerate(points):
    label, tag = LABELS[p["block"]]
    fx = {"index": i, "label": label, "tag": tag, "block": p["block"], "beforeBlock": p["block"] - 1, "timestamp": p["timestamp"],
          "txCount": len(p["txs"]),
          "txs": [{"hash": t["hash"], "from": t["from"], "to": t["to"], "value": t["value"], "gas": t["gas"], "gasUsed": t["gasUsed"],
                   "txIndex": t["txIndex"], "input": t["input"]} for t in p["txs"]],
          "implBefore": {n: impl_at(n, p["block"] - 1) for n in CONTRACTS},
          "implAfter": {n: impl_at(n, p["block"]) for n in CONTRACTS},
          "changed": [n for n in CONTRACTS if changed_at(n, p["block"])]}
    json.dump(fx, open(os.path.join(ROOT, "test", "fixtures", "upgrades", label + ".json"), "w"), indent=1)
    summary.append({k: fx[k] for k in ("index", "label", "tag", "block", "timestamp", "changed")} | {"txs": [t["hash"] for t in fx["txs"]]})
json.dump({"points": summary, "contracts": {n: blocks["contracts"][n]["proxy"] for n in CONTRACTS}},
          open(os.path.join(ROOT, "evidence", "F6-fork-points.json"), "w"), indent=1)

o = []
o.append("// SPDX-License-Identifier: MIT")
o.append("pragma solidity ^0.8.15;")
o.append("")
o.append("// GENERATED by scripts/f6_gen_harness_data.py from evidence/F6-op-upgrade-blocks.json and")
o.append("// evidence/F6-op-upgrade-txs.json. Do not edit by hand.")
o.append("//")
o.append("// A fork point is an L1 block in which the implementation pointer of at least one tracked OP Mainnet")
o.append("// proxy changed. `blockOf(i)` is that block (state at its END holds the new pointer); the block before is")
o.append("// blockOf(i) - 1. implAfter(c, i) / implBefore(c, i) are the pointer values at the END of those two blocks.")
o.append("library HFData {")
o.append(f"    uint256 internal constant POINTS = {len(points)};")
o.append(f"    uint256 internal constant CONTRACTS = {len(CONTRACTS)};")
o.append("")
o.append("    // ---- fork point indices (chronological) ----")
for i, p in enumerate(points):
    o.append(f"    uint256 internal constant {LABELS[p['block']][0]} = {i}; // block {p['block']}, {LABELS[p['block']][1]}")
o.append("")
o.append("    // ---- contract ids ----")
for i, c in enumerate(CONST):
    o.append(f"    uint256 internal constant {c} = {i}; // {CONTRACTS[i]}")
o.append("")

def fn(name, ret, rows, default="revert(\"HFData: bad index\");"):
    o.append(f"    function {name}(uint256 i) internal pure returns ({ret}) {{")
    for i, r in enumerate(rows):
        o.append(f"        if (i == {i}) return {r};")
    o.append(f"        {default}")
    o.append("    }")
    o.append("")

fn("label", "string memory", [f'"{LABELS[p["block"]][0]}"' for p in points])
fn("tag", "string memory", ['"' + LABELS[p["block"]][1].replace('"', "'") + '"' for p in points])
fn("blockOf", "uint256", [str(p["block"]) for p in points])
fn("timestampOf", "uint64", [str(p["timestamp"]) for p in points])
fn("txCount", "uint256", [str(len(p["txs"])) for p in points])
fn("contractName", "string memory", [f'"{c}"' for c in CONTRACTS])
fn("proxyOf", "address", [cs(blocks["contracts"][c]["proxy"]) for c in CONTRACTS])

o.append("    function txHash(uint256 i, uint256 k) internal pure returns (bytes32) {")
for i, p in enumerate(points):
    for k, t in enumerate(p["txs"]):
        o.append(f"        if (i == {i} && k == {k}) return {t['hash']};")
o.append('        revert("HFData: bad tx index");')
o.append("    }")
o.append("")
o.append("    /// @notice true if contract `c`'s implementation pointer changed in the block of point `i`.")
o.append("    function changedAt(uint256 c, uint256 i) internal pure returns (bool) {")
for ci, c in enumerate(CONTRACTS):
    idx = [str(i) for i, p in enumerate(points) if changed_at(c, p["block"])]
    if idx:
        o.append(f"        if (c == {ci}) return " + " || ".join(f"i == {x}" for x in idx) + ";")
o.append("        return false;")
o.append("    }")
o.append("")
for nm, off in (("implAfter", 0), ("implBefore", 1)):
    o.append(f"    /// @notice implementation pointer of contract `c` at the END of block blockOf(i){' - 1' if off else ''}.")
    o.append(f"    function {nm}(uint256 c, uint256 i) internal pure returns (address) {{")
    for ci, c in enumerate(CONTRACTS):
        o.append(f"        if (c == {ci}) {{")
        prev = None
        # compress: emit ranges
        vals = [impl_at(c, p["block"] - off) for p in points]
        for i, v in enumerate(vals):
            o.append(f"            if (i == {i}) return {cs(v)};")
        o.append("        }")
    o.append('        revert("HFData: bad index");')
    o.append("    }")
    o.append("")
o.append("}")
open(os.path.join(ROOT, "test", "src", "HistoricalForkData.sol"), "w").write("\n".join(o) + "\n")
print("points", len(points))
for s in summary:
    print(s["index"], s["label"], s["block"], len(s["txs"]), s["changed"])
