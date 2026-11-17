# LANE-28 — Portal / Messenger Cross-Contract Semantics

## Disposition

**No bounty candidate survived.** U21 creates a real, measurable cross-version gas-budget mismatch because OP Mainnet's live L2 messenger remains v2.2.1 while L1 now executes v2.13.0. For the execution-gas branch, L2 budgets 105,000 less gas than the new L1-local constants would budget. This is not permanent loss, double delivery, or inconsistent finalization:

1. `OptimismPortal2` treats the withdrawal `gasLimit` as a minimum, then forwards all remaining call-frame gas.
2. A finalizer can supply more transaction gas than the L2-recorded minimum.
3. If the L1 messenger call itself reverts or exceptionally halts, U21's portal-specific check reverts the whole finalization and leaves the withdrawal unfinalized.
4. If `relayMessage` returns normally, it has set either `successfulMessages` or `failedMessages`. A failed target call is therefore replayable directly through the messenger.

All fork tests passed: 12/12. The proof-record precondition is seeded with `vm.store`, but every portal, messenger, StandardBridge, and ERC721Bridge transition under test executes the real deployed proxy and implementation bytecode. This limitation is not represented as a real proof-generation test.

## Scope and pinned sources

- v8: `f45a5ccfebcdf6da3f5b09cbc512667c063730b7` at `/home/user/ethereum-optimism/op-v8.0.0`.
- v9: `ba6fcadbc57eb99918c5b0f14f57c72527f531e3` at `/home/user/ethereum-optimism/op-v9.0.0`.
- L1 pre-U21 block 26,430,858 (`:8546`), activation block 26,430,859 (`:8547`), later block 26,433,900 (`:8545`).
- OP Mainnet block 159,654,093 (`:9545`).
- Full selected-file patch: `mirror/lane-28/U21_SELECTED_FULL_DIFF.md`.
- Read transcript and implementation map: `mirror/lane-28/ONCHAIN_READS.md` and `mirror/lane-28/U21_PROXY_IMPLEMENTATION_MAP.md`.
- Reproduction: `mirror/lane-28/test/PortalMessengerSemantics.t.sol`.

Path aliases below are exact and pinned:

- `V9` = `/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src`
- `V8` = `/home/user/ethereum-optimism/op-v8.0.0/packages/contracts-bedrock/src`

No other lane output, candidate, rejection, PoC, snapshot, or top-level U21 analysis was read.

## 1. Complete v8 → v9 semantic diff inventory

The 1,069-line selected-file patch contains every hunk requested by the brief. The security-relevant interpretation is:

### CrossDomainMessenger

- `relayMessage` changes its payload from calldata to memory, so ABI decoding copies the dynamic payload before the body and before the `hasMinGas` check: `V8/universal/CrossDomainMessenger.sol:222-232` versus `V9/universal/CrossDomainMessenger.sol:209-219`.
- The old universal 200k/40k/40k/5k relay constants at `V8/universal/CrossDomainMessenger.sol:97-117` are removed from the base and replaced by abstract remote-cost getters plus parameterized `_baseGas`: `V9/universal/CrossDomainMessenger.sol:337-377`.
- `relayMessage` now consumes local-chain reserve and check-buffer hooks at `V9/universal/CrossDomainMessenger.sol:256-286`. Success/failure bookkeeping is otherwise the same at `V9/universal/CrossDomainMessenger.sol:288-306`.
- The EIP-7623-aware equation remains structurally the same, but now receives direction-specific parameters: `V9/universal/CrossDomainMessenger.sol:383-419`.
- Initialization logic is semantically unchanged; only formatting changes around the existing anti-reentrancy preservation of `xDomainMsgSender` at `V9/universal/CrossDomainMessenger.sol:422-432`.

### L1 and L2 messenger children

- The new constants live in `V9/libraries/GasConstants.sol:4-78`.
- L1 local relay is 135k reserve + 15k check buffer; its L1→L2 remote budget is 200k + 40k + 40k + 5k: `V9/L1/L1CrossDomainMessenger.sol:43-74`. `baseGas` explicitly uses the remote L2 constants at `:116-126`; local hooks return 135k/15k at `:145-153`.
- L2 v9 local relay would remain 40k/5k; its L2→L1 remote budget would use 200k + 40k + 135k + 15k: `V9/L2/L2CrossDomainMessenger.sol:27-58` and `:80-89`.
- Sending still deposits through the L1 portal (`V9/L1/L1CrossDomainMessenger.sol:128-133`) or calls the L2ToL1MessagePasser (`V9/L2/L2CrossDomainMessenger.sol:92-97`). Authentication/unsafe-target rules remain at `V9/L1/L1CrossDomainMessenger.sol:135-143` and `V9/L2/L2CrossDomainMessenger.sol:99-107`.
- Deployed L2 did not receive the v9 child: it is v2.2.1, whose send path is `V8/L2/L2CrossDomainMessenger.sol:46-50` and whose universal constants are `V8/universal/CrossDomainMessenger.sol:97-130`.

### SafeCall and portal

- `SafeCall.hasMinGas` retains the exact inequality `gas × 63 ≥ minGas × 64 + 63 × (40,000 + reservedGas)`: `V9/libraries/SafeCall.sol:79-109`.
- `callWithMinGas` adds a 183,600 future state-gas allowance when value is sent to a codehash-zero account, then calls with `gas()` rather than the minimum: `V9/libraries/SafeCall.sol:119-171`. This is the EIP-8037-specific semantic change.
- Portal finalization first checks pause/config/reentrancy/target/proof, marks the hash finalized, sets `l2Sender`, then calls `SafeCall.callWithMinGas`: `V9/L1/OptimismPortal2.sol:583-630`.
- U21 moves estimation handling before final emission and, critically, reverts with `OptimismPortal_L1CDMCallFailed` when the low-level call failed and the withdrawal sender is the L2 messenger: `V9/L1/OptimismPortal2.sol:632-653`. Solidity rollback undoes the earlier finalized flag, lockbox transfer, and `l2Sender` change.
- v8 instead emitted/finalized a failed low-level messenger call: `V8/L1/OptimismPortal2.sol:591-632`. Fork tests reproduce both outcomes.
- Other portal changes are orthogonal: pause/guardian reads move through the lockbox, lockbox validation/migration changes, and invalid proof deletion is added (`V9/L1/OptimismPortal2.sol:707-728`). They are present in the full patch.

### Bridges and Constants

- `universal/StandardBridge.sol`, `universal/ERC721Bridge.sol`, and `L2/L2ERC721Bridge.sol` are byte-identical.
- L1/L2 StandardBridge changes are formatting only; L1ERC721Bridge changes are formatting/comment layout only. The actual target behavior is unchanged.
- `Constants.sol` changes one comment typo only.
- StandardBridge authenticates the remote bridge at `V9/universal/StandardBridge.sol:110-117`. ETH target failure reverts at `:239-260`; ERC20 mint/escrow-transfer failure reverts at `:272-299`.
- ERC721 authenticates at `V9/universal/ERC721Bridge.sol:63-70` and fails on missing escrow/transfer at `V9/L1/L1ERC721Bridge.sol:88-117`.

## 2. Deployed-code and upgrade-state anchors

Read-only calls establish:

- L1CDM: v2.11.1 → v2.13.0; AddressManager implementation `0x59D497…86f0` → `0x7d4Ec7…9448`.
- Portal implementation: `0x100521…6748` → `0xb20b23…9645`.
- L1StandardBridge implementation stayed `0xb37a11…a891`.
- L1ERC721Bridge implementation stayed `0x9f164f…cb2e`.
- Live L2CDM: v2.2.1 at implementation `0x250AF3…DF96`.
- Deployed L1 and L2 implementation code hashes match the expected v9 and v8 runtime hashes used by the harness.

The filtered `prestateTracer` net diff of upgrade transaction `0x024770…2a99` shows only the portal implementation slot and AddressManager's L1CDM mapping changing among these contracts. Relevant business slots are identical pre/N/post. L1CDM nonce slot 205 changes `0x42a0e → 0x42a0f` at N due to ordinary transaction `0x762e0f…cfda2` at index 341, before the upgrade at index 358; its `SentMessage` log carries nonce `0x42a0e`. See the exact raw values and commands in `ONCHAIN_READS.md`.

## 3. Exact end-to-end gas accounting

Let `m` be the inner target payload length, `T = m + 260`, and `g` be `_minGasLimit`.

Live L2 v2.2.1 computes:

`oldBase = 21,000 + max(285,000 + floor(64g/63) + 16T, 40T)`.

The v9 L2 child intended for an L1 relay would compute:

`newL1Base = 21,000 + max(390,000 + floor(64g/63) + 16T, 40T)`.

The 105k difference is `(135k + 15k) - (40k + 5k)` whenever the execution branch wins. These values come from `V9/libraries/GasConstants.sol:23-28,39-43,58-63,74-78`; the formula is `V9/universal/CrossDomainMessenger.sol:391-419`.

Flow:

1. Live L2 `sendMessage` computes the old `baseGas` and passes it to `L2ToL1MessagePasser.initiateWithdrawal` (`V8/L2/L2CrossDomainMessenger.sol:46-50`).
2. MessagePasser commits that number as withdrawal `gasLimit` (`V9/L2/L2ToL1MessagePasser.sol:74-96`).
3. On L1 the portal uses it only as `callWithMinGas`'s minimum (`V9/L1/OptimismPortal2.sol:620-627`). `SafeCall` then requests all `gas()` (`V9/libraries/SafeCall.sol:156-169`). Therefore a larger finalization transaction supplies more than the stored floor.
4. L1CDM copies the payload to memory before its body, performs authentication/hash checks, and evaluates `hasMinGas(g, 150,000)`. The hardcoded 40k CALL allowance makes the check-point threshold approximately `64g/63 + 190,000` (`V9/universal/CrossDomainMessenger.sol:209-267`; `V9/libraries/SafeCall.sol:103-109`).
5. It calls the target with `gasleft() - 135,000`, restores `xDomainMsgSender`, and writes success or failure (`V9/universal/CrossDomainMessenger.sol:284-306`).

Concrete values:

| inner payload / minimum | live L2 | v9 L1-intended | result |
|---|---:|---:|---|
| 0 / 0 | 310,160 | 415,160 | +105k |
| 36 / 100,000 | 412,323 | 517,323 | +105k |
| StandardBridge ETH, 164 / 200,000 | 515,958 | 620,958 | +105k |
| 119,744 / 50,000 | 4,821,160 | 4,821,160 | calldata floor dominates |
| 36 / 15,000,000 | 15,548,831 | 15,653,831 | +105k |

The opposite L1→L2 direction has no skew: L1 v2.13.0 deliberately computes with 200k/40k/40k/5k remote-L2 costs (`V9/L1/L1CrossDomainMessenger.sol:49-74,116-126`), exactly matching live L2 v2.2.1. The aliased-L1 fork test delivers under that computed budget.

## 4. Message-class analysis

| Class | Finding |
|---|---|
| Ordinary and pre-U21 L2 messages | Stored floor can be 105k low, but finalization is permissionless and excess transaction gas reaches L1CDM. Successful fork delivery proven. |
| Maximum aligned calldata | At 119,744 inner bytes / 119,972 relay bytes, EIP-7623's 40-gas/byte floor dominates both formulas; fork target executes once. |
| High user minimum | At 15m, an exact-old-budget messenger call returns normally as failed; 16.7m direct replay succeeds. This is replayable specific-gas behavior, not permanent loss. |
| Value to a fresh EOA/account | Full portal path with the old budget delivers today. At the portal layer the target is the code-bearing L1CDM, so portal `NEW_ACCOUNT_STATE_GAS` is not triggered; the inner target is handled by messenger reserve and available excess gas. |
| L2StandardBridge ETH/ERC20 | Receive default is 200k (`V9/universal/StandardBridge.sol:27-28`; `V9/L2/L2StandardBridge.sol:80-85`). A rejecting ETH recipient yields `failedMessages=true` and replay succeeds once after the recipient accepts. ERC20 target reverts have the same messenger-level outcome. |
| L1ERC721Bridge | Missing escrow makes the real bridge revert; messenger records failure and admits later direct replays. |
| L1→L2 | Remote budget matches live L2 local constants; fork delivery proven. |

No value of payload, minimum, or value-transfer status changes the state-machine closure. Extremely high self-selected gas can make a particular attempt fail and is covered by the engagement's specific-gas suppression unless it causes a materially different permanent outcome; none was found.

## 5. Portal/messenger state consistency

For an authenticated portal call where `_tx.sender == L2CDM`, all reachable outcomes are:

- Portal or messenger reverts/exceptionally halts: the low-level call reports false or portal itself reverts; `OptimismPortal_L1CDMCallFailed` rolls the transaction back. `finalizedWithdrawals=false` and both messenger maps remain as before.
- Messenger's pre-call gas/reentrancy check fails: it writes `failedMessages=true` and returns (`V9/universal/CrossDomainMessenger.sol:256-281`). Portal observes success at the CALL level and finalizes. Direct replay is admitted.
- Target returns false: messenger writes `failedMessages=true` and returns (`:284-306`). Portal finalizes; direct replay is admitted.
- Target succeeds: messenger writes `successfulMessages=true` and returns. Portal finalizes.

Thus `relayMessage` cannot return successfully without recording one map outcome. A later successful replay intentionally leaves historical `failedMessages=true` while also setting `successfulMessages=true`; the success guard prevents another target execution.

### Revert inventory from the authenticated portal path

| Revert/exception | Source | Persistence |
|---|---|---|
| Messenger paused | `V9/universal/CrossDomainMessenger.sol:220-225` | Temporary configuration; portal rolls back/unfinalizes. |
| Nonce version ≥2 | same | Permanent for malformed message; live sender emits v1. |
| v0 legacy old hash already successful | `:227-232` | Permanent duplicate, no new delivery owed. |
| `msg.value != _value` assertion | `:239-243` | Impossible for canonical send; permanent malformed input. |
| `failedMessages[hash]` already true assertion on authenticated first path | `:239-243` | Duplicate/inconsistent path; portal rolls back. |
| Unsafe target L1CDM or portal | `V9/L1/L1CrossDomainMessenger.sol:140-143` and `V9/universal/CrossDomainMessenger.sol:250-252` | Permanent sender-selected unsafe message; portal stays unfinalized under U21. |
| Already successful v1 hash | `V9/universal/CrossDomainMessenger.sol:254` | Permanent duplicate; target cannot execute twice. |
| Estimation-address failure | `:272-279,298-305` | Simulation-only `tx.origin == address(1)`; all writes roll back. |
| OOG/invalid/assert after entry | EVM/Solidity | Portal sees false and atomically rolls back; retry with more gas where gas-dependent. |

The replay-branch checks at `V9/universal/CrossDomainMessenger.sol:244-248` are not selected for a canonical L2CDM withdrawal because portal `l2Sender` authenticates it. They require zero replay value and an existing failed hash for direct replay.

## 6. Double-delivery and griefing attempts

- **Failed map, direct replay, later portal:** impossible. A failed map that persisted from portal execution means that same portal transaction returned normally and finalized the withdrawal. `checkWithdrawal` rejects a later portal call (`V9/L1/OptimismPortal2.sol:671-685`). The fork test replays successfully once, then receives `OptimismPortal_AlreadyFinalized`.
- **Messenger failed state while portal unfinalized:** impossible from one portal attempt because both writes are in one transaction. The special portal revert rolls back the callee's storage too.
- **Hash poisoning:** the v1 hash commits nonce, sender, target, value, minimum gas, and payload (`V9/universal/CrossDomainMessenger.sol:234-248`). A non-authenticated caller cannot seed a new failure; it must already be failed. Canonical nonces are monotonic.
- **Pre-proving:** proof state is keyed by withdrawal hash and proof submitter (`V9/L1/OptimismPortal2.sol:671-674`). Another submitter's proof neither mutates the message hash nor prevents an independent proof; invalidated proofs can be deleted (`:707-728`).
- **Reentrancy:** portal's non-default `l2Sender` rejects nested finalization (`V9/L1/OptimismPortal2.sol:591-596`). Messenger's non-default `xDomainMsgSender` records a nested relay as failed without calling its target (`V9/universal/CrossDomainMessenger.sol:263-281`).
- **Acting first with low gas:** can produce a finalized/replayable failed relay if the messenger has enough gas to record failure, or a fully reverted unfinalized attempt if it does not. It cannot create a finalized-without-map state.

No third party gained a permanent denial, double execution, or inconsistent finalization primitive.

## 7. Bridge targets

The deployed L1StandardBridge and L1ERC721Bridge implementations did not change at U21. Their target reverts are contained by L1CDM's low-level `SafeCall.call`:

- Real StandardBridge ETH finalization to a rejecting recipient reverts at `V9/universal/StandardBridge.sol:258-260`. Fork result: portal finalized; messenger failed map set; after recipient accepts, direct replay sets success and transfers exactly once.
- ERC20 failures from pair validation, underfunded escrow, token mint, or safe transfer occur within `finalizeBridgeERC20` (`:272-299`), so the messenger records the same replayable failure outcome.
- Real L1ERC721Bridge missing-escrow failure at `V9/L1/L1ERC721Bridge.sol:102-106` is recorded failed; a direct replay is admitted and can later succeed if the underlying bridge condition becomes valid.

This confirms bridge-finalize failure is not transformed into finalized-undelivered loss.

## 8. Amsterdam / EIP-8037 (not locally reproducible)

Amsterdam is not active on the tested L1 and the local fork does not expose its state-gas reservoir semantics. The following is source reasoning only, not a PoC claim.

The current official EIP-8037 draft is Last Call. It specifies 1,530 gas per state byte, 64 bytes/97,920 state gas for a fresh storage slot, and 120 bytes/183,600 for a new account. It separates execution gas and state gas, passes the state reservoir intact into child frames, and makes `GAS` report execution `gas_left` only: https://eips.ethereum.org/EIPS/eip-8037.

The v9 constants explicitly anticipate these costs (`V9/libraries/GasConstants.sol:39-42,49-63`), and `SafeCall` reserves the 183,600 account-creation amount (`V9/libraries/SafeCall.sol:7-9,119-134`). The unchanged safety conclusion is outcome-based, not an assertion that the old live L2 floor is sufficient under Amsterdam:

- More transaction gas can fund both dimensions; the portal does not cap the finalizer at `_tx.gasLimit`.
- If the L1CDM frame cannot record a fresh map slot and exceptionally halts, the portal's special revert leaves the withdrawal unfinalized.
- If L1CDM returns, it recorded success or failure.
- The portal's own fresh-account allowance is irrelevant to canonical messenger withdrawals because its direct target is the existing L1CDM; fresh-account creation, if any, is the inner messenger CALL.
- A true Amsterdam client test is still required to validate the exact reservoir/boundary behavior and is listed for follow-up.

## 9. Fork evidence and limitations

Command:

`forge test --match-path test/PortalMessengerSemantics.t.sol --threads 1 -vv`

Result: **12 passed, 0 failed, 0 skipped**. Covered deployed versions/code hashes/constants, L1→L2 delivery, extra-gas finalization, low-gas failed/replay/single-delivery, maximum payload, fresh account with value, exact-old-budget current-rules delivery, 15m minimum, StandardBridge, ERC721Bridge, and pre/post portal regression behavior.

The harness uses private Anvils on 18280-18282 forked from the read-only pinned endpoints. It mutates only those private forks. A mature proof record is injected because generating a historical valid withdrawal proof is orthogonal and the shared upstream intermittently rate-limited arbitrary storage reads. The selected anchor games and all finalization checks, portal calls, messenger authentication, bookkeeping, and bridge calls are real deployed code. This proves conditional execution semantics, not that any synthetic withdrawal exists on mainnet.

## 10. Final assessment

- Candidate count: **0**.
- Strongest killed hypothesis: the 105k L2→L1 floor deficit permanently strands pre-/post-U21 messages. Killed by all-gas forwarding, portal rollback, direct replay, and deployed-code fork tests across the requested edge classes.
- Security improvement confirmed: U21 closes v8's finalized-without-messenger-outcome state when the L1CDM low-level call itself fails.
- No unauthorized public-network write was made.

## Compositions worth independent follow-up

1. **Amsterdam reservoir boundary:** run the same deployed topology under an Amsterdam-capable EVM, focusing on `GAS` excluding state reservoir, fresh failed/success map slots, new-account value, and 135k post-call reserve.
2. **Formal EIP-7825 boundary:** solve the maximum `minGasLimit` at which portal finalization and direct replay remain includable, including proxy/proof overhead. The 15m executable test is negative evidence, not a proof for every boundary integer.
3. **Pause-source divergence:** compose Portal's lockbox-derived pause with L1CDM's SystemConfig-derived pause and the U21 special rollback. Current reasoning says temporary unfinalizability only; configuration-transition testing would close it.

