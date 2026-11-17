# ATTACK-CATK-E-05 — balance, sticky-authorization, or future-address poisoning

## Hypothesis

Deposits/donations/forced ETH, sticky authorization on retired lockboxes, or pre-funding the three
future proxy addresses can make migration insolvent, block CREATE2, or grant an attacker a pooled
liquidity capability.

## Exact sequence tried

- Deposit, donate, and force ETH into both portals and both current lockboxes, then migrate.
- From the attacker, call retired `lockETH`, shared `receiveLiquidity`, and retired
  `migrateLiquidity` after migration.
- Donate to retired/shared custody after migration.
- Dry-run the timestamp-specific proxy addresses, revert the snapshot, pre-fund all three empty
  addresses, and rerun the exact migration at the same timestamp.

## Deterministic barrier

E06 pools exactly `200810526200523469952700` wei and zeroes both old lockboxes/portals. Sticky old
lockbox authorization is an entry in the *new* receiver, not permission for an EOA: lock/receive
check authorized caller mappings (`ETHLockbox.sol:133-147`), and migration is ProxyAdmin-owner-only
(`ETHLockbox.sol:203-208`). Later attacker donations only add assets.

An address with balance but no code/nonce remains CREATE2-deployable. E08 deploys all three proxies
at the predicted addresses; the only deltas are donated surplus/trapped attacker ETH, and the shared
ASR still has the governance root.

Evidence: `test_E06_depositDonateForceETH_conservedAndUnauthorized` and
`test_E08_prefundFutureProxyAddresses_noCollisionOrUnsafeRoot`.

## Disposition and honest score

Rejected. No assets are removed and no caller capability is acquired. Score:
`+8 -5 future-only -3 no eligible impact -4 known sticky-authorization/donation class = -4`.

