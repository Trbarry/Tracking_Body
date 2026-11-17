# ATTACK-D-03 — Wrong-root newest game as a tooling DoS (no trojan needed)

Verdict: **KILLED (no on-chain effect, no eligible impact).**
Hypothesis: a newest game with a WRONG chain-10 root (cheapest form) is picked by viem (`getGame.ts:92-103`, no root
check; `buildProveWithdrawal.ts:153` uses `game.index`), so users' prove txs revert; op-node errors ("output root mismatch",
`op-node/withdrawals/utils.go:169`) instead of skipping to an older game.
Evidence: `test_negative_controls` — viem pool returns the bad game; `proveWithdrawalTransaction` reverts
`OptimismPortal_InvalidOutputRootProof`; the op-node selector reverts "output root mismatch".
Barrier: nothing is written on-chain; the user loses prove gas and retries with another index. Off-chain third-party
SDK behaviour → Web/App or SDK issue outside the listed impacts; at most "DoS of tooling".
