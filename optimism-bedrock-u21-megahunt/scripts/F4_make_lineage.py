#!/usr/bin/env python3
"""F4 — assemble evidence/F4-storage-lineage.json and the generated lineage tables (markdown fragment).

Inputs : layouts (F4_build_lineage.py output, argv[1]); evidence/F4/hist-*.json, slots-*.json, events-*.json
Outputs: evidence/F4-storage-lineage.json ; argv[2] = markdown fragment with one lineage table per contract.
Lineage row = one (slot, offset); cells = label:type per tag range in which that field was unchanged.
"""
import json, sys, glob, os, datetime

BASE = "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/evidence/"
TAGS = ["v1.0.0", "v1.1.0", "v1.2.0", "v1.3.0", "v1.4.0", "v1.5.0", "v1.6.0", "v1.8.0", "v2.0.0", "v2.1.0",
        "v2.2.0", "v3.0.0", "v3.0.1", "v4.0.0", "v4.1.0", "v5.0.0", "v6.0.0", "v7.0.0", "v8.0.0", "v9.0.0"]
ORDER = ["OptimismPortal", "OptimismPortal2", "L2OutputOracle", "SystemConfig", "L1CrossDomainMessenger",
         "L1StandardBridge", "L1ERC721Bridge", "OptimismMintableERC20Factory", "SuperchainConfig", "ProtocolVersions",
         "DisputeGameFactory", "AnchorStateRegistry", "DelayedWETH", "ETHLockbox", "AddressManager", "ProxyAdmin",
         "ResolvedDelegateProxy", "L1ChugSplashProxy", "Proxy", "StorageSetter"]
ONCHAIN = {"OptimismPortal2": "OptimismPortal", "OptimismPortal": "OptimismPortal", "SystemConfig": "SystemConfig",
           "L1CrossDomainMessenger": "L1CrossDomainMessenger", "L1StandardBridge": "L1StandardBridge",
           "L1ERC721Bridge": "L1ERC721Bridge", "OptimismMintableERC20Factory": "OptimismMintableERC20Factory",
           "SuperchainConfig": "SuperchainConfig", "ProtocolVersions": "ProtocolVersions",
           "DisputeGameFactory": "DisputeGameFactory", "AnchorStateRegistry": "AnchorStateRegistry",
           "DelayedWETH": "DelayedWETH", "ETHLockbox": "ETHLockbox", "AddressManager": "AddressManager",
           "ProxyAdmin": "ProxyAdmin", "L2OutputOracle": "L2OutputOracle"}


def rng(a, b):
    return a if a == b else f"{a}..{b}"


def lineage(per_tag):
    tags = [t for t in TAGS if t in per_tag]
    keys = sorted({(f["slot"], f["offset"]) for t in tags for f in per_tag[t]})
    rows = []
    for k in keys:
        hist, cur = [], None
        for t in tags:
            f = next((x for x in per_tag[t] if (x["slot"], x["offset"]) == k), None)
            v = None if f is None else (f["label"], f["type"], f["bytes"])
            if cur is not None and cur["v"] == v:
                cur["to"] = t
            else:
                cur = {"from": t, "to": t, "v": v}
                hist.append(cur)
        rows.append({"slot": k[0], "offset": k[1],
                     "history": [{"from_tag": h["from"], "to_tag": h["to"],
                                  "label": h["v"][0] if h["v"] else None, "type": h["v"][1] if h["v"] else None,
                                  "bytes": h["v"][2] if h["v"] else None} for h in hist]})
    return tags, rows


def main():
    layouts = json.load(open(sys.argv[1]))
    out = {"generated": datetime.datetime.now(datetime.UTC).isoformat(), "head_block": 26433900,
           "tags": TAGS, "note": "layouts from .storage-layout (v1.0.0, v1.1.0) and snapshots/storageLayout (v1.2.0+); "
           "hand cross-checks of the inheritance chains are recorded in STORAGE-ARCHAEOLOGY.md",
           "contracts": {}, "chains": {}}
    md = []
    for c in ORDER:
        if c not in layouts or not layouts[c]:
            continue
        tags, rows = lineage(layouts[c])
        ent = {"tags_present": tags, "layouts": layouts[c], "lineage": rows}
        oc = ONCHAIN.get(c)
        if oc and os.path.exists(BASE + f"F4/hist-{oc}.json"):
            h = json.load(open(BASE + f"F4/hist-{oc}.json"))
            ent["op_mainnet"] = {"proxy": h["proxy"], "signature_members": h["members"], "changes": h["changes"]}
            p = BASE + f"F4/slots-{oc}.json"
            if os.path.exists(p):
                s = json.load(open(p))
                ent["op_mainnet"]["implementations"] = s["impls"]
                ent["op_mainnet"]["slots_ever_nonzero_at_sample_points"] = s["slots"]
                ent["op_mainnet"]["sample_blocks"] = s["blocks"]
            p = BASE + f"F4/events-{oc}.json"
            if os.path.exists(p):
                ent["op_mainnet"]["upgrade_block_events"] = json.load(open(p))["blocks"]
        out["contracts"][c] = ent
        md.append(f"### {c}\n")
        md.append(f"Tags with this contract: {tags[0]} .. {tags[-1]} ({len(tags)} tags).\n")
        md.append("| slot | off | lineage (tag range: `label` type [bytes]) |")
        md.append("|---|---|---|")
        for r in rows:
            cells = []
            for hh in r["history"]:
                if hh["label"] is None:
                    cells.append(f"{rng(hh['from_tag'], hh['to_tag'])}: —")
                else:
                    cells.append(f"{rng(hh['from_tag'], hh['to_tag'])}: `{hh['label']}` {hh['type']} [{hh['bytes']}]")
            flag = " **CHANGED**" if len([x for x in r["history"]]) > 1 else ""
            md.append(f"| {r['slot']} | {r['offset']} | " + " → ".join(cells).replace("|", "\\|") + flag + " |")
        md.append("")
    # other chains + extra proxies
    for f in sorted(glob.glob(BASE + "F4/hist-*.json")):
        n = os.path.basename(f)[5:-5]
        try:
            h = json.load(open(f))
        except Exception:
            continue
        out["chains"][n] = {"proxy": h["proxy"], "signature_members": h["members"], "changes": h["changes"]}
    json.dump(out, open(BASE + "F4-storage-lineage.json", "w"), indent=1)
    open(sys.argv[2], "w").write("\n".join(md))
    print("contracts", len(out["contracts"]), "histories", len(out["chains"]), "md lines", len(md))


if __name__ == "__main__":
    main()
