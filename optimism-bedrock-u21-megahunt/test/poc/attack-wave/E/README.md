# ATK-E — migration poisoning (fork tests, real deployed bytecode)

Self-contained Foundry project (forge-std only). L1 fork at block 26433900 (`l1` = pinned anvil :8545).
Exploit-phase calls come from an unprivileged EOA (`makeAddr("atk-e-unprivileged")`, `tx.origin == msg.sender`).
The only privileged action is the PLANNED OP Mainnet + Unichain `OPContractsManagerV2.migrate` (OPCM 9.0.3
`0x2d91e6F2…`), run as the ProxyAdmin-owner Safe delegatecall, with the same input as PASS A lane09.

```bash
cd /home/user/Tracking_Body/optimism-bedrock-u21-megahunt/test/poc/attack-wave/E
forge test -j 1 --match-test test_E01 -vv                    # ~11 min (dumps ~850 kB of state-diff); poison vs clean migrate
forge test -j 1 --match-test 'test_E0(4|8|9)' -vv            # ~2 s warm
python3 -I ../../../../evidence/attack-wave/E/diffacc.py \
  ../../../../evidence/attack-wave/E/migrate-clean.accesses.txt \
  ../../../../evidence/attack-wave/E/migrate-poisoned.accesses.txt
```

| test | what it does |
|---|---|
| `test_E01_poison_then_migrate_vs_clean` | snapshot; clean migrate (state-diff recorded); revert; poison P1..P7; migrate again (recorded); assert identical addresses / anchors / game config / authorizations / old-ASR pointers, and lockbox delta == exactly the attacker's donations + deposits |
| `test_E04_postMigration_poisoned_objects_inert` | after poison + migrate: attacker legacy games outside the shared domain, legacy DGF dead, legacy ASR and gen2 reject shared games, pause routing |
| `test_E08_prefund_predicted_shared_addresses` | pre-fund the three CREATE2 addresses the honest migrate will use (same block); migrate still succeeds, same addresses, ETH only becomes surplus |
| `test_E09_failed_then_retry_and_repeat` | failed first attempt leaves no partial state; retry identical to clean; repeat and subset re-migration refused |

Poison set (P1..P7): gen2 ASR `setAnchorState` (OP, Unichain), gen0 ASR write entry points, live-ASR anchor advance,
`donateETH` + SELFDESTRUCT-forced ETH into lockboxes/L1CDMs/L1SBs/ASRs, `depositTransaction`, deposit + self-unlock on
all 11 legacy DelayedWETH proxies and both current ones, wrong-root type-9 games created in the migration block.
