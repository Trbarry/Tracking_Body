# ATTACK-F-02 — Forged first relay through any L1CrossDomainMessenger / direct bridge finalization from the portal

Lane ATK-F, Opus 5.5. Kill type: failing experiment + code barrier.

**Hypothesis.** The portal is the trusted caller of the L1CDM. An attacker withdrawal (sender = attacker EOA) targeting the
OP, Ink, Soneium or Unichain L1CDM with `relayMessage(v1 nonce, L2StandardBridge, L1StandardBridge, 0, 0,
finalizeBridgeETH(attacker, attacker, 1000 ETH))` is accepted as a first relay; or the portal calls the bridges directly.

**Sequence executed.** `test_F01_targetMatrix` rows "L1CDM forged relayMessage #0..#3", "L1StandardBridge finalizeBridgeETH /
finalizeBridgeERC20", "L1ERC721Bridge finalizeBridgeERC721".

**Barrier.** First relay requires `msg.sender == portal && portal.l2Sender() == otherMessenger` (v9 src/L1/L1CrossDomainMessenger.sol:136-137);
l2Sender is the withdrawal's own sender (OptimismPortal2.sol:618), and sibling L1CDMs compare against their own portal. Otherwise
the replay branch requires `failedMessages[hash]` (src/universal/CrossDomainMessenger.sol:247) -> "message cannot be replayed".
Bridges: `onlyOtherBridge` (src/universal/StandardBridge.sol:113, src/universal/ERC721Bridge.sol:66) needs msg.sender == messenger.
The only L2 sender that satisfies the L1CDM check is the L2CDM, which only initiates withdrawals to `otherMessenger`; the
L1 scan found every proven withdrawal from 0x42..07 on the four chains targets its own L1CDM (31,804 / 1,054 / 1,925 / 3,692) except one
forged proof against a CHALLENGER_WINS game (LIVE-OBJECTS-F.md, row L1-3).

**Evidence.** evidence/attack-wave/F/forge-test-vv.txt (trace: evidence/attack-wave/F/forge-test-vvvv.txt) — reverts "message cannot be replayed" x4, "function can only be called from the other bridge" x3.
