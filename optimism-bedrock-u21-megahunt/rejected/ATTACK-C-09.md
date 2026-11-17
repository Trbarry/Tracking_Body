# ATTACK-C-09 — A third party moves a victim's withdrawal INTO the undeliverable band

Model: Opus 5.5. Lane ATK-C.

**Hypothesis.** Some permissionless action raises the L1 gas a victim's existing withdrawal needs above 2^24.

**Levers enumerated and tested.**
1. Gas supplied to finalize/replay (only third-party input on L1): floor semantics, `SafeCall.callWithMinGas` forwards
   `gas()` (`src/libraries/SafeCall.sol:161-162`); more gas never hurts; under-gassing reverts or records a
   replayable failure (ATTACK-C-01 table).
2. `gasLimit` / `minGasLimit` / message bytes: committed in `Hashing.hashWithdrawal` (gasLimit, data) and
   `hashCrossDomainMessageV1` (minGasLimit) — fixed on L2 by the sender (`src/libraries/Hashing.sol`).
3. Target state: the only state-dependent reserve is `NEW_ACCOUNT_STATE_GAS` 183,600 when
   `value != 0 && target.codehash == 0` (`SafeCall.sol:131`), plain withdrawals only. A third party can only move
   codehash from 0 to keccak("") (1-wei transfer), i.e. REMOVE the reserve; post-Cancun SELFDESTRUCT cannot delete a
   pre-existing account, EIP-161 only deletes empty accounts (which already have codehash 0). Measured: E4 rows.
4. Proof step size: the withdrawal storage proof depth is ~log16(#slots) of L2ToL1MessagePasser; the game / super-root
   preimage is chosen by whoever proves (anyone can re-prove under their own submitter slot against any valid game).
5. Forced fail then replay: replay strictly cheaper (ATTACK-C-01).

**Barrier.** No input that a non-sender controls increases the required gas. Every band found (ATTACK-C-02/04)
is fixed at L2 creation by the sender. KILLED.
