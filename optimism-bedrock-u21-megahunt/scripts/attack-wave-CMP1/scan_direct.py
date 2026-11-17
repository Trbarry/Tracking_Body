#!/usr/bin/env python3
# CMP1: census of DIRECT (sender != L2CrossDomainMessenger) withdrawals proven on the four portals and
# not finalized at the L1 pin. Passive reads only (local archive proxy :7545, pinned reads at 26433900).
import json, sys, urllib.request
RPC = "http://127.0.0.1:7545"
PIN = 26433900
PORTALS = {"op": ("0xbEb5Fc579115071764c7423A4f12eDde41f106Ed", 17422590),
           "ink": ("0x5d66C1782664115999C47c9fA5cd031f495D3e4F", 21000000),
           "soneium": ("0x88e529A6ccd302c948689Cd5156C83D4614FAE92", 21000000),
           "unichain": ("0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2", 21000000)}
L2CDM = "0x" + "42" + "00" * 18 + "07"
T_PROVEN = "0x67a6208cfcc0801d50f6cbe764733f4fddf66ac0b04442061a8a8c0cb6b63f62"
T_EXT1 = "0x798f9f13695f8f045aa5f80ed8efebb695f3c7fe65da381969f2f28bf3c60b97"  # WithdrawalProvenExtension1(bytes32,address)
def rpc(m, p):
    r = urllib.request.Request(RPC, json.dumps({"jsonrpc": "2.0", "id": 1, "method": m, "params": p}).encode(), {"Content-Type": "application/json"})
    res = json.load(urllib.request.urlopen(r, timeout=300))
    if "error" in res: raise RuntimeError(res["error"])
    return res["result"]
def logs(addr, topics, a, b):
    try:
        return rpc("eth_getLogs", [{"address": addr, "topics": topics, "fromBlock": hex(a), "toBlock": hex(b)}])
    except Exception:
        if b - a < 2000: raise
        m = (a + b) // 2
        return logs(addr, topics, a, m) + logs(addr, topics, m + 1, b)
def call(to, data, blk=PIN):
    return rpc("eth_call", [{"to": to, "data": data}, hex(blk)])
out = {}
for name, (portal, start) in PORTALS.items():
    rows = []
    a = start
    while a <= PIN:
        b = min(a + 500000, PIN)
        for l in logs(portal, [T_PROVEN], a, b):
            frm = "0x" + l["topics"][2][26:]
            if frm == L2CDM.lower(): continue
            rows.append({"hash": l["topics"][1], "from": frm, "to": "0x" + l["topics"][3][26:], "block": int(l["blockNumber"], 16), "tx": l["transactionHash"]})
        a = b + 1
    # finalized at pin?  finalizedWithdrawals(bytes32) = 0xa14238e7
    for r in rows:
        r["finalizedAtPin"] = int(call(portal, "0xa14238e7" + r["hash"][2:]), 16) == 1
        tx = None
        for _ in range(4):
            tx = rpc("eth_getTransactionByHash", [r["tx"]])
            if tx: break
        tx = tx or {"from": None, "to": None, "input": "0x"}
        r["txFrom"] = tx["from"]; r["txTo"] = tx["to"]; r["input"] = tx["input"]
        rc = rpc("eth_getTransactionReceipt", [r["tx"]]) or {"logs": []}
        subs = [("0x" + x["topics"][2][26:]) for x in rc["logs"] if x["topics"] and x["topics"][0] == T_EXT1 and x["topics"][1] == r["hash"]]
        r["proofSubmitters"] = subs
        code = rpc("eth_getCode", [r["to"], hex(PIN)])
        r["targetCodeLen"] = (len(code) - 2) // 2
    out[name] = rows
    print(name, "direct proofs", len(rows), "unfinalized", sum(1 for r in rows if not r["finalizedAtPin"]), flush=True)
json.dump(out, open(sys.argv[1], "w"), indent=1)
