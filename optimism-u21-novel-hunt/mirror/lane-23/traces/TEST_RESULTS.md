# Lane 23 fork-test and trace record

Command:

    forge test --match-path test/PortalETHLockboxConservation.t.sol -vvv

Result: 13 passed, 0 failed, 0 skipped on 2026-11-17. Test source is
`mirror/lane-23/test/PortalETHLockboxConservation.t.sol`.

## Deployed-code evidence

- `test_depositMovesValueDirectlyIntoLockbox`: portal stays zero; lockbox rises by
  exactly 1 ETH.
- `test_receiveAlsoMovesValueDirectlyIntoLockbox`: same for the receive path.
- `test_donationAndForcedETHStayInPortalUntilAdminMigration`: donation and forced
  value stay in portal; production owner path sweeps the entire balance once.
- `test_realMatureWithdrawalFinalizesAndConservesValue`: real proof, real target,
  and deployed bytecode at block 26433900. Trace emits
  `ETHUnlocked(638177259920741319864)`, calls L1 messenger `relayMessage` with the
  same value, emits `RelayedMessage` and `WithdrawalFinalized(..., true)`, reduces
  lockbox by exactly that value, leaves portal zero, restores `l2Sender`, and rejects
  a second finalization with `OptimismPortal_AlreadyFinalized`.
- Guard tests confirm deployed bad-target, authorization, CGT, interop, migration,
  and proof-deletion reverts.

## Modeled-only evidence (not production exploit proof)

- `test_realProofEtchedMessengerFailureRevertsUnlockAndFinalization`: uses the real
  proof but `vm.etch` replaces its fixed L1 messenger target with reverting code.
  It demonstrates transactional rollback semantics only.
- `test_realProofEtchedReentrantFinalizeCannotDoubleUnlock` and
  `test_realProofEtchedReentrantDepositRelocksExactlyNestedValue`: use `vm.etch` to
  make the fixed real target adversarial. They demonstrate deployed portal/lockbox
  ordering, not reachability for that historical withdrawal.
- `test_modeledDirectWithdrawalFailureRelocksExactValueAndPreservesPortalSurplus`:
  uses `vm.store` to copy a real proof word to a synthetic non-messenger withdrawal
  hash and `vm.etch` for a reverting target. It proves the branch arithmetic only;
  it is not evidence that the synthetic proof exists on mainnet.
- Pause and CGT tests mock or mutate only the relevant configuration state to check
  branch behavior. Live reads separately show both modes inactive at the later
  fork.

The test suite makes no claim of exploitability from any modeled-only setup.

