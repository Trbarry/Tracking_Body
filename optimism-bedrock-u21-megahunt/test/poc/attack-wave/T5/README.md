# ATK-T5 fork tests — custody solvency (OP ETHLockbox vs outstanding L2 ETH liability)

Model: Opus 5.5 (CLAUDE.md exception, Mythos 5.2 quota exhausted until 2026-11-22).

    cd /home/user/Tracking_Body/optimism-bedrock-u21-megahunt/test/poc/attack-wave/T5
    forge test -j 1 -vv          # 3 tests, all PASS (fork: read-only archive proxy :7545, L1 block 26,433,900)

`foundry.toml` = u21-work template with `l1` pointed at :7545 (block pinned in `setUp`); `lib/forge-std` -> v9 checkout.
Deployed bytecode only; the exploit-side actor is an unprivileged EOA; no vm.store, no privileged prank.

| Test | What it shows |
|---|---|
| `test_T5_custody_covers_liability_at_26433900` | lockbox balance read on the fork == reconciled custody 182,541.068255115703234018 ETH; portal/L1CDM/L1SB hold 0; custody − liability upper bound = 1.701970011999999992 ETH (constants from `evidence/attack-wave/T5/reconcile.json`) |
| `test_T5_every_deposit_path_mints_exactly_what_it_locks` | portal `depositTransaction` (mint 3), `depositTransaction` with value>0/msg.value 0 (mint 0, no lock), portal `receive`, L1StandardBridge `depositETH`, L1CDM `sendMessage{value}`: each emits exactly one `TransactionDeposited` whose opaqueData mint == ETH added to the lockbox |
| `test_T5_donations_and_forced_eth_are_surplus_only` | `donateETH` and SELFDESTRUCT-forced ETH into lockbox/L1SB/L1CDM emit no `TransactionDeposited` (no L2 claim); they only add custody |
