# Bounded block-N to later-state reads

Passive `cast balance` / `cast call` reads against `http://127.0.0.1:8547` (block 26430859) and `http://127.0.0.1:8545` (block 26433900). Columns are exact wei/integer/address values.

| Chain | Lockbox balance N | Lockbox balance later | DGF count N | DGF count later | DelayedWETH balance N | DelayedWETH balance later | anchorGame N | anchorGame later |
|---|---:|---:|---:|---:|---:|---:|---|---|
| OP | 182420511216757812708529 | 182541068255115703234018 | 21378 | 21389 | 20582782000000000000 | 20662782000000000000 | `0x51024A83c2F94c8e70014A732d3e2559CdceeB1D` | `0x55A5CFd4270340b3822BB9D8eebdb450ac206f95` |
| Ink | 23088758336628210326229 | 23088758336628210326229 | 2639 | 2640 | 5710376000000000000 | 5710376000000000000 | `0x7A5559F33142609Db4bf9d187311140325e27f81` | `0x38925ef2ec5451E7280CC7bBe08E73E74ebf8945` |
| Soneium | 2195560152606106316659 | 2195560152606106316659 | 8533 | 8537 | 0 | 0 | `0xa64e0DAf4A8b918811369C856897f4d6ee8b3FED` | `0x5dFB50E0E35005a0d302799bAaFf6E99134eC454` |
| Unichain | 18222347018032559647506 | 18266157945407766718622 | 17681 | 17691 | 21419797000000000000 | 21419797000000000000 | `0x55AE7D93c00a37BA77D267AE9ed1C9040cE9B1DD` | `0x944a783a2f1F187F0D475Df8aCf09c9463bCAfD5` |

Portal balances were zero at both endpoints. Bounded getter reads also found unchanged implementation/config pointers, `ETH_LOCKBOX=true`, `INTEROP=false`, exact lockbox authorization, and no pause on all four chains. The observed deltas are consistent with normal deposits, dispute-game creation/bonds, and anchor advancement; no corrective governance mutation was identified.
