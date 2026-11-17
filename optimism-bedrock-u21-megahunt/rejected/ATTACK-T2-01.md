# ATTACK-T2-01 — Already-paid legacy (version-0) withdrawal is paid a second time through the v9 portal

Model: Opus 5.5 (CLAUDE.md exception). Verdict: **KILLED — invariant barrier, full population read.**

Hypothesis: the Bedrock migration put every legacy L2 message (OVM 1.0 and OVM 2.0) into
`L2ToL1MessagePasser.sentMessages`, including messages already relayed by the pre-Bedrock L1 messenger. If the v9 legacy
branch cannot see some pre-Bedrock relay (different messenger/proxy, OVM 1.0 vs 2.0 implementation, slot misalignment
with Lib_ResolvedDelegateProxy storage, relays outside the scanned history), an unprivileged party proves that object
against a current game and the portal pays its value (up to 35,555.8 ETH) again.

Sequence tried (fork, deployed bytecode, unprivileged EOAs, real L2 storage proofs, real game #21388):
prove OVM 1.0 nonce 16,753 (599.999 ETH) and OVM 2.0 nonce 110,269 (35,555.8 ETH) -> resolve game honestly -> mature ->
`finalizeWithdrawalTransactionExternalProof` from a third EOA; then direct `L1CDM.relayMessage`.

Barrier:
- `/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/universal/CrossDomainMessenger.sol:229-231` — for nonce version 0 the relay requires
  `successfulMessages[hashCrossDomainMessageV0(target,sender,message,nonce)] == false`; the mapping is written only
  to `true`; `/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/L1/OptimismPortal2.sol:651-652` turns the messenger revert into `OptimismPortal_L1CDMCallFailed`
  (whole finalization reverts, value stays in the lockbox, `finalizedWithdrawals` stays false).
- Population: the L1CDM proxy 0x25ace71c… has code from L1 12,686,757 (binary search); all 20,292 legacy
  `RelayedMessage` hashes it ever emitted map to migrated objects (12,780 OVM 2.0 nonces 100,000..139,884 + 7,512
  OVM 1.0 nonces 0..17,923 from `ovm-messages.json`) and every one reads `successfulMessages(v0) == true` at
  26,433,900 through the v9 getter (the slot the legacy branch reads). No relayed hash is missing.

Evidence: `test/poc/attack-wave/T2/test/ATKT2.t.sol::test_T2a_ovm1_relayed_v0_600ETH_blocked`,
`::test_T2a_ovm2_relayed_v0_35555ETH_blocked` (PASS; revert data 0x979d93bf; lockbox/recipient deltas 0);
`evidence/attack-wave/T2/legacy-storage-check.json` (relayedChecked 20292, relayedNotSuccessful []);
`evidence/attack-wave/T2/{ovm1,legacy}-v0-census.json.gz`; `scripts/attack-wave-T2/{legacy_census,ovm1_census,storage_check}.py`.
Note: the 20,288 already-paid objects remain provable forever but can never finalize (correct behaviour; under v8 a
third party could finalize them as `success=false` with relock, which is the B-lane observation).
