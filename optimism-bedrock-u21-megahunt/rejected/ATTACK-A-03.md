# ATTACK-A-03 — EVM-stack delta (revm 41 -> 43, op-revm handler rewrite, deposit EIP-7825 exemption moved, FpvmOpTx)

Lane ATK-A. Model: Opus 5.5 (user-approved exception).

**Hypothesis.** Between kona-client/v1.7.0 and v1.9.0 the FPVM EVM changed: revm 41.0.0 -> 43.0.x (Cargo.lock),
op-revm `handler.rs` `last_frame_result`/`tx_gas`/`refund` rewritten (PRs #22993, #22495, #23046), the deposit
exemption from the 2^24 tx gas cap moved from `alloy-op-evm OpEvm::transact_raw` to `OpHandler::tx_gas` (commit
`bf4fc514`), and `FpvmOpTx` gained `effective_gas_price` delegation (commit `1e5b69c7`). Under the ACTIVE spec (OP
Karst = Osaka, no EIP-8037) any difference in status, gas, refund, logs or state lets a user tx or deposit make the two
programs disagree, and one of them disagrees with the canonical chain.

**Executed experiment.** `test/poc/attack-wave/A/revm-diff/` builds the same harness against op-revm at each tag, each
with the tag's own `Cargo.lock` (revm-handler 41.0.0 vs 43.0.2). It runs a randomised `OpSpecId::KARST` corpus:
CALL/CALLCODE/DELEGATECALL/STATICCALL with value and gas variants, CREATE/CREATE2 with reverting, invalid,
selfdestructing and 0xEF init code, SSTORE/TSTORE refunds, memory OOG, LOG, EXT*, MCOPY, SELFDESTRUCT, an EIP-7702
delegated target, all precompiles including P256, legacy and 1559 txs, deposits with mint, failing deposits, and
deposits above the cap. It compares status, tx gas used, final refund, floor gas, logs hash, output hash, created
address and a full post-state digest.
- With the v1.7.0 production path mirrored (`MIRROR_TRANSACT_RAW=1`, the exact `transact_raw` cap lift at
  `alloy-op-evm/src/lib.rs:344-370` @v1.7.0; FPVM uses `OpEvm` per `kona/bin/client/src/fpvm_evm/factory.rs:92-93`):
  **10 seeds x 20,000 cases = 200,000 cases, 0 divergences** (`evidence/attack-wave/A/revmdiff-mirror-summary.txt`).
  Coverage per 20k cases: about 40k txs, 15.9k success, 7.3k halt, 0.7k revert, 7.5k FailedDeposit, 1.5k creates,
  482 deposits above 2^24 gas. Halt reasons byte-identical.
- Negative control (detection power): without the mirror, 3/3000 cases differ, all deposits with gasLimit 2e7 > 2^24
  (`revmdiff-NOMIRROR-negctrl.diff`). That is the relocated exemption, and it confirms the harness sees a real
  consensus delta.
- `effective_gas_price`: the revm-context-interface 41.0.0 default (`src/transaction.rs:147-160`) returns
  `gas_price()` (0 for deposits) for every input where the op-revm override applies. Identical.
- Interpreter deltas (revm-interpreter 41 -> 43.0.1): Amsterdam-gated (EIP-8037/8038), or SSTORE `skip_cold_load`
  2000 -> 2100, which can never bind because the EIP-2200 sentry requires gas > 2300 first. Memory resize failure:
  halt either way.

**Barrier.** Executed differential equivalence on the active spec. Limits: no access-list or authorization-list txs
are generated, and the alloy-op-evm block executor is not in the loop (its non-Lagoon delta is only
`validate_post_exec_entry_count`, see ATTACK-A-05).

**Verdict.** KILL.
