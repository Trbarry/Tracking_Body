#!/usr/bin/env python3
# CMP1-07: Permit2 Approval/Permit events whose spender is a portal or L1CrossDomainMessenger of the four chains.
import json, sys, urllib.request
RPC = "http://127.0.0.1:7545"
PERMIT2 = "0x000000000022D473030F116dDEE9F6B43aC78BA3"
SPENDERS = ["0xbEb5Fc579115071764c7423A4f12eDde41f106Ed", "0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1",
            "0x5d66C1782664115999C47c9fA5cd031f495D3e4F", "0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f",
            "0x88e529A6ccd302c948689Cd5156C83D4614FAE92", "0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f",
            "0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2", "0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6"]
T_APPROVAL = "0xda9fa7c1b00402c17d0161b249b1ab8bbec047c5a52207b9c112deffd817036b"  # Approval(address,address,address,uint160,uint48)
T_PERMIT = "0xc6a377bfc4eb120024a8ac08eef205be16b817020812c73223e81d1bdb9708ec"    # Permit(address,address,address,uint160,uint48,uint48)
def rpc(m, p):
    r = urllib.request.Request(RPC, json.dumps({"jsonrpc": "2.0", "id": 1, "method": m, "params": p}).encode(), {"Content-Type": "application/json"})
    res = json.load(urllib.request.urlopen(r, timeout=300))
    if "error" in res: raise RuntimeError(res["error"])
    return res["result"]
def logs(a, b):
    topics = [[T_APPROVAL, T_PERMIT], None, None, ["0x" + "0" * 24 + s[2:].lower() for s in SPENDERS]]
    try:
        return rpc("eth_getLogs", [{"address": PERMIT2, "topics": topics, "fromBlock": hex(a), "toBlock": hex(b)}])
    except Exception:
        if b - a < 2000: raise
        m = (a + b) // 2
        return logs(a, m) + logs(m + 1, b)
out = []
a, END = 15986000, 26433900
while a <= END:
    b = min(a + 1000000, END)
    out += logs(a, b)
    a = b + 1
json.dump({"range": [15986000, END], "spenders": SPENDERS, "hits": out}, open(sys.argv[1], "w"), indent=1)
print("hits", len(out))
