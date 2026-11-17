# ATTACK-A-02 — OLD prestate replaces a block by a deposit-only block on ANY executor error

Lane ATK-A. Model: Opus 5.5 (user-approved exception).

**Hypothesis.** At v1.7.0 `rust/kona/crates/proof/driver/src/core.rs` (Holocene branch) retries every
`execute_payload` error as a deposit-only block. v1.9.0 (PR #23012, commit `c368ce97`) does so only when
`ExecutorError::is_invalid_payload()` (`rust/kona/crates/proof/executor/src/errors.rs`). If an L2 user or an L1
depositor can make the executor return a NON-payload error (DB/provider/internal/EVM custom) on a block that op-geth or
op-reth executes fine, the old program outputs a deposit-only block, so an invalid root wins or an honest root loses.

**Exact search.** Every producer of a non-payload error on the v1.7.0 FPVM execution path:
- Precompiles: `kona/bin/client/src/fpvm_evm/precompiles/provider.rs:118-129` (v1.7.0) returns `Err` only for
  `PrecompileError::Fatal/FatalAny` of NON-accelerated precompiles. revm-precompile 41.0.0 has no producer of
  `Fatal` (grep: only the type definition, `src/interface.rs:529-557`). Accelerated precompiles return an
  `EthPrecompileResult`, so a host failure or bad input is an ordinary precompile failure, the same in both versions.
- EVM `Database` / `IncrementBalanceFailed` / `LoadCacheAccount` / `TrieDBError`: come only from the
  oracle-backed TrieDB. Preimages are content-addressed, and a step needs the preimage in the on-chain
  PreimageOracle, so a valid trace cannot observe a missing or wrong node. The error cannot be reached from transaction
  contents.
- `MissingGasLimit/MissingTransactions/MissingEIP1559Params/MissingParentBeaconBlockRoot/InvalidExtraData`: built by the
  program's own derivation, deterministic and not attacker-selected.
- `EVMError::Custom` from op-revm or alloy-op-evm: only forwarded (`alloy-op-evm/src/error.rs:39-40`), with no
  producer on the deposit or user path.

**Barrier.** No unprivileged input reaches a non-payload error, so the fallback difference never triggers. A kona-mpt
or TrieDB bug that rejected a valid state would be a separate root cause, present unchanged in BOTH programs
(`rust/kona/crates/proof/mpt` is untouched between the tags), and would make v1.9.0 fail as well.

**Verdict.** KILL (unreachable precondition; witness not executed, because the precondition has no producer).
