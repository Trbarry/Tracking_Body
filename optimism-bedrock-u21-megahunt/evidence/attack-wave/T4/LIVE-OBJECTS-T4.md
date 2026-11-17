# LIVE-OBJECTS-T4 — production objects matching the T4 preconditions (passive reads, 2026-11-17)

| chain | object | read | why it matters |
|---|---|---|---|
| OP (L1) | game 21377 `0x675e956b1912df79108408ca524fb37810500d10` (type 9, old prestate) | `status()`=0 IN_PROGRESS, `l2SequenceNumber()`=1794868743, `startingSequenceNumber()`=1794262423, `rootClaim()`=0x3c35e311…ffda7 | the L2 range a disputed step would run with kona v1.7.0; its claim recomputed from the L2 header by kona v1.7.0/v1.9.0/op-node |
| OP (L1) | game 21308 `0x5d62795e45fca7bdf9c20a26464e1bb4b4f369ed` | `status()`=2 DEFENDER_WINS, l2Seq 1794620587, start 1794012829 | oldest old-prestate game of the census, now resolved |
| OP (L1) | games `0x2f55f48e…86fd`, `0x42d0c7b4…cb` | rootClaim recomputed equal | additional claim checks |
| OP (L2) | blocks 159,634,384–159,634,983 and 159,331,824–159,332,223 | 1,000 blocks, all derived identically by both kona versions and op-node, equal to the canonical block | inside game 21377's disputed range |
| L1 | OptimismPortal2 (OP) deposit logs, L1 26,380,000–26,430,700 | 1,669 TransactionDeposited logs in 1,609 L1 blocks, max 4 per block (`deposit-scan-26380000-26430700.json`) | the only user-constructible derivation input; 23 heaviest epochs derived |
| OP (L2) | 53 user deposits in the sampled epochs | all from one aliased sender 0x36bde71c…70b2 (alias of L1 0x25ace71c…5fa1, version 2.13.0); 3 with mint/value > 0; 0 creations; max 516 data bytes | real deposits are narrow; the field space is covered synthetically |

No production object matches any divergence precondition (malformed deposit log, mint ≥ 2^128, padded version-0
scalar, blob base fee ≥ 2^128, pre-Cancun header with blob fields): such objects cannot be produced.
