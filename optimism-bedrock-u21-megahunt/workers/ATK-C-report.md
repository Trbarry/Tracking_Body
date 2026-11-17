# ATK-C report — EIP-7825 gas cap x cross-layer relay budget (permanent undeliverability)

Model: **Opus 5.5** (`claude-opus-5-5`), per the user-approved exception in `/home/user/Tracking_Body/CLAUDE.md`
(Mythos 5.2 quota exhausted until 2026-11-22 00:00 UTC).

**Outcome: 0 candidates, 9 deterministic kills (ATTACK-C-01..09).**

Harness: private anvil :19030 (L1 forked @26433900, osaka), real `eth_sendTransaction`s from a fresh
unprivileged EOA against deployed portal 6.1.0 / L1CDM 2.13.0 / L1SB 2.8.2 / ETHLockbox; the proof step is
replaced by `anvil_setStorageAt` of `provenWithdrawals` (stated vehicle; slot 57 verified against a real proof).
Binary search on the **tx gas limit** (128-gas precision); feasibility = min gas limit <= 16,777,216. Edges also
confirmed with txs at exactly 2^24. Code and the exact command: `test/poc/attack-wave/C/README.md`.
Raw outputs: `evidence/attack-wave/C/{results.jsonl,edge-at-cap.jsonl,l2-acceptance.txt,*scan*.json}`.

## Symbolic budget (file:line in README)

`B = 21000 + max(285000 + ⌊64m/63⌋ + 16(L+260), 40(L+260))` (live L2CDM 2.2.1) →
portal `63·gas ≥ 64·B + 63·(40000+N)` (N = 183,600 only for plain value withdrawals to codehash 0) →
L1CDM `63·gas ≥ 64·m + 63·190000` else `failedMessages` → replay (any EOA, msg.value 0) same check with one
fewer 64/63 frame. Measured fits: finalize-min = 518,843 + 1.04838·m; one-tx relay slope 1.06503;
large payload ~65.6 gas/byte.

## Experiments

| id | hypothesis | command / case | result | verdict |
|---|---|---|---|---|
| X1 | full Bedrock-era OP withdrawal population near the edge | `scan_messagepassed.py` | 35,579 = messageNonce delta (complete); max gasLimit 8,415,632, max data 644 B | input to kills |
| X2 | legacy v0 migrated withdrawals near the edge | `scan_legacy_sentmessage.py` | 39,885 logs; max msg 356 B → gasLimit ≈1.31M; 100k pre-regenesis nonces have no logs (residual) | ATTACK-C-07 |
| X3 | real unproven objects m=8M: never-proven status | L1 `eth_getLogs` by hash | 4 never proven, 1 reference finalized | LIVE-OBJECTS-C |
| E1 ×6 | live budget, empty msg, m ∈ {0,7M,8M,15M,15.8M,16M} | `run_all.py E1` | 518,843 / 7,857,518 relayed; 8M: 8,905,922 failed, replay 8,540,027; 15M: 16,244,598 failed, relay 16,372,478, replay 15,764,039; 15.8M: 17,083,307 (> cap); 16M: 17,292,927 | C-01, C-02 |
| EDGE ×5 | txs at exactly 2^24, m ∈ {15.37M,15.39M,15.50M,15.51M,15.52M} | `edge_at_cap.py` | relayed / failed+replay OK / failed+replay OK / REVERT / REVERT | C-02, C-08 |
| E2 | REAL withdrawal `0x0adc…0dbe` (L1SB ERC20, m=8M) | `run_all.py E2_live` | finalize min 8,886,768 failed; relay 8,921,191; replay 8,543,146 | C-03 |
| E3 ×2 | messenger 1 ETH to new account, m=0 / 15.8M | `run_all.py E3` | 537,760 relayed; 17,102,209 (no 183.6k term) | C-05 |
| E4 ×4 | plain 1 ETH new vs 1-wei pre-funded, gasLimit 0 / 16.2M | `run_all.py E4` | 401,924 vs 215,460; 17,120,407 vs 16,933,882 (+186.5k, removable by anyone) | C-05 |
| E5 ×3 | payload 250 KB / 320 KB nonzero, 400 KB zero, m=0 | `run_all.py E5` | 15,855,984 fits; 20,446,910 and 21,009,847 do not; edge ≈264 KB | C-04 |
| E6 ×2 | gas-burning target m=8M / 15.8M | `run_all.py E6` | forced `failedMessages`, never relays; finalize-min identical to empty target | C-06 |
| L2 ×6 | L2 accepts the probed messages | `l2_accept.py` | m=16M: 86,388 gas; m=4e9: 86,400; 350 KB: 19.3M; 400 KB zero: 18.0M (< 40M block) | C-02, C-04 |
| T | third-party lever into the band | source + E1/E4/C-01 | gasLimit/m/data are hash-committed; gas is a floor; target state can only lower N | C-09 |

## Bands classified

| band | status | who chooses | verdict |
|---|---|---|---|
| m ≳ 15.51M (gasLimit ≳ 16.06M) | live: never deliverable while EIP-7825 holds | sender | self-inflicted; known Low "gas ceiling of withdrawals" |
| m ≈ 15.38M–15.51M | one-tx relay impossible; finalize-as-failed + replay both ≤ 2^24 | sender | retryable inconvenience |
| payload ≳ 264 KB nonzero | live, never deliverable | sender | known excluded "large-calldata" class |
| plain value withdrawal to a fresh account, gasLimit ≈15.87M–16.05M | needs a 1-wei pre-fund first | anyone can fix | not stranded |
| forced fail (m ≥ 7.3M live / 5.76M Bedrock-era) | replay is always ≥343k cheaper than the forcing tx | third party | known replayable griefing |

No live object in any band: the highest gasLimit ever is 52% of the edge.

## Single highest-value next experiment

Run the same `MessagePassed` scan on Ink, Soneium and Unichain (no local L2 archive for them). Then, for any
withdrawal with gasLimit > 15.38M or data > 250 KB, run `run_all.py`-style finalize+replay on its real struct
on :19030. A hit would still be self-inflicted (score < 7), so this is a completeness check, not a lead.
