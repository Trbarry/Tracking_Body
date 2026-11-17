#!/usr/bin/env python3
"""Legacy (pre-Bedrock OVM) L2CrossDomainMessenger SentMessage scan on OP Mainnet blocks 0..105235062:
the migrated version-0 withdrawal gasLimit is 16*len(relayMessage calldata) + 1,300,873 (op-chain-ops
crossdomain/migrate.go:77-121). Report the largest message and how many exceed the delivery edge."""
import json, sys, urllib.request, time
RPC = "http://127.0.0.1:7546"; ADDR = "0x4200000000000000000000000000000000000007"
TOPIC = "0xcb0f7ffd78f9aee47a248fae8db181db6eee833039123e026dcbff529522e52a"
END = 105235062; OUT = sys.argv[1]
def rpc(m, p):
    for i in range(8):
        try:
            j = json.loads(urllib.request.urlopen(urllib.request.Request(RPC, json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(), {"Content-Type":"application/json"}), timeout=180).read())
            if "error" in j: raise Exception(j["error"])
            return j["result"]
        except Exception as e:
            err = e; time.sleep(2 + 3*i)
    raise err
b, step, total, top = 0, 2_000_000, 0, []
while b <= END:
    e = min(b + step - 1, END)
    try:
        logs = rpc("eth_getLogs", [{"address":ADDR,"fromBlock":hex(b),"toBlock":hex(e),"topics":[TOPIC]}])
    except Exception:
        if step > 5000: step //= 4; continue
        raise
    for l in logs:
        d = bytes.fromhex(l["data"][2:]); off = int.from_bytes(d[32:64],"big"); ln = int.from_bytes(d[off:off+32],"big")
        total += 1
        top.append((ln, int(l["blockNumber"],16), l["transactionHash"], int.from_bytes(d[96:128],"big")))
        top = sorted(top, reverse=True)[:20]
    b = e + 1
    if len(logs) < 3000 and step < 8_000_000: step *= 2
    print(e, total, top[0][0] if top else 0, flush=True)
json.dump({"range":[0,END],"total":total,"top20_by_message_len":top}, open(OUT,"w"), indent=1)
print("done", total)
