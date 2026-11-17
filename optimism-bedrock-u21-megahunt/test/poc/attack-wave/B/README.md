# ATK-B fork tests — forced messenger failure x delayed replay (deployed v9 bytecode)

Self-contained: `ATKB.t.sol` + `U21Fixtures.sol` (copied from PASS A) + `evidence/` (real withdrawal
fixtures f0..f30 and the 15 still-failed OP Mainnet messages). Fork: `l1` = anvil :8545 (L1 @ 26433900).

```bash
cp -r /home/user/u21-work/template /home/user/u21-work/atkb-run && cd /home/user/u21-work/atkb-run
rm -f test/Sanity.t.sol
D=/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/test/poc/attack-wave/B
cp $D/ATKB.t.sol $D/U21Fixtures.sol test/ && cp $D/foundry.toml . && cp -r $D/evidence .
ulimit -v 6000000; forge test -j 1 --match-path test/ATKB.t.sol -vv
```

Expected: 5 passed (all are KILL experiments; assertions encode the barrier). Archived output:
`evidence/attack-wave/B/forge-ATKB-output.txt`.

| test | experiment |
|---|---|
| test_E1_census_replay_stillFailed_underV9 | replay all 15 OP messages still in failedMessages at the pin, unrelated EOA, 15M gas |
| test_E2_forcedFail_ERC20_ordering_and_replay_blocking | real CRV withdrawal f5 forced-failed; same-pair f6 overtakes; 3 blocking attempts; honest replay |
| test_E3_replay_gas_sweep_no_starvation_band | 501 replay gas values 300k..800k after a forced fail |
| test_E4_parked_ETH_not_capturable | real ETH withdrawal f1 forced-failed; 3 capture attempts on the parked ETH; honest replay |
| test_E5_forcedFail_then_migrate_then_replay | f1 (ETH) + f7 (CRV) forced-failed, planned OPCMv2.migrate (OP+Unichain) as the Safe, replay |

Harness-only cheat: the attacker's OWN failed message is created by injecting a provenWithdrawals
entry (vm.store) for the attacker's own L2CDM withdrawal (as PASS A NestedReplay.t.sol). Victims are
real mainnet withdrawals driven through public functions only. The only privileged prank is the
documented planned migrate in E5 (setup).
