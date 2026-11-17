# CW0 — PASS A ingest and semantic ancestry mirror

## Outcome

No new vulnerability candidate was established. No `PRIM-CW0-*`, `REJ-CW0-*`, or `CAND-CW0-*` file was warranted: the independent historical pass found semantic pivots and persistent-object compositions worth testing, but no permissionless impact survived the evidence threshold.

The 115-file PASS A corpus contains 112 in-scope primitives after the required exclusion of PRIM-3301..3303. Conservative mechanism-identical deduplication produced 89 `A-*` records: 24 P0, 58 P1, 7 P2. `CW0DeliverablesValidation` passed with all 112 source files covered exactly once, an 82×82 P0/P1 matrix, 21 lineage records, and 180 tag-qualified citations resolved within pinned source files.

## Facts locked

- Portal proof identity changed from one L2OO proof per hash (`v1.0.0:contracts/L1/OptimismPortal.sol:242-420`) to per-submitter fault-game cells (`v1.4.0:src/L1/OptimismPortal2.sol:83-95,254-522`), while finalization remained hash-global. Validity governance moved into ASR in v4 and the unified v7/v9 prove path selects output-root versus per-chain super-root using the registered game's type (`v9.0.0:src/L1/OptimismPortal2.sol:390-492`).
- ASR changed from per-type anchors (`v1.4.0:src/dispute/AnchorStateRegistry.sol:20-87`) to one shared `anchorGame` and a predicate pipeline (`v2.0.0:src/dispute/AnchorStateRegistry.sol:39-262`). Registration's embedded-ASR equality was removed by v7; current registration relies on the DGF UUID domain plus retirement (`v9.0.0:src/dispute/AnchorStateRegistry.sol:215-352`).
- DGF UUID inputs remain `(type, root, extraData)`, but future-clone meaning became mutable through `gameArgs`, and v6/v7 introduced dual immutable layouts plus deterministic CREATE2 (`v9.0.0:src/dispute/DisputeGameFactory.sol:147-245,312-318`). Existing clones do not migrate.
- Custody moved from Portal balance to ETHLockbox in v4. Lock is intentionally unpaused, unlock is paused, authorizations are monotonic, and shared migration transfers aggregate balances (`v9.0.0:src/L1/ETHLockbox.sol:112-235`).
- Pause authority moved local Portal → global SuperchainConfig → scoped expiring identifiers → U21 ETHLockbox key (`v9.0.0:src/L1/SuperchainConfig.sol:79-153`; `src/L1/OptimismPortal2.sol:306-330`).
- Messenger v0/v1 hash and replay mappings date to Bedrock (`v1.0.0:contracts/universal/CrossDomainMessenger.sol:303-413`). U21 changes local gas budgeting and makes a failed L1CDM call atomic at the Portal, without migrating old message objects (`v9.0.0:src/universal/CrossDomainMessenger.sol:209-420,461-466`; `src/L1/OptimismPortal2.sol:620-653`).
- Maintenance branches v2.1/v2.2 and v3.0.1 introduce no indexed target-surface semantic delta; the generated function-body index records the comparison.

## P0 primitive map

| IDs | One-line reason |
|---|---|
| A-002 | Old-prestate type-9 clone is still consumed by current singleton predicates (L1). |
| A-004, A-008, A-079 | `tx.origin` type-5 creation, proposer rotation, and shared cross-type anchor compose (L7). |
| A-012 | Nested messenger replay can create a retryable `failedMessages` entry holding withdrawal ETH (L3). |
| A-022, A-044 | Trojan/future super-game roots accept genuine per-chain proofs; delay impact remains unpriced (L4). |
| A-017, A-035, A-041, A-045, A-046, A-086, A-089 | Old persisted gas limits meet split U21/future-EVM execution budgets (L5). |
| A-038 | Live v0 and old-budget messages prove that legacy objects cross the boundary. |
| A-034, A-040, A-061, A-071, A-074, A-081, A-085 | Shared migration leaves the richest proof/singleton/authorization/type-list residue (L8). |
| A-060 | Shared lockbox is an aggregate pool with no per-portal quota; safety depends on Portal validity (L9). |
| A-087 | v9 adds calldata-proportional deposit gas at the exact implementation boundary (L6). |

## Strongest negatives

- Hash-global finalization and messenger mappings block ordinary double execution (`v9.0.0:src/L1/OptimismPortal2.sol:577-666`; `src/universal/CrossDomainMessenger.sol:209-310`).
- Delete cannot remove a still-valid proof; it only clears one cell after challenger-win or current-registry blacklist (`v9.0.0:src/L1/OptimismPortal2.sol:711-728`).
- Direct-call failure relocks exact value; transaction rollback kills pre-metering lock/call effects (`v9.0.0:src/L1/OptimismPortal2.sol:577-666,741-795`).
- Fresh DGF+ASR migration makes old proofs unregistered/retired, rather than silently carrying their authority forward (`v9.0.0:src/dispute/AnchorStateRegistry.sol:94-132,227-352`).

## Limits and next wave

This pass is source-lineage and PASS A ingest, not a new live-chain census. It did not rerun the pre-v1.9 kona program, reconstruct pre-pooling L2 ETH liability, activate Amsterdam/EIP-7825, or execute the eventual governed shared migration. The next wave should prioritize: (1) old-prestate type-9 execution; (2) migration residue plus per-chain liability; (3) EIP-7825/Amsterdam gas-cap arithmetic over real v0/old-budget messages.
