# F2 — release-DAG node data (hand-curated from the sources listed in each node's "evidence").
# Rendered to RELEASE-DAG.json / RELEASE-DAG.md by F2_build_dag.py, which also joins the on-chain
# implementation histories in evidence/F2-impl-history-*.json by execution block.
#
# Evidence shorthand used below:
#   IMPL(op)   evidence/F2-impl-history-op-mainnet.json        (EIP-1967 / AddressManager slot history)
#   CALL(op)   evidence/F2-call-history-op-mainnet.json        (view-call history: roles, game types)
#   GAMES(op)  evidence/F2-game-impls-op-mainnet.json          (every registered game implementation)
#   ARGS(op)   evidence/F2-call-history-gameargs-op-mainnet.json
#   TASKS      evidence/F2-superchain-ops-tasks.json           (task -> tx -> block -> UTC)
#   SEMVER     evidence/F2-semver-by-tag.json                  (contract versions in each tag's source tree)
#   OPS-OLD    superchain-ops @ cccb99f8 (branch 03-05-mainnet_opcm_v2.0.0_unichain) tasks/eth/<task>
#   OPS        superchain-ops @ 903cefaa (main) src/tasks/eth/<task>
#   REG        superchain-registry @ edd89bd1
#   GOV n      https://gov.optimism.io/t/<n>  (first post, fetched 2026-11-17)
#   NOTICE x   optimism @ e5423ae6 docs/public-docs/notices/[archive/]x.mdx

GOV = "https://gov.optimism.io/t/"

OP_PAO = "0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A"
FUS = "0x847B5c174615B1B7fDF770882256e2D3E95b9D92"
FOS = "0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A"
SC_SAFE = "0xc2819DC788505Aac350142A7A707BF9D03E3Bd03"
GUARDIAN_SAFE = "0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2"

# L1 block -> node id, per chain (used to label the on-chain implementation histories).
BLOCK_TO_NODE = {
    "op-mainnet": {
        12686687: "OVM", 12686756: "OVM", 12686786: "OVM", 12686787: "OVM", 12706528: "OVM", 13596294: "OVM",
        13596781: "OVM", 13596915: "OVM", 15677422: "OVM", 15677648: "OVM",
        17365801: "U1", 17365802: "U1", 17365803: "U1", 17365804: "U1", 17422444: "U1", 17423158: "U1",
        18367300: "V1.1.0", 18367320: "V1.1.0", 19064589: "U4", 19314493: "U4", 19634866: "U6",
        19884569: "U7", 19884570: "U7", 19884592: "U7", 20062696: "U7", 20063224: "U8", 20270847: "U9",
        20543021: "INC-2024-08", 20637593: "U10", 20637594: "U10", 20637603: "U10", 20637604: "U10",
        20723924: "U10", 20728464: "U10", 21379267: "U11", 21379268: "U11", 21379271: "U11", 21379272: "U11",
        21580854: "U11", 21695024: "U11", 22182531: "U13", 22339996: "U14", 22432368: "U15a",
        22990599: "U16", 23491328: "U16a", 23877377: "U17", 24421512: "U18", 25397811: "U19",
        26048619: "U20", 26430859: "U21",
    },
    "ink": {
        21344310: "GENESIS", 21618223: "CHAIN-FP-ENABLE", 21682329: "CHAIN-FP-ENABLE", 22069032: "U11+U12",
        22182531: "U13", 22339996: "U14", 22432368: "U15a", 22990599: "U16", 23491328: "U16a",
        23877377: "U17", 24421512: "U18", 25397811: "U19", 26048619: "U20", 26430859: "U21",
    },
    "soneium": {
        21314185: "GENESIS", 21945575: "U11", 22182531: "U13", 22339996: "U14", 22990670: "U16",
        23491328: "U16a", 23877377: "U17", 24478557: "U18", 25397811: "U19", 26048619: "U20", 26430859: "U21",
    },
    "unichain": {
        21116350: "GENESIS", 21116351: "GENESIS", 21116362: "GENESIS", 21116363: "GENESIS",
        21689135: "CHAIN-FP-ENABLE", 22081789: "U11", 22254924: "U13", 22342667: "U14", 22432925: "U15a",
        22990722: "U16", 23492571: "U16a", 23878509: "U17", 24427874: "U18", 25475307: "U19",
        25976344: "MAINT-UNI-PAO", 26048619: "U20", 26430859: "U21",
    },
}

AUDIT_INDEX_NOTE = ("Titles are the rows of the index table in optimism@e5423ae6 docs/security-reviews/README.md "
                    "(Date | Reviewer | Focus and Scope). The table has no commit column, so audited commits are "
                    "recorded only where a governance proposal states them. Reports themselves were NOT opened (Track A).")

NODES = []


def node(**kw):
    NODES.append(kw)


# --------------------------------------------------------------------------------------------- OVM
node(
    id="OVM", order=0,
    title="Legacy OVM residue (OVM 1.0 mainnet beta 2021-06, OVM 2.0 regenesis 2021-11, pre-Bedrock L1ERC721Bridge 2022-10)",
    proposal=dict(number=None, name="none (pre-governance / pre-Bedrock)", url=None),
    classification="residue (no governance upgrade number)",
    release=dict(tag=None, commit=None,
                 notes="No op-contracts tag. The pre-Bedrock implementations are only identified by address."),
    execution={
        "op-mainnet": [
            dict(what="AddressManager 0xdE1FCfB0851916CA5101820A69b13a4E276bd81F deployed", block=12686687, utc="2021-06-22 22:13:53", tx="0x8803c67a0032b8dea6b0e3a9d2ff1708346a41a8d2945d4e84e5d81862f1cb54"),
            dict(what="AddressManager name OVM_L1CrossDomainMessenger first set -> 0x16393737d09d2722ad13dca3ca8c3db957699f1d", block=12686756, utc="2021-06-22 22:29:27", tx="0xd19d40f11c375feeea5fe47576ce98a3a08caac68b2a8a52fb95dd1a76dd205a"),
            dict(what="L1StandardBridge L1ChugSplashProxy 0x99C9fc46... first implementation 0x9091dda480b232133a7d2e4cb23336b4f0293196", block=12686787, utc="2021-06-22 22:37:53", tx=None),
            dict(what="OVM_L1CrossDomainMessenger -> 0xbfba066b5ca610fe70adce45fcb622f945891bb0", block=12706528, utc="2021-06-26 00:52:47", tx="0x98a05fb521b3349dd92cff2e104d78c6c318add003bb501c0d416b2b4d75df8a"),
            dict(what="OVM 2.0 regenesis: OVM_L1CrossDomainMessenger set to address(0) (messenger disabled)", block=13596294, utc="2021-11-11 17:37:56", tx="0x2625aa2013fd1a650fb0264d2746be597e12f846baa48a68fe14539c200ed6dc"),
            dict(what="OVM 2.0: OVM_L1CrossDomainMessenger -> 0xd9166833ff12a5f900ccfbf2c8b62a90f1ca1fd5", block=13596781, utc="2021-11-11 19:29:14", tx="0xbabb37235bd38ae5a29717590eedfd9b02f84a12b890b2126feac68f223d7448"),
            dict(what="OVM 2.0: L1StandardBridge implementation -> 0x40e0c049f4671846e9cff93aaed88f2b48e527bb", block=13596915, utc="2021-11-11 19:59:10", tx=None),
            dict(what="L1ERC721Bridge proxy 0x5a7749f8... deployed (first impl 0x3268ed09..., version 1.0.0, set at block 15677648)", block=15677422, utc="2022-10-04 21:23:11", tx="0x7583d011cf1593fb1ffc79b097b0a365192c87dfdccbf860e1ad3f1425a305ef"),
        ],
        "ink": "n/a (chain created 2024-12)", "soneium": "n/a (chain created 2024-12)", "unichain": "n/a (chain created 2024-11)",
    },
    chain_set=["op-mainnet"],
    changed_l1=["AddressManager (Lib_AddressManager) — still the resolver of the L1CrossDomainMessenger implementation today",
                "L1CrossDomainMessenger ResolvedDelegateProxy 0x25ace71c... (proxy and its storage survive every later release)",
                "L1StandardBridge L1ChugSplashProxy 0x99C9fc46... (proxy and its storage survive)",
                "L1ERC721Bridge Proxy 0x5a7749f8... (deployed 8 months before Bedrock with a 1.0.0 implementation)"],
    changed_l2_clients=["OVM l2geth; whole L2 state carried into Bedrock by the migration (see U1)"],
    initializers=["n/a (legacy)"],
    storage_headline=["Storage created under OVM code and still present under the same proxies: L1CDM slot 0 held abi.encodePacked(initialized=true, libAddressManager) until U4; "
                      "L1StandardBridge slot 0 held the legacy `messenger` address until U4; L1StandardBridge `deposits[l1Token][l2Token]`; "
                      "L1CDM legacy relay bookkeeping (successful/blocked/relayed message mappings keyed by legacy hashes). Exact slots: F4."],
    roles=["AddressManager owner / L1ChugSplashProxy owner = legacy Optimism multisig 0x9BA6e03D... until Bedrock handed both to the ProxyAdmin 0x543bA4AA..."],
    dispute=["none (OVM state commitment chain; not carried forward)"],
    invalidated=["nothing explicitly; pre-Bedrock L2->L1 messages remain relayable only through the Bedrock migration path (U1)"],
    audits=["2020-10 Trail of Bits — Rollup", "2020-11 Dapphub — ECDSA Wallet", "2021-03 OpenZeppelin — OVM and Rollup", "2021-03 ConsenSys Diligence — Safety Checker"],
    skipped_alternate=["Only OP Mainnet has OVM ancestry. Ink, Soneium and Unichain proxies were created fresh in 2024 with a clean slot 0 and a per-proxy AddressManager entry (ResolvedDelegateProxy.addressManager[proxy], slot keccak(proxy,1))."],
    cannot_matter=None,
    evidence=["IMPL(op) targets L1CrossDomainMessenger(AddressManager ...), L1StandardBridge, L1ERC721Bridge",
              "OPS-OLD 004-add-superchainConfig/Validation.md (L1CDM slot 0 and L1StandardBridge slot 0 'Before' values)"],
)

# --------------------------------------------------------------------------------------------- U1
node(
    id="U1", order=1,
    title="Upgrade #1 — Bedrock",
    proposal=dict(number="1", name="[FINAL] Upgrade #1: Bedrock Protocol Upgrade - v2", url=GOV + "5548"),
    classification="hardfork (re-genesis-less migration) + full L1 contract replacement",
    release=dict(tag="op-contracts/v1.0.0", commit="a12a09f7000ff785a4058998e09b366cbe5a3ed2",
                 notes="Lightweight tag; commit dated 2023-06-06 12:31 -0400 ('Update b2.json'), i.e. tagged on the migration day."),
    execution={
        "op-mainnet": [
            dict(what="Proxies pre-deployed: L2OutputOracle, OptimismPortal, OptimismMintableERC20Factory, SystemConfig", block="17365801-17365804", utc="2023-05-29 16:22:47..16:23:23", tx="0x615bd360..., 0x8da60c6c..., 0x4c2e6326..., 0x17a29cb8..."),
            dict(what="Migration step A (Safe 0x9BA6e03D... execTransaction): SystemConfig impl 1.3.0 + first initialize; AddressManager OVM_L1CrossDomainMessenger set to address(0) (L1 messenger disabled for the migration window)", block=17422444, utc="2023-06-06 15:58:47", tx="0x76bceccd7d44656f5a129a600a6120091570b897c1d45c18cd7134cfe67c2537"),
            dict(what="L2 Bedrock genesis block 105235063, timestamp 1686068903, L1 origin 17422590 (REG op.toml)", block=17422590, utc="2023-06-06 16:28:23", tx=None),
            dict(what="Migration step B (same Safe): OptimismPortal 1.6.0, L2OutputOracle 1.3.0, OptimismMintableERC20Factory 1.1.0, L1CDM 1.4.0 (AddressManager), L1StandardBridge 1.1.0 (ChugSplash); ProxyAdmin owner -> 0x9BA6e03D...", block=17423158, utc="2023-06-06 18:24:11", tx="0xe2ff41f9bdf03d5455f55539b8b9c350276a179ca7f79322e2077d7c1ffb1268"),
        ],
        "ink": "genesis-active (chain genesis 2024-12-06 on L1 block 21344310)",
        "soneium": "genesis-active (chain genesis 2024-12-02 on L1 block 21314185)",
        "unichain": "genesis-active (chain genesis 2024-11-04 on L1 block 21116363)",
    },
    chain_set=["op-mainnet"],
    changed_l1=["NEW: OptimismPortal 1.6.0, L2OutputOracle 1.3.0, SystemConfig 1.3.0, OptimismMintableERC20Factory 1.1.0, ProxyAdmin 0x543bA4AA...",
                "REPLACED IN PLACE (OVM proxies kept): L1CrossDomainMessenger 1.4.0, L1StandardBridge 1.1.0",
                "L1ERC721Bridge stays at its 2022 implementation 1.0.0 (not touched by the migration transactions)"],
    changed_l2_clients=["op-geth + op-node replace l2geth; L2 predeploys at Bedrock genesis versions on OP Mainnet: L2ToL1MessagePasser 1.0.0, L2CrossDomainMessenger 1.4.0, L2StandardBridge 1.1.0, L1Block 1.0.0, GasPriceOracle 1.0.0",
                        "ON OP MAINNET THESE BRIDGE PREDEPLOYS KEEP THEIR BEDROCK-GENESIS IMPLEMENTATION UNTIL KARST (U19): no implementation change is visible between L2 block 105235063 and 153963812 (evidence/F2-impl-history-op-mainnet-L2-predeploys.json)"],
    initializers=["OptimismPortal.initialize(bool _paused) [initializer]", "SystemConfig.initialize(owner, overhead, scalar, batcherHash, gasLimit, unsafeBlockSigner, resourceConfig) [initializer]",
                  "L1CrossDomainMessenger.initialize() [initializer]; L1StandardBridge has no initializer in v1.0.0 (immutables)"],
    storage_headline=["Portal: `paused` local flag, `provenWithdrawals[hash] -> {outputRoot, timestamp, l2OutputIndex}`, `finalizedWithdrawals`; immutables L2_ORACLE, GUARDIAN, SYSTEM_CONFIG",
                      "L1CDM/L1StandardBridge re-use the OVM proxies: legacy slots are kept as spacers (see OVM node); withdrawal hash / message nonce get a version field (v0 legacy, v1 Bedrock)"],
    roles=["ProxyAdmin 0x543bA4AA... owner: 0xb4453ceb33d2e67fa244a24acf2e50cef31f53cb at L1 block 17422590 -> 0x9BA6e03D... at 17423158 (CALL(op) proxyAdmin.owner())",
           "Guardian = portal immutable GUARDIAN = 0x9BA6e03D...; SystemConfig owner = 0x9BA6e03D...; L2 ProxyAdmin owner = 0x7871d1187a97cbbe40710ac119aa3d412944e4fe (evidence/F2-call-history-op-mainnet-L2.json)"],
    dispute=["L2OutputOracle (permissioned proposer, challenger can delete outputs, 7-day finalization)"],
    invalidated=["OVM-era withdrawal relays are replaced by the two-step prove/finalize flow; legacy L2->L1 messages are carried as migrated withdrawals (B02 owns the hash-domain question)"],
    audits=["2022-05 Zeppelin — Bedrock Contracts", "2022-05 Trail of Bits — OpNode", "2022-08 Sigma Prime — Bedrock GoLang",
            "2022-09 Zeppelin — Bedrock and Periphery: All contracts in packages/contracts-bedrock/contracts", "2022-10 Spearbit — Drippie: Drippie.sol",
            "2022-11 Trail of Bits — Invariant Testing: OptimismPortal.sol", "2022-12 Runtime Verification — Deposit Transaction: OptimismPortal.sol",
            "2023-01 Trail of Bits — Bedrock Updates: SystemConfig.sol", "2023-01 Sherlock — Bedrock: All contracts in packages/contracts-bedrock/src",
            "2023-03 Sherlock — Bedrock Fixes: All contracts in packages/contracts-bedrock/src"],
    skipped_alternate=["Regolith is 'Genesis / at Bedrock' for mainnet (hardfork registry)."],
    cannot_matter=None,
    evidence=["IMPL(op)", "CALL(op)", "REG superchain/configs/mainnet/op.toml [genesis]", "GOV 5548", "SEMVER v1.0.0"],
)

# --------------------------------------------------------------------------------------------- v1.1.0
node(
    id="V1.1.0", order=2,
    title="op-contracts/v1.1.0 — tag without an OP Mainnet upgrade (ProtocolVersions is its only footprint)",
    proposal=dict(number=None, name="none found on gov.optimism.io for this tag", url=None),
    classification="tag only / new signalling contract (not a governance-numbered upgrade)",
    release=dict(tag="op-contracts/v1.1.0", commit="c383eb880f307caa3ca41010ec10f30f08396b2e",
                 notes="Lightweight tag, commit 2023-10-16. Its contract versions (OptimismPortal 1.10.0, SystemConfig 1.10.0, L1CDM 1.7.0, L2OO 1.6.0) were never set on an OP Mainnet proxy: every proxy goes directly from its v1.0.0 implementation to its v1.2.0 implementation at U4."),
    execution={
        "op-mainnet": [dict(what="ProtocolVersions proxy 0x8062AbC2... created, implementation 1.0.0 (0x42f0bd83...) set one day after the tag commit (attribution to this tag is an inference from the date and from ProtocolVersions first appearing in the v1.1.0 tree)", block="18367300 / 18367320", utc="2023-10-17 03:05:11 / 03:09:35", tx="0x4ab7f052... / 0xa97289b1...")],
        "ink": "n/a", "soneium": "n/a", "unichain": "n/a",
    },
    chain_set=["op-mainnet (superchain-wide ProtocolVersions)"],
    changed_l1=["NEW ProtocolVersions 1.0.0 (required/recommended protocol version signals read by op-node; owner 0x9BA6e03D... -> Foundation Upgrade Safe on 2024-06-27; upgraded once to 1.1.0 at U13; dropped from OPCM at U20, proxy still deployed)"],
    changed_l2_clients=["op-node reads ProtocolVersions to warn/halt on outdated software (off-chain behaviour)"],
    initializers=["ProtocolVersions.initialize(owner, required, recommended) via upgradeToAndCall (0x4f1ef286)"],
    storage_headline=["none on bridge contracts"],
    roles=["ProtocolVersions owner (signalling only)"],
    dispute=["none"], invalidated=["none"], audits=["no row in the index table"],
    skipped_alternate=["SKIPPED on OP Mainnet as a contract release (implementation history IMPL(op): Portal 1.6.0 -> 2.4.0, SystemConfig 1.3.0 -> 1.11.0, L1CDM 1.4.0 -> 2.2.0)."],
    cannot_matter=("Marked 'cannot matter' for the bridge state machine. Checked against each criterion: (1) persistent state — creates only the ProtocolVersions proxy, which no bridge contract reads "
                   "(no reference in OptimismPortal/SystemConfig/L1CDM/bridges at any tag; only OPCM v2..v7 upgraded it); (2) surviving object mutated — none (no OP Mainnet proxy ever pointed at a v1.1.0 implementation); "
                   "(3) interpretation of current state — none; (4) authorization/dependency — none on-chain (op-node halting is an off-chain liveness signal owned by the Foundation Upgrade Safe); "
                   "(5) proof validity — none; (6) residue — the orphaned ProtocolVersions proxy at 1.1.0; (7) canonical upgrade path — not part of it; (8) branch-specific history — none for the four chains; "
                   "(9) prestate/game type/root format — none; (10) L1/L2 relationship — none. Residual risk stated: an op-node 'required version' halt is a liveness lever outside the contracts."),
    evidence=["IMPL(op) ProtocolVersions, OptimismPortal, SystemConfig", "SEMVER v1.1.0"],
)

# --------------------------------------------------------------------------------------------- SC phase 0
node(
    id="SC-PHASE-0", order=3,
    title="Security Council Phase 0 — L1 ProxyAdmin owner becomes the 2-of-2 Safe",
    proposal=dict(number=None, name="Security Council: Vote #1 - Change to Security Model (+ member ratification)", url=GOV + "6886"),
    classification="authorization change (no code release)",
    release=dict(tag=None, commit=None, notes="Safe configuration only."),
    execution={"op-mainnet": [dict(what="ProxyAdmin.owner(): 0x9BA6e03D... -> 0x5a0Aae59... (2-of-2: Foundation Upgrade Safe 0x847B5c17... + Security Council Safe 0xc2819DC7...)", block=19193284, utc="2024-02-09 21:35:47", tx="0xd2a7e63eb76199234e4876c1c99dcdf73f0ed04eb8b8767e94809cc2de2629ca")],
               "ink": "inherits (PAO 0x5a0Aae59... from genesis)", "soneium": "inherits (PAO 0x5a0Aae59... from genesis)",
               "unichain": "DIFFERENT: own 3-of-3 PAO 0x6d5B183F... (chain governor + Foundation + Security Council) until 2026-09-14 (MAINT-UNI-PAO)"},
    chain_set=["op-mainnet"],
    changed_l1=["none (ownership only)"], changed_l2_clients=["none"], initializers=["none"], storage_headline=["ProxyAdmin._owner"],
    roles=["Upgrade authority for every OP Mainnet L1 proxy moves to 0x5a0Aae59... and stays there through U21 (CALL(op) proxyAdmin.owner(): no later change)"],
    dispute=["none"], invalidated=["none"], audits=["no row in the index table"],
    skipped_alternate=["Unichain used a different upgrade authority for U13..U19 (separate transactions, different execution dates: see per-chain columns)."],
    cannot_matter=None,
    evidence=["CALL(op) proxyAdmin.owner()", "OPS-OLD 001-security-council-phase-0", "TASKS"],
)

node(
    id="PAUSE-2024-02", order=4,
    title="Mainnet pause rehearsal on the Bedrock portal (local `paused` flag)",
    proposal=dict(number=None, name="none (operational; superchain-ops task 002-pause-mainnet)", url=None),
    classification="operational event (state toggled and restored)",
    release=dict(tag=None, commit=None, notes="Portal implementation 1.6.0 (v1.0.0)."),
    execution={"op-mainnet": [dict(what="OptimismPortal Paused(account=0x9BA6e03D...) — the only Paused log of the portal in blocks 17365802..19320000", block=19233786, utc="2024-02-15 14:00:23", tx="0x374dc0d5ad3dd0683d92762c84c7038804dd987e9fd9bac7418dca5ff489e6b0"),
                              dict(what="Unpause (tx hash from the task README; block not resolved here)", block=None, utc=None, tx="0x7d6880954fd4df2a8da987b5d8500e07613e3549a3376bef94e951aab890fc54")],
               "ink": "n/a", "soneium": "n/a", "unichain": "n/a"},
    chain_set=["op-mainnet"],
    changed_l1=["none"], changed_l2_clients=["none"], initializers=["none"],
    storage_headline=["Portal slot 53 byte 0 (`paused`) set and cleared 11 days before U4 re-used slot 53 for `superchainConfig` (packed after a 1-byte spacer)"],
    roles=["Guardian (0x9BA6e03D...) pause authority exercised on mainnet for the first time"],
    dispute=["none"], invalidated=["none (prove/finalize blocked while paused)"], audits=["n/a"],
    skipped_alternate=[], cannot_matter=None,
    evidence=["evidence/F2-op-portal-paused-logs.json", "OPS-OLD 002-pause-mainnet/README.md", "CALL(op) portal.paused() == false at every 20k-block sample"],
)

# --------------------------------------------------------------------------------------------- U2 / U3
node(
    id="U2", order=5, title="Upgrade #2 — Canyon",
    proposal=dict(number="2", name="[FINAL] Upgrade Proposal #2: Canyon Network Upgrade", url=GOV + "7088"),
    classification="hardfork (L2 only)",
    release=dict(tag=None, commit="6cce3728... (monorepo commit named 'code complete' in the proposal; not an op-contracts tag)", notes="No op-contracts release."),
    execution={"op-mainnet": [dict(what="Canyon activation, L2 timestamp 1704992401 (first OP Mainnet block: 114696812, computed from 2 s blocks)", block=None, utc="2024-01-11 17:00:01", tx=None)],
               "ink": "active from genesis (canyon_time = 0)", "soneium": "active from genesis", "unichain": "active from genesis"},
    chain_set=["op-mainnet (and Base, PGN, Zora at the time)"],
    changed_l1=["none"],
    changed_l2_clients=["Shapella EIPs on L2; EIP-1559 denominator 50 -> 250; deposit nonce + nonce version added to the deposit receipt hash; create2Deployer predeploy at 0x13b0D85C...; channel ordering fix (op-node >= v1.3.1 / op-geth >= v1.101304.1)"],
    initializers=["none"], storage_headline=["none on L1"], roles=["none"], dispute=["none (L2OutputOracle era)"], invalidated=["none"],
    audits=["no row in the index table"], skipped_alternate=[],
    cannot_matter=("L1-object lineage only: no L1 contract, storage, role, proof or root-format change. NOT skipped for the L2 side: it creates persistent L2 state (create2Deployer code) and changes the receipt-hash rule. "
                   "It cannot be re-executed by any live dispute game: every chain's anchor was re-set to a super root at U20 (OP Mainnet: L2 block 156622039), far above the activation block. "
                   "Kept in the DAG as an L2-rule node; no L1 edge originates here."),
    evidence=["hardfork registry canyon.mdx", "REG superchain.toml", "GOV 7088"],
)

node(
    id="U3", order=6, title="Upgrade #3 — Delta",
    proposal=dict(number="3", name="[FINAL] Upgrade Proposal #3: Delta Network Upgrade", url=GOV + "7310"),
    classification="hardfork (consensus-layer only: span batches)",
    release=dict(tag=None, commit=None, notes="No op-contracts release (op-node v1.4.1 / op-geth v1.101304.2 per the proposal)."),
    execution={"op-mainnet": [dict(what="Delta activation, L2 timestamp 1708560000", block=None, utc="2024-02-22 00:00:00", tx=None),
                              dict(what="ProtocolVersions required+recommended -> 5.0.0 (set AFTER activation)", block=19320684, utc="2024-02-27 18:29:59", tx="0x2c616fc82192b85d245fe7bff1f4ed8015a6b3bfdbcbedf087fd7e6d25ffe814")],
               "ink": "active from genesis", "soneium": "active from genesis", "unichain": "active from genesis"},
    chain_set=["op-mainnet"],
    changed_l1=["none (ProtocolVersions values only)"], changed_l2_clients=["span batches in derivation (op-node); no execution-engine change"],
    initializers=["none"], storage_headline=["none"], roles=["none"], dispute=["none"], invalidated=["none"], audits=["no row in the index table"],
    skipped_alternate=["The proposal text quotes Unix time 1707922800 for 2024-02-22 00:00 UTC; the registry value is 1708560000 (the proposal number is a typo)."],
    cannot_matter=("L1-object lineage only: derivation-format change, no L1 contract/storage/role/proof/root-format change and no persistent L2 contract state. Same anchor argument as U2. Kept as an L2-rule node."),
    evidence=["hardfork registry delta.mdx", "OPS-OLD 003-protocol-versions-delta", "TASKS", "GOV 7310"],
)

# --------------------------------------------------------------------------------------------- U4
node(
    id="U4", order=7, title="Upgrade #4 — SuperchainConfig and extended pause",
    proposal=dict(number="4", name="Upgrade Proposal #4", url=GOV + "7534"),
    classification="contracts-only",
    release=dict(tag="op-contracts/v1.2.0", commit="856c08bf84d9aa829d1e764fc8e9a37d41960ba0",
                 notes="Same commit as v1.2.0-rc.1. OUT OF ORDER: this commit is dated 2024-01-24, two days AFTER the v1.3.0 commit (2024-01-22) — v1.2.0 is a branch cut from pre-MCP code, not an ancestor-by-date of v1.3.0. "
                       "The proposal text announces OptimismPortal 2.1.0; the tagged and deployed version is 2.4.0."),
    execution={"op-mainnet": [dict(what="SuperchainConfig proxy 0x95703e09... + implementation 1.1.0 (0x53c16516...) deployed and initialized (guardian 0x9BA6e03D..., paused=false)", block=19064589, utc="2024-01-22 20:19:59", tx="0x3c23aae4..., 0x8ba0e42b..., 0xcde51cae..."),
                              dict(what="Upgrade transaction (Safe 0x5a0Aae59...): 7 proxies in one tx", block=19314493, utc="2024-02-26 21:44:11", tx="0x3f7c36a1d636cdb23bf4f9171c27ebe58b73f4c0e6a33dbaac2c2f3c142faf50")],
               "ink": "genesis-included (SuperchainConfig 0x95703e09... is shared)", "soneium": "genesis-included (shared SuperchainConfig)", "unichain": "genesis-included (shared SuperchainConfig)"},
    chain_set=["op-mainnet"],
    changed_l1=["NEW SuperchainConfig 1.1.0 (guardian + global pause)", "OptimismPortal 1.6.0 -> 2.4.0", "SystemConfig 1.3.0 -> 1.11.0", "L1CrossDomainMessenger 1.4.0 -> 2.2.0",
                "L1StandardBridge 1.1.0 -> 2.0.0", "L1ERC721Bridge 1.0.0 -> 2.0.0", "OptimismMintableERC20Factory 1.1.0 -> 1.8.0 (decimals, CREATE2)", "L2OutputOracle 1.3.0 -> 1.7.0"],
    changed_l2_clients=["none"],
    initializers=["OptimismPortal.initialize(SuperchainConfig) [initializer]", "L1CrossDomainMessenger.initialize(SuperchainConfig) [initializer]",
                  "L1StandardBridge.initialize(SuperchainConfig) [initializer] — first time the bridge has an initializer", "L1ERC721Bridge.initialize(SuperchainConfig) [initializer]",
                  "Because these use OZ `initializer`, the legacy non-zero slot-0 contents of the OVM-era proxies had to be rewritten in the same transaction (see storage)."],
    storage_headline=["Portal slot 53 (0x35): `superchainConfig` packed after the old 1-byte `paused` field (value 0x...95703e09...4a4c00)",
                      "L1CDM slot 0: 0x...01<AddressManager> -> 0x...01<zero> (legacy libAddressManager deleted, `_initialized` byte at offset 20 kept); slot 251 (0xfb) = superchainConfig",
                      "L1StandardBridge slot 0: legacy `messenger` address (0x25ace71c...) -> 0x...01 (`_initialized`); slot 50 (0x32) = superchainConfig",
                      "L1ERC721Bridge slot 0 = 1 (initialized), slot 50 = superchainConfig"],
    roles=["Guardian is now read from SuperchainConfig (0x9BA6e03D... at this point; CALL(op) portal.guardian())",
           "Pause scope extended from portal prove/finalize to L1CDM.relayMessage, L1StandardBridge finalize*, L1ERC721Bridge.finalizeBridgeERC721",
           "Portal-local `paused` flag is no longer the source of truth"],
    dispute=["none (L2OutputOracle re-implemented, same semantics)"], invalidated=["none stated"],
    audits=["2023-12 Trust — Superchain Config Upgrade: SuperchainConfig.sol, L1CrossDomainMessenger.sol, L1ERC721Bridge.sol, L1StandardBridge.sol, OptimismPortal.sol, CrossDomainMessenger.sol, ERC721Bridge.sol, StandardBridge.sol",
            "2024-02 Runtime Verification — Pausability (Kontrol Verification)"],
    skipped_alternate=["The proposal (not an audit report) states that the upgrade PATH itself had an issue that the upgrade scripts were changed to avoid — i.e. the order of operations of this transaction was security-relevant."],
    cannot_matter=None,
    evidence=["IMPL(op) block 19314493", "OPS-OLD 004-add-superchainConfig/Validation.md", "GOV 7534", "SEMVER v1.2.0"],
)

# --------------------------------------------------------------------------------------------- U5
node(
    id="U5", order=8, title="Upgrade #5 — Ecotone",
    proposal=dict(number="5", name="Upgrade Proposal #5: Ecotone Network Upgrade", url=GOV + "7669"),
    classification="hardfork",
    release=dict(tag=None, commit="f707883038d527cbf1e9f8ea513fe33255deadbc (monorepo 'code complete' commit per the proposal; op-node v1.7.0)", notes="No op-contracts release."),
    execution={"op-mainnet": [dict(what="ProtocolVersions -> 6.0.0", block=19420232, utc="2024-03-12 16:36:35", tx="0x29bb617fac8f49f5c934cc776b22d47e187ab482e86f21e4502a23ba1c9ad0da"),
                              dict(what="Ecotone activation, L2 timestamp 1710374401 = OP Mainnet L2 block 117387812 (L1Block 1.0.0 -> 1.2.0 and GasPriceOracle 1.0.0 -> 1.2.0 by upgrade deposit transactions in that block)", block=None, utc="2024-03-14 00:00:01", tx=None),
                              dict(what="SystemConfig gas config set for Ecotone scalars (task 005-2); task 005-3 CANCELLED", block=19429571, utc="2024-03-14 00:03:11", tx="0xac827d7a1238dfd6f3cc81dba09f0a3e1d9dc685bcc6b22466d76bb2335db38b")],
               "ink": "active from genesis", "soneium": "active from genesis", "unichain": "active from genesis"},
    chain_set=["op-mainnet"],
    changed_l1=["none (SystemConfig value only: `scalar` re-encoded with version byte 1 = basefeeScalar/blobbasefeeScalar)"],
    changed_l2_clients=["Cancun EIPs on L2, EIP-4788 beacon roots contract, blob DA in derivation, L1Block.setL1BlockValuesEcotone, new L1 fee formula"],
    initializers=["none on L1"], storage_headline=["SystemConfig.scalar value semantics change (versioned encoding) — same slot, new interpretation by op-node/L1Block"],
    roles=["none"], dispute=["none"], invalidated=["none"], audits=["no row in the index table"], skipped_alternate=[],
    cannot_matter=None,
    evidence=["evidence/F2-impl-history-op-mainnet-L2-predeploys.json (L1Block, GasPriceOracle at L2 block 117387812)", "OPS-OLD 005-*", "TASKS", "GOV 7669"],
)

# --------------------------------------------------------------------------------------------- U6
node(
    id="U6", order=9, title="Upgrade #6 — Multi-Chain Prep (MCP) L1",
    proposal=dict(number="6", name="Upgrade Proposal #6: Multi-Chain Prep (MCP) L1", url=GOV + "7677"),
    classification="contracts-only",
    release=dict(tag="op-contracts/v1.3.0", commit="e6ef3a900c42c8722e72c2e2314027f85d12ced5",
                 notes="Same commit as v1.3.0-rc.1 ('feat: MCP L1 (#9058)', 2024-01-22). Committed BEFORE the v1.2.0 commit but executed after it."),
    execution={"op-mainnet": [dict(what="Upgrade transaction (Safe 0x5a0Aae59...), 7 proxies", block=19634866, utc="2024-04-11 20:49:59", tx="0x4758bd62359bc69d7e8a0faaf5308d826379c23258d689a7430d5c0ad0361ad2")],
               "ink": "genesis-included", "soneium": "genesis-included", "unichain": "genesis-included"},
    chain_set=["op-mainnet (Metal, Mode, Zora 2024-04-19; Base 2024-06-28 by their own tasks)"],
    changed_l1=["OptimismPortal 2.4.0 -> 2.5.0", "SystemConfig 1.11.0 -> 1.12.0", "L1CrossDomainMessenger 2.2.0 -> 2.3.0", "L1StandardBridge 2.0.0 -> 2.1.0",
                "L1ERC721Bridge 2.0.0 -> 2.1.0", "OptimismMintableERC20Factory 1.8.0 -> 1.9.0", "L2OutputOracle 1.7.0 -> 1.8.0 (its last implementation; frozen since)"],
    changed_l2_clients=["none (an 'MCP L2' counterpart was never executed on OP Mainnet: L2 bridge predeploys stay at Bedrock-genesis implementations until Karst)"],
    initializers=["All seven contracts re-initialized with the values that used to be immutables (OZ `initializer`; the upgrade resets `_initialized` through a StorageSetter step — F4 owns the detail)"],
    storage_headline=["Immutables moved to storage: Portal l2Oracle (slot 54), systemConfig (slot 55); L1CDM otherMessenger (slot 207), portal (slot 252); L1StandardBridge messenger (slot 3), otherBridge (slot 4); "
                      "L1ERC721Bridge messenger (slot 1), otherBridge (slot 2); OptimismMintableERC20Factory bridge (slot 1); L2OO submissionInterval/l2BlockTime/challenger/proposer/finalizationPeriodSeconds (slots 4..8)",
                      "SystemConfig gains address slots (l1CrossDomainMessenger, l1ERC721Bridge, l1StandardBridge, l2OutputOracle, optimismPortal, optimismMintableERC20Factory, batchInbox) and startBlock = 17422444"],
    roles=["No role change. Dependencies that were code constants become mutable storage reachable by the ProxyAdmin owner."],
    dispute=["none"], invalidated=["none stated"],
    audits=["2024-02 Cantina — MCP L1: OptimismPortal.sol, L1CrossDomainMessenger.sol, L1StandardBridge.sol, L1ERC721Bridge.sol, OptimismMintableERC20Factory.sol, L2OutputOracle.sol, SystemConfig.sol"],
    skipped_alternate=["Ink/Soneium/Unichain never held immutable-era values: they were deployed post-MCP."],
    cannot_matter=None,
    evidence=["IMPL(op) block 19634866", "OPS-OLD 006-MCP-L1/VALIDATION.md", "GOV 7677", "SEMVER v1.3.0"],
)

# --------------------------------------------------------------------------------------------- U7
node(
    id="U7", order=10, title="Upgrade #7 — Fault Proofs",
    proposal=dict(number="7", name="[FINAL] Protocol Upgrade #7: Fault Proofs", url=GOV + "8161"),
    classification="contracts-only",
    release=dict(tag="op-contracts/v1.4.0", commit="547ea72d9849e13ce169fd31df0f9197651b3f86",
                 notes="Annotated tag created 2024-06-07 on the rc.4 commit (2024-05-16). v1.4.0-rc.2 = a6d4eeda = the op-program/v1.0.0 commit the first absolute prestate was built from."),
    execution={"op-mainnet": [dict(what="Pre-deployment: DisputeGameFactory proxy (impl 1.0.0), AnchorStateRegistry gen1 0x18DAc71c... (1.0.0), DelayedWETH gen1 0xE497B094... (1.0.0), FaultDisputeGame 0x4146DF64... and PermissionedDisputeGame 0xE9daD167... (1.2.0), MIPS 0x0f8EdFbD..., PreimageOracle 0xD326E10B...; gameImpls(0),(1) set and initBonds 0.08 ETH; DGF owner 0xf2fbae9b... -> 0x5a0Aae59... four minutes later", block="19884569-19884592", utc="2024-05-16 19:17:23..19:21:59", tx="0x8104cc6e..., 0x2c16c813..., 0x49303e95..., 0x864c1af8..."),
                              dict(what="Upgrade transaction: OptimismPortal -> OptimismPortal2 3.10.0, SystemConfig -> 2.2.0", block=20062696, utc="2024-06-10 16:42:59", tx="0xbe810ed6e1e827930bd46cde42c4883662ddb6d244a26af2f0409cc2782bee61")],
               "ink": "genesis-included but started with respectedGameType = 1 (permissioned); CANNON implementation registered 2025-01-13, respected type switched to 0 on 2025-01-22 (L1 block 21682329)",
               "soneium": "genesis-included, permissioned only: gameImpls(0) has never been set; respected type 1 until U20",
               "unichain": "genesis-included, respectedGameType = 1 until 2025-01-23 (L1 block 21689135), then 0"},
    chain_set=["op-mainnet"],
    changed_l1=["OptimismPortal 2.5.0 -> OptimismPortal2 3.10.0 (DisputeGameFactory replaces L2OutputOracle as the source of roots)", "SystemConfig 1.12.0 -> 2.2.0 (disputeGameFactory slot, 200M max gas limit, setResourceConfig removed)",
                "NEW DisputeGameFactory 1.0.0, AnchorStateRegistry 1.0.0, DelayedWETH 1.0.0, FaultDisputeGame/PermissionedDisputeGame 1.2.0, MIPS 1.0.1, PreimageOracle 1.0.0",
                "NOT changed: L1CrossDomainMessenger, L1StandardBridge, L1ERC721Bridge, OptimismMintableERC20Factory; L2OutputOracle left deployed and frozen (latestOutputIndex 8878, L2 block 121217263)"],
    changed_l2_clients=["op-challenger, op-dispute-mon, op-proposer (dispute-game mode); op-program v1.0.0 (absolute prestate 0x037ef3c1...)"],
    initializers=["OptimismPortal2.initialize(disputeGameFactory, systemConfig, superchainConfig) [initializer]; SystemConfig.initialize(...) [initializer]"],
    storage_headline=["Portal: disputeGameFactory at slot 56 (0x38); respectedGameType + respectedGameTypeUpdatedAt at slot 59 (0x3b) (updatedAt = 0x66672d13 = execution time); "
                      "legacy `provenWithdrawals[hash]` mapping becomes a spacer and a new `provenWithdrawals[hash][submitter] -> {disputeGameProxy, timestamp}` mapping is used; l2Oracle getter removed",
                      "SystemConfig: L2OutputOracle slot cleared, DisputeGameFactory slot set"],
    roles=["Guardian gains blacklistDisputeGame / setRespectedGameType; proposing becomes permissionless",
           "ORDER: U7 executed at 16:42:59, the guardian only moved to the Security Council guardian Safe at 18:29:23 (U8) — for 1h46m the fault-proof portal ran under the Foundation guardian"],
    dispute=["Game types 0 CANNON and 1 PERMISSIONED_CANNON; respected type 0; absolute prestate 0x037ef3c1a487960b0e633d3e513df020c43432769f41a634d18a9595cbf53c55 (op-program 1.0.0, cannon32)",
             "proofMaturityDelaySeconds 604800, disputeGameFinalityDelaySeconds 302400 (unchanged since)", "Starting anchor: L2 block 120059863",
             "Games could be (and were allowed to be) created for 25 days before the portal upgrade"],
    invalidated=["ALL pending withdrawal proofs (proofs against L2OutputOracle indices are unreadable by OptimismPortal2; users re-prove against a game)",
                 "L2OutputOracle outputs are no longer consumed"],
    audits=["2024-03 Sherlock — Fault Proofs (Sherlock Optimism Fault Proofs Contest)"],
    skipped_alternate=["Chains that stayed on L2OutputOracle used op-contracts/v1.5.0's OptimismPortal 2.8.0 line instead (not the four chains)."],
    cannot_matter=None,
    evidence=["IMPL(op) blocks 19884569..20062696", "CALL(op) portal.respectedGameType()", "GAMES(op)", "OPS-OLD 009-fp-upgrade/VALIDATION.md", "GOV 8161"],
)

# --------------------------------------------------------------------------------------------- U8
node(
    id="U8", order=11, title="Upgrade #8 — Guardian, Security Council threshold, L2 ProxyAdmin ownership (Stage 1)",
    proposal=dict(number="8", name="[FINAL] Protocol Upgrade #8: Guardian, Security Council Threshold and L2 ProxyAdmin Ownership changes for Stage 1 Decentralization", url=GOV + "8157"),
    classification="authorization change + Safe modules",
    release=dict(tag="op-contracts/v1.5.0", commit="9047beb54c66a5c572784efec8984f259302ec92",
                 notes="Annotated tag created 2024-06-07 (same day as v1.4.0) on the rc.1 commit of 2024-05-16. The release content that reached OP Mainnet is the Safe extensions (LivenessGuard, LivenessModule, DeputyGuardianModule); "
                       "the v1.5.0 tree's OptimismPortal 2.8.0 / L1CDM 2.4.0 / L1StandardBridge 2.2.0 were NEVER set on OP Mainnet proxies."),
    execution={"op-mainnet": [dict(what="L2 ProxyAdmin owner 0x7871d118... -> 0x6B1BAE59... (L1->L2 alias of 0x5a0Aae59...) at OP Mainnet L2 block 121221987", block=None, utc="2024-06-10 18:05:51", tx=None),
                              dict(what="010-1: SuperchainConfig Upgraded -> StorageSetter 0xd81f43ed... -> back to the SAME implementation 1.1.0, re-initialize with guardian = Guardian Safe 0x09f7150D... (Initialized(1) emitted again)", block=20063224, utc="2024-06-10 18:29:23", tx="0xe361c0d4ae3aebc94b3f281ee372fbb1cbdb0c33ca8b1b35e7f3b009b2fcbdb0"),
                              dict(what="010-2: Security Council Safe threshold 4 -> 10 of 13, LivenessGuard 0x24424336..., LivenessModule 0x04540925...; DeputyGuardianModule 0x5dC91D01... enabled on the Guardian Safe", block=20063319, utc="2024-06-10 18:48:23", tx="0x50db9c1b9f5a8616f982022429a1d75c35986bcfb67bd1e3358d97ddbe751144"),
                              dict(what="011: SystemConfig and ProtocolVersions owner 0x9BA6e03D... -> Foundation Upgrade Safe 0x847B5c17... (bundled with the Fjord ProtocolVersions bump)", block=20186225, utc="2024-06-27 23:11:47", tx="0xa324ca8056ff79064771df050d70df9d44deab56290916339d94fd11ea5ee3c0")],
               "ink": "genesis-included (guardian 0x09f7150D... from genesis)", "soneium": "genesis-included", "unichain": "genesis-included for the guardian; L2 ProxyAdmin owner was the alias of its own 3-of-3 until 2026-09-14"},
    chain_set=["op-mainnet (SuperchainConfig is shared, so the guardian change is superchain-wide)"],
    changed_l1=["SuperchainConfig: same implementation, guardian slot rewritten", "Safe modules/guards only"],
    changed_l2_clients=["L2 ProxyAdmin (0x4200...0018) owner"],
    initializers=["SuperchainConfig.initialize(guardian, paused=false) re-run after a StorageSetter reset of `_initialized`"],
    storage_headline=["SuperchainConfig guardian slot (keccak('superchainConfig.guardian')-1): 0x9BA6e03D... -> 0x09f7150D..."],
    roles=["Guardian: Foundation Operations Safe -> 1-of-1 Guardian Safe owned by the Security Council; Foundation keeps guardian powers through DeputyGuardianModule (revocable)",
           "L2 predeploy upgrade authority: Foundation -> alias of the L1 ProxyAdmin owner", "SystemConfig owner: Foundation Operations Safe -> Foundation Upgrade Safe (2024-06-27)"],
    dispute=["DeputyGuardianModule can call setRespectedGameType / blacklistDisputeGame through the Guardian Safe"], invalidated=["none"],
    audits=["no row in the index table for the Safe extensions (the proposal mentions a Cantina contest and a Spearbit reviewer)"],
    skipped_alternate=[], cannot_matter=None,
    evidence=["evidence/F2-superchainconfig-logs.json (block 20063224)", "CALL(op) portal.guardian(), systemConfig.owner()", "evidence/F2-call-history-op-mainnet-L2.json", "OPS-OLD 010-1, 010-2, 011", "GOV 8157"],
)

# --------------------------------------------------------------------------------------------- U9
node(
    id="U9", order=12, title="Upgrade #9 — Fjord",
    proposal=dict(number="9", name="Upgrade Proposal #9: Fjord Network Upgrade", url=GOV + "8236"),
    classification="hardfork + absolute-prestate rotation on L1",
    release=dict(tag=None, commit="f8143c8cbc4cc0c83922c53f17a1e47280673485 (monorepo 'code complete' commit per the proposal)", notes="No op-contracts release: the new games are v1.4.0 FaultDisputeGame code (version 1.2.0) redeployed with a new prestate."),
    execution={"op-mainnet": [dict(what="ProtocolVersions recommended 7.0.0 (011) / required 7.0.0 (012)", block="20186225 / 20269315", utc="2024-06-27 / 2024-07-09 13:45:11", tx="0xa324ca80... / 0xea0bb21a..."),
                              dict(what="013: DisputeGameFactory.setImplementation(0, 0xf691F8A6...) and (1, 0xc307e93a...) — prestate 0x03617abe... (op-program 1.2.0)", block=20270847, utc="2024-07-09 18:52:47", tx="0x7abecacd8b1a54db8f0835a5c82edfab96ff922a41d2faa914c339e3e9319b43"),
                              dict(what="Fjord activation, L2 timestamp 1720627201 (OP Mainnet L2 block 122514212; GasPriceOracle 1.2.0 -> 1.3.0 in that block)", block=None, utc="2024-07-10 16:00:01", tx=None),
                              dict(what="014: Fjord gas config", block=20277159, utc="2024-07-10 16:01:35", tx="0x220c443aebcd9bb04d6eb79e975c6bbe710104feddf8c4fffa3f13eb3c338af9")],
               "ink": "active from genesis", "soneium": "active from genesis", "unichain": "active from genesis"},
    chain_set=["op-mainnet"],
    changed_l1=["DisputeGameFactory.gameImpls only (two new game implementation contracts, same DelayedWETH gen1 and AnchorStateRegistry gen1)"],
    changed_l2_clients=["RIP-7212 precompile, FastLZ L1 fee estimation (GasPriceOracle), Brotli channels, constant max sequencer drift; op-program 1.2.0"],
    initializers=["none"], storage_headline=["DGF gameImpls[0], gameImpls[1]"], roles=["none"],
    dispute=["Absolute prestate 0x037ef3c1... -> 0x03617abec0b255dc7fc7a0513a2c2220140a1dcd7a1c8eca567659bd67e05cea for NEW games; games already created keep the old prestate (immutable in the implementation)"],
    invalidated=["none (respected game type and its timestamp unchanged)"], audits=["no row in the index table"],
    skipped_alternate=["First instance of the recurring pattern 'hardfork => new prestate => new game implementations registered a day before activation'."],
    cannot_matter=None,
    evidence=["GAMES(op)", "OPS-OLD 013-fp-upgrade-fjord", "TASKS", "GOV 8236"],
)

# --------------------------------------------------------------------------------------------- incident
node(
    id="INC-2024-08", order=13, title="Permissioned fallback (respected game type 0 -> 1)",
    proposal=dict(number=None, name="none (guardian action; later described in Upgrade Proposal #10)", url=GOV + "8733"),
    classification="guardian action / incident response",
    release=dict(tag=None, commit=None, notes="No code change."),
    execution={"op-mainnet": [dict(what="015: Foundation (via DeputyGuardianModule) -> OptimismPortal.setRespectedGameType(1); respectedGameTypeUpdatedAt = 0x66bf9c0f", block=20543021, utc="2024-08-16 18:35:59", tx="0x493e2f3354e8c6c46fb37925a13c02364c1f3b38f88548b9bb4673e3fc762e69")],
               "ink": "n/a (not yet deployed)", "soneium": "n/a", "unichain": "n/a"},
    chain_set=["op-mainnet"],
    changed_l1=["none"], changed_l2_clients=["op-proposer switched to permissioned games"], initializers=["none"],
    storage_headline=["Portal slot 59: respectedGameType 0 -> 1 and timestamp bump"],
    roles=["DeputyGuardianModule used in production"],
    dispute=["Permissionless CANNON games created before this point stop being usable for withdrawals; they still resolve and pay bonds through DelayedWETH gen1"],
    invalidated=["ALL in-progress withdrawal proofs (games must be of the respected type and created after respectedGameTypeUpdatedAt)"],
    audits=["n/a"], skipped_alternate=["Reverted by U10 task 019 on 2024-09-11."], cannot_matter=None,
    evidence=["CALL(op) portal.respectedGameType(), respectedGameTypeUpdatedAt()", "OPS-OLD 015-fallback-permissioned-game", "TASKS"],
)

# --------------------------------------------------------------------------------------------- U10
node(
    id="U10", order=14, title="Upgrade #10 — Granite (hardfork + fault-proof contract fixes)",
    proposal=dict(number="10", name="Upgrade Proposal #10: Granite Network Upgrade", url=GOV + "8733"),
    classification="hardfork + contracts (dispute system only)",
    release=dict(tag="op-contracts/v1.6.0", commit="33f06d2d5e4034125df02264a5ffe84571bd0359",
                 notes="Lightweight tag = rc.3; a merge commit of a release-proposal branch (2024-08-23). Only the dispute contracts of this tree were deployed; its OptimismPortal2 3.11.0-beta.2 / SystemConfig 2.3.0-beta.2 are betas that never reached a proxy."),
    execution={"op-mainnet": [dict(what="DelayedWETH gen2 proxies created (permissionless 0x82511d49..., permissioned 0x9F9b897e..., implementation 1.1.0)", block="20637593-20637604", utc="2024-08-29 23:43..23:45", tx="0xd9f9b3f7..., 0xb1757756..., 0xb5cf8f61..., 0x25ff1420..."),
                              dict(what="016: ProtocolVersions 8.0.0", block=20714426, utc="2024-09-09 17:04:23", tx="0x804fd189aad5c2caccf274235649905f0dd18c8a4f34c58ce471176fec3e34b7"),
                              dict(what="018: gameImpls(0) -> 0xA6f3DFdb..., gameImpls(1) -> 0x050ed6F6... (version 1.3.0, prestate 0x038512e0...); AnchorStateRegistry gen1 proxy upgraded IN PLACE 1.0.0 -> 2.0.0 (0x1B5CC028...) through a StorageSetter, superchainConfig slot set", block=20723924, utc="2024-09-11 00:54:59", tx="0x3bd2d811d0298313e6fb75f0e69fb54280c9b4f2e60f8f04472aaa166c285641"),
                              dict(what="Granite activation, L2 timestamp 1726070401 (OP Mainnet L2 block 125235812)", block=None, utc="2024-09-11 16:00:01", tx=None),
                              dict(what="019 (Security Council Safe): respectedGameType 1 -> 0 (updatedAt 0x66e1c083); DeputyGuardianModule 0x5dC91D01... replaced by 0xc6901F65... (adds setAnchorState)", block=20728464, utc="2024-09-11 16:08:35", tx="0x592e73fdf57e7cc2c51cfaafa891fe91164d125b7943aa26a15285276de27509"),
                              dict(what="020: SystemConfig gas limit 30M -> 60M (later 40M on 2025-05-22)", block=21023675, utc="2024-10-22 21:02:23", tx="0x14ac2b3612fa27ac89f31d1d2174b4436c19b6721f1ecefce89b1f17c7be5e3c")],
               "ink": "genesis-included (Granite active from genesis; genesis PermissionedDisputeGame is 1.3.1-beta.3 with the op-program 1.3.1 prestate 0x038512e0...)",
               "soneium": "genesis-included (same beta game version at genesis)", "unichain": "genesis-included"},
    chain_set=["op-mainnet"],
    changed_l1=["FaultDisputeGame / PermissionedDisputeGame 1.2.0 -> 1.3.0, MIPS 1.0.1 -> 1.1.0, PreimageOracle 1.0.0 -> 1.1.2 (new singletons)", "DelayedWETH 1.0.0 -> 1.1.0 as NEW proxies (gen2); gen1 proxy left at 1.0.0",
                "AnchorStateRegistry gen1: implementation 1.0.0 -> 2.0.0 in place (the object games created since 2024-05-16 point at)", "DeputyGuardianModule 1.1.0 -> 2.0.0",
                "NOT changed: OptimismPortal2 (3.10.0), SystemConfig, messenger, bridges, DisputeGameFactory"],
    changed_l2_clients=["bn256Pairing input limit 112687 bytes, channel timeout 300 -> 50; op-program 1.3.1"],
    initializers=["AnchorStateRegistry (gen1) re-initialized with superchainConfig via StorageSetter (`initializer`)"],
    storage_headline=["ASR gen1: new superchainConfig slot; anchors mapping preserved"],
    roles=["Guardian / DeputyGuardian may set the anchor state to an existing resolved game"],
    dispute=["Absolute prestate -> 0x038512e02c4c3f7bdaec27d00edf55b7155e0905301e1a88083e4e0a6764d54c (op-program 1.3.1)",
             "Respected type history on OP Mainnet: 0 (2024-06-10) -> 1 (2024-08-16) -> 0 (2024-09-11)"],
    invalidated=["Second and third global proof invalidation: every proof made before 2024-08-16 18:35:59 (fallback) and every proof made against permissioned games before 2024-09-11 16:08:35 (re-enable)"],
    audits=["2024-08 Cantina — Fault proof MIPS: MIPS.sol", "2024-08 Spearbit — Fault proof no-MIPS: All contracts in the packages/contracts-bedrock/src/dispute directory",
            "(the proposal also cites a Code4rena review; no row in the index table)"],
    skipped_alternate=["The proposal lists the fixed audit items; this file deliberately does not restate them (Track A)."],
    cannot_matter=None,
    evidence=["GAMES(op)", "evidence/F2-impl-history-op-mainnet-legacy-dispute-proxies.json", "CALL(op)", "OPS-OLD 018-granite-upgrade, 019-permissionless-games+upgrade-dgm", "GOV 8733"],
)

# --------------------------------------------------------------------------------------------- U11
node(
    id="U11", order=15, title="Upgrade #11 — Holocene",
    proposal=dict(number="11", name="Upgrade Proposal #11: Holocene Network Upgrade", url=GOV + "9313"),
    classification="hardfork + contracts (SystemConfig, MIPS, games)",
    release=dict(tag="op-contracts/v1.8.0", commit="2073f4059bd806af3e8b76b820aa3fa0b42016d0",
                 notes="Annotated tag created 2025-01-10 (after activation) on the rc.4 commit of 2024-12-16. There is no v1.7.0 release (only 'v.1.7.0-beta.1+l2-contracts', a typo-named L2-genesis tag) and v1.9.0 exists only as rc.1..rc.3. "
                       "Released contracts: MIPS 1.2.1, FaultDisputeGame/PermissionedDisputeGame 1.3.1, SystemConfig 2.3.0; everything else in the tree is beta and was not deployed."),
    execution={"op-mainnet": [dict(what="DelayedWETH gen3 proxies created (0x323dFC63... permissionless, 0x21429aF6... permissioned; implementation 1.1.0)", block="21379267-21379272", utc="2024-12-11 12:29..12:30", tx="0x70859ae1..., 0x6b9ad25c..., 0xdf99e2d8..., 0x01fcf030..."),
                              dict(what="021: ProtocolVersions 9.0.0", block=21573148, utc="2025-01-07 14:20:11", tx="0x0c3cf835020aabd0d584a4f64f3f463edb9953c39504a1bf2f108024c327eb14"),
                              dict(what="022: gameImpls(0) -> 0x27B81db4..., gameImpls(1) -> 0x91a66189... (1.3.1, prestate 0x03f89406..., MIPS 1.2.1 0x5fE03a12...)", block=21580854, utc="2025-01-08 16:08:47", tx="0x22ab07b0bb1bc8504256835d555307ff522b78651dca33c9cd5b05591ca5b4f7"),
                              dict(what="Holocene activation, L2 timestamp 1736445601 (OP Mainnet L2 block 130423412)", block=None, utc="2025-01-09 18:00:01", tx=None),
                              dict(what="028: SystemConfig 2.2.0 -> 2.3.0 on op/metal/mode/zora/arena-z, FIFTEEN DAYS AFTER activation: ProxyAdmin.upgrade(StorageSetter) -> setBytes32(0,0) -> upgradeAndCall(initialize)", block=21695024, utc="2025-01-24 14:41:35", tx="0x86da7386a26978c3db89e97c1f4feee613a8a0c07bbe4640624b05276f49c350")],
               "ink": "DIFFERENT: Holocene activated 2025-03-19 15:00:00 (holocene_time 1742396400). The SystemConfig 2.3.0 step was NEVER executed (2.2.0 -> 2.4.0 at U13). The Holocene game implementations came with the Pectra prestate in one task (ink-003, 2025-03-17, L1 block 22069032).",
               "soneium": "DIFFERENT: Holocene activated 2025-02-03 09:00:00 (1738573200); SystemConfig 2.3.0 on 2025-02-28 (L1 block 21945575, task 030); permissioned game kept its genesis implementation until U13",
               "unichain": "Holocene at the superchain time; SystemConfig 2.3.0 only on 2025-03-19 (L1 block 22081789, task unichain-001), ten weeks after activation"},
    chain_set=["op-mainnet, metal, mode, zora, arena-z (task 028); base (029); soneium (030); unichain (unichain-001)"],
    changed_l1=["SystemConfig 2.2.0 -> 2.3.0 (setEIP1559Params, new fee-scalar setters)", "FaultDisputeGame/PermissionedDisputeGame 1.3.0 -> 1.3.1, MIPS 1.1.0 -> 1.2.1", "DelayedWETH gen3 proxies (still implementation 1.1.0)",
                "NOT changed: OptimismPortal2, messenger, bridges, DGF, ASR gen1"],
    changed_l2_clients=["Holocene derivation (strict batch ordering, partial span batch validity, fast channel invalidation, steady block derivation), EIP-1559 params in block extraData; op-program 1.4.0"],
    initializers=["SystemConfig.initialize(...) re-run after zeroing slot 0 with a StorageSetter (`initializer`), preserving parameters; basefeeScalar/blobbasefeeScalar storage populated (OP Mainnet: 5227 / 1014213)"],
    storage_headline=["SystemConfig: basefeeScalar + blobbasefeeScalar packed next to gasLimit; eip1559Denominator/eip1559Elasticity slot (zero until the owner calls setEIP1559Params)"],
    roles=["none"],
    dispute=["Absolute prestate -> 0x03f89406817db1ed7fd8b31e13300444652cdb0b9c509a674de43483b2f83568 (op-program 1.4.0, cannon32)"],
    invalidated=["none"],
    audits=["2024-10 3Doc Security — Fault proof MIPS: MIPS.sol (2024_10-Cannon-FGETFD)"],
    skipped_alternate=["Per-chain divergence: Ink skipped the SystemConfig re-initialization entirely; Soneium, Unichain and OP Mainnet ran it 15 to 70 days after their Holocene activation."],
    cannot_matter=None,
    evidence=["IMPL(op) SystemConfig block 21695024", "IMPL(ink|soneium|unichain) SystemConfig", "GAMES(op)", "OPS-OLD 022, 028, 030, unichain-001, ink-003", "REG ink.toml/soneium.toml", "GOV 9313"],
)

# --------------------------------------------------------------------------------------------- U12
node(
    id="U12", order=16, title="Upgrade #12 — L1 Pectra readiness",
    proposal=dict(number="12", name="Upgrade Proposal #12: L1 Pectra Readiness", url=GOV + "9706"),
    classification="maintenance (node software + absolute prestate; no L1 contract code change)",
    release=dict(tag=None, commit=None, notes="No op-contracts tag. Components: op-geth v1.101500.0, op-node v1.11.0/1.11.1, op-program v1.5.0-rc.2 (later 1.5.0 = prestate 0x039facea...), kona v0.1.0-beta.9, op-challenger v1.3.1."),
    execution={"op-mainnet": "NO dedicated L1 transaction: task 031-op-mainnet-pectra-defense is 'DRAFT, NOT READY TO SIGN' at superchain-ops cccb99f8 and gameImpls(0)/(1) do not change between 2025-01-08 (U11) and 2025-04-02 (U13). "
                             "The Pectra-ready prestate 0x039facea... reached OP Mainnet as the U13 prestate. (The draft would have used OPPrestateUpdater 0x6E34d06b... with prestate 0x035ac388... = 1.5.0-rc.2.)",
               "ink": [dict(what="ink-003: gameImpls(0) -> 0x7e87B471..., (1) -> 0x8D9faaEb... (1.3.1) with prestate 0x039facea... (Holocene + Pectra in one step) and new DelayedWETH proxies", block=22069032, utc="2025-03-17 20:36:23", tx="0xd80b96282ad4d71aeb29b25e0ceee2bdf0840b258fccffedc951ce0553b6800b")],
               "soneium": "via U13 (2025-04-02)", "unichain": "via U13 (2025-04-12)"},
    chain_set=["all OP Stack chains (node software); L1 prestate updates per chain"],
    changed_l1=["none on OP Mainnet"], changed_l2_clients=["EIP-7702 type-4 transactions excluded from batch sources; L1 header requestsHash; op-program/kona updated before L1 Pectra (mainnet 2025-05-07)"],
    initializers=["none"], storage_headline=["none"], roles=["none"],
    dispute=["Prestate 1.5.0 (cannon32) 0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9 — on OP Mainnet first used by the U13 games"],
    invalidated=["none"], audits=["no row in the index table (the proposal cites an FMA)"],
    skipped_alternate=["On OP Mainnet this numbered upgrade has NO on-chain node of its own; it is an edge label on U13."],
    cannot_matter=None,
    evidence=["CALL(op) dgf.gameImpls(0)/(1)", "GAMES(ink)", "OPS-OLD 031-op-mainnet-pectra-defense, ink-003-fp-holocene-pectra-upgrade", "REG standard-prestates.toml", "GOV 9706"],
)

# --------------------------------------------------------------------------------------------- U13
node(
    id="U13", order=17, title="Upgrade 13 — OPCM and incident response improvements",
    proposal=dict(number="13", name="Upgrade Proposal #13: OPCM and Incident Response improvements", url=GOV + "9739"),
    classification="contracts-only (first OPCM upgrade)",
    release=dict(tag="op-contracts/v2.0.0", commit="8d0dd96e494b2ba154587877351e87788336a4ec",
                 notes="Lightweight tag = rc.1 ('do not alias 7702 addresses', 2025-02-25). OPCM 0x026b2F158255Beac46c1E7c6b8BbF29A4b6A7B76 (OPContractsManager semver 1.6.0). "
                       "LATER MAINTENANCE TAGS ON THIS LINE: v2.1.0 (e45b33a0, 2025-08-14, OPCM '1.6.0-no-superchain-upgrade') and v2.2.0 (7fe5151a, 2025-08-15, OPCM 1.7.0) were created AFTER v3.0.0 and v4.0.0 so that chains still on v1.8.0 could run the U13 step without upgrading a shared SuperchainConfig/ProtocolVersions; identical L1 contract versions."),
    execution={"op-mainnet": [dict(what="000: OPCM.upgrade for OP Mainnet + Soneium + Ink (one transaction, DELEGATECALL from 0x5a0Aae59...)", block=22182531, utc="2025-04-02 16:50:23", tx="0x5f3530e593bbac37c61dc5b7755b6a40c06c20c1a3a1b13fca5b7d00cde65c29"),
                              dict(what="007: DelayedWETH gen3 owner Foundation Operations Safe -> ProxyAdmin owner", block=22349174, utc="2025-04-25 22:58:35", tx="0x0fa256d2f49d9bf94abf6bfcd3defcbb29dcd2edeb1e3750a68c3fa7993aea95"),
                              dict(what="011: DeputyPauseModule 1.0.0-beta.2 (0x126a736B...) enabled on the Foundation Operations Safe", block=22432200, utc="2025-05-07 13:58:11", tx="0x5580a50fd248f0d4034f5eb270636202e2d957b84a6975f7bd7b8c72ff541233"),
                              dict(what="Mainnet Superchain-wide pause test: SuperchainConfig Paused('Deputy...') ... Unpaused() (012). Every L1 bridge of every chain sharing 0x95703e09... was paused for 10 min 36 s.", block="22482108 .. 22482160", utc="2025-05-14 14:50:59 .. 15:01:35", tx="0x343257f790de... / 0x758b4196114928b4e43c2f3b6d65e0737dde9f1ed6f346eac16843f5fd3fac74")],
               "ink": "same transaction as OP Mainnet (block 22182531). Ink arrives from SystemConfig 2.2.0 and from the ink-003 games.",
               "soneium": "same transaction as OP Mainnet (block 22182531); permissioned only",
               "unichain": [dict(what="002: OPCM.upgrade for Unichain, executed by its own 3-of-3 PAO 0x6d5B183F..., ten days later", block=22254924, utc="2025-04-12 19:18:59", tx="0x7e5e478cafbe30293645e6972a477f77dcfdc006c4cf1dd248a94e6386d04159")]},
    chain_set=["op-mainnet, soneium, ink (000); unichain (002); base (own task)"],
    changed_l1=["OptimismPortal2 3.10.0 -> 3.13.0", "SystemConfig 2.3.0 -> 2.4.0 (Ink: 2.2.0 -> 2.4.0)", "L1CrossDomainMessenger 2.3.0 -> 2.5.0", "L1StandardBridge 2.1.0 -> 2.2.2", "L1ERC721Bridge 2.1.0 -> 2.3.1",
                "OptimismMintableERC20Factory 1.9.0 -> 1.10.1", "DisputeGameFactory 1.0.0 -> 1.0.1", "SuperchainConfig 1.1.0 -> 1.2.0", "ProtocolVersions 1.0.0 -> 1.1.0",
                "NEW AnchorStateRegistry proxy per chain (gen2; OP Mainnet 0x1c68ECfb..., implementation 2.2.2); gen1 is orphaned",
                "DelayedWETH gen3 proxies upgraded IN PLACE 1.1.0 -> 1.3.0 (hold() now also transfers); gen1/gen2 untouched",
                "FaultDisputeGame / PermissionedDisputeGame 1.3.1 -> 1.4.1 (bond refunding, wasRespectedGameTypeWhenCreated), MIPS 1.2.1 -> 1.3.0",
                "CustomGasToken (v1) logic removed from the L1 contracts; deposit sender aliasing changed for EIP-7702"],
    changed_l2_clients=["op-dispute-mon v1.4.0 required; no node change"],
    initializers=["New AnchorStateRegistry proxies: initialize(superchainConfig, disputeGameFactory, portal, startingAnchorRoot) [initializer]; the other proxies are upgraded without re-initialization (SuperchainConfig log shows only Upgraded at block 22182531)"],
    storage_headline=["ASR gen2: one unified anchor (root + l2BlockNumber at slots 4/5) instead of one per game type", "Portal: respectedGameTypeUpdatedAt no longer bumped by setRespectedGameType (special input type(uint32).max bumps it)"],
    roles=["DeputyPauseModule lets a Foundation 'pause deputy' key trigger the global pause", "DelayedWETH gen3 owner -> ProxyAdmin owner (2025-04-25)", "OPCM itself holds no role (delegatecalled by the ProxyAdmin owner)"],
    dispute=["Absolute prestate -> 0x039facea... (op-program 1.5.0, cannon32; = the U12 Pectra prestate)", "AnchorStateRegistry.setAnchorState only by a finalized game of the respected type; anchor unified across types"],
    invalidated=["One-time invalidation of ALL pending withdrawal proofs. Mechanism (source, v2.0.0 OptimismPortal2.sol:556): checkWithdrawal does `try game.wasRespectedGameTypeWhenCreated()`; games created by pre-U13 implementations do not have that getter and are treated as not respected. "
                 "The portal's respectedGameTypeUpdatedAt was NOT changed (still 0x66e1c083 until U16)."],
    audits=["2024-12 MiloTruck (independent) — DeputyPauseModule", "2024-12 Radiant Labs — DeputyPauseModule", "2025-01 Offbeat Labs — Incident Response Improvements", "2025-02 Spearbit — Upgrade 13"],
    skipped_alternate=["Chains that had not done this step by August 2025 use v2.1.0 / v2.2.0 instead (not the four chains)."],
    cannot_matter=None,
    evidence=["IMPL(op|ink|soneium|unichain)", "GAMES(*)", "evidence/F2-impl-history-op-mainnet-legacy-dispute-proxies.json", "evidence/F2-superchainconfig-logs.json", "OPS 000, 002, 007, 011, 012", "GOV 9739", "NOTICE upgrade-13"],
)

# --------------------------------------------------------------------------------------------- U14
node(
    id="U14", order=18, title="Upgrade 14 — Isthmus L1 contracts + MT-Cannon",
    proposal=dict(number="14", name="Upgrade Proposal #14: Isthmus L1 Contracts + MT-Cannon", url=GOV + "9796"),
    classification="contracts-only",
    release=dict(tag="op-contracts/v3.0.0", commit="ef7a933ca7f3d27ac40406f87fea25e0c3ba2016",
                 notes="Lightweight tag = rc.2 (2025-03-13). OPCM 0x3a1f523a4bc09cd344a2745a108bb0398288094f (OPContractsManager semver 1.9.0 — superchain-ops comments call it 'v1.9.0', which is the OPCM contract version, not a release). "
                       "v3.0.1 (48e36d5c, 2025-09-22) was created after v4.0.0/v4.1.0 and only changes DeployOPChain.s.sol."),
    execution={"op-mainnet": [dict(what="003: OPCM.upgrade for OP Mainnet + Soneium + Ink", block=22339996, utc="2025-04-24 16:16:23", tx="0xbe44244e352a9ffa67ad7f7133e9ed014b380e4b1bd789419e6d33aaad780d12")],
               "ink": "same transaction (block 22339996)", "soneium": "same transaction (block 22339996)",
               "unichain": [dict(what="005: OPCM.upgrade for Unichain (own PAO)", block=22342667, utc="2025-04-25 01:12:11", tx="0xc74c5e0dddfa9e2d0fd5d902fb7b1aa4cc28ba034ebed7bf3a0aa3a8b8d21b20")]},
    chain_set=["op-mainnet, soneium, ink (003); unichain (005); base, mode, zora, arena-z, swell, metal announced"],
    changed_l1=["OptimismPortal2 3.13.0 -> 3.14.0", "SystemConfig 2.4.0 -> 2.5.0 (operatorFeeScalar / operatorFeeConstant)", "L1CrossDomainMessenger 2.5.0 -> 2.6.0", "L1StandardBridge 2.2.2 -> 2.3.0", "L1ERC721Bridge 2.3.1 -> 2.4.0",
                "MIPS (32-bit) replaced by MIPS64 1.0.0; new FaultDisputeGame/PermissionedDisputeGame deployments (still 1.4.1) pointing at MIPS64",
                "NOT changed: DGF, SuperchainConfig, OptimismMintableERC20Factory, ASR gen2, DelayedWETH gen3"],
    changed_l2_clients=["op-challenger >= v1.3.1, op-node v1.12.2 (new SystemConfig event), cannon64 op-program 1.5.1-rc.1"],
    initializers=["none visible (implementation swaps)"], storage_headline=["SystemConfig operator-fee slot"], roles=["none"],
    dispute=["Absolute prestate -> 0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405 (op-program 1.5.1-rc.1, first cannon64 / MT-Cannon prestate)"],
    invalidated=["none stated"],
    audits=["2025-01 Spearbit — 64-bit Multithreaded Cannon: MIPS64.sol", "2025-01 Coinbase Protocol Security — Multi-thread & 64-bit Cannon"],
    skipped_alternate=["Executed 22 days after U13; U15a then replaced the prestate 13 days later — on OP Mainnet/Ink/Unichain the 0x03ee2917... games existed for only 13 days. Soneium kept this prestate for 3 months (until U16)."],
    cannot_matter=None,
    evidence=["IMPL(*)", "GAMES(*)", "OPS 003, 005", "GOV 9796", "NOTICE upgrade-14"],
)

# --------------------------------------------------------------------------------------------- U15
node(
    id="U15", order=19, title="Upgrade 15 — Isthmus hardfork",
    proposal=dict(number="15", name="Upgrade Proposal #15 - Isthmus Hard Fork", url=GOV + "9804"),
    classification="hardfork",
    release=dict(tag=None, commit=None, notes="No op-contracts release of its own (uses U14's L1 contracts). op-node v1.13.2, op-geth v1.101503.4, op-batcher v1.12.0, op-challenger v1.4.0."),
    execution={"op-mainnet": [dict(what="Isthmus activation, L2 timestamp 1746806401 = OP Mainnet L2 block 135603812 (L1Block 1.2.0 -> 1.6.0, GasPriceOracle 1.3.0 -> 1.4.0, OperatorFeeVault predeploy)", block=None, utc="2025-05-09 16:00:01", tx=None)],
               "ink": "same timestamp", "soneium": "same timestamp", "unichain": "same timestamp"},
    chain_set=["all superchain-inheriting chains"],
    changed_l1=["none (requires U14)"],
    changed_l2_clients=["Pectra EIPs on L2 (7702, 2537, 2935, 7623); L2ToL1MessagePasser storage root written to the block header withdrawalsRoot; operator fee; EIP-2935 history contract"],
    initializers=["none"], storage_headline=["L2 header field withdrawalsRoot is re-purposed: from Isthmus on it equals the message-passer storage root (output-root component)"],
    roles=["none"], dispute=["Needs a prestate that knows the activation time -> U15a"], invalidated=["none"], audits=["no row in the index table"],
    skipped_alternate=["Ratified 'contingent upon' a follow-up maintenance proposal (U15a) carrying the activation time."],
    cannot_matter=None,
    evidence=["evidence/F2-impl-history-op-mainnet-L2-predeploys.json", "hardfork registry isthmus.mdx", "NOTICE upgrade-15", "GOV 9804"],
)

node(
    id="U15a", order=20, title="Upgrade 15a — absolute prestate for Isthmus activation + blob-preimage fix",
    proposal=dict(number="15a", name="Upgrade Proposal #15a - Absolute Prestate Updates for Isthmus Activation & Blob Preimage Fix", url=GOV + "9869"),
    classification="maintenance (prestate rotation through OPCM.updatePrestate)",
    release=dict(tag=None, commit=None, notes="No new op-contracts tag: re-uses the v3.0.0 OPCM 0x3a1f523a... (function updatePrestate). op-program 1.6.0-rc.2."),
    execution={"op-mainnet": [dict(what="009: OPCM(v3.0.0).updatePrestate for OP Mainnet + Ink: new FaultDisputeGame 0x89d68b1d... / PermissionedDisputeGame 0xa1e0bacd... registered", block=22432368, utc="2025-05-07 14:33:23", tx="0xc4a7089a92c96b83475a7c20e40b4c888a277a90208d649c81df243ecdceb587")],
               "ink": "same transaction (block 22432368)",
               "soneium": "NOT EXECUTED: gameImpls(1) unchanged between 2025-04-24 and 2025-07-24 — Soneium's permissioned game ran the U14 prestate 0x03ee2917... across the Isthmus activation",
               "unichain": [dict(what="010: updatePrestate for Unichain (own PAO)", block=22432925, utc="2025-05-07 16:28:47", tx="0xd3247421f6f8039ab186878aa996984a67b3149dd543e688b1d30236516eba00")]},
    chain_set=["op-mainnet, ink (009); unichain (010); base (own task); NOT soneium"],
    changed_l1=["DisputeGameFactory.gameImpls(0),(1) only (FaultDisputeGame/PermissionedDisputeGame 1.4.1 redeployed with a new prestate; same ASR gen2, same DelayedWETH gen3)"],
    changed_l2_clients=["op-program 1.6.0 (Isthmus activation time for the listed chains + blob preimage handling fix)"],
    initializers=["none"], storage_headline=["DGF gameImpls"], roles=["none"],
    dispute=["Absolute prestate -> 0x03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6 (op-program 1.6.0-rc.2, cannon64)"],
    invalidated=["none (games in flight keep their prestate)"],
    audits=["2025-04 Aleph_v (independent) — op-program and op-challenger blob preimage handling"],
    skipped_alternate=["Skipped on Soneium."],
    cannot_matter=None,
    evidence=["CALL(op|ink|soneium|unichain) dgf.gameImpls", "GAMES(*)", "OPS 009, 010", "GOV 9869"],
)

# --------------------------------------------------------------------------------------------- U16
node(
    id="U16", order=21, title="Upgrade 16 — Interop contracts, Stage 1, Go 1.23 in Cannon",
    proposal=dict(number="16", name="Upgrade 16 Proposal: Interop Contracts, Stage 1, and Go 1.23 Support in Cannon", url=GOV + "10037"),
    classification="contracts-only",
    release=dict(tag="op-contracts/v4.0.0", commit="54c19f6acb7a6d3505f884bae601733d3d54a3a6",
                 notes="Lightweight tag = rc.8 (2025-06-11). OPCM 0x56ebc5c4870f5367b836081610592241ad3e0734 (OPContractsManager semver 2.4.0)."),
    execution={"op-mainnet": [dict(what="017: OPCM.upgrade for OP Mainnet + Ink. Portal ETH 236,752.2431 -> 0; new ETHLockbox 0x322b47Ff... holds 236,752.2431 ETH (balances at blocks 22990598/22990599)", block=22990599, utc="2025-07-24 17:47:23", tx="0x46acdce174c8d83ebe2f208d8c76c867e75617483d64c3e407f69ae2f9868716"),
                              dict(what="016 + 020: DeputyPauseModule 2.1.0 (0x76fc2f97...) enabled on the Guardian Safe; DeputyGuardianModule 0xc6901F65... removed", block=22990706, utc="2025-07-24 18:08:59", tx="0x7e5703b1ab5d09aa107aa1a5fb2c7808c32023bd76048c192139bdb9b5dda092"),
                              dict(what="021: old DeputyPauseModule 0x126a736B... removed from the Foundation Operations Safe", block=22990723, utc="2025-07-24 18:12:23", tx="0xd770166ff63183dae868ca11852268115035d2f74574b55b8e1ecd552da80378")],
               "ink": "same transaction as OP Mainnet (block 22990599); 6,020.6105 ETH moved portal -> lockbox 0xbd4AbB32...",
               "soneium": [dict(what="018: OPCM.upgrade for Soneium; 8,877.0509 ETH moved portal -> lockbox 0x67B4de6F...", block=22990670, utc="2025-07-24 18:01:35", tx="0xdd89a3933dea0f44e1a461441f3c78e341702e9a4148784780644cdac90148c2")],
               "unichain": [dict(what="019: OPCM.upgrade for Unichain (own PAO); 133,613.2483 ETH moved portal -> lockbox 0x08bA0023...", block=22990722, utc="2025-07-24 18:12:11", tx="0x1f1f283ad793a901a94e11241d46b87cd264b2e276a690b9554148ba56c57959")]},
    chain_set=["op-mainnet, ink, soneium, unichain — exactly the four chains of this hunt. Base and the other governed chains did NOT execute U16."],
    changed_l1=["OptimismPortal2 3.14.0 -> 4.6.0 (ASR is the source of truth for game validity; ETH custody moved out; super-root prove path present but disabled)", "SystemConfig 2.5.0 -> 3.4.0 (superchainConfig, proxyAdmin, l2ChainId; MAX_GAS_LIMIT 200M -> 500M; pause read through SystemConfig)",
                "L1CrossDomainMessenger 2.6.0 -> 2.9.0", "L1StandardBridge 2.3.0 -> 2.6.0", "L1ERC721Bridge 2.4.0 -> 2.7.0", "DisputeGameFactory 1.0.1 -> 1.2.0", "SuperchainConfig 1.2.0 -> 2.3.0 (per-identifier pause with 3-month expiry)",
                "NEW ETHLockbox proxy per chain (1.2.0)", "NEW AnchorStateRegistry proxy per chain (gen3, 3.5.0; OP Mainnet 0x23B2C629...); gen2 orphaned",
                "NEW DelayedWETH proxies (gen4, 1.5.0, no owner — controlled by the ProxyAdmin owner)", "FaultDisputeGame/PermissionedDisputeGame 1.4.1 -> 1.7.0, MIPS64 1.0.0 -> 1.4.0-patch.2 (tree value)",
                "DeputyGuardianModule removed; DeputyPauseModule 2.1.0 on the Guardian Safe"],
    changed_l2_clients=["op-challenger v1.5.1; op-program 1.6.1-rc.1 (Go 1.23)"],
    initializers=["New regime: ReinitializableBase + ProxyAdminOwnedBase. initVersion 2 for OptimismPortal2 / SystemConfig / L1CDM / bridges / SuperchainConfig, 1 for ETHLockbox / DGF / ASR / DelayedWETH. "
                  "Existing proxies run `upgrade(...)` (reinitializer(2)); new proxies run `initialize(...)`. SuperchainConfig emitted Initialized(2)."],
    storage_headline=["Portal: anchorStateRegistry + ethLockbox slots; superchainConfig no longer read from the portal's own slot (resolved through SystemConfig)", "SystemConfig: superchainConfig stored (later packed with minBaseFee at slot 0x6c)",
                      "ASR gen3: retirementTimestamp = execution timestamp (OP Mainnet 0x688271ab = 1753379243); portal.respectedGameTypeUpdatedAt() now returns that value",
                      "ETH custody: 100% of each portal's balance moved to its lockbox in the upgrade transaction"],
    roles=["Foundation can no longer act as guardian (DeputyGuardianModule removed); it keeps only a time-bounded pause via DeputyPauseModule", "Pause is per identifier (address) or global, expires after 3 months, re-arming needs the guardian",
           "initialize/upgrade callable only by the ProxyAdmin or its owner", "DelayedWETH has no owner variable any more"],
    dispute=["Absolute prestate -> 0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8 (op-program 1.6.1-rc.1)",
             "ALL games created at or before the execution timestamp are retired by ASR.retirementTimestamp; this is the lower bound of every game that can still be claim-valid today"],
    invalidated=["One-time invalidation of ALL withdrawal proofs (stated in the proposal; mechanism: new ASR with retirementTimestamp = now)"],
    audits=["2025-03 Spearbit — Interop Contracts", "2025-03 Wonderland — Interop Portal Contracts (u16)", "2025-04 Cantina (contest) — Interop Portal Contracts (u16)", "2025-05 Spearbit — Interop Portal Contracts (u16)",
            "2025-05 Coinbase Protocol Security — Cannon updates to support Go 1.23 and Kona", "2025-06 Spearbit — Cannon Go 1.23 support fix review", "2025-05 Spearbit — Upgrade 16", "2025-07 Spearbit — VerifyOPCM"],
    skipped_alternate=["BRANCH POINT: chains on U16 keep the ETHLockbox through U16a..U20; chains that skipped U16 (Base, Zora, Metal, Mode, Arena-Z, Swell: tasks 025-029 'u13-to-u16a') have no lockbox until U21. "
                       "The U16 notice says the super-root prove path 'will be enabled in Upgrade 17'; it was removed again by U16a."],
    cannot_matter=None,
    evidence=["IMPL(*)", "CALL(*) portal.ethLockbox(), portal.anchorStateRegistry()", "cast balance <portal|lockbox> at execution block and block-1 (in workers/F2-report.md)", "evidence/F2-superchainconfig-logs.json", "OPS 016-021", "GOV 10037", "NOTICE upgrade-16"],
)

node(
    id="U16a", order=22, title="Upgrade 16a — maintenance release superseding U16",
    proposal=dict(number="16a", name="Maintenance Upgrade Proposal: U16a", url=GOV + "10288"),
    classification="maintenance (contracts-only)",
    release=dict(tag="op-contracts/v4.1.0", commit="594bc933a38425f745b46399a3619bcdeb74965d", notes="Lightweight tag = rc.3 (2025-09-17). OPCM 0x8123739c1368c2dedc8c564255bc417feeebff9d (semver 3.2.0); supports U15 -> U16a and U16 -> U16a."),
    execution={"op-mainnet": [dict(what="023: OPCM.upgrade for OP Mainnet + Soneium + Ink", block=23491328, utc="2025-10-02 16:35:23", tx="0x744cf7d28324729cace731ac736872da669439a0d380f1f52b8d31af203f7329")],
               "ink": "same transaction", "soneium": "same transaction",
               "unichain": [dict(what="024: OPCM.upgrade for Unichain (own PAO)", block=23492571, utc="2025-10-02 20:45:59", tx="0xc98240172fa3950ec9c62f32cc09d0eb0ed21684b02f1b2677357674cda64ca5")]},
    chain_set=["op-mainnet, soneium, ink (023); unichain (024); base (own); zora/metal/mode/arena-z/swell via 'u13-to-u16a' tasks 025-029 (2025-10-09/14)"],
    changed_l1=["OptimismPortal2 4.6.0 -> 5.0.0 (interop withdrawal-proving code removed)", "SystemConfig 3.4.0 -> 3.7.0 (feature flags; ETH_LOCKBOX is the first)", "L1CrossDomainMessenger 2.9.0 -> 2.10.0", "L1StandardBridge 2.6.0 -> 2.7.0",
                "L1ERC721Bridge 2.7.0 -> 2.8.0", "NEW DelayedWETH proxies (gen5; same implementation 1.5.0) and new game implementations (1.7.0, same prestate)", "NOT changed: DGF, ASR gen3, ETHLockbox, SuperchainConfig"],
    changed_l2_clients=["op-challenger v1.5.1 (cannon v1.6.0)"],
    initializers=["initVersion 3 for OptimismPortal2 (`upgrade(anchorStateRegistry)`), SystemConfig, L1CDM, bridges. initVersion stays 3 from here through v9.0.0."],
    storage_headline=["SystemConfig feature bitmap; ETH_LOCKBOX set for chains that already have a lockbox"],
    roles=["none"], dispute=["Prestate unchanged (0x03eb0710...); new game implementation addresses and new DelayedWETH proxies"],
    invalidated=["None for U16 chains ('withdrawal proofs created under U16 remain valid'). Chains coming from U15 get the U16-style invalidation."],
    audits=["2025-09 Spearbit — U16a"],
    skipped_alternate=["Two entry paths into the same code: U16 -> U16a (lockbox, the four chains) and U15 -> U16a (no lockbox)."],
    cannot_matter=None,
    evidence=["IMPL(*)", "GAMES(*)", "OPS 023, 024, 025-029", "GOV 10288", "NOTICE upgrade-16a"],
)

# --------------------------------------------------------------------------------------------- U17
node(
    id="U17", order=23, title="Upgrade 17 — Jovian hardfork and Fusaka readiness",
    proposal=dict(number="17", name="Upgrade 17 - Jovian Hardfork and Fusaka Readiness (supersedes '[deprecated] Upgrade 17 Proposal: Jovian Hardfork', topic 10374, whose calldata snippets were incorrect)", url=GOV + "10400"),
    classification="hardfork + contracts",
    release=dict(tag="op-contracts/v5.0.0", commit="d09c836f818c73ae139f60b717654c4e53712743", notes="Lightweight tag = rc.2 (2025-10-24). OPCM 0xfa1ef97fb02b0da2ee2346b8e310907ab5519449 (semver 4.2.0). Side tags v5.0.0+l2-rev-share-contracts and v5.0.0+l2-fee-splitter-contracts are L2-only."),
    execution={"op-mainnet": [dict(what="032: OPCM.upgrade for OP Mainnet + Soneium + Ink", block=23877377, utc="2025-11-25 17:46:35", tx="0xf556934cb4de1ab40a4cfba17856cd601cbc8b875b96a9ccd8ee32bcd363abf5"),
                              dict(what="Jovian activation, L2 timestamp 1764691201 = OP Mainnet L2 block 144546212 (L1Block 1.6.0 -> 1.7.0, GasPriceOracle 1.4.0 -> 1.6.0)", block=None, utc="2025-12-02 16:00:01", tx=None)],
               "ink": "same transaction", "soneium": "same transaction (permissioned)",
               "unichain": [dict(what="035: OPCM.upgrade for Unichain (own PAO)", block=23878509, utc="2025-11-25 21:35:35", tx="0x7c9e6b65258838fb38bc0bf584cb0c0802bc0dfbbe877a8639880e2ed88b3aa6")]},
    chain_set=["op-mainnet, soneium, ink (032); metal/mode/zora (033); arena-z/swell (034); unichain (035); base (own)"],
    changed_l1=["OptimismPortal2 5.0.0 -> 5.1.1", "SystemConfig 3.7.0 -> 3.11.0 (minBaseFee, daFootprintGasScalar)", "L1CrossDomainMessenger 2.10.0 -> 2.11.0", "L1StandardBridge 2.7.0 -> 2.8.0", "L1ERC721Bridge 2.8.0 -> 2.9.0",
                "OptimismMintableERC20Factory 1.10.1 -> 1.10.2", "DisputeGameFactory 1.2.0 -> 1.3.0 (gameArgs getter appears, empty)", "SuperchainConfig 2.3.0 -> 2.4.0", "FaultDisputeGame/PermissionedDisputeGame 1.7.0 -> 1.8.0, MIPS64 -> 1.9.0 (Go 1.24)",
                "NOT changed: ETHLockbox, ASR gen3, DelayedWETH gen5"],
    changed_l2_clients=["min base fee, DA footprint block limit (header blobGasUsed re-purposed), operator-fee formula change; op-program 1.8.0-rc.4 (Jovian + L1 Fusaka: blob verification without KZG proofs, BPO blob schedule)"],
    initializers=["From here on every OPCM upgrade re-runs `initialize` with the UNCHANGED initVersion 3, which requires resetting the initializer slot through a StorageSetter implementation first (visible as Upgraded(StorageSetter) then Upgraded(impl) pairs)"],
    storage_headline=["SystemConfig slot 0x6c packs superchainConfig (low 160 bits) with minBaseFee (upper bits)"],
    roles=["none"],
    dispute=["Absolute prestate -> 0x03caa1871bb9fe7f9b11217c245c16e4ded33367df5b3ccb2c6d0a847a217d1b (op-program 1.8.0-rc.4)"],
    invalidated=["none stated"],
    audits=["2025-06 Radiant Labs — Cannon Go 1.24 support", "2025-10 Spearbit — U17", "(adjacent, L2 only) 2025-10 Spearbit — Revenue sharing and FeeVaults; 2025-11 Spearbit — Safer Safes"],
    skipped_alternate=["A first U17 proposal was deprecated and replaced within a week."],
    cannot_matter=None,
    evidence=["IMPL(*)", "GAMES(*)", "evidence/F2-impl-history-op-mainnet-L2-predeploys.json", "OPS 032, 035", "GOV 10400, 10374", "NOTICE upgrade-17"],
)

# --------------------------------------------------------------------------------------------- U18
node(
    id="U18", order=24, title="Upgrade 18 — Custom Gas Token v2, Cannon+Kona, creator-pattern games",
    proposal=dict(number="18", name="Upgrade 18 - Custom Gas Token v2 and Kona Proofs", url=GOV + "10576"),
    classification="contracts-only",
    release=dict(tag="op-contracts/v6.0.0", commit="018f5ae926ec3277746b56a1c4ddb715c568603d",
                 notes="Annotated tag created 2026-03-16 — five weeks AFTER mainnet execution — on the rc.2 commit of 2026-01-14 (rc.2 = rc.1 L1 contracts + L2-only changes). OPCM 0x50f47b43c24f40b92c873fa0704d4207586d0c9f (semver 6.0.0), the last OPCM v1."),
    execution={"op-mainnet": [dict(what="040: OPCM.upgrade for OP Mainnet, Ink, Metal, Mode, Zora, Arena-Z, Swell", block=24421512, utc="2026-02-09 20:10:59", tx="0x8808cd53114e4cf07bfde30daf24f2984d4a40ab09c5ca67bd171ac29d6dbf37")],
               "ink": "same transaction",
               "soneium": [dict(what="042: OPCM.upgrade for Soneium, eight days later", block=24478557, utc="2026-02-17 19:11:11", tx="0xeba2fc77f814ea5de7fc0e3b1496926483d14cf8541633c04aec9d1fec8eaf9c")],
               "unichain": [dict(what="041: OPCM.upgrade for Unichain (own PAO)", block=24427874, utc="2026-02-10 17:30:23", tx="0x5672a02ba8c40bd35c87787ceddff5181c588e697a1924be6ea061af71cbb4ca")]},
    chain_set=["op-mainnet, ink, metal, mode, zora, arena-z, swell (040); unichain (041); soneium (042); base (own)"],
    changed_l1=["OptimismPortal2 5.1.1 -> 5.2.0", "SystemConfig 3.11.0 -> 3.13.1 (CUSTOM_GAS_TOKEN feature, off)", "DisputeGameFactory 1.3.0 -> 1.4.0", "AnchorStateRegistry gen3 3.5.0 -> 3.7.0",
                "Game implementations become shared clone-with-immutable-args singletons: FaultDisputeGame 0x6ddba09b... (2.2.0) for types 0 AND 8, PermissionedDisputeGame 0x58bf355c... (2.2.0); per-chain parameters move to DisputeGameFactory.gameArgs",
                "NOT changed: L1CrossDomainMessenger (2.11.0), L1StandardBridge, L1ERC721Bridge, OptimismMintableERC20Factory, ETHLockbox, SuperchainConfig, DelayedWETH gen5 (re-used)"],
    changed_l2_clients=["op-challenger v1.9.0, op-dispute-mon v1.5.0, kona-client v1.2.7; no hardfork"],
    initializers=["StorageSetter + initialize(initVersion 3) cycle on the upgraded proxies"],
    storage_headline=["DGF: gameArgs[type] bytes (prestate | vm | asr | weth | l2ChainId [| proposer | challenger])"],
    roles=["none"],
    dispute=["NEW game type 8 CANNON_KONA registered (not respected): prestate 0x0323914d3050e80c3d09da528be54794fde60cd26849cd3410dde0da7cd7d4fa (kona-client 1.2.7) — NOT present in superchain-registry standard-prestates.toml at edd89bd1",
             "Type 0 prestate -> 0x033c000916b4a88cfffeceddd6cf0f4be3897a89195941e5a7c3f8209b4dbb6e (op-program 1.9.0-rc.1)", "MIPS64 0x6463dee3...; initBonds(8) = 0.08 ETH; absolutePrestate() on the bare implementation returns zero from now on"],
    invalidated=["none stated"],
    audits=["2025-11 Spearbit — Custom Gas Token", "2026-01 Cantina — Upgrade 18", "(between U18 and U19) 2026-03 Cantina — PolicyEngineStaking Contract; 2026-03 Cantina — Kona"],
    skipped_alternate=["'Upgrade 18a' on the forum is an Arena-Z chain-servicer migration, not a protocol maintenance release (see U18a)."],
    cannot_matter=None,
    evidence=["IMPL(*)", "GAMES(*)", "ARGS(op)", "OPS 040, 041, 042", "GOV 10576", "NOTICE upgrade-18"],
)

node(
    id="U18a", order=25, title="'Upgrade 18a' — Arena-Z chain servicer migration",
    proposal=dict(number="18a", name="Maintanance Upgrade Proposal 18a: Arena-Z Chain Servicer Migration", url=GOV + "10623"),
    classification="maintenance (single-chain configuration, not the four chains)",
    release=dict(tag=None, commit=None, notes="No release."),
    execution={"op-mainnet": "not affected", "ink": "not affected", "soneium": "not affected", "unichain": "not affected",
               "arena-z": [dict(what="048 proposer rotation (DGF.setImplementation with new gameArgs), 049 fee-vault update", block="24776353 / 24776372", utc="2026-03-31 08:19:59 / 08:23:47", tx="0xfbcdd181... / 0x95b7d66a...")]},
    chain_set=["arena-z (7897)"],
    changed_l1=["Arena-Z DisputeGameFactory gameArgs only"], changed_l2_clients=["Arena-Z fee vault predeploys"], initializers=["none"], storage_headline=["none on the four chains"],
    roles=["Arena-Z proposer"], dispute=["Demonstrates that since U18 a proposer/challenger rotation is a DGF.setImplementation(type, sameImpl, newArgs) call"], invalidated=["none"], audits=["n/a"],
    skipped_alternate=["The same pattern was later used for Ink (061), Unichain (078) and, inside U21, OP Mainnet proposer rotations."],
    cannot_matter=("Cannot matter for the four chains. (1) persistent state: only Arena-Z's own DGF/fee vaults; (2) surviving object: none shared — the shared Safes only spend a nonce; (3)-(5) no interpretation, authorization or proof change on the four chains; "
                   "(6) residue: none; (7) not on the canonical path; (8) no branch history for the four chains; (9) no prestate/game-type/root-format change; (10) no L1/L2 relationship change. Shared objects touched: Safe nonces only."),
    evidence=["OPS 048, 049", "TASKS", "GOV 10623"],
)

# --------------------------------------------------------------------------------------------- U19
node(
    id="U19", order=26, title="Upgrade 19 ('19b') — Karst hardfork, contracts v7, OPCMv2, L2CM",
    proposal=dict(number="19b", name="Upgrade 19b — Karst Hardfork", url=GOV + "10713"),
    classification="hardfork + contracts",
    release=dict(tag="op-contracts/v7.0.0", commit="a7c88c8d636ceb9944ea0edaf7d033da258778ab",
                 notes="Annotated tag created 2026-06-25 (execution day) on the rc.4 commit of 2026-05-26. OPCMv2 0x9ce712ff84e02659846dc6450bb9b7642fe8be5d (OPContractsManagerV2 7.1.17). "
                       "Tag oddity: op-contracts/v8.0.0-rc.1 points at the SAME commit (7cbcb58f) as v7.0.0-rc.1 and v7.0.0-rc.2."),
    execution={"op-mainnet": [dict(what="053: OPCM.upgradeSuperchain + OPCM.upgrade for OP Mainnet, Ink, Metal, Mode, Zora, Soneium", block=25397811, utc="2026-06-25 23:05:47", tx="0xbfdac60c9687a2e469159bf2458e73de2915a0a5eb53c4991a7ecde2b1fb3f15"),
                              dict(what="Karst activation, L2 timestamp 1783526401 = OP Mainnet L2 block 153963812: L2CM upgrade transaction 0xd2e9eb2b... replaces the implementations of the bridge predeploys for the FIRST time since Bedrock (L2ToL1MessagePasser 1.0.0 -> 1.2.0, L2CrossDomainMessenger 1.4.0 -> 2.2.1, L2StandardBridge 1.1.0 -> 1.13.2, L1Block 1.7.0 -> 1.9.0, ...)", block=None, utc="2026-07-08 16:00:01", tx="L2 0xd2e9eb2ba77098610e7dda134e70f741f7456f4ec49912d667860c40988dfd8e"),
                              dict(what="055: SystemConfig.setGasLimit(40,000,000) re-issued to re-emit ConfigUpdate (Karst gas-limit bug, keep_karst_upgrade_gas = true)", block=25488918, utc="2026-07-08 16:03:11", tx="0x8738995c1d3c654b0c919e39456a215db650dd75eae2feb13e463725c8362af7")],
               "ink": "same L1 transaction (block 25397811); same Karst timestamp",
               "soneium": "same L1 transaction; permissioned: stays on type 1, CANNON_KONA not installed",
               "unichain": [dict(what="054: OPCM.upgrade for Unichain by its own 3-of-3 PAO, eleven days after OP Mainnet and two days before Karst", block=25475307, utc="2026-07-06 18:32:35", tx="0xb3c65cbf6285d4b32d576c866fffced1c77747c53163b604e20feb6aad121421")]},
    chain_set=["op-mainnet, ink, metal, mode, zora, soneium (053); unichain (054)"],
    changed_l1=["OptimismPortal2 5.2.0 -> 5.6.1 (rootClaim / rootClaimByChainId dispatch by game type)", "SystemConfig 3.13.1 -> 3.14.2 (batchInbox recomputed for pre-OPCM chains, per the U20 proposal)", "L1CrossDomainMessenger 2.11.0 -> 2.11.1",
                "L1StandardBridge 2.8.0 -> 2.8.2", "L1ERC721Bridge 2.9.0 -> 2.9.1", "OptimismMintableERC20Factory 1.10.2 -> 1.11.0", "DisputeGameFactory 1.4.0 -> 1.6.1", "ETHLockbox 1.2.0 -> 1.3.1", "AnchorStateRegistry gen3 3.7.0 -> 3.9.0",
                "SuperchainConfig 2.4.0 -> 2.4.2", "NEW DelayedWETH proxy 0x1b6dbf05... (1.5.1) shared by ALL game types of the chain (previous generations were one proxy per game type)",
                "FaultDisputeGame 2.4.2 (0x2dda3584...), PermissionedDisputeGame 2.4.0 (0xe1dffcbe...), MIPS64 1.10.1 (0xacc005dc...)", "OPCM v1 replaced by OPContractsManagerV2 (deploy/upgrade/upgradeSuperchain)"],
    changed_l2_clients=["Osaka EIPs on L2 (EIP-7825 tx gas cap, not applied to deposits), bn256Pairing input 427 -> 300 pairs, L2 Contract Manager; op-geth and op-program end of support; op-node v1.19.1, op-reth v2.3.3, op-challenger v1.9.3, kona-client 1.6.0-rc.2"],
    initializers=["StorageSetter (0x2476c911...) + initialize cycle; SuperchainConfig emitted Initialized(2) again", "L2 side: L2CM runs ProxyAdmin.upgradePredeploys() inside the activation block"],
    storage_headline=["L2: every bridge predeploy jumps from its genesis layout to the v7 layout in one block (OP Mainnet: three years of versions at once)", "SystemConfig.batchInbox rewritten on pre-OPCM chains"],
    roles=["none on L1; L2 predeploy upgrades are now also possible through consensus (network upgrade transactions) in addition to the aliased ProxyAdmin owner"],
    dispute=["Respected game type 0 -> 8 (CANNON_KONA) on permissionless chains (OP Mainnet/Ink at block 25397811; Unichain at 25475307)", "gameImpls(0) CLEARED and initBonds(0) = 0: no new CANNON games; in-flight ones still resolve",
             "Type 8 prestate -> 0x0337ecb3604c0b40c352e0c7711beb17a212d583f4fe956fd8d66e29ad5f9025 (kona-client 1.6.0-rc.2); type 1 re-registered with placeholder prestate 0xdead0000...",
             "No type-8 gameArgs change between U18 and U19 on OP Mainnet (ARGS(op))"],
    invalidated=["Not stated as an invalidation. Proofs against type-0 games created while type 0 was respected stay usable (wasRespectedGameTypeWhenCreated is per game)."],
    audits=["2026-05 Cantina — Upgrade 19", "2026-06 Cantina — OPCMv2: OPContractsManagerV2.sol, OPContractsManagerMigrator.sol, OPContractsManagerContainer.sol, OPContractsManagerUtils.sol, OPContractsManagerUtilsCaller.sol, and VerifyOPCM.s.sol",
            "2026-06 Cantina — Interop L2 Contracts (re-review)"],
    skipped_alternate=["Only a '19b' proposal exists on the forum (no separate 'Upgrade 19' or '19a' topic was found by search).",
                       "Unichain ran type-0 as respected for eleven days longer than OP Mainnet/Ink."],
    cannot_matter=None,
    evidence=["IMPL(*)", "GAMES(*)", "ARGS(op)", "evidence/F2-impl-history-op-mainnet-L2-predeploys.json", "OPS 053, 054, 055", "GOV 10713", "NOTICE upgrade-19"],
)

node(
    id="MAINT-UNI-PAO", order=27, title="Unichain ProxyAdmin owner transition (and other 2026 single-chain maintenance)",
    proposal=dict(number=None, name="Maintenance Upgrade Proposal: Unichain ProxyAdmin Owner Transition to Standard Optimism Governance", url=GOV + "10839"),
    classification="authorization change (single chain)",
    release=dict(tag=None, commit=None, notes="No release."),
    execution={"op-mainnet": "not affected (see the 'other maintenance' list in RELEASE-DAG.md section 9 for OP Mainnet gas-limit and proposer changes)",
               "ink": [dict(what="065: Ink SystemConfig owner -> Foundation Upgrade Safe", block=25834840, utc="2026-08-25 21:15:59", tx="0xbf75cc41981ecb8481f3b114697310490b72f96c74fcc34e33b57433b6d9e756")],
               "soneium": "not affected (SystemConfig owner is still 0x509182eC... at block 26433900)",
               "unichain": [dict(what="069: ProxyAdmin 0x3B73Fa8d... and DisputeGameFactory owner 0x6d5B183F... (3-of-3) -> 0x5a0Aae59...", block=25976344, utc="2026-09-14 14:37:59", tx="0xfca98b14ae7163d444cd17285c7f97e1fb76db00cd971bae847a8af5f8ecb77f"),
                            dict(what="070: L2 ProxyAdmin owner -> 0x6B1BAE59... (alias of 0x5a0Aae59...) by a deposit through Unichain's portal", block=25976818, utc="2026-09-14 16:13:35", tx="0x53c072f1be2e42d2089aa76b6f769a378a3d12200a4d7b7c11606df2c7e0a8e2")]},
    chain_set=["unichain"],
    changed_l1=["none (owners only)"], changed_l2_clients=["Unichain L2 ProxyAdmin owner"], initializers=["none"], storage_headline=["owner slots"],
    roles=["From 2026-09-14 the same Safe 0x5a0Aae59... upgrades all four chains; this is what makes the single-transaction U20 and U21 (and the planned OP+Unichain migrate) possible"],
    dispute=["none"], invalidated=["none"], audits=["n/a"],
    skipped_alternate=["Before this, every Unichain upgrade (U13..U19) was a separate transaction from a different Safe with different timing."],
    cannot_matter=None,
    evidence=["CALL(unichain) proxyAdmin.owner(), dgf.owner()", "OPS 065, 069, 070", "TASKS", "GOV 10839"],
)

# --------------------------------------------------------------------------------------------- U20
node(
    id="U20", order=28, title="Upgrade 20 — Super Root dispute games, OPCM v8",
    proposal=dict(number="20", name="Upgrade 20 - Super Root Dispute Games & OPCM v8.0.0", url=GOV + "10856"),
    classification="contracts-only",
    release=dict(tag="op-contracts/v8.0.0", commit="f45a5ccfebcdf6da3f5b09cbc512667c063730b7", notes="Annotated tag created 2026-09-17 on the rc.3 commit (2026-08-13). OPCM 0x1951828ce913dc4383a8a1695695d537a11d896a (8.0.1). Per the proposal the audit ran on rc.2 with a fix review on rc.3."),
    execution={"op-mainnet": [dict(what="071: one transaction from 0x5a0Aae59...: OPCM.upgradeSuperchain + OPCM.upgrade for OP Mainnet, Ink, Soneium, Unichain", block=26048619, utc="2026-09-24 16:51:23", tx="0x0a0fe86f7b1a3d3d2d0be990e3f8b15628b885363ae527fa9548cb2c2375741a")],
               "ink": "same transaction", "soneium": "same transaction (respected type 1 -> 5)", "unichain": "same transaction (first Unichain upgrade from the standard PAO)"},
    chain_set=["op-mainnet, ink, soneium, unichain"],
    changed_l1=["OptimismPortal2 5.6.1 -> 5.8.0", "SystemConfig 3.14.2 -> 4.0.0 (batchInbox() and setGasConfig(uint256,uint256) removed; legacy batchInbox slot cleared; overhead zeroed)", "SuperchainConfig 2.4.2 -> 2.4.3",
                "NEW game implementations: SuperPermissionedDisputeGame 0x5c3eb47c... (1.1.0, type 5), SuperFaultDisputeGame 0x19af533c... (0.8.0, type 9)",
                "NOT changed: L1CrossDomainMessenger, bridges, DGF (1.6.1), ETHLockbox, ASR gen3 (3.9.0), DelayedWETH 0x1b6dbf05...; ProtocolVersions dropped from OPCM (proxy stays at 1.1.0)"],
    changed_l2_clients=["op-proposer v1.16.4 (--superroot-rpcs), op-challenger v1.9.5, op-dispute-mon v1.6.0, kona-client v1.7.0 exactly; no hardfork (L2 predeploy changes of this release are NOT deployed)"],
    initializers=["StorageSetter + initialize cycle (SuperchainConfig log: two Upgraded(StorageSetter)/Upgraded(impl) pairs, one Initialized(2))", "OPCM v8 enforces 'last upgrade was applied by an OPCM 7.x'"],
    storage_headline=["SystemConfig legacy batchInbox slot cleared; overhead = 0", "ASR anchor replaced by a super root at an L2 TIMESTAMP (OP Mainnet: L2 block 156622039, timestamp 1788842855) — l2SequenceNumber changes unit from block number to timestamp"],
    roles=["none"],
    dispute=["Respected type 8 -> 9 (SUPER_CANNON_KONA) on OP Mainnet/Ink/Unichain; 1 -> 5 (SUPER_PERMISSIONED) on Soneium", "gameImpls(1) and gameImpls(8) CLEARED on every chain (type 0 was already cleared at U19); initBonds(1) = initBonds(8) = 0",
             "Type 9 prestate 0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df (kona-client 1.7.0, interop variant), gameArgs l2ChainId = 0", "Type 5 gameArgs = asr(20) | proposer(20), bondless, resolves DEFENDER_WINS immediately (air-gap + blacklist remain)",
             "Root format: root claim is a super root; the portal reads the chain's output root with rootClaimByChainId"],
    invalidated=["None: 'withdrawal proofs submitted before Upgrade 20 remain valid'; output-root games created after the U16 retirement timestamp remain claim-valid when resolved"],
    audits=["2026-08 Cantina — Upgrade 20"],
    skipped_alternate=["Chains must already be on OPCM 7.x (sequence enforcement). Base is not part of it."],
    cannot_matter=None,
    evidence=["IMPL(*)", "GAMES(*)", "ARGS(op)", "CALL(*) portal.respectedGameType()", "OPS 071", "GOV 10856", "NOTICE upgrade-20"],
)

# --------------------------------------------------------------------------------------------- U21
node(
    id="U21", order=29, title="Upgrade 21 — interop readiness, OPCM v9",
    proposal=dict(number="21", name="Upgrade 21 - Interop Readiness", url=GOV + "10948"),
    classification="contracts-only",
    release=dict(tag="op-contracts/v9.0.0", commit="ba6fcadbc57eb99918c5b0f14f57c72527f531e3", notes="Annotated tag created 2026-11-04 on the rc.1 commit (2026-10-29). OPCM 0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f (9.0.3), deployed 2026-10-30. Tags v9.0.0+allowlist and v10.0.0-rc.1 already exist (not executed)."),
    execution={"op-mainnet": [dict(what="084: one transaction from 0x5a0Aae59...: OPCM.upgradeSuperchain + OPCM.upgrade for OP Mainnet, Ink, Soneium, Unichain (PASS A anchor)", block=26430859, utc="2026-11-16 23:23:59", tx="0x024770b5fba87683ee1466562eefb1bcb408c29c764e24abd07c7d4050a82a99")],
               "ink": "same transaction", "soneium": "same transaction", "unichain": "same transaction"},
    chain_set=["op-mainnet, ink, soneium, unichain"],
    changed_l1=["OptimismPortal2 5.8.0 -> 6.1.0", "SystemConfig 4.0.0 -> 4.3.0", "L1CrossDomainMessenger 2.11.1 -> 2.13.0", "ETHLockbox 1.3.1 -> 2.0.0", "AnchorStateRegistry gen3 3.9.0 -> 4.0.0",
                "DelayedWETH 0x1b6dbf05... 1.5.1 -> 2.0.0", "SuperchainConfig 2.4.3 -> 2.5.0", "NOT changed: L1StandardBridge (2.8.2), L1ERC721Bridge (2.9.1), OptimismMintableERC20Factory (1.11.0), DGF (1.6.1), game implementations, MIPS64"],
    changed_l2_clients=["op-challenger v1.11.0, kona-client 1.9.0; no hardfork"],
    initializers=["See PASS A (U21_INITIALIZER_CALLS.md)"],
    storage_headline=["See PASS A (47 net slot changes)"],
    roles=["Lockbox is the only chain-scoped pause identifier", "OP Mainnet SUPER_PERMISSIONED proposer rotated inside the upgrade: gameArgs(5) proposer 0x473300df... -> 0xc27ba3e0fc01567a5e57ae0c391aa98cecba5be0"],
    dispute=["Type 9 prestate -> 0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9 (kona-client 1.9.0, interop variant); respected type unchanged"],
    invalidated=["none (OPContractsManagerV2.migrate, not executed, would invalidate all proofs)"],
    audits=["2026-11 Cantina — Upgrade 21"],
    skipped_alternate=["Planned next node: Lagoon. REG already sets lagoon_time = 1799683201 (2027-01-11 16:00:01 UTC) in op.toml, ink.toml, soneium.toml AND unichain.toml, while the hardfork registry page still says 'not scheduled' and the interop notice names only OP Mainnet + Unichain."],
    cannot_matter=None,
    evidence=["PASS A workspace", "IMPL(*)", "ARGS(op)", "OPS 084", "GOV 10948", "NOTICE upgrade-21"],
)
