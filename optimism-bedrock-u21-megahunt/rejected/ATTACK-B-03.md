# ATTACK-B-03 — Forced failure + reordering breaks L1StandardBridge ERC20 accounting / release
**Hypothesis.** Forcing victim W1 into failedMessages, letting a later same-pair W2 finalize first, then replaying
W1 changes `deposits[l1][l2]` or token release (underflow, misdirected tokens, double pay).
**Sequence.** test_E2: real CRV withdrawals f5 (victim, 292.93 CRV) and f6 (8.10 CRV) @26433900; nested finalize
of f5 inside attacker replay; f6 finalized normally; replay f5 by unrelated EOA.
**Barrier.** deposits is a per-pair sum debited with checked math (StandardBridge.sol:292) — order-independent while
sum(withdrawals) <= deposits; all mature fixtures have deposits >> pending (e.g. CRV 6.5M vs ~1.7k). Recipient
receives amtV+amtO exactly once; deposits and bridge custody debited exactly; second replay reverts (:254).
**Evidence.** test/poc/attack-wave/B/ATKB.t.sol::test_E2_forcedFail_ERC20_ordering_and_replay_blocking PASS, evidence/attack-wave/B/forge-ATKB-output.txt.
**ERC721 variant (code barrier, no mature ERC721 fixture exists).** L1ERC721Bridge.finalizeBridgeERC721 checks and
clears a per-(l1,l2,tokenId) bool (v9 src/L1/L1ERC721Bridge.sol:104-110) under the same onlyOtherBridge
(xDomainMessageSender, set on replay) and paused (:99) gates: a delayed replay is identical to first delivery; the
token cannot be withdrawn twice on L2 without a new deposit.
