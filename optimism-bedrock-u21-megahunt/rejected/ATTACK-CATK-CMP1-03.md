# ATTACK-CATK-CMP1-03 — Lockbox-local pause misses already parked messenger ETH

Families: pause identity + lockbox custody + messenger replay. Score: **1.5/10**.

C03 first parked the genuine application withdrawal in L1CDM, then modeled a legitimate guardian
pause under the current OP lockbox identifier. Replay reverted `CrossDomainMessenger: paused`.
Guardian unpause restored replay and exact settlement.

Kill barrier: `SystemConfig.paused()` resolves through the portal's current lockbox and L1CDM reads
that SystemConfig state. U21's local identifier therefore reaches the messenger even after portal
finalization. The proposed pause-identity gap does not exist.

Evidence: C03; `SystemConfig.sol:574-575`; `L1CrossDomainMessenger.sol:98-100`.
