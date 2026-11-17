#!/usr/bin/env python3
"""F5: assemble chains/<CHAIN>/{DEPLOYMENT,UPGRADE-PATH,STATE-U21}.json and the generated part of HISTORY.md
from the evidence gathered by the F5 scripts (all read-only chain reads at / before L1 block 26433900)."""
import json, sys, os, datetime, collections, toml
sys.path.insert(0, "scripts")
from F5_lib import *

E = "evidence/F5"
REG = "/home/user/ethereum-optimism/ext/superchain-registry/superchain/configs/mainnet"
PASSA = "/home/user/Tracking_Body/optimism-u21-novel-hunt/POST_UPGRADE_STATE_26433900.json"
KEYS = dict(OP=("op", "op-mainnet-10", "op-mainnet"), INK=("ink", "ink-57073", "ink"), SONEIUM=("soneium", "soneium-1868", "soneium"), UNICHAIN=("unichain", "unichain-130", "unichain"))
CENSUS = dict(OP="op-games-0-21388.json", INK="ink-games-0-2639.json", SONEIUM="soneium-games-0-8536.json", UNICHAIN="unichain-games-0-17690.json")
VERIF = dict(OP="op-root-verification.json", INK="ink-root-verification.json", SONEIUM="soneium-root-verification.json", UNICHAIN="unichain-root-verification.json")
d = lambda t: datetime.datetime.fromtimestamp(t, datetime.UTC).strftime('%Y-%m-%d %H:%M:%S')
ST = {0: "IN_PROGRESS", 1: "CHALLENGER_WINS", 2: "DEFENDER_WINS", None: "?"}
f2tasks = json.load(open("evidence/F2-superchain-ops-tasks.json"))["tasks"] if os.path.exists("evidence/F2-superchain-ops-tasks.json") else []
TX2TASK = {}
for t in f2tasks:
    for ex in t.get("executions") or []:
        TX2TASK[ex["tx"].lower()] = t["task"]
passa = json.load(open(PASSA))
vc = json.load(open(f"{E}/impl-version-cache.json"))
RELEASE = {  # upgrade block -> label (dates/tasks are evidence; the U-number mapping is F2's to confirm)
}
tsc = {}
def bts(b):
    if b not in tsc: tsc[b] = block_ts(b)
    return tsc[b]
def short(a): return a[:10] + "…" if a else str(a)

def build(chain):
    regname, pakey, f2key = KEYS[chain]
    c = CHAINS[chain]
    raw = json.load(open(f"{E}/{chain}-history-raw.json"))
    ups = json.load(open(f"{E}/{chain}-upgrade-txs.json"))
    st2 = json.load(open(f"{E}/{chain}-stage2.json"))
    games = json.load(open(f"{E}/{CENSUS[chain]}"))
    ver = json.load(open(f"{E}/{VERIF[chain]}")) if os.path.exists(f"{E}/{VERIF[chain]}") else None
    reg = toml.load(f"{REG}/{regname}.toml")
    os.makedirs(f"chains/{chain}", exist_ok=True)

    # ---------------- DEPLOYMENT.json
    dep = dict(chain=chain, chainId=c["chainId"], source="F5 scripts/F5-history.py (eth_getCode binary search, eth_getLogs full range through the L1 archive proxy), superchain-registry@edd89bd1",
               registry=dict(name=reg["name"], superchain_time=reg.get("superchain_time"), genesis=reg["genesis"], hardforks=reg["hardforks"], block_time=reg["block_time"],
                             batch_inbox_addr=reg["batch_inbox_addr"], roles=reg.get("roles"), public_rpc=reg.get("public_rpc"), data_availability_type=reg.get("data_availability_type")),
               proxies={})
    for n, r in raw["contracts"].items():
        first_up = next((e for e in r["events"] if e["event"].startswith("Upgraded")), None)
        born_impl = r.get("implSlotAtBirth")
        if (not born_impl or int(born_impl, 16) == 0) and first_up:
            born_impl = "0x" + first_up["topics"][0][-40:]
        if n == "L1CrossDomainMessenger":
            am = [e for e in raw["contracts"]["AddressManager"]["events"] if e["event"].startswith("AddressSet") and e["topics"][0] == "0x3b4a6791a6879d27c0ceeea3f78f8ebe66a01905f4a1290a8c6aff3e85f4665a"]
            born_impl = ("0x" + am[0]["data"][26:66]) if am else born_impl
        if n == "L1StandardBridge" and r.get("implSlotHistory"):
            nz = [a for b, a in r["implSlotHistory"] if a and int(a, 16)]
            born_impl = nz[0] if nz else born_impl
        dep["proxies"][n] = dict(address=r["address"], firstCodeBlock=r["firstCodeBlock"], firstCodeTime=d(r["firstCodeTs"]),
                                 implSlotAtFirstCodeBlock=r.get("implSlotAtBirth"), firstImplementation=born_impl,
                                 firstImplementationVersion=vc.get(born_impl.lower()) if born_impl else None,
                                 adminSlotAtFirstCodeBlock=r.get("adminSlotAtBirth"), adminSlotAtPin=r.get("adminSlotAtPin"), implAtPin=r.get("implSlotAtPin"))
    blocks = sorted({p["firstCodeBlock"] for p in dep["proxies"].values()})
    dep["deploymentBlocks"] = blocks
    json.dump(dep, open(f"chains/{chain}/DEPLOYMENT.json", "w"), indent=1)

    # ---------------- UPGRADE-PATH.json
    path = dict(chain=chain, source="Upgraded(address) events on every proxy, AddressManager AddressSet for L1CrossDomainMessenger, EIP-1967 slot bisection for L1StandardBridge (L1ChugSplashProxy emits no event). '*' / storageSetterCycle = StorageSetter implementation installed first in the same tx.",
                upgrades=[], lastUsedOPCM=st2["lastUsedOPCM"], asrSlot6History=st2["asrSlot6History"])
    for u in ups:
        if u["block"] < 17000000 and chain == "OP":
            # pre-Bedrock OVM AddressManager churn: keep only as a count
            continue
        row = dict(block=u["block"], time=u["time"], tx=u["tx"], superchainOpsTask=TX2TASK.get((u["tx"] or "").lower()), proxies=u["proxies"])
        path["upgrades"].append(row)
    if chain == "OP":
        path["preBedrockAddressManagerEvents"] = sum(1 for u in ups if u["block"] < 17000000)
    # cross-check against F2 slot-sampled history when present
    f2p = f"evidence/F2-impl-history-{f2key}.json"
    if os.path.exists(f2p):
        f2 = json.load(open(f2p)); mism = []; checked = 0
        mine = collections.defaultdict(dict)
        for u in ups:
            for p, x in u["proxies"].items():
                if x["impl"]: mine[p.split("(")[0]][u["block"]] = x["impl"].lower()
        for t in f2.get("targets", []):
            nm = t["name"].split("(")[0]
            for h in t.get("history", []):
                impl = (h.get("implementation") or "").lower()
                if not impl or int(impl, 16) == 0: continue
                checked += 1
                if mine.get(nm, {}).get(h["block"]) != impl:
                    mism.append(dict(name=nm, block=h["block"], f2=impl, f5=mine.get(nm, {}).get(h["block"])))
        path["crossCheckWithF2"] = dict(file=f2p, entriesChecked=checked, mismatches=mism)
    json.dump(path, open(f"chains/{chain}/UPGRADE-PATH.json", "w"), indent=1)

    # ---------------- STATE-U21.json
    pa = passa[pakey]
    state = dict(chain=chain, pinnedBlock=PIN, sources=["PASS A POST_UPGRADE_STATE_26433900.json (getters, raw slots)", "F5 census / stage2 / root verification"],
                 contracts={k: dict(proxy=v.get("proxy"), implementation=v.get("implementation"), version=v.get("version"), ethBalanceEther=v.get("ethBalanceEther"),
                                    initializedVersion=v.get("initializedVersion"), getters=v.get("getters")) for k, v in pa.items() if isinstance(v, dict)},
                 legacySlots={}, disputeInfra=dict(anchorStateRegistries=[{k: v for k, v in a.items() if k != "events"} for a in st2["asr"]],
                                                   delayedWETH=[{k: v for k, v in a.items() if k != "events"} for a in st2["delayedWETH"]]),
                 custodyAtPin=st2["custody"][-1])
    def slot(contract, s):
        e = pa.get(contract, {}).get("slots", {}).get(str(s))
        return e.get("raw") if e else None
    state["legacySlots"] = {
        "OptimismPortal2.slot53 (legacy paused byte | superchainConfig)": slot("OptimismPortal2", 53),
        "OptimismPortal2.slot54 (legacy l2Oracle)": slot("OptimismPortal2", 54),
        "OptimismPortal2.slot56 (legacy disputeGameFactory)": slot("OptimismPortal2", 56),
        "OptimismPortal2.slot59 (legacy respectedGameType | respectedGameTypeUpdatedAt)": slot("OptimismPortal2", 59),
        "OptimismPortal2.slot63 (ethLockbox | legacy superRootsActive byte)": slot("OptimismPortal2", 63),
        "L1CrossDomainMessenger.slot51 (legacy OVM owner)": slot("L1CrossDomainMessenger", 51),
        "L1CrossDomainMessenger.slot151 (legacy reentrancy status)": slot("L1CrossDomainMessenger", 151),
        "L1CrossDomainMessenger.slot251 (legacy superchainConfig)": slot("L1CrossDomainMessenger", 251),
        "L1StandardBridge.slot1 (legacy l2TokenBridge)": slot("L1StandardBridge", 1),
        "L1StandardBridge.slot50 (legacy superchainConfig)": slot("L1StandardBridge", 50),
        "SystemConfig.slot106 (eip1559Denominator | eip1559Elasticity | operatorFee*)": slot("SystemConfig", 106),
        "SystemConfig.slot108 (superchainConfig | minBaseFee)": slot("SystemConfig", 108),
        "DelayedWETH.slot4 (legacy config/systemConfig spacer)": slot("DelayedWETH", 4),
    }
    # census summary
    cls = collections.OrderedDict()
    for g in games:
        k = (g["type"], g["version"], g["gameAsr"], g["weth"], g["prestate"])
        cls.setdefault(k, []).append(g)
    state["gameCensus"] = dict(
        gameCount=len(games),
        lineageClasses=[dict(type=k[0], gameVersion=k[1], gameASR=k[2], weth=k[3], absolutePrestate=k[4], n=len(v), firstIndex=v[0]["index"], lastIndex=v[-1]["index"],
                             firstCreated=d(v[0]["createdAt"]), lastCreated=d(v[-1]["createdAt"]), creators=dict(collections.Counter(x["creator"] for x in v).most_common(6))) for k, v in cls.items()],
        byTypeCreatorStatus=[dict(type=k[0], creator=k[1], status=k[2], claimValid=k[3], retired=k[4], n=n) for k, n in
                             sorted(collections.Counter((g["type"], g["creator"], ST[g["status"]], g["claimValid"], g["retired"]) for g in games).items(), key=lambda z: -z[1])],
        blacklisted=[g["index"] for g in games if g["blacklisted"]],
        nonRetiredWithForeignASR=[g["index"] for g in games if not g["retired"] and (g["gameAsr"] or "").lower() != c["AnchorStateRegistry"].lower()],
        claimValid=sum(1 for g in games if g["claimValid"]), retired=sum(1 for g in games if g["retired"]),
        inProgress=[dict(index=g["index"], type=g["type"], game=g["game"], creator=g["creator"], createdAt=d(g["createdAt"]), prestate=g["prestate"]) for g in games if g["status"] == 0],
    )
    if ver:
        state["rootVerification"] = dict(method="output root recomputed from the L2 block header (post-Isthmus withdrawalsRoot); super games: extraData decoded, single-entry check, block = genesis + (timestamp-genesisTime)/blockTime",
                                         table=ver["table"],
                                         anomalies=[{k: g.get(k) for k in ("index", "type", "game", "creator", "status", "claimValid", "l2Block", "claimedOutput", "computedOutput", "match")}
                                                    for g in ver["games"] if (g["match"] is not True and (g["claimValid"] or g["status"] != 1)) or (g["match"] is True and g["status"] == 1)])
    json.dump(state, open(f"chains/{chain}/STATE-U21.json", "w"), indent=1)

    # ---------------- HISTORY (generated tables)
    L = []
    A = L.append
    A(f"# {chain} (chain id {c['chainId']}) — chain history profile (worker F5)\n")
    A(f"Generated from chain state by `scripts/F5-build-chain-files.py`; every row is a `cast`-equivalent read through the L1 archive proxy `http://127.0.0.1:7545` "
      f"at or before the pinned block {PIN}, or a superchain-registry / superchain-ops file. Raw evidence: `evidence/F5/{chain}-history-raw.json`, "
      f"`evidence/F5/{chain}-upgrade-txs.json`, `evidence/F5/{chain}-stage2.json`, `evidence/F5/{CENSUS[chain]}`, `evidence/F5/{VERIF[chain]}`.\n")
    A("## 1. Genesis / deployment generation\n")
    g = reg["genesis"]
    A(f"- Registry: L2 genesis time {g['l2_time']} ({d(g['l2_time'])} UTC), L1 origin block {g['l1']['number']}, L2 genesis block {g['l2']['number']}, block time {reg['block_time']} s, "
      f"`superchain_time` = {reg.get('superchain_time')}, fault proofs (chainList.json): {'permissioned' if chain == 'SONEIUM' else 'permissionless'}.")
    A(f"- Hardforks: " + ", ".join(f"{k.replace('_time','')}={v}" for k, v in reg["hardforks"].items() if k.endswith("_time")) + ".\n")
    A("| Proxy | Address | First code block | Date (UTC) | First implementation (version) | Admin slot at birth |")
    A("|---|---|---|---|---|---|")
    for n, p in dep["proxies"].items():
        A(f"| {n} | `{p['address']}` | {p['firstCodeBlock']} | {p['firstCodeTime']} | `{p['firstImplementation']}` ({p['firstImplementationVersion']}) | `{p['adminSlotAtFirstCodeBlock']}` |")
    A("")
    A("## 2. Upgrade path (every implementation change)\n")
    A("`*` = a StorageSetter implementation was installed first in the same transaction (re-initialisation cycle). Task = superchain-ops task whose README status line names this tx (mapping from `evidence/F2-superchain-ops-tasks.json`).\n")
    A("| L1 block | Date | Tx | superchain-ops task | Proxies -> version |")
    A("|---|---|---|---|---|")
    for u in path["upgrades"]:
        A(f"| {u['block']} | {u['time'][:10]} | `{(u['tx'] or 'n/a (slot bisection)')[:18]}` | {u['superchainOpsTask'] or '—'} | " +
          ", ".join(f"{p.split('(')[0]}={x['version']}{'*' if x['storageSetterCycle'] else ''}" for p, x in u["proxies"].items()) + " |")
    A("")
    if "crossCheckWithF2" in path:
        cc = path["crossCheckWithF2"]
        A(f"Cross-check against F2's independent slot-sampling history (`{cc['file']}`): {cc['entriesChecked']} (proxy, block, implementation) entries compared, {len(cc['mismatches'])} mismatches.\n")
    A("`lastUsedOPCM` (SystemConfig) sampled at each upgrade block:\n")
    A("| L1 block | lastUsedOPCM | version |")
    A("|---|---|---|")
    for x in st2["lastUsedOPCM"]:
        A(f"| {x['block']} | `{x['lastUsedOPCM']}` | {x['lastUsedOPCMVersion']} |")
    A("")
    A("## 3. Ownership, guardian, SuperchainConfig\n")
    for n in ("ProxyAdmin", "SystemConfig", "DisputeGameFactory", "AddressManager"):
        evs = [e for e in raw["contracts"][n]["events"] if e["event"].startswith("OwnershipTransferred")]
        # drop ProxyAdmin round trips inside an upgrade tx (owner -> ProxyAdmin -> owner) for readability
        seq = []
        bytx = collections.defaultdict(list)
        for e in evs: bytx[(e["block"], e["tx"])].append(e)
        for (b, tx), es in sorted(bytx.items()):
            frm = "0x" + es[0]["topics"][0][-40:]; to = "0x" + es[-1]["topics"][1][-40:]
            if frm == to and len(es) > 1:
                continue
            seq.append((b, tx, frm, to, len(es)))
        A(f"- **{n} owner history** (net change per tx; same-tx round trips through the ProxyAdmin during re-initialisation omitted): " +
          "; ".join(f"{b} ({d(bts(b))[:10]}) `{short(frm)}` -> `{to}`" for b, tx, frm, to, k in seq) + ".")
    A(f"- SuperchainConfig: `{SUPERCHAIN_CONFIG}` — portal slot 53 already held it at the proxy's first initialised block (shared instance from genesis for the three 2024 chains; OP Mainnet since the 2024-02-26 SuperchainConfig introduction). Guardian `0x9ba6e03d…` (2024-01-22) -> `0x09f7150d…` (2024-06-10), unchanged since (`evidence/F5/superchainconfig-events.json`).\n")
    A("## 4. Custody (ETH) at every upgrade block\n")
    A("| L1 block | Date | Portal before -> after | ETHLockbox before -> after | L1CDM | L1StandardBridge |")
    A("|---|---|---|---|---|---|")
    for r in st2["custody"]:
        f = lambda x: "—" if x is None else f"{x:,.3f}"
        A(f"| {r['block']} | {r['time'][:10]} | {f(r['OptimismPortal_before'])} -> {f(r['OptimismPortal_after'])} | {f(r['ETHLockbox_before'])} -> {f(r['ETHLockbox_after'])} | {f(r['L1CrossDomainMessenger_after'])} | {f(r['L1StandardBridge_after'])} |")
    A("")
    mig = [e for e in raw["contracts"]["OptimismPortal"]["events"] if e["event"].startswith("ETHMigrated")]
    for e in mig:
        A(f"- `ETHMigrated(lockbox=0x{e['topics'][0][-40:]}, amount={int(e['data'],16)/1e18:,.6f} ETH)` at block {e['block']} tx `{e['tx']}` — the only liquidity migration event of this portal.")
    lbe = collections.Counter(e["event"] for e in raw["contracts"]["ETHLockbox"]["events"])
    A(f"- ETHLockbox administrative events since birth: {dict(lbe)} (no `LockboxAuthorized`, `LiquidityMigrated`, `LiquidityReceived`).\n")
    A("## 5. Dispute infrastructure generations\n")
    A("| AnchorStateRegistry | Born | Version now | Games (index range) | Current? | ETH | respectedGameType / retirementTimestamp now |")
    A("|---|---|---|---|---|---|---|")
    for a in st2["asr"]:
        A(f"| `{a['address']}` | {a['bornBlock']} ({a['bornTime'][:10]}) | {a['version']} | {a['games']} ({a['firstGame']}..{a['lastGame']}) | {'yes' if a['isCurrent'] else 'orphaned'} | {a['ethBalance']/1e18:.4f} | {a['respectedGameType']} / {a['retirementTimestamp']} |")
    A("")
    A("| DelayedWETH | Born | Version | Games using it (range) | ETH balance | owner() | SystemConfig-registered? |")
    A("|---|---|---|---|---|---|---|")
    for a in st2["delayedWETH"]:
        A(f"| `{a['address']}` | {a['bornBlock']} ({a['bornTime'][:10]}) | {a['version']} | {a['games']} ({a['firstGame']}..{a['lastGame']}) | {a['ethBalance']:.6f} | `{a['owner']}` | {'yes' if a['isSystemConfigWeth'] else 'no (legacy)'} |")
    A("")
    A("Live ASR slot 6 history (`respectedGameType | retirementTimestamp | ethLockbox`), by storage bisection:\n")
    A("| L1 block | Date | respectedGameType | retirementTimestamp | raw |")
    A("|---|---|---|---|---|")
    for x in st2["asrSlot6History"]:
        A(f"| {x['block']} | {x['time'][:10]} | {x['respectedGameType']} | {x['retirementTimestamp']} | `{x['raw']}` |")
    A("")
    pe = [e for e in raw["contracts"]["OptimismPortal"]["events"] if e["event"].split("(")[0] in ("RespectedGameTypeSet", "Paused", "Unpaused", "DisputeGameBlacklisted")]
    A("Portal-era events (pre-U16 respected type lived in the portal): " + ("; ".join(f"{e['block']} ({d(bts(e['block']))[:10]}) {e['event'].split('(')[0]}({', '.join(str(int(t,16)) for t in e['topics'])}{' ' + e['data'][-40:] if len(e['data'])>2 else ''})" for e in pe) or "none") + ".\n")
    A("Game types ever registered (`ImplementationSet` on the DisputeGameFactory):\n")
    A("| L1 block | Date | Tx | type -> implementation |")
    A("|---|---|---|---|")
    bytx = collections.OrderedDict()
    for e in raw["contracts"]["DisputeGameFactory"]["events"]:
        if e["event"].startswith("ImplementationSet"):
            bytx.setdefault((e["block"], e["tx"]), []).append((int(e["topics"][1], 16), "0x" + e["topics"][0][-40:]))
    for (b, tx), v in bytx.items():
        A(f"| {b} | {d(bts(b))[:10]} | `{tx[:18]}` | " + ", ".join(f"{t}->{'unset' if int(i,16)==0 else '`'+i[:10]+'…`'}" for t, i in v) + " |")
    A("")
    A("Game census at the pinned block (lineage classes):\n")
    A("| type | game version | game's own ASR | DelayedWETH | absolutePrestate | n | index range | created | creators |")
    A("|---|---|---|---|---|---|---|---|---|")
    for x in state["gameCensus"]["lineageClasses"]:
        A(f"| {x['type']} | {x['gameVersion']} | `{short(x['gameASR'])}` | `{short(x['weth'])}` | `{short(x['absolutePrestate'])}` | {x['n']} | {x['firstIndex']}..{x['lastIndex']} | {x['firstCreated'][:10]}..{x['lastCreated'][:10]} | " +
          ", ".join(f"`{short(k)}`×{v}" for k, v in x["creators"].items()) + " |")
    A("")
    gc = state["gameCensus"]
    A(f"- Games: {gc['gameCount']}; retired (createdAt <= retirementTimestamp): {gc['retired']}; claim-valid: {gc['claimValid']}; blacklisted: {len(gc['blacklisted'])}; "
      f"non-retired games whose own ASR is not the live ASR: {len(gc['nonRetiredWithForeignASR'])}; in progress: {len(gc['inProgress'])}.")
    if ver:
        A(f"- Header-derived root check of every non-retired game: `{json.dumps(ver['table'])}`; anomalies: {len(state['rootVerification']['anomalies'])}.")
        for a in state["rootVerification"]["anomalies"]:
            A(f"  - index {a['index']} type {a['type']} `{a['game']}` creator `{a['creator']}` status {ST[a['status']]} claimValid {a['claimValid']} claimed `{a['claimedOutput']}` header-derived `{a['computedOutput']}`.")
    A("")
    A("## 6. Legacy slots at the pinned block\n")
    A("| Slot | Raw value |")
    A("|---|---|")
    for k, v in state["legacySlots"].items():
        A(f"| {k} | `{v}` |")
    A("")
    extra = f"chains/{chain}/HISTORY-notes.md"
    body = "\n".join(L)
    if os.path.exists(extra):
        body += "\n" + open(extra).read()
    open(f"chains/{chain}/HISTORY.md", "w").write(body)
    print(chain, "written", len(L), "lines; upgrades", len(path["upgrades"]), "F2 cross-check", path.get("crossCheckWithF2", {}).get("entriesChecked"), len(path.get("crossCheckWithF2", {}).get("mismatches", [])))

for ch in sys.argv[1:]:
    build(ch)
