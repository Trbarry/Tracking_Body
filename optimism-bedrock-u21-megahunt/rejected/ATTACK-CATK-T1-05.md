# ATTACK-CATK-T1-05 — pause pointer divergence

## Hypothesis

An attacker changes `ethLockbox` or disables the lockbox feature so a portal value exit resolves a
different pause identifier and proceeds during an effective pause.

## Original condition and changed precondition

The historical fix assumed a stable pause source. v9 resolves portal pause through `ethLockbox`
(`OptimismPortal2.sol:273-307`) and guards `SystemConfig.setFeature`
(`SystemConfig.sol:528-540`). C8 covered paused value paths; this test targets the two public ABI
writers that could change their precondition after upgrade.

## Exact sequence and result

On OP, Ink, Soneium and Unichain, first assert portal lockbox, ASR, SystemConfig, pause value and
`ETH_LOCKBOX=true`. From the attacker, call portal `initialize(..., attackerLockbox)` and
`SystemConfig.setFeature(ETH_LOCKBOX,false)`. All eight calls revert; pointers and feature remain
unchanged.

## Barrier and evidence

Both mutations require ProxyAdmin/owner authority, which the attacker model excludes. The historical
identifier behavior is separately known (blacklist Pause family and Part 2 item 10). Test
`test_T05_pausePointerCannotBeMutatedByAttacker` passes at
`mirror/CATK-T1/test/FixRegressionCATKT1.t.sol:339`. Privileged-only/known kill; no candidate.

