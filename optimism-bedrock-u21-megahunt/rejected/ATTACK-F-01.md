# ATTACK-F-01 — Withdrawal into a lockbox the portal does not treat as unsafe (sibling, retired, implementation)

Lane ATK-F, Opus 5.5. Kill type: failing experiment + code barrier.

**Hypothesis.** `_isUnsafeTarget` blocks only {portal, current ethLockbox}. A withdrawal from an unprivileged L2 sender,
finalized by the OP portal (msg.sender = portal), targets another lockbox: Ink/Soneium/Unichain lockbox `unlockETH(balance)`
(theft), `lockETH{1 ETH}` / `receiveLiquidity{1 ETH}` (accounting), or the bare lockbox implementation.

**Sequence executed.** `test_F01_targetMatrix` rows 1-8 (test/poc/attack-wave/F/test/ATKF_UnsafeTargets.t.sol): attacker EOA calls `L2ToL1MessagePasser.initiateWithdrawal`
on the OP Mainnet fork (sentMessages asserted), proof cell written by vehicle on L1, `finalizeWithdrawalTransactionExternalProof`
from the attacker. `test_F07`: own lockbox / own portal on all four chains.

**Barrier.**
- Sibling lockboxes: `authorizedPortals[msg.sender]` (v9 src/L1/ETHLockbox.sol:147 lockETH, :163 unlockETH); the cross
  product 4 lockboxes x 4 portals is diagonal (C9, re-read inside the test snapshot). Revert `ETHLockbox_Unauthorized` (0x665a1d1c).
- Even an authorized portal cannot unlock during a withdrawal: `sender.l2Sender() != DEFAULT_L2_SENDER` (ETHLockbox.sol:169-170),
  present unchanged since the lockbox's first release (hist v4.0.0 src/L1/ETHLockbox.sol:168; v4.1.0/v5.0.0/v6.0.0 same line).
- `receiveLiquidity`: `authorizedLockboxes[msg.sender]` (ETHLockbox.sol:136).
- Implementation: `paused()` calls superchainConfig == address(0) -> revert.
- Own lockbox / own portal: `OptimismPortal_BadTarget` (OptimismPortal2.sol:599-601, :846-849), all four chains (F07).
- No retired lockbox exists: each chain has had exactly one ETHLockbox proxy since U16 (chains/*/HISTORY.md section 1).
- Failed call relocks exactly `_tx.value` into the portal's own lockbox (OptimismPortal2.sol:661-665): test asserts OP lockbox
  delta 0 for these rows and sibling balances unchanged.

**Evidence.** evidence/attack-wave/F/forge-test-vv.txt (trace: evidence/attack-wave/F/forge-test-vvvv.txt). Result: every row `WithdrawalFinalized(success=false)`, shared-state hash unchanged.
