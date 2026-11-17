# ATTACK-D-02 — Overwrite / poison a relayer's good proof with a trojan proof

Verdict: **KILLED (invariant barrier, executed).**
Hypothesis: the attacker proves the same withdrawal against the trojan so that the auto-prover's (0x431f…ddf5) good
proof is replaced or becomes deletable.
Barrier: proofs are keyed by `msg.sender`: `provenWithdrawals[withdrawalHash][msg.sender] = …`
(`op-v9.0.0 src/L1/OptimismPortal2.sol:483-484`). `deleteProvenWithdrawal` requires the stored game to be
CHALLENGER_WINS or blacklisted (C4).
Evidence: `test_trojan_vs_default_tooling_end_to_end` — after 3 trojan proofs of the same hashes, `provenWithdrawals(h, 0x431f…)`
still returns game 21314 and `deleteProvenWithdrawal(h, 0x431f…)` reverts `OptimismPortal_DisputeGameNotInvalidated` for all 3.
The relayer can only be affected if its OWN selector picks the trojan (it picks lag 0/1 games: 96/39 of 135 proofs). That
case is ATTACK-D-01 (re-provable delay, known).
