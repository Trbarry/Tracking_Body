# ATTACK-C-01 — Third party forces a victim's messenger withdrawal to `failedMessages`, replay then needs more than the 2^24 cap

Model: Opus 5.5 (CLAUDE.md exception). Lane ATK-C.

**Hypothesis.** Attacker proves (own submitter slot) and finalizes a victim's matured L2CDM withdrawal with the
minimum gas the portal accepts, so the v9 L1CDM records `failedMessages` (band m >= ~7.3M live budget,
>= ~5.76M Bedrock-era budget). If the replay `relayMessage` needs more than 16,777,216 gas the victim's
funds are stranded forever.

**Sequence executed** (real txs, private anvil :19030 = L1 @26433900 osaka, deployed portal 6.1.0 / L1CDM 2.13.0;
proof step replaced by `anvil_setStorageAt` of `provenWithdrawals`, stated vehicle):
1. attacker EOA `finalizeWithdrawalTransactionExternalProof(w, attacker)` at the binary-searched minimum gas;
2. check `failedMessages[h]`;
3. any EOA `relayMessage(...)` with msg.value 0, binary-searched minimum gas.

**Result** (`evidence/attack-wave/C/results.jsonl`, 128-gas precision, tx gas limits):

| case | gasLimit | finalize min (outcome) | replay min after forced fail | replay − finalize |
|---|---|---|---|---|
| live budget m=8.0M | 8,437,144 | 8,905,922 (failed) | 8,540,027 | −365,895 |
| live budget m=15.0M | 15,548,255 | 16,244,598 (failed) | 15,764,039 | −480,559 |
| live budget m=15.8M | 16,360,953 | 17,083,307 (failed) | 16,589,594 | −493,713 |
| live budget m=16.0M | 16,564,128 | 17,292,927 (failed) | 16,796,004 | −496,923 |
| REAL OP withdrawal `0x0adc3473…0dbe` (m=8M, L1SB ERC20) | 8,415,632 | 8,886,768 (failed) | 8,543,146 | −343,622 |

**Barrier (deterministic).** Replay is strictly cheaper than the forcing finalize at every m: the replay frame is
tx -> ResolvedDelegateProxy -> impl, the finalize frame is tx -> portal Proxy -> impl -> CALL L1CDM proxy -> impl,
i.e. one extra 64/63 factor on the whole budget plus the portal pre-checks (~150k) and larger calldata
(`src/L1/OptimismPortal2.sol:627`, `src/libraries/SafeCall.sol:103-107`; replay check `src/universal/CrossDomainMessenger.sol:243-247,266`).
The attacker's forcing tx must itself be <= 2^24, so the replay is always <= 2^24 − 343k. The forced fail is the known
replayable griefing class (PRIM-0801 / C7). KILLED.
