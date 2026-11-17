# F5 — Chain-history differential mapper (TRACK A, blind) — report

Model: **Opus 5.5** (`claude-opus-5-5`), not Mythos 5.2: the user validated an exception in `/home/user/Tracking_Body/CLAUDE.md`
(2026-11-17) because the Mythos 5.2 quota is exhausted until 2026-11-22. This run resumed the previous F5 instance's
work (rate-limited) and did not restart it. No audit corpus read; passive reads only; no broadcast.

## Deliverables

- `chains/{OP,INK,SONEIUM,UNICHAIN}/{HISTORY.md,DEPLOYMENT.json,STATE-U21.json,UPGRADE-PATH.json}`: OP generated in this run.
  All four were rebuilt with hand-written §7 notes (`chains/<CHAIN>/HISTORY-notes.md`, appended by
  `scripts/F5-build-chain-files.py`). They contain:
  - born-with versions, every implementation change cross-checked against F2 (Ink/Soneium/Unichain 0 mismatches; OP 14, all coverage gaps on F5's side);
  - owner / guardian / SuperchainConfig history, custody at every upgrade block, pause history;
  - every ASR and DelayedWETH generation with its ETH;
  - game types ever registered, respected-type and retirement history, prestate per type (census lineage classes), blacklist (empty everywhere);
  - legacy slots.
- `CHAIN-HISTORY-DIFFERENTIAL.md`: 14 divergence rows with the v9 reader, the behaviour per chain and whether it can be reached unprivileged.
- Fork tests `test/F5/F5_ChainHistoryDifferential{,2}.t.sol` (run in `/home/user/u21-work/F5`, `-j 1`): 6/6 PASS.
- `evidence/F5/registry-binding-check.{json,txt}` (script fixed, rerun), `evidence/F5/root-spotchecks.txt`.
- `primitives/PRIM-F5-01.md`, `rejected/REJ-F5-01.md`, `rejected/REJ-F5-02.md`.

## Facts locked

- Registry binding (C15): all 43,480 non-retired games are bound to the live ASR (OP 11,561, Ink 1,718, Soneium 5,696, Unichain 11,505).
  Every implementation registered after the cut is bound to the live ASR; the five / six / two / five "foreign" lines in the previous summary were a
  script artefact (a CWIA implementation returns `address(0)`).
- Every claim-valid game on every chain has a root that matches the L2 header. Two third-party type-9 games are IN_PROGRESS with wrong roots:
  Ink #2638 and Unichain #17586. Both are countered and inert (`test_b`).
- Custody: portal / L1CDM / L1StandardBridge hold 0 ETH on all four chains at every block after U16. Lockboxes hold 182,541.07 / 23,088.76 / 2,195.56 / 18,266.16 ETH.
  Legacy DelayedWETH bonds: OP 0.32 ETH, Ink 0.08, Unichain 0.08 (Unichain's legacy WETH owner is still Unichain's Safe).
- Pause: none of the four chains' identifiers was ever paused. The only identifier pause on the shared SuperchainConfig was Swellchain's portal, now expired.
- Ink was U16-upgraded in the same transaction as OP (identical retirement timestamp). Soneium never had permissionless types.

## Primitives / rejections

- PRIM-F5-01: on every chain the orphaned gen2 ASR (v2.2.2) accepts live-registry legacy games as claim-valid, and anyone can move its anchor.
  This was verified on the fork. It is inert today because no implementation binds to gen2 and the anchor is only read by a game's own `initialize`.
- REJ-F5-01: a foreign-registry game is claim-valid on the live ASR (killed by the census).
- REJ-F5-02: OP-only legacy slots are reinterpreted (all are spacers that v9 never reads).

## Queue

- B13: DONE.
- Input for B03 (D7), B04 (D1–D4, D10, D11), B06 (D13) and B09 (D8): see the differential table.

## Limits

- The full-census L2 endpoint was not logged by the previous instance. Spot checks were re-run with named RPCs (`root-spotchecks.txt`).
- L2 ETH liability against the lockbox (L9) cannot be checked from L1.

## Next edges

1. Anything that reads an old registry's `getAnchorRoot`: the `migrate` replay after a gen2 anchor move (PRIM-F5-01 × C10).
2. Bond mode at `closeGame` for gen2-era games (OPUS-11).
3. Prestate soundness of the type-9 `0x031ac6f1…` window, 1,115 claim-valid games on OP (L1, B05).
