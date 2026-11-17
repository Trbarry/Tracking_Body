# ATTACK-CATK-T3-04 — Active ERC20 pair can release more than its exact-pair deposits

Model: Codex, configured by the worker brief as `gpt-daybreak-blue-latest`.

Verdict: **KILLED — event ledger equals storage; supply is below escrow.**

## Hypothesis

Legacy/new event paths or a remote-token alias cause `deposits[l1][l2]` to diverge from real outstanding L2 supply,
allowing a high-activity pair to withdraw beyond deposits or debit a sibling pair.

## Exact sequence tried

Rank OP pairs by deposit/withdrawal event count. For the top 11, aggregate event amounts through L1 block 26,433,900,
read the exact mapping on the pinned L1 fork, and read linked L2 `totalSupply` at OP block 159,654,093. Separately,
deposit one locally created non-mintable token against two remote addresses through deployed L1StandardBridge and try an
unprivileged finalize.

## Barrier

For all 11 pairs, `sum(deposits)-sum(finalized withdrawals) == deposits(l1,l2)` exactly. Every L2 supply is below, not
above, escrow. The fork test increments two independent mapping cells; the unauthenticated finalize reverts without
changing either. Current finalization subtracts the exact pair with Solidity checked arithmetic before transfer
(`StandardBridge.sol:281-293`).

## Evidence

- `mirror/CATK-T3/evidence/top-pair-census.md` (11/11 exact; 0 excess-supply pair).
- PASS: `test_nonMintableAccounting_isIsolatedByExactRemoteAddress`.
- The existing full-population T2 closure (324 pairs, zero ledger mismatch) was not rerun.
