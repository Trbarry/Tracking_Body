# ATTACK-CATK-F-06 — benign-at-initiation target gains later privileged code

**Hypothesis.** A never-finalized withdrawal targets an address with no code at initiation, and later
code interprets the committed calldata as a privileged shared-state operation.

**Experiment.** Compare L1 code at each effective target's first L2 message timestamp with code at the
pin for 66 unique targets. Reproduce the only transition using its exact sender, target, value,
selector, argument, nonce, and gas on the pinned L1 fork.

**Observed.** Only `0x00C7ecc4187F239e09D4cFeA5aBe6d3c18f923bC` changed from no code to a
23-byte EIP-7702 designator. Withdrawal `0x21dee245…9902e` is unproven and commits zero value, with the
same account as sender and target. The current delegate rejects selector `0x06684706`; the L1
messenger records `failedMessages`, finalization consumes the outer withdrawal, and ETH is unchanged.

**Barrier.** Exact current execution reverts, and the immutable message is a zero-value self-message
with no shared protocol target or authority.

**Decision.** Rejected. Candidate score: **0/10**. Evidence: code chronology in
`withdrawal-object-census.json` and
`test_historicalCodeLaterSelfMessageCannotAffectSharedProtocolState`.

