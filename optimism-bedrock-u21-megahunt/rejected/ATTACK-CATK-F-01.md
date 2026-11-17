# ATTACK-CATK-F-01 — live unfinalized system-target withdrawal

**Hypothesis.** A permanent historical withdrawal can be finalized today with the portal as caller
against a current/historical system contract that trusts that identity.

**Experiment.** Complete OP L2 `MessagePassed` census from genesis through block 159654093; join to
L1 proof/finalization events through block 26433900; decode every canonical messenger payload; match
outer and inner targets against 379 curated system addresses.

**Observed.** 35,579 withdrawals; 35 direct non-messenger withdrawals with zero curated-system
targets. Of 35,544 messenger withdrawals, 3,702 unfinalized inner messages target bridges: 3,698 have
the canonical L2 bridge sender and four have a noncanonical sender. There are zero decode failures and
zero curated targets among 32 distinct noncanonical L1 proofs.

**Barrier.** Expected bridge messages are legitimate user objects. The four wrong-sender messages
cannot satisfy `onlyOtherBridge`. Outer target choice does not let an attacker choose the committed
L2 sender.

**Decision.** Rejected. Candidate score: **0/10** (no attacker-controlled live object with shared
impact). Evidence: `mirror/CATK-F/LIVE-OBJECTS-CATK-F.md` and
`mirror/CATK-F/evidence/withdrawal-object-census.json`.

