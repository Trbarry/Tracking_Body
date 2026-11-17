# Lane 30 — exact OP state boundary

Blocks: N−1 `26430858` on `:8546`; N `26430859` on `:8547`; later `26433900` on `:8545`. Upgrade tx `0x024770b5fba87683ee1466562eefb1bcb408c29c764e24abd07c7d4050a82a99` is transaction 358 in N.

## Compiler-declared static storage

I took every distinct slot named by the v9 storage layouts for the 11 OP proxies in the implementation map (97 slots total) and compared `eth_getStorageAt` at N−1/N. Exactly five final static slots differed:

| Proxy / slot / label | N−1 | N | Accounting |
|---|---|---|---|
| Portal slot 1 `params` | `0x…01934d6e…0007e376…3b9aca00` = `(1 gwei,516982,26430830)` | `0x…01934d8b…0007df76…3b9aca00` = `(1 gwei,515958,26430859)` | Normal block-N resource-meter update. Old metering layout is unchanged (`ResourceMetering.sol:58-75`). |
| Lockbox slot 3 `superchainConfig` | zero | `0x95703e…04a4c` | v2 initializer installs direct SC pointer (`ETHLockbox.sol:94-108`). Old SystemConfig remains in spacer slot 0. |
| DelayedWETH slot 5 `ethLockbox` | zero | `0x322b47…94D43` | New pause/config pointer (`DelayedWETH.sol:42-64`). Old SystemConfig remains in spacer slot 4. |
| ASR slot 6 packed `respectedGameType,retirementTimestamp,ethLockbox` | `0x…688271ab00000009` | `0x322b47…94d43 00000000 688271ab 00000009` | Adds Lockbox in free high 20 bytes; type 9 and retirement `1753379243` unchanged (`AnchorStateRegistry.sol:50-59,94-133`). |
| L1CDM slot 205 `msgNonce` | `0x42a0e` | `0x42a0f` | One U21 cross-domain message; source increments at `CrossDomainMessenger.sol:196`. |

All other compiler-declared static slots — including every legacy spacer, owner, pointer, feature mapping base, DGF array length, and initialization byte — were identical. Initializer reset/install/restore is transient and explains multiple upgrade logs without a different final init byte.

## Unstructured and dynamic storage

- SystemConfig `OPCM_SLOT = keccak256("systemconfig.opcm")-1 = 0x99f459…ff42` changed from `0x1951828Ce913DC4383a8A1695695D537a11D896a` to v9 OPCM `0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f`, as written by `SystemConfig.sol:230-238`.
- DGF `gameArgs[9]` (mapping slot 105, entry `0xd59adc…f134`, long-bytes base `0x42faa4…a794`) kept length marker `0xf9` and changed only its first data word:
  - N−1 prestate `0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df`
  - N prestate `0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9`
  - VM `0xaCc005DCd857B401e4732E6F7837135A22825cfA`, ASR `0x23B2…`, WETH `0x1B6D…`, and zero chain word stayed byte-identical. DGF setter is `DisputeGameFactory.sol:307-318`.
- Proxy implementation resolution changed only as recorded in `U21_PROXY_IMPLEMENTATION_MAP.md`; admin/owner did not change.

## Critical state preserved at N

| State | N−1 → N |
|---|---|
| DGF `gameCount()` | `21378 → 21378` (no game created in U21) |
| type-9 implementation/bond | `0x19AF533C…`, `0.08 ETH` unchanged |
| type-5 implementation/bond | `0x5C3eb47c…`, `0` unchanged |
| ASR anchor / retirement | `0x51024A83…` / `1753379243`, unchanged |
| DelayedWETH delay | `302400`, unchanged immutable |
| DelayedWETH supply and ETH balance | both `20.582782 ETH`, unchanged |
| SystemConfig features | `ETH_LOCKBOX=true`, `INTEROP=false`, unchanged |
| Portal / Lockbox | Portal balance zero; Portal was already authorized; Lockbox held `182416.306525160721816415 ETH` at N−1 |

## In-flight game population and singleton references

A batched read of DGF indices `20878..21377` spans timestamps `1793080523..1794870155` (500 games, about 20.7 days). All 500 are type 9. At N−1, 84 were `IN_PROGRESS`, indices `21294..21377`, created `1794571403..1794870155`. Every one returned the same immutable arguments:

- VM `0xaCc005DCd857B401e4732E6F7837135A22825cfA`
- ASR `0x23B2C62946350F4246f9f9D027e071f0264FD113`
- DelayedWETH `0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162`
- old prestate `0x031ac6f1…90e1df`

This follows DGF’s immutable-argument clone construction (`DisputeGameFactory.sol:174-217`) and game getters (`SuperFaultDisputeGame.sol:792-875`). VM is v1.10.1; its unchanged oracle is `0x1E1d73536A081Ef2F355d29794547a9770Aeb1E0`, v1.1.5, challenge period 86400.

Representative index 21377 is `0x675E956B1912Df79108408CA524fB37810500d10`, created at `1794870155`, before N timestamp `1794871439`, one root claim, and holds `0.08 ETH` WETH credit. `Lane30InFlight.t.sol` resolves its claim/game, waits ASR finality, closes it, starts the DelayedWETH unlock, waits 302400, then pays the creator and drains the game’s WETH balance to zero.

## N → later post block

Repeating the same 97-slot comparison found only ordinary activity:

- Portal params block number `26430859 → 26433899`, bought gas unchanged at 515958.
- DGF list length/game count `21378 → 21389`.
- ASR anchor `0x51024A83… → 0x55A5CFd4…`.
- L1CDM raw nonce `0x42a0f → 0x42a6d`.

All 11 final implementations remained the N implementations. No delayed follow-up configuration change explains or creates a candidate.
