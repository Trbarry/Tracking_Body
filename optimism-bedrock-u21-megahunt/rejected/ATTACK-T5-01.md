# ATTACK-T5-01 — OP Mainnet custody below outstanding L2 ETH liability (protocol insolvency) (KILLED)

**Hypothesis.** At a consistent pair (L1 26,433,900 / L2 159,654,093, L1 origin 26,433,801) the OP ETH custody
(lockbox + portal + L1CDM + L1StandardBridge) is below every ETH claim an L2 holder can still finalize.

**Sequence executed (read-only through :7545/:7546).**
1. Custody: lockbox `0x322b47Ff…` 182,541.068255115703234018 ETH; portal, L1CDM, L1SB 0.
2. Bedrock seed: L1SB → portal exactly 293,288.256836040170934313 ETH at L1 17,423,158 (balance bisection).
3. Legacy supply: OVM_ETH `totalSupply` at L2 105,235,062 = 285,751.404305961746468821; migrated balances
   S0 = totalSupply − 1.627270011999999992 (op-chain-ops `crossdomain/params.go` ExpectedSupplyDelta, chain 1, enforced
   by `ether/migrate.go:212-224`).
4. Σ deposit mint: 285,860 `TransactionDeposited` (all version 0) on the portal proxy, L1 17,420,000..26,433,900 (181
   chunked calls) = 1,146,026.646229017822569211 ETH.
5. Σ initiated on L2: 35,579 `MessagePassed` = 1,255,981.957789961336879992 ETH; passer balance 101,329.631836142963388882
   + 113 `WithdrawerBalanceBurnt` 1,154,652.325953818373491110 = Σ initiated (0 wei difference).
6. Σ finalized: 26,000 `WithdrawalFinalized`, every hash mapped (24,383 Bedrock-era success 1,249,728.952160103263942833;
   1,613 legacy v0 success 7,044.882649839026326673; 4 legacy success=false 2.13 ETH, no outflow; 0 unknown, 0 duplicate).
7. Liability upper bound = S0 + Σmint − Σinitiated (circulating 175,794.465475006232158048, incl. deposits locked on L1
   but not yet minted) + pending Bedrock-era 6,253.005629858072937159 + pending legacy v0 491.895180239398138819
   = 182,539.366285103703234026 ETH.

**Barrier.** custody − liability = **+1.701970011999999992 ETH** (= the Bedrock-time margin: regenesis-4 supply delta
1.627270012 + 0.0747 pre-OVM-2.0 residual). Custody ledger B0 + Σmint − Σpaid equals the read portal+lockbox balance with
**0 wei residual at all 20 checkpoints** (17,423,158 .. 26,433,900, across the U16 sweep). Liability is an upper bound
(L2 SELFDESTRUCT burns ignored; they only widen the margin). No shortfall exists, so no attacker sequence is built.

**Evidence.** `evidence/attack-wave/T5/reconcile.json`, `finalized-join.json`, `op-portal-deposits.json.gz`,
`l2-passer-burns.json`, `custody-checkpoints.txt`; `test_T5_custody_covers_liability_at_26433900` (PASS).
Scripts `scripts/attack-wave-T5/{scan_deposits,finalized_join,reconcile}.py`.
