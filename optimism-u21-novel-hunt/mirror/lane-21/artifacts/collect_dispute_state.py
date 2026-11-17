#!/usr/bin/env python3
"""Collect DGF configuration and pre-existing/new game behavior around U21."""

import json
import subprocess


CHAINS = [
    {
        "name": "OP Mainnet",
        "factory": "0xe5965Ab5962eDc7477C8520243A95517CD252fA9",
        "asr": "0x23B2C62946350F4246f9f9D027e071f0264FD113",
        "respected": 9,
    },
    {
        "name": "Ink",
        "factory": "0x10d7B35078d3baabB96Dd45a9143B94be65b12CD",
        "asr": "0xEe018bAf058227872540AC60eFbd38b023d9dAe2",
        "respected": 9,
    },
    {
        "name": "Soneium",
        "factory": "0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0",
        "asr": "0x4890928941e62e273dA359374b105F803329F473",
        "respected": 5,
    },
    {
        "name": "Unichain",
        "factory": "0x2F12d621a16e2d3285929C9996f478508951dFe4",
        "asr": "0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9",
        "respected": 9,
    },
]

BLOCKS = {
    "pre": ("http://127.0.0.1:8546", 26430858),
    "post": ("http://127.0.0.1:8547", 26430859),
    "later": ("http://127.0.0.1:8545", 26433900),
}
GAME_TYPES = [0, 1, 4, 5, 8, 9, 10]


def call(address: str, signature: str, args: list[str], endpoint: str, block: int) -> str:
    proc = subprocess.run(
        [
            "cast", "call", address, signature, *args,
            "--rpc-url", endpoint, "--block", str(block),
        ],
        check=False,
        text=True,
        capture_output=True,
    )
    if proc.returncode:
        return "ERROR: " + (proc.stderr.strip() or proc.stdout.strip())
    return proc.stdout.strip()


def first_token(value: str) -> str:
    return value.splitlines()[0].split()[0]


def game_at(factory: str, index: int, endpoint: str, block: int) -> dict:
    raw = call(factory, "gameAtIndex(uint256)(uint32,uint64,address)", [str(index)], endpoint, block)
    lines = raw.splitlines()
    return {
        "index": index,
        "gameType": int(lines[0].split()[0]),
        "timestamp": int(lines[1].split()[0]),
        "game": lines[2].split()[0],
    }


def game_state(game: str, game_type: int, asr: str, endpoint: str, block: int) -> dict:
    state = {
        "gameType": first_token(call(game, "gameType()(uint32)", [], endpoint, block)),
        "status": first_token(call(game, "status()(uint8)", [], endpoint, block)),
        "createdAt": first_token(call(game, "createdAt()(uint64)", [], endpoint, block)),
        "anchorStateRegistry": first_token(
            call(game, "anchorStateRegistry()(address)", [], endpoint, block)
        ),
        "weth": first_token(call(game, "weth()(address)", [], endpoint, block)),
        "isRegistered": first_token(
            call(asr, "isGameRegistered(address)(bool)", [game], endpoint, block)
        ),
        "isRespected": first_token(
            call(asr, "isGameRespected(address)(bool)", [game], endpoint, block)
        ),
        "isRetired": first_token(
            call(asr, "isGameRetired(address)(bool)", [game], endpoint, block)
        ),
        "isProper": first_token(
            call(asr, "isGameProper(address)(bool)", [game], endpoint, block)
        ),
    }
    if game_type == 9:
        state["absolutePrestate"] = first_token(
            call(game, "absolutePrestate()(bytes32)", [], endpoint, block)
        )
    if game_type == 5:
        state["proposer"] = first_token(call(game, "proposer()(address)", [], endpoint, block))
    return state


def main() -> None:
    output = []
    for chain in CHAINS:
        counts = {
            label: int(first_token(call(chain["factory"], "gameCount()(uint256)", [], endpoint, block)))
            for label, (endpoint, block) in BLOCKS.items()
        }
        configs = {}
        for label, (endpoint, block) in BLOCKS.items():
            configs[label] = {}
            for game_type in GAME_TYPES:
                configs[label][str(game_type)] = {
                    "implementation": first_token(
                        call(chain["factory"], "gameImpls(uint32)(address)", [str(game_type)], endpoint, block)
                    ),
                    "initBond": first_token(
                        call(chain["factory"], "initBonds(uint32)(uint256)", [str(game_type)], endpoint, block)
                    ),
                    "gameArgs": first_token(
                        call(chain["factory"], "gameArgs(uint32)(bytes)", [str(game_type)], endpoint, block)
                    ),
                }

        respected_index = counts["pre"] - 1
        while respected_index >= 0:
            candidate = game_at(chain["factory"], respected_index, *BLOCKS["pre"])
            if candidate["gameType"] == chain["respected"]:
                break
            respected_index -= 1
        if respected_index < 0:
            raise RuntimeError(f"no respected pre-U21 game for {chain['name']}")
        pre_game = game_at(chain["factory"], respected_index, *BLOCKS["pre"])
        pre_game["state"] = {
            label: game_state(
                pre_game["game"], pre_game["gameType"], chain["asr"], endpoint, block
            )
            for label, (endpoint, block) in BLOCKS.items()
        }

        new_games = []
        for index in range(counts["post"], counts["later"]):
            game = game_at(chain["factory"], index, *BLOCKS["later"])
            game["state"] = game_state(
                game["game"], game["gameType"], chain["asr"], *BLOCKS["later"]
            )
            new_games.append(game)

        asr_state = {
            label: {
                "respectedGameType": first_token(
                    call(chain["asr"], "respectedGameType()(uint32)", [], endpoint, block)
                ),
                "retirementTimestamp": first_token(
                    call(chain["asr"], "retirementTimestamp()(uint64)", [], endpoint, block)
                ),
            }
            for label, (endpoint, block) in BLOCKS.items()
        }
        output.append({
            **chain,
            "gameCounts": counts,
            "factoryConfigs": configs,
            "anchorStateRegistryState": asr_state,
            "lastPreUpgradeRespectedGame": pre_game,
            "gamesCreatedAfterU21ThroughLaterBlock": new_games,
        })

    print(json.dumps({"chains": output}, indent=2))


if __name__ == "__main__":
    main()
