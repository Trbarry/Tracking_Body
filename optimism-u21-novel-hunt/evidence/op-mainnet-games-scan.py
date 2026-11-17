#!/usr/bin/env python3
"""Passive scan of every OP Mainnet dispute game created after the ASR retirement timestamp.
Reads only (eth_call via Multicall3 at a pinned block). Output: JSON + summary."""
import json, subprocess, sys, collections

RPC = "http://127.0.0.1:7545"
BLOCK = "26433900"
MC = "0xcA11bde05977b3631167028862bE2a173976CA11"
DGF = "0xe5965Ab5962eDc7477C8520243A95517CD252fA9"
ASR = "0x23B2C62946350F4246f9f9D027e071f0264FD113"
START, END, B = int(sys.argv[1]), int(sys.argv[2]), 20
OUT = sys.argv[3]

def sh(*a):
    for _ in range(6):
        r = subprocess.run(a, capture_output=True, text=True)
        if r.returncode == 0:
            return r.stdout.strip()
    raise RuntimeError(r.stderr[:300])

def sel(sig, *args):
    return sh("cast", "calldata", sig, *map(str, args))

def multicall(calls):
    arg = "[" + ",".join(f"({t},true,{d})" for t, d in calls) + "]"
    data = sh("cast", "calldata", "aggregate3((address,bool,bytes)[])", arg)
    raw = sh("cast", "call", MC, data, "--block", BLOCK, "--rpc-url", RPC)
    dec = sh("cast", "abi-decode", "--json", "f()((bool,bytes)[])", raw)
    return json.loads(dec)[0]

S_CREATOR, S_STATUS, S_ROOT, S_SEQ = (sel("gameCreator()"), sel("status()"), sel("rootClaim()"), sel("l2SequenceNumber()"))
games = []
for lo in range(START, END, B):
    idx = list(range(lo, min(lo + B, END)))
    r1 = multicall([(DGF, sel("gameAtIndex(uint256)", i)) for i in idx])
    meta = []
    for i, (ok, ret) in zip(idx, r1):
        h = ret[2:]
        meta.append((i, int(h[0:64], 16), int(h[64:128], 16), "0x" + h[128 + 24:192]))
    calls = []
    for (_, _, _, g) in meta:
        calls += [(g, S_CREATOR), (g, S_STATUS), (g, S_ROOT), (g, S_SEQ), (ASR, sel("isGameBlacklisted(address)", g)), (ASR, sel("isGameRetired(address)", g)), (ASR, sel("isGameClaimValid(address)", g))]
    r2 = multicall(calls)
    for k, (i, gt, ts, g) in enumerate(meta):
        c = r2[7 * k: 7 * k + 7]
        v = lambda j: c[j][1][2:] if c[j][0] and len(c[j][1]) >= 66 else None
        games.append(dict(index=i, type=gt, createdAt=ts, game=g,
                          creator=("0x" + v(0)[24:64]) if v(0) else None,
                          status=int(v(1), 16) if v(1) else None,
                          rootClaim=("0x" + v(2)) if v(2) else None,
                          l2Seq=int(v(3), 16) if v(3) else None,
                          blacklisted=bool(int(v(4), 16)) if v(4) else None,
                          retired=bool(int(v(5), 16)) if v(5) else None,
                          claimValid=bool(int(v(6), 16)) if v(6) else None))
    print(f"scanned {lo}..{idx[-1]}", flush=True)
    json.dump(games, open(OUT, "w"))

cnt = collections.Counter((g["type"], g["creator"], g["status"], g["claimValid"], g["blacklisted"], g["retired"]) for g in games)
print("\n(type, creator, status, claimValid, blacklisted, retired) -> count")
for k, n in sorted(cnt.items(), key=lambda x: -x[1]):
    print(k, n)
