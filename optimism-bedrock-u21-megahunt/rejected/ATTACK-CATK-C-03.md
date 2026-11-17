# ATTACK-CATK-C-03 — value, new-account reserve, and StandardBridge target

## Hypothesis

Value transfer, the 183,600 codehash-zero reserve, or deployed bridge finalization makes a failed message unreplayable under the cap and strands another user's ETH.

## Exact sequence tried

1. Fabricate an isolated `failedMessages` entry and messenger balance as the post-failure state vehicle.
2. Directly replay empty/value messages to an existing account and to a provably nonexistent account.
3. Replay an authenticated L2StandardBridge message into the deployed L1StandardBridge `finalizeBridgeETH` path and verify recipient balance change.
4. Independently binary-search deployed Portal2 direct-withdrawal `gasLimit` for existing versus codehash-zero value recipients.

## Result and barrier

All messenger replays delivered, including value to the new account and the deployed bridge call. The bridge replay floor was 27,210. For direct portal withdrawals, the maximum existing-recipient gas limit was 16,053,187 and the new-account maximum was 15,870,005, a measured 183,182 edge shift matching the intended reserve.

The reserve changes only a withdrawal gas limit selected and committed by its sender. A third party cannot turn an existing target into a codehash-zero account in the relevant post-Cancun state model, and cannot change the committed target/value/gas. No unrelated-victim permanent band was found.

## Evidence

- Tests: `test_emptyValueNewAccountAndDeployedBridgeTargets`, `test_newAccountReserveOnlyShrinksSelfChosenDirectWithdrawalBand`
- Output: `mirror/CATK-C/evidence/TEST-RESULTS.md`
- Source: `op-v9.0.0/packages/contracts-bedrock/src/libraries/SafeCall.sol:9,121-132`

## Classification and honest score

Live deployed behavior, but sender-selected with no eligible impact. Score: **0** (`+2 permissionless +2 current +2 deployed PoC +1 cross-contract -4 voluntary selection -3 no eligible impact`). Rejected.

