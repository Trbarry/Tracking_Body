#!/usr/bin/env python3
"""L2 acceptance: gas an ordinary OP Mainnet sender pays to create the measured messages (OP fork :9545 @159654093)."""
import json, urllib.request, subprocess
L2 = "http://127.0.0.1:9545"
def rpc(m, p):
    j = json.loads(urllib.request.urlopen(urllib.request.Request(L2, json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(), {"Content-Type":"application/json"}), timeout=300).read())
    if "error" in j: return "ERR " + json.dumps(j["error"])[:200]
    return j["result"]
sel = subprocess.check_output(["cast", "sig", "sendMessage(address,bytes,uint32)"]).decode().strip()[2:]
w = lambda x: x.to_bytes(32, "big")
pad = lambda b: b + b"\x00" * ((32 - len(b) % 32) % 32)
SENDER = "0x00000000000000000000000000000000000a11ce"
out = []
for L, byte, m in [(0, 0, 16_000_000), (0, 0, 4_000_000_000), (100_000, 0xff, 0), (350_000, 0xff, 0), (400_000, 0, 0), (1_000_000, 0, 0)]:
    msg = bytes([byte]) * L
    cd = bytes.fromhex(sel) + w(0xb0b01) + w(0x60) + w(m) + w(L) + pad(msg)
    g = rpc("eth_estimateGas", [{"from": SENDER, "to": "0x4200000000000000000000000000000000000007", "data": "0x" + cd.hex(), "gas": hex(39_000_000)}])
    r = {"msgLen": L, "byte": byte, "minGasLimit": m, "l2_estimateGas": int(g, 16) if not str(g).startswith("ERR") else g}
    print(json.dumps(r), flush=True); out.append(r)
print("L2 block gasLimit", int(rpc("eth_getBlockByNumber", ["latest", False])["gasLimit"], 16))
