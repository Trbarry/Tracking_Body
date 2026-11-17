# ATK-F report — unsafe targets and surviving system-contract trust

Model: Opus 5.5 (user-approved CLAUDE.md exception; Mythos 5.2 quota exhausted until 2026-11-22).
Result: 0 candidates, 8 deterministic kills. Tests: `test/poc/attack-wave/F/` (4/4 PASS, `forge test -j 1 -vv`).
Output: `evidence/attack-wave/F/forge-test-vv.txt`, trace `forge-test-vvvv.txt`, objects `LIVE-OBJECTS-F.md`.

| Id | Hypothesis | Command / test | Result | Kill |
|---|---|---|---|---|
| F-S1 | Proven withdrawals on the 4 portals target a system contract (any chain/generation) | `scripts/attack-wave-F/scan_l1_proven.py` | only own-L1CDM (38,475), 10 code-less EOAs, 2 forged proofs on CHALLENGER_WINS games, 1 WETH9.approve | LIVE-OBJECTS-F |
| F-S2 | Unproven OP L2 withdrawals to a system contract (incl. addresses that gained code later) | `scan_l2_op.py` | 1 hit (WETH9.approve, finalized) | ATTACK-F-08 |
| F-S3 | Allowances / balances held by portals and L1CDMs | Approval/ApprovalForAll log scan, balanceOf reads | 2 allowances (2.53 USDC; spam token), 0 balances | ATTACK-F-05 |
| F-S4 | Source sweep v1.0.0..v9.0.0 for portal-trusting contracts | grep `l2Sender()` / msg.sender==portal over hist tags | only ETHLockbox, L1CrossDomainMessenger | ATTACK-F-03/08 |
| F-01a | Sibling lockbox unlockETH / lockETH / receiveLiquidity, lockbox impl | `test_F01_targetMatrix` rows 1-8 | call fails (ETHLockbox_Unauthorized), relock exact | ATTACK-F-01 |
| F-01b | Forged first relay via 4 L1CDMs; direct bridge finalize | rows 9-15 | "message cannot be replayed", onlyOtherBridge | ATTACK-F-02 |
| F-01c | SystemConfig, ProxyAdmin, AddressManager, SuperchainConfig, ASR v4/2.0.0/2.2.2, DelayedWETH v2/g1, DGF, L2OO, OPCMv2 | rows 16-30 | all revert on auth; state hash unchanged | ATTACK-F-03 |
| F-01d | Sibling-portal deposit / L1CDM.sendMessage from the portal | rows 31-32 | succeed, attacker's own value only (exact lockbox deltas) | ATTACK-F-06 |
| F-07 | Current lockbox / portal as target, 4 chains | `test_F07_currentLockboxBlocked` | OptimismPortal_BadTarget | ATTACK-F-01 |
| F-08 | Sender 0x…dEaD vs sibling lockboxes | `test_F08_deadSenderVsSiblingLockboxes` | Unauthorized; sender is a 160-bit preimage | ATTACK-F-04 |
| F-09 | Spend live USDC allowance to Unichain L1CDM | `test_F09_liveAllowanceToMessenger` | PASS (2.531863 USDC), score 1 | ATTACK-F-05 |
| F-10 | tx.origin type-5 game via portal-relayed DGF.create (Soneium) | `cast nonce` proposer @26433900 = 8537 = gameCount | proposer never sent another tx; privileged | ATTACK-F-07 |

Next highest-value experiment (outside this lane's kill set): none in the unsafe-target class; the only portal-trusting
predicates are `l2Sender == DEFAULT` and `l2Sender == L2CDM`. A live break needs an L2 path that makes 0x42..07 initiate a withdrawal to a
non-L1CDM target (A-017: decode every pre-Bedrock migrated and every L2CDM-version withdrawal target, which belongs to ATK-B).
