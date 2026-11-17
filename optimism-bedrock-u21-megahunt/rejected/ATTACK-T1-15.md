# ATTACK-T1-15 — DelayedWETH generations: old proxies keep bonds while "paused"/"delay" change meaning

Lane ATK-T1, Opus 5.5. Target 15 (rows 18/19). Kill type: failing experiment on 23 deployed proxies + impact exclusion.

**Condition.** U16a 5.1.2 / OPCMv2 3.1.1: each upgrade minted a new DelayedWETH; old proxies keep game bonds and are no longer
upgraded; v9 DelayedWETH 2.0.0 resolves pause through `ethLockbox` (`DelayedWETH.sol:43-63`), older ones through their
SuperchainConfig/SystemConfig. Withdraw gate: per-(msg.sender, guy) unlocked amount + delay + caller's own WETH balance
(:101-108); `recover`/`hold` owner-only.

**Sequence executed** (`T1_Extra.t.sol::test_T1_12_delayedWethGenerations`, L1 @ 26433900): every DelayedWETH that any game of the four
chains ever used (23 proxies from the F5 census; versions 1.0.0..2.0.0, delays 302,400 / 604,800 s), total ETH held
48.272955 ETH (OP 2.0.0 20.662782, Unichain 2.0.0 21.419797, Ink 2.0.0 5.710376, old generations 0.08-0.16 each). Unprivileged
attacker: `withdraw(attacker, bal)`; `unlock(attacker, bal)` (succeeds: books only its own sub-account) then warp past `delay()` and
`withdraw(attacker, bal)`; `withdraw(game, bal)`; `transferFrom(game, attacker, 1)`; `recover(bal)`; `hold(game, 1)`.

**Result / barrier.** Every extraction call reverts on every generation; ETH balances unchanged. WETH98 `withdraw` debits
`balanceOf[msg.sender]` and `transferFrom` needs an allowance, so a sub-account unlock confers nothing. Pause/delay semantics of old
generations affect only bond timing; bonds are excluded from every SCOPE 1.4 fund impact, and no "incorrectly initiated bond
withdrawal" path exists. Known: U21 3.1.5, 3.1.15 (Part 2 #12). Output: `evidence/attack-wave/T1/T1_Extra_11_12_13.out.txt`. Score <= 0.
