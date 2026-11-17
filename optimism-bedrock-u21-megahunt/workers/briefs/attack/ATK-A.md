# LANE A — OLD-PRESTATE SOUNDNESS TO ARBITRARY WITHDRAWAL

Inputs: A-002, lead L1, PRIM-0102, PRIM-2103 (PASS A), PRIM-CF2-03; old type-9 prestate `0x031ac6f1…`,
new `0x03e5a548…`; old-prestate type-9 games that stay respected after U21.

Facts that bound the lane (verify quickly, do not re-derive at length): no new games use the old
prestate since block 26430859; all claim-valid games' roots match the L2 header; no third-party
old-prestate game is in progress (census). So a live Critical/High needs either (i) an old-prestate
game still IN_PROGRESS whose challenge can be won by a dishonest party because the old program is
unsound, or (ii) a soundness bug that ALSO exists in the NEW prestate (then the lane becomes "current
program unsound": still in scope if it lets an invalid root win or an honest root lose).

Mission:
1. Map each prestate hash to the exact source revision. Use the superchain-registry
   (`/home/user/ethereum-optimism/ext/superchain-registry/validation/standard/standard-prestates.toml`
   and git history there), the monorepo `kona-client/v*` tags (`git -C /home/user/ethereum-optimism/optimism
   ls-remote --tags origin 'refs/tags/kona-client/*'`; fetch one tag at a time with
   `GIT_LFS_SKIP_SMUDGE=1 git -C /home/user/ethereum-optimism/optimism fetch --depth 1 origin refs/tags/kona-client/vX:refs/tags/kona-client/vX`),
   `docs/public-docs/notices/archive/` (the U20 notice names the prior prestate). Kona sources are also
   in the v8/v9 checkouts under `rust/kona`.
2. Diff the proof program between the two revisions — the client/program crates, derivation pipeline,
   executor, interop consolidation / super-root transition, precompile accelerations, hint/preimage
   handling, encoding/decoding of roots — ignoring comments/refactors. List every change that can alter
   ACCEPTANCE of an L2 transition, output root, super root or claim (commit/PR title + file:line).
3. For each security-relevant delta, build the smallest witness (invalid transition accepted by old but
   rejected by new, or valid rejected by old but accepted by new). If you cannot build or run the
   program locally (no cannon/kona toolchain), you may still decide by exact code reading plus a
   concrete input description — but the lane result must then say "witness not executed" and that is a
   kill unless the semantic difference is unambiguous.
4. Production check: list the old-prestate type-9 games on OP, Ink and Unichain that are IN_PROGRESS at
   the latest block you can read (via the proxy), with their clocks; if none remain, the old-prestate
   path is closed by time — say exactly when the last one resolved.
5. If (and only if) a delta is unsound in a way that matters, attempt the full path on a fork: an
   old-prestate game reaching DEFENDER_WINS with an invalid root -> anchor update -> proof -> finalize.
Promotion: Critical/High if an old (or current) respected program validates an invalid root that
unlocks funds; Medium if an attacker defeats honest games or halts withdrawals repeatably. Kill
otherwise with the exact diff evidence.
