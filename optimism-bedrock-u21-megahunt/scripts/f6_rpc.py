"""F6 shared JSON-RPC helper (read-only). Talks to the local failover archive proxies only."""
import json, time, urllib.request

L1 = "http://127.0.0.1:7545"
L2 = "http://127.0.0.1:7546"
_id = 0

def _post(url, payload, timeout=60):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(), headers={"content-type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())

def call(method, params, url=L1, retries=6):
    global _id
    _id += 1
    last = None
    for a in range(retries):
        try:
            r = _post(url, {"jsonrpc": "2.0", "id": _id, "method": method, "params": params})
            if "error" in r:
                last = r["error"]
                # do not hammer on deterministic errors
                if a >= 2 and "limit" in json.dumps(last).lower():
                    break
                time.sleep(0.5 * (a + 1))
                continue
            return r["result"]
        except Exception as e:  # noqa
            last = str(e)
            time.sleep(0.7 * (a + 1))
    raise RuntimeError(f"rpc {method} failed: {last}")

def batch(calls, url=L1, retries=6):
    """calls: list of (method, params). Returns list of results (None on per-item error after retries)."""
    out = [None] * len(calls)
    todo = list(range(len(calls)))
    for a in range(retries):
        if not todo:
            break
        payload = [{"jsonrpc": "2.0", "id": i, "method": calls[i][0], "params": calls[i][1]} for i in todo]
        try:
            res = _post(url, payload)
            if isinstance(res, dict):
                res = [res]
            nxt = set(todo)
            for r in res:
                if "result" in r and r["result"] is not None:
                    out[r["id"]] = r["result"]
                    nxt.discard(r["id"])
            todo = sorted(nxt)
        except Exception:
            pass
        if todo:
            time.sleep(0.6 * (a + 1))
    return out

def storage_at(addr, slot, block, url=L1):
    return call("eth_getStorageAt", [addr, slot, hex(block)], url)

def eth_call(to, data, block, url=L1):
    return call("eth_call", [{"to": to, "data": data}, hex(block) if isinstance(block, int) else block], url)

def get_logs(address, topics, frm, to, url=L1):
    p = {"fromBlock": hex(frm), "toBlock": hex(to), "topics": topics}
    if address is not None:
        p["address"] = address
    return call("eth_getLogs", [p], url)

# ---------------------------------------------------------------------------------------------
# pure-python keccak256 (no external dependency available on this machine)
# ---------------------------------------------------------------------------------------------
_RC = [0x0000000000000001, 0x0000000000008082, 0x800000000000808A, 0x8000000080008000, 0x000000000000808B, 0x0000000080000001,
       0x8000000080008081, 0x8000000000008009, 0x000000000000008A, 0x0000000000000088, 0x0000000080008009, 0x000000008000000A,
       0x000000008000808B, 0x800000000000008B, 0x8000000000008089, 0x8000000000008003, 0x8000000000008002, 0x8000000000000080,
       0x000000000000800A, 0x800000008000000A, 0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008]
_ROT = [[0, 36, 3, 41, 18], [1, 44, 10, 45, 2], [62, 6, 43, 15, 61], [28, 55, 25, 21, 56], [27, 20, 39, 8, 14]]
_M = (1 << 64) - 1

def _f(a):
    for rc in _RC:
        c = [a[x][0] ^ a[x][1] ^ a[x][2] ^ a[x][3] ^ a[x][4] for x in range(5)]
        d = [c[(x - 1) % 5] ^ (((c[(x + 1) % 5] << 1) | (c[(x + 1) % 5] >> 63)) & _M) for x in range(5)]
        a = [[a[x][y] ^ d[x] for y in range(5)] for x in range(5)]
        b = [[0] * 5 for _ in range(5)]
        for x in range(5):
            for y in range(5):
                r = _ROT[x][y]
                v = a[x][y]
                b[y][(2 * x + 3 * y) % 5] = ((v << r) | (v >> (64 - r))) & _M if r else v
        a = [[b[x][y] ^ ((~b[(x + 1) % 5][y]) & b[(x + 2) % 5][y]) for y in range(5)] for x in range(5)]
        a[0][0] ^= rc
    return a

def keccak256(data: bytes) -> bytes:
    rate = 136
    p = bytearray(data)
    p.append(0x01)
    while len(p) % rate:
        p.append(0)
    p[-1] |= 0x80
    a = [[0] * 5 for _ in range(5)]
    for off in range(0, len(p), rate):
        for i in range(rate // 8):
            a[i % 5][i // 5] ^= int.from_bytes(p[off + 8 * i: off + 8 * i + 8], "little")
        a = _f(a)
    out = b""
    for i in range(4):
        out += a[i % 5][i // 5].to_bytes(8, "little")
    return out

def keccak_hex(data: bytes) -> str:
    return "0x" + keccak256(data).hex()
