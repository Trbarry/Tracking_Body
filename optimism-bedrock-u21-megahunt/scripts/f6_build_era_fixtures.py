#!/usr/bin/env python3
"""F6: era fixtures for OP Mainnet — real in-flight objects created under each historical release.

For every fork point i (evidence/F6-fork-points.json) the "era" i is the block range
[blockOf(i), blockOf(i+1) - 1] in which the release installed at point i was live.

 proves          WithdrawalProven logs of the portal in the LAST <=10k blocks of the era (i.e. proofs
                 that were in flight when the NEXT upgrade landed) — one eth_getLogs call per era.
                 The withdrawal struct is decoded from the calldata of the prove transaction
                 (selector 0x4870496f; embedded calls inside Safe/MultiSend/4337 wrappers are found by
                 scanning for the selector and accepted only if the re-hashed struct equals the logged
                 withdrawalHash).
 failedMessages  every FailedRelayedMessage(bytes32) of the L1CrossDomainMessenger since Bedrock
                 (evidence/F6-failed-relayed-logs.json, full-history scan) assigned to its era, with the
                 transaction that produced it and the relayMessage calldata that replays it.

Outputs:
  evidence/F6-era-fixtures/<ERA>.json            full era record
  evidence/F6-era-fixtures/<ERA>/p<i>.json       one prove fixture per file (fast Solidity loader)
  evidence/F6-era-fixtures/<ERA>/m<i>.json       one failed-message fixture per file
  evidence/F6-era-fixtures/index.json            counts per era
Read-only; RPC = local archive proxy http://127.0.0.1:7545.
"""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from f6_rpc import call, batch, get_logs, keccak256

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUTD = os.path.join(ROOT, "evidence", "F6-era-fixtures")
PORTAL = "0xbeb5fc579115071764c7423a4f12edde41f106ed"
L1CDM = "0x25ace71c97b33cc4729cf772ae268934f7ab5fa1"
L2CDM = "0x4200000000000000000000000000000000000007"
T_PROVEN = "0x67a6208cfcc0801d50f6cbe764733f4fddf66ac0b04442061a8a8c0cb6b63f62"
T_PROVEN_EXT1 = "0x798f9f13695f8f045aa5f80ed8efebb695f3c7fe65da381969f2f28bf3c60b97"
T_FINALIZED = "0xdb5c7652857aa163daadd670e116628fb42e869d8ac4251ef8971d9e5727df1b"
SEL_PROVE = "4870496f"
SEL_FINALIZE = "8c3152e9"
SEL_FINALIZE_EXT = "43ca1c50"
SEL_RELAY = "d764ad0b"
MAX_PROVES = 14
WINDOW = 10000

def u(b, i):
    return int.from_bytes(b[i:i + 32], "big")

def decode_wd(args: bytes, tuple_off: int):
    """Decode Types.WithdrawalTransaction located at args[tuple_off:]. Returns dict or None."""
    try:
        t = args[tuple_off:]
        nonce, sender, target, value, gas_limit, doff = u(t, 0), u(t, 32), u(t, 64), u(t, 96), u(t, 128), u(t, 160)
        if sender >> 160 or target >> 160 or doff != 192:
            return None
        ln = u(t, doff)
        if ln > len(t):
            return None
        data = t[doff + 32: doff + 32 + ln]
        if len(data) != ln:
            return None
        wd = {"nonce": hex(nonce), "sender": "0x%040x" % sender, "target": "0x%040x" % target, "value": hex(value),
              "gasLimit": hex(gas_limit), "data": "0x" + data.hex()}
        enc = (nonce.to_bytes(32, "big") + sender.to_bytes(32, "big") + target.to_bytes(32, "big") + value.to_bytes(32, "big")
               + gas_limit.to_bytes(32, "big") + (192).to_bytes(32, "big") + ln.to_bytes(32, "big") + data + b"\x00" * ((-ln) % 32))
        wd["hash"] = "0x" + keccak256(enc).hex()
        return wd
    except Exception:
        return None

def find_calls(inp: bytes, selector_hex: str):
    """Yield (offset, args) for every position where `selector` appears (direct call at 0 or embedded)."""
    sel = bytes.fromhex(selector_hex)
    pos = 0
    while True:
        k = inp.find(sel, pos)
        if k < 0:
            return
        yield k, inp[k + 4:]
        pos = k + 1

def decode_withdrawals(inp_hex: str, selector_hex: str, wanted: set):
    """All withdrawal structs embedded in a tx input for calls with `selector`, keyed by hash (only wanted hashes)."""
    inp = bytes.fromhex(inp_hex[2:])
    out = {}
    for k, args in find_calls(inp, selector_hex):
        if len(args) < 64:
            continue
        off = u(args, 0)
        if off > len(args):
            continue
        wd = decode_wd(args, off)
        if wd and wd["hash"] in wanted and wd["hash"] not in out:
            wd["_callOffset"] = k
            wd["_second"] = hex(u(args, 32))
            out[wd["hash"]] = wd
    return out

def call_nn(method, params, tries=8):
    """call() that also retries on a null result (one upstream of the failover proxy sometimes lacks old txs)."""
    import time
    for a in range(tries):
        r = call(method, params)
        if r is not None:
            return r
        time.sleep(0.5 * (a + 1))
    raise RuntimeError(f"{method} {params} returned null {tries} times")

def eth_call_at(to, data, block):
    return call("eth_call", [{"to": to, "data": data}, hex(block) if isinstance(block, int) else block])

def main():
    fp = json.load(open(os.path.join(ROOT, "evidence", "F6-fork-points.json")))
    points = fp["points"]
    head = int(call("eth_blockNumber", []), 16) - 8
    failed = json.load(open(os.path.join(ROOT, "evidence", "F6-failed-relayed-logs.json")))["logs"]
    os.makedirs(OUTD, exist_ok=True)
    index = {"meta": {"head": head, "window": WINDOW, "portal": PORTAL, "l1cdm": L1CDM,
                      "note": "era i = blocks [blockOf(i), blockOf(i+1)-1]; proves are taken from the last <=10k blocks of the era"},
             "eras": []}
    only = set(sys.argv[1:])
    for i, p in enumerate(points):
        era = p["label"]
        if only and era not in only:
            continue
        start = p["block"]
        end = points[i + 1]["block"] - 1 if i + 1 < len(points) else head
        rec = {"era": era, "tag": p["tag"], "eraStart": start, "eraEnd": end, "nextPoint": points[i + 1]["label"] if i + 1 < len(points) else None,
               "proves": [], "failedMessages": [], "limits": []}
        # ---------------- proves ----------------
        a = max(start, end - WINDOW + 1)
        try:
            logs = get_logs(PORTAL, [[T_PROVEN, T_PROVEN_EXT1]], a, end)
        except Exception as e:
            logs = []
            rec["limits"].append(f"eth_getLogs {a}-{end} refused: {str(e)[:160]}")
        proven = [l for l in logs if l["topics"][0] == T_PROVEN]
        ext = {(l["transactionHash"], l["topics"][1]): "0x" + l["topics"][2][-40:] for l in logs if l["topics"][0] == T_PROVEN_EXT1}
        rec["scan"] = {"from": a, "to": end, "withdrawalProvenLogs": len(proven)}
        # finalized at head?
        hashes = sorted({l["topics"][1] for l in proven})
        fin = batch([("eth_call", [{"to": PORTAL, "data": "0xa14238e7" + h[2:]}, hex(head)]) for h in hashes])
        fin_at_head = {h: (int(r, 16) != 0 if r else None) for h, r in zip(hashes, fin)}
        rec["scan"]["distinctHashes"] = len(hashes)
        rec["scan"]["unfinalizedAtHead"] = sum(1 for h in hashes if fin_at_head[h] is False)
        # choose: unfinalized first (latest first), then finalized (latest first)
        ordered = sorted(proven, key=lambda l: (fin_at_head[l["topics"][1]] is not False, -int(l["blockNumber"], 16), -int(l["logIndex"], 16)))
        seen_tx = {}
        for l in ordered:
            if len(rec["proves"]) >= MAX_PROVES:
                break
            h = l["topics"][1]
            if any(x["hash"] == h for x in rec["proves"]):
                continue
            txh = l["transactionHash"]
            if txh not in seen_tx:
                seen_tx[txh] = call_nn("eth_getTransactionByHash", [txh])
            tx = seen_tx[txh]
            wds = decode_withdrawals(tx["input"], SEL_PROVE, {h})
            if h not in wds:
                rec.setdefault("undecodable", []).append({"tx": txh, "hash": h, "to": tx["to"], "selector": tx["input"][:10]})
                continue
            wd = wds[h]
            blk = int(l["blockNumber"], 16)
            direct = (tx["to"] or "").lower() == PORTAL and tx["input"][2:10] == SEL_PROVE
            submitter = ext.get((txh, h)) or (tx["from"] if direct else None)
            hdr = call_nn("eth_getBlockByNumber", [hex(blk), False])
            fx = {"era": era, "hash": h, "nonce": wd["nonce"], "sender": wd["sender"], "target": wd["target"], "value": wd["value"],
                  "gasLimit": wd["gasLimit"], "data": wd["data"],
                  "kind": "messenger" if wd["sender"] == L2CDM else "plain", "hasValue": int(wd["value"], 16) != 0,
                  "proofSubmitter": submitter or "0x0000000000000000000000000000000000000000",
                  "submitterKnown": submitter is not None,
                  "proofRefIndex": wd["_second"],  # l2OutputIndex (pre fault proofs) or disputeGameIndex
                  "proveTx": txh, "proveTxFrom": tx["from"], "proveTxTo": tx["to"], "proveTxIndex": int(tx["transactionIndex"], 16),
                  "proveTxGas": int(tx["gas"], 16), "proveTxValue": tx["value"],
                  "direct": direct, "proveBlock": blk, "proveTimestamp": int(hdr["timestamp"], 16),
                  "finalizedAtHead": fin_at_head[h], "headBlock": head, "proveTxInput": tx["input"]}
            # what the portal stored (era-dependent ABI)
            try:
                if submitter and i >= 7:  # fault-proof portal: provenWithdrawals(bytes32,address) -> (game, timestamp)
                    r = eth_call_at(PORTAL, "0xbb2c727e" + h[2:] + submitter[2:].rjust(64, "0"), blk)
                    fx["storedGame"] = "0x" + r[26:66]
                    fx["storedTimestamp"] = int(r[66:130], 16)
                    fx["proofModel"] = "disputeGame"
                else:  # legacy: provenWithdrawals(bytes32) -> (outputRoot, timestamp, l2OutputIndex)
                    r = eth_call_at(PORTAL, "0xe965084c" + h[2:], blk)
                    fx["storedOutputRoot"] = "0x" + r[2:66]
                    fx["storedTimestamp"] = int(r[66:130], 16)
                    fx["storedL2OutputIndex"] = int(r[130:194], 16)
                    fx["storedGame"] = "0x0000000000000000000000000000000000000000"
                    fx["proofModel"] = "l2OutputOracle"
            except Exception as e:
                fx["proofModel"] = "unknown"
                fx["storedGame"] = "0x0000000000000000000000000000000000000000"
                fx["storedTimestamp"] = 0
                rec["limits"].append(f"provenWithdrawals read failed for {h}: {str(e)[:100]}")
            rec["proves"].append(fx)
        # ---------------- failed messages ----------------
        for lg in failed:
            if not (start <= lg["block"] <= end):
                continue
            tx = call_nn("eth_getTransactionByHash", [lg["tx"]])
            hdr = call_nn("eth_getBlockByNumber", [hex(lg["block"]), False])
            inp = bytes.fromhex(tx["input"][2:])
            fx = {"era": era, "msgHash": lg["msgHash"], "block": lg["block"], "timestamp": int(hdr["timestamp"], 16), "tx": lg["tx"],
                  "txFrom": tx["from"], "txTo": tx["to"], "txIndex": lg["txIndex"], "txGas": int(tx["gas"], 16), "txValue": tx["value"],
                  "txSelector": tx["input"][:10], "txInput": tx["input"]}
            # relayMessage calldata whose keccak is the (v1) message hash
            relay = None
            for k, args in find_calls(inp, SEL_RELAY):
                # relayMessage(uint256,address,address,uint256,uint256,bytes): head 6 words, bytes offset 0xc0
                if len(args) < 224 or u(args, 160) != 192:
                    continue
                ln = u(args, 192)
                tot = 224 + ln + ((-ln) % 32)
                cd = bytes.fromhex(SEL_RELAY) + args[:tot]
                if "0x" + keccak256(cd).hex() == lg["msgHash"]:
                    relay = cd
                    fx["relay"] = {"nonce": hex(u(args, 0)), "sender": "0x%040x" % u(args, 32), "target": "0x%040x" % u(args, 64),
                                   "value": hex(u(args, 96)), "minGasLimit": hex(u(args, 128)), "message": "0x" + args[224:224 + ln].hex()}
                    break
            fx["relayCalldata"] = "0x" + relay.hex() if relay else "0x"
            fx["hashIsV1"] = relay is not None
            # how it was produced: portal finalize (first failure) or direct replay on the messenger
            kind = "unknown"
            wds = {}
            for sel in (SEL_FINALIZE, SEL_FINALIZE_EXT):
                for k, args in find_calls(inp, sel):
                    if len(args) < 64:
                        continue
                    wd = decode_wd(args, u(args, 0)) if u(args, 0) < len(args) else None
                    if wd and relay and bytes.fromhex(wd["data"][2:]) == relay:
                        wds = wd
                        kind = "portalFinalize"
            if kind == "unknown" and relay is not None:
                kind = "messengerReplay"
            fx["producedBy"] = kind
            if wds:
                fx["withdrawal"] = {k: wds[k] for k in ("hash", "nonce", "sender", "target", "value", "gasLimit", "data")}
            # state at head and right after the tx's block
            sm, fm, sm0, fm0 = batch([
                ("eth_call", [{"to": L1CDM, "data": "0xb1b1b209" + lg["msgHash"][2:]}, hex(head)]),
                ("eth_call", [{"to": L1CDM, "data": "0xa4e7f8bd" + lg["msgHash"][2:]}, hex(head)]),
                ("eth_call", [{"to": L1CDM, "data": "0xb1b1b209" + lg["msgHash"][2:]}, hex(lg["block"])]),
                ("eth_call", [{"to": L1CDM, "data": "0xa4e7f8bd" + lg["msgHash"][2:]}, hex(lg["block"])]),
            ])
            fx["successfulAtHead"] = int(sm, 16) != 0
            fx["failedAtHead"] = int(fm, 16) != 0
            fx["successfulAfterBlock"] = int(sm0, 16) != 0
            fx["failedAfterBlock"] = int(fm0, 16) != 0
            fx["headBlock"] = head
            rec["failedMessages"].append(fx)
        # ---------------- write ----------------
        json.dump(rec, open(os.path.join(OUTD, era + ".json"), "w"), indent=1)
        d = os.path.join(OUTD, era)
        os.makedirs(d, exist_ok=True)
        for k, fx in enumerate(rec["proves"]):
            json.dump(fx, open(os.path.join(d, f"p{k}.json"), "w"), indent=1)
        for k, fx in enumerate(rec["failedMessages"]):
            json.dump(fx, open(os.path.join(d, f"m{k}.json"), "w"), indent=1)
        json.dump({"era": era, "proves": len(rec["proves"]), "failedMessages": len(rec["failedMessages"])}, open(os.path.join(d, "count.json"), "w"))
        e = {"era": era, "eraStart": start, "eraEnd": end, "scan": rec["scan"], "proves": len(rec["proves"]),
             "provesUnfinalizedAtHead": sum(1 for x in rec["proves"] if x["finalizedAtHead"] is False),
             "failedMessages": len(rec["failedMessages"]),
             "failedStillFailedAtHead": sum(1 for x in rec["failedMessages"] if x["failedAtHead"] and not x["successfulAtHead"]),
             "undecodableProveTxs": len(rec.get("undecodable", [])), "limits": rec["limits"]}
        index["eras"].append(e)
        print(json.dumps(e), file=sys.stderr, flush=True)
    if not only:
        json.dump(index, open(os.path.join(OUTD, "index.json"), "w"), indent=1)

if __name__ == "__main__":
    main()
