# ATTACK-D-04 — Keep default-tooling withdrawals unavailable indefinitely (sustained engine, pricing)

Verdict: **KILLED (not freezing; priced; same known root cause as D-01).**
Pricing from the fork run and live data (`LIVE-OBJECTS-D.md`):
- Honest cadence ~1 proposal / 3,624 s. One trojan per proposal = 24/day × 0.167594 ETH, each locked ~10.5 d
  (clock 302,400 s + air-gap 302,400 s + DelayedWETH 302,400 s, all read on the fork) → ~42 ETH in flight. All of it is
  recoverable if the attacker's same-tx counter is the honest claim (shown: 0.167594 ETH recovered). If it is not, about 4 ETH/day goes to the challenger.
  Gas: 715,171 per strike plus resolve/claim calls.
- Selection probability: op-node / op-chain-ops CLI and viem `getGame` 'latest': 1 with 1 trojan per proposal.
  The docs-default viem `waitToProve` draws at random (`waitForNextGame.ts:102-105`): p = k/(k+h), h = 1–2 for a fresh withdrawal. p = 1 needs
  100 trojans per honest proposal (16.76 ETH/hour, ~4,200 ETH in flight). Not sustainable.
- Victims: 242 proofs / 7 d on OP, 78% from the 1–2 newest games. 2 provers (36 proofs) reuse one old game and are immune.
- Max delay per cycle 7 d (viem shows 'waiting-to-finalize' until resolvedAt + 3.5 d). It repeats only while the victim
  keeps using the same selector. A random-pool user escapes geometrically.
Barrier: the user can prove against an honest game at any time (`OptimismPortal2.sol:390-492` accepts any proper,
respected, non-CHALLENGER_WINS game; the PoC finalizes after re-proving against 21388). This is not "Temporary freezing" (an
avoidable delay, see the brief §6). Known via CC25 3.1.6.
