# ATTACK-C-02 — Non-empty "never deliverable" band by minGasLimit under EIP-7825 (live L2CDM 2.2.1 budget)

Model: Opus 5.5. Lane ATK-C.

**Hypothesis.** A normal L2 sender can create a messenger withdrawal that no L1 transaction <= 2^24 can ever
finalize or replay.

**Measured edges** (real txs at exactly `gas = 16,777,216`, `evidence/attack-wave/C/edge-at-cap.jsonl`; empty
message, value 0, deployed portal 6.1.0 + L1CDM 2.13.0, gasLimit = live L2CDM 2.2.1 `baseGas` on `:9545`):

| minGasLimit | withdrawal gasLimit | finalize at 2^24 | replay at 2^24 after that |
|---|---|---|---|
| 15,370,000 | 15,924,128 | RELAYED | — |
| 15,390,000 | 15,944,445 | finalized + `failedMessages` | RELAYED |
| 15,500,000 | 16,056,191 | finalized + `failedMessages` | RELAYED |
| 15,510,000 | 16,066,350 | REVERT (`SafeCall: Not enough gas`, stays unfinalized) | unreachable |
| 15,520,000 | 16,076,509 | REVERT | unreachable |

Fits from the battery (`results.jsonl`, E1): finalize-min(m) = 518,843 + 1.04838·m (three 64/63 factors:
portal Proxy delegatecall, `hasMinGas` on gasLimit, gasLimit = 64m/63 + …); single-tx relay slope 1.06503.
So: m <= ~15.38M deliverable in one tx; ~15.38M..~15.51M deliverable only as finalize-as-failed + replay (both
permissionless, each <= 2^24); m >= ~15.51M (gasLimit >= ~16.06M) **never deliverable while EIP-7825 holds**.
For the Bedrock-era budget the edge is the same in gasLimit terms (~16.06M).

L2 acceptance: `L2CDM.sendMessage(target, "", 16,000,000)` costs 86,388 L2 gas; m = 4e9 costs 86,400
(`evidence/attack-wave/C/l2-acceptance.txt`). Nothing on L2 bounds m (uint32).

**Classification.** Non-empty, live today, but SELF-INFLICTED: m is chosen by the sender and committed in the
message hash; no third-party lever (ATTACK-C-09). Same root cause and impact as the KNOWN U21 audit Low
"gas ceiling of withdrawals" and the suppressed class "specific-gas message griefing". Funds stay in the lockbox
(not lost to anyone else); a future L1 fork raising the cap would make them deliverable.
**Live objects:** none — the highest gasLimit of all 35,579 OP Mainnet withdrawals ever is 8,415,632
(`LIVE-OBJECTS-C.md`), < 52% of the edge. Score: permissionless 0 (sender-only) — < 7. KILLED.
