# PRIM-CF5-03 — game validity is historical state embedded at creation

## Primitive

v9 does not compare a game to the ASR's current respected type. It reads the game's stored `wasRespectedGameTypeWhenCreated()` (`AnchorStateRegistry.sol:215-246`), then separately applies factory registration, blacklist, retirement, resolution, finality, and defender-win conditions (`AnchorStateRegistry.sol:256-352`). Thus identical current ASR code can accept different historical games on different chains.

The policy epochs differ: OP/Ink/Unichain moved 0→8→9; Soneium moved 1→5. Current retirement timestamps also differ by each U16 execution time. The exhaustive game/prestate/anchor histories are in `mirror/CF5/chains/*/UPGRADE-PATH.json`.

## Falsification so far

The U16 ASR replacements and DGF re-registrations share their respective OPCM transactions, and census index boundaries show no post-retirement game retaining an old ASR. All 12 ASRs emitted zero blacklist events through block 26,433,900. No stale-ASR acceptance candidate survived; trace-level initializer/callback ordering and exact transition-boundary replay deserve the next wave.
