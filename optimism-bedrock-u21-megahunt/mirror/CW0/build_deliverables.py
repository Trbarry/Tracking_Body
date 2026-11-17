#!/usr/bin/env python3
"""Build CW0's independently derived PASS-A ingest and historical-lineage artifacts."""

from __future__ import annotations

import csv
import json
import re
from pathlib import Path


OUT = Path("/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/mirror/CW0")
PASS_A = Path("/home/user/Tracking_Body/optimism-u21-novel-hunt")


def clean_title(path: Path) -> str:
    text = path.read_text()
    for line in text.splitlines()[:12]:
        if line.startswith("Title:"):
            title = line.split(":", 1)[1].strip()
            break
    else:
        title = ""
        for line in text.splitlines()[:12]:
            if re.match(r"^#?\s*PRIM-(?:ID:\s*PRIM-)?\d+", line):
                title = re.sub(r"^#?\s*PRIM-(?:ID:\s*PRIM-)?\d+\s*(?:[—–:-]\s*)?", "", line).strip()
                if title:
                    break
            if line.startswith("PRIM-ID:"):
                title = re.sub(r"^PRIM-ID:\s*PRIM-\d+\s*(?:[—–:-]\s*)?", "", line).strip()
                if title:
                    break
    title = title.lstrip("�� ").strip()
    fallback = {
        "2501": "Permissionless proof deletion is limited to challenger wins or blacklist",
        "2502": "Proof cells are per submitter while the submitter list is append-only",
        "2503": "Adversarial proving cannot overwrite another submitter's proof cell",
        "2504": "v8 proofs survive the v9 implementation upgrade",
        "2505": "A fresh shared registry invalidates every old-registry proof",
        "2506": "A malformed stored game would make proof cleanup revert",
    }
    ident = path.stem.split("-")[1]
    return title or fallback.get(ident, f"PASS A primitive {ident}")


# These are mechanism-identical duplicate reports, not merely related observations.
DEDUP_GROUPS = [
    ["0104", "0705"],
    ["0402", "2401"],
    ["0501", "2501"],
    ["0303", "2304"],
    ["0304", "0401", "0803", "1102", "1202"],
    ["0305", "2307", "2602", "3102"],
    ["0306", "0901"],
    ["0502", "2502", "3103"],
    ["2404", "3203"],
    ["0603", "2603"],
    ["0606", "0903"],
    ["2405", "3104"],
    ["0902", "3201"],
    ["1003", "3001"],
    ["2402", "3101"],
    ["2303", "2901"],
    ["2505", "2705"],
]


FAMILY_IDS = {
    "custody": "0303 0306 0901 2301 2302 2303 2304 2305 2306 2308 2901 2902 2903 3003".split(),
    "proof-lifecycle": "0203 0406 0501 0502 0504 2401 2403 2404 2406 2501 2502 2503 2504 2505 2506 3103 3203".split(),
    "messenger-replay": "0301 0302 0304 0401 0402 0403 0802 0803 0805 1102 1202 2306 2402 3101 3106".split(),
    "pause": "0201 0305 0601 0603 0604 0605 1204 2203 2307 2602 2603 3002 3102".split(),
    "storage-init": "0202 1003 1203 2102 2201 2202 2205 3001".split(),
    "upgrade-engine": "0405 2101 3005".split(),
    "identity-binding": "0606 0701 0703 0903 2701 2702 2704 3004".split(),
    "dispute-game": "0101 0102 0104 0204 0503 0505 0702 0705 1101 2103 2204 2703".split(),
    "bond-credit": "0103 0602".split(),
    "gas-budget": "0404 0801 0804 1001 1002 1103 1201 2405 3006 3104 3105 3202".split(),
    "migration": "0704 0902 0904 2305 2505 2601 2604 2605 2705 2903 3201".split(),
    "tooling": ["2104"],
}


FAMILY_FACTS = {
    "custody": {
        "ancestor": "first: v1.0.0:contracts/L1/OptimismPortal.sol:325-420 (withdrawal value and finalize-before-call); current form: v4.0.0:src/L1/ETHLockbox.sol:132-219 (separate pooled custody), with U21 pause/identity source at v9.0.0:src/L1/ETHLockbox.sol:112-235",
        "consumer": "v9.0.0:src/L1/OptimismPortal2.sol:577-666,741-795 and v9.0.0:src/L1/ETHLockbox.sol:133-235",
        "state": "ETH in a portal/ETHLockbox/L1 messenger plus monotonic portal/lockbox authorizations",
        "branches": ["v1.0.0 portal custody — contracts/L1/OptimismPortal.sol:325-490", "v1.6.0 custom-gas-token branch — src/L1/OptimismPortal2.sol:362-440,504-573", "v4.0.0 per-chain ETHLockbox — src/L1/ETHLockbox.sol:67-219", "v7.0.0 shared-lockbox migration — src/L1/OptimismPortal2.sol:503-537", "v9.0.0 lockbox-sourced pause — src/L1/ETHLockbox.sol:112-119"],
        "edge": "create ETH liability or authorization before the v4/v7 custody split; consume it after pooling, re-pointing, or a failed current finalization",
    },
    "proof-lifecycle": {
        "ancestor": "first: v1.0.0:contracts/L1/OptimismPortal.sol:242-420 (one proof and hash-global finalization); current form: v1.4.0:src/L1/OptimismPortal2.sol:254-387,461-522 (per-submitter fault proofs), with U21 cleanup at v9.0.0:src/L1/OptimismPortal2.sol:671-728",
        "consumer": "v9.0.0:src/L1/OptimismPortal2.sol:390-492,577-728",
        "state": "provenWithdrawals[withdrawalHash][submitter], proofSubmitters[], finalizedWithdrawals[withdrawalHash], and referenced game clone",
        "branches": ["v1.0.0 L2OO proof — contracts/L1/OptimismPortal.sol:242-420", "v1.4.0 fault-game/per-submitter proof — src/L1/OptimismPortal2.sol:254-522", "v2.0.0 respect-at-creation — src/L1/OptimismPortal2.sol:292-378", "v4.0.0 ASR-owned validity — src/dispute/AnchorStateRegistry.sol:182-340", "v7.0.0 super-game branch — src/L1/OptimismPortal2.sol:368-471", "v9.0.0 deletion — src/L1/OptimismPortal2.sol:711-728"],
        "edge": "create a proof under an earlier registry/game-validity meaning; consume or delete it after registry, retirement, root-format, or cleanup semantics change",
    },
    "messenger-replay": {
        "ancestor": "first: v1.0.0:contracts/universal/CrossDomainMessenger.sol:303-413 (v0/v1 hash, replay, reentrancy and success/failure mappings); current form: v9.0.0:src/universal/CrossDomainMessenger.sol:212-302 (split local/remote gas budgets)",
        "consumer": "v9.0.0:src/universal/CrossDomainMessenger.sol:212-302 and v9.0.0:src/L1/OptimismPortal2.sol:620-653",
        "state": "successfulMessages/failedMessages keyed by versioned message hash, xDomainMsgSender sentinel, and a proven messenger withdrawal",
        "branches": ["v1.0.0 v0/v1 replay — contracts/universal/CrossDomainMessenger.sol:303-413", "v1.2.0 paused relay — src/universal/CrossDomainMessenger.sol:219-330", "v3.0.0 EIP-7623 baseGas — src/universal/CrossDomainMessenger.sol:354-390", "v9.0.0 local/remote reserve split and portal L1CDM revert — src/universal/CrossDomainMessenger.sol:212-373; src/L1/OptimismPortal2.sol:639-653"],
        "edge": "create a legacy hash, failedMessages entry, or old-budget withdrawal before U21; consume it through the current replay and portal atomicity branches",
    },
    "pause": {
        "ancestor": "first: v1.0.0:contracts/L1/OptimismPortal.sol:83,174-187 (portal-local guardian flag); current form: v9.0.0:src/L1/SuperchainConfig.sol:79-153 plus v9.0.0:src/L1/ETHLockbox.sol:112-119",
        "consumer": "v9.0.0:src/L1/ETHLockbox.sol:112-119,157-174; v9.0.0:src/L1/OptimismPortal2.sol:306-330",
        "state": "pause timestamp keyed by global/portal/SystemConfig/ETHLockbox identifier and cached dependency pointers",
        "branches": ["v1.0.0 portal-local bool — contracts/L1/OptimismPortal.sol:83,174-187", "v1.2.0 global SuperchainConfig — src/L1/SuperchainConfig.sol:19-81", "v4.0.0 expiring scoped timestamp — src/L1/SuperchainConfig.sol:40-182", "v4.1.0 SystemConfig-selected key — src/L1/SystemConfig.sol:503-534", "v9.0.0 lockbox key — src/L1/ETHLockbox.sol:112-119"],
        "edge": "create a scoped pause or store a dependency pointer under an earlier identifier generation; consume it after the v9 lockbox-key pivot",
    },
    "storage-init": {
        "ancestor": "first: v1.0.0:contracts/L1/OptimismPortal.sol:50-83,165-169 (proxy storage plus initializer); current replay/reset form: v7.0.0:src/L1/opcm/OPContractsManagerUtils.sol:307-372 and v9.0.0:src/L1/opcm/OPContractsManagerUtils.sol:312-377",
        "consumer": "v9.0.0 proxy initializers, including src/L1/OptimismPortal2.sol:273-303 and src/dispute/AnchorStateRegistry.sol:94-133",
        "state": "proxy slots, packed initializer byte, preserved legacy spacers, and cached dependency addresses",
        "branches": ["v1.0.0 proxy initialization — contracts/L1/OptimismPortal.sol:50-83,165-169", "v1.1.0 storage-address dependencies — src/L1/SystemConfig.sol:30-73,155-191", "v4.0.0 legacy spacers — src/L1/OptimismPortal2.sol:40-126", "v7.0.0 OPCM reset-and-reinitialize — src/L1/opcm/OPContractsManagerUtils.sol:307-372", "v9.0.0 heterogeneous initializer offsets — src/L1/opcm/OPContractsManagerUtils.sol:312-377"],
        "edge": "write a slot or initializer byte under a pre-v7 layout; consume it through the current same-version reset/reinitializer machinery",
    },
    "upgrade-engine": {
        "ancestor": "first/current recognizable engine: v7.0.0:src/L1/opcm/OPContractsManagerV2.sol:229-290 and src/L1/opcm/OPContractsManagerUtils.sol:307-372; U21 form: v9.0.0:src/L1/opcm/OPContractsManagerV2.sol:244-305",
        "consumer": "v9.0.0:src/L1/opcm/OPContractsManagerV2.sol:244-305 and src/L1/opcm/OPContractsManagerMigrator.sol:129-520",
        "state": "implementation/version records, proxy initializer state, deterministic deployment salt, and upgrade instructions",
        "branches": ["v7.0.0 OPCM V2 introduction — src/L1/opcm/OPContractsManagerV2.sol:229-290", "v8.0.0 migration validation — src/L1/opcm/OPContractsManagerMigrator.sol:89-520", "v9.0.0 U21 bundle — src/L1/opcm/OPContractsManagerV2.sol:244-305"],
        "edge": "create proxy/version state under the first OPCM V2 bundle; consume it in a later same-version replay or migration with changed initializer metadata",
    },
    "identity-binding": {
        "ancestor": "first game identity: v1.4.0:src/dispute/AnchorStateRegistry.sol:59-87 and src/dispute/DisputeGameFactory.sol:84-134; current super-root form: v7.0.0:src/L1/OptimismPortal2.sol:368-471 and v9.0.0:src/dispute/AnchorStateRegistry.sol:215-352",
        "consumer": "v9.0.0:src/L1/OptimismPortal2.sol:390-492 and src/dispute/AnchorStateRegistry.sol:227-370",
        "state": "factory UUID, immutable clone args, root claim/preimage, chain ID source, ASR/factory pointer, and proxy-admin owner identity",
        "branches": ["v1.4.0 factory/address identity — src/dispute/AnchorStateRegistry.sol:59-87", "v2.0.0 single anchor and snapshot respect — src/dispute/AnchorStateRegistry.sol:39-239", "v4.0.0 super-root portal — src/L1/OptimismPortal2.sol:396-570", "v7.0.0 unified super-game branch — src/L1/OptimismPortal2.sol:368-471", "v9.0.0 lockbox identity source — src/dispute/AnchorStateRegistry.sol:33-59,136-143"],
        "edge": "create an immutable game under old factory/ASR/chain-binding inputs; consume it after a mutable singleton or identity source is re-pointed",
    },
    "dispute-game": {
        "ancestor": "first factory clone: v1.0.0:contracts/dispute/DisputeGameFactory.sol:78-162; fault-proof registry form: v1.4.0:src/dispute/AnchorStateRegistry.sol:20-87; current form: v9.0.0:src/dispute/DisputeGameFactory.sol:147-245 and src/dispute/AnchorStateRegistry.sol:227-370",
        "consumer": "v9.0.0:src/dispute/AnchorStateRegistry.sol:227-370 and src/L1/OptimismPortal2.sol:390-492",
        "state": "immutable game clone, DGF UUID/list entry, snapshotted respect, l1Head/prestate, terminal status, and shared anchorGame",
        "branches": ["v1.0.0 factory clone — contracts/dispute/DisputeGameFactory.sol:78-162", "v1.4.0 per-type anchor — src/dispute/AnchorStateRegistry.sol:20-87", "v2.0.0 single anchor/snapshot respect — src/dispute/AnchorStateRegistry.sol:39-239", "v5.0.0 gameArgs — src/dispute/DisputeGameFactory.sol:70-190,278-292", "v7.0.0 CREATE2 and super games — src/dispute/DisputeGameFactory.sol:147-225", "v9.0.0 current validity — src/dispute/AnchorStateRegistry.sol:227-352"],
        "edge": "create a game clone under an older implementation/gameArgs/prestate; consume it through today's mutable ASR predicates or shared anchor",
    },
    "bond-credit": {
        "ancestor": "first/current recognizable credit: v1.4.0:src/dispute/weth/DelayedWETH.sol:20-92 and src/dispute/weth/WETH98.sol:28-42; U21 form: v9.0.0:src/dispute/DelayedWETH.sol:37-129",
        "consumer": "v9.0.0:src/dispute/DelayedWETH.sol:74-129",
        "state": "WETH balance, delayed withdrawal timestamp/amount, and the pause/guardian dependency pointer",
        "branches": ["v1.4.0 SuperchainConfig-backed DelayedWETH — src/dispute/weth/DelayedWETH.sol:20-92", "v1.6.0 recover via call — src/dispute/weth/DelayedWETH.sol:85-105", "v9.0.0 ETHLockbox-backed pause/guardian — src/dispute/DelayedWETH.sol:37-129"],
        "edge": "create bond credit in a legacy DelayedWETH or via payable fallback; consume/recover it after pause-source or singleton re-pointing",
    },
    "gas-budget": {
        "ancestor": "first: v1.0.0:contracts/libraries/SafeCall.sol:91-159 and contracts/universal/CrossDomainMessenger.sol:123-159,303-413; current form: v9.0.0:src/libraries/SafeCall.sol:7-9,103-171 and src/L1/L1CrossDomainMessenger.sol:43-74,117-153",
        "consumer": "v9.0.0:src/universal/CrossDomainMessenger.sol:212-302,334-373 and src/libraries/SafeCall.sol:103-171",
        "state": "persisted withdrawal/message gasLimit encoded under an older remote baseGas schedule",
        "branches": ["v1.0.0 EIP-150 reserve — contracts/libraries/SafeCall.sol:91-159", "v3.0.0 calldata-floor baseGas — src/universal/CrossDomainMessenger.sol:354-390", "v9.0.0 local/remote budget split and codehash-zero reserve — src/L1/L1CrossDomainMessenger.sol:43-153; src/libraries/SafeCall.sol:103-171"],
        "edge": "create a message using the old L2 budget; consume it on L1 after U21 or a future Amsterdam cost activation",
    },
    "migration": {
        "ancestor": "first shared migration engine: v7.0.0:src/L1/opcm/OPContractsManagerMigrator.sol:89-316 and src/L1/OptimismPortal2.sol:502-572; U21 form: v9.0.0:src/L1/opcm/OPContractsManagerMigrator.sol:129-520",
        "consumer": "v9.0.0:src/L1/opcm/OPContractsManagerMigrator.sol:129-520; src/L1/OptimismPortal2.sol:502-572; src/L1/ETHLockbox.sol:180-235",
        "state": "old proof/game/anchor, per-chain lockbox balance, sticky authorization, cached singleton pointer, and feature flag",
        "branches": ["v4.0.0 portal liquidity/super-root migration — src/L1/OptimismPortal2.sol:374-429", "v7.0.0 shared-game migration — src/L1/opcm/OPContractsManagerMigrator.sol:89-316", "v8.0.0 validation hardening — src/L1/OptimismPortal2.sol:510-554", "v9.0.0 U21 state — src/L1/opcm/OPContractsManagerMigrator.sol:129-520"],
        "edge": "create proof, authorization, liquidity, or game before migration; consume it after fresh DGF/ASR and shared-lockbox cutover",
    },
    "tooling": {
        "ancestor": "first/current deterministic proxy utility: v7.0.0:src/L1/opcm/OPContractsManagerUtils.sol:96-110,231-372; U21 form: v9.0.0:src/L1/opcm/OPContractsManagerUtils.sol:101-115,236-377",
        "consumer": "v9.0.0:src/L1/opcm/OPContractsManagerV2.sol:244-305 and src/L1/opcm/OPContractsManagerMigrator.sol:129-520",
        "state": "CREATE2 address occupancy and serialized upgrade/deployment instruction",
        "branches": ["v7.0.0 utility introduced — src/L1/opcm/OPContractsManagerUtils.sol:96-110,231-372", "v8.0.0 migration validation — src/L1/opcm/OPContractsManagerMigrator.sol:89-520", "v9.0.0 unchanged deployment domain — src/L1/opcm/OPContractsManagerUtils.sol:101-115,236-377"],
        "edge": "create deterministic occupancy through a caller different from the eventual deployment context; consume the same salt in a governed bundle",
    },
}


P0 = set("0102 0104 0204 0304 0404 0503 0704 0801 0805 0904 1001 1101 1103 1201 2303 2305 2505 2604 2704 2901 2903 3005 3006 3105 3202".split())
P1 = set("0101 0103 0201 0203 0301 0302 0303 0306 0402 0403 0405 0406 0501 0502 0504 0505 0601 0602 0605 0606 0701 0702 0703 0802 0804 0902 1002 1003 1203 2101 2102 2103 2201 2202 2203 2204 2205 2301 2302 2306 2308 2402 2403 2404 2405 2406 2503 2504 2506 2605 2701 2702 2703 2902 3001 3002 3003 3004 3101 3106 3203".split())


# Per-mechanism ancestry overrides keep the mandatory "earliest" field narrower than the family history.
PRIMITIVE_OVERRIDES: dict[str, dict[str, str]] = {}


def override(ids: str, ancestor: str, consumer: str, state: str | None = None, edge: str | None = None) -> None:
    value = {"EARLIEST_SEMANTIC_ANCESTOR": ancestor, "CURRENT_U21_CONSUMER": consumer}
    if state is not None:
        value["PERSISTENT_STATE_OR_OBJECT"] = state
    if edge is not None:
        value["UNREVIEWED_CROSS_UPGRADE_EDGE"] = edge
    for ident in ids.split():
        PRIMITIVE_OVERRIDES[ident] = value


override(
    "0101 0505 0702 2703",
    "first: v2.0.0:src/dispute/AnchorStateRegistry.sol:116-234 (factory registration, snapshotted respect, retirement and claim validity); current form: v7.0.0:src/dispute/AnchorStateRegistry.sol:215-352 (type-independent proper plus retirement-backed domain), preserved at v9.0.0:src/dispute/AnchorStateRegistry.sol:227-352",
    "v9.0.0:src/dispute/AnchorStateRegistry.sol:227-370 and src/L1/OptimismPortal2.sol:390-492",
    "historical output-root game clone with creation-time respect, status, timestamps and DGF UUID",
)
override(
    "0102",
    "first: v2.0.0:src/dispute/SuperFaultDisputeGame.sol:257-284,1083-1084 (fixed absolute prestate in a super game); current form: v9.0.0:src/dispute/SuperFaultDisputeGame.sol:251-278,823-874 (prestate and singleton addresses in immutable clone args)",
    "v9.0.0:src/dispute/SuperFaultDisputeGame.sol:251-340,823-887 and src/dispute/AnchorStateRegistry.sol:227-352",
    "already-created type-9 clone embedding the earlier absolute prestate and mutable singleton addresses",
)
override(
    "0103 0602",
    "first/current recognizable credit: v1.4.0:src/dispute/weth/DelayedWETH.sol:20-92 and src/dispute/weth/WETH98.sol:28-42; current dependency form: v9.0.0:src/dispute/DelayedWETH.sol:37-129",
    "v9.0.0:src/dispute/DelayedWETH.sol:74-129",
    "legacy WETH balance plus withdrawals[account] timestamp/amount and the proxy's pause-source pointer",
)
override(
    "0104 0204",
    "first: v2.0.0:src/dispute/SuperPermissionedDisputeGame.sol:42-52,89-108 (immutable proposer/challenger and tx.origin creation gate); current form: v9.0.0:src/dispute/SuperPermissionedDisputeGame.sol:52-78,133-135 (born-resolved immutable-arg game)",
    "v9.0.0:src/dispute/SuperPermissionedDisputeGame.sol:52-78,133-135 and src/dispute/AnchorStateRegistry.sol:331-370",
    "type-5 clone, snapshotted respect, proposer immutable arg and possible shared-anchor position",
)
override(
    "0201 0601 1204 2202 2203 3002",
    "first indirection: v1.2.0:src/L1/OptimismPortal.sol:147-149 and src/L1/SuperchainConfig.sol:19-81; current four-pointer/lockbox-key form: v9.0.0:src/L1/OptimismPortal2.sol:306-330, src/dispute/AnchorStateRegistry.sol:33-59,136-143, and src/dispute/DelayedWETH.sol:37-76",
    "v9.0.0:src/L1/ETHLockbox.sol:112-119, src/L1/OptimismPortal2.sol:306-330, and src/dispute/AnchorStateRegistry.sol:136-143",
    "cached Portal/ASR/DelayedWETH/ETHLockbox dependency pointers plus scoped pause timestamps",
)
override(
    "0202",
    "first live words: v1.0.0:contracts/L1/OptimismPortal.sol:50-83; current dead form: v9.0.0:src/L1/OptimismPortal2.sol:64-120 (explicit legacy spacers)",
    "no runtime consumer found; layout preservation is visible at v9.0.0:src/L1/OptimismPortal2.sol:64-120",
    "nonzero preserved proxy words under fields now declared as legacy spacers",
)
override(
    "0203 0501",
    "array/cell split first: v1.4.0:src/L1/OptimismPortal2.sol:83-95,423-430; delete-without-prune current form first: v9.0.0:src/L1/OptimismPortal2.sol:711-728",
    "v9.0.0:src/L1/OptimismPortal2.sol:671-728",
    "one per-submitter proof cell, an append-only submitter array entry and the hash-global finalized bit",
)
override(
    "0301 0402",
    "first: v1.4.0:src/L1/OptimismPortal2.sol:339-387 (external proof submitter and permissionless finalize); current form: v9.0.0:src/L1/OptimismPortal2.sol:577-666 (lockbox custody plus L1CDM-specific atomic revert)",
    "v9.0.0:src/L1/OptimismPortal2.sol:577-666 and src/libraries/SafeCall.sol:121-171",
    "mature per-submitter proof and its unfinalized hash-global replay bit",
)
override(
    "0302",
    "first: v1.0.0:contracts/L1/OptimismPortal.sol:67,369-409 (l2Sender execution sentinel); current lockbox call graph: v9.0.0:src/L1/OptimismPortal2.sol:620-660",
    "v9.0.0:src/L1/OptimismPortal2.sol:577-666 and src/L1/ETHLockbox.sol:157-174",
    "in-flight withdrawal execution context: l2Sender, finalized bit and temporarily unlocked ETH",
)
override(
    "0303",
    "donation first: v1.0.0:contracts/L1/OptimismPortal.sol:210-215; portal surplus becomes separate from backing at v4.0.0:src/L1/OptimismPortal2.sol:374-382,740-788; current form: v9.0.0:src/L1/OptimismPortal2.sol:381-383,502-513",
    "v9.0.0:src/L1/OptimismPortal2.sol:381-383,502-513",
    "ETH held by the Portal address rather than its ETHLockbox liability pool",
)
override(
    "0304",
    "components first coexist at v1.4.0:src/L1/OptimismPortal2.sol:339-387 and src/universal/CrossDomainMessenger.sol:219-330; current nested-replay outcome: v9.0.0:src/universal/CrossDomainMessenger.sol:212-302 with src/L1/OptimismPortal2.sol:620-653",
    "v9.0.0:src/universal/CrossDomainMessenger.sol:212-302 and src/L1/OptimismPortal2.sol:620-653",
    "a proven messenger withdrawal, outer failedMessages replay context and ETH parked in L1CrossDomainMessenger",
)
override(
    "0305",
    "deposit-vs-exit asymmetry first: v1.0.0:contracts/L1/OptimismPortal.sol:174-187,242-490; lockbox form: v4.0.0:src/L1/ETHLockbox.sol:132-177; current key: v9.0.0:src/L1/ETHLockbox.sol:112-159",
    "v9.0.0:src/L1/ETHLockbox.sol:112-159 and src/L1/OptimismPortal2.sol:390-492,577-666,741-795",
    "active lockbox-key pause timestamp plus deposits made while outflows are stopped",
)
override(
    "0306 2902",
    "first relevant migration/lockbox topology: v7.0.0:src/L1/OptimismPortal2.sol:503-537 and src/L1/ETHLockbox.sol:180-232; current unsafe-target predicate: v9.0.0:src/L1/OptimismPortal2.sol:846-849",
    "v9.0.0:src/L1/OptimismPortal2.sol:577-666,741-795,846-849",
    "retired/sibling portal or lockbox address left authorized and not equal to the current unsafe target",
)
override(
    "0403 0802 3106",
    "first/current sender-specific L1CDM atomicity rule: v9.0.0:src/L1/OptimismPortal2.sol:620-653; underlying messenger outcome mappings date to v1.0.0:contracts/universal/CrossDomainMessenger.sol:171-193,374-413",
    "v9.0.0:src/L1/OptimismPortal2.sol:620-653 and src/universal/CrossDomainMessenger.sol:256-302",
    "withdrawal sender identity plus successfulMessages/failedMessages outcome for the nested relay",
    "create a messenger withdrawal under pre-v9 outcome semantics, then finalize through the sender-only v9 guard where L1CDM returns normally but its mappings encode failure",
)
override(
    "0404 0801 0804 1001 1002 1103 1201 2405 3006 3202",
    "first reserve model: v1.0.0:contracts/libraries/SafeCall.sol:91-159 and contracts/universal/CrossDomainMessenger.sol:123-159; current split/reserve form: v9.0.0:src/L1/L1CrossDomainMessenger.sol:43-74,117-153 and src/libraries/SafeCall.sol:7-9,103-171",
    "v9.0.0:src/universal/CrossDomainMessenger.sol:212-302,334-373 and src/libraries/SafeCall.sol:103-171",
    "persisted message/withdrawal gasLimit encoded under an earlier remote budget and target code-presence state",
)
override(
    "0405 2101 2102 2201 2205",
    "first/current recognizable reset-and-replay engine: v7.0.0:src/L1/opcm/OPContractsManagerV2.sol:229-290 and src/L1/opcm/OPContractsManagerUtils.sol:307-372; U21 form: v9.0.0:src/L1/opcm/OPContractsManagerV2.sol:244-305 and src/L1/opcm/OPContractsManagerUtils.sol:312-377",
    "v9.0.0:src/L1/opcm/OPContractsManagerV2.sol:244-305 and src/L1/opcm/OPContractsManagerUtils.sol:312-377",
    "proxy implementation/version, packed initializer byte and the atomic StorageSetter/initializer instruction pair",
)
override(
    "0406 0502",
    "per-submitter cell/list first: v1.4.0:src/L1/OptimismPortal2.sol:83-95,423-430; current deletion and hash-global finalization: v9.0.0:src/L1/OptimismPortal2.sol:577-728",
    "v9.0.0:src/L1/OptimismPortal2.sol:390-492,577-728",
    "per-submitter proof cells, duplicate/stale proofSubmitters entries and one finalizedWithdrawals bit",
)
override(
    "0503 1101",
    "super-root proof first: v4.0.0:src/L1/OptimismPortal2.sol:396-570; current unified game-type branch: v7.0.0:src/L1/OptimismPortal2.sol:368-471, preserved at v9.0.0:src/L1/OptimismPortal2.sol:390-492",
    "v9.0.0:src/L1/OptimismPortal2.sol:390-492 and src/dispute/AnchorStateRegistry.sol:286-352",
    "attacker-created super-game/root claim and a genuine per-chain output-root inclusion proof",
)
override(
    "0504 2404",
    "current-at-finalization recheck first: v1.4.0:src/L1/OptimismPortal2.sol:441-522; ASR-owned current configuration: v4.0.0:src/dispute/AnchorStateRegistry.sol:182-340; current form: v9.0.0:src/L1/OptimismPortal2.sol:671-728",
    "v9.0.0:src/L1/OptimismPortal2.sol:671-728 and src/dispute/AnchorStateRegistry.sol:227-352",
    "stored proof pointing to a game plus mutable current DGF/blacklist/retirement/pause configuration",
)
override(
    "0603 0604",
    "first scoped/expiring timestamp model: v4.0.0:src/L1/SuperchainConfig.sol:40-182; current form: v9.0.0:src/L1/SuperchainConfig.sol:39-40,79-162",
    "v9.0.0:src/L1/SuperchainConfig.sol:79-162 and src/L1/ETHLockbox.sol:112-113",
    "pauseTimestamps[identifier], including expired or currently unconsumed identifiers",
)
override(
    "0605 2308 2601",
    "runtime feature map first: v4.1.0:src/L1/SystemConfig.sol:139,503-534; current immutable/transition guards: v9.0.0:src/L1/SystemConfig.sol:532-568 and src/L1/OptimismPortal2.sol:500-589,741-759",
    "v9.0.0:src/L1/SystemConfig.sol:532-568 and src/L1/OptimismPortal2.sol:500-589,741-759",
    "feature bit plus pre-existing Portal/lockbox ETH, proofs, messages and cached dependencies",
    "create liquidity/proofs/messages with a feature disabled, then consume them after CGT/ETH_LOCKBOX/INTEROP flips without object-by-object conversion",
)
override(
    "0606 0701 0703 2701 2702",
    "super-root chain selection first: v4.0.0:src/L1/OptimismPortal2.sol:396-570; current unified binding: v7.0.0:src/L1/OptimismPortal2.sol:368-471, preserved at v9.0.0:src/L1/OptimismPortal2.sol:390-492",
    "v9.0.0:src/L1/OptimismPortal2.sol:390-492, src/dispute/DisputeGameFactory.sol:147-245, and src/dispute/AnchorStateRegistry.sol:227-352",
    "super-game UUID/root/preimage, immutable l1Head/extraData and SystemConfig.l2ChainId selected at proof time",
)
override(
    "0704 0904 2305 2505 2604 2903",
    "shared cutover first/current recognizable form: v7.0.0:src/L1/opcm/OPContractsManagerMigrator.sol:89-316, src/L1/OptimismPortal2.sol:502-572, and src/L1/ETHLockbox.sol:180-232; U21 form: v9.0.0:src/L1/opcm/OPContractsManagerMigrator.sol:129-563",
    "v9.0.0:src/L1/opcm/OPContractsManagerMigrator.sol:129-563, src/L1/OptimismPortal2.sol:502-572, and src/L1/ETHLockbox.sol:180-235",
    "old proofs/games/anchors, per-chain lockbox balance, cached singleton pointers and sticky authorization entries",
)
override(
    "0805",
    "legacy hash objects first: v1.0.0:contracts/universal/CrossDomainMessenger.sol:303-413; unchanged mapping consumers with U21 budgets: v9.0.0:src/universal/CrossDomainMessenger.sol:212-302",
    "v9.0.0:src/universal/CrossDomainMessenger.sol:212-302 and src/L1/OptimismPortal2.sol:577-666",
    "live version-0/old-budget withdrawal, legacy/canonical message hashes and persistent messenger mappings",
)
override(
    "0902",
    "first/current zero-balance validation: v9.0.0:src/L1/opcm/OPContractsManagerMigrationValidator.sol:559-568; validation entry: v9.0.0:src/L1/opcm/OPContractsManagerMigrationValidator.sol:74-115",
    "v9.0.0:src/L1/opcm/OPContractsManagerMigrationValidator.sol:559-568",
    "mutable Portal/legacy-lockbox account balances observed by an off-chain/governed migration validator",
    "establish the validator's zero-balance premise at one block, then mutate the historical account before or inside the eventual governed migration sequence",
)
override(
    "1003",
    "immutable clone/singleton split first: v1.4.0:src/dispute/DisputeGameFactory.sol:84-132 and src/dispute/AnchorStateRegistry.sol:20-87; current mutable-arg/reinitializer form: v7.0.0:src/dispute/DisputeGameFactory.sol:147-225 and src/dispute/AnchorStateRegistry.sol:94-133",
    "v9.0.0:src/dispute/DisputeGameFactory.sol:147-225, src/dispute/AnchorStateRegistry.sol:94-133, and src/dispute/DelayedWETH.sol:58-76",
    "immutable game clone retaining old ASR/DelayedWETH/prestate args while referenced singleton proxies are reinitialized",
    "create a clone with old immutable singleton/prestate arguments, reinitialize the shared proxies at M, then resolve/redeem the old clone through new singleton semantics",
)
override(
    "1203",
    "the omitted-sibling-check set is U21-current: v9.0.0:src/L1/ETHLockbox.sol:94-109,180-235; src/L1/OptimismPortal2.sol:273-303,528-572; src/dispute/AnchorStateRegistry.sol:94-133",
    "v9.0.0:src/L1/ETHLockbox.sol:94-235, src/L1/OptimismPortal2.sol:273-303,528-572, and src/dispute/AnchorStateRegistry.sol:94-185",
    "privileged dependency pointer, monotonic authorization or feature/type setting",
    "create a pointer/authorization relationship under an earlier initializer, then consume it after U21 through a sibling path that omits the newer equality/nonzero check",
)
override(
    "2103 2204",
    "implementation mapping first: v1.0.0:contracts/dispute/DisputeGameFactory.sol:30-37,78-162; dynamic gameArgs first: v5.0.0:src/dispute/DisputeGameFactory.sol:70-190,278-292; current dual layout: v9.0.0:src/dispute/DisputeGameFactory.sol:147-225,312-318",
    "v9.0.0:src/dispute/DisputeGameFactory.sol:147-245,302-329 and src/dispute/AnchorStateRegistry.sol:227-352",
    "old and new immutable game clones sharing a UUID schema but embedding different implementation arguments/prestates",
)
override(
    "2104",
    "first/current deterministic proxy utility: v7.0.0:src/L1/opcm/OPContractsManagerUtils.sol:96-110,231-372; U21 form: v9.0.0:src/L1/opcm/OPContractsManagerUtils.sol:101-115,236-377",
    "v9.0.0:src/L1/opcm/OPContractsManagerV2.sol:244-305 and src/L1/opcm/OPContractsManagerMigrator.sol:129-563",
    "CREATE2 deployer+salt+initcode tuple and occupancy at the resulting proxy address",
)
override(
    "2301",
    "lockbox-backed deposit first: v4.0.0:src/L1/OptimismPortal2.sol:740-788 and src/L1/ETHLockbox.sol:132-151; current CGT/exact encoding form: v9.0.0:src/L1/OptimismPortal2.sol:741-795",
    "v9.0.0:src/L1/OptimismPortal2.sol:741-795 and src/L1/ETHLockbox.sol:133-151",
    "deposit ETH locked exactly once plus emitted opaque mint/value fields",
)
override(
    "2302 2306 2402",
    "lockbox unlock/call/relock first: v4.0.0:src/L1/OptimismPortal2.sol:624-681; messenger-specific atomic rollback current form: v9.0.0:src/L1/OptimismPortal2.sol:620-660",
    "v9.0.0:src/L1/OptimismPortal2.sol:577-666 and src/L1/ETHLockbox.sol:157-177",
    "mature proof, global finalized bit, temporarily unlocked value and possible messenger failedMessages custody",
)
override(
    "2303",
    "multi-portal aggregate pool is structurally present at v4.0.0:src/L1/ETHLockbox.sol:70-73,123-177; shared migration makes it cross-chain at v7.0.0:src/L1/ETHLockbox.sol:180-232; current form: v9.0.0:src/L1/ETHLockbox.sol:71-75,124-235",
    "v9.0.0:src/L1/ETHLockbox.sol:124-235 and src/L1/OptimismPortal2.sol:577-795",
    "aggregate ETH balance and monotonic authorizedPortals mapping with no per-portal accounting",
)
override(
    "2403",
    "hash-global finalization first: v1.0.0:contracts/L1/OptimismPortal.sol:72,383-409; per-submitter proof cells first: v1.4.0:src/L1/OptimismPortal2.sol:83-95,423-430; current form: v9.0.0:src/L1/OptimismPortal2.sol:390-492,577-728",
    "v9.0.0:src/L1/OptimismPortal2.sol:390-492,577-728",
    "multiple submitter proof cells converging on finalizedWithdrawals[withdrawalHash]",
)
override(
    "2406 2504",
    "current proof storage form first: v1.4.0:src/L1/OptimismPortal2.sol:83-95,423-430; v8-to-v9 consumer remains at v9.0.0:src/L1/OptimismPortal2.sol:390-492,577-728",
    "v9.0.0:src/L1/OptimismPortal2.sol:577-728 and src/universal/CrossDomainMessenger.sol:212-302",
    "pre-U21 provenWithdrawal cells, submitter list, finalized bit and messenger replay mappings",
)
override(
    "2503",
    "per-submitter isolation first/current storage shape: v1.4.0:src/L1/OptimismPortal2.sol:83-95,423-430; current consumer: v9.0.0:src/L1/OptimismPortal2.sol:390-492,577-705",
    "v9.0.0:src/L1/OptimismPortal2.sol:390-492,577-705",
    "two disjoint provenWithdrawals[hash][submitter] cells and one hash-global finalization bit",
)
override(
    "2506",
    "cleanup assumption first/current: v9.0.0:src/L1/OptimismPortal2.sol:711-728; production provenance barrier dates to v1.4.0:src/L1/OptimismPortal2.sol:254-328",
    "v9.0.0:src/L1/OptimismPortal2.sol:711-728 and src/dispute/DisputeGameFactory.sol:147-225",
    "hypothetical stored proof whose disputeGameProxy has no conforming status() code",
)
override(
    "2605",
    "L1 feature map first: v4.1.0:src/L1/SystemConfig.sol:139,503-534; current independent L1/L2 setters: v9.0.0:src/L1/SystemConfig.sol:532-568 and src/L2/L1Block.sol:230-258",
    "v9.0.0:src/L1/SystemConfig.sol:532-568, src/L2/L1Block.sol:230-258, and src/L2/L2ContractsManager.sol:403-428",
    "independent L1 SystemConfig and L2 L1Block feature bits plus already-created cross-domain objects",
    "create a cross-domain object while L1 and L2 flags disagree, transition only one domain, then consume the object in the other domain's feature branch",
)
override(
    "2704",
    "single shared anchor first: v2.0.0:src/dispute/AnchorStateRegistry.sol:39-110,239-262; embedded-ASR registration check removed in current lineage at v7.0.0:src/dispute/AnchorStateRegistry.sol:215-236; current form: v9.0.0:src/dispute/AnchorStateRegistry.sol:188-236,331-370",
    "v9.0.0:src/dispute/AnchorStateRegistry.sol:188-236,331-370",
    "claim-valid game from the current DGF domain and one shared anchorGame pointer across types",
)
override(
    "3003",
    "lockbox-before-metered-body ordering first: v4.0.0:src/L1/OptimismPortal2.sol:740-788; current form: v9.0.0:src/L1/OptimismPortal2.sol:741-795",
    "v9.0.0:src/L1/OptimismPortal2.sol:741-795 and src/L1/ETHLockbox.sol:144-151",
    "deposit call-frame effects that are transactionally reverted if ResourceMetering later rejects",
    "no persistent cross-upgrade object identified: EVM transaction rollback kills the pre-metering lock/call effect (closed by C3 unless an external non-rollback observer appears)",
)
override(
    "3004",
    "shared-owner predicate first/current: v4.0.0:src/L1/ProxyAdminOwnedBase.sol:35-105; current universal location: v9.0.0:src/universal/ProxyAdminOwnedBase.sol:41-101",
    "v9.0.0:src/universal/ProxyAdminOwnedBase.sol:41-101 and src/L1/ETHLockbox.sol:180-235",
    "sampled proxyAdminOwner identity and any authorization persisted after that sample",
    "authorize while two proxy-admin owners compare equal, transfer only one owner later, then consume the monotonic authorization under divergent security domains",
)
override(
    "3005",
    "hard-coded migration clear list first: v7.0.0:src/L1/opcm/OPContractsManagerMigrator.sol:293-299; current shared list: v9.0.0:src/dispute/lib/Types.sol:51,101-118 and src/L1/opcm/OPContractsManagerMigrator.sol:537-541",
    "v9.0.0:src/L1/opcm/OPContractsManagerMigrator.sol:537-541 and src/L1/opcm/OPContractsManagerMigrationValidator.sol:713-739",
    "DGF implementation/gameArgs entries for any deployed game type omitted from the finite clear list",
    "create a game/config under a type absent from the migration's finite list, then consume it through the old DGF after listed types are cleared",
)
override(
    "3105",
    "first/current regression boundary: v9.0.0:src/L1/OptimismPortal2.sol:741-795; predecessor comparison: v8.0.0:src/L1/OptimismPortal2.sol:684-738",
    "v9.0.0:src/L1/OptimismPortal2.sol:741-795",
    "user-selected deposit calldata length and gasLimit at the v8→v9 implementation boundary",
    "construct a relayer/deposit envelope that fit the v8 implementation, then consume the same maximum-size calldata immediately after v9 under transaction/block gas caps",
)


def family_for(members: list[str]) -> str:
    choices = []
    for family, ids in FAMILY_IDS.items():
        count = len(set(members) & set(ids))
        if count:
            choices.append((count, family))
    if not choices:
        raise AssertionError(f"no family for {members}")
    return sorted(choices, reverse=True)[0][1]


def priority_for(members: list[str]) -> str:
    if set(members) & P0:
        return "P0"
    if set(members) & P1:
        return "P1"
    return "P2"


def next_experiment(members: list[str], family: str) -> str:
    ids = set(members)
    if ids & {"0102"}: return "L1: execute old-prestate type-9 games against the pre-v1.9.0 kona program and compare the exact prestate transition."
    if ids & {"0304", "0401", "0803", "1102", "1202"}: return "L3: replay parked failedMessages through targets with pause and migration transitions; measure whether value can become permanently unrecoverable."
    if ids & {"0503", "1101"}: return "L4: price a sustained Trojan super-root withdrawal-delay strategy using real bond/finality timing."
    if ids & {"0404", "0801", "1001", "1103", "1201", "3006", "3202"}: return "L5: solve the EIP-7825 transaction-gas cap against v9's 150k local reserve and maximum replay calldata."
    if ids & {"3105"}: return "L6: isolate the exact deposit calldata term added at U21 and find the smallest production payload that crosses a block/tx gas limit."
    if ids & {"0104", "0204", "0705", "2704"}: return "L7: trace the type-5 proposer call graph and test whether a born-resolved cross-type game can advance the shared anchor under every deployed forwarding path."
    if family == "migration" or ids & {"0901", "2303", "2305", "2901", "2903", "3005"}: return "L8/L9: reconstruct pre-migration per-chain ETH liability and compose orphaned singleton state, sticky authorization, and cleared game types."
    if ids & {"0101", "0505", "0702", "2703"}: return "closed on OP by C13; reopen on Ink/Soneium/Unichain or for an official-proposer root not recomputed in PASS A."
    if ids & {"0202"}: return "closed: C2"
    if ids & {"0203", "0501", "2501", "0406", "0502", "2502", "3103"}: return "closed: C4/C5 unless a pre-fault-proof non-game proof record is found."
    if family == "pause": return "closed: C8 unless a historical chain profile proves pointer or identifier divergence."
    if ids & {"2104"}: return "closed: C14"
    if family == "tooling": return "closed: C10/C14"
    if family == "gas-budget": return "closed: C6 for current rules; reopen on Amsterdam activation or L5 cap arithmetic."
    if family == "custody": return "closed: C3/C9 for current topology; reopen only with pre-U16 residue or historical authorization divergence."
    if family == "messenger-replay": return "closed: C5/C7 for direct replay; retain only if a historical hash-domain split or L3 composition is demonstrated."
    if family == "identity-binding": return "closed: C11/C12 unless the old kona prestate or a non-atomic ASR/DGF migration breaks the factory domain."
    if family == "upgrade-engine" or family == "storage-init": return "closed: C1 for the U21 bundle; exercise against the first historical layout/reinitializer version that differs."
    return "Historical fork: create the object at its earliest semantic ancestor, upgrade release-by-release, then invoke the U21 consumer."


def build_primitives() -> tuple[list[dict], dict[str, str]]:
    source_paths = sorted((PASS_A / "primitives").glob("PRIM-*.md"))
    ids = [p.stem.split("-")[1] for p in source_paths if p.stem not in {"PRIM-3301", "PRIM-3302", "PRIM-3303"}]
    # The corpus currently contains 115 files total; the brief explicitly excludes 3301..3303.
    assert len(ids) == 112, len(ids)
    grouped = {item for group in DEDUP_GROUPS for item in group}
    assert len(grouped) == sum(map(len, DEDUP_GROUPS)), "overlapping dedupe groups"
    assert grouped <= set(ids)
    groups = [sorted(g) for g in DEDUP_GROUPS] + [[i] for i in ids if i not in grouped]
    groups.sort(key=lambda g: int(g[0]))
    records = []
    source_to_a = {}
    for pos, members in enumerate(groups, 1):
        aid = f"A-{pos:03d}"
        family = family_for(members)
        facts = FAMILY_FACTS[family]
        paths = [PASS_A / "primitives" / f"PRIM-{i}.md" for i in members]
        title = clean_title(paths[0])
        if len(members) > 1:
            title += f" [exact PASS-A duplicates: {', '.join('PRIM-' + x for x in members)}]"
        rec = {
            "id": aid,
            "source_files": [str(p) for p in paths],
            "title": title,
            "family": family,
            "EARLIEST_SEMANTIC_ANCESTOR": facts["ancestor"],
            "CURRENT_U21_CONSUMER": facts["consumer"],
            "PERSISTENT_STATE_OR_OBJECT": facts["state"],
            "HISTORICAL_BRANCHES": facts["branches"],
            "AUDIT_COVERAGE_ALREADY_DONE": "TRACK-B",
            "UNREVIEWED_CROSS_UPGRADE_EDGE": facts["edge"],
            "NEXT_EXPERIMENT": next_experiment(members, family),
            "priority": priority_for(members),
            "pass_a_status": "primitive/negative retained; PASS A did not establish a permissionless bounty impact",
        }
        rec.update(PRIMITIVE_OVERRIDES.get(members[0], {}))
        records.append(rec)
        for member in members:
            source_to_a[member] = aid
    flattened = [Path(p).stem.split("-")[1] for r in records for p in r["source_files"]]
    assert sorted(flattened) == sorted(ids)
    assert not ({"3301", "3302", "3303"} & set(flattened))
    (OUT / "PRIMITIVES.json").write_text(json.dumps(records, indent=2) + "\n")
    return records, source_to_a


def build_matrix(records: list[dict], source_to_a: dict[str, str]) -> None:
    kept = [r for r in records if r["priority"] in {"P0", "P1"}]
    ids = [r["id"] for r in kept]
    cells: dict[tuple[str, str], set[str]] = {}

    def edge(producer: str, consumer: str, state: str) -> None:
        row, col = source_to_a[producer], source_to_a[consumer]
        if row in ids and col in ids:
            cells.setdefault((row, col), set()).add(state)

    # Only concrete create -> consume relations are entered; related-but-independent records stay blank.
    for c in ["0101", "0503", "1101", "2704"]: edge("2103", c, "old-config game clone + UUID")
    for c in ["0101", "0503", "0704", "2704"]: edge("2204", c, "clone immutable gameArgs")
    edge("0104", "2704", "born-resolved type-5 game / shared anchor candidate")
    for c in ["0301", "0504", "2403", "2505"]: edge("2406", c, "pre-U21 provenWithdrawal record")
    edge("0805", "0404", "legacy/old-budget messenger withdrawal")
    edge("0805", "0304", "legacy message hash and proven messenger withdrawal")
    edge("0304", "0304", "failedMessages entry with parked ETH")
    edge("2301", "2302", "ETHLockbox deposit balance")
    edge("2301", "2303", "pooled ETHLockbox balance")
    edge("2301", "2305", "per-chain lockbox liquidity")
    edge("0303", "2305", "portal surplus ETH")
    for c in ["0305", "0602", "2203"]: edge("0603", c, "pauseTimestamps[identifier]")
    edge("0602", "0103", "legacy DelayedWETH credit")
    edge("2305", "2303", "sticky authorizedPortals/authorizedLockboxes")
    edge("2305", "2902", "shared-lockbox authorization")
    edge("0605", "2308", "runtime feature bit over existing ETH/liability")
    edge("1003", "0102", "reinitialized ASR/DelayedWETH singleton pointer consumed by an old clone")
    edge("2201", "0201", "reinitialized dependency pointer")
    edge("2202", "0201", "packed ASR dependency pointer")
    edge("2102", "2205", "packed initializer byte selected for reset")

    with (OUT / "PRIMITIVE-COMPATIBILITY-MATRIX.csv").open("w", newline="") as fh:
        writer = csv.writer(fh)
        writer.writerow(["creates \\ consumes", *ids])
        for row in ids:
            writer.writerow([row, *["; ".join(sorted(cells.get((row, col), set()))) for col in ids]])


def lineage_record(surface: str, symbol: str, introduced: str, meaning: str, invariant: str,
                   changes: list[str], call_order: list[str], reverts: list[str], identity: list[str],
                   auth: list[str], pause: list[str], old_objects: list[str], migrations: list[str],
                   consumers: list[str], paths: list[str]) -> dict:
    return {
        "SURFACE": surface,
        "FUNCTION_OR_FIELD": symbol,
        "FIRST_INTRODUCED": introduced,
        "ORIGINAL_MEANING": meaning,
        "ORIGINAL_INVARIANT": invariant,
        "ALL_SEMANTIC_CHANGES": changes,
        "ALL_CALL_ORDER_CHANGES": call_order,
        "ALL_REVERT_SEMANTIC_CHANGES": reverts,
        "ALL_IDENTITY_SOURCE_CHANGES": identity,
        "ALL_AUTHORIZATION_CHANGES": auth,
        "ALL_PAUSE_SOURCE_CHANGES": pause,
        "OBJECTS_CREATED_UNDER_OLD_MEANING": old_objects,
        "MIGRATION_OR_INVALIDATION_EVENTS": migrations,
        "CURRENT_CONSUMERS": consumers,
        "UNREVIEWED_TRANSITIVE_PATHS": paths,
    }


def build_lineage() -> list[dict]:
    R = lineage_record
    data = [
        R("OptimismPortal/OptimismPortal2", "l2Sender; provenWithdrawals; proofSubmitters; finalizedWithdrawals",
          "v1.0.0:contracts/L1/OptimismPortal.sol:67-83",
          "One output-root proof per withdrawal hash; l2Sender is a reentrancy/context sentinel; finalization is hash-global.",
          "A withdrawal executes at most once, and only inside the authenticated L2-sender context.",
          ["v1.4.0:src/L1/OptimismPortal2.sol:51-95 — proof storage becomes hash×submitter and an append-only submitter list; selector/storage head survive.",
           "v9.0.0:src/L1/OptimismPortal2.sol:711-728 — permissionless delete clears one proof cell only; global finalization/list remain."],
          ["v1.0.0:contracts/L1/OptimismPortal.sol:383-409 — set finalized and l2Sender before target call, reset sender after.", "v4.0.0:src/L1/OptimismPortal2.sol:624-681 — lockbox unlock precedes target call; failed direct call relocks."],
          ["v1.4.0:src/L1/OptimismPortal2.sol:461-522 — validity failures move into checkWithdrawal.", "v9.0.0:src/L1/OptimismPortal2.sol:711-728 — delete reverts unless CHALLENGER_WINS or current-registry blacklist."],
          ["v1.4.0:src/L1/OptimismPortal2.sol:83-95 — proof submitter becomes part of proof identity, not execution identity."],
          [], [],
          ["All L2OO proofs, per-submitter game proofs, duplicated submitter entries, and finalized hashes written since Bedrock."],
          ["v1.4.0 fault-proof migration changes proof keying without changing finalization key.", "v7.0.0 super-game migration changes the game/root meaning while preserving cells.", "v9.0.0 adds selective deletion."],
          ["v9.0.0:src/L1/OptimismPortal2.sol:577-728"],
          ["Pre-v1.4 proof records if any survived historical production migration; current cleanup of a legacy/non-game address (C4 reopen condition)."]),

        R("OptimismPortal/OptimismPortal2", "initialize; paused; guardian; superchainConfig",
          "v1.0.0:contracts/L1/OptimismPortal.sol:50-60,83,165-187",
          "Portal stored immutable dependencies plus a local guardian-controlled paused bool.",
          "The same guardian and pause bit gate proving/finalization for one portal.",
          ["v1.1.0:src/L1/OptimismPortal.sol:120-135 — oracle/SystemConfig/guardian become initialized storage.",
           "v1.2.0:src/L1/OptimismPortal.sol:147-149 — pause/guardian route through SuperchainConfig.",
           "v1.4.0:src/L1/OptimismPortal2.sol:163-190 — initializer adds DGF and game-validity state.",
           "v4.0.0:src/L1/OptimismPortal2.sol:250-273,294-318 — dependencies reinitialized; pause/guardian route through SystemConfig.",
           "v4.1.0:src/L1/OptimismPortal2.sol:222-260,446-514,566-616 — lockbox use becomes feature-gated.",
           "v7.0.0:src/L1/OptimismPortal2.sol:251-281 — initializer accepts lockbox and interop config.",
           "v9.0.0:src/L1/OptimismPortal2.sol:273-330 — pause, guardian, and SuperchainConfig now route through ETHLockbox."],
          [], ["v9.0.0:src/L1/OptimismPortal2.sol:273-303 — initializer rejects invalid interop/lockbox combinations."],
          ["v1.0.0 local guardian → v1.2.0 SuperchainConfig → v4.0.0 SystemConfig → v9.0.0 ETHLockbox: v9.0.0:src/L1/OptimismPortal2.sol:306-330."],
          ["v1.0.0 guardian direct calls; current setters/migrations require ProxyAdmin or its owner: v9.0.0:src/L1/OptimismPortal2.sol:273-303,528-572."],
          ["v1.0.0 local bool; v1.2.0 global SC; v4.0.0 SystemConfig-selected scoped key; v9.0.0 local-or-global ETHLockbox key."],
          ["Pause timestamps under portal/SystemConfig identifiers and dependency pointers initialized before U21."],
          ["Each reinitializer preserves proxy storage but changes the authority/pause indirection; v9 migrateToSharedDisputeGame can repoint lockbox/ASR."],
          ["prove/finalize/deposit bridge pause checks: v9.0.0:src/L1/OptimismPortal2.sol:390-492,577-666,741-795"],
          ["Historic pointer divergence on a non-profiled chain; old scoped pause timestamp consumed after identifier pivot (C8 reopen)."]),

        R("OptimismPortal/OptimismPortal2", "proveWithdrawalTransaction; checkWithdrawal; blacklist/respected-type/retirement",
          "v1.0.0:contracts/L1/OptimismPortal.sol:242-318",
          "Proof binds an L2 output-oracle proposal to withdrawal storage; proof validity is stored with the oracle root.",
          "Only a finalized canonical output root can authorize a withdrawal.",
          ["v1.4.0:src/L1/OptimismPortal2.sol:254-328,441-522 — indexed game proof; Portal owns blacklist, respected type, cutoff and rechecks them at finalization.",
           "v2.0.0:src/L1/OptimismPortal2.sol:292-378 — respect is snapshotted at game creation and creation must be after cutoff.",
           "v4.0.0:src/L1/OptimismPortal2.sol:439-570,693-727 — validity governance moves into ASR; super-root proof branch added.",
           "v4.1.0:src/L1/OptimismPortal2.sol:430-570 — output-root Portal2 and interop Portal split.",
           "v7.0.0:src/L1/OptimismPortal2.sol:368-471 — one function branches on registered game type and extracts per-chain root from super games.",
           "v9.0.0:src/L1/OptimismPortal2.sol:390-492,671-705 — current ASR proper/respected checks and current-registry revalidation."],
          ["v1.4.0 proves game identity before MPT inclusion and writes last; v4.0.0 delegates current validity to ASR before root-format branch."],
          ["v1.4.0 allowed reprove after root change; v2.0.0 rejects games not respected at creation; v4.0.0 returns InvalidRootClaim through ASR result."],
          ["L2OO address+index → DGF index/game address → ASR's DGF registration plus game-snapshotted respect; super game additionally uses SystemConfig.l2ChainId."],
          ["v1.4.0 Portal guardian setters → v4.0.0 ASR guardian setters: v9.0.0:src/dispute/AnchorStateRegistry.sol:156-185."],
          ["v4.0.0 ASR pause participates in isGameProper; v9 routes it via ETHLockbox: v9.0.0:src/dispute/AnchorStateRegistry.sol:136-143,286-305."],
          ["Old L2OO proofs, games created under each respected-type/prestate, and proof cells referencing an old DGF/ASR."],
          ["Fresh-ASR migration retires old games; current initializer retains an already nonzero retirement timestamp: v9.0.0:src/dispute/AnchorStateRegistry.sol:124-132."],
          ["v9.0.0:src/L1/OptimismPortal2.sol:390-492,671-705; src/dispute/AnchorStateRegistry.sol:227-352"],
          ["L1: pre-v1.9 kona prestate game consumed by current ASR; L8: old game/proof after shared-registry migration."]),

        R("OptimismPortal/OptimismPortal2", "finalizeWithdrawalTransactionExternalProof; unsafe targets",
          "base finalize: v1.0.0:contracts/L1/OptimismPortal.sol:325-420; external-proof overload: v1.4.0:src/L1/OptimismPortal2.sol:339-387",
          "Anyone may execute a mature proof; global finalization is committed before the target call; failed target call is normally non-reverting.",
          "Global hash replay protection survives arbitrary finalizer identity and target behavior.",
          ["v1.4.0:src/L1/OptimismPortal2.sol:339-387 — caller may select another proof submitter.",
           "v4.0.0:src/L1/OptimismPortal2.sol:624-681,805-808 — ETH unlock/relock surrounds call and lockbox joins unsafe-target list.",
           "v9.0.0:src/L1/OptimismPortal2.sol:577-666 — failed L1CDM call from the L2CDM sender now reverts the entire finalization; other failures remain finalized/relocked."],
          ["v4.0.0 unlock before finalized bit/target then exact relock on failure; v9 checks feature/pause/game before unlock and performs messenger-specific revert after call."],
          ["v1.0.0 only estimation-origin failure reverts after target failure; v9 additionally reverts failed L1CDM messenger withdrawals at lines 639-653."],
          ["Unsafe target began as Portal/self; v4 adds current ETHLockbox; retired lockboxes and sibling portals are not identity-derived targets: v9.0.0:src/L1/OptimismPortal2.sol:846-849."],
          [], ["Pause source follows Portal generations; current check is lockbox pause before state mutation: v9.0.0:src/L1/OptimismPortal2.sol:583-589."],
          ["Mature proofs from every prior proof regime; failedMessages and portal/lockbox balances produced before U21."],
          ["v9 messenger atomicity invalidates the prior finalized+failed L1CDM outcome but deliberately retains direct-call failure semantics."],
          ["ETHLockbox, L1CrossDomainMessenger, arbitrary L1 target, SafeCall: v9.0.0:src/L1/OptimismPortal2.sol:620-660"],
          ["L3 replay callback → nested finalization → parked L1CDM value across pause/migration; retired-lockbox target after shared migration."]),

        R("OptimismPortal/OptimismPortal2", "depositTransaction; donateETH; migrateLiquidity; migrateToSuperRoots/migrateToSharedDisputeGame",
          "deposit/donate: v1.0.0:contracts/L1/OptimismPortal.sol:196-215,434-490; migrations: v4.0.0:src/L1/OptimismPortal2.sol:374-429",
          "Deposits escrow msg.value in Portal and emit an opaque L2 mint/call-value transaction; donate accepts unaccounted ETH.",
          "Deposit value is exactly escrowed once; migration cannot strand the active withdrawal backing.",
          ["v1.6.0:src/L1/OptimismPortal2.sol:362-440,504-573 — custom-gas-token mode separates native balance accounting.",
           "v4.0.0:src/L1/OptimismPortal2.sol:374-429,740-788 — deposits lock ETH in ETHLockbox; portal liquidity and super-root migrations added.",
           "v4.1.0:src/L1/OptimismPortal2.sol:222-260,446-514,566-616 — lockbox use becomes feature-gated.",
           "v7.0.0:src/L1/OptimismPortal2.sol:503-537 — shared-dispute-game migration repoints lockbox and ASR.",
           "v8.0.0:src/L1/OptimismPortal2.sol:510-554 — nonzero/new-lockbox authorization checks hardened.",
           "v9.0.0:src/L1/OptimismPortal2.sol:502-572,741-795 — CGT guard and current shared migration."],
          ["v4.0.0 deposit body locks ETH before ResourceMetering modifier completes: v9.0.0:src/L1/OptimismPortal2.sol:741-795."],
          ["Lockbox authorization/balance failures now revert deposit; CGT rejects positive ETH liability paths: v9.0.0:src/L1/OptimismPortal2.sol:741-759."],
          ["Custody address changes from Portal itself to its current ETHLockbox; migration selects a new shared lockbox/ASR."],
          ["Migration restricted to ProxyAdmin owner and same-admin authorization: v9.0.0:src/L1/OptimismPortal2.sol:528-572."],
          ["Deposits intentionally stay open while unlocks are paused: v9.0.0:src/L1/ETHLockbox.sol:142-159."],
          ["Portal surplus, per-chain lockbox liquidity, historical deposits and sticky authorization records."],
          ["migrateLiquidity drains portal to lockbox; shared migration authorizes/repoints and separately migrates old lockbox liquidity."],
          ["v9.0.0:src/L1/ETHLockbox.sol:124-235; src/L1/OptimismPortal2.sol:502-572,741-795"],
          ["L8/L9: pre-pooling L2 ETH liability vs each lockbox; orphaned per-chain lockbox and portal surplus after cutover."]),

        R("OptimismPortal2", "deleteProvenWithdrawal",
          "v9.0.0:src/L1/OptimismPortal2.sol:711-728",
          "Anyone may clear one submitter's proof only after its game is challenger-wins or current-registry-blacklisted.",
          "Deletion cannot make a still-finalizable proof unavailable and cannot clear global replay protection.",
          [], ["status() is called before current-registry blacklist at v9.0.0:src/L1/OptimismPortal2.sol:717-723."],
          ["A no-code/reverting stored game makes cleanup revert before blacklist; deletion does not cover retirement/unregistration."],
          ["Blacklist identity is the Portal's current ASR, not necessarily the ASR that accepted the proof."],
          [], [], ["All pre-v9 proof cells and stale proofSubmitters entries."],
          ["Shared-registry swap makes old proofs dead but normally undeletable unless the new ASR blacklists the old address."],
          ["proof cell/list and checkWithdrawal: v9.0.0:src/L1/OptimismPortal2.sol:671-728"],
          ["Pre-fault-proof/non-game storage record (C4 reopen); cleanup after a non-atomic registry swap."]),

        R("CrossDomainMessenger", "relayMessage; hash versions; replay/reentrancy; gas constants",
          "v1.0.0:contracts/universal/CrossDomainMessenger.sol:123-193,303-413",
          "Accept v0 legacy and v1 canonical hashes; initial relay authenticates other messenger, replay requires failedMessages; sentinel blocks reentrancy; every nonreverting call writes success or failure.",
          "One economic message cannot succeed twice, and failed messages remain permissionlessly retryable.",
          ["v1.2.0:src/universal/CrossDomainMessenger.sol:219-330 — relay becomes pause-aware and asserts success mapping consistency.",
           "v1.3.0:src/universal/CrossDomainMessenger.sol:80-110 — otherMessenger changes immutable→storage without changing hash.",
           "v3.0.0:src/universal/CrossDomainMessenger.sol:354-390 — baseGas accounts for EIP-7623 calldata floor.",
           "v9.0.0:src/universal/CrossDomainMessenger.sol:212-302,334-373 — local reserve/check split from advertised remote budget."],
          ["Initial/replay branch precedes unsafe-target and success checks; gas/reentrant failure is recorded before target call; target call then selects success vs failed mapping."],
          ["Low local gas or reentrant sentinel returns after marking failed, rather than reverting; current Portal wraps a failed L1CDM low-level call with a withdrawal-level revert."],
          ["v0 uses legacy hash; v1+ canonical hash includes value/minGas/nonce; replay identity remains canonical message hash."],
          ["Initial relay uses authenticated other messenger; replay is public but requires failedMessages."],
          ["v1.2 adds chain pause; L1 source changes SuperchainConfig→SystemConfig in v4: v9.0.0:src/L1/L1CrossDomainMessenger.sol:98-100."],
          ["Legacy v0 hashes, successful/failed mappings, in-flight withdrawals sized under older remote constants."],
          ["Proxy upgrades preserve mapping slots and legacy hash branch; U21 changes local execution budget without migrating message objects."],
          ["Portal, L1StandardBridge and arbitrary message target: v9.0.0:src/universal/CrossDomainMessenger.sol:256-302"],
          ["L3 forced failedMessages × target replay/pause/migration; L5 transaction cap × maximum calldata and local reserve."]),

        R("L1CrossDomainMessenger", "paused; _isUnsafeTarget; local/remote gas getters",
          "v1.0.0:contracts/L1/L1CrossDomainMessenger.sol:45-66",
          "Portal authenticates L2 messenger; Portal and messenger itself are unsafe relay targets; no L1 pause override.",
          "Relayed calls cannot recursively control the transport contracts.",
          ["v1.2.0:src/L1/L1CrossDomainMessenger.sol:63-64 — pause supplied by SuperchainConfig.",
           "v4.0.0:src/L1/L1CrossDomainMessenger.sol:74-75 — pause supplied by SystemConfig.",
           "v9.0.0:src/L1/L1CrossDomainMessenger.sol:43-74,117-153 — exposes distinct local 135k/15k budget and remote-budget getters."],
          [], ["Current local budget can reject/record failure even when the remote advertised floor was lower."],
          ["Portal address remains the authentication and unsafe-target identity; its SystemConfig now supplies pause indirectly through lockbox."],
          ["onlyOtherMessenger still resolves through Portal l2Sender: v9.0.0:src/L1/L1CrossDomainMessenger.sol:129-143."],
          ["none → SuperchainConfig → SystemConfig → SystemConfig→Portal→ETHLockbox."],
          ["All old-budget L2→L1 messages and failedMessages."], [],
          ["CrossDomainMessenger.relayMessage and Portal finalization."],
          ["Amsterdam/EIP-7825 budget boundary; historical v0 message encoded under pre-Bedrock budget."]),

        R("SafeCall", "hasMinGas; callWithMinGas",
          "v1.0.0:contracts/libraries/SafeCall.sol:91-159",
          "Precheck EIP-150 forwarding plus 40k reserve, then call with exactly the requested minimum-gas envelope.",
          "Caller retains enough gas to record the outcome after an adversarial callee.",
          ["v1.6.0:src/libraries/SafeCall.sol:93-161 — overload/refactor preserves reserve meaning.",
           "v9.0.0:src/libraries/SafeCall.sol:7-9,103-171 — value call to codehash-zero target reserves 183,600 future new-account state gas."],
          ["State-dependent codehash test occurs before computing the call gas/reserve at v9 lines 121-171."],
          ["Insufficient envelope returns false from hasMinGas or reverts the guarded call; target failure remains a boolean."],
          ["Target codehash now changes the gas identity class."], [], [],
          ["Persisted messages targeting accounts that were empty/nonempty at different times."], [],
          ["Portal finalization and CrossDomainMessenger relay."],
          ["L5: empty-target state transition between proof and relay; Amsterdam actual cost vs pre-reserved 183,600."]),

        R("StandardBridge", "finalizeBridgeETH/finalizeBridgeERC20 (legacy finalizeETHWithdrawal/finalizeERC20Withdrawal)",
          "v1.0.0:contracts/universal/StandardBridge.sol:294-348",
          "Only the counterpart bridge may finalize; ETH requires exact msg.value and successful recipient call; ERC20 mints native token or decrements escrow then transfers.",
          "Exactly one messenger-authenticated finalize releases/mints exactly the encoded amount.",
          ["v1.2.0:src/universal/StandardBridge.sol:250-340 — both finalize paths become pause-aware.",
           "v2.0.0:src/universal/StandardBridge.sol:230-310 — naming/interface refactor; custody invariant unchanged.",
           "v9.0.0:src/universal/StandardBridge.sol:239-299 — current exact-value and escrow/mint split."],
          ["ETH external call follows messenger authentication, pause, value and unsafe recipient checks; ERC20 escrow decrement precedes transfer."],
          ["ETH recipient failure reverts bridge call; messenger records failure/replay rather than partial release."],
          ["Native-vs-remote token pair selects mint vs escrow branch."],
          ["onlyOtherBridge resolves xDomainMessageSender through messenger: v9.0.0:src/universal/StandardBridge.sol:111-117."],
          ["v1.2 virtual pause; current L1 bridge ultimately consumes ETHLockbox-key pause through SystemConfig."],
          ["Legacy v0 bridge messages, escrowed ERC20 balances, failedMessages."], [],
          ["L1/L2 CrossDomainMessenger and token contracts."],
          ["Legacy hash-domain change describing the same bridge release (C5 reopen); L3 replay target composition."]),

        R("SystemConfig", "initialize arguments; address storage scheme",
          "v1.0.0:contracts/L1/SystemConfig.sol:43-64,125-143",
          "Initialize owner, fee scalars, batcher/gas limit, unsafe-block signer and resource config in ordinary storage.",
          "One authoritative per-chain configuration supplies derivation and L1 contract dependencies.",
          ["v1.1.0:src/L1/SystemConfig.sol:30-73,155-191 — Addresses struct moves dependencies into fixed unstructured slots and adds startBlock/batchInbox.",
           "v1.2.0:src/L1/SystemConfig.sol:109-150 — maintenance branch temporarily retains lean initializer shape.",
           "v1.3.0:src/L1/SystemConfig.sol:150-210 — structured address scheme restored with automatic startBlock.",
           "v4.0.0:src/L1/SystemConfig.sol:133-200 — l2ChainId and SuperchainConfig added.",
           "v4.1.0:src/L1/SystemConfig.sol:139-226 — features mapping enters initializer state.",
           "v9.0.0:src/L1/SystemConfig.sol:49-99,203-248 — Addresses includes DelayedWETH/OPCM; no batch-inbox initializer argument."],
          [], ["Current initializer has explicit dependency validity and ProxyAdmin authority checks."],
          ["Dependency identity moves from ordinary fields to named slots; l2ChainId becomes the Portal's super-game chain selector."],
          ["Initializer authority evolves to ProxyAdmin or owner under ReinitializableBase."], [],
          ["Every proxy slot/address written by older initializers and all deposits/games using the historical chain config."],
          ["OPCM reset/reinitializer rewrites named addresses but retains fee/config state."],
          ["Portal, bridges, messenger, resource metering, dispute games."],
          ["Pre-v1.3 chain whose temporarily lean initializer history differs; l2ChainId written after a game root was created."]),

        R("SystemConfig", "features; paused; superchainConfig; guardian",
          "superchainConfig/l2ChainId: v4.0.0:src/L1/SystemConfig.sol:133-200; features: v4.1.0:src/L1/SystemConfig.sol:139,503-534",
          "SystemConfig owned feature bits and selected a portal-or-lockbox pause identifier against SuperchainConfig.",
          "Feature transitions cannot enable an invalid custody mode, and all chain contracts observe one pause/guardian.",
          ["v4.1.0:src/L1/SystemConfig.sol:503-534 — feature map and pause-key selection introduced.",
           "v9.0.0:src/L1/SystemConfig.sol:532-581 — ETH_LOCKBOX/INTEROP are immutable once set; paused delegates to Portal's lockbox while guardian remains the stored SC guardian."],
          ["v9 setFeature checks portal-identifier pause before enabling ETH_LOCKBOX; paused then calls Portal→ETHLockbox."],
          ["Feature transitions reject disabling immutable features and some paused enables."],
          ["Pause identifier changes SystemConfig/Portal→Portal's ETHLockbox, while guardian identity remains SystemConfig.superchainConfig."],
          ["onlyOwner sets features: v9.0.0:src/L1/SystemConfig.sol:532-568."],
          ["v4.1 local/global key selection; v9 Portal-lockbox delegation."],
          ["Existing ETH, proofs, messages and games when a runtime feature flips."],
          ["OPCM migrations enable features and repoint Portal; no object-by-object conversion."],
          ["Portal, messenger, bridges, resource-metered deposit path."],
          ["Privileged feature transition over pre-existing liquidity; independent L1/L2 feature state machines."]),

        R("SuperchainConfig", "guardian; pause generations",
          "v1.2.0:src/L1/SuperchainConfig.sol:19-23,49-81",
          "One guardian controls one global unstructured paused bit.",
          "A global pause consistently blocks security-critical exits until guardian unpauses.",
          ["v4.0.0:src/L1/SuperchainConfig.sol:40-182 — pause becomes expiring timestamp mapping keyed by identifier; initializer migrates old guardian/global pause.",
           "v9.0.0:src/L1/SuperchainConfig.sol:30-40,79-153 — local paused(address) excludes global; new isLocalOrGlobalPaused explicitly ORs both."],
          ["pause refuses any nonzero historical timestamp, even expired; extend refreshes a nonzero timestamp: v9 lines 79-120."],
          ["Expired pause reads false but still makes pause() revert AlreadyPaused; guardian must unpause/extend."],
          ["Pause identity expands global address(0) → arbitrary address → current ETHLockbox consumers."],
          ["Guardian remains initializer-set and directly authorizes pause/unpause/extend."],
          ["global bool → expiring scoped mapping → explicit local-or-global helper."],
          ["All historical nonzero pause timestamps, including inert/expired keys."],
          ["v4 initializer clears/migrates old global state; v9 preserves timestamps and changes consumers."],
          ["ETHLockbox.paused at v9.0.0:src/L1/ETHLockbox.sol:112-113; legacy consumers of paused()."],
          ["Historical identifier divergence; a non-lockbox timestamp made operational again by future pointer reuse."]),

        R("AnchorStateRegistry", "anchors → anchorGame/startingAnchorRoot; setAnchorState",
          "v1.4.0:src/dispute/AnchorStateRegistry.sol:20-87",
          "Store an independent anchor root per game type; a registered defender-win game may advance its type's anchor.",
          "Only a valid newer output for that game type advances that type's starting state.",
          ["v1.6.0:src/dispute/AnchorStateRegistry.sol:99-119 — guardian can override an anchor via SuperchainConfig authority.",
           "v2.0.0:src/dispute/AnchorStateRegistry.sol:39-84,239-262 — per-type mapping collapses to one anchorGame plus starting root.",
           "v4.0.0:src/dispute/AnchorStateRegistry.sol:34-55,168-200,294-340 — ASR owns validity/retirement and one shared anchor.",
           "v7.0.0:src/dispute/AnchorStateRegistry.sol:94-133 — reinitializer may clear anchor only when a changed starting root is ahead.",
           "v9.0.0:src/dispute/AnchorStateRegistry.sol:188-212,355-370 — legacy anchors(type) returns the same current root for every type."],
          ["Current setAnchorState runs full isGameClaimValid before comparing l2SequenceNumber."],
          ["Mixed output-root block numbers and super-root timestamps share one monotonic comparison."],
          ["Anchor identity changes (gameType,root) mapping → one game address/factory domain."],
          ["Permissionless claim-valid game can advance; guardian can change validity inputs rather than direct current setter."],
          ["v4 isGameProper incorporates pause; v9 pause comes from ETHLockbox."],
          ["Per-type anchors, output-root games and super-root games with different sequence-number units."],
          ["Fresh-ASR migration installs a starting root; reinitializer can preserve or clear current anchor under ahead check."],
          ["Dispute-game initialization and fault-proof programs; Portal proof validity."],
          ["L7 type-5 born-resolved game advancing shared anchor; old output-root block number versus timestamp ordering."]),

        R("AnchorStateRegistry", "isGameRegistered/isGameRespected/isGameRetired/isGameProper/isGameClaimValid",
          "registration precursor: v1.4.0:src/dispute/AnchorStateRegistry.sol:59-87; full predicate set: v2.0.0:src/dispute/AnchorStateRegistry.sol:116-239",
          "Factory membership plus current Portal-owned respect/blacklist/cutoff/finality defines whether one game claim can authorize a withdrawal.",
          "Only an authentic, noninvalidated, finalized defender-win game respected when created is claim-valid.",
          ["v2.0.0:src/dispute/AnchorStateRegistry.sol:116-239 — single-game validity predicates introduced, reading Portal governance.",
           "v4.0.0:src/dispute/AnchorStateRegistry.sol:182-340 — ASR owns DGF, blacklist, respected type, retirement; registration also checks game.anchorStateRegistry().",
           "v6.0.0:src/dispute/AnchorStateRegistry.sol:107-115 — reinitialize sets retirement only if zero.",
           "v7.0.0:src/dispute/AnchorStateRegistry.sol:215-352 — registration removes embedded-ASR equality; retirement-at-init is the invalidation boundary; proper no longer requires current type.",
           "v9.0.0:src/dispute/AnchorStateRegistry.sol:227-352 — current registered/snapshotted-respect/retirement/pause/finality predicates."],
          ["isGameClaimValid calls proper → respected → finalized → status; Portal prove may accept proper/respected before game is final."],
          ["Registration ABI failure reverts; ordinary invalidation predicates return false; retirement uses <= timestamp."],
          ["Portal governance → ASR storage; embedded ASR equality removed in favor of DGF UUID domain and retirement."],
          ["Guardian writes blacklist/type/retirement via current ETHLockbox guardian: v9 lines 156-185,374-378."],
          ["v4 proper includes pause; v9 pause source pivots SystemConfig→ETHLockbox."],
          ["Every game clone created before a reinitializer, DGF swap, type change or retirement update."],
          ["Fresh DGF+ASR makes old games unregistered and retired; in-place reinitializer preserves nonzero retirement."],
          ["Portal prove/check/finalize and setAnchorState."],
          ["L1 old prestate game under current predicate; L8 DGF/ASR partial cutover; game with old immutable ASR after registration check removal."]),

        R("AnchorStateRegistry", "guardian; blacklist; respectedGameType; retirementTimestamp; pause dependency",
          "guardian anchor override: v1.6.0:src/dispute/AnchorStateRegistry.sol:99-119; owned governance fields: v4.0.0:src/dispute/AnchorStateRegistry.sol:34-55,127-159",
          "Guardian can invalidate exact games, change accepted type, or blanket-retire old games; SystemConfig supplies guardian/pause.",
          "Emergency invalidation is monotonic enough that a known-bad game cannot later authorize a withdrawal accidentally.",
          ["v6.0.0:src/dispute/AnchorStateRegistry.sol:107-115 — reinitialization no longer advances an existing retirement timestamp.",
           "v9.0.0:src/dispute/AnchorStateRegistry.sol:33-59,94-185 — SystemConfig slot becomes spacer; ETHLockbox supplies pause, guardian and SuperchainConfig."],
          [], ["Retirement equality is invalid (createdAt <= retirement); blacklist is address exact and permanent."],
          ["Guardian and pause identity change from SC/SystemConfig to ETHLockbox while DGF/game identity is unchanged."],
          ["Guardian through ethLockbox.guardian at v9 lines 374-378; initialize through ProxyAdmin/owner at lines 103-105."],
          ["SystemConfig.paused → ETHLockbox.paused."],
          ["Games created when a type was respected and proofs referring to a pre-retirement game."],
          ["In-place U21 reinitialize preserves retirement; fresh shared ASR stamps migration time and retires all old games."],
          ["isGameProper/isGameClaimValid, Portal prove/check, setAnchorState."],
          ["Current-state-only PASS A census does not prove historical blacklist/type/retirement transitions on every chain."]),

        R("DisputeGameFactory", "create; UUID inputs; gameArgs",
          "v1.0.0:contracts/dispute/DisputeGameFactory.sol:30-37,78-162",
          "Clone implementation selected by gameType with immutable rootClaim+extraData; UUID identifies (type,root,extra).",
          "At most one registered game exists for a UUID and its immutable arguments cannot change.",
          ["v1.1.0:src/dispute/DisputeGameFactory.sol:30-115 — append-only GameId list/timestamp and upgradeability added.",
           "v1.2.0:src/dispute/DisputeGameFactory.sol:87-134 — init bonds and abi.encode UUID form established.",
           "v1.4.0:src/dispute/DisputeGameFactory.sol:84-132 — creator/root/parentHash/extraData immutable layout.",
           "v5.0.0:src/dispute/DisputeGameFactory.sol:70-190,278-292 — mutable per-type gameArgs appended to future clones.",
           "v6.0.0:src/dispute/DisputeGameFactory.sol:140-220 — empty legacy args and explicit-gameType new layout bifurcate clone decoding.",
           "v7.0.0:src/dispute/DisputeGameFactory.sol:147-225 — collision check precedes deterministic CREATE2 clone.",
           "v9.0.0:src/dispute/DisputeGameFactory.sol:147-245,312-318 — current dual-layout create and dynamic gameArgs setter."],
          ["v1 create cloned/initialized before collision store; v7 checks UUID collision before deterministic clone; initialization still precedes registry/list write."],
          ["Duplicate UUID now fails before external clone initialization rather than after it."],
          ["UUID inputs stay type/root/extra while clone identity also depends on factory CREATE2 domain and mutable implementation/gameArgs."],
          ["Anyone creates after posting initBond; owner configures implementation, args and bond."],
          [], ["Every clone permanently embeds the implementation args active at creation; append-only list preserves old entries."],
          ["Implementation/gameArgs updates bifurcate old/new clones without migrating them; DGF replacement changes registration domain."],
          ["ASR registration and Portal proof game-index lookup."],
          ["Old clone under pre-current gameArgs/prestate consumed by current mutable ASR; incomplete clearedGameTypes during migration."]),

        R("DelayedWETH", "fallback deposit; unlock/withdraw/recover; pause/guardian dependency",
          "v1.4.0:src/dispute/weth/DelayedWETH.sol:20-92 and src/dispute/weth/WETH98.sol:28-42",
          "WETH receive/fallback deposits mint; unlock starts a delay; withdraw burns/transfers after delay and global SC pause check; guardian recovers excess.",
          "Recorded bond credit is redeemable once after delay, subject only to emergency pause, and recover cannot consume backed credit.",
          ["v1.6.0:src/dispute/weth/DelayedWETH.sol:85-98 — recover uses call instead of transfer.",
           "v9.0.0:src/dispute/DelayedWETH.sol:37-129 — SystemConfig slot becomes spacer; ETHLockbox supplies pause/guardian/SC."],
          ["unlock writes timestamp/amount; withdraw validates pause+delay then clears/burns/transfers."],
          ["Unknown payable selector still succeeds as WETH fallback deposit; nonpayable unknown selector reverts by value requirement."],
          ["Pause/guardian identity moves SC→SystemConfig→ETHLockbox; token-credit identity stays account address."],
          ["Game owner can unlock/withdraw its credit; guardian recovery routes through current lockbox guardian."],
          ["global SuperchainConfig → per-chain SystemConfig → v9 ETHLockbox local-or-global."],
          ["Credits/unlock timestamps in old DelayedWETH proxies and games immutable-bound to an older proxy."],
          ["OPCM may reinitialize singleton pointers, but immutable game clones can retain old DelayedWETH addresses."],
          ["Dispute games' bond credit and guardian recovery."],
          ["L8 orphaned legacy WETH credit after shared migration; pause behavior of pre-v1.4 deployments."]),

        R("ETHLockbox", "authorized portals/lockboxes; lockETH/unlockETH; migrateLiquidity; pause/guardian",
          "v4.0.0:src/L1/ETHLockbox.sol:67-219",
          "Per-chain lockbox escrows Portal deposits, returns value through donateETH before withdrawal execution, and can migrate all balance to an authorized same-owner lockbox.",
          "Only authorized same-domain portals debit; unlock is paused, nonreentrant against an executing withdrawal, and backed by balance.",
          ["v7.0.0:src/L1/ETHLockbox.sol:67-232 — shared-lockbox authorization/migration paths are used by interop migration.",
           "v9.0.0:src/L1/ETHLockbox.sol:66-78,94-235 — SystemConfig slot becomes spacer; SC stored directly; local-or-global pause keyed by lockbox."],
          ["unlock checks pause/auth/balance/l2Sender then donateETH; Portal then marks/calls and may relock. migrate reads whole balance then calls receiveLiquidity."],
          ["Unauthorized, paused, insufficient or during-withdrawal unlock reverts; locks intentionally do not check pause."],
          ["Portal domain check resolves its SystemConfig.superchainConfig, not Portal.superchainConfig, at v9 lines 220-228."],
          ["ProxyAdmin owner authorizes; shared owner equality is sampled at authorization/migration time and authorization is monotonic."],
          ["SystemConfig.paused in v4 → directly stored SuperchainConfig.isLocalOrGlobalPaused(this) in v9."],
          ["All lockbox balances and authorization entries from per-chain/shared generations."],
          ["Portal migrate/repoint and lockbox migrate are separate calls expected to be atomic in governed batch."],
          ["Portal deposit/finalize/migrate and other authorized lockboxes."],
          ["L8 sticky retired lockbox authorization; L9 per-chain liability before pooling; later PA ownership divergence after authorization."]),

        R("ProxyAdmin", "proxy type/name mappings; upgrade; upgradeAndCall",
          "v1.0.0:contracts/universal/ProxyAdmin.sol:40-70,211-260",
          "Owner chooses proxy adapter (ERC1967/chugsplash/resolved) and performs implementation upgrades or upgrade+call.",
          "Only current owner can mutate implementation; adapter-specific routing reaches the intended proxy.",
          ["v4.0.0:src/universal/ProxyAdmin.sol:120-194 — proxy adapter support refactored without changing owner gate.",
           "v9.0.0:src/universal/ProxyAdmin.sol:152-192 — current upgrade and upgradeAndCall behavior remains owner-gated."],
          ["upgradeAndCall upgrades first and calls initializer atomically."],
          ["Adapter misclassification causes adapter-specific revert; successful call commits both implementation and initialization."],
          ["Proxy type/name and AddressManager mappings select target semantics."],
          ["Ownable owner is sole external upgrade authority."], [],
          ["Every proxy registered under historical type/name metadata."],
          ["OPCM invokes ProxyAdmin from the governed Safe context; ownership transfers change authority without proxy storage migration."],
          ["All L1 proxy upgrades."],
          ["Historical proxy registered with a different adapter/name than current OPCM metadata."]),

        R("ProxyAdminOwnedBase", "proxyAdmin; proxyAdminOwner; shared-owner assertions",
          "v4.0.0:src/L1/ProxyAdminOwnedBase.sol:35-105",
          "Implementation discovers its proxy admin through the proxy owner slot (including resolved-proxy special cases), then derives ProxyAdmin.owner and compares domains.",
          "Privileged cross-contract operations require the same live ProxyAdmin owner/security domain.",
          ["v7.0.0:src/universal/ProxyAdminOwnedBase.sol:35-105 — file moves to universal; semantics remain.",
           "v9.0.0:src/universal/ProxyAdminOwnedBase.sol:41-101 — current owner probing and shared-owner assertion."],
          ["shared-owner check reads both owners at call time; authorizers may persist the result after ownership later diverges."],
          ["Nonproxy/unrecognized proxy shapes revert on owner probing."],
          ["ERC1967 PROXY_OWNER slot first; resolved-delegate special mapping slots second."],
          ["ProxyAdmin or its owner gates initialize; ProxyAdmin owner alone gates cross-domain authorization/migration."],
          [], ["Monotonic authorizations created when owners matched."],
          ["No automatic invalidation on later ownership transfer."],
          ["Portal/ETHLockbox/ASR/DGF initializers and lockbox migration."],
          ["L8 authorization snapshot consumed after one ProxyAdmin ownership changes; spoofable proxyAdminOwner on untrusted address before a stronger identity check."]),
    ]

    # Maintenance releases are deliberately represented once because the indexed target bodies are byte-identical.
    maintenance = {
        "RELEASES": ["v2.1.0", "v2.2.0", "v3.0.1"],
        "FACT": "No indexed security-surface semantic delta from v2.0.0/v3.0.0 respectively.",
        "EVIDENCE": "mirror/CW0/SOURCE-FUNCTION-INDEX.json and SOURCE-FUNCTION-CHANGES.md, generated from pinned source trees; representative bodies: v2.0.0/v2.1.0/v2.2.0:src/L1/OptimismPortal2.sol and v3.0.0/v3.0.1:src/universal/CrossDomainMessenger.sol.",
    }
    payload = {"scope": "Bedrock v1.0.0 through op-contracts/v9.0.0", "maintenance_no_semantic_delta": maintenance, "records": data}
    (OUT / "SEMANTIC-LINEAGE.json").write_text(json.dumps(payload, indent=2) + "\n")

    md = [
        "# Semantic lineage — CW0 independent Track-A reconstruction",
        "",
        "Scope: pinned Bedrock `v1.0.0` through `op-contracts/v9.0.0`. `v2.1.0`, `v2.2.0`, and `v3.0.1` are indexed maintenance branches; the target function bodies are semantically identical to their v2/v3 bases (see `SOURCE-FUNCTION-INDEX.json`). Selector- and storage-stable semantic pivots are called out explicitly.",
        "",
        "## Release spine",
        "",
        "| Release | Security-surface pivot | Evidence |",
        "|---|---|---|",
        "| v1.0.0 | Portal custody/L2OO proofs; v0/v1 messenger replay; SafeCall; StandardBridge; DGF; ProxyAdmin | `v1.0.0:contracts/L1/OptimismPortal.sol:50-490`; `contracts/universal/CrossDomainMessenger.sol:123-413` |",
        "| v1.1.0 | Initialized dependency storage; structured SystemConfig addresses; append-only DGF list | `v1.1.0:src/L1/OptimismPortal.sol:120-135`; `src/L1/SystemConfig.sol:30-73,155-191` |",
        "| v1.2.0 | Global SuperchainConfig pause; messenger/bridge pause; DGF bonds/UUID form | `v1.2.0:src/L1/SuperchainConfig.sol:19-81`; `src/L1/L1CrossDomainMessenger.sol:63-64` |",
        "| v1.3.0 | Structured SystemConfig restored; messenger otherMessenger becomes storage | `v1.3.0:src/L1/SystemConfig.sol:150-210`; `src/universal/CrossDomainMessenger.sol:80-110` |",
        "| v1.4.0 | Portal2 per-submitter game proofs; ASR per-type anchors; DelayedWETH | `v1.4.0:src/L1/OptimismPortal2.sol:51-522`; `src/dispute/AnchorStateRegistry.sol:20-87` |",
        "| v1.6.0 | Custom-gas-token custody branch; guardian anchor override; safer recover call | `v1.6.0:src/L1/OptimismPortal2.sol:362-440,504-573`; `src/dispute/AnchorStateRegistry.sol:99-119` |",
        "| v2.0.0 | Snapshot-respect games, single anchorGame, full ASR predicates; super games/type-5 | `v2.0.0:src/dispute/AnchorStateRegistry.sol:39-262`; `src/dispute/SuperPermissionedDisputeGame.sol:89-108` |",
        "| v2.1/v2.2 | No indexed target semantic delta | `SOURCE-FUNCTION-INDEX.json` |",
        "| v3.0.0 | EIP-7623-aware messenger baseGas | `v3.0.0:src/universal/CrossDomainMessenger.sol:354-390` |",
        "| v3.0.1 | No indexed target semantic delta | `SOURCE-FUNCTION-INDEX.json` |",
        "| v4.0.0 | ETHLockbox custody; scoped expiring pauses; ASR owns invalidation; super-root Portal | `v4.0.0:src/L1/ETHLockbox.sol:67-219`; `src/dispute/AnchorStateRegistry.sol:34-340` |",
        "| v4.1.0 | Output-root/interoperability Portal split; runtime features/pause-key selection | `v4.1.0:src/L1/SystemConfig.sol:139,503-534` |",
        "| v5.0.0 | DGF gameArgs becomes persistent future-clone configuration | `v5.0.0:src/dispute/DisputeGameFactory.sol:70-190,278-292` |",
        "| v6.0.0 | ASR retirement preserved across reinitialization; dual clone-arg layout | `v6.0.0:src/dispute/AnchorStateRegistry.sol:107-115`; `src/dispute/DisputeGameFactory.sol:140-220` |",
        "| v7.0.0 | Unified super-game proving, shared-game migration, deterministic DGF clones, OPCM V2 | `v7.0.0:src/L1/OptimismPortal2.sol:368-537`; `src/L1/opcm/OPContractsManagerV2.sol:229-290` |",
        "| v8.0.0 | Shared migration validation hardening | `v8.0.0:src/L1/OptimismPortal2.sol:510-554` |",
        "| v9.0.0 | Lockbox-sourced pause/guardian, delete proof, split gas budgets, atomic failed-L1CDM withdrawal | `v9.0.0:src/L1/OptimismPortal2.sol:273-330,577-728`; `src/L1/L1CrossDomainMessenger.sol:43-153` |",
        "",
        "## Per-function/field records",
        "",
    ]
    for rec in data:
        md.extend([f"### {rec['SURFACE']} — `{rec['FUNCTION_OR_FIELD']}`", ""])
        for key in ["FIRST_INTRODUCED", "ORIGINAL_MEANING", "ORIGINAL_INVARIANT"]:
            md.append(f"- **{key}:** {rec[key]}")
        for key in ["ALL_SEMANTIC_CHANGES", "ALL_CALL_ORDER_CHANGES", "ALL_REVERT_SEMANTIC_CHANGES", "ALL_IDENTITY_SOURCE_CHANGES", "ALL_AUTHORIZATION_CHANGES", "ALL_PAUSE_SOURCE_CHANGES", "OBJECTS_CREATED_UNDER_OLD_MEANING", "MIGRATION_OR_INVALIDATION_EVENTS", "CURRENT_CONSUMERS", "UNREVIEWED_TRANSITIVE_PATHS"]:
            values = rec[key]
            md.append(f"- **{key}:**")
            if values:
                md.extend(f"  - {v}" for v in values)
            else:
                md.append("  - None identified in the pinned releases.")
        md.append("")
    (OUT / "SEMANTIC-LINEAGE.md").write_text("\n".join(md).rstrip() + "\n")
    return data


def build_dead_ends() -> None:
    rej = "/home/user/Tracking_Body/optimism-u21-novel-hunt/rejected"
    rows = [
        ("Upgrade execution / initializer replay", "The exact U21 bundle was replayed against N-1; proxy storage and initializer versions matched N, implementations were disabled, and wrong same-version offsets either reverted or remained privileged.", "no", f"{rej}/REJ-0101.md; {rej}/REJ-2101.md; {rej}/REJ-2201.md; {rej}/REJ-2205.md"),
        ("Legacy storage reinterpretation", "Nonzero legacy words/spacers did not feed a current getter or deposit path; layouts retained explicit spacers rather than reusing the slots.", "yes — another chain or pre-v7 layout can differ", f"{rej}/REJ-0201.md; {rej}/REJ-0202.md; {rej}/REJ-2202.md"),
        ("Direct implementation / partial upgrade takeover", "Implementations disable initialization and ProxyAdmin/OPCM paths require the production authority; StorageSetter+initializer changes are atomic in the governed call.", "no", f"{rej}/REJ-0103.md; {rej}/REJ-2102.md; {rej}/REJ-2103.md"),
        ("Portal/lockbox conservation", "For executable paths, lockbox delta equals locked minus unlocked; target failure rolls back or relocks exactly and global finalization prevents a second debit.", "yes — pre-U16 portal/failed-withdrawal residue remains historical", f"{rej}/REJ-0301.md; {rej}/REJ-2301.md; {rej}/REJ-2302.md; {rej}/REJ-2901.md"),
        ("Shared lockbox cross-portal drain today", "Observed authorization is diagonal and Portal unlock enforces authorized caller plus balance/reentrancy checks; no per-portal quota is exploitable without a valid withdrawal.", "yes — event history/ownership divergence can change the premise", f"{rej}/REJ-0901.md; {rej}/REJ-2902.md; {rej}/REJ-2903.md"),
        ("Proof deletion enables execution/replay", "Deletion is limited to permanent challenger-win or blacklist invalidation, clears only one submitter cell, and cannot clear the hash-global finalized bit.", "yes — a historical non-game proof address reopens cleanup reachability", f"{rej}/REJ-0501.md; {rej}/REJ-2501.md; {rej}/REJ-2506.md"),
        ("Multiple submitters / re-prove double withdrawal", "Proof cells are isolated but finalizedWithdrawals is hash-global; array duplicates are enumeration garbage, not additional execution authority.", "no, except a distinct historical hash domain for one economic action", f"{rej}/REJ-0401.md; {rej}/REJ-2403.md; {rej}/REJ-2502.md; {rej}/REJ-2503.md"),
        ("Current-registry proof survives fresh shared migration", "A fresh DGF changes factory registration and a fresh ASR stamps retirement time; the old proof bytes persist but checkWithdrawal rejects the referenced old game.", "yes — only if deployed migration ordering/inputs differ", f"{rej}/REJ-0704.md; {rej}/REJ-2505.md; {rej}/REJ-2705.md"),
        ("Messenger double relay / finalized-without-record", "Every normal nonreverting relay writes success or failure; v9 Portal reverts a failed L1CDM subcall, and hash-global Portal finalization prevents a second withdrawal execution.", "yes — Amsterdam/L2CDM timing or legacy hash equivalence", f"{rej}/REJ-0403.md; {rej}/REJ-0801.md; {rej}/REJ-1201.md; {rej}/REJ-3101.md"),
        ("Nested replay theft", "Nested finalization can park ETH in L1CDM failedMessages but cannot claim it under a different message or suppress an honest retry; direct Portal reentrancy is blocked.", "no for theft; L3 composition remains open", f"{rej}/REJ-0304.md; {rej}/REJ-1102.md; {rej}/REJ-1202.md"),
        ("Pause misses a current value exit", "Current ETH/ERC20/ERC721 release paths resolve to the lockbox key and revert while it is paused; deposits/locks remaining open is deliberate directional semantics.", "yes — historic pointer/key divergence", f"{rej}/REJ-0601.md; {rej}/REJ-1204.md; {rej}/REJ-2602.md; {rej}/REJ-3102.md"),
        ("Expired/arbitrary pause as permissionless freeze", "Only Guardian mutates timestamps; arbitrary identifiers are inert unless a consumer points to them, and expiry returns false although operational reset is awkward.", "yes — current-state-only pointer premise", f"{rej}/REJ-0603.md; {rej}/REJ-0604.md; {rej}/REJ-2603.md"),
        ("Malformed/noncanonical super root directly wins", "Structural acceptance does not bypass the respected game, challenge window, and fault-proof soundness; duplicate/unsorted entries still need a defender win.", "yes — pre-v1.9 kona soundness is L1", f"{rej}/REJ-0701.md; {rej}/REJ-2701.md; {rej}/REJ-2702.md"),
        ("Legacy game on OP is already invalid", "The full OP census found the tested third-party defender-win root canonical; current validity alone does not establish a bad historical root.", "yes — other chains and un-recomputed official roots", f"{rej}/REJ-0101.md; {rej}/REJ-0702.md; {rej}/REJ-2703.md"),
        ("CREATE2 pre-positioning of governed migration", "Standalone Utils and legitimate delegatecall contexts have different CREATE2 deployers; the actual migration salt includes timestamp and governed flow context.", "no unless a future flow CALLs Utils", f"{rej}/REJ-2104.md; {rej}/REJ-2704.md; {rej}/REJ-3004.md"),
        ("Gas boundary is permanent loss under current rules", "Current v9 tests found retryable failure rather than finalized-neither; users can add gas and Portal reverts failed messenger subcalls.", "yes — future Amsterdam/EIP-7825 or L2 still-old messenger", f"{rej}/REJ-0804.md; {rej}/REJ-1001.md; {rej}/REJ-3006.md; {rej}/REJ-3202.md"),
        ("Migration validator observations are onchain invariants", "Zero-balance and finite game-type checks are mutable snapshots/operational validation, not authorization or conservation invariants.", "yes — live balances/game types at the eventual migration block", f"{rej}/REJ-0902.md; {rej}/REJ-3005.md; {rej}/REJ-3201.md"),
    ]
    md = [
        "# Dead ends — do not redo without the stated historical reopen condition",
        "",
        "This is a family-level digest of PASS A negatives. Evidence paths point only to the permitted PASS A rejection corpus. “Current-state dependent” means a historical pass may legitimately reopen the premise.",
        "",
        "| Family | Single killing fact | Current-state dependent / reopen condition | Evidence |",
        "|---|---|---|---|",
    ]
    for fam, fact, current, evidence in rows:
        md.append(f"| {fam} | {fact} | {current} | `{evidence.replace('; ', '`; `')}` |")
    md.extend(["", "## Limits", "", "PASS A did not exhaust pre-Bedrock proof records, every chain's historical blacklist/type/retirement transitions, the pre-v1.9 kona program, Amsterdam/EIP-7825 execution, or the eventual shared-migration block state. Those are not negative findings and are the only justified reopenings above."])
    (OUT / "DEAD-ENDS-NO-REDO.md").write_text("\n".join(md) + "\n")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    records, source_to_a = build_primitives()
    build_matrix(records, source_to_a)
    lineage = build_lineage()
    build_dead_ends()
    summary = {
        "source_primitive_files": sum(len(r["source_files"]) for r in records),
        "deduplicated_records": len(records),
        "priority_counts": {p: sum(r["priority"] == p for r in records) for p in ["P0", "P1", "P2"]},
        "lineage_records": len(lineage),
    }
    (OUT / "BUILD-SUMMARY.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
