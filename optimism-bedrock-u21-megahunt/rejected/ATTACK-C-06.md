# ATTACK-C-06 — Gas-burning / gas-hungry L1 target makes a messenger withdrawal permanently undeliverable

Model: Opus 5.5. Lane ATK-C.

**Measured** (E6, target runtime `0x5b600056` = infinite loop): m=8M finalize min 8,905,922 -> finalized +
`failedMessages`; single-tx relay never (null up to the bracket); m=15.8M finalize min 17,083,307 (> cap).
Identical finalize minimum to the empty target (8,905,922 / 17,083,307): the portal and L1CDM gas checks do not
depend on the target.

**Classification.** Whether a target can ever succeed is a property of the target the sender chose (and of
m >= what it needs, also sender-chosen). A third party cannot make an existing target need more gas than the
sender's m except through the target's own (out-of-scope, third-party) logic. Outcome is replayable
`failedMessages`, value parked in L1CDM, never "finalized without record" (C6/D04 hold). KILLED (self-inflicted /
out of scope).
