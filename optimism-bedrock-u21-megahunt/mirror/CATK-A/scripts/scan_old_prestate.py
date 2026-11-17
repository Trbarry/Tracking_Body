#!/usr/bin/env python3
"""Passive, pinned-block census of type-9 games using the U20 Kona prestate.

This script only issues eth_call requests and never signs or sends transactions.
"""

import json
import subprocess
import sys
import time
import urllib.request
from datetime import datetime, timezone


RPC = "http://127.0.0.1:7545"
BLOCK = 26_435_245
BLOCK_HEX = hex(BLOCK)
OLD_PRESTATE = "0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df"
NEW_PRESTATE = "0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9"
UPGRADE_TS = 1_794_871_439
TYPE_9 = 9
MAX_RESULTS = 600

FACTORIES = {
    "op-mainnet": "0xe5965Ab5962eDc7477C8520243A95517CD252fA9",
    "ink": "0x10d7B35078d3baabB96Dd45a9143B94be65b12CD",
    "unichain": "0x2F12d621a16e2d3285929C9996f478508951dFe4",
}

SELECTORS = {
    "absolutePrestate": "0x8d450a95",
    "status": "0x200d2ed2",
    "createdAt": "0xcf09e0d0",
    "resolvedAt": "0x19effeb4",
    "maxClockDuration": "0xdabd396d",
    "challengerDuration0": "0xbd8da956" + "00" * 32,
    "wasRespectedGameTypeWhenCreated": "0x250e69bd",
    "gameCreator": "0x37b1b229",
    "l2SequenceNumber": "0x99735e32",
    "startingSequenceNumber": "0x59cebe09",
    "l1Head": "0x6361506d",
    "rootClaim": "0xbcef3b55",
}


def cast_call(address, signature, *args):
    command = [
        "cast", "call", "--rpc-url", RPC, "--block", str(BLOCK), address,
        signature, *map(str, args), "--json",
    ]
    return json.loads(subprocess.check_output(command, text=True))


def batch_eth_call(requests):
    payload = []
    keys = []
    for request_id, (key, address, data) in enumerate(requests, start=1):
        keys.append(key)
        payload.append({
            "jsonrpc": "2.0",
            "id": request_id,
            "method": "eth_call",
            "params": [{"to": address, "data": data}, BLOCK_HEX],
        })
    http_request = urllib.request.Request(
        RPC,
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
    )
    for attempt in range(8):
        with urllib.request.urlopen(http_request, timeout=120) as response:
            replies = json.load(response)
        by_id = {reply["id"]: reply for reply in replies}
        failed = [
            (keys[request_id - 1], by_id[request_id]["error"])
            for request_id in range(1, len(keys) + 1)
            if "error" in by_id[request_id]
        ]
        if not failed:
            return {
                key: by_id[request_id]["result"]
                for request_id, key in enumerate(keys, start=1)
            }
        if any(error.get("code") != 429 for _, error in failed) or attempt == 7:
            key, error = failed[0]
            raise RuntimeError(f"eth_call failed for {key}: {error}")
        time.sleep(2 ** attempt)
    raise AssertionError("unreachable")


def uint256(encoded):
    return int(encoded, 16)


def iso(timestamp):
    return datetime.fromtimestamp(timestamp, timezone.utc).isoformat().replace("+00:00", "Z")


def main():
    # Pin the temporal calculations to the timestamp of the same block as every call.
    rpc_request = urllib.request.Request(
        RPC,
        data=json.dumps({
            "jsonrpc": "2.0", "id": 1, "method": "eth_getBlockByNumber",
            "params": [BLOCK_HEX, False],
        }).encode(),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(rpc_request, timeout=30) as response:
        block_reply = json.load(response)
    block_timestamp = int(block_reply["result"]["timestamp"], 16)

    evidence = {
        "rpc_mode": "passive eth_call only",
        "block": BLOCK,
        "block_timestamp": block_timestamp,
        "block_time_utc": iso(block_timestamp),
        "upgrade_timestamp": UPGRADE_TS,
        "old_prestate": OLD_PRESTATE,
        "new_prestate": NEW_PRESTATE,
        "networks": {},
    }

    for network, factory in FACTORIES.items():
        count = int(cast_call(factory, "gameCount()(uint256)")[0])
        raw_games = cast_call(
            factory,
            "findLatestGames(uint32,uint256,uint256)((uint256,bytes32,uint64,bytes32,bytes)[])",
            TYPE_9,
            count - 1,
            MAX_RESULTS,
        )[0]
        games = []
        for index, metadata, created, root, extra_data in raw_games:
            games.append({
                "index": int(index),
                "metadata": metadata,
                "proxy": "0x" + metadata[-40:],
                "created_at": int(created),
                "root_claim_from_factory": root.lower(),
                "extra_data": extra_data,
            })

        basic_requests = []
        for game in games:
            basic_requests.extend([
                ((game["index"], "absolutePrestate"), game["proxy"], SELECTORS["absolutePrestate"]),
                ((game["index"], "status"), game["proxy"], SELECTORS["status"]),
            ])
        basic = {}
        for offset in range(0, len(basic_requests), 50):
            basic.update(batch_eth_call(basic_requests[offset:offset + 50]))
            time.sleep(0.2)

        old_games = []
        prestate_counts = {}
        status_counts = {}
        for game in games:
            index = game["index"]
            prestate = basic[(index, "absolutePrestate")].lower()
            status = uint256(basic[(index, "status")])
            prestate_counts[prestate] = prestate_counts.get(prestate, 0) + 1
            status_counts[str(status)] = status_counts.get(str(status), 0) + 1
            if prestate == OLD_PRESTATE:
                game["status"] = status
                old_games.append(game)

        in_progress_games = [game for game in old_games if game["status"] == 0]
        detail_requests = []
        for game in in_progress_games:
            for label in (
                "createdAt", "maxClockDuration",
                "wasRespectedGameTypeWhenCreated", "gameCreator", "l2SequenceNumber", "rootClaim",
                "challengerDuration0", "startingSequenceNumber", "l1Head",
            ):
                detail_requests.append(((game["index"], label), game["proxy"], SELECTORS[label]))
        details = {}
        for offset in range(0, len(detail_requests), 25):
            details.update(batch_eth_call(detail_requests[offset:offset + 25]))
            time.sleep(0.2)

        serialized_in_progress_games = []
        for game in in_progress_games:
            index = game["index"]
            duration = uint256(details[(index, "challengerDuration0")])
            max_duration = uint256(details[(index, "maxClockDuration")])
            remaining = max(0, max_duration - duration)
            # Once the duration is capped, a present-state call cannot recover the historical
            # instant at which the cap was first reached.
            deadline = block_timestamp + remaining if remaining > 0 else None
            serialized_in_progress_games.append({
                **game,
                "created_at_contract": uint256(details[(index, "createdAt")]),
                "created_at_utc": iso(game["created_at"]),
                "max_clock_duration": max_duration,
                "challenger_duration_at_block": duration,
                "clock_remaining_at_block": remaining,
                "clock_exhausted_at_block": remaining == 0,
                "clock_exhaustion_if_uninterrupted": deadline,
                "clock_exhaustion_utc": iso(deadline) if deadline is not None else None,
                "was_respected_game_type_when_created": bool(
                    uint256(details[(index, "wasRespectedGameTypeWhenCreated")])
                ),
                "game_creator": "0x" + details[(index, "gameCreator")][-40:],
                "l2_sequence_number": uint256(details[(index, "l2SequenceNumber")]),
                "starting_sequence_number": uint256(details[(index, "startingSequenceNumber")]),
                "l1_head": details[(index, "l1Head")].lower(),
                "root_claim": details[(index, "rootClaim")].lower(),
                "root_claim_matches_factory": details[(index, "rootClaim")].lower() == game["root_claim_from_factory"],
            })

        evidence["networks"][network] = {
            "factory": factory,
            "factory_game_count": count,
            "type9_results_scanned": len(games),
            "newest_type9_created_at": games[0]["created_at"] if games else None,
            "oldest_type9_created_at": games[-1]["created_at"] if games else None,
            "oldest_type9_utc": iso(games[-1]["created_at"]) if games else None,
            "coverage_older_than_max_clock": (
                games[-1]["created_at"] <= block_timestamp - 302_400 if games else False
            ),
            "prestate_counts": prestate_counts,
            "status_counts_all_scanned": status_counts,
            "old_prestate_count": len(old_games),
            "old_prestate_status_counts": {
                str(status): sum(game["status"] == status for game in old_games)
                for status in (0, 1, 2)
            },
            "old_prestate_in_progress_count": len(serialized_in_progress_games),
            "old_prestate_in_progress_games": serialized_in_progress_games,
        }

    json.dump(evidence, sys.stdout, indent=2, sort_keys=True)
    print()


if __name__ == "__main__":
    main()
