# ATTACK-CATK-C-04 — gas-burning target does not lose relay state

## Hypothesis

A target that consumes the entire forwarded allowance can make Portal2 finalize while L1CDM records neither success nor failure, or can turn a cap-induced failure into unrecoverable protocol state.

## Exact sequence tried

1. Deploy a local target whose called function executes `INVALID`, consuming all forwarded gas.
2. Relay through deployed Portal2 and deployed L1CDM with a mature-proof state vehicle.
3. Inspect `finalizedWithdrawals`, `successfulMessages`, and `failedMessages`.
4. Replay directly from the equivalent failed state under the cap.

## Result and barrier

Portal finalization completed, `successfulMessages=false`, and `failedMessages=true`. Direct replay returned normally and again retained `failedMessages=true`. There was no neither-mapping state and no messenger bookkeeping loss.

The target always fails semantically; additional envelope gas cannot make `INVALID` succeed. Any funds intentionally addressed to such a target reflect the sender's target choice, not a cross-layer gas-cap exploit or third-party protocol denial.

## Evidence

- Test: `test_gasBurningTargetRecordsReplayableFailureNotLostState`
- Output: `mirror/CATK-C/evidence/TEST-RESULTS.md`
- Source behavior: `op-v9.0.0/packages/contracts-bedrock/src/universal/CrossDomainMessenger.sol:285-307`

## Classification and honest score

Live messenger behavior with a synthetic adversarial target, but voluntary target selection and no eligible impact. Score: **-1** (`+2 permissionless +2 current +2 deployed messenger PoC -4 voluntary selection -3 no eligible impact`). Rejected.
