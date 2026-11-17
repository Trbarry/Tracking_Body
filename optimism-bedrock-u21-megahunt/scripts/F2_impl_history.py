#!/usr/bin/env python3
"""F2 — reconstruct the implementation history of a proxy from L1 archive state.

Read-only. Samples a storage slot every STEP blocks between the first block where the
proxy has code and END, then bisects every interval whose endpoints differ, so every
change that is visible at block granularity AND persists for >= STEP blocks is found
(a change-and-revert inside one STEP window with identical endpoints would be missed;
changes inside one transaction, e.g. StorageSetter cycles, are invisible by construction).

For each change block: block timestamp, new slot value, version() of the proxy at that
block (eth_call), and the transaction(s) in that block that emitted an event from the
watched contract (Upgraded(address) for EIP-1967 proxies, AddressSet for AddressManager).

usage: F2_impl_history.py <config.json> <out.json>
config: {"rpc":..., "end":N, "step":N, "targets":[{"name","addr","slot","kind","call_addr"(opt),"start"(opt)}]}
"""
import json, sys, time, urllib.request

IMPL_SLOT = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
VERSION_SEL = "0x54fd4d50"

class Rpc:
    def __init__(self, url):
        self.url = url
        self.n = 0
        self.force_single = False

    def batch(self, calls):
        """calls: list of (method, params) -> list of results (None on error)."""
        out = [None] * len(calls)
        if self.force_single:
            self.n += len(calls)
            return [self.single(m, p) for m, p in calls]
        CH = 40
        for off in range(0, len(calls), CH):
            chunk = calls[off:off + CH]
            body = [{"jsonrpc": "2.0", "id": i, "method": m, "params": p} for i, (m, p) in enumerate(chunk)]
            for attempt in range(6):
                try:
                    req = urllib.request.Request(self.url, data=json.dumps(body).encode(),
                                                 headers={"content-type": "application/json"})
                    with urllib.request.urlopen(req, timeout=120) as r:
                        res = json.loads(r.read())
                    if isinstance(res, dict):
                        raise RuntimeError(str(res)[:200])
                    bad = False
                    for item in res:
                        if "result" in item:
                            out[off + item["id"]] = item["result"]
                        else:
                            msg = str(item.get("error"))
                            # execution reverts are legitimate "no value" answers
                            if "revert" in msg.lower() or "execution" in msg.lower():
                                out[off + item["id"]] = None
                            else:
                                bad = True
                    if bad:
                        raise RuntimeError("rpc error in batch: " + str(res)[:300])
                    break
                except Exception as e:  # noqa
                    if attempt == 5:
                        for j, (m, p) in enumerate(chunk):
                            out[off + j] = self.single(m, p)
                        break
                    time.sleep(1.5 * (attempt + 1))
            self.n += len(chunk)
        return out

    def one(self, method, params):
        return self.batch([(method, params)])[0]

    def single(self, method, params):
        """one request, retried; used when the upstream rejects batches or one upstream is pruned."""
        last = None
        for attempt in range(12):
            try:
                body = {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}
                req = urllib.request.Request(self.url, data=json.dumps(body).encode(), headers={"content-type": "application/json"})
                with urllib.request.urlopen(req, timeout=120) as r:
                    res = json.loads(r.read())
                if "result" in res:
                    return res["result"]
                msg = str(res.get("error")).lower()
                if ("revert" in msg or "execution" in msg) and "pruned" not in msg and "insufficient" not in msg and "upstream" not in msg:
                    return None
                last = msg
            except Exception as e:
                last = str(e)
            time.sleep(0.5 + 0.5 * attempt)
        raise RuntimeError("single call failed: " + str(last)[:200])


    def must(self, method, params, tries=8):
        """like one(), but a null answer is retried (the failover proxy rotates upstreams)."""
        for i in range(tries):
            r = self.one(method, params)
            if r is not None:
                return r
            time.sleep(1.0 + i)
        return None


def first_code_block(rpc, addr, lo, hi):
    if rpc.one("eth_getCode", [addr, hex(lo)]) not in (None, "0x"):
        return lo
    while lo + 1 < hi:
        mid = (lo + hi) // 2
        if rpc.one("eth_getCode", [addr, hex(mid)]) not in (None, "0x"):
            hi = mid
        else:
            lo = mid
    return hi


def changes(rpc, addr, slot, start, end, step):
    pts = list(range(start, end, step)) + [end]
    vals = rpc.batch([("eth_getStorageAt", [addr, slot, hex(b)]) for b in pts])
    known = dict(zip(pts, vals))

    def get(b):
        if b not in known:
            known[b] = rpc.one("eth_getStorageAt", [addr, slot, hex(b)])
        return known[b]

    found = []

    def rec(lo, hi):
        # invariant: get(lo) != get(hi)
        if hi - lo == 1:
            found.append(hi)
            return
        mid = (lo + hi) // 2
        if get(lo) != get(mid):
            rec(lo, mid)
        if get(mid) != get(hi):
            rec(mid, hi)

    for a, b in zip(pts, pts[1:]):
        if known[a] != known[b]:
            rec(a, b)
    found.sort()
    return [(start, known[start])] + [(b, get(b)) for b in found]


def decode_string(hexdata):
    if not hexdata or hexdata == "0x":
        return None
    try:
        raw = bytes.fromhex(hexdata[2:])
        off = int.from_bytes(raw[0:32], "big")
        ln = int.from_bytes(raw[off:off + 32], "big")
        return raw[off + 32:off + 32 + ln].decode("utf-8", "replace")
    except Exception:
        return None


def main():
    cfg = json.load(open(sys.argv[1]))
    rpc = Rpc(cfg["rpc"])
    rpc.force_single = bool(cfg.get("single"))
    end, step = cfg["end"], cfg["step"]
    out = {"rpc": cfg["rpc"], "end_block": end, "sample_step": step, "method":
           "sample slot every step blocks from first-code block, bisect differing intervals; version() via eth_call at the change block",
           "targets": []}
    import os
    done = {}
    if os.path.exists(sys.argv[2]):
        try:
            done = {x["name"]: x for x in json.load(open(sys.argv[2]))["targets"]}
        except Exception:
            done = {}
    for t in cfg["targets"]:
        if t["name"] in done:
            out["targets"].append(done[t["name"]])
            continue
        addr, slot = t["addr"], t.get("slot", IMPL_SLOT)
        call_addr = t.get("call_addr", addr)
        start = t.get("start") or first_code_block(rpc, addr, cfg.get("floor", 12000000), end)
        ch = changes(rpc, addr, slot, start, end, step)
        rows = []
        for b, v in ch:
            impl = "0x" + (v or "0x" + "0" * 64)[-40:]
            blk = rpc.must("eth_getBlockByNumber", [hex(b), False])
            ver = decode_string(rpc.one("eth_call", [{"to": call_addr, "data": VERSION_SEL}, hex(b)]))
            logs = rpc.one("eth_getLogs", [{"fromBlock": hex(b), "toBlock": hex(b), "address": addr}]) or []
            txs = sorted({l["transactionHash"] for l in logs})
            txinfo = []
            for h in txs:
                tx = rpc.must("eth_getTransactionByHash", [h]) or {"from": None, "to": None, "input": "0x"}
                txinfo.append({"hash": h, "from": tx["from"], "to": tx["to"], "selector": tx["input"][:10]})
            rows.append({"block": b, "timestamp": int(blk["timestamp"], 16),
                         "utc": time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime(int(blk["timestamp"], 16))),
                         "slot_value": v, "implementation": impl, "version": ver,
                         "txs_with_logs_from_target": txinfo})
            print(t["name"], b, rows[-1]["utc"], impl, ver, [x["hash"] for x in txinfo], flush=True)
        out["targets"].append({"name": t["name"], "address": addr, "slot": slot, "kind": t.get("kind", "eip1967"),
                               "version_read_from": call_addr, "first_code_block": start, "history": rows})
        out["rpc_calls"] = rpc.n
        json.dump(out, open(sys.argv[2], "w"), indent=1)
    out["rpc_calls"] = rpc.n
    json.dump(out, open(sys.argv[2], "w"), indent=1)


if __name__ == "__main__":
    main()
