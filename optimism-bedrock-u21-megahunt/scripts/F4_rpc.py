#!/usr/bin/env python3
"""F4 — tiny read-only JSON-RPC helper (passive reads through the local failover archive proxy)."""
import json, time, urllib.request
from concurrent.futures import ThreadPoolExecutor

L1 = "http://127.0.0.1:7545"
IMPL = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
ADMIN = "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103"
HEAD = 26433900


def _post(url, payload, timeout=40):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(), headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())


def call(method, params, url=L1, tries=6):
    last = None
    for i in range(tries):
        try:
            j = _post(url, {"jsonrpc": "2.0", "id": 1, "method": method, "params": params})
            if "result" in j and j["result"] is not None:
                return j["result"]
            last = j
            if "result" in j and method in ("eth_getTransactionReceipt", "eth_getTransactionByHash"):
                return None
        except Exception as e:  # noqa
            last = repr(e)
        time.sleep(0.4 * (i + 1))
    raise RuntimeError(f"rpc failed {method} {params}: {last}")


def many(reqs, url=L1, threads=6):
    """reqs: list of (method, params). Returns results in order (threaded singles: robust to upstream batch limits)."""
    with ThreadPoolExecutor(threads) as ex:
        return list(ex.map(lambda r: call(r[0], r[1], url), reqs))


def sload(addr, slot, block, url=L1):
    s = hex(slot) if isinstance(slot, int) else slot
    return call("eth_getStorageAt", [addr, s, hex(block)], url)


def sload_many(addr, slots, block, url=L1, threads=6):
    reqs = [("eth_getStorageAt", [addr, hex(s) if isinstance(s, int) else s, hex(block)]) for s in slots]
    return many(reqs, url, threads)


def eth_call(to, data, block=HEAD, url=L1):
    try:
        return call("eth_call", [{"to": to, "data": data}, hex(block)], url, tries=2)
    except Exception:
        return None


def keccak(hexdata):
    import subprocess
    return subprocess.check_output(["cast", "keccak", hexdata]).decode().strip()


def map_slot(key_hex32, base):
    """keccak256(key . base) for value-type keys (key already left-padded to 32 bytes hex without 0x)."""
    return keccak("0x" + key_hex32.rjust(64, "0") + hex(base)[2:].rjust(64, "0"))
