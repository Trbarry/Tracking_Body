# ATTACK-T2-03 — Attacker creates a NEW version-0 (or first-relay) messenger object after Bedrock

Model: Opus 5.5. Verdict: **KILLED — code barrier + full population read.**

Hypothesis: an unprivileged L2 user mints a withdrawal carrying `relayMessage` with a version-0 nonce (legacy branch:
only the v0 hash is checked, no value semantics) and gets it first-relayed on L1.

Barrier: the Bedrock L2CDM always encodes `MESSAGE_VERSION = 1` (`/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/universal/CrossDomainMessenger.sol:95,188`);
a withdrawal whose outer sender is not the L2CDM fails `_isOtherMessenger` (`/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/L1/L1CrossDomainMessenger.sol:136-138`)
and can only replay an existing `failedMessages[v1]` entry (`CrossDomainMessenger.sol:247`, same as ATTACK-F-02).
Population: all 35,543 L2CDM-sent MessagePassed objects carry inner nonce version 1; the only non-L2CDM outer sender
to the L1CDM is 0xc0d3…0007 (`0x0a123e2e…`, unproven; CATK-F). Version-0 objects are exactly the 57,809 migrated ones.

Evidence: `evidence/attack-wave/T2/bedrock-messagepassed-census.json.gz`, `scripts/attack-wave-T2/bedrock_census.py`.
