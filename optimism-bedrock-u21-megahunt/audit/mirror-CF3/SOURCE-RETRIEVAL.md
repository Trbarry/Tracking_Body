# External-source retrieval log

Retrieved independently on 2026-11-17 UTC. No GitHub web/API result is relied upon; contest repositories were shallow-cloned and raw content was streamed read-only.

| Source | Retrieval result | Pin / integrity |
|---|---|---|
| Sherlock Bedrock contest source | Reachable by shallow clone | `sherlock-audit/2023-01-optimism` HEAD `568966b0a064d923ae723fb83ae2c45a3579c179`; contest scope commit in final report `3f4b3c3281...` (PDF p.1). |
| Sherlock Bedrock judging/final report | Reachable by shallow clone | judging HEAD `3907084c648b04281e5379830c34696fe9fc04f1`; `Audit_Report.pdf` SHA-256 `b77660df2d2714217b387fac560e4cb1d851d2531f8a91a661aa2939fdc272b3`, 122 pages. |
| Sherlock Bedrock fix source | Reachable by shallow clone | `sherlock-audit/2023-03-optimism` HEAD `0cdcafe158e00766de7fb5bb6ff2055a10b0dc78`; audit commits `9b9f78c661...` and op-geth `7eee103098...` (final report p.1). |
| Sherlock Bedrock fix judging/final report | Reachable by shallow clone | judging HEAD `175018a595d7399df88b620d790ab6b23bf1b02d`; PDF SHA-256 `83309dc342be72a7f523e50be2dcd25c680dd4ed6aa6897e378e433a7ebea2cd`, 67 pages. |
| Sherlock Fault Proofs source | Reachable by shallow clone | `sherlock-audit/2024-02-optimism-2024` HEAD `f216b0d3ad08c1a0ead557ea74691aaefd5fd489`; audited commit `5137f3b74c6ebcac4f0f5a118b0f4909df03aec6` (final report p.1). |
| Sherlock Fault Proofs judging/final report | Reachable by shallow clone | judging HEAD `2b7f5d81eeb2755a4de99e6fd5b2fce823177a3c`; PDF SHA-256 `8b585dfacb982d920e394fa7738b2241340a6a6d95ac78bea00370a5acbbf25a`, 60 pages. The final report's four Medium findings are canonical; judging-folder labels were not treated as final severity. |
| Runtime Verification Kontrol pausability | Reachable from `raw.githubusercontent.com` at indexed commit | Commit `876e16ad04968f0bb641eb76f98eb77e7e1a3e16`; README SHA-256 `284715b6861a2628f232e2cf4960f0955c41245c46dae594cf971199e1b87a42`. It documents proof setup/assumptions, not a vulnerability list. The stated withdrawal-proof bounds are array lengths 0-10 and 600-byte elements; deployment-summary equivalence is only partly enforced. |
| Spearbit May 2025 hosted PDF | **Indexed auditor-hosted path not retrievable** | Both indexed `master/pdfs/Optimism-Spearbit-Security-Review-May-2025.pdf` and the same `main` raw path returned HTTP 404. Current `spearbit/portfolio` shallow clone HEAD `43ec5f894014cd5c7918c426a9d0e544c82b6768` no longer contains that PDF path. Canonical local review PDF is available and hash-pinned: SHA-256 `96be10b24af784b5604b9f54d5f85b38237195e0b1dd313428dd0f190f0c4152`. |
| Spearbit July 2025 hosted PDF | **Indexed auditor-hosted path not retrievable** | Both indexed `master` and `main` raw PDF paths returned HTTP 404; absent from current portfolio tree. Canonical local PDF SHA-256 `d89ffcdb3e25fda38ce381f19b4e3e9b7ce5316f2bc69360b717425da836db52`. |

The local canonical corpus remains the source for page references. Failed hosted mirrors are recorded as provenance limits, not as evidence that the underlying reviews are unavailable.
