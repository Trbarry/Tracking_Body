# REJ-CF2-01 — A tracked chain took direct U15→U16a and reached U21 without prior lockbox custody

## Hypothesis

Because U16a supports both U16→U16a (retain ETHLockbox) and direct U15→U16a (no ETHLockbox), one of OP/Ink/Soneium/Unichain might have converged to the same later code while retaining Portal custody. U21's forced lockbox transition could then expose an untested liquidity/pause branch.

## Falsification

- OP and Ink executed U16 at L1 block 22,990,599; Soneium at 22,990,670; Unichain at 22,990,722.
- They then executed U16a at 23,491,328 / 23,492,571 and all later upgrades.
- Each Portal/SystemConfig history contains the U16 implementation step before U16a (`impl-history-*.json`).
- The U21 task explicitly records that all four already had an ETHLockbox wired to their Portal, so no ETH moved (`superchain-ops/src/tasks/eth/084-U21-op-ink-soneium-uni/README.md:33-35`).
- `CF2-DAG-INTEGRITY` validates all receipts against the passive L1/L2 endpoints.

## Disposition

Rejected for the four target chains. The primitive remains relevant to other chains that took the documented direct U15→U16a branch.
