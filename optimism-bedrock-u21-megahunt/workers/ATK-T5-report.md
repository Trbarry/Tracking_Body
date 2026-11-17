# ATK-T5 report — custody solvency: OP ETHLockbox vs outstanding L2 ETH liability (lead L9)

Model: **Opus 5.5** (`claude-opus-5-5`, CLAUDE.md exception: Mythos 5.2 quota exhausted until 2026-11-22 00:00 UTC).
Candidates: **0**. Kill files: `rejected/ATTACK-T5-01..05.md`. Fork tests: `test/poc/attack-wave/T5/` (3/3 PASS,
`evidence/attack-wave/T5/fork-test-output.txt`). Live objects: `evidence/attack-wave/T5/LIVE-OBJECTS-T5.md`.
Scripts: `scripts/attack-wave-T5/`. RPC: read-only through :7545/:7546 only (about 600 chunked getLogs, about 8,000
tx/balance/call reads, 50-request batches). State changes only inside `forge test`. Nothing broadcast. Third-party
contracts were not targeted; only Optimism contracts were read (balances only for the WETH/fee-vault predeploys).

Answer: at (L1 26,433,900 / L2 159,654,093) OP custody 182,541.068255 ETH ≥ liability upper bound 182,539.366285 ETH,
**margin +1.701970012 ETH**, which is exactly the Bedrock-time margin. Every Bedrock-era wei is accounted for (ledger
residual 0 at 20 checkpoints). Ink/Soneium/Unichain: L1 ledgers exact; L1-only margin −256 wei = unwithdrawable genesis
precompile dust. No shortfall, so (d) was not triggered. No eligible impact, no attacker.

| # | Hypothesis / measurement | Command / test | Result | Verdict |
|---|---|---|---|---|
| E1 | custody at 26,433,900 | cast balance lockbox/portal/L1CDM/L1SB | 182,541.068255115703234018 / 0 / 0 / 0 | data |
| E2 | Bedrock custody seed | balance bisection L1SB/portal | 293,288.256836040170934313 moved at L1 17,423,158 | data |
| E3 | migrated L2 supply | OVM_ETH totalSupply @105,235,062 + op-chain-ops ExpectedSupplyDelta | S0 = 285,749.777035949746468829 | data |
| E4 | Σ deposit mint, all portal generations | `scan_deposits.py` (285,860 logs, 181 calls) | 1,146,026.646229017822569211, all version 0 | data |
| E5 | value of every finalization | `finalized_join.py` (26,000) | 0 unknown, 0 dup; paid 1,256,773.834809942290269506 | T5-03 |
| E6 | L2 passer conservation | `WithdrawerBalanceBurnt` scan + balance | balance + Σburn == Σ initiated, 0 wei | T5-03 |
| E7 | custody ledger vs balances | `reconcile.py`, 20 checkpoints | residual 0 wei everywhere (across the U16 sweep) | T5-03 |
| E8 | OP solvency | `reconcile.py` | liability ≤ 182,539.366285103703234026; margin +1.701970011999999992 | **KILL T5-01** |
| E9 | legacy L1SB ledger | ETHDepositInitiated/Finalized (317,436 + 9,294) + `l1sb_legacy_residual.py` | 3 eventless inflows = 3.264939988 | data |
| E10 | identify eventless inflows | block/tx decode | 2 governance `migrateEth` (OVM 1.0 gateways) + 1 public `donateETH` 0.002 | T5-04 |
| E11 | Bedrock-time solvency | B0 vs totalSupply + legacy pending | B0 = TS + 7,536.777830078 + 0.0747 → margin 1.70197 | T5-01 |
| E12 | locate 0.0747 at the legacy cutoff | L1 deposits ≥17,415,000 vs L2 DepositFinalized | all minted (1 dust out of window); the single 0.0747 deposit was minted | data |
| E13 | unbacked OVM 2.0 mints | `legacy_mint_join.py` (203,074 L2 mints) | 0 without an L1 lock | T5-02 |
| E14 | OVM 2.0 supply conservation | ΔtotalSupply vs Σmint − Σwithdrawn | 0 wei → 0.0747 predates OVM 2.0 genesis | data |
| E15 | Bedrock-era derivation spot check | `l2_mint_sample.py` (25 largest + 25 random) | 50/50 L2 deposit txs exist with exact mint | T5-02 |
| E16 | other L2 ETH sources/holders | interop predeploys, WETH, vaults | ETHLiquidity unimplemented, 0 ETH | T5-02 |
| E17 | custody covers liability on fork | `test_T5_custody_covers_liability_at_26433900` | PASS | T5-01 |
| E18 | every deposit path mint == lock | `test_T5_every_deposit_path_mints_exactly_what_it_locks` | PASS (5 paths) | **KILL T5-02** |
| E19 | donations/forced ETH | `test_T5_donations_and_forced_eth_are_surplus_only` | PASS (no deposit event, custody only grows) | **KILL T5-04** |
| E20 | Unichain L1-only | `l1only_values.py` + `l1only_reconcile.py` | residual 0; unlock == decoded; margin −256 wei | T5-05 |
| E21 | Ink L1-only | same | same | T5-05 |
| E22 | Soneium L1-only | same (1 wrapper tx via receipt ETHUnlocked) | same | T5-05 |
| E23 | genesis allocations | `gensum/` on superchain-registry genesis | 256 wei each (precompiles), OP 0 | **KILL T5-05** |

Accounting notes (not exploits): OP has only 1.70 ETH of slack (1.627 ETH documented regenesis-4 supply delta + 0.0747
pre-OVM-2.0 residual); Ink/Soneium/Unichain have zero slack apart from 256 wei of precompile dust. The custody is
exact, so any future one-wei protocol loss would be an immediate shortfall on those three chains.

Remaining assumptions: the S0 supply delta is the value the migration code enforces (the migration log was not
re-read); the L2-side truth of non-OP withdrawal values rests on proof validity (F5/C15); L2 SELFDESTRUCT burns are
ignored (they only widen margins).

Highest-value next experiment: get a chain-130 (Unichain) L2 archive endpoint and repeat E6/E5 there, i.e. Σ
`MessagePassed` value per finalized hash vs the calldata values. That removes the last assumption before the
planned OP+Unichain pooling.

Stopped lines: none by a safety system. Out of authorization: none were needed.
