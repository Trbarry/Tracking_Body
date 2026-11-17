#!/usr/bin/env python3
"""F2 — metadata of every dispute-game implementation ever registered in a DisputeGameFactory.

Input: an F2-call-history-<chain>.json produced by F2_call_history.py (targets dgf.gameImpls(t)).
For each (game type, implementation, registration block) it reads, AT the registration block:
version(), gameType(), absolutePrestate(), vm(), weth(), anchorStateRegistry(), l2ChainId(),
maxGameDepth(), splitDepth(), maxClockDuration(), clockExtension(), proposer(), challenger()
on the implementation, plus DisputeGameFactory.gameArgs(t) and initBonds(t) (creator-pattern
implementations keep prestate/vm/asr/weth in gameArgs, the bare implementation returns zero).
Read-only. usage: F2_game_impls.py <call-history.json> <dgf> <out.json>
"""
import json, subprocess, sys, time, urllib.request

RPC = "http://127.0.0.1:7545"
GETTERS = ["version()", "gameType()", "absolutePrestate()", "vm()", "weth()", "anchorStateRegistry()",
           "l2ChainId()", "maxGameDepth()", "splitDepth()", "maxClockDuration()", "clockExtension()",
           "proposer()", "challenger()"]


def sel(sig, *args):
    return subprocess.check_output(["cast", "calldata", sig] + [str(a) for a in args]).decode().strip()


def batch(calls):
    out = [None] * len(calls)
    for off in range(0, len(calls), 30):
        ch = calls[off:off + 30]
        body = [{"jsonrpc": "2.0", "id": i, "method": m, "params": p} for i, (m, p) in enumerate(ch)]
        for a in range(6):
            try:
                req = urllib.request.Request(RPC, data=json.dumps(body).encode(), headers={"content-type": "application/json"})
                res = json.loads(urllib.request.urlopen(req, timeout=120).read())
                ok = True
                for it in res:
                    if "result" in it:
                        out[off + it["id"]] = it["result"]
                    elif "revert" not in str(it.get("error")).lower() and "execution" not in str(it.get("error")).lower():
                        ok = False
                if ok:
                    break
            except Exception:
                pass
            time.sleep(1.5 * (a + 1))
    return out


def dec_string(h):
    try:
        raw = bytes.fromhex(h[2:]); off = int.from_bytes(raw[:32], "big"); ln = int.from_bytes(raw[off:off + 32], "big")
        return raw[off + 32:off + 32 + ln].decode()
    except Exception:
        return None


def dec_bytes(h):
    try:
        raw = bytes.fromhex(h[2:]); off = int.from_bytes(raw[:32], "big"); ln = int.from_bytes(raw[off:off + 32], "big")
        return "0x" + raw[off + 32:off + 32 + ln].hex()
    except Exception:
        return None


def main():
    hist = json.load(open(sys.argv[1]))
    dgf = sys.argv[2]
    sels = {g: sel(g) for g in GETTERS}
    rows = []
    for t in hist["targets"]:
        if not t["name"].startswith("dgf.gameImpls("):
            continue
        gt = int(t["args"][0])
        h = t["history"]
        for i, r in enumerate(h):
            v = r["value"]
            if not v or int(v, 16) == 0:
                continue
            impl = "0x" + v[-40:]
            blk = r["block"]
            until = h[i + 1]["block"] if i + 1 < len(h) else None
            calls = [("eth_call", [{"to": impl, "data": sels[g]}, hex(blk)]) for g in GETTERS]
            calls.append(("eth_call", [{"to": dgf, "data": sel("gameArgs(uint32)", gt)}, hex(blk)]))
            calls.append(("eth_call", [{"to": dgf, "data": sel("initBonds(uint32)", gt)}, hex(blk)]))
            res = batch(calls)
            d = {"game_type": gt, "implementation": impl, "registered_block": blk, "registered_utc": r["utc"],
                 "replaced_block": until, "replaced_utc": (h[i + 1]["utc"] if until else None)}
            for g, x in zip(GETTERS, res):
                k = g[:-2]
                if x in (None, "0x"):
                    d[k] = None
                elif k == "version":
                    d[k] = dec_string(x)
                elif k in ("vm", "weth", "anchorStateRegistry", "proposer", "challenger"):
                    d[k] = "0x" + x[-40:]
                elif k == "absolutePrestate":
                    d[k] = x
                else:
                    d[k] = int(x, 16)
            ga = dec_bytes(res[-2]) if res[-2] not in (None, "0x") else None
            d["dgf_gameArgs"] = ga
            if ga and len(ga) >= 2 + 2 * 124:
                b = bytes.fromhex(ga[2:])
                d["gameArgs_decoded"] = {"absolutePrestate": "0x" + b[0:32].hex(), "vm": "0x" + b[32:52].hex(),
                                         "anchorStateRegistry": "0x" + b[52:72].hex(), "weth": "0x" + b[72:92].hex(),
                                         "l2ChainId": int.from_bytes(b[92:124], "big"),
                                         "proposer": ("0x" + b[124:144].hex()) if len(b) >= 144 else None,
                                         "challenger": ("0x" + b[144:164].hex()) if len(b) >= 164 else None,
                                         "length_bytes": len(b),
                                         "layout_assumed": "prestate(32)|vm(20)|asr(20)|weth(20)|l2ChainId(32)[|proposer(20)|challenger(20)]"}
            d["dgf_initBond_wei"] = int(res[-1], 16) if res[-1] not in (None, "0x") else None
            rows.append(d)
            print(gt, impl, r["utc"], d.get("version"), d.get("absolutePrestate") or (d.get("gameArgs_decoded") or {}).get("absolutePrestate"),
                  d.get("weth") or (d.get("gameArgs_decoded") or {}).get("weth"), d.get("anchorStateRegistry") or (d.get("gameArgs_decoded") or {}).get("anchorStateRegistry"), flush=True)
    rows.sort(key=lambda x: (x["registered_block"], x["game_type"]))
    json.dump({"rpc": RPC, "dgf": dgf, "source_history": sys.argv[1], "implementations": rows}, open(sys.argv[3], "w"), indent=1)


if __name__ == "__main__":
    main()
