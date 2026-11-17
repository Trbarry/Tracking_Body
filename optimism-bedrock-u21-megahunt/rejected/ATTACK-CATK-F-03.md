# ATTACK-CATK-F-03 — messenger/bridge authority laundering

**Hypothesis.** A raw withdrawal to an L1 messenger or bridge can turn the portal caller frame into a
privileged cross-domain sender and release shared bridge assets.

**Experiment.** Local L2 creation of attacker-authored direct and messenger withdrawals, followed by
fabricated-proof vehicles on the pinned L1 fork. Targets: OP and three sibling messengers, all four
StandardBridge proxies, and all four ERC721Bridge proxies.

**Observed.** An attacker can choose arbitrary target/calldata, but direct initiation commits the
attacker as outer sender. L2 messenger initiation commits the attacker as inner sender. Raw portal
frames fail bridge caller checks; canonical relay reaches the OP bridge but is recorded as a failed
message because `xDomainMessageSender != otherBridge`. Sibling messengers reject the OP portal.

**Barrier.** L1 messenger ingress conjunctively checks exact portal and `portal.l2Sender ==
otherMessenger`; bridges conjunctively check exact messenger and committed `otherBridge`.

**Decision.** Rejected. Candidate score: **0/10**. Evidence: 15-test fork suite and
`LIVE-OBJECTS-CATK-F.md`.

