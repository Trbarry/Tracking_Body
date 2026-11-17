# PRIM-CF4-03 — Live dispute-game generation pinning

## Primitive

Historical dispute-game clones permanently retain immutable references to distinct
AnchorStateRegistry and DelayedWETH proxy generations, so the live security graph includes old
layouts even after current proxies migrate.

## Locked facts

At Ethereum block 26433900:

- game index 0 / v1.2.0 points to ASR gen0 `0x18dac7...5e443` and WETH gen0
  `0xe497b0...88d14`;
- index 9759 / v1.4.1 points to gen1 `0x1c68ec...04305b` / `0x323dfc...cbdf0`;
- indices 20000 and 21388 point to current `0x23b2c6...fd113` / `0x1b6dbf...b3162`.

Exact `gameAtIndex`, `version`, `anchorStateRegistry`, and `weth` results are in
`mirror/CF4/evidence/game-generation-samples.json`.

## Current reachability

Expected and non-exploitable: the major ASR/DelayedWETH layout reorder is isolated by distinct
proxy addresses, not applied in place.

## Carry-forward edge

Future retirement, claims, bond recovery, validator, and ETHLockbox migration logic must be tested
against all still-live generations, not just current registry/WETH getters.
