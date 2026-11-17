# Lane 23 source diff notes (v8 -> v9)

Pinned sources:

- v8: commit `f45a5ccfebcdf6da3f5b09cbc512667c063730b7`
- v9: commit `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`

## Custody-relevant changes

- `OptimismPortal2.sol`: 83 insertions / 29 deletions. `paused`, guardian, and
  SuperchainConfig resolution now go through the lockbox; `migrateLiquidity` is
  allowed whenever the lockbox is active rather than requiring interop, and rejects
  CGT; failed outer L1 messenger calls now revert the entire finalization; invalid
  proofs can be deleted; configured lockbox state is mandatory. Relevant v9 lines:
  304-329, 500-512, 639-665, 707-728, 804-849. The core
  finalized->unlock->CALL->relock order existed in v8 at lines 559-632.
- `ETHLockbox.sol`: 22 insertions / 18 deletions. Its legacy SystemConfig slot is a
  spacer; it stores SuperchainConfig directly and resolves pause against the
  lockbox identifier. Authorization now compares the portal's SystemConfig
  SuperchainConfig, avoiding a circular portal getter. Value functions themselves
  retain exact-value behavior at v9 lines 132-216.
- `SystemConfig.sol`: 18 insertions / 31 deletions. ETH_LOCKBOX and INTEROP cannot
  be disabled; pause always resolves through the portal's lockbox. See v9 lines
  528-576.
- `SafeCall.sol`: 38 insertions / 33 deletions. `callWithMinGas` adds a 183,600 gas
  allowance for value transfer to a new account and still executes CALL with all
  remaining gas. See v9 lines 105-171. Amsterdam is not active at the pinned mainnet
  block, so future-rule implications are analytical only.
- `L1CrossDomainMessenger.sol` / `CrossDomainMessenger.sol`: gas-budget and relay
  handling changed materially. The accounting invariant remains: a failed inner
  relay is recorded and value stays in messenger for replay; an outer revert is now
  rolled back by the portal. See v9 `L1CrossDomainMessenger.sol:128-153` and
  `universal/CrossDomainMessenger.sol:209-307`.
- `OPContractsManagerMigrator.sol`: one-off interop migration was substantially
  hardened: rejects zero/duplicate/unordered L2 chain IDs, already-migrated chains,
  CGT, and paused systems; performs new authorization and both liquidity sweeps in
  one owner transaction. See v9 lines 129-328 and 475-555.
- `Features.sol` only shortens ETH_LOCKBOX commentary. `L1StandardBridge.sol` has
  formatting-only source change; its deployed implementation is unchanged across
  U21. Its inherited StandardBridge exact-value checks remain at
  `universal/StandardBridge.sol:239-260,309-329`.

No source diff creates a second permissionless exit from the lockbox. The main new
conservation behavior is safer: v9 restores backing and proof replayability when the
outer call to the L1 messenger itself reverts.

