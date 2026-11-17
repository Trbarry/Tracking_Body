# ATTACK-D-01 — Trojan super-root game as an eligible withdrawal-freeze (lead L4 / A-023 / PRIM-0503)

Model: Opus 5.5 (user-approved exception). Verdict: **KILLED — known root cause + impact not eligible. Score 2 (< 7).**

## Hypothesis
An unprivileged attacker backruns each honest type-9 proposal with a non-canonical super root (honest extraData + one
junk tuple, or a duplicated chain-10 entry) that embeds the TRUE chain-10 output root. Default tooling selects it, honest
proofs are accepted, the game loses, the proof dies, the user re-proves and waits again → sustained "temporary freezing".

## Sequence executed (fork `l1` @ 26433900, deployed bytecode) — `test/poc/attack-wave/D/AtkD_Trojan.t.sol`
1. `TrojanBot.strike`: `DGF.create{0.08}(9, keccak(x), x)` with `x = extraData(21388) ‖ (999, junk)` and, same tx,
   `attack{0.087594}(root, 0, C)` (attacker is the only counter-claimant). 715,171 gas.
2. Selectors (Solidity copies): op-node `findLatestWithdrawalGameCandidate` + `:169` root check → trojan (deterministic);
   viem `getGames` pool for the fresh real withdrawal → {trojan, 21388, 21387} (docs flow draws at random: p = 1/3);
   with 100 trojans (`test_flood_…`, 16.76 ETH) the pool is all trojans (p = 1).
3. 3 real pending withdrawals proven by `viemUser` with honest, unmodified parameters against the trojan → accepted.
4. Real moves: clock expiry, `resolveClaim(1)`, `resolveClaim(0)`, `resolve()` = CHALLENGER_WINS.
5. During the air-gap `checkWithdrawal` = ProofNotOldEnough, game proper/respected/not finalized → viem reports
   'waiting-to-finalize'; at t0+7d finalize reverts `OptimismPortal_InvalidRootClaim`; after resolvedAt+3.5d anyone
   deletes the proofs; the victim re-proves against honest 21388 and finalizes (ETHBridgeFinalized, success=true).
6. Bonds: attacker contract recovers 0.167594 ETH (= everything it locked), NORMAL mode, after clock 3.5d + air-gap 3.5d
   + DelayedWETH 3.5d.
Output: `evidence/attack-wave/D/forge-test-output.txt` (4/4 PASS), trace `trace-end-to-end.txt.gz`.

## Barrier (why it dies)
1. **Known, same root cause and same impact**: Cantina 2025-04 Interop Portal **3.1.6** (Low) — the portal does not check
   super-root chain-id ordering; "Some Users may pick seemingly valid SFDGame which turns out to be invalid … a User might
   have proven their transaction and wait 7 days … for nothing" (`/home/user/ethereum-optimism/audits-txt/2025_04-Interop-Portal-Cantina.txt:668-797`);
   recorded in `audit/KNOWN-FINDINGS-BLACKLIST.md:48` ("left to the proof program"). The v9 first-match lookup
   (`src/dispute/SuperFaultDisputeGame.sol:809-819`, consumed at `src/L1/OptimismPortal2.sol:441-450`) is the same root cause. −4.
2. **No eligible impact**: no funds move or become unavailable at protocol level. At every moment the victim can prove
   against an honest game (the PoC re-proves against 21388 and finalizes); no upgrade, guardian or hard fork is needed.
   The delay comes from the client's game choice. That is a griefing delay ("retryable inconvenience"), not "Temporary freezing
   of funds … (e.g. recoverable via an upgrade)". Bonds are explicitly excluded. −3.
3. The off-chain selectors are not Immunefi assets. viem is a third-party SDK. op-node/op-chain-ops withdrawal helpers
   are not listed impacts. A selector fix (reject non-canonical super roots, or prefer games from the configured proposer/
   resolved games) is a tooling change.

Score: +2 permissionless, +2 current, +2 deterministic PoC, +1 unrelated victims, +1 repeatable, +1 cross-contract
(portal consumes one component, validity is of the whole root) = 9; −4 known (CC25 3.1.6), −3 no eligible impact = **2**.
No −4 for victim-selected game: the selectors are official/default (docs `upgrade-20.mdx:158-192`, `cross-dom-bridge-eth.mdx:344-366`).

Reopen only if: a selector or relayer is found that proves on behalf of users AND cannot re-prove (e.g. a contract whose
prove entry point is permissionless and whose proof slot is the only one the payout path accepts), or the portal starts
refusing re-proves.
