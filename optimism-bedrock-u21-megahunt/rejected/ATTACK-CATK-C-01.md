# ATTACK-CATK-C-01 — forced L1 relay failure cannot become permanent under the same cap

## Hypothesis

A permissionless finalizer can exploit the live L2CDM 2.2.1 versus L1CDM 2.13.0 reserve mismatch, make another user's withdrawal finalize into `failedMessages`, and leave no EIP-7825-valid transaction able to replay it.

## Exact sequence tried

1. On the pinned L1 fork, fabricate only a mature `provenWithdrawals` entry for a real resolved game.
2. Binary-search `minGasLimit` while calling deployed Portal2 with exactly `2^24 - ordinaryIntrinsic` entry gas.
3. At the first forced-failure point, preserve the portal-produced state instead of reverting it.
4. In the next simulated transaction, call deployed L1CDM `relayMessage` directly with `msg.value=0`, exactly the same message, and the same capped-entry calculation. No `failedMessages` storage write is used in this sequence.

## Result and barrier

The portal delivered through `g=15,382,429`, finalized/recorded failure through `g=15,510,449`, and direct replay delivered through `g=15,981,628`. At `g=15,382,430`, the portal transaction finalized with `failedMessages=true`; the next capped direct transaction delivered the exact message.

Direct replay removes proof validation, portal/lockbox bookkeeping, the outer SafeCall, and 320 bytes of ABI envelope. The direct ceiling is 471,179 above the last portal-finalizable value. Any failure state a third party can actually create through this portal path remains cheaper to replay.

## Evidence

- Test: `test_capEdges_MinGas_ForcedFailureAlwaysHasCheaperReplay`
- Output: `mirror/CATK-C/evidence/TEST-RESULTS.md`
- Model: `mirror/CATK-C/evidence/SYMBOLIC-INEQUALITIES.md`

## Classification and honest score

Live, permissionless, deterministic, but retryable with no eligible impact. Score: **1** (`+2 permissionless +2 current +2 deployed PoC +1 cross-version -3 retryable -3 no eligible impact`). Rejected.

