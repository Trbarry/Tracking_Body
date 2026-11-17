# ATTACK-C-07 — Older budget generations (Bedrock-era formula, version-0 migrated legacy withdrawals) cross the 2^24 edge

Model: Opus 5.5. Lane ATK-C.

**Hypothesis.** In-flight withdrawals whose gasLimit was produced by an older formula sit above the cap edge
(gasLimit >= ~16.06M, ATTACK-C-02) and became undeliverable when EIP-7825 activated (pre-positioned objects).

**Formulas.** Bedrock-era: `285,000 + 16L + ⌊64m/63⌋` (verified on 4 real structs). Version-0 migrated:
`min(25e6, 16·len(relayMessage calldata) + 1,300,873)`, m = 0
(`ext-codex/sherlock-fault-proofs-CF3/optimism/op-chain-ops/crossdomain/migrate.go:77-121`); the 25M cap means only
data > ~1.48 MB would even reach it; edge crossing needs data > ~0.93 MB.

**Population scans executed (complete).**
- All 35,579 Bedrock-era OP Mainnet `MessagePassed` events (count == `messageNonce` delta between L2 105,235,063 and
  159,654,093): max gasLimit 8,415,632, max data 644 B (`evidence/attack-wave/C/messagepassed-scan-op.json`).
- All 39,885 legacy OVM-2 `SentMessage` logs (L2 0..105,235,062): largest message 356 B -> migrated gasLimit ~1.31M
  (`legacy-sentmessage-scan-op.json`). Residual: legacy `messageNonce` is 139,885; the 100,000 offset predates the
  Nov-2021 regenesis and has no logs on this chain — not scanned (OVM-1 messages; their bound is the same formula,
  and OVM-1 per-tx gas limits (~11M) make a > 0.93 MB message implausible, not proven).

**Barrier.** No existing object within 2x of the edge on OP Mainnet. Ink/Soneium/Unichain were born on Bedrock-era
contracts with the same formulas; not scanned (lower priority: the edge is formula-determined, sender-chosen).
KILLED (OP Mainnet, deterministic scan).
