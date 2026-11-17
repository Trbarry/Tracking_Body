"""Fetch L2ToL1MessagePasser storage proofs (eth_getProof, read-only) for withdrawal hashes at the L2 block
of a real L1 dispute game, and the output-root preimage. Usage: fetch_proofs.py <l2block> <in.json> <out.json>
in.json: list of {"id":..., "withdrawalHash":...}"""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rpc
from keccak import keccak
blk = int(sys.argv[1]); items = json.load(open(sys.argv[2])); out = sys.argv[3]
PASSER = "0x4200000000000000000000000000000000000016"
b = rpc.call(rpc.L2, "eth_getBlockByNumber", [hex(blk), False])
res = {"l2Block": blk, "stateRoot": b["stateRoot"], "blockHash": b["hash"], "timestamp": int(b["timestamp"], 16), "proofs": []}
slots = ["0x" + keccak(bytes.fromhex(i["withdrawalHash"][2:]) + b"\x00"*32).hex() for i in items]
for k in range(0, len(slots), 20):
    p = rpc.call(rpc.L2, "eth_getProof", [PASSER, slots[k:k+20], hex(blk)])
    res["messagePasserStorageRoot"] = p["storageHash"]
    for it, sp in zip(items[k:k+20], p["storageProof"]):
        res["proofs"].append(dict(it, slot=sp["key"], value=sp["value"], proof=sp["proof"]))
orr = keccak(b"\x00"*32 + bytes.fromhex(res["stateRoot"][2:]) + bytes.fromhex(res["messagePasserStorageRoot"][2:]) + bytes.fromhex(res["blockHash"][2:]))
res["outputRoot"] = "0x" + orr.hex()
json.dump(res, open(out, "w"), indent=1)
print("outputRoot", res["outputRoot"], "n", len(res["proofs"]), "values", sorted({p["value"] for p in res["proofs"]}))
