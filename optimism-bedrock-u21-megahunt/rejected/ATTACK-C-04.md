# ATTACK-C-04 — Large-calldata messenger withdrawals that L2 accepts but no L1 tx <= 2^24 can deliver

Model: Opus 5.5. Lane ATK-C.

**Measured** (`evidence/attack-wave/C/results.jsonl` E5; m = 0, live budget, real txs, EIP-7623 floor applied by the node):

| message | gasLimit (L2 floor branch 21000+40(L+260)) | finalize min tx gas | fits 2^24 |
|---|---|---|---|
| 250,000 B nonzero | 10,031,400 | 15,855,984 (relayed) | yes |
| 320,000 B nonzero | 12,831,400 | 20,446,910 | no |
| 400,000 B zero | 16,031,400 | 21,009,847 | no |

Slope ~65.6 gas/byte (calldata 16 + floor-driven gasLimit 40·64/63 + memory) -> edge ~264 KB nonzero.
L2 acceptance (`l2-acceptance.txt`): 350 KB nonzero via calldata = 19.3M L2 gas, 400 KB zero = 18.0M, under the
40M OP block gas limit (a contract building the payload in memory pays less). So the band (~264 KB, L2 max) is
non-empty and live. (Above ~128 KB the L1 tx also exceeds geth's public-mempool size limit; not a protocol rule.)

**Classification.** Self-inflicted: L is chosen by the sender, committed in the hash. Exactly the excluded class
"large-calldata message griefing"; no third-party lever (ATTACK-C-09); no live object (max data ever 644 B,
`LIVE-OBJECTS-C.md`). Replay is not needed (outcome at min is always relayed for m = 0). KILLED.
