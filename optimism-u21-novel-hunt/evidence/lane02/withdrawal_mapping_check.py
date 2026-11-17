#!/usr/bin/env python3
"""LANE 02: read real proven/finalized withdrawal mapping entries through the v8 implementation (block N-1 = 26430858),
the v9 implementation at N (26430859) and at 26433900. Raw slots + public getters via the shared local anvil forks
(passive eth_getStorageAt / eth_call only)."""
import json, subprocess, urllib.request, time, sys
N = 26430859
BLOCKS = {"N-1(v8)": "http://127.0.0.1:8546", "N(v9)": "http://127.0.0.1:8547", "26433900(v9)": "http://127.0.0.1:8545"}  # local anvil forks pinned at those blocks
portals = {"op": "0xbEb5Fc579115071764c7423A4f12eDde41f106Ed", "ink": "0x5d66C1782664115999C47c9fA5cd031f495D3e4F",
           "soneium": "0x88e529A6ccd302c948689Cd5156C83D4614FAE92", "unichain": "0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2"}
logs = json.load(open("evidence/lane02/portal_withdrawal_logs.json"))
def batch(calls, U):
    out = [None] * len(calls)
    todo = list(range(len(calls)))
    fails = 0
    while todo:
        chunk = todo[:30]
        body = json.dumps([{"jsonrpc": "2.0", "id": i, "method": calls[i][0], "params": calls[i][1]} for i in chunk]).encode()
        try:
            r = json.loads(urllib.request.urlopen(urllib.request.Request(U, data=body, headers={"Content-Type": "application/json", "User-Agent": "research-client"}), timeout=120).read())
            if isinstance(r, dict): raise RuntimeError(str(r)[:200])
            progressed = False
            for x in r:
                if "result" in x: out[x["id"]] = x["result"]; todo.remove(x["id"]); progressed = True
                elif "error" in x and ("revert" in json.dumps(x["error"]).lower()):
                    out[x["id"]] = {"revert": x["error"].get("data") or x["error"].get("message")}; todo.remove(x["id"]); progressed = True
            if not progressed: raise RuntimeError(str(r)[:200])
            fails = 0; time.sleep(0.05)
        except Exception as e:
            fails += 1
            if fails > 25: raise
            print("retry", fails, str(e)[:120], file=sys.stderr); time.sleep(min(30, 2 * fails))
    return out
def keccak(h): return subprocess.check_output(["cast", "keccak", h]).decode().strip()
def pad(x): return x.lower().replace("0x", "").rjust(64, "0")
def sel(s): return subprocess.check_output(["cast", "sig", s]).decode().strip()
S_NUM = sel("numProofSubmitters(bytes32)"); S_SUB = sel("proofSubmitters(bytes32,uint256)"); S_PW = sel("provenWithdrawals(bytes32,address)")
S_FIN = sel("finalizedWithdrawals(bytes32)"); S_CHK = sel("checkWithdrawal(bytes32,address)")
out = {}; total = 0; mism = 0
for ch, p in portals.items():
    hashes = {}
    for l in logs[ch]["proven"]: hashes.setdefault(l["topics"][1], {"provenBlocks": [], "finalizedBlock": None})["provenBlocks"].append(int(l["blockNumber"], 16))
    for l in logs[ch]["finalized"]: hashes.setdefault(l["topics"][1], {"provenBlocks": [], "finalizedBlock": None})["finalizedBlock"] = int(l["blockNumber"], 16)
    def prio(kv):
        h, info = kv
        return (0 if (info["finalizedBlock"] or 0) >= N else 1, -(min(info["provenBlocks"]) if info["provenBlocks"] else 0))
    items = [kv for kv in sorted(hashes.items(), key=prio) if (kv[1]["finalizedBlock"] or 0) >= N or any(b < N for b in kv[1]["provenBlocks"])][:12]
    recs = []
    # phase 1: array length + first submitter at N-1
    calls = []
    for h, info in items:
        slot_len = keccak("0x" + pad(h) + pad(hex(60))); slot_arr0 = keccak(slot_len)
        recs.append({"withdrawalHash": h, **info, "slot.finalizedWithdrawals": keccak("0x" + pad(h) + pad(hex(51))), "slot.proofSubmitters.length": slot_len,
                     "slot.proofSubmitters[0]": slot_arr0, "inner57": keccak("0x" + pad(h) + pad(hex(57)))})
        calls += [("eth_getStorageAt", [p, slot_len, "latest"]), ("eth_getStorageAt", [p, slot_arr0, "latest"])]
    r = batch(calls, BLOCKS["N-1(v8)"])
    for i, rec in enumerate(recs):
        rec["submitter0"] = "0x" + r[2*i+1][-40:]; rec["slot.provenWithdrawals[h][submitter0]"] = keccak("0x" + pad(rec["submitter0"]) + pad(rec["inner57"]))
    # phase 2: everything at the three blocks
    for tag, url in BLOCKS.items():
        calls = []; blk = "latest"
        for rec in recs:
            h = rec["withdrawalHash"]; s = rec["submitter0"]
            calls += [("eth_getStorageAt", [p, rec["slot.finalizedWithdrawals"], blk]), ("eth_getStorageAt", [p, rec["slot.proofSubmitters.length"], blk]),
                      ("eth_getStorageAt", [p, rec["slot.proofSubmitters[0]"], blk]), ("eth_getStorageAt", [p, rec["slot.provenWithdrawals[h][submitter0]"], blk]),
                      ("eth_call", [{"to": p, "data": S_FIN + pad(h)}, blk]), ("eth_call", [{"to": p, "data": S_NUM + pad(h)}, blk]),
                      ("eth_call", [{"to": p, "data": S_SUB + pad(h) + pad("0x0")}, blk]), ("eth_call", [{"to": p, "data": S_PW + pad(h) + pad(s)}, blk]),
                      ("eth_call", [{"to": p, "data": S_CHK + pad(h) + pad(s)}, blk])]
        r = batch(calls, url)
        for i, rec in enumerate(recs):
            k = ["raw.finalizedWithdrawals", "raw.proofSubmitters.length", "raw.proofSubmitters[0]", "raw.provenWithdrawals[h][submitter0]",
                 "getter.finalizedWithdrawals", "getter.numProofSubmitters", "getter.proofSubmitters(h,0)", "getter.provenWithdrawals(h,submitter0)", "call.checkWithdrawal(h,submitter0)"]
            rec.setdefault("views", {})[tag] = dict(zip(k, r[9*i:9*i+9]))
    for rec in recs:
        a, b = rec["views"]["N-1(v8)"], rec["views"]["N(v9)"]
        rec["identical_N-1_vs_N"] = all(a[k] == b[k] for k in a if not k.startswith("call."))
        pw = a["raw.provenWithdrawals[h][submitter0]"]
        rec["decoded_N-1"] = {"disputeGameProxy": "0x" + pw[-40:], "timestamp": int(pw[2:2+24][-16:], 16), "finalized": int(a["raw.finalizedWithdrawals"], 16) != 0}
        total += 1; mism += (not rec["identical_N-1_vs_N"])
    out[ch] = recs
    print(ch, "entries", len(recs), flush=True)
json.dump(out, open("evidence/lane02/withdrawal_mapping_check.json", "w"), indent=1)
print("total entries", total, "non-identical N-1 vs N (raw+getters)", mism)
