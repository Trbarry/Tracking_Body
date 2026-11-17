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
