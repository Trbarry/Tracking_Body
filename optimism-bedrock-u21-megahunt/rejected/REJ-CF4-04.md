# REJ-CF4-04 — ASR/DelayedWETH inheritance reorder corrupts live old state

## Hypothesis

The v4-era layout reorder applies to an old proxy in place, causing anchors, WETH balances,
withdrawal requests, owner or config state to be reinterpreted.

## Falsification

Production uses separate proxy generations. Live game samples independently return gen0, gen1 or
current ASR/WETH addresses according to their creation era; exact reads are in
`mirror/CF4/evidence/game-generation-samples.json`. Old games continue against old-layout proxies;
current games use the new proxies.

## Verdict

Rejected for OP Mainnet. Generation graph remains a future compatibility primitive.
