#!/usr/bin/env python3
"""F5 (orchestrator request): exhaustive registry-binding check.
(a) per game: own anchorStateRegistry() vs the portal's current registry, for every game the current registry does not retire;
(b) per factory: every ImplementationSet / ImplementationArgsSet ever emitted, with the registry the implementation (immutable getter)
    or the gameArgs (CWIA args) binds to, flagged when registered at/after the retirement cut and bound to a different registry."""
import json, sys, datetime, collections
sys.path.insert(0, "scripts")
from F5_lib import *
d = lambda t: datetime.datetime.fromtimestamp(t, datetime.UTC).strftime('%Y-%m-%d %H:%M:%S')
ST = {0: "IN_PROGRESS", 1: "CHALLENGER_WINS", 2: "DEFENDER_WINS", None: "?"}
CENSUS = dict(OP="op-games-0-21388.json", INK="ink-games-0-2639.json", SONEIUM="soneium-games-0-8536.json", UNICHAIN="unichain-games-0-17690.json")
out = {}
for chain, c in CHAINS.items():
    asr = c["AnchorStateRegistry"].lower(); dgf = c["DisputeGameFactory"]
    portal_asr = as_addr(call(c["OptimismPortal"], "anchorStateRegistry()")).lower()
    assert portal_asr == asr
    retire = as_int(call(asr, "retirementTimestamp()"))
    games = json.load(open(f"evidence/F5/{CENSUS[chain]}"))
    count_onchain = as_int(call(dgf, "gameCount()"))
    nonret = [g for g in games if g["createdAt"] > retire]
    assert all((not g["retired"]) for g in nonret) and all(g["retired"] for g in games if g["createdAt"] <= retire)
    foreign = [g for g in nonret if (g["gameAsr"] or "").lower() != asr]
    noasr = [g for g in games if g["gameAsr"] is None]
    res = dict(currentRegistry=asr, retirementTimestamp=retire, retirementTime=d(retire), gameCountOnChain=count_onchain, gamesScanned=len(games),
               indexContiguous=[g["index"] for g in games] == list(range(len(games))),
               nonRetired=len(nonret), firstNonRetiredIndex=nonret[0]["index"] if nonret else None,
               nonRetiredBoundToCurrent=sum(1 for g in nonret if (g["gameAsr"] or "").lower() == asr),
               nonRetiredForeign=[dict(index=g["index"], game=g["game"], type=g["type"], creator=g["creator"], status=ST[g["status"]], claimValid=g["claimValid"], ownRegistry=g["gameAsr"]) for g in foreign],
               gamesWhoseRegistryGetterFailed=[g["index"] for g in noasr],
               registryOfRetiredGames=dict(collections.Counter(g["gameAsr"] for g in games if g["createdAt"] <= retire)),
               registryOfNonRetiredGames=dict(collections.Counter(g["gameAsr"] for g in nonret)),
               nonRetiredByTypeStatusClaimValid={f"type{k[0]}/{k[1]}/claimValid={k[2]}": n for k, n in sorted(collections.Counter((g["type"], ST[g["status"]], g["claimValid"]) for g in nonret).items())})
    # (b) implementation registrations
    raw = json.load(open(f"evidence/F5/{chain}-history-raw.json"))
    evs = [e for e in raw["contracts"]["DisputeGameFactory"]["events"] if e["event"].split("(")[0] in ("ImplementationSet", "ImplementationArgsSet")]
    regs = []; cache = {}
    def impl_asr(a):
        if a not in cache:
            cache[a] = (as_addr(call(a, "anchorStateRegistry()")), as_str(call(a, "version()")), as_addr(call(a, "weth()")))
        return cache[a]
    last_impl = {}
    for e in evs:
        ts = block_ts(e["block"])
        if e["event"].startswith("ImplementationSet"):
            gt = int(e["topics"][1], 16); impl = "0x" + e["topics"][0][-40:]
            last_impl[gt] = impl
            if int(impl, 16) == 0:
                regs.append(dict(block=e["block"], time=d(ts), tx=e["tx"], kind="ImplementationSet", gameType=gt, implementation=None, note="type unset", afterCut=ts >= retire))
                continue
            a, v, wv = impl_asr(impl)
            if a and int(a, 16) == 0:
                a = None  # CWIA implementation (FDG >= 2.2.0): bare impl reads empty args; registry comes from ImplementationArgsSet
            regs.append(dict(block=e["block"], time=d(ts), tx=e["tx"], kind="ImplementationSet", gameType=gt, implementation=impl, implVersion=v,
                             implImmutableRegistry=a, implImmutableWeth=wv, afterCut=ts >= retire,
                             boundToCurrent=(a.lower() == asr) if a else None))
        else:
            gt = int(e["topics"][0], 16)
            data = e["data"][2:]
            ln = int(data[64:128], 16); args = data[128:128 + 2 * ln]
            rec = dict(block=e["block"], time=d(ts), tx=e["tx"], kind="ImplementationArgsSet", gameType=gt, argsLength=ln, afterCut=ts >= retire)
            if ln == 0:
                rec["note"] = "empty args"
            elif ln == 40:      # super permissioned: asr(20) ++ proposer(20)
                rec.update(argsRegistry="0x" + args[0:40], proposer="0x" + args[40:80])
            elif ln in (124, 164):  # prestate(32) vm(20) asr(20) weth(20) l2ChainId(32) [proposer(20) challenger(20)]
                rec.update(prestate="0x" + args[0:64], vm="0x" + args[64:104], argsRegistry="0x" + args[104:144], weth="0x" + args[144:184], l2ChainId=int(args[184:248], 16))
                if ln == 164: rec.update(proposer="0x" + args[248:288], challenger="0x" + args[288:328])
            else:
                rec["rawArgs"] = "0x" + args
            if "argsRegistry" in rec: rec["boundToCurrent"] = rec["argsRegistry"].lower() == asr
            regs.append(rec)
    res["implementationRegistrations"] = regs
    bad = [r for r in regs if r["afterCut"] and r.get("boundToCurrent") is False]
    unk = [r for r in regs if r["afterCut"] and r["kind"] == "ImplementationSet" and r.get("implementation") and r.get("boundToCurrent") is None]
    # pair every after-cut args-based ImplementationSet with the ImplementationArgsSet of the same type in the same tx
    unpaired = []
    for r in unk:
        m = [x for x in regs if x["kind"] == "ImplementationArgsSet" and x["tx"] == r["tx"] and x["gameType"] == r["gameType"]]
        r["pairedArgsRegistry"] = m[-1].get("argsRegistry") if m else None
        r["pairedBoundToCurrent"] = m[-1].get("boundToCurrent") if m else None
        if not m or m[-1].get("boundToCurrent") is not True:
            unpaired.append(r)
    res["afterCutArgsBasedImplsNotPairedWithCurrentRegistryArgs"] = unpaired
    # implementation live for each type at the retirement cut (last ImplementationSet with ts < cut)
    live_at_cut = {}
    for e in evs:
        if e["event"].startswith("ImplementationSet") and block_ts(e["block"]) < retire:
            live_at_cut[int(e["topics"][1], 16)] = "0x" + e["topics"][0][-40:]
    res["implLiveJustBeforeCut"] = live_at_cut
    res["typesCreatedAfterCut"] = sorted({g["type"] for g in nonret})
    res["registrationsAfterCutBoundToOtherRegistry"] = bad
    res["registrationsAfterCutWithNoImmutableRegistry"] = unk  # CWIA-args implementations: registry comes from the args set in the same tx
    out[chain] = res
    print(f"\n== {chain}: registry {asr} retirement {retire} ({d(retire)}) games {len(games)}/{count_onchain} non-retired {len(nonret)} (first idx {res['firstNonRetiredIndex']}) "
          f"bound to current {res['nonRetiredBoundToCurrent']} FOREIGN {len(foreign)} getter-failed {len(noasr)}")
    print("   registry of retired games:", res["registryOfRetiredGames"])
    print("   non-retired by type/status/claimValid:", res["nonRetiredByTypeStatusClaimValid"])
    for r in regs:
        if not r["afterCut"]: continue
        if r["kind"] == "ImplementationSet":
            print(f"   {r['block']} {r['time'][:10]} ImplSet type {r['gameType']} impl {r.get('implementation')} v{r.get('implVersion')} immutableASR {r.get('implImmutableRegistry')} bound {r.get('boundToCurrent')}")
        elif r["argsLength"]:
            print(f"   {r['block']} {r['time'][:10]} ArgsSet type {r['gameType']} len {r['argsLength']} argsASR {r.get('argsRegistry')} bound {r.get('boundToCurrent')} weth {r.get('weth')} prestate {str(r.get('prestate'))[:14]}")
    print("   AFTER-CUT registrations bound to another registry:", len(bad), "| after-cut args-based impls:", len(unk),
          "| of which NOT paired with same-tx args bound to current:", len(unpaired), "| types created after cut:", res["typesCreatedAfterCut"])
json.dump(out, open("evidence/F5/registry-binding-check.json", "w"), indent=1)
