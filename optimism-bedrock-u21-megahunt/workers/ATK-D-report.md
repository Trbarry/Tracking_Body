# ATK-D report — trojan super-root game as a protocol attack

Model: **Opus 5.5** (`claude-opus-5-5`), per the user-approved exception in CLAUDE.md (Mythos 5.2 quota exhausted until 2026-11-22).
Result: **0 candidates, 5 deterministic kills** (ATTACK-D-01..05). PoC: `test/poc/attack-wave/D/` (4/4 PASS on `l1` @ 26433900).

## Tooling selection (task 2) — exact code
| Tool | Selection | Validates super root? |
|---|---|---|
| viem 2.58.0 (latest npm, the SDK the official docs point to: `docs/public-docs/notices/archive/upgrade-20.mdx:158-192`, `app-developers/tutorials/bridging/cross-dom-bridge-eth.mdx:344-366`) | `getGames.ts:142` `findLatestGames(respectedGameType, count-1, 100)`; `:164` keep `l2SequenceNumber >= l2Timestamp`; `waitToProve.ts:189` → `waitForNextGame.ts:102-105` `getGame({strategy:'random'})` → uniform draw from that pool; `getGame.ts:92-103` default 'latest' = `games[0]` | **No**: `buildProveWithdrawal.ts:120-153` builds the proof from L2 at `game.l2BlockNumber` and returns `l2OutputIndex: game.index`; it only checks the L2 block timestamp equals the game timestamp (`:147`). No root, status or canonicality check |
| monorepo `op-node/withdrawals/utils.go` (`ProveWithdrawalParametersFaultProofs` :114, used by `op-chain-ops/cmd/withdrawal/prove.go:120`, `op-devstack/dsl/bridge.go:430`, `op-e2e/system/helpers/withdrawal_helper.go:184`) | `findLatestWithdrawalGameCandidate` :211-246: walk newest→oldest, first game with a chain-10 entry and timestamp ≥ the withdrawal's | Only `provenOutputRoot == candidate.OutputRoot` (:169), the chain-10 component. Trojan passes. A wrong-root newest game makes it **error** instead of skipping |
| viem `getWithdrawalStatus.ts:364-443` | proof against an in-progress/air-gapped trojan → 'waiting-to-finalize'; after finality → 'ready-to-prove' | — |
| Superchain bridge UI / third-party bridges | not reachable offline; not verified | — |

## Experiments
| id | hypothesis | command / test | result | verdict |
|---|---|---|---|---|
| D-E1 | trojan accepted, default selectors pick it, real-move CHALLENGER_WINS, delete, re-prove, bond recovery | `forge test --mt test_trojan_vs_default_tooling_end_to_end` | PASS. op-node + viem-latest → trojan; viem-random pool 3 (p=1/3); +604,802 s delay; attacker recovers 0.167594/0.167594 ETH | ATTACK-D-01 kill (known CC25 3.1.6, no eligible impact) |
| D-E2 | flood viem's 100-game window | `--mt test_flood_viem_random_pool_all_trojans` | PASS: 100 trojans → pool all trojans; 16.7594 ETH locked | ATTACK-D-04 (priced) |
| D-E3 | exact copy / wrong-root newest game | `--mt test_negative_controls` | copy reverts GameAlreadyExists; wrong root → prove reverts InvalidOutputRootProof, op-node errors | ATTACK-D-03 kill |
| D-E4 | duplicate chain-10 variant | `--mt test_duplicate_variant` | PASS, first match wins | part of D-01 |
| D-E5 | overwrite relayer's proof | inside D-E1 (isolation asserts) | relayer slot unchanged, delete reverts DisputeGameNotInvalidated | ATTACK-D-02 kill |
| D-E6 | live tooling fingerprint / relayers | `evidence/attack-wave/D/scanproofs.py`, `enrich.py` on :7545 | 242 proofs/7d, 78% lag ≤ 1; auto-prover 0x431f…ddf5 = 135 proofs for 74 users | LIVE-OBJECTS-D.md |
| D-E7 | OP+Unichain migration composition | source + C10/D14 fixtures | future-only, same mechanism | ATTACK-D-05 kill |

## Quantification (task 4)
Bond 0.08 ETH plus a same-tx counter bond of 0.087594 ETH. Both are fully recovered by the attacker's own counter-claimant (NORMAL mode,
after 3 × 302,400 s), provided the counter is the honest trace claim; that part is modeled and cannot be computed locally. Honest
cadence is ~3,624 s, so 1 trojan per proposal ≈ 42 ETH in flight, recoverable. That forces every user of op-node/op-chain-ops and viem-'latest'
into one wasted 7-day cycle per proof. Docs-default viem-random users are hit with p = k/(k+h). Certainty costs 100 trojans per hour.
The delay can always be avoided by proving against any honest game index. **Not** freezing.

## Single highest-value next experiment
None in this lane: the mechanism is known (CC25 3.1.6). The only reopen is a production prover CONTRACT (not an EOA) whose
permissionless prove entry point is the only proof slot its payout path accepts. Scan the proof submitters in
`op-proofs-selection-scan.json` for code (`eth_getCode`) and check for that pattern. All 39 submitters in the window sent
direct EOA calls except one (tx_to 0xd445f50d…), which is the place to start.
