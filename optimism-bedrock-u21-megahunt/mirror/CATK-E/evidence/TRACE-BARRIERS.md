# CATK-E exact barriers

## Anchor state is not a migration input

In op-contracts/v9.0.0 `OPContractsManagerMigrator.sol`:

- lines 191-222 deploy fresh shared lockbox/DGF/ASR proxies from address zero;
- lines 254-263 initialize the fresh ASR from `_input.startingAnchorRoot` and
  `_input.startingRespectedGameType`;
- lines 545-555 update only the portal's current old ASR, passing its fixed
  `getStartingAnchorRoot()`—not `anchorGame` or `getAnchorRoot()`.

E01 records zero reads and zero writes for all four orphan gen-1/gen-2 ASRs while the deployed
migrator executes. E02 identifies live ASR slot 2 as `anchorGame` and records neither a read nor a
write to it during migration. The fresh ASR root equals the calldata proposal in both tests.

Compatibility detail: historical v2.2.2 `AnchorStateRegistry.sol:239-260` first accepts the candidate
through `isGameClaimValid`, then calls `IFaultDisputeGame.l2BlockNumber()` at line 254. The deployed
type-9 Super game has only `l2SequenceNumber()`, producing a selector-level revert in the `-vvvv`
trace. Selector-compatible type-8 games still move both anchors, proving the zero-read barrier is not
an artifact of an unreachable mutation.

## Pre-migration games/proofs lose authority

`OPContractsManagerMigrator.sol:536-543` clears old DGF game implementations and points each portal
to the fresh DGF/ASR. Deployed `DisputeGameFactory.sol:156-160` refuses creation when the requested
implementation is zero. E05 proves both pre-migration game addresses are unregistered in the shared
ASR even though the portal proof-record mappings persist. E11 is the negative control: a game created
by the shared DGF proves and finalizes normally.

## Liquidity and sticky authorization

`OPContractsManagerMigrator.sol:523-534` sweeps portal and old-lockbox balances into the fresh shared
lockbox. E06 varies every attacker-controlled ETH placement and observes exact conservation.
`ETHLockbox.sol:133-147` requires an authorized lockbox/portal for `receiveLiquidity`/`lockETH`, and
lines 203-208 reserve migration for the ProxyAdmin owner. Persisting authorization is therefore not
an EOA capability. Pre-funding a future CREATE2 address gives it balance but neither code nor nonce,
so E08 deploys at the same address and merely receives attacker-funded surplus.

## WETH state cannot poison migration

The eleven legacy WETH proxies have zero recorded storage accesses. Only the two SystemConfig-live
proxies are upgraded; user balance/allowance/withdrawal mappings survive. `DelayedWETH.sol:81-108`
keys unlock state by `msg.sender` and burns only the caller's WETH on withdrawal. E03/E04 redeem from
every exercised proxy after the delay.

## Failure/retry/repeat

An empty type-5 `gameArgs` value passes `_validateDisputeGameConfigs` but fails the final registration
loop (`OPContractsManagerMigrator.sol:275-284`) after both per-chain mutation loops have executed in
the trace. E09 observes complete transaction rollback, then a successful corrected retry.
`OPContractsManagerMigrator.sol:305-311` rejects any repeat via the permanent INTEROP feature. E10
matches the custom-error selector and observes no custody or pointer delta.
