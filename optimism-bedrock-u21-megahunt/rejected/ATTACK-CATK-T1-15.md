# ATTACK-CATK-T1-15 — legacy DelayedWETH bond release

## Hypothesis

A later pause/delay generation lets an unprivileged caller unlock or recover bonds retained by a
legacy DelayedWETH proxy.

## Original condition and changed precondition

Old bonds remain safe only if withdrawal requests stay caller-namespaced and administrative recovery
stays privileged. v9 logic uses `withdrawals[msg.sender][subAccount]`, immutable delay and owner-only
`recover/hold` (`DelayedWETH.sol:50-134`). The mutation acts directly on one deployed legacy escrow
from each chain, including zero/nonzero histories, rather than the current WETH generation.

## Exact sequence and result

At the pin the four selected WETH balances are respectively 0.16, 0.08, 0 and 0.08 ETH. For each,
the attacker calls `recover(max)` and `hold(attacker,escrow+1)`; both revert. It then deposits one wei,
unlocks its own subaccount, waits the deployed delay and withdraws. Its WETH balance returns to zero
and the contract's pre-existing ETH balance is exactly unchanged.

## Barrier and evidence

Permissionless `unlock` grants withdrawal power only inside the caller's namespace; it cannot name
another owner's balance. Recovery requires ProxyAdmin owner. Test
`test_T15_legacyDelayedWETHCannotReleaseSomeoneElsesBond` passes at
`mirror/CATK-T1/test/FixRegressionCATKT1.t.sol:623`. Delay repricing/unbounded unlock are acknowledged
(blacklist Part 2 items 12/14) and no victim funds move. Deterministic kill; no candidate.

