#!/usr/bin/env python3
"""F4 — trace historical upgrade transactions (read-only debug_traceTransaction through the archive proxy).

For each tx: (1) prestateTracer{diffMode:true} => exact net storage delta per account;
             (2) callTracer => flattened list of calls whose selector is an initializer / upgrade / StorageSetter /
                 ProxyAdmin / AddressManager / ChugSplash primitive (who called what, in which order).
usage: F4_trace_upgrades.py <outdir> <label=txhash> [...]
"""
import json, sys, os
sys.path.insert(0, os.path.dirname(__file__))
from F4_rpc import call

SEL = {
    "0x4e91db08": "StorageSetter.setBytes32(bytes32,bytes32)",
    "0x0528afe2": "StorageSetter.setBytes32((bytes32,bytes32)[])",
    "0xca446dd9": "StorageSetter.setAddress(bytes32,address)",
    "0xe2a4853a": "StorageSetter.setUint(bytes32,uint256)",
    "0xabfdcced": "StorageSetter.setBool(bytes32,bool)",
    "0x99a88ec4": "ProxyAdmin.upgrade(address,address)",
    "0x9623609d": "ProxyAdmin.upgradeAndCall(address,address,bytes)",
    "0x3659cfe6": "Proxy.upgradeTo(address)",
    "0x4f1ef286": "Proxy.upgradeToAndCall(address,bytes)",
    "0x8f283970": "Proxy.changeAdmin(address)",
    "0x9b0b0fda": "L1ChugSplashProxy.setStorage(bytes32,bytes32)",
    "0x6fbc15e9": "L1ChugSplashProxy.setCode(bytes)",
    "0x9b2ea4bd": "AddressManager.setAddress(string,address)",
    "0x7eff275e": "ProxyAdmin.changeProxyAdmin(address,address)",
    "0x8d52d4a0": "ProxyAdmin.setProxyType(address,uint8)",
    "0x860f7cda": "ProxyAdmin.setImplementationName(address,string)",
    "0x07c8f7b0": "ProxyAdmin.setUpgrading(bool)",
    "0x0652b57a": "ProxyAdmin.setAddressManager(address)",
    "0x9b3b76cc": "ProxyAdmin.setAddress(string,address)",
    "0xf2fde38b": "transferOwnership(address)",
}


def flat(node, depth, out):
    inp = node.get("input", "0x")
    sel = inp[:10]
    name = SEL.get(sel)
    interesting = name or sel in INIT_SELS
    if interesting:
        out.append({"depth": depth, "type": node.get("type"), "from": node.get("from"), "to": node.get("to"),
                    "sel": sel, "name": name or INIT_SELS.get(sel), "input": inp[:10 + 64 * 6],
                    "error": node.get("error")})
    for c in node.get("calls", []) or []:
        flat(c, depth + 1, out)


INIT_SELS = {}


def main():
    outdir = sys.argv[1]
    os.makedirs(outdir, exist_ok=True)
    # any selector whose 4byte name starts with initialize/upgrade is resolved lazily from a small local table
    for sig in open(os.path.join(os.path.dirname(__file__), "F4_init_sigs.txt")).read().split("\n"):
        sig = sig.strip()
        if sig and not sig.startswith("#"):
            s, n = sig.split(" ", 1)
            INIT_SELS[s] = n
    for arg in sys.argv[2:]:
        label, tx = arg.split("=")
        diff = call("debug_traceTransaction", [tx, {"tracer": "prestateTracer", "tracerConfig": {"diffMode": True}}])
        json.dump(diff, open(f"{outdir}/{label}-diff.json", "w"))
        ct = call("debug_traceTransaction", [tx, {"tracer": "callTracer"}])
        calls = []
        flat(ct, 0, calls)
        json.dump({"tx": tx, "from": ct.get("from"), "to": ct.get("to"), "calls": calls},
                  open(f"{outdir}/{label}-calls.json", "w"), indent=1)
        print(label, tx, "accounts in diff:", len(set(diff.get("pre", {})) | set(diff.get("post", {}))), "calls kept:", len(calls))


if __name__ == "__main__":
    main()
