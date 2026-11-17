#!/usr/bin/env python3
"""F5 stage 1: per-chain proxy birth blocks, implementation history, admin/owner events (read-only)."""
import json, sys, time
sys.path.insert(0, "scripts")
from F5_lib import *

TM = json.load(open("evidence/F5/topicmap.json"))
HIGH = {"TransactionDeposited", "WithdrawalProven", "WithdrawalProvenExtension1", "WithdrawalFinalized", "SentMessage",
        "SentMessageExtension1", "RelayedMessage", "FailedRelayedMessage", "ETHDepositInitiated", "ERC20DepositInitiated",
        "ETHBridgeInitiated", "ERC20BridgeInitiated", "ETHBridgeFinalized", "ERC20BridgeFinalized", "ETHWithdrawalFinalized",
        "ERC20WithdrawalFinalized", "ERC721BridgeInitiated", "ERC721BridgeFinalized", "DisputeGameCreated", "ETHLocked",
        "ETHUnlocked", "Deposit", "Withdrawal", "Transfer", "Approval", "OptimismMintableERC20Created",
        "StandardL2TokenCreated", "OutputProposed", "Move", "Resolved", "GameClosed"}
LOW = [t for t, v in TM.items() if v["sig"].split("(")[0] not in HIGH]

def decode(l):
    t0 = l["topics"][0]
    m = TM.get(t0)
    d = dict(block=int(l["blockNumber"], 16), tx=l["transactionHash"], logIndex=int(l["logIndex"], 16), address=l["address"],
             event=m["sig"] if m else t0, topics=l["topics"][1:], data=l["data"])
    return d

def impl_info(a, block=PIN):
    if not a or int(a, 16) == 0:
        return None
    return dict(address=a, version=as_str(call(a, "version()", block=block)), codeSize=(len(code(a, block)) - 2) // 2)

def run(chain):
    c = CHAINS[chain]
    out = dict(chain=chain, chainId=c["chainId"], pin=PIN, contracts={})
    am = as_addr(call(c["ProxyAdmin"], "addressManager()"))
    names = dict(c)
    names.pop("chainId")
    names["AddressManager"] = am
    for name, a in names.items():
        t = time.time()
        fb = first_code_block(a)
        rec = dict(address=a, firstCodeBlock=fb, firstCodeTs=block_ts(fb))
        ev = logs(a, [LOW], fb, PIN)
        rec["events"] = [decode(l) for l in ev]
        if name not in ("ProxyAdmin", "AddressManager"):
            rec["implSlotAtBirth"] = as_addr(storage(a, IMPL_SLOT, fb))
            rec["adminSlotAtBirth"] = as_addr(storage(a, ADMIN_SLOT, fb))
            rec["implSlotAtPin"] = as_addr(storage(a, IMPL_SLOT, PIN))
            rec["adminSlotAtPin"] = as_addr(storage(a, ADMIN_SLOT, PIN))
        if name == "L1StandardBridge":
            rec["implSlotHistory"] = [(b, as_addr(v)) for b, v in slot_history(a, IMPL_SLOT, fb, PIN)]
        if name == "ProxyAdmin":
            rec["owner"] = as_addr(call(a, "owner()"))
            rec["ownerAtBirth"] = as_addr(call(a, "owner()", block=fb))
        out["contracts"][name] = rec
        print(chain, name, a, "born", fb, rec["firstCodeTs"], "events", len(ev), f"{time.time()-t:.1f}s", flush=True)
    json.dump(out, open(f"evidence/F5/{chain}-history-raw.json", "w"), indent=1)

for ch in sys.argv[1:]:
    run(ch)
