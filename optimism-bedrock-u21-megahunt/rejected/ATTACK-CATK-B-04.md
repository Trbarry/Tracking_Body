# ATTACK-CATK-B-04 — application replay changes identity, deadline, or beneficiary

## Hypothesis

Nested forced failure causes a production application message to observe a different authenticated sender, miss a deadline/one-shot state, or pay the replay caller.

## Exact sequence tried

Ran the same real carrier composition against a real, proven 363.438235322873695226 ETH `onMessageReceived(bytes)` victim. After forced failure, replay came from an unrelated EOA. Separately classified 43 real proven withdrawals and scanned every observed target/proxy implementation for portal `l2Sender()`, messenger `xDomainMessageSender()`, portal literals and block-context opcodes.

## Deterministic barrier

`test_realApplicationVictimForcedFailedThenSettlesExactly` passes: replay succeeds, L1CDM returns to its pre-state, and the caller gains zero. v9 reinstalls the committed `_sender` before the target call (`CrossDomainMessenger.sol:284-286`). None of ten observed production target implementations contains the `l2Sender()` selector or portal address; relevant bridges/apps use `xDomainMessageSender()`. The OP/Ink value target implementations contain no `TIMESTAMP`, `NUMBER`, or `BLOCKHASH` opcode. No permissionless pause/upgrade step exists in the attacker model.

## Evidence

- `mirror/CATK-B/evidence/observed-target-bytecode-scan.json`
- `mirror/CATK-B/evidence/prove-target-census.json`
- named fork test above

Decision: rejected; no concrete irreversible application composition.
