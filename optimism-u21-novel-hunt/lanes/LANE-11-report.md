# LANE 11 — Invariant and differential fuzzing (executed against the real deployed bytecode)

Forks: `l1` (post-U21, block 26433900: portal 6.1.0, L1CDM 2.13.0, ETHLockbox 2.0.0, ASR 4.0.0,
SystemConfig 4.3.0), `l1pre` (block 26430858: portal 5.8.0, L1CDM 2.11.1, ETHLockbox 1.3.1,
ASR 3.9.0, SystemConfig 4.0.0), `l2` (OP Mainnet 159654093: L2CDM 2.2.1).
Harness: `/home/user/u21-work/lane-11` (forge 1.5.1, `evm_version = "osaka"`). Nothing was
broadcast; the three shared anvils were only read.

Result in one line: **no vulnerability candidate.** Three evidenced primitives, five rejected
ideas with the killing measurements, and a reusable real-withdrawal fixture.

## 1. Deliverables

| Path | Content |
|---|---|
| `test/poc/README.md` | fixture documentation, install + run instructions |
| `test/poc/U21Fixtures.sol` | fixture loader + honest-path drivers (reusable base) |
| `test/poc/FixtureE2E.t.sol` | end-to-end finalization of every curated fixture |
| `test/poc/U21GasScan.sol`, `GasBoundary.t.sol`, `InjectedGas.t.sol` | gas-boundary scans + fuzz (real / harness-injected withdrawals) |
| `test/poc/Differential.t.sol` | D1–D6 v8 vs v9 differential |
| `test/poc/PortalInvariants.t.sol` | stateful invariant campaign |
| `test/poc/NestedReplay.t.sol`, `L2RelayGas.t.sol` | PRIM-1102 / PRIM-1103 executables |
| `test/poc/lane11-tools/` | log fetch, calldata decoding, fixture generation, table/diff scripts |
| `evidence/withdrawal-fixtures{.json,-all.json,/}` | the fixtures (31 curated + 2 reference; 145 total) |
| `evidence/lane11/` | every raw output quoted below |
| `primitives/PRIM-1101..1103.md`, `rejected/REJ-1101..1105.md` | findings |

## 2. Real-withdrawal fixture (task 1)

1347 portal logs in L1 blocks 26363900..26433900 → 355 proven hashes, 221 finalized at the pin,
**134 unfinalized hashes / 145 proof entries**, every one against a type-9 (SUPER_CANNON_KONA,
impl v0.8.0) game; 66 distinct games (24 IN_PROGRESS, 24 DEFENDER_WINS in air-gap, 17 claim-valid,
1 CHALLENGER_WINS). Classes: 24 pre-U21 mature+valid (finalizable with zero setup), 36 pre-U21
game-final/immature, 35 resolved/in air-gap, 46 in-progress (2 plain SequencerFeeVault withdrawals
of 53.5 and 27.2 ETH), 3 proven after U21, 1 forged proof (PRIM-1101). No unfinalized plain
withdrawal without value exists in the window (coverage gap, filled by injected cases).
All structs re-hash to the logged withdrawal hash; `proveCalldata` is the exact mainnet calldata.

End to end on `l1` (`FixtureE2E::test_e2e_all_fixtures`, `evidence/lane11/e2e-l1.json`): 30/31
fixtures finalized through public functions only (`vm.warp` + `resolveClaim`/`resolve` + finalize);
all 28 messenger ones `successfulMessages = true`, lockbox delta = −value exactly, portal balance 0.
No privileged prank, no `vm.store`. On `l1pre` 27/27 pre-U21 fixtures give the same outcomes.

## 3. Invariant groups (task 2) — `PortalInvariants.t.sol`, fork `l1`

Checked after every handler call (single `invariant_all`):

1. ETH conservation, per contract: `portal.balance == Σ donateETH`;
   `L1CDM.balance == Σ value of failed-not-yet-relayed messages`;
   `lockbox.balance == initial + Σ deposits − Σ delivered − heldByMessenger`.
2. Uniqueness: per-hash finalize count ≤ 1; a message is delivered ≤ 1 across finalize / external
   proof / messenger replay.
3. Proof isolation: prove / delete by B leaves every other submitter's `(game, timestamp)` entry
   bit-identical; a successful finalize always had (proof by that submitter ∧ > 7 d ∧
   `isGameClaimValid` ∧ not paused) before the call.
4. Finalized ⇒ delivered-or-replayable: finalized messenger withdrawal ⇒ successful ∨ failed, and
   the messenger holds the value of every failed one.
5. Pause: no prove / finalize / replay succeeds while the lockbox or global identifier is paused
   (guardian prank = production incident path); deposits do succeed (by design).
6. `deleteProvenWithdrawal` succeeds ⇔ proven ∧ (CHALLENGER_WINS ∨ blacklisted).
7. No forbidden re-entrant call succeeds from an adversarial target (`vm.etch`: revert, burn,
   200 KB return bomb, re-enter: nested finalize, self-relay, `unlockETH`, `lockETH`, `migrateLiquidity`).

Campaigns: 24 runs × 40 calls and 24 runs × 50 calls = **2 160 handler calls, 0 violations**
(default forge seed; `evidence/lane11/campaign-results.txt`, coverage in
`invariant-coverage-campaign{1,2}.txt`): finalize.ok 108 (relayed 85, failedMsg 14, plainOk 8,
plainFail 1), prove.ok 107, replay.ok 7 (5 delivered), delete.ok 1, pause.ok 50, blacklist.ok 16,
deposits 363 (52 while paused), 186 adversarial etches.
What stays true and is not a violation: `donateETH` strands ETH in the portal; failed plain
withdrawals are finalized with the value re-locked and no replay (unchanged from v8).

## 4. Differential v8 vs v9 (task 3) — every difference and its documented cause

`evidence/lane11/diff-report.txt` (741 keys):

| Test | Keys | Differences | Cause |
|---|---|---|---|
| D1 getters + per-fixture portal state | 181 | 11 | versions; `lockbox.systemConfig()` removed / `guardian()` + `superchainConfig` slot 3 added (ETHLockbox diff); `asr.systemConfig()` removed (ASR 4.0.0 stores `ethLockbox`); `deleteProvenWithdrawal` exists; `asr.anchorGame` moved between the pins. All 28 pre-U21 fixtures: `provenWithdrawals`, `finalizedWithdrawals`, `numProofSubmitters` untouched by the upgrade |
| D2 re-prove | 224 | 0 | — |
| D3 deposits 0…120 001 bytes | 230 | 1 | `migrateLiquidity` from an EOA: `NotUsingInterop` → `NotProxyAdminOwner` (gate changed in the diff) |
| D4 finalize with a failing messenger (harness `vm.store` on L1CDM: pre-set failed flag; legacy v0 already relayed) | 16 | 8 | v8: `WithdrawalFinalized(success=false)`, flag set, second finalize `AlreadyFinalized`; v9: `0x979d93bf OptimismPortal_L1CDMCallFailed`, stays unfinalized forever (documented: notice l.52/193) |
| D5 pause identifiers (lockbox, 0, portal, systemConfig, l1cdm) | 60 | 0 | — (REJ-1104) |
| D6 `deleteProvenWithdrawal` | 30 | 8 | function is new; only the forged proof is deletable |

Minimum gas for the same real withdrawal (cold, gas given to the portal call frame;
`evidence/lane11/gas-boundary-v8-vs-v9.txt`):

| fixture | gasLimit | min gas v8 | min gas v9 | Δ |
|---|---|---|---|---|
| f0 messenger, old L2 formula, value | 287 624 | 502 334 | 488 278 | −14 056 |
| f1–f4 legacy v0 message, value | 1 307 593 | 1 554 940 | 1 540 884 | −14 056 |
| f5–f8 messenger, no value | 516 982 | 712 033 | 706 380 | −5 653 |
| f10 messenger, 2 488 ETH | 515 958 | 737 974 | 723 918 | −14 056 |
| f13/f15 plain 53.5 / 27.2 ETH | 400 000 | 617 043 | 602 986 | −14 057 |
| f17–f20 messenger, no value | 669 875 | 869 908 | 864 255 | −5 653 |
| f16/f29/f30 proven post-U21 | 287 624 / 516 982 | n/a | 488 278 / 706 380 | — |

On both forks, for every real fixture, the minimum non-reverting gas equals the minimum relaying
gas and the revert below it is `SafeCall: Not enough gas`: no failed/neither band exists.
v9 is cheaper (shorter pause-check path). The single shape that got more expensive is a plain
value withdrawal to an empty account: +169 908 gas (REJ-1103).
Ample-gas outcomes are identical for the 27 pre-U21 fixtures (`e2e-l1pre.json` vs `e2e-l1.json`).

The one behavioural class difference found: **v8 has a `FINALIZED_NEITHER` gas window, v9 has
none** (Set 4, `injected-S4-v8-vs-v9.txt`, harness-injected withdrawals, target burns all gas):

| inner message | L2 formula | v8 NEITHER window (gas) | v8 FAILED from | v9 |
|---|---|---|---|---|
| 35 KB | live L2CDM 2.2.1 | 1 764 974 … 1 876 096 | 1 890 753 | FAILED from 1 759 322 |
| 35 KB | legacy | 1 159 811 … 1 876 000 | 1 887 725 | FAILED from 1 154 158 |
| 50 KB + 1 ETH | legacy | 1 489 079 … 2 055 075 | 2 068 000 | FAILED from 1 472 483 |
| 65 KB | legacy | 1 768 319 … 2 161 125 | 2 175 250 | FAILED from 1 762 667 |
| 105 KB | legacy | 2 606 631 … 2 616 075 | 2 633 400 | FAILED from 2 600 978 |
| 15/25 KB, ≥ 115 KB, ≥ 45 KB with the live formula | | none | | none |

(window ends are bracketed by the 1/400-range sweep, i.e. ±≈13–17 k gas). Cause: v8 computes
`gasleft() − 40 000` before copying the calldata message to memory, so the copy eats the reserve
(PRIM-1103). This is exactly the documented U21 fix (notice l.53), so the difference is explained.

## 5. Gas-boundary fuzz (task 4)

| | shapes | probes | NEITHER | FAILEDMSG |
|---|---|---|---|---|
| v9 real fixtures | 27 | 51 316 | **0** | 0 |
| v9 injected (P, S1, S2, S4) | 133 | 85 341 | **0** | 19 933 |
| v8 real fixtures | 24 | 45 815 | 0 | 0 |
| v8 injected | 133 | 85 404 | 2 175 (12 of 133 shapes, all "30–105 KB message + gas-burning target") | 17 748 |

plus 4 × 256 fuzz runs (`testFuzz_gas_class`, `testFuzz_injected_gas_class`, both forks), all pass.
Per-probe accounting assertions (relayed ⇒ target paid exactly, messenger empty; failed ⇒
messenger holds the value; target observed ≥ minGasLimit; reverted ⇒ lockbox and finalized flag
untouched; `l2Sender` reset; portal balance 0): 0 violations on either fork.
**Under v9 the class "finalized with neither mapping recorded" was not reached at any of
136 657 probed gas values over 160 withdrawal shapes.**

## 6. Primitives

- **PRIM-1101** — live forged 90 000 ETH proof against an attacker-created type-9 game with a
  future super-root timestamp; countered in 12 s, CHALLENGER_WINS; entry still stored; deletable
  by anyone in v9.
- **PRIM-1102** — any finalizable messenger withdrawal can be forced into `failedMessages` at any
  gas by finalizing it from inside an L1CDM replay; value parked in L1CDM; pre-existing, griefing.
- **PRIM-1103** — the relay-reserve defect fixed on L1 by U21 is still live on the un-upgraded
  L2CDM 2.2.1: 20–60 KB L1→L2 message + gas-exhausting target ⇒ deposit reverts, message in
  neither mapping, ETH stranded on the aliased L1CDM. Score as a candidate: −4.

## 7. Coverage limits (honest)

- Gas scans are exhaustive only within ±150…800 gas of the boundaries; elsewhere stepped.
- Inner messages > 300 KB, minGasLimit > 1M, ERC-20/721 bridge-specific failure modes and
  token callbacks were not explored; the inner targets of real fixtures are almost all the
  L1StandardBridge.
- Amsterdam / EIP-8037 gas rules cannot be simulated; every gas statement is for today's rules.
- Harness-injected withdrawals bypass `proveWithdrawalTransaction` (one `vm.store`); they measure
  gas behaviour only and prove nothing about reachability.
- Only OP Mainnet's single-portal lockbox; no shared-lockbox / multi-portal (interop) topology;
  Ink / Soneium / Unichain only via cast reads of their pause configuration.
- Invariant campaign: 2 160 calls with the default seed — a smoke-level stateful search, not a
  proof. Game-level adversarial moves (attack/defend/step) were not part of the handlers; games
  were only resolved through the uncontested path.
- The L2 matrix models a deposit's frame gas as `baseGas − 21000 − calldata gas`; it was not
  cross-checked against a real derived deposit of that size.
- Blind-first: no audit / known-issue comparison was made for any item.

## 8. Open questions for other lanes

1. Challenger-liveness / resolution primitives on type-9 games combined with the PRIM-1101
   pattern (the on-chain game's `extraData` is a ready template).
2. Does the L2 upgrade path (L2ContractsManager) actually deliver the `bytes memory` messenger to
   `0x42…07`, and are there production L1→L2 flows with ≥ 20 KB payloads (PRIM-1103)?
3. Amsterdam: does a value CALL to a new account inside `relayMessage` (183 600 state gas charged
   in the messenger frame) fit in the 135 000 reserve when the target burns everything? Under v9
   the portal would revert (retryable), so the question is whether some message becomes
   un-finalizable below the tx gas cap. Not reproducible here.
