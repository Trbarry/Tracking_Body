#!/usr/bin/env python3
"""F4 — chunked eth_getLogs census (<= 10k blocks per call) through the local read-only archive proxy.

usage: F4_scan_logs.py <address> <from> <to> <out.jsonl> <topic0> [topic0 ...]
Each output line: [blockNumber, txIndex, logIndex, topic0_index, topics[1:], data]   (data kept only if <= 66 chars)
A chunk that keeps failing is split in halves down to single blocks; failures are written to <out>.failed.
"""
import json, sys, os
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0, os.path.dirname(__file__))
from F4_rpc import call

CH = 10000


def fetch(addr, topics, lo, hi, failed):
    try:
        return call("eth_getLogs", [{"address": addr, "topics": [topics], "fromBlock": hex(lo), "toBlock": hex(hi)}],
                    tries=4)
    except Exception as e:
        if hi == lo:
            failed.append((lo, hi, repr(e)[:200]))
            return []
        mid = (lo + hi) // 2
        return fetch(addr, topics, lo, mid, failed) + fetch(addr, topics, mid + 1, hi, failed)


def main():
    addr, lo, hi, out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
    if "," in addr:
        addr = addr.split(",")  # several emitters in one filter
    topics = sys.argv[5:]
    chunks = [(a, min(a + CH - 1, hi)) for a in range(lo, hi + 1, CH)]
    failed = []
    n = 0
    with ThreadPoolExecutor(4) as ex, open(out, "w") as f:
        for (a, b), logs in zip(chunks, ex.map(lambda c: fetch(addr, topics, c[0], c[1], failed), chunks)):
            for l in logs:
                d = l["data"]
                f.write(json.dumps([int(l["blockNumber"], 16), int(l["transactionIndex"], 16), int(l["logIndex"], 16),
                                    topics.index(l["topics"][0]), l["topics"][1:], d if len(d) <= 66 else d[:66] + "…",
                                    l["transactionHash"], l["address"]]) + "\n")
                n += 1
            f.flush()
    with open(out + ".failed", "w") as f:
        json.dump(failed, f)
    print("logs", n, "failed chunks", len(failed))


if __name__ == "__main__":
    main()
