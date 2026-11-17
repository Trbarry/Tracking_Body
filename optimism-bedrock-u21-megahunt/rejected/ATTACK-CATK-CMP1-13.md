# ATTACK-CATK-CMP1-13 — Old-prestate game plus migration yields a false claim-valid root

Families: old historical game + chain/root identity + proof/migration. Score: **4.5/10**.

The temporary surface is genuine. The sampled newest OP old-prestate game is type 9, in progress,
one-claim, and currently proper; any EOA can challenge it. At the pin it is not claim-valid. ASR
requires proper, respected, finalized, and DEFENDER_WINS before the portal accepts the root.

Kill barrier: no user-constructible consensus delta or FPVM witness between the v1.7.0 and v1.9.0
kona programs was found. Without such a witness an attacker cannot force the status needed for a
false root. The planned shared migration is also inactive in production:
`migrateToSharedDisputeGame` reverts `OptimismPortal_NotUsingInterop()` before authorization checks.
This is therefore not a source-review-only living exploit; it is rejected until a concrete witness
exists.

Highest-value follow-up is differential old/new kona execution over attacker-controlled deposit,
L2 block, and interop inputs, producing a one-step witness if any divergence exists.

Evidence: `mirror/CATK-CMP1/evidence/state-barriers.md`;
`AnchorStateRegistry.sol:286-351`; `OptimismPortal2.sol:528-570,701-704`.
