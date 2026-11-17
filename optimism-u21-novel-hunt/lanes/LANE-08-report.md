# LANE 08 — Portal / Messenger cross-contract semantics (U21, op-contracts/v9.0.0)

Scope: `OptimismPortal2` (6.1.0) x `L1CrossDomainMessenger` (2.13.0) x live `L2CrossDomainMessenger` (2.2.1, NOT
upgraded) x `L1StandardBridge` (2.8.2) x `SafeCall` / `GasConstants`.
Phase A (blind): no audits / public findings consulted. Only local forks and private anvils (ports 18080/18082,
both stopped at the end). No transaction was sent to any public network.

Result in one line: **no candidate.** The gas asymmetry the lane was asked to probe is real and quantified, but its
only effect is "finalized + recorded-failed + replayable" for messages with `minGasLimit` above ~5.76M / ~7.32M;
every other path either delivers, records a replayable failure, or reverts retryably. U21 strictly narrows the
loss surface compared with v8 (shown on real bytecode).

---------------------------------------------------------------------------------------------------------------

## 1. On-chain facts (cast, pinned blocks)

| What | `l1pre` 26430858 | `l1` 26433900 | `l2` 159654093 |
|---|---|---|---|
| Portal version | 5.8.0 | 6.1.0 (impl `0xb20b23af…`) | |
| L1CDM version / impl | 2.11.1 / `0x59D49753…` | 2.13.0 / `0x7d4Ec7fB…` (AddressManager `0xdE1FCfB0…` `OVM_L1CrossDomainMessenger`) | |
| L1StandardBridge impl | `0xB37a11Aa…` 2.8.2 | same address (v8->v9 diff is formatting only) | |
| L2CDM version | | | **2.2.1** |
| `RELAY_CONSTANT_OVERHEAD / CALL_OVERHEAD / RESERVED_GAS / GAS_CHECK_BUFFER` getters | 200000 / 40000 / 40000 / 5000 | 200000 / 40000 / 40000 / 5000 (aliases of REMOTE_* = L2 values) | 200000 / 40000 / 40000 / 5000 |
| L1CDM storage 0,151,204,207,251,252,254 | unchanged N-1 -> N -> 26433900 (`_initialized`=3, `xDomainMsgSender`=0xdEaD, otherMessenger=0x42…07, portal, systemConfig); only `msgNonce` (205) moves | | |
| L1CDM ETH balance | 0 | 0 | |

Deployed bytecode of L1CDM impl, Portal impl and L1StandardBridge impl equals the v9 `forge-artifacts`
`deployedBytecode` (0 non-immutable byte differences). The L1CDM runtime contains `0x020f58` (135,000) twice
(byte offsets 5169 / 5582) and the folded `hasMinGas` check at pc 7312 (`PUSH1 0x3f GAS MUL`); v8 impl: pc 7473, reserve
`0x9c40`.

LOCAL (what L1 `relayMessage` really enforces, not exposed by any getter): `L1_RELAY_RESERVED_GAS = 135,000`,
`L1_RELAY_GAS_CHECK_BUFFER = 15,000` (`src/libraries/GasConstants.sol:60,75`; `L1CrossDomainMessenger.sol:44,47`).

## 2. Gas accounting, both sides, exact

L2 (live v2.2.1 — identical to the v8 source):
`sendMessage` -> `baseGas(_message, _minGasLimit)` -> `L2ToL1MessagePasser.initiateWithdrawal(L1CDM, gasLimit, relayMessage(...))`.

```
G_live(len, m) = 21,000 + max( 285,000 + floor(64m/63) + 16*(len+260) , 40*(len+260) )       (v2.2.1)
G_old (len, m) = 285,000 + floor(64m/63) + 16*len                                           (pre-2.2.x L2CDM)
G_migr          = 16*len(data) + 285,000 + floor(64*1,000,000/63)                            (Bedrock-migrated v0, observed 1,308,617 / 1,307,081)
```
All three generations are present among withdrawals that were proven in the 5k blocks before the U21 tx (§4).
`G_live` verified against the live L2CDM for 48 (len, m) pairs and against a real `sendMessage` on the l2 fork
(`test/L2Side08.t.sol`).

L1 portal (`OptimismPortal2.sol:627`, `SafeCall.sol:121-172`): the only gas condition is
`gasleft()*63 >= _tx.gasLimit*64 + 63*(40,000 + newAccountGas)` with `newAccountGas = 183,600` iff
`_tx.value != 0 && _tx.target.codehash == 0` (never for the L1CDM). The call is `call(gas(), …)`: **all** remaining
gas is forwarded; `_tx.gasLimit` is a floor.

L1CDM v2.13.0 (`CrossDomainMessenger.sol:265-285`): `gas*63 >= m*64 + 63*(40,000 + 135,000 + 15,000)` i.e.
`gas >= ceil(64m/63) + 190,000` (v8: `+ 85,000`); then `call(target, gasleft() - 135,000, …)` (v8: `- 40,000`).

Measured on the real bytecode with exact transaction (cold-access) semantics — private anvil forked at 26433900,
withdrawals proven through the real `proveWithdrawalTransaction` (fabricated super-root game as a vehicle, see §8),
portal frame entered with exactly `g` gas, `debug_traceCall` for the internal numbers; four points re-checked with
real transactions (`evidence/lane08/validate_real_tx.jsonl`, 90 gas apart from the probe figure):

| quantity (v9) | value |
|---|---|
| portal pre-call cost, cold, value=0 / value>0 | ~139,400 / ~158,100 |
| gas entering the L1CDM proxy at the portal minimum | `_tx.gasLimit + 32,634` (value>0) / `+ 36,733` (value=0), independent of the budget |
| L1CDM cost from proxy entry to the `hasMinGas` check | 40,289–41,344 for small m=0 messages, plus `gas/64` kept by the ResolvedDelegateProxy frame, plus ~3.1 gas/byte + 9.6e-6*len^2 for large payloads |
| post-call bookkeeping (reset sender, fresh mapping slot, event) | 21,651–21,832 (reserve 135,000) |
| left in L1CDM after a target that burns everything, value>0 | 123,282 (v8: 28,135; v8 with 100 kB payload: 20,503 < 21,6xx -> OOG) |

Margin at the `hasMinGas` check when the finalizer supplies the *minimum* gas the portal accepts
(`evidence/lane08/measure_tables.md`, full JSON alongside):

| message | budget | margin v9 | margin v8 | outcome at min (v9 / v8) |
|---|---|---|---|---|
| ETH bridge withdrawal, m=0 | live 312,784 | +114,074 | +218,241 | delivered / delivered |
| ETH bridge withdrawal, m=0 | old 287,624 | +89,308 | +193,475 | delivered / delivered |
| ETH bridge withdrawal, m=200k | live 515,958 | +110,898 | +215,065 | delivered / delivered |
| USDC bridge withdrawal, m=0 | old 288,648 | +94,149 | +200,739 | delivered / delivered |
| empty msg, 1 ETH -> never-touched EOA | old 285,000 | +87,345 | +191,513 | delivered / delivered |
| target burns all gas, 1 ETH | old 285,000 | +87,345 | +191,513 | failed-recorded / failed-recorded |
| 100 kB payload, burner, 1 ETH | old 1,885,000 | +1,254,533 | +1,358,701 | **failed-recorded / finalized with NO record (lost)** |
| 300 kB payload | live 12,031,400 | +9,860,393 | +9,966,983 | delivered / delivered (direct-tx gas 15,525,061) |
| m = 5,000,000 | live 5,389,525 | +36,781 | +143,371 | delivered / delivered |
| m = 6,000,000 | old 6,380,238 | **-3,859** | +102,731 | **failed-recorded** / delivered |
| m = 8,000,000 | live 8,437,144 | **-10,838** | +95,752 | **failed-recorded** / delivered |
| target = OptimismPortal (unsafe), 1 ETH | old | n/a | n/a | **revert `OptimismPortal_L1CDMCallFailed` at any gas** / finalized, success=false |

The margin falls by 1/63 gas per unit of `minGasLimit` (the proxy frame keeps 1/64). Zero crossings:
v9 `m* = 7,317,200` (live budget) / `5,756,900` (old budget); v8 `14.03M` / `12.47M`.
In that band a finalizer who supplies only the portal minimum gets `WithdrawalFinalized(success=true)` with the
message in `failedMessages` (value parked in the L1CDM); +11,363 / +4,045 gas delivers it; anyone can replay.
Confirmed with a real transaction (case 20: status 1, `successfulMessages`=0, `failedMessages`=1).

Large payloads: the budget grows 16–40 gas/byte, the pre-check cost ~3.1 gas/byte + 9.6e-6*len^2, so the margin
only turns negative at ~1.3 MB (old) / ~3.8 MB (live) — far beyond what one L1 transaction can carry (300 kB of
zero bytes already needs 15.5M gas; EIP-7825 cap 16,777,216 — cap argued from the EIP, anvil runs Prague rules).

## 3. Answer to the key question (permanent freeze through the old L2 budget?)

No. Three independent killers:
1. `SafeCall.sol:162` forwards `gas()`; a finalizer can always add gas (any message that fits the L1 tx gas cap).
2. Even at the portal minimum the old budgets exceed the v9 L1 requirement unless `minGasLimit` > 5.76M, and then
   the result is a recorded, replayable failure, not a revert.
3. If `relayMessage` does run out of gas the portal now reverts (`OptimismPortal2.sol:651-653`), nothing is
   finalized, nothing leaves the lockbox.

The only withdrawals that can never finalize are the documented ones (unsafe target; legacy message already
relayed) plus the pre-existing "does not fit an L1 transaction" class (e.g. a 600 kB message: 31.7M L2 gas to send,
`gasLimit` 24,031,400 -> portal needs > 24.4M gas). None is created or widened by U21.

## 4. Real in-flight population across the upgrade

`WithdrawalProven` logs, blocks 26425859–26430858: 39 proofs, 37 with `from = L2CDM, to = L1CDM`. 38 were direct
calls to the portal and are decoded from the prove-tx calldata (`evidence/lane08/proven_txs.json`): 36 messenger
(19 version-1, 17 version-0) + 2 fee-vault withdrawals; all 38 have `sentMessages[hash] = true` on OP Mainnet. Budget generations seen: `G_live` (312,784; 516,982; 669,875; …),
`G_old` (288,648; 492,334), migrated v0 (1,308,617; 1,307,081). One address (`0xa7fad3a7…f4dda`) proved 27 old
withdrawals, 17 of them version-0 legacy ones (16 ERC20: LINK, UNI, GTC, …, plus one `finalizeETHWithdrawal` whose
xDomain sender is the L2CDM itself and which the bridge rejects; `successfulMessages[oldHash] = 0` for all,
different recipients) — a sweeper/relayer; benign, but it shows the v0 path is in live use.

`test/InFlight08.t.sol` (`--isolate`, both forks): after letting the referenced games resolve and the proofs
mature, **all 38 finalize; outcome at the portal-minimum gas and at +3M is identical on v8 and v9**
(33 delivered, 3 failed-recorded because the target reverts, 2 non-messenger). `evidence/lane08/inflight_l1*.log`.

`test/Legacy08.t.sol`: the real legacy withdrawal nonce 106600 delivers once; with `successfulMessages[oldHash]`
set (the production state of any already-relayed legacy message, emulated by `vm.store`) v9 reverts
`L1CDMCallFailed` at 2M/10M/50M gas, v8 finalizes with `success=false` and no record.

## 5. Every revert of v9 `relayMessage` reachable from the portal path

`CrossDomainMessenger.sol` (v9) line -> reachable for a withdrawal with `sender == L2CDM`? -> permanent?

| line | condition | reachable | permanence / consequence |
|---|---|---|---|
| ABI decode (`bytes memory`) | malformed calldata | no — L2CDM encodes canonically | — |
| 222 | `paused()` | only if portal is not paused but the messenger is; both resolve to `ethLockbox.paused()` (`L1CrossDomainMessenger.sol:98`, `SystemConfig.sol:574`, `OptimismPortal2.sol:306-308`) so the portal reverts first | transient |
| 225 | version >= 2 | no — L2CDM stamps `MESSAGE_VERSION = 1`; migrated ones are 0 | — |
| 231 | v0 and legacy hash already relayed | yes (migrated set contains relayed messages) | permanent; documented; value is 0/irrelevant |
| 242 | `assert(msg.value == _value)` | no — L2CDM passes `msg.value` twice | — |
| 243 | `assert(!failedMessages[hash])` | no — a failed entry needs an earlier portal delivery of the same hash, i.e. the same withdrawal, which is then `finalizedWithdrawals` | — |
| 250 | unsafe target (L1CDM, portal) | yes, sender's own choice | permanent; documented; ETH never leaves the lockbox |
| 254 | already successful | no (same argument as 243) | — |
| 277/303 | `tx.origin == ESTIMATION_ADDRESS` | no real tx | — |
| OOG before 269/292/295, incl. in the proxy | yes | retry with more gas |
| 285 underflow `gasleft() - 135,000` | no — check guarantees >= 190,000, window costs ~5.4k | — |
| 291 `assert(successfulMessages == false)` after the call | no — target cannot set it (re-entry hits 247 or the 267 branch) | — |

`relayMessage` cannot return normally without writing `successfulMessages` or `failedMessages` (lines 269, 292,
295 cover every non-reverting exit); no `FINALIZED_NORECORD` appeared for a messenger withdrawal on v9 in any run.
The portal therefore sees failure only when the messenger reverts, and a revert undoes any messenger write, so
"failed in L1CDM while not finalized in the portal" cannot exist.

## 6. Third-party interference (`test/Semantics08.t.sol`, passes on both forks)

- S2 forced-fail: replay your own failed message; from inside it call
  `finalizeWithdrawalTransactionExternalProof(victim, submitter)`. `xDomainMsgSender != DEFAULT` (line 267) records
  the victim's message failed, the portal finalizes, value sits in the L1CDM, any later replay delivers exactly
  once with the right `xDomainMessageSender`. Identical in v8. Cost to victim: one replay transaction.
- S5 poisoning: direct `relayMessage` of an undelivered hash reverts (247); a non-messenger withdrawal carrying the
  same `relayMessage` calldata reverts inside the messenger and is finalized as failed without touching the hash;
  the victim then delivers normally.
- S8: a message target cannot re-enter `finalize…` (`OptimismPortal_NoReentrancy`, line 594).
- Pre-proving does not interfere: proofs are keyed by `(hash, submitter)`.

## 7. Bridges as relay targets, and the L1 -> L2 direction

- `StandardBridge.finalizeBridgeETH` (`:239-259`), `finalizeBridgeERC20`, `L1ERC721Bridge.finalizeBridgeERC721`:
  unchanged (v8->v9 diff is whitespace). Their reverts are swallowed by `SafeCall.call` inside the messenger ->
  `failedMessages` -> replayable. S3 shows it end to end (rejecting recipient -> finalized + failed, 3 ETH in the
  L1CDM, replay after the recipient is fixed, second replay and second finalize revert).
- `L1CDM.baseGas` is numerically identical before and after U21 and equal to the live L2 formula for 48 inputs
  (`test/BaseGas08.t.sol`); L2CDM code is unchanged, a failing L2 target is recorded failed and replayable
  (`test_l2_relay_from_l1_with_l1_baseGas`). The live L2CDM refuses to relay to itself or to the
  `L2ToL1MessagePasser`, which is what makes the portal's "sender check is enough" comment true.

## 8. Method notes and limits

- Arbitrary messenger withdrawals were proven through the real `proveWithdrawalTransaction` against a dispute game
  (respected type 9) created on the fork over a fabricated super root whose message-passer storage trie holds one
  leaf; the game resolves unchallenged after `vm.warp`. This is only a vehicle: the same `provenWithdrawals` entry
  is reached on mainnet by sending the message on L2. No `vm.store` on the portal anywhere.
- Gas rules: Prague/Osaka (what mainnet enforces at the pinned block). **Amsterdam / EIP-8037 statements are not
  locally reproducible**: (a) the 135,000 L1 reserve and the 183,600 `callWithMinGas` reserve are pre-positioned and
  already enforced — `test/NewAccount08.t.sol`: finalizing 1 ETH to a never-touched account needs 380,649 gas on
  v9 vs 208,201 on v8 (existing EOA: 194,145 vs 208,201); the extra is unused, not spent. (b) With today's rules
  the margins above hold; under Amsterdam an old-budget message at the portal minimum can run out of gas after the
  target call (state gas for the fresh slot / new account), which the portal revert turns into "retry with more
  gas", not a loss — argued from the EIP text and the v9 comments only.
- Upstream RPC was rate-limited for part of the session; the private anvils were forked directly from the archive
  endpoint (reads only).

## 9. Files

- `primitives/PRIM-0801 … 0805`, `rejected/REJ-0801 … 0808`, no candidate.
- `test/poc/lane08/` (harness copy: `test/*.sol`, `scripts/measure2.py`, `validate_tx.py`, `anvil.sh`).
- `evidence/lane08/` (tables, JSON, logs, decoded real prove transactions).

## 10. Open questions for other lanes

1. Chains still on the v8 messenger/portal (not in the U21 tx) keep the behaviour reproduced here on `l1pre`: a
   third party who finalizes a messenger withdrawal with the minimum gas loses it for good when the payload is
   >~85 kB and the target consumes its gas. Fixed by U21, so "known"; scope/eligibility is for the orchestrator.
2. The legacy double-relay guard rests entirely on slot 203 of the L1CDM keeping the pre-Bedrock
   `successfulMessages` entries; U21 did not touch it (layout identical), and legacy withdrawals are being swept
   right now. A lane looking at the migrated set could test a known already-relayed legacy message end to end.
3. When the L2CDM is eventually upgraded to 2.4.0 its `baseGas` grows by 105,000; until then the 5.76M–7.32M
   `minGasLimit` band stays "fails at minimum gas".
