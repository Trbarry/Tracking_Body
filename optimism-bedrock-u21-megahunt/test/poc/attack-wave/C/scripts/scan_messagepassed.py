#!/usr/bin/env python3
"""Scan every OP Mainnet L2ToL1MessagePasser MessagePassed log (Bedrock genesis -> pin) and keep
withdrawals whose L1 delivery cost could approach the EIP-7825 cap (gasLimit >= 8M or data >= 50 kB).
Passive reads only, local archive proxy :7546."""
import json, sys, urllib.request, time
RPC = "http://127.0.0.1:7546"
ADDR = "0x4200000000000000000000000000000000000016"
TOPIC = "0x02a52367d10742d8032712c1bb8e0144ff1ec5ffda1ed7d70bb05a2744955054"
START, END = 105235063, int(sys.argv[2]) if len(sys.argv) > 2 else 159654093
OUT = sys.argv[1]
def rpc(m, p):
    for i in range(8):
        try:
            r = urllib.request.urlopen(urllib.request.Request(RPC, json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(), {"Content-Type":"application/json"}), timeout=120)
            j = json.loads(r.read())
            if "error" in j: raise Exception(j["error"])
            return j["result"]
        except Exception as e:
            err = e; time.sleep(2 + 3*i)
    raise err
step, b, total, hits, maxgl, maxlen = 500_000, START, 0, [], (0,None), (0,None)
while b <= END:
    e = min(b + step - 1, END)
    try:
        logs = rpc("eth_getLogs", [{"address":ADDR,"fromBlock":hex(b),"toBlock":hex(e),"topics":[TOPIC]}])
    except Exception as ex:
        if step > 2000: step //= 4; continue
        raise
    for l in logs:
        d = bytes.fromhex(l["data"][2:])
        gl = int.from_bytes(d[32:64],"big"); off = int.from_bytes(d[64:96],"big"); ln = int.from_bytes(d[off:off+32],"big")
        total += 1
        if gl > maxgl[0]: maxgl = (gl, l["transactionHash"])
        if ln > maxlen[0]: maxlen = (ln, l["transactionHash"])
        if gl >= 8_000_000 or ln >= 50_000:
            hits.append({"block": int(l["blockNumber"],16), "tx": l["transactionHash"], "nonce": l["topics"][1], "sender": "0x"+l["topics"][2][-40:], "target": "0x"+l["topics"][3][-40:], "value": str(int.from_bytes(d[0:32],"big")), "gasLimit": gl, "dataLen": ln, "withdrawalHash": "0x"+d[96:128].hex()})
    b = e + 1
    if len(logs) < 3000 and step < 4_000_000: step *= 2
    print(f"{e} total={total} hits={len(hits)} maxgl={maxgl[0]} maxlen={maxlen[0]}", flush=True)
json.dump({"range":[START,END],"total":total,"maxGasLimit":maxgl,"maxDataLen":maxlen,"hits":hits}, open(OUT,"w"), indent=1)
print("done", total, len(hits))
