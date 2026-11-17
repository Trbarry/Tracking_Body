# ATTACK-CATK-T3-06 — U21 L1 bridge hardening changes token identity semantics

Model: Codex, configured by the worker brief as `gpt-daybreak-blue-latest`.

Verdict: **KILLED — target implementations are unchanged at N; messenger delta is gas-only.**

## Hypothesis

The U21 transaction changes one bridge/factory implementation or the L1CrossDomainMessenger relay interpretation so
the same pair, selector, recipient, or replay hash acquires a different meaning at activation.

## Exact sequence tried

At L1 blocks 26,430,858 and 26,430,859, read the implementation/version for all 12 target proxies on OP, Ink, Soneium
and Unichain and resolve all four messenger implementations through their AddressManagers. Diff v8/v9 bridge,
factory, token and messenger sources. Replay real ERC721 and legacy ERC20 objects on both pinned states.

## Barrier

All four chains keep L1StandardBridge 2.8.2 at `0xb37a11…a891`, L1ERC721Bridge 2.9.1 at `0x9f164f…cb2e`, and factory
1.11.0 at `0xaabea7…9b12`. L1CDM alone moves 2.11.1 -> 2.13.0; the delta separates L1/L2 gas reserve/check-buffer
constants and adjusts `baseGas`, without changing hashes, selectors, token order, or sender checks. The portal treats
the committed gas value as a floor and forwards available gas. Both real-object differentials have identical state
outcomes.

## Evidence

- `mirror/CATK-T3/evidence/u21-differential.md`.
- PASS: four pre/post in-flight tests in `CATKT3InFlightNFTForkTest`.
