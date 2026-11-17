#!/usr/bin/env python3
"""F2 — render RELEASE-DAG.json and RELEASE-DAG.md from the hand-curated node data (F2_dag_data.py)
joined with the on-chain evidence files (evidence/F2-*.json). Read-only: no RPC calls here.

usage: python3 -I scripts/F2_build_dag.py   (run from anywhere; paths are resolved from this file)
"""
import json, os, re, sys, datetime

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
EV = os.path.join(ROOT, "evidence")
sys.path.insert(0, HERE)
import F2_dag_data as D  # noqa: E402

CHAINS = ["op-mainnet", "ink", "soneium", "unichain"]


def ev(name):
    return json.load(open(os.path.join(EV, name)))


def utc(ts):
    return datetime.datetime.fromtimestamp(ts, datetime.timezone.utc).strftime("%Y-%m-%d %H:%M:%S")


# ------------------------------------------------------------------ labels added on resume (chain-local nodes)
EXTRA_BLOCK_LABELS = {
    "unichain": {21116347: "GENESIS", 21116352: "GENESIS", 21116356: "GENESIS", 21116366: "GENESIS",
                 21116371: "GENESIS", 21116372: "GENESIS", 21116377: "GENESIS", 21645364: "CHAIN-FP-ENABLE"},
}
L2_BLOCK_LABELS = {"op-mainnet-L2": {105235063: "U1", 117387812: "U5", 122514212: "U9", 135603812: "U15",
                                     144546212: "U17", 153963812: "U19"}}
ALIASES = {"U11+U12": "U12"}  # Ink's ink-003 task carries Holocene games and the Pectra prestate together

CHAIN_LOCAL = [
    dict(id="GENESIS", order=None, title="Chain genesis of Ink / Soneium / Unichain (deployed post-MCP, fault-proof capable, permissioned at start)",
         classification="chain creation (no governance upgrade number)",
         execution={
             "op-mainnet": "n/a",
             "ink": [dict(what="Genesis on L1 block 21344310 (2024-12-06); portal 3.10.0-line, respected type 1; genesis PermissionedDisputeGame 0xa8e6a9bf... 1.3.1-beta.3, prestate 0x038512e0... (op-program 1.3.1), initBond(1) = 0", block=21344310, utc="2024-12-06", tx=None)],
             "soneium": [dict(what="Genesis on L1 block 21314185 (2024-12-02); respected type 1; genesis PermissionedDisputeGame 0x42d15f04... 1.3.1-beta.3, prestate 0x038512e0..., initBond(1) = 0; DGF/ProxyAdmin owner 0x5a0Aae59...; SystemConfig owner 0x509182eC... (unchanged through 26433900)", block=21314185, utc="2024-12-02 10:19:11", tx=None)],
             "unichain": [dict(what="Genesis deployment by 0xfff2f741... on L1 blocks 21116347..21116381 (2024-11-04 19:22..19:29); ProxyAdmin and DGF owner handed to Unichain's own 3-of-3 Safe 0x6d5B183F... at 21116378/21116381; respected type 1", block="21116347-21116381", utc="2024-11-04", tx=None),
                          dict(what="Genesis PermissionedDisputeGame 0xb2872ec9... version 1.3.0 registered with absolutePrestate 0x00000000deaddeaddeaddeaddeaddeaddeaddeaddeaddeaddeaddeaddeaddead (PLACEHOLDER, not a real op-program build); in force until 2025-01-17", block=21116377, utc="2024-11-04 19:28:47", tx=None)]},
         note="Ink, Soneium and Unichain never ran the OVM, L2OutputOracle, immutable-era (pre-MCP) code or the portal-local pause; they inherit U1..U10 as genesis state."),
    dict(id="CHAIN-FP-ENABLE", order=None, title="Permissionless proofs enabled on Ink and Unichain (respected type 1 -> 0)",
         classification="chain-local dispute-game change",
         execution={
             "op-mainnet": "n/a", "soneium": "never (Soneium stays permissioned through U21: type 1 until U20, then type 5)",
             "ink": [dict(what="ink-001: gameImpls(0) 0x6a8efcba... and (1) 0x0a780be3... (1.3.0, prestate 0x03c50b9f... = op-program '1.3.1-ink', a chain-specific build) registered", block=21618223, utc="2025-01-13 21:22:47", tx="0x71234ec9d3df32360383a0091277b0facbeb21456f1a29accb110fa43a6b5441"),
                     dict(what="respectedGameType 1 -> 0 by the Foundation Operations Safe 0x9BA6e03D... (execTransaction; superchain-ops ink-002 README still says 'READY TO SIGN')", block=21682329, utc="2025-01-22 20:10:35", tx="0x20fdc1a418ba706e35ade3a2bf1e4c9198c3c62e79d1b688fd951b900d065c27")],
             "unichain": [dict(what="gameImpls(0) 0x08f0f8f4... and (1) 0xc4571729... (1.3.1, prestate 0x0336751a... = op-program '1.4.0-unichain-mainnet', chain-specific) registered by Unichain's 3-of-3 0x6d5B183F...", block=21645364, utc="2025-01-17 16:20:11", tx="0xfcdc3edd3631f3b4119ffa84b961c192530a084ff131f1eff895207469a9b210"),
                          dict(what="respectedGameType 1 -> 0 by the Foundation Operations Safe 0x9BA6e03D...", block=21689135, utc="2025-01-23 18:58:23", tx="0xc378e44280c522d56a179fee89ec50e6561eaf3a8a7857e4ae5c3a44ed879c43")]},
         note="Both chains used chain-specific absolute prestates (registry names '1.3.1-ink', '1.4.0-unichain-mainnet', validation/standard/standard-prestates.toml lines 292-294 and 264-266 at superchain-registry edd89bd1) until U12/U13 brought them onto the shared prestate 0x039facea..."),
]

# ------------------------------------------------------------------ facts added on resume (each read on chain this session)
SUPPLEMENT = {
    "U16": dict(storage_headline=[
        "VERIFIED (cast balance, L1 archive): OP Mainnet portal 236,752.243071584240518225 ETH @22990598 -> 0 @22990599, lockbox 0x322b47Ff... 0 -> 236,752.243071584240518225; "
        "Ink portal 6,020.610509607786200086 -> 0, lockbox 0xbd4AbB32... 0 -> same (same blocks); Soneium portal 8,877.050938229307093797 @22990669 -> 0 @22990670, lockbox 0x67B4de6F...; "
        "Unichain portal 133,613.248268096507106891 @22990721 -> 0 @22990722, lockbox 0x08bA0023...",
        "Lockbox balances at U21 block 26430859 (portals 0 on all four): OP 182,420.5112 ETH, Ink 23,088.7583, Soneium 2,195.5602, Unichain 18,222.3470"]),
    "MAINT-UNI-PAO": dict(roles=[
        "Ink SystemConfig owner 0xbea2bc85... -> 0x9BA6e03D... (Foundation Operations Safe) at L1 block 25573527 (2026-07-20 11:08:11, tx 0x2289375872de4969cb0f03afa95fa69b7d18d09be626c2b86cff2627ca223a47; no superchain-ops task — executed by Ink's previous owner), then -> 0x847B5c17... at 065",
        "Unichain SystemConfig owner 0x9245d5d1... -> 0x847B5c17... (Foundation Upgrade Safe) at L1 block 26286838 (" + utc(1793137691) + ", tx 0x5453bf98652454cf24e71336c615d4677128a0eb66e111e4bb055051339b5aef; no superchain-ops task), six weeks after the ProxyAdmin transfer and 3 weeks before U21",
        "Soneium SystemConfig owner is still 0x509182eC... at 26433900 (the only one of the four chains whose SystemConfig owner is chain-operated)"]),
    "U21": dict(skipped_alternate=[
        "superchain-ops 083-op-mainnet-proposer-rotation, 082-op-mainnet-set-batcher and 089-op-mainnet-set-unsafe-signer are CANCELLED; the OP Mainnet proposer rotation was folded into the U21 transaction (gameArgs(5))"]),
    "U8": dict(skipped_alternate=[
        "The SuperchainConfig implementation swap (impl -> StorageSetter -> same impl) happened inside one transaction, so the EIP-1967 sampled history shows no change at 20063224; it is visible only in evidence/F2-superchainconfig-logs.json (Upgraded + Initialized events)"]),
    "U12": dict(dispute=["Ink reached 0x039facea... from its chain-specific '1.3.1-ink' prestate 0x03c50b9f... in one task (ink-003), skipping the Holocene prestate 0x03f89406... that OP Mainnet used"]),
    "U13": dict(dispute=["Unichain moves from its chain-specific prestate 0x0336751a... ('1.4.0-unichain-mainnet') to 0x039facea... at its own task 002 (block 22254924)"]),
}


def resolve_audits(node, index, tagmap):
    out = []
    for s in node.get("audits") or []:
        for m in re.finditer(r"(\d{4}-\d{2}) ([^—;()]+?) — ", s):
            date, rev = m.group(1), m.group(2).strip()
            cand = [r for r in index if r["date"] == date and r["reviewer"].split()[0].lower() == rev.split()[0].lower()]
            if not cand:
                out.append(dict(date=date, reviewer=rev, match=None))
                continue
            for r in cand:
                c = re.sub(r"^\[|\].*$", "", r["commit"]) if r["commit"] else ""
                out.append(dict(date=r["date"], reviewer=r["reviewer"], title=r["scope"], audited_commit=c or None,
                                subsequent_release=r["release"] or None, commit_tags=tagmap.get(c[:10].lower(), []) if c else []))
    # de-duplicate
    seen, res = set(), []
    for a in out:
        k = (a.get("date"), a.get("reviewer"), a.get("title"))
        if k not in seen:
            seen.add(k); res.append(a)
    return res


def exec_status(x):
    if isinstance(x, list):
        return "executed"
    s = (x or "").lower()
    if s.startswith("same transaction") or s.startswith("same l1 transaction") or s.startswith("same timestamp") or s.startswith("same "):
        return "executed (shared tx/timestamp)"
    if "not executed" in s or s.startswith("never"):
        return "skipped"
    if "different" in s:
        return "executed (different path)"
    if "genesis" in s:
        return "genesis-inherited"
    if s.startswith("via "):
        return "folded into later node"
    if "no dedicated" in s:
        return "no L1 transaction"
    if s.startswith("n/a") or "not affected" in s:
        return "n/a"
    return "see text"


def first_exec(x):
    if isinstance(x, list):
        for e in x:
            if e.get("block") is not None or e.get("tx"):
                return e
    return None


def main():
    index = ev("F2-audit-index.json")
    tagmap = {}
    for ln in open(os.path.join(EV, "F2-op-contracts-tags.txt")):
        p = ln.split()
        if len(p) == 2:
            tagmap.setdefault(p[0][:10].lower(), []).append(p[1].replace("refs/tags/", "").replace("^{}", ""))
    labels = {c: dict(D.BLOCK_TO_NODE.get(c, {})) for c in CHAINS}
    for c, m in EXTRA_BLOCK_LABELS.items():
        labels[c].update(m)

    nodes = [dict(n) for n in D.NODES] + [dict(n) for n in CHAIN_LOCAL]
    byid = {n["id"]: n for n in nodes}
    for nid, extra in SUPPLEMENT.items():
        for k, v in extra.items():
            byid[nid][k] = list(byid[nid].get(k) or []) + ["[resume] " + x for x in v]
    for n in nodes:
        n["audits_index"] = resolve_audits(n, index, tagmap)
        n["impl_changes"] = {c: [] for c in CHAINS}
        n["game_impls"] = {c: [] for c in CHAINS}
        n["exec_status"] = {c: exec_status((n.get("execution") or {}).get(c)) for c in CHAINS}

    # implementation histories
    files = {"op-mainnet": ["F2-impl-history-op-mainnet.json", "F2-impl-history-op-mainnet-legacy-dispute-proxies.json"],
             "ink": ["F2-impl-history-ink.json"], "soneium": ["F2-impl-history-soneium.json"], "unichain": ["F2-impl-history-unichain.json"]}
    timelines = {c: {} for c in CHAINS}
    unlabeled = []
    for c, fs in files.items():
        for f in fs:
            for t in ev(f)["targets"]:
                prev = None
                tl = []
                for h in t["history"]:
                    lab = ALIASES.get(labels[c].get(h["block"]), labels[c].get(h["block"]))
                    row = dict(contract=t["name"], address=t["address"], block=h["block"], utc=h["utc"],
                               implementation=h["implementation"], version=h.get("version"), from_version=prev, node=lab,
                               txs=[x["hash"] for x in h.get("txs_with_logs_from_target", [])][:3])
                    prev = h.get("version")
                    tl.append(row)
                    if lab in byid:
                        byid[lab]["impl_changes"][c].append(row)
                    else:
                        unlabeled.append(row)
                timelines[c][t["name"]] = tl
    l2 = []
    for t in ev("F2-impl-history-op-mainnet-L2-predeploys.json")["targets"]:
        prev = None
        for h in t["history"]:
            l2.append(dict(contract=t["name"], address=t["address"], l2_block=h["block"], utc=h["utc"], version=h.get("version"),
                           from_version=prev, node=L2_BLOCK_LABELS["op-mainnet-L2"].get(h["block"])))
            prev = h.get("version")

    games = {}
    for c in CHAINS:
        rows = ev(f"F2-game-impls-{c}.json")["implementations"]
        games[c] = []
        for r in rows:
            ga = r.get("gameArgs_decoded") or {}
            pre = r.get("absolutePrestate")
            if not pre or int(pre, 16) == 0:
                pre = ga.get("absolutePrestate")
            lab = ALIASES.get(labels[c].get(r["registered_block"]), labels[c].get(r["registered_block"]))
            g = dict(game_type=r["game_type"], implementation=r["implementation"], version=r.get("version"),
                     registered_block=r["registered_block"], registered_utc=r["registered_utc"],
                     replaced_block=r["replaced_block"], replaced_utc=r["replaced_utc"], absolute_prestate=pre,
                     prestate_source="gameArgs" if ga and (not r.get("absolutePrestate") or int(r["absolutePrestate"], 16) == 0) else "implementation",
                     weth=r.get("weth") if r.get("weth") and int(r["weth"], 16) else ga.get("weth"),
                     anchor_state_registry=r.get("anchorStateRegistry") if r.get("anchorStateRegistry") and int(r["anchorStateRegistry"], 16) else ga.get("anchorStateRegistry"),
                     proposer=r.get("proposer") or ga.get("proposer"), init_bond_wei=r.get("dgf_initBond_wei"), node=lab)
            games[c].append(g)
            if lab in byid:
                byid[lab]["game_impls"][c].append(g)

    # per-chain ordered path through the DAG
    order = {n["id"]: (n["order"] if n.get("order") is not None else -1) for n in nodes}
    paths = {}
    for c in CHAINS:
        seq = []
        for n in nodes:
            st = n["exec_status"][c]
            e = first_exec((n.get("execution") or {}).get(c))
            blk = e.get("block") if e else None
            if isinstance(blk, str):
                blk = int(re.match(r"\d+", blk).group(0))
            if st in ("n/a",):
                continue
            seq.append(dict(node=n["id"], status=st, first_l1_block=blk))
        # sort: executed nodes by block where known; others by DAG order
        def key(x):
            n = byid[x["node"]]
            if x["node"] == "GENESIS":
                return (21000000, 0)
            if x["node"] == "CHAIN-FP-ENABLE":
                return (21618223, 0)
            return (x["first_l1_block"] or 0, order[x["node"]]) if x["first_l1_block"] else (0, order[x["node"]])
        paths[c] = sorted(seq, key=lambda x: (order[x["node"]] if x["node"] not in ("GENESIS", "CHAIN-FP-ENABLE") else (10.5 if x["node"] == "GENESIS" else 15.5)))

    edges = []
    main_ids = [n["id"] for n in sorted(D.NODES, key=lambda n: n["order"])]
    for a, b in zip(main_ids, main_ids[1:]):
        edges.append(dict(src=a, dst=b, kind="sequence (OP Mainnet chronological order of execution/activation)"))
    edges += [
        dict(src="U10", dst="GENESIS", kind="branch: Ink/Soneium/Unichain are created with the U1..U10 state as genesis"),
        dict(src="GENESIS", dst="CHAIN-FP-ENABLE", kind="Ink, Unichain only"),
        dict(src="CHAIN-FP-ENABLE", dst="U12", kind="Ink: ink-003"), dict(src="CHAIN-FP-ENABLE", dst="U13", kind="Unichain: 002"),
        dict(src="GENESIS", dst="U11", kind="Soneium (task 030) and Unichain (unichain-001) SystemConfig 2.3.0; Ink SKIPS this edge"),
        dict(src="U14", dst="U16", kind="Soneium skips U15a (prestate 0x03ee2917... kept across Isthmus)"),
        dict(src="U15", dst="U16a", kind="alternate entry: chains that skipped U16 (Base, Zora, Metal, Mode, Arena-Z, Swell); none of the four chains"),
        dict(src="MAINT-UNI-PAO", dst="U20", kind="Unichain joins the single-transaction upgrade path"),
    ]
    lineage = LINEAGE

    out = dict(
        generated_by="scripts/F2_build_dag.py (F2, Track A, resumed on Opus 5.5 at the user's explicit instruction relayed by the orchestrator)",
        sources=dict(node_data="scripts/F2_dag_data.py", audit_index=D.AUDIT_INDEX_NOTE,
                     evidence=sorted(f for f in os.listdir(EV) if f.startswith("F2-"))),
        chains=CHAINS, nodes=nodes, edges=edges, lineage_edges=lineage, per_chain_paths=paths,
        implementation_timelines=timelines, op_mainnet_l2_predeploys=l2, game_implementations=games,
        unlabeled_impl_changes=unlabeled)
    json.dump(out, open(os.path.join(ROOT, "RELEASE-DAG.json"), "w"), indent=1)
    open(os.path.join(ROOT, "RELEASE-DAG.md"), "w").write(render_md(out, byid))
    print("nodes", len(nodes), "edges", len(edges), "lineage", len(lineage), "unlabeled", len(unlabeled))


# ------------------------------------------------------------------ create / transform / consume edges
LINEAGE = [
    dict(id="L01", object="L1CrossDomainMessenger / L1StandardBridge proxy slot 0 (OVM-era contents)",
         create="OVM (AddressManager-resolved L1CDM: abi.encodePacked(initialized, libAddressManager); L1StandardBridge: legacy `messenger`)",
         transform="U4 (slot 0 rewritten in the upgrade tx so OZ `initializer` can run: L1CDM keeps byte 20 = 1, address zeroed; bridge slot 0 = 0x01)",
         consume="U16 (ReinitializableBase: reinitializer(2) reads the same `_initialized` byte) and every OPCM upgrade from U17 on (StorageSetter reset + initVersion 3)",
         chains="op-mainnet only (other chains have clean slot 0)", evidence="OVM, U4, U16, U17 nodes; OPS-OLD 004 Validation.md"),
    dict(id="L02", object="OptimismPortal slot 53 (`paused` byte + packed superchainConfig)",
         create="U1 (portal-local `paused` bool)", transform="PAUSE-2024-02 (set and cleared) then U4 (superchainConfig packed after the byte)",
         consume="U16+ (pause resolved through SystemConfig -> SuperchainConfig; the old byte/slot is a spacer that must stay zero)",
         chains="op-mainnet only", evidence="PAUSE-2024-02, U4, U16; evidence/F2-op-portal-{paused,unpaused}-logs.json"),
    dict(id="L03", object="respectedGameTypeUpdatedAt (proof-freshness lower bound)",
         create="U7 (0x66672d13)", transform="INC-2024-08 / U10 (bumped twice); U13 stops bumping it on setRespectedGameType",
         consume="U16 (getter now returns ASR.retirementTimestamp = 0x688271ab on OP Mainnet; all earlier games retired)",
         chains="all four (Ink/Soneium/Unichain from genesis values 0x6753162b / 0x674d899f / 0x67291fbb)", evidence="CALL(*) portal.respectedGameTypeUpdatedAt()"),
    dict(id="L04", object="per-game `wasRespectedGameTypeWhenCreated` flag",
         create="U13 (games >= 1.4.1; pre-U13 games lack the getter -> treated as not respected = invalidation)",
         transform="U19 (respected 0 -> 8, gameImpls(0) cleared; type-0 games created before stay provable)",
         consume="U20/U21 portals (5.8.0/6.1.0) proving against still-claim-valid type-0/type-8 output-root games created after the U16 retirement, via rootClaimByChainId dispatch by game type (added U19)",
         chains="op-mainnet, ink, unichain (Soneium: type 1 -> 5)", evidence="U13, U19, U20 nodes; GAMES(*)"),
    dict(id="L05", object="AnchorStateRegistry gen3 anchor (unit of l2SequenceNumber)",
         create="U16 (gen3 proxy, anchor = output root at an L2 block number)", transform="U20 (anchor replaced by a super root at an L2 TIMESTAMP; OP Mainnet L2 block 156622039 / ts 1788842855)",
         consume="U21 (ASR 4.0.0 reads the same anchor; output-root games of types 0/8 created between U16 and U20 still resolve against the ASR)",
         chains="all four", evidence="U16, U20, U21 nodes; IMPL(*) AnchorStateRegistry(current)"),
    dict(id="L06", object="ETH custody",
         create="U1 (portal holds ETH) / genesis for the other chains", transform="U16 (100% moved portal -> ETHLockbox in the upgrade tx; balances verified)",
         consume="U16a (SystemConfig ETH_LOCKBOX feature flag set because a lockbox already exists) and U21 (ETHLockbox 2.0.0; OPContractsManagerV2.migrate prepared but not executed)",
         chains="all four (chains that skipped U16 get no lockbox until later)", evidence="U16, U16a, U21 nodes; cast balance reads"),
    dict(id="L07", object="DelayedWETH generations (bond custody per game)",
         create="U7 gen1 0xE497B094... (1.0.0, shared, owned)", transform="U10 gen2, U11 gen3 (new proxies; gen1/gen2 left at old implementations, still hold credit for their games); U13 gen3 upgraded in place to 1.3.0 and owner -> PAO",
         consume="U16 gen4 (ownerless), U16a gen5, U19 one shared proxy 0x1b6dbf05... for all types, U21 DelayedWETH 2.0.0 — old generations are residue that old games still withdraw from",
         chains="op-mainnet (Ink/Unichain have their own generations from CHAIN-FP-ENABLE)", evidence="evidence/F2-impl-history-op-mainnet-legacy-dispute-proxies.json; GAMES(*) weth column"),
    dict(id="L08", object="SystemConfig address slots incl. batchInbox",
         create="U6 (immutables moved to storage)", transform="U19 (batchInbox recomputed for pre-OPCM chains)",
         consume="U20 (legacy batchInbox slot cleared, batchInbox() removed; overhead zeroed)", chains="op-mainnet (pre-OPCM chain)", evidence="U6, U19, U20 nodes"),
    dict(id="L09", object="SystemConfig fee scalars (basefeeScalar/blobbasefeeScalar)",
         create="U5 (Ecotone versioned `scalar` encoding)", transform="U11 (2.3.0 re-initialize populates the packed scalars; OP Mainnet 5227/1014213) — SKIPPED on Ink (2.2.0 -> 2.4.0 at U13)",
         consume="U14 (operator fee), U17 (minBaseFee/daFootprintGasScalar packed), consumed by op-node/L1Block derivation",
         chains="all; Ink path differs", evidence="U11 node; IMPL(ink) SystemConfig. Whether Ink's packed scalars were ever initialised is NOT established here (F4 storage read)"),
    dict(id="L10", object="DGF gameArgs (creator-pattern per-chain parameters: prestate | vm | asr | weth | l2ChainId [| proposer | challenger])",
         create="U18", transform="U19 (type 1 re-registered with placeholder prestate 0xdead0000...; type 8 prestate rotated) and single-chain proposer rotations (Arena-Z 048, Ink 061, Unichain 078)",
         consume="U20 (types 1/8 cleared; type 5 gameArgs = asr | proposer) and U21 (OP Mainnet gameArgs(5) proposer rotated, type 9 prestate rotated)",
         chains="all four", evidence="ARGS(*), GAMES(*)"),
    dict(id="L11", object="SuperchainConfig pause / guardian authority",
         create="U4 (global pause, guardian 0x9BA6e03D...)", transform="U8 (guardian -> Guardian Safe 0x09f7150D..., DeputyGuardianModule), U13 (DeputyPauseModule; mainnet pause test 2025-05-14)",
         consume="U16 (per-identifier pause with expiry, read via SystemConfig; DGM removed) and U21 (lockbox is the only chain-scoped pause identifier)",
         chains="shared object 0x95703e09... for all four", evidence="evidence/F2-superchainconfig-logs.json; U4, U8, U13, U16, U21"),
    dict(id="L12", object="OP Mainnet L2 bridge predeploys (L2ToL1MessagePasser, L2CrossDomainMessenger, L2StandardBridge) storage",
         create="U1 (Bedrock genesis implementations 1.0.0 / 1.4.0 / 1.1.0 incl. migrated legacy storage)",
         transform="U15 (Isthmus: header withdrawalsRoot = message-passer storage root, read by output roots; no code change)",
         consume="U19 (Karst L2CM: first implementation change in three years, 1.0.0 -> 1.2.0 / 1.4.0 -> 2.2.1 / 1.1.0 -> 1.13.2) and U20 super roots built from those output roots",
         chains="op-mainnet (Ink/Soneium/Unichain L2 histories not read: no local L2 proxy)", evidence="evidence/F2-impl-history-op-mainnet-L2-predeploys.json"),
]


def fmt_exec(x):
    if isinstance(x, list):
        return "<br>".join(f"{e.get('what')} — L1 block {e.get('block')}, {e.get('utc')}, tx {e.get('tx')}" for e in x)
    return str(x)


def short_exec(x):
    if isinstance(x, list):
        e = first_exec(x) or x[0]
        t = e.get("tx") or "-"
        if isinstance(t, str) and len(t) > 14 and " " not in t:
            t = t[:12] + "…"
        return f"{e.get('block')} ({(e.get('utc') or '')[:10]}) {t}"
    s = str(x)
    return s if len(s) < 70 else s[:67] + "…"


def render_md(o, byid):
    L = []
    w = L.append
    w("# RELEASE-DAG — OP Stack L1/L2 release lineage, OVM residue -> Bedrock (U1) -> Upgrade 21\n")
    w("Worker F2 (Track A, blind). Generated by `scripts/F2_build_dag.py` from `scripts/F2_dag_data.py` + `evidence/F2-*.json`; machine-readable twin: `RELEASE-DAG.json`.")
    w("All on-chain facts were read from the local L1 archive proxy `http://127.0.0.1:7545` (OP Mainnet L2: `:7546`) by bisected sampling (step 20,000 L1 / 200,000 L2 blocks), with the exact change block found by bisection. "
      "Model note: this resume ran on Opus 5.5 at the user's explicit instruction (relayed by the orchestrator) after the Mythos 5.2 quota was exhausted.\n")
    w("Audit titles/commits: " + D.AUDIT_INDEX_NOTE + "\n")
    w("## 1. Node summary (chronological on OP Mainnet)\n")
    w("| # | Node | Proposal | Class | op-contracts tag @ commit | OP Mainnet L1 execution | Ink | Soneium | Unichain |")
    w("|---|---|---|---|---|---|---|---|---|")
    for n in sorted([n for n in o["nodes"] if n.get("order") is not None], key=lambda n: n["order"]):
        r = n.get("release") or {}
        tag = f"{r.get('tag') or '—'} @ `{(r.get('commit') or '—')[:12]}`" if r.get("tag") else ("— " + (f"(`{r.get('commit')[:12]}`)" if r.get("commit") else ""))
        ex = n.get("execution") or {}
        w(f"| {n['order']} | **{n['id']}** {n['title'][:60]} | {(n.get('proposal') or {}).get('number') or '—'} | {n.get('classification','')[:40]} | {tag} | {short_exec(ex.get('op-mainnet'))} | "
          f"{n['exec_status']['ink']} | {n['exec_status']['soneium']} | {n['exec_status']['unichain']} |")
    w("\nChain-local nodes (not on OP Mainnet): **GENESIS** (Ink 2024-12-06, Soneium 2024-12-02, Unichain 2024-11-04) and **CHAIN-FP-ENABLE** (Ink 2025-01-13/22, Unichain 2025-01-17/23). Details in section 4.\n")

    w("## 2. DAG\n")
    w("```mermaid\nflowchart TD")
    for e in o["edges"]:
        w(f"  {e['src'].replace('.', '_').replace('-', '_')} --> {e['dst'].replace('.', '_').replace('-', '_')}")
    w("```\n")
    w("Edges other than the OP Mainnet chronological sequence:\n")
    for e in o["edges"]:
        if not e["kind"].startswith("sequence"):
            w(f"- {e['src']} -> {e['dst']}: {e['kind']}")
    w("")

    w("## 3. Per-chain path\n")
    for c in CHAINS:
        w(f"**{c}**: " + " -> ".join(f"{p['node']}" + ("" if p["status"].startswith("executed") else f" [{p['status']}]") for p in o["per_chain_paths"][c]) + "\n")

    w("## 4. Nodes in detail\n")
    allnodes = sorted([n for n in o["nodes"] if n.get("order") is not None], key=lambda n: n["order"]) + [n for n in o["nodes"] if n.get("order") is None]
    for n in allnodes:
        w(f"### {n['id']} — {n['title']}\n")
        p = n.get("proposal") or {}
        if p:
            w(f"- **Proposal**: {p.get('number') or '—'} — {p.get('name')} {('(' + p['url'] + ')') if p.get('url') else ''}")
        w(f"- **Classification**: {n.get('classification')}")
        r = n.get("release") or {}
        if r:
            w(f"- **Release**: tag `{r.get('tag')}`, commit `{r.get('commit')}`. {r.get('notes') or ''}")
        w("- **Execution**:")
        for c in CHAINS:
            w(f"  - {c} [{n['exec_status'][c]}]: {fmt_exec((n.get('execution') or {}).get(c))}")
        for c, v in (n.get("execution") or {}).items():
            if c not in CHAINS:
                w(f"  - {c}: {fmt_exec(v)}")
        for key, lab in [("chain_set", "Chain set"), ("changed_l1", "Changed L1 contracts"), ("changed_l2_clients", "Changed L2 / clients"),
                         ("initializers", "Initializer calls"), ("storage_headline", "Headline storage changes"), ("roles", "Role changes"),
                         ("dispute", "Dispute game / prestate"), ("invalidated", "Proofs / messages invalidated"), ("skipped_alternate", "Skipped / alternate paths")]:
            v = n.get(key)
            if v:
                w(f"- **{lab}**:" + ("".join(f"\n  - {x}" for x in v) if isinstance(v, list) else f" {v}"))
        if n.get("note"):
            w(f"- **Note**: {n['note']}")
        ic = [x for c in CHAINS for x in n["impl_changes"][c] if x["version"] != x["from_version"] or x["from_version"] is None]
        if any(n["impl_changes"][c] for c in CHAINS):
            w("- **Implementation changes (on-chain, EIP-1967 / AddressManager)**:")
            for c in CHAINS:
                rows = n["impl_changes"][c]
                if rows:
                    w(f"  - {c}: " + "; ".join(f"{x['contract']} {x['from_version'] or '∅'} -> {x['version'] or '∅'} (`{x['implementation'][:10]}`, blk {x['block']})" for x in rows))
        if any(n["game_impls"][c] for c in CHAINS):
            w("- **Game implementations registered (DGF.gameImpls)**:")
            for c in CHAINS:
                rows = n["game_impls"][c]
                if rows:
                    w(f"  - {c}: " + "; ".join(f"type {g['game_type']} `{g['implementation'][:10]}` v{g['version']} prestate `{(g['absolute_prestate'] or 'n/a')[:10]}` blk {g['registered_block']}" for g in rows))
        a = n.get("audits_index")
        if a:
            w("- **Audit index rows (title / audited commit / tags at that commit / 'Subsequent Release')**:")
            for x in a:
                if x.get("title"):
                    w(f"  - {x['date']} {x['reviewer']} — {x['title']} / `{x['audited_commit'] or '—'}` / {', '.join(x['commit_tags']) or 'no op-contracts tag'} / {x['subsequent_release'] or '—'}")
                else:
                    w(f"  - {x['date']} {x['reviewer']} — (no matching index row)")
        elif n.get("audits"):
            w("- **Audits**: " + "; ".join(n["audits"]))
        if n.get("cannot_matter"):
            w(f"- **Cannot-matter verdict**: {n['cannot_matter']}")
        w(f"- **Evidence**: {'; '.join(n.get('evidence') or [])}\n")

    w("## 5. Implementation version timelines\n")
    for c in CHAINS:
        w(f"### {c}\n")
        w("| Contract | versions (L1 block) |\n|---|---|")
        for name, tl in o["implementation_timelines"][c].items():
            w(f"| {name} | " + " → ".join(f"{x['version'] or '∅'} ({x['block']}{'/' + x['node'] if x['node'] else ''})" for x in tl) + " |")
        w("")
    w("### OP Mainnet L2 predeploys (L2 block)\n")
    w("| Predeploy | versions |\n|---|---|")
    by = {}
    for x in o["op_mainnet_l2_predeploys"]:
        by.setdefault(x["contract"], []).append(x)
    for k, v in by.items():
        w(f"| {k} | " + " → ".join(f"{x['version'] or '∅'} ({x['l2_block']}{'/' + x['node'] if x['node'] else ''})" for x in v) + " |")
    w("")

    w("## 6. Dispute-game implementations and absolute prestates\n")
    for c in CHAINS:
        w(f"### {c}\n")
        w("| type | impl | version | registered (node) | replaced | prestate | source | weth | ASR | initBond |\n|---|---|---|---|---|---|---|---|---|---|")
        for g in o["game_implementations"][c]:
            w(f"| {g['game_type']} | `{g['implementation'][:10]}` | {g['version']} | {g['registered_utc'][:10]} ({g['node']}) | {(g['replaced_utc'] or '—')[:10]} | `{(g['absolute_prestate'] or '—')[:18]}` | {g['prestate_source']} | `{(g['weth'] or '—')[:10]}` | `{(g['anchor_state_registry'] or '—')[:10]}` | {g['init_bond_wei']} |")
        w("")

    w("## 7. Global proof-invalidation boundaries\n")
    w("| When | Node | Mechanism | Chains |\n|---|---|---|---|")
    w("| 2024-06-10 16:42:59 | U7 | OptimismPortal2 cannot read L2OutputOracle proofs | op-mainnet |")
    w("| 2024-08-16 18:35:59 | INC-2024-08 | respected type 0 -> 1, updatedAt bumped | op-mainnet |")
    w("| 2024-09-11 16:08:35 | U10 (019) | respected type 1 -> 0, updatedAt bumped | op-mainnet |")
    w("| 2025-01-22 / 2025-01-23 | CHAIN-FP-ENABLE | respected 1 -> 0, updatedAt bumped | ink / unichain |")
    w("| 2025-04-02 (OP/Ink/Soneium), 2025-04-12 (Unichain) | U13 | pre-1.4.1 games lack wasRespectedGameTypeWhenCreated | all four |")
    w("| 2025-07-24 17:47:23 (OP/Ink), 18:01:35 (Soneium), 18:12:11 (Unichain) | U16 | ASR gen3 retirementTimestamp | all four |")
    w("\nNo invalidation after U16 (U16a, U17-U21 state none; U19/U20 respected-type switches are per-game). Every game that can be claim-valid today was created after the U16 retirement timestamp of its chain.\n")

    w("## 8. Create-at-N / transform-at-N+1 / consume-at-N+2 edges\n")
    for e in o["lineage_edges"]:
        w(f"- **{e['id']} {e['object']}** — create: {e['create']}; transform: {e['transform']}; consume: {e['consume']}. Chains: {e['chains']}. Evidence: {e['evidence']}")
    w("")

    w("## 9. Other maintenance executions (not upgrade nodes)\n")
    w("Superchain-ops executions that change configuration of the four chains but are not numbered upgrades (from `evidence/F2-superchain-ops-tasks.json`):\n")
    w("- OP Mainnet gas: 008 (22432131, 2025-05-07), 013 (22539537, 2025-05-22, 40M), 020 (21023675, 60M), 055 (25488918, Karst re-emit).")
    w("- Deputy pause key rotation 052 (25080490, 2026-05-12); SaferSafes enable 038/039 (24292298/24292330, 2026-01-22); Foundation Safe signer rotations 030/031, 043/044, 050/051, 056-059, 074/075.")
    w("- Ink: 060 batcher/unsafe signer (25631821), 061 proposer rotation (25674914), 062 fee-vault recipient (25674961), 065 SystemConfig owner -> FUS (25834840), 073 gas limit (26083470).")
    w("- Soneium: 072 fee-vault recipient (26077684); 085-088 READY TO SIGN / contingency (not executed by 26433900).")
    w("- Unichain: 069/070 ownership (MAINT-UNI-PAO), 076/079 L1 splitter, 077 batcher/unsafe signer (26299498), 078 proposer rotation (26299517), 080 operator fee vault (26299707).")
    w("- Cancelled: 005-3, 006, 014, 037, 046, 047, 066, 082, 083, 089. Draft/not executed: 031-op-mainnet-pectra-defense, ink-002 (superseded by an FOS transaction, see CHAIN-FP-ENABLE).\n")

    w("## 10. Where the conceptual lineage was wrong or incomplete\n")
    for x in CORRECTIONS:
        w(f"- {x}")
    w("")
    w("## 11. Limits\n")
    for x in LIMITS:
        w(f"- {x}")
    w("")
    return "\n".join(L)


CORRECTIONS = [
    "Missing nodes: op-contracts/v1.1.0 (tag only; ProtocolVersions is its sole footprint, no OP Mainnet proxy ever pointed at a v1.1.0 implementation), Security Council Phase 0 (ProxyAdmin owner -> 0x5a0Aae59... on 2024-02-09, BEFORE U4), the 2024-02-15 portal pause rehearsal, the 2024-08-16 permissioned fallback (INC-2024-08), chain GENESIS of Ink/Soneium/Unichain, CHAIN-FP-ENABLE on Ink/Unichain, and the 2026-09-14 Unichain ProxyAdmin transfer (MAINT-UNI-PAO).",
    "Tag order != commit order != execution order: v1.2.0 (U4) commit 856c08bf is dated 2024-01-24, AFTER v1.3.0 (U6) commit e6ef3a90 of 2024-01-22; maintenance tags v2.1.0/v2.2.0 (2025-08) and v3.0.1 (2025-09) post-date v3.0.0/v4.0.0/v4.1.0; v6.0.0 and v7.0.0 annotated tags were created after (v6, +5 weeks) or on (v7) the execution day; op-contracts/v8.0.0-rc.1 points at the same commit as v7.0.0-rc.1/rc.2.",
    "No v1.7.0 release (only a typo-named L2-genesis tag) and v1.9.0 only as rc; v1.5.0 = U8, but only its Safe modules reached mainnet (its OptimismPortal 2.8.0 line was never deployed on the four chains); v1.6.0 (U10) deployed only dispute contracts.",
    "U2 Canyon, U3 Delta, U5 Ecotone, U9 Fjord, U12 and U15 Isthmus have no op-contracts release; U9/U10/U11 carry the 'hardfork => new prestate => new game implementations' pattern on L1.",
    "U12 'L1 Pectra readiness' has NO OP Mainnet L1 transaction (task 031 stayed DRAFT); its prestate 0x039facea... first appears on OP Mainnet with U13. Only Ink executed a U12 step (ink-003, Holocene + Pectra games in one task).",
    "U13 'deputy pause': DeputyPauseModule was enabled on the Foundation Operations Safe five weeks after U13 (task 011, 2025-05-07) and moved to the Guardian Safe (2.1.0) only at U16; U13 itself also removed CGT v1, added a new ASR per chain and unified the anchor.",
    "U8 and U7 executed the same day; U7's fault-proof portal ran 1h46m under the Foundation guardian before U8 moved the guardian.",
    "U11 Holocene's SystemConfig step executed 15 days after activation on OP Mainnet, 25 days on Soneium, 69 days on Unichain, and NEVER on Ink (2.2.0 -> 2.4.0 at U13).",
    "U15a was SKIPPED on Soneium (U14 prestate 0x03ee2917... ran across the Isthmus activation until U16).",
    "U16 is the branch point for the lockbox: only the four chains of this hunt executed U16; Base/Zora/Metal/Mode/Arena-Z/Swell entered U16a from U15/U13 without a lockbox. U16's super-root prove path was removed again in U16a.",
    "'U18a' is not a maintenance release of the four chains: it is an Arena-Z chain-servicer migration (cannot matter for the four chains).",
    "'U19/U19b': only a '19b' proposal exists; one release (v7.0.0) and one L1 tx for OP/Ink/Soneium (053) plus Unichain (054, 11 days later). Karst is the FIRST change of OP Mainnet's L2 bridge predeploy implementations since Bedrock (no 'MCP L2' was ever executed).",
    "Unichain did not share any upgrade transaction with OP Mainnet until U20; every Unichain upgrade U13..U19 is a separate transaction from its own 3-of-3 Safe, on a different date.",
    "Ink and Unichain started with chain-specific absolute prestates ('1.3.1-ink' 0x03c50b9f..., '1.4.0-unichain-mainnet' 0x0336751a...), and Unichain's genesis permissioned game carried a PLACEHOLDER prestate 0x00000000deaddead... for 2.5 months.",
    "Audit index: the table DOES have a Commit column (an earlier F2 draft said otherwise). Audited commit == released tag commit only for MCP L1 (e6ef3a90 = v1.3.0) and Upgrade 16 (54c19f6a = v4.0.0). Others are pre-release: U13 7d6d1543 (untagged; v2.0.0 = 8d0dd96e), U16a 47580169 = v4.1.0-rc.2 (released rc.3), U17 aeed7033 = v5.0.0-rc.1 (released rc.2), U18 87d406db (untagged; released v6.0.0-rc.2 018f5ae9), U19 7cbcb58f = v7.0.0-rc.1 (released rc.4 a7c88c8d), U20 7799a246 = v8.0.0-rc.2 (released rc.3), U21 8fdb2775 (untagged; released v9.0.0-rc.1 ba6fcadb).",
]

LIMITS = [
    "Sampling+bisection cannot see a value that changes and changes back inside one 20,000-block window (e.g. the U8 SuperchainConfig StorageSetter swap inside one tx; the 2024-02-15 pause, visible only through log scans). Log scans were done only for the OP portal Paused/Unpaused and SuperchainConfig events.",
    "The 2024-02 portal unpause block was not resolved (tx hash from the task README only).",
    "Diffs between audited commits and released commits were not computed (shallow clone; would need one fetch per commit).",
    "L2 predeploy histories were read for OP Mainnet only; Ink/Soneium/Unichain L2 state has no local archive proxy and was not read.",
    "Canyon/Delta/Ecotone/Fjord/Granite/Holocene/Isthmus/Jovian/Karst activation L2 block numbers are computed from timestamps (2 s blocks) except where the L2 predeploy history shows the activation block.",
    "Slot-level layouts (exact slots of legacy mappings, `_initialized` offsets, Ink's scalar slots after skipping Holocene's SystemConfig re-init) are F4's job and are not asserted here beyond the cited Validation.md values.",
    "Governance forum text and notices were read by the previous F2 instance (fetched 2026-11-17) and not re-fetched on resume; proposal numbers/titles are as it recorded them.",
    "Base and the non-hunt chains are mentioned only where they create alternate paths; their histories were not read.",
]

if __name__ == "__main__":
    main()
