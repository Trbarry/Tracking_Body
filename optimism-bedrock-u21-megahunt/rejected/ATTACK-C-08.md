# ATTACK-C-08 — Band where one-tx delivery is impossible under the cap (finalize-as-failed + replay is the only path)

Model: Opus 5.5. Lane ATK-C.

**Measured at exactly 2^24** (`evidence/attack-wave/C/edge-at-cap.jsonl`): m=15,390,000 and 15,500,000 —
finalize at 16,777,216 gas = finalized + `failedMessages`; replay at 16,777,216 = RELAYED (gasUsed 117,205).
m=15,370,000 relays in one tx; m>=15,510,000 reverts.

**Why it exists.** Single-tx relay slope 1.06503/gas-of-m vs non-revert slope 1.04838: the L1CDM v9 150k check sits
behind one more 64/63 factor than the portal's check, so for m in ~(15.38M, 15.51M) every finalize under the cap
lands in `failedMessages`.

**Barrier.** Not a loss: both steps are permissionless and each fits 2^24; the message is delivered with all value
(replay from L1CDM's balance). Sender-chosen m. KILLED (retryable inconvenience only, -3).
