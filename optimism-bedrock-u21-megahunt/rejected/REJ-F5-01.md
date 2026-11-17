REJ-ID: REJ-F5-01
Title: "A game bound to a superseded registry, or created by an implementation registered against one, is claim-valid on the LIVE registry of some U21 chain (isGameRegistered lost its binding check)"

Idea
- v9 `AnchorStateRegistry.isGameRegistered` only asks the factory (src/dispute/AnchorStateRegistry.sol:227-237). Every
  chain's factory serves three registry generations. A non-retired game whose own registry is not the live one, or a
  later `ImplementationSet` pointing at an old registry, would be claim-valid under rules it was never judged by.

Killing fact
- Exhaustive census at L1 block 26433900 (Multicall3 through the archive proxy :7545, small checkpointed batches):
  non-retired games OP 11,561 / Ink 1,718 / Soneium 5,696 / Unichain 11,505. Every one has
  `anchorStateRegistry() == portal.anchorStateRegistry()`: FOREIGN 0, getter failures 0, `gameCount()` equals the number of
  scanned indices (contiguous).
- Every `ImplementationSet` / `ImplementationArgsSet` at or after each chain's `retirementTimestamp` is bound to the live
  registry: by its immutable getter (FDG <= 1.8.0) or by the same-transaction `gameArgs` (FDG >= 2.2.0, SFDG 0.8.0,
  SPDG 1.1.0). 0 mismatches, 0 unpaired args-based implementations.
- Current configuration of types 0..10 and the live anchor game: re-checked on the fork (`test/F5/F5_ChainHistoryDifferential2.t.sol::test_a`).

Evidence
- evidence/F5/registry-binding-check.{json,txt}, evidence/F5/{op,ink,soneium,unichain}-games-*.json
- scripts/F5-games-scan.py, scripts/F5-registry-binding.py (the summary counter was corrected: CWIA implementations return
  `address(0)` from the bare implementation and had been counted as "bound to another registry")
- Closure C15 (orchestrator). Reopen at the next registry replacement or `ImplementationSet`.
