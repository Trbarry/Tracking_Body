#!/usr/bin/env python3
"""ATK-C edge confirmation: transactions at EXACTLY the EIP-7825 cap (2^24 gas) around the measured edges.
Usage: python3 -I -u edge_at_cap.py <out.jsonl>"""
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gascap import *

OUT = sys.argv[1]
setup()
EMPTY = "0x00000000000000000000000000000000000b0b01"
names = {0: "REVERT (unfinalized, retry)", 1: "RELAYED", 2: "FINALIZED+failedMessages", 3: "FINALIZED NO RECORD"}
for i, m in enumerate([15_370_000, 15_390_000, 15_500_000, 15_510_000, 15_520_000]):
    w = messenger_w(9000 + i, EMPTY, 0, m, b"")
    o, used, snap = try_finalize(w, CAP, keep=True)
    r = {"m": m, "gasLimit": w.g, "finalize_at_cap": names[o], "gasUsed": used}
    if o == 2:
        ro, rused = try_replay(w, CAP)
        r["replay_at_cap_after_failed"] = "RELAYED" if ro == 1 else ("no-op/failed" if ro == 2 else "REVERT")
        r["replay_gasUsed"] = rused
    rpc(L1, "evm_revert", [snap])
    print(json.dumps(r), flush=True)
    open(OUT, "a").write(json.dumps(r) + "\n")
