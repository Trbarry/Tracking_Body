# ATTACK-T1-08 — SafeCall reserve constants: a third-party finalizer starves the target of a DIRECT withdrawal

Lane ATK-T1, Opus 5.5. Target 8 (row 28). Kill type: failing experiment, deployed v9 portal, osaka rules, `--isolate`.

**Original safety condition.** Sherlock 2023-01 H-1/H-2, 2023-03 H-3: `callWithMinGas` guarantees the target receives
>= `_tx.gasLimit`, else the finalize reverts (a direct withdrawal that fails is final: no replay; value is re-locked). v9 adds a
second reserve regime: `NEW_ACCOUNT_STATE_GAS = 183,600` only when `_value != 0 && codehash == 0` (`SafeCall.sol:131-132`,
check :103-109 = 40,000 base + 64/63). Mutation: targets/values between the two regimes, EIP-7702 delegated targets, precompiles.

**Sequence executed** (`T1_Portal.t.sol::test_T1_08_minGasGuaranteeDirectWithdrawals`, OP portal, proof cell vehicle = slot 57 written
to the claim-valid anchor game, everything else deployed code; evm = osaka; every call its own transaction): gasLimit in
{0, 21k, 100k, 1M, 10M} x targets {fresh empty account + 1 ETH, GasProbe (reverts if gasleft < gasLimit-300) without and with
value, EIP-7702-delegated EOA -> GasProbe with value, precompile 0x0a}. Binary search of the minimum non-reverting outer gas, then
a 64-step sweep of the 4,096 gas above it.

**Result.** 0 non-reverting finalizations with a starved target in every case (`success=true` at the minimum, value delivered;
fresh-account minimum = probe minimum + ~184k as designed). Precompile 0x0a fails by input validation at every gas (the sender's
own target choice, not starvation). Output: `evidence/attack-wave/T1/T1_08_minGas.out.txt`. The messenger-path budget was
covered by Lane C (ATTACK-C-01..09). Score <= 0.
