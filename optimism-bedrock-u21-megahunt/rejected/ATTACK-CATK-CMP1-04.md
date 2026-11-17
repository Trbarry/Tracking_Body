# ATTACK-CATK-CMP1-04 — Global pause can be bypassed by direct failed-message replay

Families: global pause identity + messenger replay + custody. Score: **1.0/10**.

C04 globally paused SuperchainConfig after the real 363.438 ETH message was parked. A direct replay
from an unrelated EOA reverted and left both message state and custody unchanged. Unpause restored
settlement.

Kill barrier: direct replay is permissionless but not pause-free. L1CDM checks the same global-or-
local pause path before executing the target. No bypass or alternative entry point was found.

Evidence: C04 and `mirror/CATK-CMP1/evidence/fork-test-output.txt`.
