# ATK-T1 report — FIX-REGRESSION (audit-fix mutation of the top-15 targets on deployed v9 bytecode)

Model: Opus 5.5 (user-approved CLAUDE.md exception; Mythos 5.2 quota exhausted until 2026-11-22 00:00 UTC).
Result: **0 candidates, 15 deterministic kills** (`rejected/ATTACK-T1-01.md` .. `-15.md`), one per target of
`audit/FIX-CLOSURE-MATRIX.md` section B. Tests: `test/poc/attack-wave/T1/` (13 fork tests on L1 @ 26433900, all PASS; commands in
its README). Evidence: `evidence/attack-wave/T1/` (forge outputs, two bounded log scans, `LIVE-OBJECTS-T1.md`).
Every exploit-phase call is from an unprivileged EOA/contract; no privileged prank was used. Vehicle: proof cell written with
`vm.store` (slot 57) in T1-05 and T1-08 only; T1-09/T1-10 use a real OP prove transaction and a real game.

| Id | Target (row) | Hypothesis / mutation | Command / test | Result | Kill |
|---|---|---|---|---|---|
| T1-S1 | 1 | every game type ever configured on the 4 factories | `implscan.py` getLogs ImplementationSet/ArgsSet/InitBond 19.8M..26.43M (56 calls) | types {0,1,4,5,8,9,10}; live 5 + 9 | ATTACK-T1-01 |
| T1-01 | 1, 13 | foreign-bound registered impl; cross-chain presentation through the shared type-9 impl; `l2ChainId` binding | `test_T1_01_registeredTypesBoundToPortalRegistry` | args name only the portal ASR; attacker games bound/registered only in own registry; matrix diagonal; l2ChainId 10/57073/1868/130 | ATTACK-T1-01, -13 |
| T1-02 | 2 | anchor blacklisted/retired/de-respected seeds new games | `test_T1_02_anchorGamesClean` + `asrscan.py` (guardian events, 4 ASRs) | anchors clean; 0 guardian events; census: 0 blacklisted | ATTACK-T1-02 |
| T1-03 | 11 | tx.origin type-5 creation by attacker / via contract; proposer 7702 | `test_T1_03_txOriginTypesClosed` | reverts on 4 chains; proposers code-less | ATTACK-T1-11 |
| T1-04 | 4, 5 | pause pointer divergence (messenger/bridges/WETH/ASR vs portal); latched pause under retired id | `test_T1_04_pausePointerGraph` | one identifier per chain; all pauseTimestamps 0 | ATTACK-T1-04, -05 |
| T1-05 | 9 | legacy-slot residue read by v9 | `test_T1_05_legacySlotResidueNeverRead` | residue present; 41 reads/chain, none legacy | ATTACK-T1-09 |
| T1-06 | 10 | sentinels reset / initializer reachable | `test_T1_06_initializerSentinelsAndGuards` | fields intact; 36 initialize calls revert | ATTACK-T1-10 |
| T1-08 | 8 | third-party starves a direct withdrawal's target (two reserve regimes, 7702, precompile) | `test_T1_08_minGasGuaranteeDirectWithdrawals --isolate` | 0 non-reverting starved finalizations (22 cases, 17 excluding precompile 0x0a; binary search + sweep) | ATTACK-T1-08 |
| T1-09 | 7 | closeGame try/catch starvation leaves anchor stale | `test_T1_09_closeGameAnchorStarvation --isolate` (real game #21359) | min gas 128,411; 0 starved outcomes in 600 runs; anchor moves | ATTACK-T1-07 |
| T1-10 | 3, 12 | per-submitter records: third-party re-prove, finalize via own record, re-prove after finalize, delete | `test_T1_10_reproveAfterFinalizeAndDelete --isolate` (real 119.59 ETH withdrawal) | victim timer untouched; exact value to committed target; AlreadyFinalized; deletes refused | ATTACK-T1-03, -12 |
| T1-11 | 6 | no block/sequence bound on live types; far-future super game moves the anchor | `test_T1_11_farFutureSuperGameNoBlockCheck` | created at 2^64-1; honest counter -> CHALLENGER_WINS; anchor unchanged | ATTACK-T1-06 |
| T1-12 | 15 | extraction from any of 23 DelayedWETH generations | `test_T1_12_delayedWethGenerations` | all paths revert; 48.27 ETH untouched | ATTACK-T1-15 |
| T1-13 | 14 | old-prestate games after the prestate switch | `test_T1_13_prestateGenerations` + cast | 74/7/75 old-prestate in-progress games; same VM; Lane A kills apply | ATTACK-T1-14 |

Prior coverage reused instead of re-run (no precondition change): C15 (registry census), C16/C2 (legacy slots), F6 carry-through
(old proof cells under v9), ATTACK-E-05 / CATK-E-04 (post-migrate registry/proof binding), Lane C (messenger gas generations),
CATK-B-01 (version-0 relays), Lane A (old prestate).

Lines of work stopped: none (no safety-system stop, no out-of-authorization hypothesis).

Highest-value next experiment: none of the 15 conditions is violated on any of the four chains today; every residual variant needs a
privileged write (factory args, guardian blacklist/retirement, OPCM re-initialisation) or an incorrectly resolved game. The single
remaining permissionless edge in this class is the old-prestate population (T1-13: ~156 live type-9 games still judged by
kona-client v1.7.0) — only a new kona v1.7.0 soundness difference (Lane A queue) would turn it into a candidate.
