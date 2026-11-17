# ATK-T1 fork tests — FIX-REGRESSION (audit-fix mutation on deployed v9 bytecode)

Model: Opus 5.5 (CLAUDE.md exception, Mythos 5.2 quota exhausted until 2026-11-22).
Targets: `audit/FIX-CLOSURE-MATRIX.md` section B, items 1-15. Kill files: `rejected/ATTACK-T1-01.md` .. `ATTACK-T1-15.md`.

Needs the shared read-only pinned fork `:8545` (L1 @ 26433900). Forge forks it in-process; nothing is sent to it.
`foundry.toml` = u21-work template + `via_ir`, `evm_version = "osaka"` (mainnet rules at the pin), unlimited test gas.
`lib/forge-std` is a symlink to the v9 checkout. `fixtures/proves.json` = PASS A lane04 (43 real OP prove txs).

    cd /home/user/Tracking_Body/optimism-bedrock-u21-megahunt/test/poc/attack-wave/T1
    forge test -j 1 --match-contract T1_Registry -vv
    forge test -j 1 --match-contract T1_Portal --no-match-test test_T1_08 -vv
    forge test -j 1 --match-test test_T1_08 --isolate -vv      # gas: every call its own tx (cold access lists)
    forge test -j 1 --match-contract T1_Games --isolate -vv
    forge test -j 1 --match-contract T1_Extra -vv

| Test | Target | What it executes (unprivileged attacker unless stated) |
|---|---|---|
| `test_T1_01_registeredTypesBoundToPortalRegistry` | 1, 13 | every configured game type on 4 factories; args name only the portal ASR; attacker type-9 games bound/registered/respected only in own registry; `l2ChainId` binding; cross-registry matrix diagonal |
| `test_T1_02_anchorGamesClean` | 2 | live anchors on 4 chains claim-valid, not blacklisted/retired, respected type |
| `test_T1_03_txOriginTypesClosed` | 11 | type-5 proposers are code-less EOAs; attacker (direct + via contract) cannot create type 5 |
| `test_T1_04_pausePointerGraph` | 4, 5 | portal/ASR/SystemConfig/L1CDM/L1SB/L1ERC721/DelayedWETH resolve pause to the same lockbox; no pause under any lineage id |
| `test_T1_05_legacySlotResidueNeverRead` | 9 | legacy-slot residue on 4 portals; `vm.record` over deposit/check/delete/finalize: no legacy slot read |
| `test_T1_06_initializerSentinelsAndGuards` | 10 | metering params and `xDomainMsgSender` intact; 36 `initialize` calls by attacker revert |
| `test_T1_08_minGasGuaranteeDirectWithdrawals` | 8 | min-gas guarantee of direct withdrawals (fresh account, probe, 7702-delegated, precompile), binary search + sweep |
| `test_T1_09_closeGameAnchorStarvation` | 7 | real OP game #21359 resolved permissionlessly; closeGame gas search: no starved try/catch outcome |
| `test_T1_10_reproveAfterFinalizeAndDelete` | 3, 12 | real 119.59 ETH withdrawal: third-party re-prove, finalize via own record, re-prove after finalize, deletes |
| `test_T1_11_farFutureSuperGameNoBlockCheck` | 6 | no `challengeRootL2Block` on live types; attacker game at seq 2^64-1; honest counter keeps the anchor |
| `test_T1_12_delayedWethGenerations` | 15 | 23 DelayedWETH generations: withdraw/unlock+withdraw/transferFrom/recover/hold by attacker |
| `test_T1_13_prestateGenerations` | 14 | live type-9 prestate/VM per chain; in-progress games still on the old prestate |

VEHICLE (stated, T1-05/T1-08 only): the proof cell `provenWithdrawals[hash][submitter]` (portal slot 57) is written with
`vm.store` pointing at the chain's claim-valid anchor game; everything else is deployed code. T1-10 uses a REAL prove calldata.

Log scans (read-only `eth_getLogs` through the L1 archive proxy :7545, 500k-block chunks, 0.2 s spacing):

    python3 scripts/implscan.py 19800000 26433900 500000 ../../../../evidence/attack-wave/T1/dgf-config-events.json
    python3 scripts/asrscan.py ../../../../evidence/attack-wave/T1/asr-guardian-events.json
