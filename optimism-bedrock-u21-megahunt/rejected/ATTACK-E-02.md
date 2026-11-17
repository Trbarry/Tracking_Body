# ATTACK-E-02 — orphaned gen-0 ASR (v2.0.0) is attacker-writable (KILLED)

**Hypothesis.** The gen-0 registries (OP 0x18DAc71c…, Unichain 0x318A642d…) have a permissionless writer an attacker
can use to pre-position state consumed by later flows.

**Sequence executed.** `test/poc/attack-wave/E/test/ATKE_Poison.t.sol` P2 (inside test_E01): attacker `tryUpdateAnchorState()` -> REVERT (empty: `msg.sender.gameData()`
on an EOA), `setAnchorState(game)` -> REVERT `Unauthorized()` 0x82b42900.

**Barrier.** /home/user/ethereum-optimism/hist/v1.6.0/packages/contracts-bedrock/src/dispute/AnchorStateRegistry.sol:71-82
(`tryUpdateAnchorState` requires `msg.sender` to be the factory-registered game of its own gameData) and :99-100
(`setAnchorState` guardian-only). No live implementation creates games bound to gen-0 (C15), so no game can call it;
and migrate does not read gen-0 (E-01 state-diff).

**Evidence.** forge-E01.txt poison log.
