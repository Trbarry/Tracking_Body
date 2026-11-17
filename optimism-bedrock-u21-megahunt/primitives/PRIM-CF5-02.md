# PRIM-CF5-02 — retired game lineages retain version-specific bond custody

## Primitive

Factory history leaves old ASR and DelayedWETH objects live after the current Portal changes references. Across the four factories, games reference 12 ASRs and 23 DelayedWETHs. At block 26,433,900 the WETH lineages hold OP 20.982782 ETH, Ink 5.790376 ETH, Soneium 0, and Unichain 21.499797 ETH; some legacy v1.0/v1.1 objects are owner-based while current v2.0 objects resolve through chain lockboxes (`mirror/CF5/evidence/historical-game-objects.json`).

## Security relevance

Old games still use their embedded WETH for credit/refund settlement. This makes credit ownership, delay, pause routing, and withdrawal semantics a cumulative state machine rather than a current-proxy-only property.

## Falsification so far

Every retained balance observed is consistent with game bonds/refund credits. No tested path mutates another game's credit or withdraws another claimant's balance; there is no Portal/L1XDM/bridge residue. Retain for cross-version credit testing, not as a candidate.
