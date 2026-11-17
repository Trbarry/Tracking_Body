# ATTACK-CATK-CMP1-01 — Forced failed application replay gains a time-based theft window

Families: historical proof/game + messenger replay + third-party target time. Score: **4.0/10**.

The local fork used a genuine proven withdrawal of `363.438235322873695226 ETH` to the deployed
EtherFi receiver. An unrelated caller finalized it while messenger reentrancy was occupied, leaving
the immutable message failed and its ETH in L1CDM. After a ten-year warp the same unrelated caller
replayed it successfully.

Kill barrier: the target and pool have no deadline or age-dependent branch. Replay commits the
original sender, target, value, and calldata; the pool validates `amountIn == msg.value` and processes
the original deposit. The replay caller received zero. This demonstrates liveness, not theft or an
eligible loss.

Evidence: `mirror/CATK-CMP1/test/CATK_CMP1.t.sol` C01 and
`mirror/CATK-CMP1/evidence/fork-test-output.txt`.
