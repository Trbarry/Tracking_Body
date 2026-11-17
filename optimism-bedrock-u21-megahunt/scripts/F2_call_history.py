#!/usr/bin/env python3
"""F2 — history of view-call results (roles, respected game type, game implementations, pause)
from L1 archive state. Read-only.

Same sampling+bisection method as F2_impl_history.py, applied to eth_call results: a value is
sampled every STEP blocks and every interval with differing endpoints is bisected to the exact
block of change. A revert (or empty return) is recorded as null and treated as a value.
A change that is reverted inside one STEP window is NOT detected (stated limit).

usage: F2_call_history.py <config.json> <out.json>
config: {"rpc":..,"end":N,"step":N,"targets":[{"name","to","sig","args":[..],"start":N}]}
"sig" is a cast-style signature; calldata is produced with `cast calldata`.
"""
import json, subprocess, sys, time, urllib.request, os


class Rpc:
    def __init__(self, url):
        self.url, self.n = url, 0
        self.force_single = False

    def batch(self, calls):
        out = [None] * len(calls)
        if self.force_single:
            self.n += len(calls)
            return [self.single(m, p) for m, p in calls]
        CH = 40
        for off in range(0, len(calls), CH):
            chunk = calls[off:off + CH]
            body = [{"jsonrpc": "2.0", "id": i, "method": m, "params": p} for i, (m, p) in enumerate(chunk)]
            for attempt in range(7):
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
                            msg = str(item.get("error")).lower()
                            if "revert" in msg or "execution" in msg or "invalid opcode" in msg or "out of gas" in msg:
                                out[off + item["id"]] = None
                            else:
                                bad = True
                    if bad:
                        raise RuntimeError("rpc error: " + str(res)[:300])
                    break
                except Exception:
                    if attempt == 6:
                        for j, (m, p) in enumerate(chunk):
                            out[off + j] = self.single(m, p)
                        break
                    time.sleep(1.5 * (attempt + 1))
            self.n += len(chunk)
        return out

    def one(self, m, p):
        return self.batch([(m, p)])[0]

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



def norm(v):
    return None if v in (None, "0x") else v


def changes(rpc, to, data, start, end, step):
    pts = list(range(start, end, step)) + [end]
    vals = [norm(v) for v in rpc.batch([("eth_call", [{"to": to, "data": data}, hex(b)]) for b in pts])]
    known = dict(zip(pts, vals))

    def get(b):
        if b not in known:
            known[b] = norm(rpc.one("eth_call", [{"to": to, "data": data}, hex(b)]))
        return known[b]

    found = []

    def rec(lo, hi):
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


def main():
    cfg = json.load(open(sys.argv[1]))
    rpc = Rpc(cfg["rpc"])
    rpc.force_single = bool(cfg.get("single"))
    end, step = cfg["end"], cfg["step"]
    out = {"rpc": cfg["rpc"], "end_block": end, "sample_step": step, "targets": []}
    done = {}
    if os.path.exists(sys.argv[2]):
        try:
            done = {x["name"]: x for x in json.load(open(sys.argv[2]))["targets"]}
        except Exception:
            done = {}
    tscache = {}
    for t in cfg["targets"]:
        if t["name"] in done:
            out["targets"].append(done[t["name"]])
            continue
        data = subprocess.check_output(["cast", "calldata", t["sig"]] + [str(a) for a in t.get("args", [])]).decode().strip()
        ch = changes(rpc, t["to"], data, t["start"], end, step)
        rows = []
        for b, v in ch:
            if b not in tscache:
                blk = None
                for _ in range(8):
                    blk = rpc.one("eth_getBlockByNumber", [hex(b), False])
                    if blk:
                        break
                    time.sleep(1)
                tscache[b] = int(blk["timestamp"], 16)
            rows.append({"block": b, "timestamp": tscache[b],
                         "utc": time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime(tscache[b])), "value": v})
            print(t["name"], b, rows[-1]["utc"], v if v is None or len(v) <= 130 else v[:130] + "...", flush=True)
        out["targets"].append({"name": t["name"], "to": t["to"], "sig": t["sig"], "args": t.get("args", []),
                               "calldata": data, "start": t["start"], "history": rows})
        out["rpc_calls"] = rpc.n
        json.dump(out, open(sys.argv[2], "w"), indent=1)


if __name__ == "__main__":
    main()
