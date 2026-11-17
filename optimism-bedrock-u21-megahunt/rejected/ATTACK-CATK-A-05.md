# ATTACK-CATK-A-05 — deposit EIP-7825 gas-cap divergence

## Hypothesis

A deposit above the live `2^24` transaction gas cap might execute under v1.9 but be rejected by
v1.7, forcing a different derived root in a live old-prestate game.

## Exact sequence tried

1. Compared the two tagged execution paths.
2. Passively scanned `TransactionDeposited` logs from 24 hours before each contested game's anchor
   through its pinned L1 head.
3. Decoded every opaque deposit gas limit: Ink game 2638 had 379 deposits, maximum 516,470;
   Unichain game 17586 had 403, maximum 3,395,155; none exceeded `16,777,216`.

## Barrier

The premise is false: v1.7 already lifts the cap for deposits in
`alloy-op-evm/src/lib.rs:344-369`. v1.9 merely relocates the same rule to
`op-revm/src/handler.rs:202-221`. The range scan independently found no trigger anyway.

## Verdict

Rejected as semantic equivalence plus absent fixed-input trigger. Exploitability: 0/10.

