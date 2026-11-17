#!/usr/bin/env python3
"""ATK-T4 synthetic corpus (deterministic, seed-driven). No network.
Usage: gen_synth.py <real-cases.jsonl> <out.jsonl> <seed>
Each case carries "reach": "user" (an L1 user can make OptimismPortal2 emit / cause it on mainnet
today), "priv" (needs SystemConfig owner / operator), or "none" (no producer: malformed log the
portal cannot emit, or an L1 header that cannot occur).
"""
import json, random, sys, copy

real = [json.loads(l) for l in open(sys.argv[1])]
out = open(sys.argv[2], "w")
R = random.Random(int(sys.argv[3]))
PORTAL = "0xbeb5fc579115071764c7423a4f12edde41f106ed"
DEP_TOPIC = "0xb3813568d9991fc951961fcb4c784893574240a28925604d09fc577c55bb7c32"
ALIAS = 0x1111000000000000000000000000000000001111
n = 0


def emit(c):
    global n
    n += 1
    c["id"] = f'{c.get("id", "s")}#{n}'
    out.write(json.dumps(c) + "\n")


def h32(x):
    return "0x" + x.to_bytes(32, "big").hex()


def rand_addr():
    return R.getrandbits(160)


def opaque(mint, value, gas, iscreate, data):
    return (mint.to_bytes(32, "big") + value.to_bytes(32, "big") + gas.to_bytes(8, "big")
            + bytes([iscreate]) + data)


def logdata(op, offset=32, pad_byte=0, extra=b""):
    padlen = (-len(op)) % 32
    return (offset.to_bytes(32, "big") + len(op).to_bytes(32, "big") + op + bytes([pad_byte]) * padlen + extra)


def rand_data():
    r = R.random()
    if r < 0.35:
        L = R.randint(0, 40)
    elif r < 0.7:
        L = R.randint(41, 600)
    elif r < 0.95:
        L = R.randint(601, 8000)
    else:
        L = R.choice([119999, 120000, R.randint(8001, 120000)])
    mode = R.random()
    if mode < 0.3:
        return bytes(L)
    if mode < 0.4:
        return b"\xff" * L
    return R.randbytes(L)


def user_deposit():
    """Fields an L1 caller controls through OptimismPortal2.depositTransaction (v9):
    _to, _value (any uint256), _gasLimit (uint64, >= 21000+40*len, metered <= 20M),
    _isCreation (requires _to == 0), _data (<= 120000 bytes), msg.value -> mint;
    from = caller or its L1->L2 alias."""
    data = rand_data()
    gmin = 21000 + 40 * len(data)
    gas = R.choice([gmin, 20_000_000, R.randint(gmin, max(gmin, 20_000_000))])
    iscreate = 1 if R.random() < 0.15 else 0
    to = 0 if (iscreate or R.random() < 0.05) else rand_addr()
    mint = R.choice([0, 0, 1, R.getrandbits(64), R.getrandbits(80), 10**24])
    value = R.choice([0, mint, 1, R.getrandbits(256), 2**256 - 1, R.getrandbits(90)])
    frm = rand_addr()
    if R.random() < 0.4:
        frm = (frm + ALIAS) % (1 << 160)
    return frm, to, mint, value, gas, iscreate, data


def dep_log(frm, to, op, version=0, offset=32, pad=0, extra=b""):
    return {"address": PORTAL, "topics": [DEP_TOPIC, h32(frm), h32(to), h32(version)],
            "data": "0x" + logdata(op, offset, pad, extra).hex()}


# ---- 1. single-log deposit decoding ------------------------------------------------------
for i in range(4000):
    frm, to, mint, value, gas, ic, data = user_deposit()
    l = dep_log(frm, to, opaque(mint, value, gas, ic, data))
    emit(dict(k="dep", id="dep-user", reach="user", bh=h32(R.getrandbits(256)),
              idx=R.choice([0, 1, R.getrandbits(10), R.getrandbits(16), 2**32 - 1]), **l))
# boundary values that the contract would also emit (or bound by ETH supply)
for mint in [0, 1, 2**64, 2**96, 2**127, 2**128 - 1]:
    for value in [0, 2**128, 2**255, 2**256 - 1]:
        for gas in [21000, 20_000_000, 2**63, 2**64 - 1]:
            l = dep_log(rand_addr(), rand_addr(), opaque(mint, value, gas, 0, R.randbytes(R.randint(0, 70))))
            reach = "user" if (mint <= 10**27 and gas <= 20_000_000) else "none"
            emit(dict(k="dep", id="dep-bound", reach=reach, bh=h32(R.getrandbits(256)), idx=7, **l))
# malformed / impossible logs (no producer: the portal always emits abi.encode(bytes))
for i in range(600):
    frm, to, mint, value, gas, ic, data = user_deposit()
    op = opaque(mint, value, gas, ic, data)
    kind = R.randrange(11)
    topics_override = None
    if kind == 0:
        l = dep_log(frm, to, op, offset=R.choice([0, 64, 33, 2**64]))
    elif kind == 1:
        l = dep_log(frm, to, op, pad=R.choice([1, 0xff])) if len(op) % 32 else dep_log(frm, to, op + b"\x01", pad=1)
    elif kind == 2:
        l = dep_log(frm, to, op, extra=bytes(32))
    elif kind == 3:
        l = dep_log(frm, to, op, extra=R.randbytes(32))
    elif kind == 4:
        l = dep_log(frm, to, op, version=R.choice([1, 2, 2**255]))
    elif kind == 5:
        l = dep_log(frm, to, opaque(2**128 + R.getrandbits(100), value, gas, ic, data))
    elif kind == 6:
        l = dep_log(frm, to, op[:R.randint(0, 72)])
    elif kind == 7:
        l = dep_log(frm, to, opaque(mint, value, gas, R.choice([2, 0xff]), data))
    elif kind == 8:
        l = dep_log(frm, to, op)
        l["topics"][1] = h32((1 << 200) | frm)
    elif kind == 9:
        l = dep_log(frm, to, op)
        l["topics"] = l["topics"][:3]
    else:
        l = dep_log(frm, to, op)
        d = bytes.fromhex(l["data"][2:])
        d = d[:32] + (len(op) + R.choice([1, 32, 2**40])).to_bytes(32, "big") + d[64:]
        l["data"] = "0x" + d.hex()
    emit(dict(k="dep", id=f"dep-malformed{kind}", reach="none", bh=h32(R.getrandbits(256)), idx=3, **l))

# ---- 2. full payload attributes: many deposits / interleaving at epoch boundaries --------
epochs = [c for c in real if c.get("receipts")]
assert epochs, "need at least one real epoch-first case"
for i in range(160):
    base = copy.deepcopy(R.choice(epochs))
    base.pop("expect", None)
    rs = base["receipts"]
    ndep = R.choice([0, 1, 2, 17, 100, 400, 1500])
    for _ in range(ndep):
        frm, to, mint, value, gas, ic, data = user_deposit()
        if len(data) > 4000:
            data = data[:R.randint(0, 4000)]
        lg = dep_log(frm, to, opaque(mint, value, gas, ic, data))
        noise = []
        if R.random() < 0.3:  # same event from a non-portal contract (ignored by both)
            noise.append(dict(lg, address="0x" + rand_addr().to_bytes(20, "big").hex()))
        if R.random() < 0.3:  # other portal event (topic0 differs)
            noise.append({"address": PORTAL, "topics": [h32(R.getrandbits(256))], "data": "0x"})
        logs = noise + [lg] if R.random() < 0.5 else [lg] + noise
        pos = R.randint(0, len(rs))
        cg = rs[pos - 1]["cgu"] if pos > 0 else 0
        rs.insert(pos, {"status": 1, "cgu": cg, "logs": logs})
    if R.random() < 0.3:  # reverted L1 txs: no logs (consensus: a failed receipt carries none)
        rs.insert(R.randint(0, len(rs)), {"status": 0, "cgu": 0, "logs": []})
    base["id"] = f"attr-many{ndep}"
    base["reach"] = "user"
    emit(base)

# ---- 3. hardfork activation boundaries (fork times shifted; same input both sides) --------
def seq0_case(base, chain, bt, delta):
    c = copy.deepcopy(base)
    c.pop("expect", None)
    c["chain"] = chain
    hts = int(c["l1_header"]["timestamp"], 16)
    c["parent"]["l1_hash"] = c["l1_header"]["parentHash"]
    c["parent"]["l1_number"] = int(c["l1_header"]["number"], 16) - 1
    c["parent"]["timestamp"] = hts + delta
    return c

BT = {10: 2, 57073: 1, 130: 1}
for chain in (10, 57073, 130):
    for fork in ("ecotone", "fjord", "granite", "holocene", "isthmus", "jovian", "karst"):
        for off in (-2, -1, 0, 1, 2):
            base = R.choice(epochs)
            c = seq0_case(base, chain, BT[chain], R.randint(0, 30))
            nxt = c["parent"]["timestamp"] + BT[chain]
            later = ["ecotone", "fjord", "granite", "holocene", "isthmus", "jovian", "karst"]
            later = later[later.index(fork) + 1:]
            ov = {fork: nxt - off * BT[chain]}
            for lf in later:  # keep later forks after this one
                ov[lf] = nxt + 1000
            c["override_hardforks"] = ov
            c["id"] = f"fork-{chain}-{fork}{off:+d}"
            c["reach"] = "none"  # past forks: activation blocks are history, not live input
            emit(c)

# ---- 4. L1 header blob-fee schedule & header field variants ------------------------------
SCHED = {"cancun": 1710338135, "prague": 1746612311, "osaka": 1764798551, "bpo1": 1765290071,
         "bpo2": 1767747671}
for i in range(240):
    base = R.choice(epochs)
    c = seq0_case(base, R.choice([10, 57073, 130]), 2, 0)
    hd = c["l1_header"]
    t = R.choice(list(SCHED.values())) + R.choice([-13, -1, 0, 1, 12, 86400])
    if R.random() < 0.6:
        t = int(hd["timestamp"], 16) + R.randint(-50, 50)
    hd["timestamp"] = hex(t)
    ebg = R.choice([0, 1, 393216, 10**6, 2**22, 2**25, 2**28, R.getrandbits(28)] + ([2**30, 1_100_000_000, 2**31, 2**32] if i < 24 else []))
    if i < 24:
        ebg = [2**30, 1_100_000_000, 2**31, 2**32][i % 4]
    hd["excessBlobGas"] = hex(ebg)
    hd["baseFeePerGas"] = hex(R.choice([0, 1, 7, R.getrandbits(40), 2**63]))
    if R.random() < 0.08:  # header without blob fields (pre-Cancun shape)
        for k in ("blobGasUsed", "excessBlobGas", "parentBeaconBlockRoot", "requestsHash"):
            hd.pop(k, None)
    c["parent"]["timestamp"] = t + R.randint(0, 20)
    c["id"] = "l1hdr-extreme" if i < 24 else "l1hdr"
    c["reach"] = "none"  # L1 header fields are set by L1 consensus, not a user
    emit(c)

# ---- 5. system-config value space (privileged inputs, parity only) -----------------------
for i in range(200):
    base = R.choice(epochs)
    c = copy.deepcopy(base)
    c.pop("expect", None)
    s = c["sys"]
    ver = R.choice([0, 1, 1, 1])
    s["scalar"] = str((ver << 248) | (R.getrandbits(32) << 32) | R.getrandbits(32))
    s["operator_fee_scalar"] = R.choice([None, 0, R.getrandbits(32)])
    s["operator_fee_constant"] = R.choice([None, 0, R.getrandbits(64)])
    s["da_footprint_gas_scalar"] = R.choice([None, 0, 1, R.getrandbits(16)])
    s["min_base_fee"] = R.choice([None, 0, R.getrandbits(64)])
    s["gas_limit"] = R.choice([30_000_000, 2**63, R.getrandbits(64)])
    s["eip1559_denominator"] = R.choice([None, 0, R.getrandbits(32)])
    s["eip1559_elasticity"] = 0 if s["eip1559_denominator"] is None else R.getrandbits(32)
    if s["eip1559_denominator"] is None:
        s["eip1559_elasticity"] = None
    c["id"] = "sys"
    c["reach"] = "priv"
    emit(c)

# ---- 6. output root / super root encoding ------------------------------------------------
for i in range(500):
    emit(dict(k="oroot", id="oroot", reach="none", state=h32(R.getrandbits(256)),
              storage=h32(R.getrandbits(256)), block=h32(R.getrandbits(256))))
for i in range(500):
    m = R.choice([1, 1, 2, 3, 8])
    ids = list(dict.fromkeys(R.choice([10, 57073, 130, 1868, 8453, R.getrandbits(64), 2**64 - 1]) for _ in range(m)))
    emit(dict(k="sroot", id="sroot", reach="none", ts=R.choice([0, 1794868743, 2**64 - 1, R.getrandbits(64)]),
              outs=[[str(x), h32(R.getrandbits(256))] for x in ids]))
# ---- 7. deposit-only fallback filter and receipts-trie root ------------------------------
for i in range(400):
    txs = []
    for _ in range(R.randint(0, 12)):
        t = R.choice(["dep", "dep", "legacy", "typed", "empty", "postexec", "one7e"])
        if t == "dep":
            txs.append("0x7e" + R.randbytes(R.randint(1, 300)).hex())
        elif t == "legacy":
            txs.append("0xf8" + R.randbytes(R.randint(60, 200)).hex())
        elif t == "typed":
            txs.append("0x" + bytes([R.choice([1, 2, 3, 4])]).hex() + R.randbytes(R.randint(60, 300)).hex())
        elif t == "empty":
            txs.append("0x")
        elif t == "postexec":
            txs.append("0x7d" + R.randbytes(40).hex())
        else:
            txs.append("0x7e")
    emit(dict(k="donly", id="donly", reach="user", txs=txs))
for i in range(400):
    rs = []
    cg = 0
    for j in range(R.randint(0, 60)):
        ty = R.choice([0x7e] * 3 + [0, 1, 2, 2, 2, 4])
        cg += R.randint(21000, 3_000_000)
        logs = [{"address": "0x" + rand_addr().to_bytes(20, "big").hex(),
                 "topics": [h32(R.getrandbits(256)) for _ in range(R.randint(0, 4))],
                 "data": "0x" + R.randbytes(R.choice([0, 32, 64, R.randint(0, 700)])).hex()}
                for _ in range(R.choice([0, 0, 1, 2, 5]))]
        st = 1 if R.random() < 0.85 else 0
        if st == 0:
            logs = []
        r = {"type": ty, "status": st, "cgu": cg, "logs": logs, "deposit_nonce": None, "deposit_receipt_version": None}
        if ty == 0x7e:
            r["deposit_nonce"] = R.choice([0, R.getrandbits(20), R.getrandbits(64)])
            r["deposit_receipt_version"] = 1
        rs.append(r)
    emit(dict(k="rroot", id="rroot", reach="user", receipts=rs))
for chain in (10, 57073, 130, 1868):
    emit(dict(k="cfg", id=f"cfg-{chain}", reach="none", chain=chain))
print("cases", n, file=sys.stderr)
