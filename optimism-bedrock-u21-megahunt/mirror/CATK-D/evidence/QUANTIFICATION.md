# Reach, cost, cadence, and delay

## Honest-game cadence

Passive call:

```bash
cast call 0xe5965Ab5962eDc7477C8520243A95517CD252fA9 \
  'findLatestGames(uint32,uint256,uint256)((uint256,bytes32,uint64,bytes32,bytes)[])' \
  9 21388 100 --rpc-url http://127.0.0.1:8545 --json
```

For the newest 100 type-9 games: creation span 353,052 seconds; 99 intervals; mean 3,566.18 s; median 3,624 s; minimum 1,620 s; maximum 3,636 s. The newest 24 were created by two EOAs: 13 by `0x473300df21D047806A082244b417f96b32f13A33`, 11 by `0xc27ba3E0Fc01567a5E57Ae0c391AA98cECBA5bE0`.

An attacker can vary the noncanonical preimage/root and post multiple distinct games instantly; the factory charges 0.08 ETH each.

## Withdrawal proving population

Passive `WithdrawalProven` scan on the portal from L1 blocks 26,363,900 through 26,433,900:

- wall-clock span: 842,460 seconds = 9.75069 days;
- 487 prove events, 355 distinct withdrawal hashes;
- approximately 49.95 prove events/day and 36.41 distinct withdrawals/day;
- top proof submitter: unattributed EOA `0x431f...ddf5`, 135 events (27.72%).

A selected trojan can bind any number of proofs submitted while it is selectable; the cost is per game, not per victim. It cannot bind an unrelated submitter's slot itself.

## Selection cost

| Consumer | One newly latest trojan | Deterministic capture cost |
|---|---:|---:|
| op-node helper / viem direct default `latest` | Selected until a newer type-9 game appears (observed median about 1 hour) | 0.08 ETH per refresh |
| viem `waitToProve` | `1/N` among eligible games, up to 100 | 100 trojans = 8 ETH for an attacker-only 100-game window |

These bonds are not profit. Real game 21288 shows the root bond is credited to the counterer after challenger win. Critical/High scope impacts expressly exclude proposer/challenger bonds.

## Delay and repeatability

Portal proof maturity is 604,800 s (7 days). Real invalid game 21288 resolved challenger-wins after 302,448 s (about 3.50 days), close to its 302,400 s max-clock value. Deletion is then permissionless, and re-proving resets the seven-day timer.

More importantly, the submitter need not wait: `test_sameSubmitterCanImmediatelyReplaceTrojanProofWithHonestGame` overwrites the trojan slot with an honest game while the trojan is still in progress. Thus the protocol-enforced extra delay is zero once the submitter chooses an honest game; only the newly reset seven-day timer remains. Repetition requires the submitter/tool to select another attacker game again. There is no attacker-only transaction that perpetually freezes the withdrawal.

At the observed real-game timing, a passive user who waits for invalidation before re-proving would finalize about 10.5 days after the first proof rather than 7 days, an approximately 3.5-day inconvenience. This is not a maximum protocol bound and is not an upgrade-required freeze.
