# ATTACK-CATK-CMP1-12 — Trojan newest game permanently poisons automatic prover withdrawals

Families: trojan game + automatic prover + proof-submit identity. Score: **2.0/10**.

The live surface is real: type 9 is permissionless and recent proof submitters frequently choose the
newest games. But portal proofs are keyed by `(withdrawalHash, msg.sender)`. A trojan-selected proof
cannot overwrite a different submitter's good proof, and a blacklisted/challenger-wins proof is
permissionlessly deletable and replaceable.

Kill barrier: tooling may waste gas or delay its own submission, but it does not write a global
poison bit. C05 additionally proves that once portal finalization has parked a message, later game
blacklisting and proof deletion cannot reach messenger replay. No eligible theft or permanent freeze
was composed.

Evidence: C05; `OptimismPortal2.sol:481-487,671-727`.
