# ATTACK-CATK-CMP1-05 — Game invalidation strands finalized failed-message value

Families: proof/game invalidation + messenger replay + custody. Score: **3.0/10**.

After C05 finalized the genuine withdrawal as a failed messenger message, the guardian blacklisted
its real dispute game. An unrelated EOA permissionlessly deleted the selected proof. The proof record
was zeroed, yet direct message replay settled the exact 363.438 ETH to its committed target.

Kill barrier: portal proof and game checks end at finalization. The messenger failed/successful maps
are a separate state machine. Before finalization, invalidation merely requires a valid re-proof;
after finalization it cannot block or redirect replay.

Evidence: C05; `OptimismPortal2.sol:671-727`.
