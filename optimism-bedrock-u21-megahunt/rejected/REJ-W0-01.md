REJ-ID: REJ-W0-01
Title: "A legacy (pre-Bedrock) L2->L1 message that the OVM owner BLOCKED becomes relayable, because Bedrock dropped the blockedMessages check"

Idea
- The pre-Bedrock L1CrossDomainMessenger refused to relay a message whose hash was in `blockedMessages`
  (owner-only `blockMessage` / `allowMessage`).
- Bedrock keeps that mapping only as a storage spacer: `spacer_201_0_32` = blockedMessages, `spacer_202_0_32` =
  relayedMessages (v1.0.0 contracts/universal/CrossDomainMessenger.sol:91,98; layout snapshot v1.2.0
  snapshots/storageLayout/L1CrossDomainMessenger.json slots 201-203). No Bedrock..v9 code reads slot 201.
- `relayMessage` protects legacy (version-0) messages only through `successfulMessages[hashCrossDomainMessageV0]`
  (v1.0.0 contracts/universal/CrossDomainMessenger.sol:303-413; identical branch at v9
  src/universal/CrossDomainMessenger.sol:229-232).
- The Bedrock migration re-encoded pending legacy withdrawals as portal withdrawals with a version-0 nonce; PASS A
  saw 17 of them still in flight (PRIM-0805). A blocked-but-never-relayed legacy message in that set would be
  provable and finalizable today, i.e. a message the operator had deliberately stopped would execute.

Killing fact
- `eth_getLogs` on the OP Mainnet L1CDM proxy 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1 for
  topic0 in {MessageBlocked(bytes32) = 0xf52508d5…a13a02, MessageAllowed(bytes32) = 0x52c8a268…240405},
  L1 blocks 12,686,000 .. 17,430,000 in 475 windows of 10,000 blocks through the archive proxy :7545:
  0 logs, 0 errors. `blockMessage` was never called, so slot 201 holds no entry.
- Range is complete: the proxy has no code at block 12,686,000 and code at 12,690,000 (cast code);
  `version()` is "1.4.0" (Bedrock, op-contracts v1.0.0) at block 17,425,000.
- Positive control for old-range log service: RelayedMessage(bytes32) on the same address returns 42 logs in
  blocks 14,000,000 .. 14,009,999.

Evidence
- evidence/W0/l1cdm-messageblocked-scan-12686000-17430000.json (range, step, logs = [], errors = [])
- scripts/W0-scan-messageblocked.py

Limits
- OP Mainnet only (Ink, Soneium, Unichain have no pre-Bedrock messenger).
- Says nothing about the other legacy question (a legacy message relayed before Bedrock under a hash different
  from hashCrossDomainMessageV0): that stays in PRE_U16_BACKTRACE_QUEUE row B02 / PRIMITIVES A-041.
