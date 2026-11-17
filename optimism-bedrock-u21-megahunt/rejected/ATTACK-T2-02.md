# ATTACK-T2-02 — Unrelayed legacy (version-0) withdrawal delivered under a different meaning in v9

Model: Opus 5.5. Verdict: **KILLED — failing experiment + full population read.**

Hypothesis: the 35,697 never-relayed migrated messages (491.895 ETH in 13,012 value-bearing ones) carry an OVM-era
meaning (ETH as an ERC20 through L1StandardBridge, no value field, no minGasLimit, legacy target set) that v9 interprets
differently: value released to a party other than the committed recipient, value released twice (v0 hash and v1 hash
both unused), gas floor above the EIP-7825 cap, or the target receiving the portal's ETH outside the bridge.

Sequence tried: OVM 1.0 nonce 668 (25.714 ETH) and OVM 2.0 nonce 132,971 proven with real L2 storage proofs against game
#21388, finalized by an unprivileged third EOA; then a second finalize and a direct `L1CDM.relayMessage` replay.

Barrier:
- Delivered exactly once: lockbox −value, committed `to` +value, finalizer +0; `successfulMessages[v1] = true`;
  second finalize reverts (`finalizedWithdrawals`, `/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/L1/OptimismPortal2.sol:610`); direct replay reverts
  "message cannot be replayed" (`/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/universal/CrossDomainMessenger.sol:247`); the v0 hash stays unset but the v1
  hash is the relay key and only one portal object per legacy message exists (0 duplicate v0/withdrawal hashes).
- Value: migration assigns value only to L2StandardBridge `finalizeETHWithdrawal` messages (op-chain-ops
  `legacy_withdrawal.go` Value()); all 13,012 value-bearing unrelayed objects are exactly L2SB -> L1SB 0x1532ec34, and
  v9 L1StandardBridge requires `msg.value == _amount` (`/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/universal/StandardBridge.sol` finalizeBridgeETH).
- Gas: migrated gasLimit = 16·len + 1,300,873, max over 57,809 objects 1,310,665 (closes the unscanned legacy half
  of ATTACK-C-07); inner minGasLimit 0 and the portal forwards all gas.
- No unrelayed legacy object targets the L1CDM or the portal (`_isUnsafeTarget`, `/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/L1/L1CrossDomainMessenger.sol:141-143`).

Evidence: `::test_T2a_ovm1_unrelayed_v0_deliveredOnce`, `::test_T2a_ovm2_unrelayed_v0_deliveredOnce` (PASS);
`legacy-storage-check.json` (13,312/13,312 sampled unrelayed objects live in sentMessages); censuses as T2-01.
