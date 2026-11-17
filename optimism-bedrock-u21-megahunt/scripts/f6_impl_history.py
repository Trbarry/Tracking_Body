#!/usr/bin/env python3
"""F6: implementation history of OP Mainnet L1 proxies by storage sampling + bisection.

Method (read-only, local archive proxy http://127.0.0.1:7545):
  1. sample the implementation pointer of every tracked proxy on a block grid (default 10_000);
  2. for every grid interval whose endpoints differ, bisect recursively to the exact block(s)
     at which the value changed (state at END of block b differs from END of block b-1);
  3. for every change record version() before/after.
Limit: an A -> B -> A excursion that starts and ends inside one grid interval is invisible.
Intermediate implementations set and replaced inside ONE transaction/block (StorageSetter) are
invisible by construction (block granularity) - use the Upgraded logs of the tx for those.

Usage: f6_impl_history.py [--step 10000] [--start 17300000] [--end <latest>] [--out evidence/F6-op-upgrade-blocks.json]
"""
import argparse, json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from f6_rpc import batch, call, eth_call

EIP1967 = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
OWNER1967 = "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103"
ADDRESS_MANAGER = "0xdE1FCfB0851916CA5101820A69b13a4E276bd81F"
# keccak256(abi.encode(keccak256("OVM_L1CrossDomainMessenger"), uint256(1)))  (Lib_AddressManager.addresses at slot 1)
AM_L1CDM_SLOT = None  # computed below

TRACKED = [
    # name, proxy, (storage holder, slot), proxy kind
    ("OptimismPortal", "0xbEb5Fc579115071764c7423A4f12eDde41f106Ed", None, "eip1967"),
    ("SystemConfig", "0x229047fed2591dbec1eF1118d64F7aF3dB9EB290", None, "eip1967"),
    ("L1CrossDomainMessenger", "0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1", "AM", "ResolvedDelegateProxy/AddressManager"),
    ("L1StandardBridge", "0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1", None, "L1ChugSplashProxy (eip1967 slot)"),
    ("DisputeGameFactory", "0xe5965Ab5962eDc7477C8520243A95517CD252fA9", None, "eip1967"),
    ("AnchorStateRegistry", "0x23B2C62946350F4246f9f9D027e071f0264FD113", None, "eip1967"),
    ("AnchorStateRegistryLegacy", "0x18DAc71c228D1C32c99489B7323d441E1175e443", None, "eip1967"),
    ("ETHLockbox", "0x322b47Ff1FA8D5611F761e3E275C45B71b294D43", None, "eip1967"),
    ("L1ERC721Bridge", "0x5a7749f83b81B301cAb5f48EB8516B986DAef23D", None, "eip1967"),
    ("OptimismMintableERC20Factory", "0x75505a97BD334E7BD3C476893285569C4136Fa0F", None, "eip1967"),
    ("SuperchainConfig", "0x95703e0982140D16f8ebA6d158FccEde42f04a4C", None, "eip1967"),
    ("L2OutputOracle", "0xdfe97868233d1aa22e815a266982f2cf17685a27", None, "eip1967"),
    ("ProtocolVersions", "0x8062AbC286f5e7D9428a0Ccb9AbD71e50d93b935", None, "eip1967"),
    ("DelayedWETH_0x1b6d", "0x1b6dbf05eaf22d4e70dc993e8a19dd9f3dcb3162", None, "eip1967"),
]

def keccak(b):
    import subprocess
    return subprocess.check_output(["cast", "keccak", "0x" + b.hex()]).decode().strip()

def am_slot():
    name_hash = keccak(b"OVM_L1CrossDomainMessenger")
    return keccak(bytes.fromhex(name_hash[2:]) + (1).to_bytes(32, "big"))

def holder_slot(entry):
    name, proxy, holder, kind = entry
    if holder == "AM":
        return ADDRESS_MANAGER, AM_L1CDM_SLOT
    return proxy, EIP1967

def sample(entries_blocks):
    """entries_blocks: list of (entry, block) -> list of 32-byte hex values"""
    calls = []
    for e, b in entries_blocks:
        h, s = holder_slot(e)
        calls.append(("eth_getStorageAt", [h, s, hex(b)]))
    out = []
    for i in range(0, len(calls), 80):
        res = batch(calls[i:i + 80])
        for j, r in enumerate(res):
            if r is None:
                m, p = calls[i + j]
                r = call(m, p)
            out.append(r)
    return out

def addr(v):
    return "0x" + v[-40:]

def version_at(proxy, block):
    try:
        r = eth_call(proxy, "0x54fd4d50", block)
        if not r or r == "0x":
            return None
        raw = bytes.fromhex(r[2:])
        ln = int.from_bytes(raw[32:64], "big")
        return raw[64:64 + ln].decode(errors="replace")
    except Exception:
        return None

def main():
    global AM_L1CDM_SLOT
    ap = argparse.ArgumentParser()
    ap.add_argument("--step", type=int, default=10000)
    ap.add_argument("--start", type=int, default=17300000)
    ap.add_argument("--end", type=int, default=None)
    ap.add_argument("--out", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "evidence", "F6-op-upgrade-blocks.json"))
    a = ap.parse_args()
    AM_L1CDM_SLOT = am_slot()
    end = a.end or int(call("eth_blockNumber", []), 16) - 8
    grid = list(range(a.start, end, a.step)) + [end]
    result = {"meta": {"method": "grid sample + recursive bisection of the implementation pointer", "rpc": "http://127.0.0.1:7545",
                       "grid_step": a.step, "start": a.start, "end": end, "eip1967_slot": EIP1967,
                       "address_manager": ADDRESS_MANAGER, "address_manager_l1cdm_slot": AM_L1CDM_SLOT,
                       "semantics": "change_block = first block at whose END the pointer holds `to`; before_block = change_block - 1"},
              "contracts": {}}
    for e in TRACKED:
        name, proxy, holder, kind = e
        vals = sample([(e, b) for b in grid])
        known = dict(zip(grid, vals))
        changes = []

        def bisect(lo, hi):
            # invariant: known[lo] != known[hi]
            if hi - lo == 1:
                changes.append((hi, known[lo], known[hi]))
                return
            mid = (lo + hi) // 2
            if mid not in known:
                known[mid] = sample([(e, mid)])[0]
            if known[lo] != known[mid]:
                bisect(lo, mid)
            if known[mid] != known[hi]:
                bisect(mid, hi)

        for i in range(len(grid) - 1):
            if known[grid[i]] != known[grid[i + 1]]:
                bisect(grid[i], grid[i + 1])
        changes.sort()
        rows = []
        for (blk, old, new) in changes:
            hdr = call("eth_getBlockByNumber", [hex(blk), False])
            rows.append({"block": blk, "before_block": blk - 1, "timestamp": int(hdr["timestamp"], 16),
                         "from_impl": addr(old), "to_impl": addr(new),
                         "version_before": version_at(proxy, blk - 1), "version_after": version_at(proxy, blk)})
        h, s = holder_slot(e)
        result["contracts"][name] = {"proxy": proxy, "kind": kind, "pointer_holder": h, "pointer_slot": s,
                                     "first_grid_value": addr(known[grid[0]]), "final_impl": addr(known[grid[-1]]),
                                     "changes": rows}
        print(name, len(rows), "changes", file=sys.stderr)
        for r in rows:
            print("   ", r["block"], r["from_impl"], "->", r["to_impl"], r["version_before"], "->", r["version_after"], file=sys.stderr)
        json.dump(result, open(a.out, "w"), indent=1)

if __name__ == "__main__":
    main()
