# ATTACK-T1-06 — Block-number challenge is the only anchor sanity check; absent on the live game types

Lane ATK-T1, Opus 5.5. Target 6 (row 12). Kill type: failing experiment + known issue + fault-proof precondition.

**Original condition.** Sherlock FP M-2: `challengeRootL2Block` (v9 `FaultDisputeGame.sol:655-691`) bounds the claimed L2 block of
output-root games. Absent on super games (U21 3.2.11), unpermissioned on the permissioned game (U19 3.2.10), callable between
`resolveClaim` and `resolve` (Spearbit 5.2.2). No output-root type is registered on any chain (T1-01: live types 5 and 9 only).

**Sequence executed** (`T1_Extra.t.sol::test_T1_11_farFutureSuperGameNoBlockCheck`, L1 @ 26433900):
1. `challengeRootL2Block(…)` on the live anchor game of each chain (types 9/9/5/9): reverts with empty data (no such function).
2. Unprivileged attacker creates an OP type-9 game with `l2SequenceNumber = 2^64-1` (bond 0.08 ETH): accepted (no on-chain bound).
3. Unprivileged honest challenger attacks the root (bond `getRequiredBond(2)`), clocks expire, `resolveClaim(1)`, `resolveClaim(0)`,
   `resolve()` -> CHALLENGER_WINS; after the finality delay `setAnchorState(game)` reverts `AnchorStateRegistry_InvalidAnchorGame`;
   `closeGame()`; anchor unchanged.

**Barrier.** The far-future super root can only move the anchor if it resolves DEFENDER_WINS, i.e. if the standard counter is
absent for the whole clock (incorrectly resolved game: a fault-proof liveness/soundness failure, not this root cause), and the
missing bound itself is acknowledged (U21 3.2.11; SFP M-2; KNOWN Part 1 §4 and Part 2 #5) -> -4. On Soneium type 5 only the
proposer key can create games (ATTACK-T1-11). Output: `evidence/attack-wave/T1/T1_Extra_11_12_13.out.txt`. Score <= 0.
