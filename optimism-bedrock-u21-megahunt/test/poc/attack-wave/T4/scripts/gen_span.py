#!/usr/bin/env python3
"""ATK-T4 synthetic span-batch tx corpus: user-signable tx shapes (legacy protected/unprotected,
EIP-2930, EIP-1559, EIP-7702; creation; access lists; auth lists; big data; extreme field values).
Signatures are random (the span codec does not verify them; the hash check is skipped for these).
Usage: gen_span.py <out.jsonl> <seed>"""
import json, random, sys
R = random.Random(int(sys.argv[2]))
out = open(sys.argv[1], "w")
SECP_N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141


def q(x):
    return hex(x)


def big():
    return R.choice([0, 1, R.getrandbits(8), R.getrandbits(32), R.getrandbits(64), R.getrandbits(128), 2**256 - 1, R.getrandbits(256)])


def addr():
    return "0x" + R.randbytes(20).hex()


def sig():
    return q(R.randrange(1, SECP_N)), q(R.randrange(1, SECP_N // 2 + 1))


def data():
    L = R.choice([0, 0, 4, 36, 68, R.randint(0, 300), R.randint(300, 5000), R.choice([24576, 49152, 100000])])
    return "0x" + R.randbytes(L).hex()


def alist():
    return [{"address": addr(), "storageKeys": ["0x" + R.randbytes(32).hex() for _ in range(R.choice([0, 1, 3]))]}
            for _ in range(R.choice([0, 0, 1, 2, 5]))]


def tx(chain=10):
    ty = R.choice([0, 0, 1, 2, 2, 4])
    r, s = sig()
    t = {"type": q(ty), "nonce": q(R.choice([0, 1, R.getrandbits(32), 2**64 - 2])), "gas": q(R.choice([21000, R.getrandbits(24), 2**24, 2**63])),
         "value": q(big()), "input": data(), "r": r, "s": s, "hash": "0x" + "00" * 32}
    create = R.random() < 0.15 and ty != 4
    t["to"] = None if create else addr()
    if ty == 0:
        t["gasPrice"] = q(R.choice([0, 1, R.getrandbits(40), R.getrandbits(128)]))
        if R.random() < 0.25:  # pre-EIP-155 (unprotected)
            t["v"] = q(R.choice([27, 28]))
        else:
            t["chainId"] = q(chain)
            t["v"] = q(chain * 2 + 35 + R.randint(0, 1))
    else:
        yp = R.randint(0, 1)
        t["chainId"] = q(chain)
        t["yParity"] = q(yp)
        t["v"] = q(yp)
        t["accessList"] = alist()
        if ty == 1:
            t["gasPrice"] = q(R.choice([0, 1, R.getrandbits(40), R.getrandbits(128)]))
        else:
            t["maxFeePerGas"] = q(R.choice([0, 1, R.getrandbits(40), R.getrandbits(128)]))
            t["maxPriorityFeePerGas"] = q(R.choice([0, 1, R.getrandbits(40)]))
        if ty == 4:
            auths = []
            for _ in range(R.choice([1, 1, 2, 8])):
                ar, as_ = sig()
                auths.append({"chainId": q(R.choice([0, chain, R.getrandbits(64)])), "address": addr(),
                              "nonce": q(R.choice([0, R.getrandbits(64)])), "yParity": q(R.randint(0, 1)), "r": ar, "s": as_})
            t["authorizationList"] = auths
    return t


n = 0
for i in range(1500):
    txs = [tx() for _ in range(R.choice([1, 1, 2, 5, 20, 80]))]
    out.write(json.dumps({"k": "span", "id": f"spansyn#{i}", "chain_id": 10, "rpc_txs": txs}) + "\n")
    n += len(txs)
print("txs", n, file=sys.stderr)
