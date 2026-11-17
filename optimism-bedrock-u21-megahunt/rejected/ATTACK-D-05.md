# ATTACK-D-05 — Compose with the planned OP+Unichain shared migration (FUTURE-ONLY)

Verdict: **KILLED (future-only, no new mechanism; −5).**
After `migrate` both portals read one shared factory with two-chain super roots. A trojan is then a well-formed 2-chain
root that has a correct chain-10 (or 130) entry and a wrong other entry, or a duplicate. This is the same first-match consumption
(`SuperFaultDisputeGame.sol:809-819`, `OptimismPortal2.sol:441-450`) and the same "victim re-proves" impact. It is in fact
the CC25 3.1.6 framing ("a multi-chain super root is invalid because of another chain"). Pending proofs die at migrate
anyway (C10, `InvalidRootClaim`; KNOWN U21 3.2.1). No irreversible pre-positioning exists: games and proofs made before
migrate are not consumable by the new factory (C10/D14, `test/poc/lane09/`). Not executed beyond the cited migration fixtures.
