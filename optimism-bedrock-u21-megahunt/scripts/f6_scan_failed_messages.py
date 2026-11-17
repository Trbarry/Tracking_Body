#!/usr/bin/env python3
"""F6: full-history census of FailedRelayedMessage(bytes32) emitted by the OP Mainnet
L1CrossDomainMessenger proxy (0x25ace71c...) from Bedrock to head, in <=10k-block eth_getLogs chunks
(local archive proxy :7545). Resumable: progress is saved every 20 chunks.

Output: evidence/F6-failed-relayed-logs.json
  {"meta": {...}, "done_to": <block>, "logs": [{"block","tx","txIndex","logIndex","msgHash"}], "refused": [[from,to,err]]}
"""
import json, os, sys, concurrent.futures as cf
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from f6_rpc import call, get_logs

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "evidence", "F6-failed-relayed-logs.json")
L1CDM = "0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1"
TOPIC = "0x99d0e048484baa1b1540b1367cb128acd7ab2946d1ed91ec10e3c85e4bf51b8f"
START = 17422444
STEP = 10000

def chunk(a):
    b = a + STEP - 1
    try:
        return a, b, get_logs(L1CDM, [TOPIC], a, b), None
    except Exception as e:
        return a, b, [], str(e)[:200]

def main():
    head = int(call("eth_blockNumber", []), 16) - 8
    st = {"meta": {"address": L1CDM, "topic0": TOPIC, "start": START, "step": STEP, "rpc": "http://127.0.0.1:7545"},
          "done_to": START - 1, "logs": [], "refused": []}
    if os.path.exists(OUT):
        st = json.load(open(OUT))
    starts = list(range(st["done_to"] + 1, head + 1, STEP))
    with cf.ThreadPoolExecutor(3) as ex:
        for i in range(0, len(starts), 21):
            grp = starts[i:i + 21]
            for a, b, logs, err in ex.map(chunk, grp):
                if err:
                    st["refused"].append([a, b, err])
                for lg in logs:
                    st["logs"].append({"block": int(lg["blockNumber"], 16), "tx": lg["transactionHash"],
                                       "txIndex": int(lg["transactionIndex"], 16), "logIndex": int(lg["logIndex"], 16),
                                       "msgHash": lg["topics"][1]})
            st["done_to"] = min(grp[-1] + STEP - 1, head)
            st["head"] = head
            json.dump(st, open(OUT, "w"), indent=0)
            print(st["done_to"], len(st["logs"]), len(st["refused"]), file=sys.stderr, flush=True)

if __name__ == "__main__":
    main()
