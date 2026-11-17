#!/usr/bin/env python3
"""F4 — build per-contract storage-layout lineage across op-contracts tags v1.0.0 .. v9.0.0.

Inputs (read-only):
  v1.0.0  hist/v1.0.0/packages/contracts-bedrock/.storage-layout          (markdown tables)
  v1.1.0  `git show op-contracts/v1.1.0:packages/contracts-bedrock/.storage-layout` saved to argv[1]
  v1.2.0+ hist/<tag>/packages/contracts-bedrock/snapshots/storageLayout/<Contract>.json
  v7..v9  op-v{7,8,9}.0.0/packages/contracts-bedrock/snapshots/storageLayout/<Contract>.json
Output: JSON {contract: {tag: [fields]}} on stdout.
Snapshots are NOT trusted on their own: STORAGE-ARCHAEOLOGY.md cross-checks the inheritance chains by hand.
"""
import json, os, re, sys

HIST = "/home/user/ethereum-optimism/hist"
TAGS = ["v1.0.0", "v1.1.0", "v1.2.0", "v1.3.0", "v1.4.0", "v1.5.0", "v1.6.0", "v1.8.0", "v2.0.0", "v2.1.0",
        "v2.2.0", "v3.0.0", "v3.0.1", "v4.0.0", "v4.1.0", "v5.0.0", "v6.0.0", "v7.0.0", "v8.0.0", "v9.0.0"]
CONTRACTS = ["OptimismPortal", "OptimismPortal2", "L2OutputOracle", "SystemConfig", "L1CrossDomainMessenger",
             "L1StandardBridge", "L1ERC721Bridge", "OptimismMintableERC20Factory", "SuperchainConfig",
             "ProtocolVersions", "DisputeGameFactory", "AnchorStateRegistry", "DelayedWETH", "ETHLockbox",
             "AddressManager", "ProxyAdmin", "Proxy", "L1ChugSplashProxy", "ResolvedDelegateProxy", "StorageSetter",
             "OptimismPortalInterop", "SystemConfigInterop", "DataAvailabilityChallenge"]


def parse_md(path):
    out, cur = {}, None
    for line in open(path, encoding="utf-8"):
        m = re.match(r"^➡ .*:(\w+)\s*$", line)
        if m:
            cur = m.group(1)
            out[cur] = []
            continue
        if cur and line.startswith("|") and not line.startswith("|--") and "Name" not in line.split("|")[1]:
            c = [x.strip() for x in line.strip().strip("|").split("|")]
            out[cur].append({"label": c[0], "type": c[1], "slot": int(c[2]), "offset": int(c[3]), "bytes": int(c[4])})
    return out


def snapdir(tag):
    if tag in ("v7.0.0", "v8.0.0", "v9.0.0"):
        return f"/home/user/ethereum-optimism/op-{tag}/packages/contracts-bedrock/snapshots/storageLayout"
    return f"{HIST}/{tag}/packages/contracts-bedrock/snapshots/storageLayout"


def main():
    md = {"v1.0.0": parse_md(f"{HIST}/v1.0.0/packages/contracts-bedrock/.storage-layout"),
          "v1.1.0": parse_md(sys.argv[1])}
    res = {c: {} for c in CONTRACTS}
    for tag in TAGS:
        for c in CONTRACTS:
            if tag in md:
                if c in md[tag]:
                    res[c][tag] = md[tag][c]
                continue
            p = os.path.join(snapdir(tag), c + ".json")
            if os.path.exists(p):
                res[c][tag] = [{"label": f["label"], "type": f["type"], "slot": int(f["slot"]),
                                "offset": int(f["offset"]), "bytes": int(f["bytes"])} for f in json.load(open(p))]
    json.dump(res, sys.stdout, indent=1)


if __name__ == "__main__":
    main()
