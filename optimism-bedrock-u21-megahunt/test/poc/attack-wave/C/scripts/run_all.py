#!/usr/bin/env python3
"""ATK-C experiment battery. Usage: python3 -I -u run_all.py <out.jsonl> [case-prefix]"""
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gascap import *

OUT = sys.argv[1]
ONLY = sys.argv[2] if len(sys.argv) > 2 else ""
EMPTY_TARGET = "0x00000000000000000000000000000000000b0b01"  # no code, no balance
LIVE = json.load(open("/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/evidence/attack-wave/C/live-objects-8M.json"))


def emit(r):
    with open(OUT, "a") as f:
        f.write(json.dumps(r) + "\n")


def run(case, fn):
    if ONLY and not case.startswith(ONLY):
        return
    r = fn()
    r["case"] = case
    emit(r)


setup()
salt = [100]


def nxt():
    salt[0] += 1
    return salt[0]


# E1: live budget, empty message, no value, code-less target; sweep minGasLimit
for m in [0, 7_000_000, 8_000_000, 15_000_000, 15_800_000, 16_000_000]:
    run(f"E1_m{m}", lambda m=m: measure(f"live budget, empty msg, value 0, m={m}", messenger_w(nxt(), EMPTY_TARGET, 0, m, b""), hi=40_000_000))

# E2: the four real unproven OP Mainnet withdrawals with minGasLimit 8,000,000 (old budget generation)
for i, o in enumerate(LIVE):
    def f(o=o):
        w = W(o["nonce"], o["sender"], o["target"], o["value"], o["gasLimit"], bytes.fromhex(o["data"][2:]))
        assert "0x" + w.wh.hex() == o["withdrawalHash"], "hash mismatch"
        w.relay = (o["msgNonce"], o["msgSender"], o["msgTarget"], o["msgValue"], o["minGasLimit"], bytes.fromhex(o["message"][2:]))
        r = measure("REAL object " + o["withdrawalHash"], w, hi=40_000_000)
        r["withdrawalHash"] = o["withdrawalHash"]
        return r
    run(f"E2_live{i}", f)

# E3: messenger value message (1 ETH) to a never-touched account (messenger relays with SafeCall.call, no 183.6k)
for m in [0, 15_800_000]:
    t = "0x" + (b"\x0c" * 1 + (m + 7).to_bytes(19, "big")).hex()
    run(f"E3_value_new_m{m}", lambda m=m, t=t: measure(f"messenger 1 ETH to new account, m={m}", messenger_w(nxt(), t, 10**18, m, b""), hi=40_000_000))

# E4: PLAIN withdrawal (L2ToL1MessagePasser.initiateWithdrawal) 1 ETH to a never-touched account: portal uses
# callWithMinGas -> +183,600 reserve when codehash == 0. Measure at gasLimit 0 and near the cap, then after a
# 1-wei pre-fund of the target (anyone can do it).
def plain(gl, prefund):
    t = "0x" + (b"\x0d" + (gl + (1 if prefund else 0)).to_bytes(19, "big")).hex()
    if prefund:
        rpc(L1, "anvil_setBalance", [t, "0x1"])  # stands for a 1-wei transfer by anyone
    w = W((1 << 240) | (500_000_000 + nxt()), "0x00000000000000000000000000000000000a11ce", t, 10**18, gl, b"")
    r = measure(f"plain 1 ETH to {'pre-funded' if prefund else 'new'} account, gasLimit={gl}", w, hi=40_000_000)
    if prefund:
        rpc(L1, "anvil_setBalance", [t, "0x0"])
    return r
for gl in [0, 16_200_000]:
    for pf in (False, True):
        run(f"E4_plain_gl{gl}_{'pf' if pf else 'new'}", lambda gl=gl, pf=pf: plain(gl, pf))

# E5: large calldata, m = 0, nonzero bytes (worst case for L1 calldata), live budget
for L in [250_000, 320_000]:
    run(f"E5_L{L}", lambda L=L: measure(f"live budget, {L} B nonzero message, m=0", messenger_w(nxt(), EMPTY_TARGET, 0, 0, b"\xff" * L), hi=60_000_000))
for L in [400_000]:
    run(f"E5z_L{L}", lambda L=L: measure(f"live budget, {L} B zero message, m=0", messenger_w(nxt(), EMPTY_TARGET, 0, 0, b"\x00" * L), hi=60_000_000))

# E6: gas-burning target near the cap edge: every delivery fails; replay fails at any gas (target property)
for m in [8_000_000, 15_800_000]:
    run(f"E6_burner_m{m}", lambda m=m: measure(f"gas-burning target, m={m}", messenger_w(nxt(), BURNER, 0, m, b""), hi=40_000_000, do_replay=False))
