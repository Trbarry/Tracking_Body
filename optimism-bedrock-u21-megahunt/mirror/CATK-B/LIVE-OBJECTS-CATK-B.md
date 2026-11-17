# CATK-B live-object census

Cutoff: Ethereum block **26,433,900**. RPC: read-only proxy `:7545`. Both event scans covered 907 ranges of at most 10,000 blocks, with zero errors. All amounts below are relay ETH, not token amounts encoded in calldata.

## Exhaustive event population

| Chain | Portal | Birth | `WithdrawalFinalized` | `success=false` | L1CDM `FailedRelayedMessage` events / unique |
|---|---|---:|---:|---:|---:|
| OP | `0xbEb5…106Ed` | 17,365,802 | 26,000 | 4 | 23 / 19 |
| Ink | `0x5d66…D3e4F` | 21,344,310 | 919 | 0 | 7 / 3 |
| Soneium | `0x88e5…AE92` | 21,314,185 | 1,580 | 0 | 0 / 0 |
| Unichain | `0x0bd4…A7a2` | 21,116,371 | 3,508 | 0 | 0 / 0 |

There are 22 unique failed-message hashes: 7 later succeeded and 15 remain unsuccessful. All four L1CDM balances are exactly zero at the cutoff. Because every non-reverting relay exit writes one mapping and v9 reverts a failed L2CDM portal call, the exhaustive four-event `success=false` set is the only possible neither-mapping set. Each is actually a version-0 duplicate whose old hash was already successful.

## Nonzero-value failures (all later settled)

| Chain | Message hash | ETH | First failure | First success | Delay | Replay caller |
|---|---|---:|---:|---:|---:|---|
| OP | `0x4469d07d864c41bc36ce454810ca41b0aab298b8a997658cb49d9219da263276` | 236.749727508928692667 | 26,346,791 | 26,357,020 | 10,229 blocks | `0xb7b51e…07529` |
| Ink | `0x940ba5ec73a0003ac5147379a5c1d8665ffb674cd11b89d3b87b69bb0cd57941` | 17.294485522346960448 | 22,419,550 | 22,425,052 | 5,502 | `0x63c99b…db864` |
| Ink | `0xd9204ef4371eca7b4f54ecc662bbddb826f9eafb959739adda4f88cf4d07b8fe` | 58.326225035908748465 | 23,096,290 | 23,096,380 | 90 | `0x63c99b…db864` |
| Ink | `0xfac7aaf73dc66ed712f0d756d6b0432ded6189e3ba77591daaf2557354c84445` | 15.865961601206262980 | 23,175,112 | 23,175,119 | 7 | `0x63c99b…db864` |

Total: **328.236399668390660000 ETH**. Every row is `failed=true, successful=true`; every successful replay transaction supplied zero ETH and called the messenger directly.

## Portal `success=false` population

| Block | Withdrawal hash | ETH | Old message hash state | Barrier |
|---:|---|---:|---|---|
| 25,149,695 | `0x50d7b36248d6690bd50386f31cdbae2c0844fa4e01f86babac82b7206bbf6ddd` | 0.608658420630034106 | `0x15b9…402d` successful | legacy already relayed |
| 25,149,748 | `0x64db0ab9509c1dcd15a09cb23d8f24f88cd508a1b314d4d154c1336213d7a7ec` | 0.001 | `0x128a…5b7f` successful | legacy already relayed |
| 25,163,168 | `0xd3628e076f6b807297b42b7780a867b7762999081ebee4d0342529cf9aa65977` | 1.521959602251578445 | `0xcd29…860f` successful | legacy already relayed |
| 26,139,841 | `0xad0a2811460d8a7f4ef1c467171ee312fb9b85f9ca8965fa44a7e9542cc68ec4` | 0 | `0xaef8…574f` successful | legacy already relayed |

Their v1 hashes have neither mapping both immediately before the event and at the cutoff, but v0 is the protocol-correct identity for these nonce-version-0 messages.

## Fifteen currently unsuccessful messages

All are OP and carry zero relay ETH. Chronological and reverse full-gas replay produce the same three recoveries, proving order independence for this population.

| First failure | Message hash | Selector / target | Current replay |
|---:|---|---|---|
| 17,941,194 | `0x18b123eba23716f71c057e6aea971962e44dd5ff7060a448940f3b70cc544c25` | `0x0166a07a` / L1StandardBridge | succeeds |
| 18,080,973 | `0x1829f5fef01c789059b15c617fb80c38c9d5878d28711b0ac56029c924cd2b92` | `0x0166a07a` / L1StandardBridge | bare token revert |
| 18,837,534 | `0x6c9a36ef9b84c9b81e771d69cb3510a754dc27a0c8d7107d0ff886eeffd0623d` | `0x0166a07a` / L1StandardBridge | succeeds |
| 20,350,732 | `0x71c9882b0173bb6c4f718642f0e20c3171c2669c9e4ef0ef99d64ee958ee4162` | `0x0166a07a` / L1StandardBridge | succeeds |
| 22,046,337 | `0x33f61390a17c6fc32db1a11557ae861c762d6784a3f4a493138c38051faee088` | `0xef6ebe5e` / `0xb890…727f` | transfer root already confirmed |
| 22,774,953 | `0x2c820221fbef636211cbff87243f637325f124f5e6c27c91929cb4854000f60f` | `0x0166a07a` / L1StandardBridge | `TransfersBlocked()` |
| 22,775,135 | `0xdc594bf2048e71225a1d0bebeab1a81e0e77bef9227e6770a41916396af859d7` | `0x0166a07a` / L1StandardBridge | `TransfersBlocked()` |
| 22,863,733 | `0x09af464ae93df20c9d7d768402753578bd7aef7eebfc2f7b1e8a37eb77280ff1` | `0x0166a07a` / L1StandardBridge | `TransfersBlocked()` |
| 24,678,043 | `0xe43cf22b3252c92cce6b3884f541ac9986c6859fd0b4421f8ab0a13db78c8802` | `0x0166a07a` / L1StandardBridge | arithmetic underflow |
| 24,678,434 | `0xe208b5278fff03643885102e09614d11a39aa3ec0efc3418e9f31170b1dc566f` | `0xa9f9e675` / `0xaba2…f128` | invalid L1 token |
| 25,271,086 | `0x384bf7ec98f1b63104cf6867d15a537510d99750345268f05b15175f07e2dd1e` | `0xa9059cbb` / `0x9175…c9d0` | subtraction overflow |
| 25,475,826 | `0x43e0b78554c436637d3a3f6383edce9dd460777a14776a6b035c604c38bd0deb` | `0xa6492fe2` / `0x39ea…e48f` | must be proxy target |
| 26,100,288 | `0xb53bc394addf5cc3467d06f5a06b44cbcbd7f12d71cce812afe5f6f51b65f403` | same | must be proxy target |
| 26,102,366 | `0xae1005458951d769f4f18048ee0fab273be75169c397e0c0fbdc34b8b9081a7d` | same | must be proxy target |
| 26,385,051 | `0x9546105b80a67d2890768f2cf1c9bfdbc6d855ed8e8d7f47373d491b8bb11312` | same | must be proxy target |

Three additional zero-ETH hashes already succeeded after failure: `0xc510…0454`, `0xd965…e2a9`, and `0xda5b…d616`.

Machine evidence: `failure-census-enriched.json`, `value-message-replays.json`, `active-zero-value-replays.json`, and `active-zero-value-replay-traces.json`.
