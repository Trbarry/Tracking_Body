# ATTACK-T5-03 — an L1 payout without a matching L2 burn / custody outflow not explained by a finalized withdrawal (KILLED)

**Hypothesis.** Some ETH left OP custody (portal pre-U16, lockbox post-U16) that does not correspond to a finalized
withdrawal of ETH that was removed from L2 circulation.

**Sequence executed.** Ledger predicted(b) = 293,288.256836 + Σmint(≤b) − Σ value of success finalizations(≤b) versus
`eth_getBalance(portal)+eth_getBalance(lockbox)` at 20 L1 blocks; value of every finalized hash from L2 `MessagePassed`
or the recomputed v0 migrated withdrawal (T2 census); passer inflow vs burns + balance on L2.

**Barrier.** Residual 0 wei at every checkpoint (incl. 22,500,000 → 23,000,000 across the U16 `migrateLiquidity`
sweep): no unexplained outflow and no donation ever reached the OP portal/lockbox after Bedrock. 26,000/26,000 finalized
hashes are L2-initiated objects (0 unknown, 0 duplicates); L2ToL1MessagePasser balance + Σburn == Σ initiated (0 wei).
Double payment is separately closed (C5, ATTACK-T2-01).

**Evidence.** `reconcile.json` (checkpoints), `finalized-join.json`, `finalized-paid-by-block.json.gz`, `l2-passer-burns.json`.
