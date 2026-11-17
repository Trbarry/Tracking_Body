#!/usr/bin/env python3
"""N (26430859) -> 26433900 raw storage delta for every touched proxy (same slot set as the state dumps)."""
import json, urllib.request, time, sys
R = "http://127.0.0.1:8545"
base = json.load(open("POST_UPGRADE_STATE.json"))
NSLOTS = dict(SystemConfig=112, OptimismPortal2=72, ETHLockbox=70, AnchorStateRegistry=70, DisputeGameFactory=108, DelayedWETH=70,
              L1CrossDomainMessenger=258, L1StandardBridge=70, L1ERC721Bridge=70, OptimismMintableERC20Factory=70, ProxyAdmin=70, SuperchainConfig=70)
def batch(calls):
    out = {}
    todo = list(range(len(calls)))
    fails = 0
    while todo:
        chunk = todo[:60]
        body = json.dumps([{"jsonrpc": "2.0", "id": i, "method": calls[i][0], "params": calls[i][1]} for i in chunk]).encode()
        try:
            r = json.loads(urllib.request.urlopen(urllib.request.Request(R, data=body, headers={"Content-Type": "application/json"}), timeout=300).read())
            ok = 0
            for x in r:
                if "result" in x: out[x["id"]] = x["result"]; todo.remove(x["id"]); ok += 1
            if not ok: raise RuntimeError(str(r)[:200])
        except Exception as e:
            fails += 1
            if fails > 40: raise
            print("retry", fails, str(e)[:100], file=sys.stderr); time.sleep(min(20, 2 * fails))
    return [out[i] for i in range(len(calls))]
lines = []
for ch in base:
    if ch == "_meta": continue
    lines.append("===== " + ch)
    for name, c in base[ch].items():
        n = NSLOTS[name]; addr = c["proxy"]
        named = list(c["namedSlots"].items())
        calls = [("eth_getStorageAt", [addr, hex(i), "latest"]) for i in range(n)] + [("eth_getStorageAt", [addr, v["slot"], "latest"]) for k, v in named] + [("eth_getBalance", [addr, "latest"])]
        r = batch(calls)
        rows = []
        for i in range(n):
            a = c["slots"].get(str(i), {}).get("raw", "0x" + "0" * 64)
            if a != r[i]: rows.append(f"   slot {i} [{c['slots'].get(str(i), {}).get('label', '?')[:50]}] {a} -> {r[i]}")
        for j, (k, v) in enumerate(named):
            if v["raw"] != r[n + j]: rows.append(f"   named {k} {v['raw']} -> {r[n + j]}")
        bal = int(r[-1], 16)
        if str(bal) != c["ethBalance"]: rows.append(f"   ethBalance {int(c['ethBalance'])/1e18:.6f} -> {bal/1e18:.6f} (delta {(bal-int(c['ethBalance']))/1e18:+.6f})")
        lines.append(f"-- {name} {addr} | changed items: {len(rows)}")
        lines += rows
        print(ch, name, len(rows), file=sys.stderr, flush=True)
open("evidence/lane02/delta_N_to_26433900.txt", "w").write("\n".join(lines) + "\n")
print("\n".join(lines))
