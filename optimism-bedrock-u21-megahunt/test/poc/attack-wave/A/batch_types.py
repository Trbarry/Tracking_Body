#!/usr/bin/env python3
"""ATK-A D1 production check: decode every batcher blob/calldata tx to the batch inbox of
OP/Ink/Unichain in an L1 block range and classify the batches (0 = singular, 1 = span).
Passive reads: L1 EL archive proxy + a public beacon API (blob sidecars). Needs `brotli`."""
import json, sys, zlib, hashlib, urllib.request, collections
import brotli
EL, BEACON = sys.argv[1], sys.argv[2]
START, END = int(sys.argv[3]), int(sys.argv[4])
INB = {"0xff00000000000000000000000000000000000010": ("op", "0x6887246668a3b87f54deb3b94ba47a6f63f32985"),
       "0xff00000000000000000000000000000000000130": ("unichain", "0x9ef649e8746cc47a17708a5e86b2d66c7f6c00d1"),
       "0x005969bf0ecbf6edb6c47e5e94693b1c3651be97": ("ink", "0x6db6161fc5662450e801398bad62dd9921216b98")}
GENESIS = 1606824023
def rpc(m, p):
    r = urllib.request.Request(EL, json.dumps({"jsonrpc": "2.0", "id": 1, "method": m, "params": p}).encode(), {"content-type": "application/json"})
    return json.loads(urllib.request.urlopen(r, timeout=60).read())["result"]
def beacon(path):
    return json.loads(urllib.request.urlopen(urllib.request.Request(BEACON + path, headers={"accept": "application/json"}), timeout=60).read())
def blob_to_data(b):
    assert b[1] == 0, "blob encoding version"
    n = (b[2] << 16) | (b[3] << 8) | b[4]
    out = bytearray(130044 + 4)
    out[0:27] = b[5:32]
    opos, ipos, eb = 28, 32, [b[0], 0, 0, 0]
    def fe(opos, ipos):
        assert b[ipos] & 0xC0 == 0
        out[opos:opos + 31] = b[ipos + 1:ipos + 32]
        return b[ipos], opos + 32, ipos + 32
    def reasm(opos, e):
        opos -= 1
        x = (e[0] & 0x3F) | ((e[1] & 0x30) << 2); y = (e[1] & 0x0F) | ((e[3] & 0x0F) << 4); z = (e[2] & 0x3F) | ((e[3] & 0x30) << 2)
        out[opos - 32] = z; out[opos - 64] = y; out[opos - 96] = x
        return opos
    for i in range(1, 4): eb[i], opos, ipos = fe(opos, ipos)
    opos = reasm(opos, eb)
    r = 1
    while r < 1024 and opos < n:
        for j in range(4): eb[j], opos, ipos = fe(opos, ipos)
        opos = reasm(opos, eb); r += 1
    return bytes(out[:n])
def frames(data):
    assert data[0] == 0, "derivation version"
    i, fs = 1, []
    while i < len(data):
        cid = data[i:i + 16]; num = int.from_bytes(data[i + 16:i + 18], "big"); ln = int.from_bytes(data[i + 18:i + 22], "big")
        fd = data[i + 22:i + 22 + ln]; last = data[i + 22 + ln]; i += 23 + ln
        fs.append((cid, num, fd, last))
    return fs
def rlp_item(d, i):
    p = d[i]
    if p < 0x80: return d[i:i + 1], i + 1
    if p < 0xB8: l = p - 0x80; return d[i + 1:i + 1 + l], i + 1 + l
    if p < 0xC0: ll = p - 0xB7; l = int.from_bytes(d[i + 1:i + 1 + ll], "big"); return d[i + 1 + ll:i + 1 + ll + l], i + 1 + ll + l
    if p < 0xF8: l = p - 0xC0; return ("L", d[i + 1:i + 1 + l]), i + 1 + l
    ll = p - 0xF7; l = int.from_bytes(d[i + 1:i + 1 + ll], "big"); return ("L", d[i + 1 + ll:i + 1 + ll + l]), i + 1 + ll + l
def rlp_list(d):
    out, i = [], 0
    while i < len(d):
        x, i = rlp_item(d, i); out.append(x)
    return out
def decompress(c):
    if c[0] == 1: return brotli.decompress(c[1:])
    if c[0] & 0x0F in (8, 15): return zlib.decompressobj().decompress(c)
    raise ValueError("unknown compression %x" % c[0])
chan = collections.defaultdict(dict)  # (chain, cid) -> {num: data}; last
lastnum = {}
stats = collections.Counter(); singular = []
# Blocks that carry a tx to any inbox (trace_filter on the reth archive), scanned in 500-block windows.
blocks = set()
for a in range(START, END + 1, 500):
    tr = rpc("trace_filter", [{"fromBlock": hex(a), "toBlock": hex(min(END, a + 499)), "toAddress": list(INB)}])
    blocks |= {x["blockNumber"] for x in tr}
print(f"# {len(blocks)} L1 blocks with inbox txs in [{START},{END}]", file=sys.stderr)
for bn in sorted(blocks):
    blk = rpc("eth_getBlockByNumber", [hex(bn), True])
    txs = [t for t in blk["transactions"] if (t.get("to") or "").lower() in INB]
    if not txs: continue
    slot = (int(blk["timestamp"], 16) - GENESIS) // 12
    sidecars = None
    for t in txs:
        chain, batcher = INB[t["to"].lower()]
        if t["from"].lower() != batcher: stats[(chain, "non-batcher-sender")] += 1; continue
        datas = []
        if t["type"] == "0x3":
            if sidecars is None:
                sc = beacon(f"/eth/v1/beacon/blob_sidecars/{slot}")["data"]
                sidecars = {}
                for s in sc:
                    vh = "0x01" + hashlib.sha256(bytes.fromhex(s["kzg_commitment"][2:])).hexdigest()[2:]
                    sidecars[vh] = bytes.fromhex(s["blob"][2:])
            for vh in t["blobVersionedHashes"]: datas.append(blob_to_data(sidecars[vh]))
        else:
            datas.append(bytes.fromhex(t["input"][2:]))
        for d in datas:
            for cid, num, fd, last in frames(d):
                chan[(chain, cid)][num] = fd
                if last: lastnum[(chain, cid)] = num
                stats[(chain, "frames")] += 1
    for key in [k for k in list(lastnum) if len(chan[k]) == lastnum[k] + 1]:
        chain = key[0]
        raw = b"".join(chan[key][i] for i in range(lastnum[key] + 1))
        del chan[key]; del lastnum[key]
        try:
            for item in rlp_list(decompress(raw)):
                bt = item[0]
                stats[(chain, f"batch_type_{bt}")] += 1
                if bt == 0:
                    singular.append((chain, bn, key[1].hex()))
            stats[(chain, "channels")] += 1
        except Exception as e:
            stats[(chain, "decode_error:" + type(e).__name__)] += 1
print(json.dumps({"range": [START, END], "stats": {f"{a}:{b}": v for (a, b), v in sorted(stats.items())},
                  "singular_batches": singular[:50], "incomplete_channels": len(lastnum) + len(chan)}, indent=1))
