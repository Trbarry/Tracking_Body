#!/usr/bin/env python3
"""ATK-T4 real-data corpus builder. Passive, low-rate, read-only JSON-RPC through the local
proxies only (L1 :7545, OP :7546): eth_getBlockByNumber / eth_getBlockByHash /
eth_getBlockReceipts / eth_getLogs (bounded chunks) / eth_getProof. Results cached on disk.

Usage: fetch_real.py <outdir> <spec...>
  spec "range:<l2_first>:<l2_last>"  every L2 block in the range
  spec "heavy:<l1_from>:<l1_to>:<topN>" top-N L1 blocks by portal deposit count, then their
        epoch-first OP block
Writes <outdir>/real-cases.jsonl (kind "attr" cases + "expect" field) and caches.
"""
import json, os, sys, time, urllib.request, hashlib

L1 = "http://127.0.0.1:7545"
L2 = "http://127.0.0.1:7546"
PORTAL = "0xbeb5fc579115071764c7423a4f12edde41f106ed"
DEP_TOPIC = "0xb3813568d9991fc951961fcb4c784893574240a28925604d09fc577c55bb7c32"
SLEEP = 0.12  # <= ~8 req/s
OUT = sys.argv[1] if len(sys.argv) > 1 else "."
CACHE = os.path.join(OUT, "cache")
os.makedirs(CACHE, exist_ok=True)


def rpc(url, method, params):
    key = hashlib.sha256(json.dumps([url, method, params]).encode()).hexdigest()
    p = os.path.join(CACHE, key + ".json")
    if os.path.exists(p):
        return json.load(open(p))
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    for attempt in range(5):
        try:
            req = urllib.request.Request(url, body, {"content-type": "application/json"})
            r = json.load(urllib.request.urlopen(req, timeout=120))
            break
        except Exception as e:  # transient proxy error: back off
            time.sleep(2 + attempt * 3)
    else:
        raise RuntimeError(f"rpc failed {method} {params}")
    time.sleep(SLEEP)
    if "error" in r:
        raise RuntimeError(f"rpc error {method} {params}: {r['error']}")
    json.dump(r["result"], open(p, "w"))
    return r["result"]


HDR_KEYS = ["parentHash", "sha3Uncles", "miner", "stateRoot", "transactionsRoot", "receiptsRoot",
            "logsBloom", "difficulty", "number", "gasLimit", "gasUsed", "timestamp", "extraData",
            "mixHash", "nonce", "baseFeePerGas", "withdrawalsRoot", "blobGasUsed", "excessBlobGas",
            "parentBeaconBlockRoot", "requestsHash"]


def hdr(b):
    return {k: b[k] for k in HDR_KEYS if k in b and b[k] is not None}


def l2block(n):
    return rpc(L2, "eth_getBlockByNumber", [hex(n), True])


def parse_l1info(inp):
    d = bytes.fromhex(inp[2:])
    sel = d[:4].hex()
    o = 4
    def take(n):
        nonlocal o
        v = d[o:o + n]; o += n
        return int.from_bytes(v, "big")
    r = {"len": len(d), "sel": sel}
    if len(d) == 260:  # bedrock (abi-encoded) - not expected in current blocks
        raise RuntimeError("bedrock-format l1 info in a current block")
    r["base_scalar"] = take(4); r["blob_scalar"] = take(4); r["seq"] = take(8); r["time"] = take(8)
    r["number"] = take(8); r["basefee"] = take(32); r["blobbasefee"] = take(32)
    r["hash"] = "0x" + d[o:o + 32].hex(); o += 32
    r["batcher"] = "0x" + d[o + 12:o + 32].hex(); o += 32
    if len(d) >= 176:
        r["op_scalar"] = take(4); r["op_const"] = take(8)
    if len(d) >= 178:
        r["da_scalar"] = take(2)
    return r


def extra_params(extra):
    d = bytes.fromhex(extra[2:])
    if len(d) == 0:
        return None, None, None
    den = int.from_bytes(d[1:5], "big"); el = int.from_bytes(d[5:9], "big")
    mbf = int.from_bytes(d[9:17], "big") if d[0] == 1 and len(d) >= 17 else None
    return den, el, mbf


def case_for(n, tag):
    b = l2block(n)
    p = l2block(n - 1)
    pi = parse_l1info(p["transactions"][0]["input"])
    bi = parse_l1info(b["transactions"][0]["input"])
    den, el, mbf = extra_params(p["extraData"])
    sysc = {
        "batcher": pi["batcher"], "overhead": "0",
        "scalar": str((1 << 248) | (pi["blob_scalar"] << 32) | pi["base_scalar"]),
        "gas_limit": int(p["gasLimit"], 16),
        "base_fee_scalar": None, "blob_base_fee_scalar": None,
        "eip1559_denominator": den, "eip1559_elasticity": el,
        "operator_fee_scalar": pi.get("op_scalar"), "operator_fee_constant": pi.get("op_const"),
        "min_base_fee": mbf, "da_footprint_gas_scalar": pi.get("da_scalar"),
    }
    l1b = rpc(L1, "eth_getBlockByHash", [bi["hash"], False])
    case = {
        "k": "attr", "id": f"{tag}:{n}", "chain": 10,
        "parent": {"hash": p["hash"], "number": int(p["number"], 16), "timestamp": int(p["timestamp"], 16),
                   "l1_hash": pi["hash"], "l1_number": pi["number"], "seq": pi["seq"]},
        "l1_header": hdr(l1b), "sys": sysc,
    }
    if bi["seq"] == 0:
        rs = rpc(L1, "eth_getBlockReceipts", [bi["hash"]])
        case["receipts"] = [{"status": int(r["status"], 16), "cgu": int(r["cumulativeGasUsed"], 16),
                             "logs": [{"address": l["address"], "topics": l["topics"], "data": l["data"]}
                                      for l in r["logs"]]} for r in rs]
    ndep = 0
    for t in b["transactions"]:
        if t["type"] == "0x7e":
            ndep += 1
        else:
            break
    bden, bel, bmbf = extra_params(b["extraData"])
    case["expect"] = {
        "l1_hash": l1b["hash"], "timestamp": int(b["timestamp"], 16), "prev_randao": b["mixHash"],
        "beacon_root": b.get("parentBeaconBlockRoot"), "gas_limit": int(b["gasLimit"], 16),
        "eip1559": "0x%08x%08x" % (bden, bel) if bden is not None else None, "min_base_fee": bmbf,
        "deposit_tx_hashes": [t["hash"] for t in b["transactions"][:ndep]],
        "seq": bi["seq"], "fee_recipient": b["miner"],
    }
    return case


def heavy(l1_from, l1_to, top):
    counts = {}
    step = 2000
    for s in range(l1_from, l1_to + 1, step):
        e = min(s + step - 1, l1_to)
        logs = rpc(L1, "eth_getLogs", [{"address": PORTAL, "topics": [DEP_TOPIC], "fromBlock": hex(s), "toBlock": hex(e)}])
        for l in logs:
            k = (int(l["blockNumber"], 16), l["blockHash"])
            counts[k] = counts.get(k, 0) + 1
    ranked = sorted(counts.items(), key=lambda kv: -kv[1])
    json.dump({"range": [l1_from, l1_to], "l1_blocks_with_deposits": len(counts),
               "total_deposits": sum(counts.values()),
               "top": [[k[0], k[1], v] for k, v in ranked[:50]]},
              open(os.path.join(OUT, f"deposit-scan-{l1_from}-{l1_to}.json"), "w"), indent=1)
    out = []
    for (num, h), cnt in ranked[:top]:
        l1b = rpc(L1, "eth_getBlockByNumber", [hex(num), False])
        ts = int(l1b["timestamp"], 16)
        n = 105235063 + (ts - 1686068903) // 2  # L2 block at the L1 timestamp
        for _ in range(40):  # walk to the epoch-first block of this origin
            info = parse_l1info(l2block(n)["transactions"][0]["input"])
            if info["number"] == num:
                n -= info["seq"]
                break
            n += max(1, (num - info["number"]) * 6) if info["number"] < num else -max(1, (info["number"] - num) * 6)
        else:
            continue
        out.append((n, cnt))
    return out


if __name__ == "__main__":
    cases = []
    for spec in sys.argv[2:]:
        kind, *a = spec.split(":")
        if kind == "range":
            for n in range(int(a[0]), int(a[1]) + 1):
                cases.append(case_for(n, "range"))
        elif kind == "heavy":
            for n, cnt in heavy(int(a[0]), int(a[1]), int(a[2])):
                cases.append(case_for(n, f"heavy{cnt}"))
        print(spec, "cases so far", len(cases), file=sys.stderr)
    with open(os.path.join(OUT, "real-cases.jsonl"), "w") as f:
        for c in cases:
            f.write(json.dumps(c) + "\n")
    print("wrote", len(cases), file=sys.stderr)
