#!/usr/bin/env python3
"""Render the pinned CATK-A old-prestate census as a Markdown live-object ledger."""

import json
import sys


def main():
    if len(sys.argv) != 2:
        raise SystemExit(f"usage: {sys.argv[0]} CENSUS.json")
    with open(sys.argv[1], encoding="utf-8") as handle:
        data = json.load(handle)

    print("# CATK-A live old-prestate objects\n")
    print(
        f"Pinned passive L1 read: block `{data['block']}` "
        f"(`{data['block_time_utc']}`). No transaction was sent.\n"
    )
    print(
        "`remaining` is `maxClockDuration - getChallengerDuration(0)` at the pinned block. "
        "A zero value proves exhaustion by that block but does not recover the earlier instant "
        "when the capped duration was first reached.\n"
    )
    print(
        "The engagement's locked facts classify Ink game 2638 and Unichain game 17586 as "
        "countered wrong-root third-party games. This ledger independently pins their current "
        "contract state; it does not relabel them as claim-valid.\n"
    )

    total = 0
    for network, network_data in data["networks"].items():
        games = network_data["old_prestate_in_progress_games"]
        total += len(games)
        statuses = network_data["old_prestate_status_counts"]
        print(f"## {network}\n")
        print(
            f"Factory `{network_data['factory']}`; type-9 results scanned "
            f"`{network_data['type9_results_scanned']}`; old-prestate games "
            f"`{network_data['old_prestate_count']}` "
            f"(status 0/1/2 = `{statuses['0']}/{statuses['1']}/{statuses['2']}`); "
            f"live old-prestate games `{len(games)}`; coverage older than the maximum clock: "
            f"`{str(network_data['coverage_older_than_max_clock']).lower()}`.\n"
        )
        print(
            "| index | game | creator | created UTC | claim seq | start seq | L1 head | "
            "remaining | exhaustion if uninterrupted | respected | root claim |"
        )
        print(
            "|---:|---|---|---|---:|---:|---|---:|---|---|---|"
        )
        for game in sorted(games, key=lambda item: item["index"]):
            deadline = game["clock_exhaustion_utc"] or "exhausted by pinned block"
            print(
                f"| {game['index']} | `{game['proxy']}` | `{game['game_creator']}` | "
                f"{game['created_at_utc']} | {game['l2_sequence_number']} | "
                f"{game['starting_sequence_number']} | `{game['l1_head']}` | "
                f"{game['clock_remaining_at_block']} | {deadline} | "
                f"{str(game['was_respected_game_type_when_created']).lower()} | "
                f"`{game['root_claim']}` |"
            )
        print()

    print(f"Total live old-prestate games: **{total}**.")


if __name__ == "__main__":
    main()
