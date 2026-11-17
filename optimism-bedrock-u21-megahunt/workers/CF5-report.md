# CF5 report — chain-history differential mapper

## Disposition

No bounty candidate survived falsification. The thesis is nevertheless proven: identical v9 bytecode produces different permissionless behavior from historical chain-local storage. The strongest fork-demonstrated split is documented policy, not an authorization bypass.

Primary synthesis: `mirror/CF5/CHAIN-HISTORY-DIFFERENTIAL.md`. Per-chain packets: `mirror/CF5/chains/{OP,INK,SONEIUM,UNICHAIN}/{HISTORY.md,DEPLOYMENT.json,STATE-U21.json,UPGRADE-PATH.json}`. Raw evidence and reproducible scripts are under `mirror/CF5/evidence/` and `/home/user/u21-work/codex-CF5/h/scripts/`.

## Facts locked

- Passive L1 state is pinned at block 26,433,900; U21 executed at 26,430,859. No transaction was broadcast and no shared fork was mutated.
- All four chains run the same v9 SystemConfig, Portal, DGF, ASR, DelayedWETH, ETHLockbox, and L1XDM implementations, but OP/Ink/Unichain retain registered/respected type 9 with a 0.08 ETH bond while Soneium retains type 5 only (`evidence/pinned-cast-reads.txt:27-32,55-60,83-88,111-116`).
- Named fork test `test_sameType9CreationCallDiffersBecauseRegistrationHistoryDiffers`: byte-identical valid type-9 creation succeeds on OP and reverts `NoImplementation(uint32)` on Soneium (`h/test/ChainHistoryDifferential.t.sol:14-40`; `evidence/chain-history-differential-test.txt`). U20/U21 task text proves this split intentional.
- Each chain executed U2, U3, U16, U16a, U17, U18, U19, U20, and U21; per-component no-ops, every current-proxy `Upgraded` event, release snapshots, OPCM succession, manual tasks, and prestate epochs are normalized in `UPGRADE-PATH.json`.
- Current ProxyAdmin/DGF owner is the 2-of-2 L1PAO Safe. Its owner Safes are 5-of-7 and 10-of-13. OP/Ink/Unichain SystemConfig uses the 5-of-7 Safe; Soneium uses a distinct 3-of-5. Complete setup/member/threshold history is `evidence/safe-owner-history.json`.
- U16 migrated exact Portal ETH into four lockboxes. At the pinned block, every target Portal, L1XDM, and L1StandardBridge balance is zero; current liquidity is confined to the chain lockboxes.
- Historical games reference 12 ASRs and 23 DelayedWETHs. DelayedWETH lineages hold OP 20.982782 ETH, Ink 5.790376 ETH, Soneium 0, Unichain 21.499797 ETH. All 32,101 ASR anchor updates and zero blacklist events are retained.
- Complete censuses: Ink 2,640, Soneium 8,537, Unichain 17,691 games. After official proposer rotations, Ink index 2638 and Unichain index 17586 are the only unexpected live flags; both are type 9, claim-invalid, and mismatch independently reconstructed L2 header roots. OP index 19206 is a claim-valid third-party control whose root matches exactly.
- Global pause lasted 636 seconds in May 2025. The only later local pause was for Swell, not a target chain, and expired. All targets are currently unpaused.
- OP-only nonzero legacy XDM/bridge/Portal slots map to v9 private spacers and have no reader.

## Primitives and rejections

- `PRIM-CF5-01`: historical game registration changes permissionless reachability under identical code.
- `PRIM-CF5-02`: retired game lineages retain version-specific bond custody.
- `PRIM-CF5-03`: withdrawal-game validity depends on respect-at-creation and other historical predicates.
- `REJ-CF5-01` through `REJ-CF5-05`: inert legacy slots; invalid unexpected games; no stranded custody; no target pause drift; intended type-5/type-9 policy.

Candidate: none; severity/likelihood score not applicable.

## Limits and next wave

Balances are sampled at births/releases/current head, not every intervening block. Header reconstruction targeted unexpected live games plus one OP control. Recommended next edges: cross-version credit withdrawal over nonzero legacy DelayedWETHs; trace initializer/callback ordering inside ASR replacement transactions; replay first post-U20 games across the respected-type transition.
