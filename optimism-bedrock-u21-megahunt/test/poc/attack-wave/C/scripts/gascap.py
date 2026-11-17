#!/usr/bin/env python3
"""ATK-C: minimum L1 transaction gas for finalize / replay of L2->L1 withdrawals on the DEPLOYED
OP Mainnet portal 6.1.0 + L1CDM 2.13.0 (private anvil fork of L1 @ 26433900, hardfork osaka,
port 19030). Real transactions (intrinsic gas, EIP-7623 floor, warm/cold sets are the node's).

Vehicle (stated): the Merkle/super-root proof step is replaced by writing
provenWithdrawals[wh][attacker] = (anchorGame, now-7d-1s) with anvil_setStorageAt (slot 57, verified
against a real mainnet proof). Everything measured afterwards is deployed bytecode.
Withdrawal gasLimit always comes from the LIVE L2CrossDomainMessenger 2.2.1 baseGas() on the OP
Mainnet fork :9545, unless the case reproduces a real in-flight object (then its real struct).

The anvil does not enforce EIP-7825, so feasibility is: min tx gas limit <= 16,777,216.
"""
import json, sys, urllib.request

L1 = "http://127.0.0.1:19030"
L2 = "http://127.0.0.1:9545"
PORTAL = "0xbeb5fc579115071764c7423a4f12edde41f106ed"
L1CDM = "0x25ace71c97b33cc4729cf772ae268934f7ab5fa1"
L2CDM = "0x4200000000000000000000000000000000000007"
ANCHOR_GAME = 0x55A5CFd4270340b3822BB9D8eebdb450ac206f95
ATTACKER = "0x0320e43ae5e349b53824bbe869d0f84662fd2c9d"  # fresh EOA, no code, no role
KECCAK_HELPER = "0x00000000000000000000000000000000000a7c01"  # runtime: return keccak256(calldata)
BURNER = "0x00000000000000000000000000000000000a7c02"  # runtime: infinite loop (burns all gas)
CAP = 1 << 24


def rpc(url, m, p):
    r = urllib.request.urlopen(urllib.request.Request(url, json.dumps({"jsonrpc": "2.0", "id": 1, "method": m, "params": p}).encode(), {"Content-Type": "application/json"}), timeout=600)
    j = json.loads(r.read())
    if "error" in j:
        raise RuntimeError(j["error"])
    return j["result"]


def w32(x):
    return x.to_bytes(32, "big")


def addr(a):
    return w32(int(a, 16))


def pad(b):
    return b + b"\x00" * ((32 - len(b) % 32) % 32)


def keccak(b):
    return bytes.fromhex(rpc(L1, "eth_call", [{"to": KECCAK_HELPER, "data": "0x" + b.hex()}, "latest"])[2:])


def enc6(n, s, t, v, g, data):  # abi.encode(uint256,address,address,uint256,uint256,bytes)
    return w32(n) + addr(s) + addr(t) + w32(v) + w32(g) + w32(0xC0) + w32(len(data)) + pad(data)


def relay_calldata(n, s, t, v, m, msg):
    return bytes.fromhex("d764ad0b") + enc6(n, s, t, v, m, msg)


def l2_base_gas(msg, m):
    cd = bytes.fromhex("b28ade25") + w32(0x40) + w32(m) + w32(len(msg)) + pad(msg)
    return int(rpc(L2, "eth_call", [{"to": L2CDM, "data": "0x" + cd.hex()}, "latest"]), 16)


class W:
    def __init__(self, nonce, sender, target, value, gasLimit, data):
        self.n, self.s, self.t, self.v, self.g, self.d = nonce, sender, target, value, gasLimit, data
        self.wh = keccak(enc6(nonce, sender, target, value, gasLimit, data))
        self.mh = keccak(data) if sender.lower() == L2CDM else None

    def finalize_cd(self):
        return bytes.fromhex("43ca1c50") + w32(0x40) + addr(ATTACKER) + enc6(self.n, self.s, self.t, self.v, self.g, self.d)


def messenger_w(salt, target, value, m, msg, gasLimit=None, msg_sender="0x00000000000000000000000000000000000a11ce"):
    mn = (1 << 240) | (700_000_000 + salt)
    data = relay_calldata(mn, msg_sender, target, value, m, msg)
    g = gasLimit if gasLimit is not None else l2_base_gas(msg, m)
    w = W((1 << 240) | (600_000_000 + salt), L2CDM, L1CDM, value, g, data)
    w.relay = (mn, msg_sender, target, value, m, msg)
    return w


def setup():
    rpc(L1, "anvil_setCode", [KECCAK_HELPER, "0x365f5f37365f205f5260205ff3"])
    rpc(L1, "anvil_setCode", [BURNER, "0x5b600056"])
    rpc(L1, "anvil_setBalance", [ATTACKER, hex(10**24)])
    rpc(L1, "anvil_impersonateAccount", [ATTACKER])  # own fresh EOA: only to skip local signing
    rpc(L1, "anvil_setBlockGasLimit", [hex(1 << 30)])


def fabricate_proof(w):
    ts = int(rpc(L1, "eth_getBlockByNumber", ["latest", False])["timestamp"], 16) - 604_801 - 60
    inner = keccak(w.wh + w32(57))
    slot = keccak(addr(ATTACKER) + inner)
    rpc(L1, "anvil_setStorageAt", [PORTAL, "0x" + slot.hex(), "0x" + w32((ts << 160) | ANCHOR_GAME).hex()])


def view_bool(to, sel, h):
    return int(rpc(L1, "eth_call", [{"to": to, "data": "0x" + sel + h.hex()}, "latest"]), 16) != 0


def send(to, cd, gas):
    rpc(L1, "anvil_dropAllTransactions", [])
    nonce = rpc(L1, "eth_getTransactionCount", [ATTACKER, "pending"])
    txh = rpc(L1, "eth_sendTransaction", [{"from": ATTACKER, "to": to, "data": "0x" + cd.hex(), "gas": hex(gas), "value": "0x0", "nonce": nonce, "gasPrice": hex(10**10)}])
    rc = None
    for _ in range(30):
        rc = rpc(L1, "eth_getTransactionReceipt", [txh])
        if rc:
            break
        rpc(L1, "evm_mine", [])
    if rc is None:
        raise RuntimeError("no receipt " + txh)
    return int(rc["status"], 16), int(rc["gasUsed"], 16)


def state(w):
    fin = view_bool(PORTAL, "a14238e7", w.wh)
    ok = view_bool(L1CDM, "b1b1b209", w.mh) if w.mh else None
    failed = view_bool(L1CDM, "a4e7f8bd", w.mh) if w.mh else None
    return fin, ok, failed


# outcome codes: 0 tx reverted, 1 finalized+relayed, 2 finalized+failedMessages, 3 finalized no record, 4 plain finalized
def try_finalize(w, gas, keep=False):
    snap = rpc(L1, "evm_snapshot", [])
    fabricate_proof(w)
    st, used = send(PORTAL, w.finalize_cd(), gas)
    fin, ok, failed = state(w)
    if st == 0:
        o = 0
    elif w.mh is None:
        bal = int(rpc(L1, "eth_getBalance", [w.t, "latest"]), 16)
        o = 4 if bal >= w.v else 5  # 4 plain delivered, 5 plain finalized with failed call (value back to lockbox)
    else:
        o = 1 if ok else (2 if failed else 3)
    if not keep:
        rpc(L1, "evm_revert", [snap])
        return o, used, None
    return o, used, snap


def try_replay(w, gas):
    snap = rpc(L1, "evm_snapshot", [])
    st, used = send(L1CDM, relay_calldata(*w.relay), gas)
    _, ok, failed = state(w)
    rpc(L1, "evm_revert", [snap])
    return (1 if (st and ok) else (2 if st else 0)), used


def bsearch(pred, lo, hi, step=16):
    """smallest g in [lo,hi] with pred(g) True (pred monotone); None if pred(hi) False"""
    if not pred(hi):
        return None
    while hi - lo > step:
        mid = (lo + hi) // 2
        if pred(mid):
            hi = mid
        else:
            lo = mid
    return hi


def measure(label, w, hi=None, do_replay=True, step=128):
    """Brackets derived from the inequalities in the README; every bracket edge is itself tested
    (bsearch checks pred(hi) first, and lo is asserted to fail)."""
    L = len(w.d)
    m = w.relay[4] if w.mh else 0
    base = (64 * w.g) // 63
    res = {"label": label, "gasLimit": w.g, "dataLen": L, "minGasLimit": m, "value": w.v, "target": w.t if not w.mh else w.relay[2]}
    lo, hi1 = base, base + 60 * L + 600_000 + (183_600 if w.v else 0)
    assert try_finalize(w, lo)[0] == 0, "lower bracket unexpectedly passes"
    g_nr = bsearch(lambda g: try_finalize(w, g)[0] != 0, lo, hi1, step)
    res["finalize_min_nonrevert"] = g_nr
    if g_nr is None:
        print(json.dumps(res), flush=True)
        return res
    o, used, _ = try_finalize(w, g_nr)
    res["outcome_at_min"] = o
    res["gasUsed_at_min"] = used
    if w.mh is None:
        res["finalize_min_delivered"] = g_nr if o == 4 else bsearch(lambda g: try_finalize(w, g)[0] == 4, g_nr, g_nr + 400_000, step)
    else:
        res["finalize_min_relayed"] = g_nr if o == 1 else bsearch(lambda g: try_finalize(w, g)[0] == 1, g_nr, g_nr + m // 20 + 600_000, step)
        if do_replay and o == 2:
            # third-party move: finalize at the minimum (records failedMessages), then anyone replays
            _, _, snap = try_finalize(w, g_nr, keep=True)
            rlo = (64 * m) // 63
            g_r = bsearch(lambda g: try_replay(w, g)[0] == 1, rlo, rlo + m // 20 + 60 * L + 600_000, step)
            res["replay_min_after_forced_fail"] = g_r
            rpc(L1, "evm_revert", [snap])
    for k in ("finalize_min_nonrevert", "finalize_min_relayed", "finalize_min_delivered", "replay_min_after_forced_fail"):
        if res.get(k) is not None:
            res[k + "_fits_cap"] = res[k] <= CAP
    res["precision_gas"] = step
    print(json.dumps(res), flush=True)
    return res


if __name__ == "__main__":
    setup()
    print("block", int(rpc(L1, "eth_blockNumber", []), 16), "baseGas('',0) live L2CDM =", l2_base_gas(b"", 0))
