# ATTACK-C-03 — Real in-flight OP Mainnet withdrawals with minGasLimit 8,000,000 are stranded or third-party-strandable

Model: Opus 5.5. Lane ATK-C.

**Objects.** Four never-proven OP Mainnet L2StandardBridge ERC20 withdrawals (OS token, 26.5 OS each),
L2 blocks 113,711,749..803, minGasLimit 8,000,000, Bedrock-era budget gasLimit 8,415,632
(`evidence/attack-wave/C/live-objects-8M.json`, `LIVE-OBJECTS-C.md`). They sit in the forced-fail band
(m >= 5.76M for this budget generation).

**Sequence executed** on the REAL struct of `0x0adc3473…0dbe` (hash re-derived and asserted), proof step by
`anvil_setStorageAt` (vehicle), then real txs from an unprivileged EOA: finalize at min gas; finalize with enough
gas; forced fail + replay. Deployed portal 6.1.0, L1CDM 2.13.0, L1StandardBridge 2.8.2, real OS token.

**Result** (`results.jsonl`, case `E2_live0`): finalize minimum 8,886,768 -> finalized + `failedMessages`;
single-tx relay from 8,921,191 (tokens delivered via `finalizeBridgeERC20`); after the forced fail, replay by
anyone from 8,543,146. All far below 2^24. The other three objects differ only in nonce (identical shape).

**Barrier.** Deliverable today in one tx at <= 8.93M gas; the only third-party effect is the known replayable
forced fail (ATTACK-C-01). Why they were never proven is off-chain (user/UI); no contract barrier. KILLED.
