# ATTACK-CATK-CMP1-08 — Historical target upgrade turns replay into authorized execution

Families: messenger replay + target authorization + implementation identity. Score: **1.0/10**.

C08 replayed live failed Synthetix message `0x43e0b785...d0deb`. The message still targets the
historical direct implementation and remains rejected by `Must be proxy target`.

Kill barrier: the version-1 message hash commits the target and calldata. An attacker cannot replace
the target with the proxy or change the committed L2 sender. The message has zero value and never
enters an authorized state-changing path.

Evidence: C08 and `CrossDomainMessenger.sol:234-254`.
