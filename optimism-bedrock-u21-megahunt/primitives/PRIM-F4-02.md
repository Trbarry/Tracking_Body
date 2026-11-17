PRIM-ID: PRIM-F4-02
Title: U19 (v7 OPCMv2 re-initialisation) overwrote `SystemConfig.batchInbox` with the derived default
  `0x00 ‖ keccak256(abi.encode(chainId))[0:19]` on chains whose real inbox is different (OP Mainnet, Unichain); wrong
  on-chain value until U20 zeroed the slot and removed the getter
Earliest semantic ancestor: v1.3.0 (MCP) `SystemConfig` hashed slot `keccak256("systemconfig.batchinbox") - 1`
  (0x71ac1282…c597), written 19634866 on OP with the real inbox 0xFF00000000000000000000000000000000000010.
Current consumer: none in v9 (`LEGACY_BATCH_INBOX_SLOT` only zeroed, `op-v9.0.0 src/L1/SystemConfig.sol:240-242`; no
  getter). Past consumers 25397811 .. 26048618: `SystemConfig.batchInbox()` (v7 `src/L1/SystemConfig.sol:335`) and
  anything (tooling, validators, off-chain config loaders) that trusted it.
Releases crossed: v1.3.0 -> v7.0.0 (writer `op-v7.0.0 src/L1/opcm/OPContractsManagerV2.sol:1011`,
  `_chainIdToBatchInboxAddress(_cfg.l2ChainId)` passed to `SystemConfig.initialize`) -> v8.0.0 (zeroed).
Chains affected: OP Mainnet (0xFF00…0010 -> 0x00c65A7bB8d6351C1Cf70C95A316CC6A92839c98 at 25397811), Unichain
  (0xff00…0130 -> 0x00b2244e644cfe16f72b654fbc48ff0fecec8fc5 at 25475307); Ink (0x005969bf…) and Soneium (0x008dc74c…)
  already held the derived value, so unchanged.
Source contracts + functions: SystemConfig 3.14.2 `initialize`, `batchInbox()`; OPContractsManagerV2 (v7) upgrade path.
Persistent object or state: SystemConfig hashed slot 0x71ac1282…c597 (cast storage @19634865/19634866/25397810/25397811/
  26048618/26048619/26433900 on 0x229047fe…; Unichain 0xc407398d… @25475306/25475307/26048618).
Trigger: official U19 upgrade (privileged).
Attacker-controlled inputs: none.
Required pre-state: chain whose inbox is not the derived default.
State mutation: one hashed slot.
External calls: none.
Identity dependencies: chain id.
Broken or weakened assumption: "re-initialisation re-writes the same values" — the OPCM re-derived a value instead of
  carrying it over.
Candidate compositions: none current (slot zero, getter gone); pattern to watch: any OPCM re-init that recomputes a
  chain-specific value instead of reading it (a future validator check against a derived value).
Current production evidence: cast reads above; derived defaults recomputed (`cast keccak $(cast abi-encode 'f(uint256)' 10)`
  = 0xc65a7bb8d6351c1cf70c95a316cc6a92839c9866…).
Reason it may be benign: op-node / kona take the inbox from the rollup config, not from L1 storage; past-only (-5);
  privileged upgrade (-6); no eligible impact found.
Exact falsification experiment: none needed for current state (slot is 0 at 26433900 and no v9 reader exists).
Confidence: high (fact); no exploit.
Audit coverage:
Nearest known finding:
