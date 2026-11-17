# LANE 10 — Historical Assumption Archaeology (old primitives newly reached or surrounded by U21)

Scope walked: v8 -> v9 library diffs, unchanged-since-v7 primitives that the changed files call, shared singletons
swapped underneath in-flight games, assumption comments, proxy-admin sameness checks, and the gas rules the
old L2 side still encodes. All state claims are `cast` reads on `l1` (26433900), `l1pre` (26430858), `l2`
(159654093); fork tests run against the deployed bytecode (harness `/home/user/u21-work/lane10`).

Result: no candidate. Three primitives, five rejected ideas. Nothing found that lets a permissionless actor
steal or freeze bridge custody, forge a withdrawal proof, or block finalization on the U21 contracts.

## 1. What actually changed in the "small library" set

Whitespace-normalized comparison (v7, v8, v9):

| File | v8 -> v9 | Runtime effect |
|---|---|---|
| `libraries/rlp/RLPReader.sol` | formatter only (identical since v7) | none — trie proofs unchanged |
| `libraries/trie/*`, `rlp/RLPWriter`, `Bytes`, `Hashing`, `Encoding`, `Types`, `Storage`, `EOA` | identical since v7 | none |
| `libraries/SafeCall.sol` | `NEW_ACCOUNT_STATE_GAS = 183_600`; `callWithMinGas` reserves it when `value != 0 && target.codehash == 0` | yes (PRIM-1002) |
| `libraries/GasConstants.sol` (new) + `CrossDomainMessenger` | constants split LOCAL/REMOTE; L1 reserve 40k -> 135k, check buffer 5k -> 15k; `_message` now `bytes memory` | yes (PRIM-1001) |
| `libraries/Burn.sol` | TODO comment (Amsterdam: selfdestruct no longer burns) | none on L1 (`Burn.eth` is L2 only) |
| `libraries/Constants.sol`, `Predeploys.sol`, `GasPayingToken.sol`, `Features.sol`, `DevFeatures.sol` | comments / formatting | none |
| `dispute/lib/LibPosition`, `LibUDT` | formatter only | none |
| `dispute/lib/LibGameArgs` | braces | none |
| `dispute/lib/Types.sol` | adds `GameTypes.clearedGameTypes()` (7 types the migrator clears on old factories) | migration only |
| `cannon/PreimageOracle`, `MIPS64`, `MIPS64Instructions` | formatter only | none |
| `cannon/libraries/MIPS64Memory` | NatSpec | none |
| `universal/ProxyAdmin`, `ProxyAdminOwnedBase`, `safe/LivenessModule`, `L2/FeeVault`, `legacy/LegacyMintableERC20` | formatter only | none |
| `dispute/FaultDisputeGame`, `SuperFaultDisputeGame`, `SuperPermissionedDisputeGame`, `DisputeGameFactory` | formatter only | none |
| `dispute/DelayedWETH`, `AnchorStateRegistry` | `systemConfig` -> spacer, new `ethLockbox` pointer for pause / config / guardian | yes (PRIM-1003) |

Deployed implementations equal the v9 build byte for byte outside immutables (portal, L1CDM, lockbox, DelayedWETH,
ASR, SystemConfig, SuperchainConfig, L1StandardBridge, SuperFaultDisputeGame, DisputeGameFactory). L1StandardBridge
(`0xb37a11aa…`), game impls, factory impl, VM and oracle are the same contracts as before U21.

## 2. Messenger and portal gas (finalization)

- L1 runs the January 2026 fork; no Amsterdam scheduled. v9 pre-positions for EIP-8037.
- L2CDM on OP Mainnet is still 2.2.1: withdrawals carry `gasLimit = baseGas_old` (310,160 for an empty message),
  105,000 less than the v9 L2CDM 2.4.0 would request, while the L1CDM already reserves 150,000 around the call.
- Invariant tested on the fork for every sampled finalize gas: outcome is exactly one of {revert, relayed,
  failed-and-recorded}; never "finalized with no record"; the target never receives less than `minGasLimit`.
  Holds for value to a new account, a gas-burning target, and a 20 kB message.
- Under today's rules the old budget is still sufficient at the portal minimum (no forced failure).
- Under Amsterdam (argued, not simulated) old-budget value-to-new-account relays cannot complete at the
  guaranteed gas; the U21 portal turns the resulting revert into `OptimismPortal_L1CDMCallFailed` (retry).
- `callWithMinGas` now needs 186.5k more gas for value to a non-existent account, and wraps for
  `gasLimit >= 2^250` (old behaviour, initiator-only).
- `relayMessage` revert causes enumerated: none can be induced by a third party for somebody else's message.

## 3. Shared singletons under in-flight games

- DelayedWETH `0x1b6dbf05…` (20.66 ETH of bonds) and the ASR were upgraded and re-initialized with the lockbox;
  wiring is consistent on all four chains and the pause identifier did not move (lockbox was already the
  identifier before U21).
- 67 pre-U21 games holding bonds resolve, close and pay out in full after U21 (fork test with `vm.warp`).
- `ASR.initialize` overwrites `respectedGameType`; `SystemConfig.initialize` re-emits three `ConfigUpdate`
  events per chain — the 12 events in the upgrade receipt equal the pre-upgrade values.
- The planned interop migration re-points each chain's old DelayedWETH and old ASR at the shared lockbox
  (`OPContractsManagerMigrator.sol:267,417-430,545-555`).

## 4. Assumption mining (`TODO`, `nosemgrep`, "should never", `spacer_`)

| Hit | Assessment |
|---|---|
| `OptimismPortal2.sol:649-650` "checking the sender is enough because the L2CDM only initiates withdrawals to otherMessenger and blocks L2ToL1MessagePasser" | holds for L2CDM 2.2.1 (`_isUnsafeTarget` unchanged v8 -> v9) and for migrated legacy withdrawals |
| `OptimismPortal2.sol:707` deleteProvenWithdrawal "both conditions are permanent" | status never leaves CHALLENGER_WINS; blacklist is set-only; other lanes own this |
| `OptimismPortal2.sol:439` TODO legacy `rootClaim()` | type-9 games on OP/Ink/Unichain carry single-chain super roots; `rootClaimByChainId` returns the first match, uniqueness is a fault-proof property |
| `SystemConfig.sol:240` TODO remove legacy batch inbox writes | writes zero; no getter left |
| `AnchorStateRegistry.sol` isGameRespected "legacy games won't be used" | all registered impls expose `wasRespectedGameTypeWhenCreated` |
| `Burn.sol:29` Amsterdam TODO | L2 only |
| `SuperFaultDisputeGame.sol:1022` try/catch (EIP-150) | bond path only |
| `ProxyAdminOwnedBase.sol:15-18` "only safe with Proxy / ResolvedDelegateProxy" | L1ChugSplashProxy stores its owner in the same EIP-1967 slot; verified on chain |
| `SuperPermissionedDisputeGame.sol` `tx.origin != proposer()` | permissioned design; type 5 is respected on Soneium only |

## 5. Open questions for other lanes

1. Activation ordering: Amsterdam on L1 vs the L2CDM 2.4.0 upgrade, and chains that are not on U21 at that point
   (old messenger + old portal finalize a reverted relay as failed-without-record).
2. `OPContractsManagerUtils._adminFor` trusts the ProxyAdmin a target self-reports (owner-supplied inputs only).
3. `rootClaimByChainId` first-match semantics once a shared factory carries multi-chain super roots.

## 6. Files

- `primitives/PRIM-1001.md`, `PRIM-1002.md`, `PRIM-1003.md`
- `rejected/REJ-1001.md` … `REJ-1005.md`
- `test/poc/lane10/{MessengerGasCrossVersion,SafeCallFloor,InflightGames}.t.sol`
  (run from a harness copy; set `ALT_RPC=<archive url>` if the shared `l1` anvil's upstream is throttled)
- `evidence/lane10/{messenger-gas-cross-version,safecall-floor,inflight-games-postU21}.log`

Limits: Amsterdam behaviour is argued from v9 comments and the EIP, not executed. Fork gas numbers come from
single-transaction forge execution (warm/cold accounting differs slightly from a standalone transaction).
The in-flight game sample is every third game of the last 210, single-claim games only. Three test runs read
block 26433900 from a public archive endpoint (passive reads) because the shared anvil's upstream returned 429.
