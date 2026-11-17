# ATTACK-T5-05 — Ink / Soneium / Unichain lockbox below its chain's L2 ETH liability before pooling (lead L9) (KILLED to the L1-only bound)

**Hypothesis.** A chain that U21's planned migrate will pool (Unichain with OP) has its own deficit, so pooling would make
another chain's users pay for it.

**Sequence executed (L1 only, no L2 RPC for these chains).** Per portal: all `TransactionDeposited` (Unichain 53,801,
Ink 36,220, Soneium 80,288); all `WithdrawalFinalized` (3,508 / 919 / 1,580) with the withdrawal value recovered from
the finalize calldata by locating the ABI tuple whose keccak equals the event hash (1 Soneium wrapper tx via its
receipt's `ETHUnlocked`); lockbox `ETHUnlocked` sums; balances at 14-15 checkpoints; genesis allocation from the
superchain-registry genesis files (local `ext/superchain-registry`, dictionary-zstd).

**Barrier.** Custody ledger Σmint − Σpaid == portal+lockbox balance, 0 wei residual at every checkpoint for all three;
lockbox-era Σ`ETHUnlocked` == Σ decoded values (0 wei). L1-only liability upper bound = G + Σmint − Σfinalized values
(pending withdrawals cancel), G = 256 wei (1 wei on each precompile 0x00..0xff) on each chain, so margin = **−256 wei**,
i.e. exactly the precompile genesis dust, which no account can withdraw (precompiles cannot initiate a withdrawal).
Accounting note, not an exploit: no attacker, no eligible impact.

**What is missing.** L2 RPC for chains 130/57073/1868: L2-side Σ`MessagePassed` (to confirm each finalized value was
burned on L2 — today this rests on proof validity, F5/C15), L2 SELFDESTRUCT burns (would only increase the margin).

**Evidence.** `{uni,ink,soneium}-reconcile.json`, `*-finalized-values.json`, `*-portal-deposits.json.gz`,
`*-custody-checkpoints.txt`; scripts `l1only_values.py`, `l1only_reconcile.py`.
