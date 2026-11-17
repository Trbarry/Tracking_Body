# LIVE-OBJECTS-T5 — custody vs outstanding L2 ETH liability (ATK-T5, Opus 5.5)

Pair: L1 26,433,900 / OP L2 159,654,093 (L1 origin 26,433,801). Read-only via :7545 / :7546. All amounts in ETH, exact wei
in `reconcile.json` and `*-reconcile.json`.

## A. OP Mainnet balance sheet

| item | value | source |
|---|---:|---|
| custody: ETHLockbox `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43` | 182,541.068255115703234018 | eth_getBalance |
| custody: portal / L1CDM / L1StandardBridge | 0 / 0 / 0 | eth_getBalance |
| B0: L1SB → portal at Bedrock (L1 17,423,158) | 293,288.256836040170934313 | balance bisection |
| OVM_ETH totalSupply at L2 105,235,062 | 285,751.404305961746468821 | eth_call |
| S0 migrated balances (totalSupply − 1.627270012 regenesis delta) | 285,749.777035949746468829 | op-chain-ops params.go |
| Σ mint, 285,860 TransactionDeposited | 1,146,026.646229017822569211 | getLogs |
| Σ initiated, 35,579 MessagePassed | 1,255,981.957789961336879992 | T2 raw |
| L2ToL1MessagePasser balance / Σ burned (113 burns) | 101,329.631836142963388882 / 1,154,652.325953818373491110 | sums to Σ initiated exactly |
| Σ paid: 24,383 Bedrock-era + 1,613 legacy v0 (success) | 1,249,728.952160103263942833 + 7,044.882649839026326673 | join |
| circulating L2 ETH upper bound | 175,794.465475006232158048 | S0 + Σmint − Σinitiated |
| pending Bedrock-era withdrawals (11,196) | 6,253.005629858072937159 | join |
| pending legacy v0 (13,012 value-bearing incl. 207 proven) | 491.895180239398138819 | T2 census |
| **liability upper bound** | **182,539.366285103703234026** | |
| **margin** | **+1.701970011999999992** | = Bedrock-time margin |

Ledger residual (actual − (B0 + Σmint − Σpaid)) = 0 wei at 20 checkpoints. Known L2 holders at 159,654,093 (sanity,
all ≤ circulating): WETH predeploy 20,865.13; SequencerFeeVault 29.69; BaseFeeVault 5.69; L1FeeVault 1.57; L2CDM 4.0551;
L2SB 0.002646; ETHLiquidity 0x…25 0 (no implementation).

## B. Margin decomposition (pre-Bedrock)

- Legacy L1SB: Σ ETHDepositInitiated 576,055.796 − Σ ETHWithdrawalFinalized 282,770.804 = B0 − 3.264939988000841220;
  the 3.265 = two governance `migrateEth` moves from the retired OVM 1.0 ETH gateways (1.740038988 at 12,688,132;
  1.522901 at 12,782,215) + one public `donateETH` 0.002 (17,140,200).
- B0 = totalSupply + legacy withdrawals pending at Bedrock (7,536.777830078) + 0.0747 exactly.
- OVM 2.0 era conserved exactly: ΔtotalSupply (L2 0 → 105,235,062) = Σ 203,074 ETH mints − Σ OVM 2.0 withdrawals (0 wei);
  every OVM 2.0 mint matches an L1 lock. Hence the 0.0747 ETH (and the documented 1.627 ETH regenesis delta) predate
  OVM 2.0 genesis (OVM 1.0 / regenesis 4); OVM 1.0 state is not served by :7546. Direction: overcollateralization.

## C. Ink / Soneium / Unichain (L1-only)

| chain | lockbox | custody | Σmint (deposits) | Σfinalized values (n) | genesis alloc | ledger residual | margin |
|---|---|---:|---:|---:|---:|---:|---:|
| Unichain | `0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5` | 18,266.157945407766718622 | 650,587.937 (53,801) | 632,321.779 (3,508) | 256 wei | 0 | −256 wei |
| Ink | `0xbd4AbB321138e8Eddc399cE64E66451294325a14` | 23,088.758336628210326229 | 168,923.235 (36,220) | 145,834.477 (919) | 256 wei | 0 | −256 wei |
| Soneium | `0x67B4de6FfA66EF201Ea6099A89cA397D56622E31` | 2,195.560152606106316659 | 20,362.696 (80,288) | 18,167.135 (1,580) | 256 wei | 0 | −256 wei |

−256 wei = 1 wei on each precompile in genesis, unwithdrawable. Missing for a full bound: L2 MessagePassed and L2 burns.
