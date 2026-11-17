# Lane 26 — pause resolver and value-path matrix

Pinned v9 root: `/home/user/ethereum-optimism/op-v9.0.0`, commit `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`. All state-changing checks below ran only inside Foundry forks of L1 block 26,430,859.

## Resolver graph

| Contract | v9 resolver | Cached reference |
|---|---|---|
| ETHLockbox | `SuperchainConfig.isLocalOrGlobalPaused(address(this))` (`src/L1/ETHLockbox.sol:111-114`) | SuperchainConfig |
| OptimismPortal | `ethLockbox.paused()` (`src/L1/OptimismPortal2.sol:305-307`) | Current lockbox |
| SystemConfig | `optimismPortal().ethLockbox().paused()` (`src/L1/SystemConfig.sol:570-576`) | Portal address; follows Portal's current lockbox |
| AnchorStateRegistry | `ethLockbox.paused()` (`src/dispute/AnchorStateRegistry.sol:135-143`) | Lockbox |
| DelayedWETH | `ethLockbox.paused()` on withdrawal (`src/dispute/DelayedWETH.sol:47-75,98-108`) | Lockbox |
| L1CrossDomainMessenger | `systemConfig.paused()` (`src/L1/L1CrossDomainMessenger.sol:98-105`) | SystemConfig |
| L1StandardBridge | `systemConfig.paused()` (`src/L1/L1StandardBridge.sol:122-129`) | SystemConfig |
| L1ERC721Bridge | `systemConfig.paused()` (`src/L1/L1ERC721Bridge.sol:68-75`) | SystemConfig |

## Four-chain deployed state

Passive calls at N and a fork test established this exact fan-out:

| Chain | Portal | Lockbox / pause ID | ASR | DelayedWETH | All seven exposed `paused()` values after guardian pauses lockbox |
|---|---|---|---|---|---|
| OP | `0xbEb5...106Ed` | `0x322b...94D43` | `0x23B2...FD113` | `0x1B6D...b3162` | true |
| Ink | `0x5d66...D3e4F` | `0xbd4A...25a14` | `0xEe01...9dAe2` | `0x57b4...134eA` | true |
| Soneium | `0x88e5...FAE92` | `0x67B4...22E31` | `0x4890...9F473` | `0x18fB...16B47` | true |
| Unichain | `0x0bd4...6A7a2` | `0x08bA...df5C5` | `0x27Cf...CAFF9` | `0x74ad...22FCf` | true |

“All seven” means lockbox, Portal, SystemConfig, ASR, messenger, StandardBridge, and ERC721Bridge. DelayedWETH exposes no `paused()` getter, but every Portal, ASR, and DelayedWETH pointed to its row's lockbox; every lockbox pointed to common SuperchainConfig `0x9570...04a4C`; all authorized the correct Portal.

The global identifier plus all four old Portal IDs and all four lockbox IDs had `pauseTimestamps == 0` at N-1, N, and block 26,433,900. Therefore no active or expired old pause was lost or resurrected. All four chains already had `ETH_LOCKBOX=true` at N-1, so their effective pre-U21 identifier was already the same lockbox. v8 chose Portal versus lockbox by the feature (`op-v8.0.0/packages/contracts-bedrock/src/L1/SystemConfig.sol:575-588`); v9 is unconditional.

Pausing the old OP Portal identifier after U21 made `SuperchainConfig.paused(portal)==true` but left every dependent resolver false. This is intended lockbox-only behavior and proves stale guardian tooling is ineffective, not a contract bypass.

## Value and state paths under lockbox pause

| Path | Result on real OP contracts | First controlling check |
|---|---|---|
| Portal `depositTransaction` / direct receive | **Live**; ETH locks in lockbox | No pause check; lock path intentionally remains live (`src/L1/OptimismPortal2.sol:730-795`; `src/L1/ETHLockbox.sol:142-151`) |
| Messenger `sendMessage` | **Live**; ends in a Portal deposit | Send has no pause check (`src/universal/CrossDomainMessenger.sol:178-198`); relay does (`:209-223`) |
| StandardBridge ETH deposit | **Live** | Inbound path reaches Portal |
| Portal prove / finalize | **Blocked** | `_assertNotPaused()` at `src/L1/OptimismPortal2.sol:390-409,577-589` |
| Messenger `relayMessage` | **Blocked** | `src/universal/CrossDomainMessenger.sol:209-223` |
| StandardBridge finalize ETH/ERC20 | **Blocked** | `src/L1/L1StandardBridge.sol:239-259,272-299` |
| ERC721 bridge finalize | **Blocked** | `src/L1/L1ERC721Bridge.sol:90-105` |
| Lockbox `unlockETH` | **Blocked** | `src/L1/ETHLockbox.sol:153-175` |
| DelayedWETH deposit / unlock bookkeeping | **Live** | No value leaves |
| DelayedWETH withdraw | **Blocked** | `src/dispute/DelayedWETH.sol:98-108` |
| ASR `setAnchorState` | **Blocked as invalid** | `isGameProper` returns false while paused (`src/dispute/AnchorStateRegistry.sol:286-305,355-371`) |
| Open legacy Fault game `closeGame` / `claimCredit` | **Blocked** | `src/dispute/FaultDisputeGame.sol:979-1040` |
| Already-closed legacy Fault game first claim phase | **Bookkeeping live, no ETH release** | `closeGame` returns before pause; `claimCredit` may call `DelayedWETH.unlock` (`src/dispute/FaultDisputeGame.sol:979-1013,1021-1040`). Fork test advanced a zero-credit phase on real type-8 game `0xfb4D...9E826`; the underlying WETH withdrawal remained blocked. |
| SuperFault game claim/close, including closed | **Blocked** | Its pause check precedes the closed-game return (`src/dispute/SuperFaultDisputeGame.sol:945-995`) |
| ZK closed-game first phase | Same bookkeeping-only nuance as legacy Fault | Underlying withdrawal still reaches paused DelayedWETH (`src/dispute/zk/ZKDisputeGame.sol:647-716`) |

The distinction is deliberate withdrawal-pause directionality: deposits and internal credit scheduling can continue, but no Portal/lockbox/DelayedWETH route releases L1 ETH.

## Expiry semantics

SuperchainConfig v2.5.0 gives each identifier its own timestamp and a 7,884,000-second expiry (`src/L1/SuperchainConfig.sol:31-40`). Only Guardian may pause, unpause, or extend (`:79-121`). `paused(id)` becomes false exactly at `timestamp + expiry`, while the nonzero timestamp still makes a new `pause(id)` revert; Guardian must `extend` (which immediately reactivates even an expired pause) or `unpause` first (`:85-119,139-163`). The fork test covered exact expiry, failed re-pause, extend, and clear.

## CGT and shared-lockbox cases

No upgraded governed chain is CGT. A role-simulated fork set OP's CGT flag and confirmed Portal/SystemConfig/ASR still resolve through the lockbox. This matches U21: OPCM always installs/initializes a lockbox but skips moving Portal ETH for CGT (`src/L1/opcm/OPContractsManagerV2.sol:860-896`). It is a deployed-bytecode test of a synthetic state, not evidence that OP is CGT.

Interop migration gives every member the same newly deployed lockbox. A pause of that address therefore pauses the entire interop set, not one member independently. The migrator refuses any active old resolver pause before switching (`src/L1/opcm/OPContractsManagerMigrator.sol:494-500`), moves old lockbox liquidity, and rewires legacy WETH and ASR references atomically (`:265-272,412-430,526-555`). No stale per-chain value-release path was found. This shared pause scope is structural and expected, but deserves explicit runbook treatment.
