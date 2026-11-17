#!/usr/bin/env python3
# Passive scan of OP Mainnet L2CrossDomainMessenger SentMessage logs (Bedrock era) via the local archive proxy.
import json, sys, urllib.request, concurrent.futures as cf
RPC = "http://127.0.0.1:7546"
L2CDM = "0x4200000000000000000000000000000000000007"
T0 = "0xcb0f7ffd78f9aee47a248fae8db181db6eee833039123e026dcbff529522e52a"  # SentMessage(address,address,bytes,uint256,uint256)
START, END, STEP = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3])
OUT = sys.argv[4]
def rpc(m, p):
    r = urllib.request.Request(RPC, json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(), {"Content-Type":"application/json"})
    return json.load(urllib.request.urlopen(r, timeout=300))
def get(a, b):
    res = rpc("eth_getLogs", [{"address": L2CDM, "topics": [T0], "fromBlock": hex(a), "toBlock": hex(b)}])
    if "error" in res:
        if b - a < 1000: raise RuntimeError(res["error"])
        m = (a + b) // 2
        return get(a, m) + get(m + 1, b)
    return res["result"]
def dec(l):
    d = bytes.fromhex(l["data"][2:])
    sender = "0x" + d[12:32].hex()
    off = int.from_bytes(d[32:64], "big")
    nonce = int.from_bytes(d[64:96], "big")
    gas = int.from_bytes(d[96:128], "big")
    ln = int.from_bytes(d[off:off+32], "big")
    msg = d[off+32:off+32+ln]
    return {"blk": int(l["blockNumber"], 16), "tx": l["transactionHash"], "target": "0x" + l["topics"][1][26:],
            "sender": sender, "nonce": hex(nonce), "gas": gas, "len": ln, "sel": "0x" + msg[:4].hex(), "msg": "0x" + msg.hex()}
ranges = [(a, min(a + STEP - 1, END)) for a in range(START, END + 1, STEP)]
out = []
with cf.ThreadPoolExecutor(4) as ex:
    for i, logs in enumerate(ex.map(lambda r: get(*r), ranges)):
        out += [dec(l) for l in logs]
        if i % 10 == 0: print(ranges[i], len(out), flush=True)
json.dump(out, open(OUT, "w"))
print("done", len(out))
