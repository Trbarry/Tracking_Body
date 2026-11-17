# CATK-C symbolic gas model

## Notation and transaction envelope

Let `C = 2^24 = 16,777,216`, `n = message.length`, `g = minGasLimit`, and `p(n) = 32 ceil(n/32)`.

The relevant ABI calldata lengths are:

- normal L2 `sendMessage`: `S(n) = 132 + p(n)`;
- direct L1 `relayMessage`: `R(n) = 228 + p(n)`;
- portal `finalizeWithdrawalTransactionExternalProof`: `F(n) = 548 + p(n)`.

For calldata with `z` zero bytes and `u` nonzero bytes, EIP-7623 tokens are `T = z + 4u`. The ordinary intrinsic debit is `I = 21,000 + 4T`, while the calldata floor is `H = 21,000 + 10T`. A normal transaction must satisfy `H <= G <= C`; execution enters with `G - I` gas. Both L1 and post-Karst OP Mainnet normal transactions are capped; deposits are irrelevant here.

Memory expansion from `a` to `b` 32-byte words costs `M(b)-M(a)`, where `M(w)=3w+floor(w^2/512)`. Each copy additionally costs `3 ceil(length/32)` plus its opcode base; `KECCAK256` costs `30+6 ceil(length/32)` plus expansion. The inequalities below retain the deployed-path prefix terms `P_*`, which are the exact opcode, cold/warm access, copy, hash, and memory-expansion sums for the fixed fork state. The fork tests execute those terms rather than substituting a guessed constant.

## Live L2 creation

The deployed L2CDM 2.2.1 constants and v8 source at `packages/contracts-bedrock/src/universal/CrossDomainMessenger.sol:98-130,357-395` give:

`B(n,g) = 21,000 + max(285,000 + floor(64g/63) + 16(n+260), 40(n+260))`.

A normal L2 sender can create the withdrawal iff:

`H(S(n)) <= C` and `P_L2(n) <= C - I(S(n))`.

`g` is metadata: `L2ToL1MessagePasser` imposes no second gas-limit bound. The live messenger accepted `g=2^32-1`, producing `B(0,g)=4,363,451,539`, in a cheap capped L2 call.

## Portal path

At the portal's `SafeCall.callWithMinGas` (`OptimismPortal2.sol:627`), define gas immediately before `hasMinGas` as:

`G_P = C - I(F(n)) - P_portal(n,state)`.

`SafeCall.sol:103-109` requires:

`63 G_P >= 64 B(n,g) + 63(40,000 + A)`.

For an L2CDM withdrawal the target is the existing L1CDM, so `A=0`. For a direct value-bearing withdrawal to a codehash-zero account, `A=183,600` (`SafeCall.sol:9,121-132`).

Inside L1CDM 2.13.0, the local reserve and buffer are 135,000 and 15,000 (`GasConstants.sol:60,75`). With `G_M` at its check, `CrossDomainMessenger.sol:266` requires:

`63 G_M >= 64g + 63(40,000 + 135,000 + 15,000)`

or `G_M >= ceil(64g/63 + 190,000)`.

The target call requests `gasleft()-135,000` (`CrossDomainMessenger.sol:285`). At the CALL opcode, the exact forwarded amount is the lesser of that request and the EIP-150 `63/64` cap after dynamic CALL/memory costs (plus the value stipend when applicable). The 135,000 remainder is the post-call reserve. If the check or reentrancy guard fails, `failedMessages[hash]` is set and relay returns; if the outer messenger call itself reverts, Portal2 reverts and leaves the withdrawal unfinalized (`OptimismPortal2.sol:627-652`).

## Direct replay

Direct replay requires `msg.value=0` and an existing `failedMessages[hash]`. Its entry gas is:

`G_D = C - I(R(n)) - P_direct(n,state)`.

It then faces the same L1CDM inequality `63 G_M >= 64g + 63*190,000`. It omits proof validation, lockbox/portal bookkeeping, the outer SafeCall, and 320 bytes of ABI envelope. Therefore a message that the portal actually reaches and records as failed has a strictly cheaper retry path; the deployed-fork edge measurements validate that dominance.

This distinction matters: for oversized/specific-gas messages that the portal can never reach, `failedMessages` does not exist, so direct replay is not yet authorized. Those are the sender-selected, upgrade-required class explicitly excluded by `SCOPE.md:311,409`.

## Measured envelopes on the fixed deployed state

For `n=0`, zero value, existing EOA target:

- portal delivery: `g <= 15,382,429`;
- portal finalization (including recorded failure): `g <= 15,510,449`;
- direct replay delivery, given failed state: `g <= 15,981,628`.

Thus the 128,020-value recorded-failure band is fully below the direct-replay ceiling. At `g=15,382,430`, one capped portal transaction created the real failed state and the next capped EOA transaction delivered it.

For `g=0`, all-zero payloads at 32-byte ABI word edges:

- L2 normal creation: 379,200 bytes fits; 379,232 bytes fails;
- portal delivery: 323,168 bytes fits; 323,200 bytes is unfinalized;
- the first portal-rejected payload has portal calldata floor 3,260,880, so execution—not the calldata floor—is the barrier;
- direct replay is gas-feasible for 323,200 and 379,200 bytes if failed state already exists.

The creation-to-portal gap is real but sender-selected and matches the programme's explicit large-data/specific-gas exclusion.

