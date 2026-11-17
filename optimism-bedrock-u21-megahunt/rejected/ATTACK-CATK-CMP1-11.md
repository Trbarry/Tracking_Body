# ATTACK-CATK-CMP1-11 — Failed-message composition multiplies a live messenger allowance

Families: allowances/call executor + messenger replay + one-shot state. Score: **1.0/10**.

Passive reads independently confirmed a live USDC approval: owner
`0x66ba29ab634845a509d2718deab78dba28b43d79` approved Unichain L1CDM for 9 USDC;
the current owner balance is 2.531863 USDC. An ordinary committed L2 message can spend it.

Kill barrier: this is a voluntary user approval to a documented generic call executor, not protocol
custody or U21-created authority. Target failure rolls back `transferFrom`; target success writes the
terminal messenger bit, so forced failure cannot multiply the spend. Current maximum impact is
2.531863 USDC and is victim-error behavior.

No transaction was sent or simulated against the victim. Evidence:
`mirror/CATK-CMP1/evidence/state-barriers.md`; `CrossDomainMessenger.sol:284-296`.
