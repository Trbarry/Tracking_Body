# CF3 independent audit-corpus mirror report

## Outcome

Independent Track-B corpus mining produced a structured blacklist and release-edge map, but **no bounty-ready vulnerability candidate**. I did not run a fork exploit because the corpus pass did not produce a root cause that was both novel and above the current Immunefi threshold. No transaction or state-changing RPC was sent.

The catalog contains **342 audit observations across 41 reports**: 9 source-Critical, 45 source-High, 93 source-Medium, and 195 retained source-Low. These are source labels, not current bounty severities. Every Low maps below the current reward threshold unless a new proof independently demonstrates Medium+ impact.

## Deliverables

- `AUDIT-FINDINGS.json` — required fields, controlled root-cause vocabulary, commits, page evidence, status and later-release retouches.
- `AUDIT-COVERAGE-MATRIX.csv` — 16 component families x 20 releases.
- `AUDIT-EDGE-GRAPH.md` — release-aligned scopes and eight uncovered create-transform-consume paths.
- `KNOWN-FINDINGS-BLACKLIST.md` — closed families plus acknowledged/live-by-design conditions.
- `FIX-CLOSURE-MATRIX.md` — ranked top 15 closure risks and a per-record closure ledger.
- `SOURCE-RETRIEVAL.md` — Sherlock/Kontrol/Spearbit provenance and hashes.
- `tools/build-artifacts.mjs`, `tools/pagegrep.pl` — reproducible generator and page locator.

## Facts locked

- Indexed release/report commits were taken from `docs/security-reviews/README.md:17-59`; exact tag commits are those in the governing context.
- U21 audited `8fdb2775612f23a7d51bde6c1f4961faf7e0dd7b`: 19 Low, 15 Informational, no Medium+, with all 19 Low acknowledged (U21 report p.3).
- Current v9.0.0 code still makes authorization monotonic in ETHLockbox (`ETHLockbox.sol:72,122-136,180-195,218-234`) and explicitly documents SafeCall limits (`SafeCall.sol:88-102`); both are known conditions, not new findings.
- No one report scope spans the old withdrawal record, its per-submitter transformation, and its v9 deletion/finalization consumer (`v1.0.0 OptimismPortal.sol:77,308-325`; `v2.0.0 OptimismPortal2.sol:114,132,366-377`; `v9.0.0 OptimismPortal2.sol:707-727`).
- Explicit main-tag review cells are blank at v1.1, v1.5, v2.1, v2.2, v3.0, and v3.0.1. Blank means “no indexed release-mapped report,” not “no review happened.”

## Primitives

- **PRIM-CF3-01 — HISTORICAL_OBJECT_CONTINUITY:** create an object under release N, transform its representation/authority at N+1, then consume it under N+2 assumptions.
- **PRIM-CF3-02 — NAMESPACE_IDENTITY_DRIFT:** move one semantic identity (pause key, chain ID, registry/game type) across contracts or keys while validators check only one representation.
- **PRIM-CF3-03 — GAS_GUARANTEE_COMPOSITION:** purchase gas in one layer, apply wrapper/proxy/EIP-150/fork costs in another, and enforce success in a third.

## Candidate register

**None — 0/10 bounty readiness.** The strongest compositions overlap acknowledged U21 or Interop-L2 findings and currently lack a distinct exploit condition, fork reproduction, and Medium+ impact.

## Strongest negatives

- Exact current-code observations around invalid interop destination IDs, relayer-supplied value, no-code message consumption, unbounded returndata, full-width batcher hashes, monotonic lockbox authorization, and U21 migration delays are already acknowledged or documented.
- The formal Kontrol item is a proof harness, not a findings report; its deployment equivalence is partly enforced and withdrawal-proof arrays are bounded to lengths 0-10 with 600-byte elements.
- No accepted issue was found in the invariant-testing, deposit-transaction formal review, 3Doc FGETFD review, blob-handling review, Coinbase Cannon update review, or Cannon fix review.

## Retrieval and limits

All Sherlock source/judging repositories and final PDFs were retrieved and hash-pinned. Kontrol was reachable at commit `876e16ad...`. The indexed Spearbit May/July 2025 hosted PDF paths now return 404 and are absent from the current portfolio tree; canonical local PDFs were used and hashed.

Older PDFs contain imperfect OCR; titles and pages were cross-checked against finding headings. Where a report named only a PR, `fix_commit` says so rather than inventing a merge hash. Contract/function normalization is conservative; an empty list means the title/report record did not support a safe normalized name.

## Next wave

1. **Withdrawal-proof history:** v1 single record -> v2 submitter mapping/array -> v9 delete/finalize, with pre-existing proofs and skipped migrations.
2. **Pause/authorization history:** retired Portal identifiers plus monotonic portal/lockbox authorization against pooled ETH.
3. **Gas envelope history:** old L2 messenger `baseGas` -> proxy haircut/state gas -> v9 Portal SafeCall ceiling under the executed fork rules.

