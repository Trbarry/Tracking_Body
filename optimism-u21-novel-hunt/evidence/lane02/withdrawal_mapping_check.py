#!/usr/bin/env python3
"""Read proven/finalized withdrawal mapping entries through v8 (block N-1, :8546), v9 at N (:8547) and v9 at 26433900 (:8545):
raw slots and public getters. Read-only."""
import json, subprocess, urllib.request
RPCS = {"N-1(v8)": "http://127.0.0.1:8546", "N(v9)": "http://127.0.0.1:8547", "26433900(v9)": "http://127.0.0.1:8545"}
N = 26430859
portals={"op":"0xbEb5Fc579115071764c7423A4f12eDde41f106Ed","ink":"0x5d66C1782664115999C47c9fA5cd031f495D3e4F","soneium":"0x88e529A6ccd302c948689Cd5156C83D4614FAE92","unichain":"0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2"}
logs = json.load(open("evidence/lane02/portal_withdrawal_logs.json"))
def rpc(url, method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    for i in range(9):
        try:
            r = json.loads(urllib.request.urlopen(urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"}), timeout=120).read())
            if "result" in r: return r["result"]
            err = r.get("error")
            if err and "revert" in json.dumps(err).lower(): return {"revert": err}
        except Exception as e: err = str(e)
        import time; time.sleep(2 + 2 * i)
    if method == "eth_getStorageAt": raise RuntimeError("storage read failed: %r" % (err,))
    return {"error": err}
def keccak(h): return subprocess.check_output(["cast", "keccak", h]).decode().strip()
def pad(x): return x.lower().replace("0x", "").rjust(64, "0")
def sel(s): return subprocess.check_output(["cast", "sig", s]).decode().strip()
S_NUM = sel("numProofSubmitters(bytes32)"); S_SUB = sel("proofSubmitters(bytes32,uint256)"); S_PW = sel("provenWithdrawals(bytes32,address)")
S_FIN = sel("finalizedWithdrawals(bytes32)"); S_CHK = sel("checkWithdrawal(bytes32,address)")
out = {}; mism = 0; total = 0
for ch, p in portals.items():
    out[ch] = []
    hashes = {}
    for l in logs[ch]["proven"]: hashes.setdefault(l["topics"][1], {"provenBlocks": [], "finalizedBlock": None})["provenBlocks"].append(int(l["blockNumber"], 16))
    for l in logs[ch]["finalized"]: hashes.setdefault(l["topics"][1], {"provenBlocks": [], "finalizedBlock": None})["finalizedBlock"] = int(l["blockNumber"], 16)
    ext = {}
    for l in logs[ch]["ext"]: ext.setdefault(l["topics"][1], []).append("0x" + l["topics"][2][26:])
    for h, info in hashes.items():
        # only entries that existed before the upgrade (proven before N, or finalized after N => proven >=7d earlier under v8)
        proven_pre = any(b < N for b in info["provenBlocks"]); fin = info["finalizedBlock"]
        if not (proven_pre or (fin is not None)): continue
        rec = {"withdrawalHash": h, **info, "submittersFromLogs": ext.get(h, []), "views": {}}
        slot_fin = keccak("0x" + pad(h) + pad(hex(51))); slot_len = keccak("0x" + pad(h) + pad(hex(60))); slot_arr0 = keccak(slot_len)
        inner = keccak("0x" + pad(h) + pad(hex(57)))
        for tag, url in RPCS.items():
            v = {}
            v["raw.finalizedWithdrawals"] = rpc(url, "eth_getStorageAt", [p, slot_fin, "latest"])
            v["raw.proofSubmitters.length"] = rpc(url, "eth_getStorageAt", [p, slot_len, "latest"])
            n = int(v["raw.proofSubmitters.length"], 16)
            v["getter.numProofSubmitters"] = rpc(url, "eth_call", [{"to": p, "data": S_NUM + pad(h)}, "latest"])
            v["getter.finalizedWithdrawals"] = rpc(url, "eth_call", [{"to": p, "data": S_FIN + pad(h)}, "latest"])
            subs = []
            for i in range(min(n, 4)):
                raw_sub = rpc(url, "eth_getStorageAt", [p, hex(int(slot_arr0, 16) + i), "latest"])
                sub = "0x" + raw_sub[-40:]
                slot_pw = keccak("0x" + pad(sub) + pad(inner))
                e = {"submitter.raw": raw_sub, "submitter.getter": rpc(url, "eth_call", [{"to": p, "data": S_SUB + pad(h) + pad(hex(i))}, "latest"]),
                     "provenWithdrawals.rawslot": slot_pw, "provenWithdrawals.raw": rpc(url, "eth_getStorageAt", [p, slot_pw, "latest"]),
                     "provenWithdrawals.getter": rpc(url, "eth_call", [{"to": p, "data": S_PW + pad(h) + pad(sub)}, "latest"]),
                     "checkWithdrawal": rpc(url, "eth_call", [{"to": p, "data": S_CHK + pad(h) + pad(sub)}, "latest"])}
                subs.append(e)
            v["submitters"] = subs
            rec["views"][tag] = v
        # compare N-1 vs N for entries whose proof pre-dates N and that were not finalized inside block N
        a, b = rec["views"]["N-1(v8)"], rec["views"]["N(v9)"]
        same = True
        for k in ("raw.finalizedWithdrawals", "raw.proofSubmitters.length", "getter.numProofSubmitters", "getter.finalizedWithdrawals"):
            if a[k] != b[k]: same = False
        for x, y in zip(a["submitters"], b["submitters"]):
            for k in ("submitter.raw", "submitter.getter", "provenWithdrawals.raw", "provenWithdrawals.getter"):
                if x[k] != y[k]: same = False
        if len(a["submitters"]) != len(b["submitters"]): same = False
        rec["identical_N-1_vs_N(raw+getters)"] = same
        total += 1; mism += (not same)
        out[ch].append(rec)
    print(ch, "entries", len(out[ch]))
json.dump(out, open("evidence/lane02/withdrawal_mapping_check.json", "w"), indent=1)
print("total entries", total, "mismatching N-1 vs N", mism)
