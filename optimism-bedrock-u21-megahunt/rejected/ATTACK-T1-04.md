# ATTACK-T1-04 — "Messenger never reverts / portal always finalizes" inverted at v9: make a first relay revert

Lane ATK-T1, Opus 5.5. Target 4 (row 4). Kill type: failing experiment (pointer graph) + prior executed kills + known.

**Original safety condition.** Sherlock 2023-01 H-3 / 2023-03 M-1/M-4/M-6: the first relay from the portal never reverts; it
records `failedMessages`. v9 inverts the portal side: `OptimismPortal2.sol:651-653` reverts `OptimismPortal_L1CDMCallFailed`
iff `!success && _tx.sender == L2CDM`, so any way to make `relayMessage` REVERT on a first relay freezes the withdrawal.

**Revert branches of v9 `CrossDomainMessenger.relayMessage` on a first relay, each checked:**
| Branch (v9 `universal/CrossDomainMessenger.sol`) | Status |
|---|---|
| `require(paused() == false)` :222 — pause pointer mismatch between portal and messenger | EXECUTED `T1_Portal.t.sol::test_T1_04_pausePointerGraph`: on all four chains L1CDM.systemConfig == portal.systemConfig, SystemConfig.optimismPortal == portal, both resolve to `portal.ethLockbox()`; pauseTimestamps(0 / lockbox / portal) == 0. Same identifier => the portal is paused whenever the messenger is (finalize blocked first, retryable). |
| version >= 2 nonce :225 | L2CDM only emits version 1 (and 0 for migrated legacy) — sender-fixed |
| version 0 already relayed :229-232 | ATTACK-CATK-B-01 (4 OP objects, all paid pre-Bedrock) |
| `assert(!failedMessages)` :243 on first relay | requires the same v1 hash to have been relayed by the portal before = same withdrawal = already `finalizedWithdrawals` (C5) |
| unsafe target :250 | sender-chosen at L2 creation; documented in the portal (:640-646), KNOWN Part 2 #3 |
| reserve under the Amsterdam schedule | future-only (EIP-8037 not scheduled), C6 |
| reentrant-relay branch | records failed, does not revert: KNOWN Part 2 #1 (Trust M-1) |
| older L2 constants | Lane C ATTACK-C-01..09, CATK-C-01..04 (every generation delivers within 2^24) |

**Barrier.** No third party can make the first relay revert: every revert branch is either fixed by the sender at L2 creation,
shared with the portal's own pause, or requires the withdrawal to be already finalized. Output:
`evidence/attack-wave/T1/T1_Portal_04_05_06.out.txt`. Score <= 0.
