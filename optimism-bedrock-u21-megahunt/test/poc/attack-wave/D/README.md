# ATK-D fork tests — trojan super-root game vs the official withdrawal tooling (OP Mainnet, post-U21)

Model: Opus 5.5 (user-approved exception, Mythos 5.2 quota exhausted until 2026-11-22).

Fork: `l1` = `http://127.0.0.1:8545` (Ethereum mainnet pinned @ 26433900, post-U21). Deployed bytecode only;
no privileged prank (the only pranks are the unprivileged attacker, a fresh prover `viemUser`, and `rando`).

Run (working copy `/home/user/u21-work/ATK-D`):

    cp -r /home/user/u21-work/template /tmp/atkd && cp *.sol /tmp/atkd/test/ && cp *.json foundry.toml /tmp/atkd/ \
      && rm -f /tmp/atkd/test/Sanity.t.sol && cd /tmp/atkd && forge test -j 1 -vv

Last output: `evidence/attack-wave/D/forge-test-output.txt` (4/4 PASS); full -vvvv trace of the end-to-end test:
`evidence/attack-wave/D/trace-end-to-end.txt.gz`.

Fixtures:
- `victims.json` — 3 real, still-unfinalized L2StandardBridge ETH withdrawals that the production auto-prover
  0x431f…ddf5 proved (L1 txs 0xc57d4b53…, 0x815fbca2…, 0x2b8325aa…) — their withdrawal tuples are decoded from that calldata.
- `proofs_21388.json` — outputRootProof + storage proof of those withdrawals at the timestamp of the newest honest
  game 21388 (L2 block 159653251), from `eth_getProof` on the OP archive — what viem `buildProveWithdrawal` builds.
  The test checks that `hashOutputRootProof == game21388.rootClaimByChainId(10)`.
- `fresh.json` — real withdrawal from L2 block 159650756 (ts 1794900289), first covered by game 21387.

Tests (`AtkD_Trojan.t.sol`):
- `test_trojan_vs_default_tooling_end_to_end` — attacker contract makes the trojan (honest 21388 extraData + one
  junk tuple) and counters its own root in the SAME tx; Solidity copies of the selectors (op-node `findLatestWithdrawalGameCandidate`
  + root check, viem `getGames` pool) return the trojan; 3 honest proofs accepted; auto-prover's real proofs untouched
  and undeletable; real moves -> CHALLENGER_WINS; `checkWithdrawal` = ProofNotOldEnough while the game is proper,
  respected, not finalized (viem: 'waiting-to-finalize'); finalize at t0+7d reverts InvalidRootClaim; after the air-gap anyone
  deletes; victim re-proves against 21388 and finalizes (ETHBridgeFinalized, success=true) 604,802 s later than the
  honest path; attacker recovers 0.167594 ETH (creator bond + counter bond, NORMAL mode, via DelayedWETH).
- `test_flood_viem_random_pool_all_trojans` — 100 trojans (16.7594 ETH) fill viem's 100-game window: the docs-default
  `waitToProve` random draw can only return a trojan; the fresh real withdrawal proves against it.
- `test_negative_controls` — an exact copy of the honest game reverts `GameAlreadyExists` (so any trojan is non-canonical);
  a wrong-root newest game is picked by viem but the prove reverts `InvalidOutputRootProof`; the op-node selector errors.
- `test_duplicate_variant` — `[(10,R),(10,X)]` duplicate form: first match wins, honest proof accepted.

Modeled (not executable locally): that the attacker's counter-claim equals the honest trace value at position 2, so
op-challenger does not counter it (a duplicate move is rejected on-chain). If it does not, the challenger takes the bonds.
