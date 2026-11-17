# ATTACK-CATK-CMP1-07 — Delayed replay re-executes a Hop one-shot economic effect

Families: historical replay + target one-shot state + chain identity. Score: **1.0/10**.

The live failed zero-value message `0x33f61390...e088` targets Hop
`confirmTransferRoot`. The exact root id already stores timestamp `1711679503`, equal to the
message's committed timestamp. C07 replayed it; it remained failed and unsuccessful.

Kill barrier: `TransferRoot already confirmed` proves the intended economic state was already
applied. The message carries zero value, its parameters are immutable, and the replay caller gains
nothing. This is target-side idempotence, not a stale one-shot theft.

Evidence: C07 and `mirror/CATK-CMP1/evidence/state-barriers.md`.
