# Lane 26 — four-chain SystemConfig state

Values are passive `cast call` reads at L1 block 26,430,859 (`http://127.0.0.1:8547`); the listed values also matched block 26,433,900. Contract root is pinned v9. U21 upgrade transaction is `0x024770b5fba87683ee1466562eefb1bcb408c29c764e24abd07c7d4050a82a99`.

## Identity and feature state

| Chain | SystemConfig | L2 ID | owner | PA owner | init / semver | E / C / I |
|---|---|---:|---|---|---|---|
| OP | `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` | 10 | `0x847B...9D92` | `0x5a0A...d2A` | 3 / 4.3.0 | true / false / false |
| Ink | `0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364` | 57073 | `0x847B...9D92` | `0x5a0A...d2A` | 3 / 4.3.0 | true / false / false |
| Soneium | `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3` | 1868 | `0x5091...3033` | `0x5a0A...d2A` | 3 / 4.3.0 | true / false / false |
| Unichain | `0xc407398d063f942feBbcC6F80a156b47F3f1BDA6` | 130 | `0x847B...9D92` | `0x5a0A...d2A` | 3 / 4.3.0 | true / false / false |

All use SuperchainConfig `0x95703e0982140D16f8ebA6d158FccEde42f04a4C`, guardian `0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2`, v2.5.0. All report last-used OPCM `0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f`, v9.0.3. `SystemConfig` stores L2 ID, SuperchainConfig, and features at `src/L1/SystemConfig.sol:150-160`; initialization writes identity at `:203-248`.

## Gas and fee configuration

| Chain | gas limit | base / blob scalar | EIP-1559 denom / elasticity | operator scalar / constant | DA footprint | min base fee |
|---|---:|---|---|---|---:|---:|
| OP | 40,000,000 | 5,227 / 1,014,213 | 250 / 2 | 0 / 0 | 0 | 0 |
| Ink | 30,000,000 | 4,424 / 810,831 | **0 / 0** | 0 / 0 | 0 | 0 |
| Soneium | 40,000,000 | 9,736 / 1,540,079 | 250 / 10 | 0 / 0 | 0 | 12,000,000 |
| Unichain | 60,000,000 | 2,000 / 900,000 | 250 / 12 | 0 / 0 | 0 | 500,000 |

All have `overhead=0` and the identical resource tuple:

```
maxResourceLimit              20,000,000
elasticityMultiplier                  10
baseFeeMaxChangeDenominator            8
minimumBaseFee              1,000,000,000
systemTxMaxGas                  1,000,000
maximumBaseFee       2^128 - 1
```

Thus `minimumGasLimit()` is 21,000,000 and `maximumGasLimit()` is 500,000,000 on every chain. The SystemConfig owner can change gas limit only within those bounds (`SystemConfig.sol:250-265,398-409`). ResourceConfig has no external setter in v9; its initializer validates min/max base fees, denominator, gas-limit sum, elasticity, and exact divisibility (`:494-526`). Portal reads it per deposit (`src/L1/OptimismPortal2.sol:851-859`).

Ink's stored EIP-1559 `0/0` is the only visually surprising value. It was already `0/0` at N-1, so U21 did not introduce it. The ordinary owner setter rejects values below 1 (`SystemConfig.sol:415-431`). No permissionless route reaches any gas/config setter.

## Address map

Each tuple is `(L1CDM, L1ERC721Bridge, L1StandardBridge, Portal, MintableERC20Factory, DelayedWETH, lastUsedOPCM)` from `getAddresses()` (`SystemConfig.sol:321-332`).

* OP: `0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1`, `0x5a7749f83b81B301cAb5f48EB8516B986DAef23D`, `0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1`, `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed`, `0x75505a97BD334E7BD3C476893285569C4136Fa0F`, `0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162`, `0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f`.
* Ink: `0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f`, `0x661235a238B11191211fa95D4Dd9E423d521E0Be`, `0x88FF1e5b602916615391F55854588EFcBB7663f0`, `0x5d66C1782664115999C47c9fA5cd031f495D3e4F`, `0xA8B389A82e088b164cD03230e900980CcED34d29`, `0x57b4C29DAee99a28E6E86778b499361294c134eA`, common OPCM.
* Soneium: `0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f`, `0x5933e323bE8896DfaCd1cD671442F27dAA10a053`, `0xeb9bf100225c214Efc3E7C651ebbaDcF85177607`, `0x88e529A6ccd302c948689Cd5156C83D4614FAE92`, `0xc1047e30EFC9E172cFe7aa0219895B6a43fC415F`, `0x18fBb58C366e21F395DdEc7cBa0510a2D9116B47`, common OPCM.
* Unichain: `0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6`, `0xD04D0D87E0bd4D2E50286760a3EF323FeA6849Cf`, `0x81014F44b0a345033bB2b3B21C7a1A308B35fEeA`, `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2`, `0xA2B597EaeAcb6F627e088cbEaD319e934ED5edad`, `0x74ad145aC900F1DD5551F0C9E143314DC4022FCf`, common OPCM.

## Batcher/signing state

| Chain | batcher | unsafe signer |
|---|---|---|
| OP | `0x6887246668a3b87f54deb3b94ba47a6f63f32985` | `0xAAAA45d9549EDA09E70937013520214382Ffc4A2` |
| Ink | `0x6db6161fc5662450e801398bad62dd9921216b98` | `0x7b322282DF45E537E5de76D60E1432Db3cF3F8E1` |
| Soneium | `0x6776be80dbada6a02b5f2095cf13734ac303b8d1` | `0x7c2Bd59ee2a2C7391c9A240132f26071e9546262` |
| Unichain | `0x9ef649e8746cc47a17708a5e86b2d66c7f6c00d1` | `0xFaACA0A10e4a23C5E01485DE07767547d4D8056D` |

At N, all four Portal ETH balances were zero. Lockbox balances in wei were respectively `182420511216757812708529`, `23088758336628210326229`, `2195560152606106316659`, and `18222347018032559647506`; each Portal was authorized. This is consistent with non-CGT custody after U21.
