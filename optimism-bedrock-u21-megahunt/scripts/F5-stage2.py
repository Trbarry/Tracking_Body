#!/usr/bin/env python3
"""F5 stage 2: dispute-infra generations, custody samples, respected-type / retirement / OPCM slot histories (read-only)."""
import json, sys, datetime, collections
sys.path.insert(0, "scripts")
from F5_lib import *
TM = json.load(open("evidence/F5/topicmap.json"))
d = lambda t: datetime.datetime.fromtimestamp(t, datetime.UTC).strftime('%Y-%m-%d %H:%M:%S')
HIGH = {"Deposit", "Withdrawal", "Transfer", "Approval", "AnchorUpdated"}
LOW = [t for t, v in TM.items() if v["sig"].split("(")[0] not in HIGH and v["sig"].split("(")[0] not in
       {"TransactionDeposited", "WithdrawalProven", "WithdrawalProvenExtension1", "WithdrawalFinalized", "DisputeGameCreated", "OutputProposed", "Move", "Resolved", "GameClosed", "ETHLocked", "ETHUnlocked"}]
OPCM_SLOT = None
def dec(l):
    m = TM.get(l["topics"][0]); b = int(l["blockNumber"], 16)
    return dict(block=b, tx=l["transactionHash"], event=m["sig"] if m else l["topics"][0], topics=l["topics"][1:], data=l["data"][:1026])

CENSUS = dict(OP="evidence/F5/op-games-0-21388.json", INK="evidence/F5/ink-games-0-2639.json", SONEIUM="evidence/F5/soneium-games-0-8536.json", UNICHAIN="evidence/F5/unichain-games-0-17690.json")
def run(chain):
    c = CHAINS[chain]
    games = json.load(open(CENSUS[chain]))
    up = json.load(open(f"evidence/F5/{chain}-upgrade-txs.json"))
    out = dict(chain=chain, pin=PIN)
    # --- dispute infra generations discovered from the census
    asrs = collections.OrderedDict(); weths = collections.OrderedDict()
    for g in games:
        if g["gameAsr"]: asrs.setdefault(g["gameAsr"], []).append(g["index"])
        if g["weth"]: weths.setdefault(g["weth"], []).append(g["index"])
    # super permissioned (type 5) games have no weth(); add SystemConfig.delayedWETH and current
    weths.setdefault(c["DelayedWETH"].lower(), [])
    out["asr"] = []
    for a, idx in asrs.items():
        fb = first_code_block(a)
        rec = dict(address=a, bornBlock=fb, bornTime=d(block_ts(fb)), version=as_str(call(a, "version()")), games=len(idx), firstGame=idx[0], lastGame=idx[-1],
                   isCurrent=a.lower() == c["AnchorStateRegistry"].lower(), ethBalance=balance(a),
                   respectedGameType=as_int(call(a, "respectedGameType()")), retirementTimestamp=as_int(call(a, "retirementTimestamp()")),
                   anchorGame=as_addr(call(a, "anchorGame()")), paused=as_int(call(a, "paused()")), portal=as_addr(call(a, "portal()")),
                   superchainConfig=as_addr(call(a, "superchainConfig()")), disputeGameFactory=as_addr(call(a, "disputeGameFactory()")),
                   implSlot=as_addr(storage(a, IMPL_SLOT)), adminSlot=as_addr(storage(a, ADMIN_SLOT)))
        ev = [dec(l) for l in logs(a, [LOW], fb, PIN)]
        rec["events"] = [e for e in ev if e["event"].split("(")[0] not in ("AdminChanged",)]
        out["asr"].append(rec)
        print(chain, "ASR", a, rec["bornTime"], "v", rec["version"], "games", len(idx), "events", collections.Counter(e["event"].split("(")[0] for e in ev), flush=True)
    out["delayedWETH"] = []
    for a, idx in weths.items():
        fb = first_code_block(a)
        rec = dict(address=a, bornBlock=fb, bornTime=d(block_ts(fb)), version=as_str(call(a, "version()")), games=len(idx),
                   firstGame=idx[0] if idx else None, lastGame=idx[-1] if idx else None, isSystemConfigWeth=a.lower() == c["DelayedWETH"].lower(),
                   ethBalanceWei=balance(a), ethBalance=balance(a) / 1e18, totalSupply=as_int(call(a, "totalSupply()")), delay=as_int(call(a, "delay()")),
                   owner=as_addr(call(a, "owner()")), config=as_addr(call(a, "config()")), systemConfig=as_addr(call(a, "systemConfig()")),
                   proxyAdminOwner=as_addr(call(a, "proxyAdminOwner()")), implSlot=as_addr(storage(a, IMPL_SLOT)), adminSlot=as_addr(storage(a, ADMIN_SLOT)))
        ev = [dec(l) for l in logs(a, [LOW], fb, PIN)]
        rec["events"] = [e for e in ev if e["event"].split("(")[0] not in ("AdminChanged",)]
        rec["implVersionNow"] = as_str(call(rec["implSlot"], "version()")) if rec["implSlot"] and int(rec["implSlot"], 16) else None
        out["delayedWETH"].append(rec)
        print(chain, "WETH", a, rec["bornTime"], "v", rec["version"], "games", len(idx), "bal", rec["ethBalance"], "owner", rec["owner"], "events", collections.Counter(e["event"].split("(")[0] for e in ev), flush=True)
    # --- ASR slot 6 history (respectedGameType | retirementTimestamp | ethLockbox) on the current ASR
    a = c["AnchorStateRegistry"]; fb = first_code_block(a)
    out["asrSlot6History"] = [dict(block=b, time=d(block_ts(b)), raw=v, respectedGameType=int(v[-8:], 16), retirementTimestamp=int(v[-24:-8], 16)) for b, v in slot_history(a, 6, fb, PIN)]
    for x in out["asrSlot6History"]: print(chain, "ASR slot6", x, flush=True)
    # --- SystemConfig lastUsedOPCM history: sample at each upgrade block
    sc = c["SystemConfig"]
    out["lastUsedOPCM"] = []
    for u in up:
        b = u["block"]
        if b < 23000000: continue
        v = as_addr(call(sc, "lastUsedOPCM()", block=b))
        ver = as_str(call(sc, "lastUsedOPCMVersion()", block=b))
        out["lastUsedOPCM"].append(dict(block=b, time=u["time"], lastUsedOPCM=v, lastUsedOPCMVersion=ver))
        print(chain, "lastUsedOPCM", b, v, ver, flush=True)
    # --- custody samples at each upgrade block (before / after)
    out["custody"] = []
    blocks = sorted({u["block"] for u in up if u["block"] > 17000000})
    lb = c["ETHLockbox"]; lb_born = first_code_block(lb)
    for b in blocks + [PIN]:
        row = dict(block=b, time=d(block_ts(b)))
        for nm in ("OptimismPortal", "L1CrossDomainMessenger", "L1StandardBridge"):
            row[nm + "_before"] = balance(c[nm], b - 1) / 1e18
            row[nm + "_after"] = balance(c[nm], b) / 1e18
        row["ETHLockbox_before"] = balance(lb, b - 1) / 1e18 if b - 1 >= lb_born else None
        row["ETHLockbox_after"] = balance(lb, b) / 1e18 if b >= lb_born else None
        out["custody"].append(row)
        print(chain, "custody", row, flush=True)
    json.dump(out, open(f"evidence/F5/{chain}-stage2.json", "w"), indent=1)
for ch in sys.argv[1:]:
    run(ch)
