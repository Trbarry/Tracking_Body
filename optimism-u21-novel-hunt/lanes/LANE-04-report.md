# LANE 04 - Withdrawal finalization and replay (OP Mainnet portal v6.1.0 / L1CDM v2.13.0, U21)

Result: **no candidate**. Neither invariant was broken on the deployed implementations.
(A) "finalized-and-undelivered with the replay path removed" and (B) "same economic withdrawal executed twice"
both hold for messenger withdrawals; for direct (non-messenger) withdrawals (A) is violated only in the
documented, user-inflicted way, and the exact third-party window is quantified in PRIM-0402.
Six primitives (PRIM-0401..0406), ten rejections (REJ-0401..0410), 37 passing fork tests.

All fork work: `forge test` in `/home/user/u21-work/lane-04` (copy in `test/poc/lane04/`), forks `l1` (26433900),
`l1pre` (26430858), `l2` (159654093). No transaction was sent anywhere; shared anvils were only read.
Gas thresholds quoted "cold" come from `forge test --isolate` (each top-level call is its own transaction).
Outputs: `evidence/lane04-forge-output.txt`, `evidence/lane04-forge-isolate-output.txt`.

## 1. Material used

- 43 real `proveWithdrawalTransaction` calls on the OP portal, L1 blocks 26425493..26433490 (40 before the U21
  block 26430859, 3 after), recovered from `WithdrawalProven` logs; structs and proofs decoded from calldata
  (`test/poc/lane04/proves.json`). 41 messenger withdrawals (sender 0x42…07 -> L1CDM), 2 direct
  SequencerFeeVault withdrawals (sender 0x42…11 -> minimal proxy 0xa3d596EA…, 27.24 and 53.47 ETH, gasLimit 400,000).
- Respected game type on OP Mainnet is 9 (SUPER_CANNON_KONA) before and after U21; proofs go through
  `rootClaimByChainId(10)`; game extraData holds a single-chain super root (`01 | ts | chainId 10 | outputRoot`).
- Honest games were resolved in-process through `resolveClaim(0,0)` + `resolve()` after `vm.warp` (no pranks).
- The real U21 transaction was re-executed on `l1pre` for the cross-version tests (PRIM-0405).
- Fabricated proofs (`vm.store` into `provenWithdrawals`, slot 57) are used only to characterise branches that no
  real withdrawal exercises; every such test is labelled.

## 2. State machine (per withdrawal hash h, per submitter s)

Portal storage: `provenWithdrawals[h][s] = (game, ts)`, `proofSubmitters[h][]`, `finalizedWithdrawals[h]`, `l2Sender`.
Messenger storage (messenger withdrawals only): `successfulMessages[m]`, `failedMessages[m]`, `xDomainMsgSender`.
`[M]` marks a guard that reads MUTABLE CURRENT configuration for an object created earlier.

| # | From -> To | Function (caller) | Guards |
|---|---|---|---|
| T1 | unproven(h,s) -> proven(h,s,game,now) | `proveWithdrawalTransaction` (anyone; s = msg.sender) | not paused [M: lockbox->SuperchainConfig]; target not portal / current lockbox [M]; CGT => value 0 [M]; game = DGF.gameAtIndex [M: ASR->DGF]; `isGameProper` [M: registered in current DGF, blacklist, retirementTimestamp, pause]; `wasRespectedGameTypeWhenCreated` (fixed at creation); status != CHALLENGER_WINS; now > createdAt; output root = `rootClaimByChainId(l2ChainId)` for types 4,5,7,9,10 else `rootClaim()` [M: systemConfig.l2ChainId]; trie proof of `sentMessages[h]`. Does NOT check `finalizedWithdrawals`. |
| T2 | proven(h,s) -> proven(h,s,game',now) | same, same s | as T1; overwrites, resets only s's timer; pushes s again into `proofSubmitters`. |
| T3 | proven(h,s) -> unproven(h,s) | `deleteProvenWithdrawal` (anyone) - NEW in v9 | ts != 0; game.status == CHALLENGER_WINS or blacklisted in the CURRENT ASR [M]. Array entry stays. |
| T4 | proven(h,s) & !finalized(h) -> finalized(h), delivered | `finalizeWithdrawalTransaction` (s) / `…ExternalProof(tx, s)` (anyone) | not paused [M]; CGT => value 0 [M]; `l2Sender == DEFAULT`; target safe [M: current lockbox]; `!finalized[h]`; ts != 0; ts > game.createdAt; now - ts > PROOF_MATURITY_DELAY (immutable of the CURRENT implementation [M]); `ASR.isGameClaimValid(game)` [M: current ASR pointer, DGF registration, blacklist, retirementTimestamp, pause, finality delay immutable of current ASR impl; plus DEFENDER_WINS + airgap]; lockbox `unlockETH` (pause [M], authorised [M], balance); `hasMinGas(gasLimit, 183,600 if value != 0 && target.codehash == 0)`; target call returns true. |
| T5 | same -> finalized(h), UNDELIVERED, value re-locked | same | as T4 but target call returns false and `sender != 0x42…07`. Terminal, no replay. |
| T6 | same -> unchanged (revert `OptimismPortal_L1CDMCallFailed`) - NEW in v9 | same | target call returns false and `sender == 0x42…07` (target not examined). |
| T7 | same -> unchanged (revert `OptimismPortal_GasEstimation`) | same | call failed and tx.origin == 0x…01 (now evaluated before T6 and before the event). |
| M1 | (inside T4) message m -> successful | L1CDM.relayMessage via portal | paused [M]; version < 2; v0 not already relayed; msg.value == _value; !failed[m]; target not L1CDM/portal; !successful[m]; `hasMinGas(minGas, 150,000)`; `xDomainMsgSender == DEFAULT`; target call ok. |
| M2 | (inside T4) message m -> failed (ETH kept by L1CDM) | same | as M1 but gas check fails, or messenger is mid-relay (`xDomainMsgSender != DEFAULT`), or target call fails. Portal still sees success => T4. |
| M3 | failed(m) -> successful(m) | `relayMessage` (anyone, msg.value 0) | paused [M]; failed[m]; !successful[m]; target safe; gas check; not re-entered; target call ok. |
| M4 | failed(m) -> failed(m) | same | as M3 but gas check / re-entrancy / target failure. Below ~75k gas reverts, 75k..265k (minGas 0, cold) returns without effect. |

Terminal states: `finalized(h)` (portal) and `successful(m)` (messenger). No transition leaves either; no
transition clears `finalizedWithdrawals`, `successfulMessages` or `failedMessages`.

Observations on the `[M]` guards (objects created earlier, config read now):
- A proof is evaluated against the ASR *pointer at finalize time* and against that ASR's *current* blacklist,
  retirement timestamp, pause and factory; a withdrawal already proven can be invalidated (never upgraded) by
  config changes, and T3 lets anyone clear such an entry. None of these is permissionless.
- `PROOF_MATURITY_DELAY_SECONDS` and the finality delay are implementation immutables: an upgrade changes the
  wait of proofs that already exist (U21 kept 604800 / 302400).
- `_isUnsafeTarget` and `_isUsingLockbox` read the current lockbox / feature flag; the flag cannot be turned off
  (REJ-0407).
- The pause is one source for portal, ASR, L1CDM and SystemConfig after U21 (`ethLockbox.paused()`).

## 3. What was tested (fork, deployed implementations)

Real material:
- messenger withdrawal proven under v8, finalized under v9 by a third party (lockbox -119.59 ETH; -2000 ETH);
- 2000 ETH messenger withdrawal: gas sweep, forced-fail by nested finalize (PRIM-0401), replay;
- ERC20 messenger withdrawals (minGas 200k): gas sweep; one withdrawal whose bridge call underflows -> recorded
  failed, finalized, replay keeps failing (a fake-token shape, not pursued);
- FeeVault direct withdrawal (27.24 ETH): third party via ExternalProof, gas sweep (no failure window);
  with recipient code substituted by `vm.etch` (reverting): third party burns it, ETH stays in the lockbox;
- second submitter re-using the real proof, duplicate pushes, finalize with the other submitter's proof,
  all later attempts AlreadyFinalized; re-prove while a mature proof exists;
- `deleteProvenWithdrawal`: reverts for IN_PROGRESS and DEFENDER_WINS games, for unproven entries and for
  finalized withdrawals; succeeds for anyone after a Guardian blacklist (privileged setup); re-prove against the
  blacklisted game reverts `ImproperDisputeGame`;
- cross-version through the real U21 transaction: proven-v8 -> finalize-v9; failed-v8 -> replay-v9.
- L2 (deployed L2CDM v2.2.1): relay to the message passer / to itself is refused; `sendMessage` targets the L1CDM;
  its `baseGas` still uses the pre-v9 constants.

Fabricated proofs (branch characterisation):
- trigger table of `OptimismPortal_L1CDMCallFailed` (PRIM-0403);
- messenger message to the portal: never finalizable; message failing in the target: finalized + failed +
  replayable once, also through a non-messenger withdrawal carrying the same calldata;
- EOA target with `codehash == 0` vs `keccak("")`; burner targets, wrappers, return bomb / revert bomb (no effect
  on the portal: outlen 0, no returndatacopy), state-dependent target, gas probe (target receives 136,691 gas at
  the minimum outer gas 278,777 for gasLimit 100,000, cold);
- large messages 20 KB / 200 KB / 500 KB with the old L2 budget.

## 4. Answers to the brief

1. Which condition triggers `OptimismPortal_L1CDMCallFailed`? Only `!success && _tx.sender == 0x42…07`. The
   target is not looked at. sender = L2CDM + other target: reverts (unreachable from the live L2 code).
   target = L1CDM + other sender: no protection, withdrawal is consumed when the relay reverts.
2. Can a third party force "inner fails, outer succeeds" for someone else's direct withdrawal, with value, through
   the ExternalProof entry point? Yes, but only if the target rejects at that moment, or still fails after
   receiving >= 830,645 gas (direct) / 430,114 (one wrapper) / 301,794 (two wrappers); `_tx.gasLimit` below that
   is irrelevant because under-gassed attempts revert the outer call. Harmed: the withdrawer (ETH re-locked in
   the lockbox with no claim). The real FeeVault withdrawals are not forcible.
3. Can `relayMessage` succeed for the portal while the message is neither delivered nor recorded? No (REJ-0401).
   Delivered-not, recorded-failed, forced by a third party at will: yes (PRIM-0401), still replayable.
4. Failed-replayable in the messenger and finalizable again in the portal? No (REJ-0402).
5. Cross-version: v8 proofs finalize once under v9; v8-failed messages replay once under v9 (REJ-0409).
6. Amsterdam constants today: +183,600 gas requirement for value to a never-touched account, removable by
   anyone with 1 wei; L1 relay reserve 150,000 instead of 45,000 while L2 still budgets 45,000 - absorbed by slack,
   no failure window (PRIM-0404, REJ-0406). Statements about behaviour under EIP-8037 are reasoning from the
   constants in `GasConstants.sol` / `SafeCall.sol` and are NOT locally reproducible.

## 5. Open questions / hand-offs

- PRIM-0404 residual: ~55k gas of slack is all that keeps minimal-gas finalizations from being recorded as
  failed while L2 runs v2.2.1. Worth re-measuring on the sibling chains' L1CDMs (ResolvedDelegateProxy vs
  normal Proxy differ in overhead) and against any chain whose pause path is longer.
- PRIM-0401 composition: look for production relay targets whose behaviour depends on `portal.l2Sender()` or on
  being called in the same transaction as the finalization; for those, forced-fail + replay is not equivalent
  to first delivery.
- `rootClaimByChainId` returns the FIRST entry matching the chain id and `decodeSuperRootProof` does not reject
  duplicate or unsorted chain ids (Encoding.sol:308-345, SuperFaultDisputeGame.sol:809-819). Whether a super
  root with two entries for one chain can survive the fault proof is a dispute-game question, not examined here.
- Sibling chains: L2 predeploy versions of Ink / Soneium / Unichain were not read (no local L2 fork), so
  REJ-0405 is proven for OP Mainnet only.
- Historical `FailedRelayedMessage` logs could not be enumerated (public getLogs limited to ~10k recent blocks:
  none in 26424600..head), so the L1CDM solvency invariant "balance >= sum of failed, unreplayed values" was
  argued from code, not checked against chain history.
