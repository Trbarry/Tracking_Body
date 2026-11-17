# Lane 31 exact N-1 -> N differential results

Baseline commits are v8 `f45a5ccfebcdf6da3f5b09cbc512667c063730b7` and v9 `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`. State forks are N-1 `26430858` (`l1pre`), N `26430859` (`l1n`), and later post `26433900` (`l1`). Unless stated otherwise, the same decoded `pre-messenger-zero.json` withdrawal and its same stored proof are used on both exact-boundary forks.

## Outcome matrix

| Action | N-1 / v8 | N / v9 | Classification |
|---|---|---|---|
| Normal real messenger finalization, 2m outer gas | succeeds; finalized; same relay result/event; portal and lockbox restored; measured 213,582 gas | same semantics; measured 219,563 gas | Expected implementation-gas drift (+5,981), no state/event divergence |
| Real path with L1CDM code replaced by immediate reverter | call succeeds, `finalized=true`, `WithdrawalFinalized(...,false)` | reverts `OptimismPortal_L1CDMCallFailed()`, `finalized=false`, event rolled back | Documented U21 hardening |
| Binary-search minimum outer gas, same fixture | 643,533 | 648,547 | +5,014; at `min-1` both revert and retain no finalization; at minimum each records a messenger outcome |
| Second submitter proves same withdrawal, then reproves | both calls succeed; original submitter unchanged; own timer resets; submitter list +2 | identical | No semantic differential |
| Portal getters | version `5.8.0`; guardian and SuperchainConfig values | version `6.1.0`; same guardian and SuperchainConfig | Version/documented wiring only |
| Empty-account value-call minimum, deployed portal with synthetic proven state | 241,483 | 419,518 | +178,035 observed; source adds 183,600 to the minimum-gas requirement; mocked-proof reachability only |
| 120,000-byte deposit | success; same event digest/limits; 5,194,026 isolated gas | same semantics; 5,635,990 gas | +441,964 in isolated run; unexplained gas-only primitive, suppressed impact class |
| 120,001-byte deposit / underpriced gas | revert / revert | same selectors | No divergence |

The failing-messenger change is explicit at v9 `/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/L1/OptimismPortal2.sol:639-653`; v8 instead retains the failed finalization and emits the event at `/home/user/ethereum-optimism/op-v8.0.0/packages/contracts-bedrock/src/L1/OptimismPortal2.sol:614-624`. It is also documented in the U21 notice at `/home/user/ethereum-optimism/optimism/docs/public-docs/notices/upgrade-21.mdx:50-55` and `:193-194`.

The exact tests are `test/DifferentialWithdrawal.t.sol:80-195`, `test/NewAccountGasDifferential.t.sol`, and `test/DepositDifferential.t.sol`. The failing-target case deliberately uses `vm.etch` only to make the cross-version target outcome identical; it establishes the deployed portal's branch behavior, not a production ability to replace L1CDM.

## Large-calldata curve

Measured around the same low-level call in one warmed sequence:

| Calldata bytes | N-1 gas | N gas | N - N-1 |
|---:|---:|---:|---:|
| 0 | 45,506 | 42,111 | -3,395 |
| 256 | 34,122 | 36,840 | +2,718 |
| 4,096 | 191,192 | 217,315 | +26,123 |
| 32,768 | 1,386,899 | 1,586,921 | +200,022 |
| 120,000 | 5,367,471 | 6,096,868 | +729,397 |

Portal deposit semantics and the 120,000-byte bound are at v9 `OptimismPortal2.sol:741-795`; the equivalent v8 function is `OptimismPortal2.sol:684-738`. Source-level deposit logic is materially the same, so the calldata-proportional deployed-bytecode gas drift remains unexplained. It produced no revert-selector, event, resource-price, or custody difference. Large-calldata/specific-gas griefing is expressly suppressed by `LANE_CONTEXT.md:206-215`, so this is not a candidate.

## View and state checks

Raw `cast call`, `cast storage`, balances, implementation slots, versions, feature flags, and messenger constants are in `onchain-state-reads.txt`. Public messenger aliases remain `200000 / 40000 / 40000 / 5000`, and `baseGas(0x,200000)=513334` on v8 L1, v9 L1, and live L2. V9's internal L1 local relay reserve is nevertheless 135,000 with a 15,000 buffer (`GasConstants.sol:49-78`); public getters intentionally expose remote budgets (`L1CrossDomainMessenger.sol:43-74,117-125`).

## Amsterdam caveat

V9 `SafeCall.callWithMinGas` adds `NEW_ACCOUNT_STATE_GAS=183600` only when value is nonzero and `target.codehash==0` (`SafeCall.sol:7-9,95-132`). The pinned L1 has no Amsterdam state-gas rules. The test uses real deployed portal bytecode but installs synthetic proof storage so target/value can be isolated; it does not claim that synthetic withdrawal is a mainnet proof. The observed outer delta includes CALL/access overhead and is not expected to equal exactly 183,600.
