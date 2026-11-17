# ATTACK-CATK-B-02 — historical value-bearing failures are stranded or caller-capturable

## Hypothesis

Production nonzero-value `FailedRelayedMessage` objects retain ETH in an L1CDM, cannot be replayed under v9, or can be captured by an arbitrary replay caller.

## Exact sequence tried

Reconstructed all 22 unique failed hashes on four chains, located every later `RelayedMessage`, read current mappings/balances, and asserted the live state on the block-26,433,900 fork with `test_liveValueBearingFailuresAllSettledAndNoMessengerCustody`.

## Deterministic barrier

Exactly four failed hashes carry ETH, totaling 328.236399668390660000 ETH. All four later succeeded through direct zero-value messenger calls, with delays of 7, 90, 5,502 and 10,229 blocks. They are now `failed=true, successful=true`, and every scoped L1CDM balance is zero. `CrossDomainMessenger.sol:234-247,284-296` commits and forwards the original target/value; the caller cannot substitute itself.

## Evidence

- `mirror/CATK-B/evidence/value-message-replays.json`
- `mirror/CATK-B/evidence/failure-census-enriched.json`
- named fork test above

Decision: rejected; observed impact is retry/replay inconvenience only.
