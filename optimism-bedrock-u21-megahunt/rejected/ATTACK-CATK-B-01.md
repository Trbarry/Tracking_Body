# ATTACK-CATK-B-01 — false portal finalization strands an unmapped message

## Hypothesis

A portal `WithdrawalFinalized(hash,false)` can consume a value withdrawal while writing neither L1CDM mapping, leaving no permissionless recovery route.

## Exact sequence tried

Exhaustively scanned all four portals from birth through block 26,433,900, reconstructed every false event from its call trace, decoded the relay nonce/version, and read both v0 and v1 message mappings at block-1 and the cutoff. Fork test: `test_falsePortalFinalizationsAreLegacyV0Duplicates`.

## Deterministic barrier

Only four of 32,007 finalizations are false, all OP. Every relay has nonce version 0 and reverts `CrossDomainMessenger: legacy withdrawal already relayed`; its v0 hash was already `successful=true` before the attempted duplicate. The apparent unmapped v1 identity is the wrong identity for a v0 message. No first delivery was lost. `CrossDomainMessenger.sol:227-237` at `op-contracts/v9.0.0` enforces both identities.

## Evidence

- `mirror/CATK-B/evidence/failure-census-enriched.json`
- `mirror/CATK-B/evidence/fork-test-output.txt`
- `mirror/CATK-B/LIVE-OBJECTS-CATK-B.md`

Decision: rejected; no attacker-caused eligible impact.
