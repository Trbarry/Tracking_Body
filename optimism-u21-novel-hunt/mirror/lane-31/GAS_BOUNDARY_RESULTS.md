# Lane 31 real messenger gas-boundary classification

## Target and fixture

- Deployed v9 portal `0xbEb5...106Ed`, implementation `0xb20b...9645`, on the block-26433900 fork.
- Deployed L1CrossDomainMessenger proxy `0x25ac...fA1`, resolved implementation `0x7d4E...9448`.
- Real post-U21 type-9 fixture `post-messenger-zero-1.json`, withdrawal `0x76313a38...e6b59`, proved in block 26432559 and initially unfinalized.
- The real game is matured and permissionlessly resolved exactly as described in `WITHDRAWAL_FIXTURES.md`. No privileged prank is used.

`test/MessengerGasBoundary.t.sol:28-50` snapshots, invokes `finalizeWithdrawalTransactionExternalProof` with exactly the selected outer gas, reads portal finalization plus both real messenger mappings, asserts the forbidden class is absent, and restores the snapshot.

## Coverage and result

- 64 Foundry fuzz cases, gas bounded to `[100000, 2000000]`.
- 128 deterministic pseudorandom points in the same interval.
- Two exact binary searches plus boundary assertions at `minimum-1` and `minimum`.
- Total sampled gas values: 192, plus binary-search probes. This is not exhaustive over all 1,900,001 integer values.

Deterministic 128-point classification:

| Class | Count |
|---|---:|
| reverted, unfinalized | 43 |
| finalized + `successfulMessages` | 85 |
| finalized + `failedMessages` | 0 |
| **finalized + neither mapping** | **0** |

Exact boundary for this fixture and harness:

| Property | Gas |
|---|---:|
| Minimum outer gas for non-reverting portal finalization | 708,920 |
| Minimum outer gas for successful inner relay | 708,920 |
| At 708,919 | reverted; unfinalized; not relayed |
| At 708,920 | finalized; relayed |

No sampled real-code gas value produced the serious class `finalized && !successfulMessages && !failedMessages`.

## Why the invariant held

The real messenger checks that it can both call and finish, recording `failedMessages` before returning when gas is low (`/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/universal/CrossDomainMessenger.sol:256-281`), and records either success or failure after the target call (`:284-306`). The v9 portal calls through `SafeCall.callWithMinGas` (`OptimismPortal2.sol:620-627`) and, for messenger-sender withdrawals only, rolls the whole finalization back when that low-level messenger call itself fails (`:639-653`). The portal's global finalized flag is written before the call (`:603-615`), but EVM revert atomicity rolls it and any lockbox unlock back.

`GasConstants.sol:49-56` explicitly describes the historical risk of running out after the target call and recording neither outcome. V9 sets the L1-local post-call reserve to 135,000 and check buffer to 15,000 (`:60-78`).

## Mock boundary of the claim

Replacing L1CDM code with a successful no-op/return-bomb makes the deployed portal finalize while neither genuine messenger mapping changes (`test/AdversarialTargets.t.sol:109-131`). That is a concrete trust-boundary primitive, not a live exploit: production L1CDM is not attacker-replaceable, and its actual branches above always write an outcome. Reverting and gas-burning replacements instead caused `OptimismPortal_L1CDMCallFailed`, rolled back the value unlock, and left the real withdrawal replayable (`:83-107`).

Raw output is in `test-results/gas-boundary.txt` and `test-results/forge-test-full.txt`.
