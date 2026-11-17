# LANE C — GAS CAP / CROSS-LAYER BUDGET PERMANENT UNDELIVERABILITY

Inputs: A-018, lead L5, PRIM-1201, PRIM-0801, PRIM-1001, PRIM-0404 (PASS A); live L2CDM 2.2.1 budget
(40k + 5k reserve) vs L1CDM 2.13.0 (135k + 15k); SafeCall +183,600 floor for value to codehash==0
targets; EIP-7825 tx gas cap 2^24 live; Amsterdam/EIP-8037 not active (no scheduled fork).
Known (do not re-measure unless needed): at portal minimum gas the margin is +87k..+114k for
bridge-style messages; negative only for minGasLimit >= ~7.3M (live budget), outcome then
finalized + failedMessages (replayable).

Mission:
1. Derive the exact symbolic inequalities, from v9 bytecode-matching source (cite file:line), for:
   L2 `sendMessage` -> `baseGas(message, minGasLimit)` (live L2CDM constants read on `:9545`) ->
   withdrawal `gasLimit`; portal `callWithMinGas(target, gasLimit, value, data)` requirement; L1CDM
   `relayMessage` pre-check (`hasMinGas(minGasLimit, RESERVED)`) and post-call reserve; target-call gas;
   intrinsic + calldata + memory costs of the L1 tx; the 2^24 cap. Do the same for the DIRECT replay
   path (`relayMessage` called by an EOA with msg.value 0).
2. Search for a non-empty band of (message size, minGasLimit, value, target type) that a normal L2 sender
   can create (the L2 side must accept it: L2 tx gas limits, L2 block gas limit, L2ToL1MessagePasser
   constraints) but that NO L1 transaction under the cap can ever deliver OR replay. Measure the edges on
   a fork with the deployed L1 portal + L1CDM bytecode (a proven state may be fabricated with vm.store
   ONLY as a vehicle; say so; gas behaviour of real bytecode is what is measured).
3. Test: empty target, value-bearing, value to a new account (+183.6k), large calldata (to the L1 and L2
   limits), L1StandardBridge finalize, gas-burning target.
4. Classify every non-empty band: live today / future-only after a fork / retryable with more gas /
   self-inflicted only (the sender chose it). Third-party relevance: can a third party force a victim's
   message into the band (e.g. forced-fail via nested replay, then replay needs more than the cap)?
5. Promote only if a permissionless actor can strand ANOTHER user's funds or cause protocol-wide denial.
   Note the known class "large-calldata / specific-gas message griefing" is excluded unless the impact
   is materially different (e.g. permanent loss caused by a third party).
