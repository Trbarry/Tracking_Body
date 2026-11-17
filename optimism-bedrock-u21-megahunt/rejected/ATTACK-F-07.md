# ATTACK-F-07 — Portal-relayed DisputeGameFactory.create of a tx.origin-authorized type-5 game (Soneium)

Lane ATK-F, Opus 5.5. Kill type: privileged precondition, deterministic chain read.

**Hypothesis.** v9 SuperPermissionedDisputeGame authorizes on `tx.origin == proposer()` only and resolves DEFENDER_WINS at
initialize (src/dispute/SuperPermissionedDisputeGame.sol:60-68). Soneium respects type 5. An attacker withdrawal targeting the
Soneium DGF `create(5, forgedRoot, extraData)` becomes a claim-valid forged super root if the transaction finalizing it has
tx.origin == proposer.

**Barrier.** Only the proposer key can be tx.origin. Soneium proposer 0x400c164C…E1b8: `cast nonce` at L1 26,433,900 = 8537 =
Soneium DGF `gameCount()` = 8537, and the F5 census (evidence/F5/soneium-games-census.txt) attributes all 8537 games to it: the
proposer has never sent any transaction other than `create`, so no finalize ever ran with that origin. Requires the privileged
proposer to sign an attacker-chosen finalize = outside the attacker model (privileged / social engineering, -5). On OP/Ink/Unichain
type 5 is registered but not respected (respected 9), so `isGameClaimValid` is false regardless.
