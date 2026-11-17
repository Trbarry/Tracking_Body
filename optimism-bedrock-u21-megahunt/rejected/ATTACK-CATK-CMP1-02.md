# ATTACK-CATK-CMP1-02 — Target pause makes forced replay permanently attacker-controlled

Families: messenger replay + target authorization + time/pause. Score: **2.0/10**.

C02 created the same real failed 363.438 ETH message. The deployed pool's sole operations multisig
paused it; an unprivileged replay remained failed and value stayed in L1CDM. The legitimate
operations identity unpaused it, after which the same unprivileged replay settled exactly.

Kill barrier: only the application's authorized operations identity can create or remove this gate.
The attacker cannot cause the pause, extend it, change the committed recipient, or capture the
parked value. The condition is privileged and reversible, not an attacker-created permanent freeze.

Evidence: C02 and `mirror/CATK-CMP1/evidence/state-barriers.md`.
