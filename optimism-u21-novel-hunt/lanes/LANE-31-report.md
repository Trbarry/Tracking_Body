# LANE 31 report — Invariant and differential fuzzing

## Executive result

No bounty candidate survived falsification, so lane 31 writes no `CAND-31xx.md`.

The principal security result is positive: against the real deployed v9 portal and L1 messenger, a real post-U21 type-9 withdrawal never finalized without a messenger outcome at any of 192 sampled outer gas values or at the exact discovered boundary. The minimum non-reverting portal finalization and successful relay were both 708,920 gas for that fixture. At 708,919 the call reverted and portal/lockbox state rolled back.

The exact N-1 -> N semantic difference for a failed messenger call is the documented U21 fix: v8 commits a failed finalization; v9 reverts `OptimismPortal_L1CDMCallFailed` and leaves it retryable. Normal finalization, re-proving, view wiring, deposit acceptance, events, and custody remained consistent. One unexplained calldata-proportional deposit gas regression was measured, but it has no reproduced semantic or eligible impact and falls under the engagement's explicit suppression.

## Safety, provenance, and method

- No public transaction was signed or broadcast. Public/local RPC use was passive only. All state transitions, including game resolution, guardian pause setup, `vm.etch`, and finalization, occurred inside `forge test` forks.
- Target v9 commit: `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`; baseline v8: `f45a5ccfebcdf6da3f5b09cbc512667c063730b7`.
- Exact state forks: N-1 `26430858`, N `26430859`, later post `26433900`, and OP Mainnet `159654093`.
- I did not read prior audits, findings, sibling lanes, or forbidden orchestrator outputs. Permitted U21 documentation was used only to classify independently observed differences.
- Raw exact implementation slots, versions, feature flags, storage, constants, and balances are in `mirror/lane-31/onchain-state-reads.txt`; the summarized map is `mirror/lane-31/U21_PROXY_IMPLEMENTATION_MAP.md`.

## Real fixture construction and end-to-end proof

The 60,001-block scan `26373900..26433900` produced 1,247 portal events: 470 proof events, 470 proof-submitter extensions, and 307 finalizations, with zero missing chunks. Publicnode rejected the archive request with HTTP 403, preserved in `logs/publicnode-probe.json`; the full passive scan used DRPC in 100-block chunks. See `mirror/lane-31/WITHDRAWAL_FIXTURES.md`.

Eight complete JSON fixtures retain the real prove calldata, decoded withdrawal tuple, DGF index, output-root proof, all trie nodes, event hash/submitter, and pinned-fork state. Coverage includes pre/post messenger, zero/value, valid plain value, and a real invalid high-value plain proof. No plain zero-value proof existed in the scanned window, and none is claimed.

`RealWithdrawalFinalizationTest` loads `post-messenger-zero-1.json`, checks the withdrawal hash, warps the real type-9 game clock, permissionlessly calls `resolveClaim(0,0)` and `resolve()`, waits both maturity periods, and finalizes through the deployed v9 portal/L1CDM. **No prank is used for resolution or finalization.** The only privileged prank anywhere in the suite is the real Guardian used to create a legitimate pause state, explicitly setup-only. Public game resolution is implemented by the deployed game; source entry points are at `/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/dispute/FaultDisputeGame.sol:704-829`, and portal maturity/validity checks at `OptimismPortal2.sol:671-704`.

The finalization emitted success, set the global flag, recorded exactly one messenger outcome, retained no ETH in the portal, and preserved lockbox balance for value zero. Trace: `test-results/real-finalization-trace.txt`.

## State machine and invariants

The handler covers deposits with bounded value/data, donations, proof replay by alternate submitters, finalize/external-proof replay, valid-proof deletion attempts, time warps, and pause/extend. Four Foundry invariant campaigns ran 16 runs x depth 10 each (640 total handler calls, zero reverts), plus a deterministic 36-action sweep:

1. `portal.balance + lockbox.balance == initial custody + deposits + donations - value delivered out of portal/lockbox`.
2. Portal balance equals explicit donations; value deposits go directly to lockbox.
3. Any successfully finalized messenger withdrawal has `successfulMessages || failedMessages`.
4. Portal `l2Sender` is always restored to the default sender.

All passed. See `test/PortalHandlerInvariant.t.sol` and final output `test-results/forge-test-full.txt`.

Additional real-proof checks established:

- Global withdrawal uniqueness across direct and external proof paths (`OptimismPortal2.sol:603-610,671-679`).
- Proof isolation: another submitter cannot reset the original timer; same-submitter reprove resets only its timer. The enumerable list appends duplicates (`:480-487,797-801`), recorded as PRIM-3103.
- Deletion is confined to challenger-win or ASR-blacklisted games (`:711-727`).
- Pausing the lockbox identifier consistently pauses portal, lockbox, SystemConfig, and L1CDM outflows. Proof/finalize/unlock revert. Inflows remain deliberately open: the lockbox says “Unlocks are blocked when paused, locks are not” (`ETHLockbox.sol:142-177`). The test added exactly 3 ETH to lockbox and 1 ETH donation to portal, with no exit.
- Reverting and gas-burning messenger replacements roll back finalization/value unlock. A reentrant replacement cannot reenter either finalize path because `l2Sender` is the portal's reentrancy guard (`OptimismPortal2.sol:591-595`). Return-bomb/no-op behavior is isolated as a mocked trust boundary only.

## Exact differential matrix

Full details and gas curve are in `mirror/lane-31/DIFFERENTIAL_RESULTS.md`.

| Same action / fixture | N-1 v8 | N v9 | Result |
|---|---|---|---|
| Normal real messenger finalize | success, 213,582 measured gas | same state/event, 219,563 | no semantic difference |
| Immediate failing L1CDM call (`vm.etch`, same proof) | finalized, event false | `OptimismPortal_L1CDMCallFailed`, unfinalized | documented U21 hardening |
| Minimum outer gas, same real proof | 643,533 | 648,547 | +5,014; both safe at boundary |
| Alternate submitter prove + same submitter reprove | isolated/reset/list +2 | identical | no difference |
| Portal getters | 5.8.0 | 6.1.0 | guardian/SuperchainConfig values unchanged |
| 120,000-byte deposit | success/event/custody match | same | more v9 gas only |
| 120,001-byte / underpriced deposit | reverts | matching reverts | no difference |

V9's failed-messenger gate is at `OptimismPortal2.sol:639-653`; v8's commit-on-failure behavior is `/home/user/ethereum-optimism/op-v8.0.0/packages/contracts-bedrock/src/L1/OptimismPortal2.sol:614-624`. The U21 notice documents the change at `/home/user/ethereum-optimism/optimism/docs/public-docs/notices/upgrade-21.mdx:50-55,193-194`.

The exact 120 kB isolated deposit measurement was 5,194,026 -> 5,635,990 gas. A warmed length curve reached +729,397 at 120 kB. Acceptance, minimum L2 gas, event digest, balances, and error selectors match. Source deposit logic is at v8 `OptimismPortal2.sol:684-738` and v9 `:741-795`; the deployed gas cause remains unexplained, so it is PRIM-3105, but large-calldata/specific-gas griefing is suppressed.

## Gas-boundary result

The real v9 messenger classification comprised 64 fuzz values, 128 deterministic pseudorandom values, and binary probes. Deterministic counts: 43 reverted/unfinalized, 85 finalized+relayed, 0 finalized+failed, **0 finalized+neither**. Coverage is bounded, not exhaustive.

L1CDM records failure before returning on insufficient relay gas (`CrossDomainMessenger.sol:256-281`) and records success/failure after the target call (`:284-306`). The portal's messenger-specific low-level failure rolls back (`OptimismPortal2.sol:639-653`). `GasConstants.sol:49-78` documents the “neither mapping” hazard and raises L1 local reserve/buffer to 135,000/15,000. See `mirror/lane-31/GAS_BOUNDARY_RESULTS.md`.

## New-account reserve and Amsterdam

V9 reserves 183,600 additional minimum gas when value is nonzero and target codehash is zero (`SafeCall.sol:7-9,95-132`). Using deployed v8/v9 portal bytecode with synthetic proof storage, empty-target minimum moved 241,483 -> 419,518; on v9, nonempty vs empty was 233,014 vs 419,518. This is a source/deployed-bytecode primitive only: the proof was mocked, the observed outer delta contains other costs, and Amsterdam is not active on pinned L1. No mainnet exploitability is claimed.

## Primitive ledger

- **PRIM-3101:** Real messenger finalization atomicity and exact gas boundary.
- **PRIM-3102:** Pause blocks outflows but intentionally accepts bridge inflows.
- **PRIM-3103:** Per-submitter proof isolation with duplicate enumerable entries.
- **PRIM-3104:** Codehash-zero value target adds the 183,600 v9 reserve pre-Amsterdam.
- **PRIM-3105:** Exact-N calldata-proportional deposit gas regression, semantics unchanged.
- **PRIM-3106:** Portal trusts successful L1CDM return rather than reading outcome mappings; mocked-only reachability.

## Candidate decision

No candidate file was created. The nearest serious shape is PRIM-3106, but its honest candidate-style score is **-3**: +2 reproduced against real portal code, +2 cross-contract invariant, +1 deterministic sequence, -3 mocked-only reachability, -3 no eligible reproduced impact, -2 unverified/non-production configuration. Real L1CDM gas fuzz killed the necessary production condition.

## Strongest killed ideas

- Real gas-induced finalized-neither: zero occurrences; exact boundary atomic.
- 90,000 ETH withdrawal: underlying game is real `CHALLENGER_WINS`; cannot finalize and is safely deletable.
- Pause bypass: only inflows stay open; all tested outflows revert and custody rises exactly.
- Multi-proof replay/deletion: global finalization prevents second delivery; valid proofs cannot be deleted.
- Reentrant/reverting/gas-burning target: no double finalize, custody drift, or stuck `l2Sender`.
- Empty-account reserve: retryable with gas, synthetic proof only, no eligible impact.
- Large calldata gas: real regression but identical semantics and expressly suppressed impact class.

Exact killing facts are in `rejected/REJ-3101.md` through `REJ-3108.md`.

## Compositions worth a separate lane

1. **Future L1CDM upgrades x portal success trust:** prove whether any real messenger branch, proxy-resolution edge, or future upgrade can return normally without either mapping; this is the only route from PRIM-3106 to the serious class.
2. **Amsterdam activation x target codehash transitions:** model EIP-8037 accurately, including empty-account deployment/selfdestruct timing and relayer estimation, before deciding whether PRIM-3104 ever exceeds inconvenience.
3. **Future interop migration x unbounded duplicate proof history:** inspect whether shared-portal/migration/indexing code ever iterates `proofSubmitters`; current v9 finalization does not, but duplicates are permissionlessly amplifiable.

## Files and verification

- Harness suites/scripts/config copied to `mirror/lane-31/{test,scripts,foundry.toml}`.
- Eight fixtures in `mirror/lane-31/fixtures/`; 60k-block raw scan in `mirror/lane-31/logs/`.
- State, fixture, differential, gas, proxy-map, traces, and complete test output under `mirror/lane-31/`.
- Six primitive files, eight rejection files, this report, and no candidate file.
- Final command: `forge test --fuzz-runs 64 -vv` — **27 passed, 0 failed, 0 skipped across 9 suites**.

## Coverage limitations

The gas sweep is sampled, one real messenger payload supplies the v9 exact-boundary campaign, no valid plain-zero fixture appeared in the scan, and the empty-account differential uses synthetic proof state. `vm.etch` tests locate cross-contract assumptions only. Amsterdam behavior is not locally simulated. The reentrant adversary covers portal deposit/donate/both finalize entries and lockbox lock/unlock, not literally every administrative or privileged selector. These limits are why no mocked or future-state condition is promoted to a candidate.
