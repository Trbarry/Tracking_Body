# ATTACK-B-05 — Capture of ETH parked in the L1CDM by a forced failure
**Hypothesis.** Parked ETH (pooled in L1CDM) can be pulled by the attacker via a replay with value, a re-encoded
own failed message with value>0, or the victim's message redirected.
**Sequence.** test_E4: real ETH withdrawal f1 forced-failed (0.0005 ETH parked); three capture attempts; honest replay.
**Barrier.** Replay requires msg.value==0 (CrossDomainMessenger.sol:245) and failedMessages[v1hash] (:247), where the
v1 hash commits to nonce/sender/target/value/minGas/message; the parked value pays only the original target.
Recipient (an EIP-7702-delegated EOA forwarding to 0x810b0cFd…) is paid exactly; L1CDM back to 0.
**Evidence.** test/poc/attack-wave/B/ATKB.t.sol::test_E4_parked_ETH_not_capturable PASS, evidence/attack-wave/B/forge-ATKB-output.txt.
