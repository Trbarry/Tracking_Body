| era | fixture | prove block | portal | model | real-tx replay | stored == mainnet | same calldata from fresh submitter | new object stored |
|---|---|---|---|---|---|---|---|---|
| BEDROCK | p0 0xcbd2396ecedf84698737bbafd377b9b1cde17bbd9c468ad3a35b89e5703a4a13 | 18361305 | 1.6.0 | l2OutputOracle | ok | yes | revert Error(OptimismPortal: withdrawal hash has already been proven) | n/a (proof keyed by hash only) |
| PROTOCOL_VERSIONS_INIT | p0 0x609d5b78a84b3cbf49c51bacb3738853dbe7ab50190541cb321838bd899f65b0 | 19057918 | 1.6.0 | l2OutputOracle | ok | yes | revert Error(OptimismPortal: withdrawal hash has already been proven) | n/a (proof keyed by hash only) |
| SUPERCHAIN_CONFIG_INIT | p0 0xc7b7491399946c37d189413f0be102dafab443236c2c1a08b76020a8fb61a8d2 | 19309253 | 1.6.0 | l2OutputOracle | ok | yes | revert Error(OptimismPortal: withdrawal hash has already been proven) | n/a (proof keyed by hash only) |
| V1_2_0 | p0 0x4b6ab75315b5510b1ea1ce8d67c94e1afa41daa17f5d5b2942a30979afc73ed0 | 19627525 | 2.4.0 | l2OutputOracle | ok | yes | revert Error(OptimismPortal: withdrawal hash has already been proven) | n/a (proof keyed by hash only) |
| V1_3_0 | p0 0x88ff4b8f3a2a9f07da967862fc4cabc7fbb56ba2ab1398eae994aef1fc827e44 | 19884249 | 2.5.0 | l2OutputOracle | ok | yes | revert Error(OptimismPortal: withdrawal hash has already been proven) | n/a (proof keyed by hash only) |
| FP_PROXIES_INIT | p0 0x50e0e4c2b5a0f5970dcdb4146851a405d07033f98e376ea473083779f1927a31 | 20057553 | 2.5.0 | l2OutputOracle | ok | yes | revert Error(OptimismPortal: withdrawal hash has already been proven) | n/a (proof keyed by hash only) |
| V1_4_0_FP | p0 0x36139cf5c63ab5361c02b95f426f164e68d12c8e909c922307530a27827fb4a6 | 20721858 | 3.10.0 | disputeGame | ok | yes | ok | yes (keyed by submitter) |
| V1_6_0_ASR | p0 0x1b54792b208e24448dd46ae0a0819e1cb090c8b838b0d078a16bfc89008fbffa | 21695017 | 3.10.0 | disputeGame | ok | yes | ok | yes (keyed by submitter) |
| V1_8_0 | p0 0x55fdea3547f291106288f82dbcf59befb5908343769257ba731e4487cd14a4b0 | 22179587 | 3.10.0 | disputeGame | ok | yes | ok | yes (keyed by submitter) |
| U13_V2 | p0 0xa441f02f8848ee0ffe77e14e0605ab45be8cf0333d0bd0e23a7f2b5a5f2239f0 | 22339436 | 3.13.0 | disputeGame | ok (re-prove: replaced an older proof) | yes | ok | yes (keyed by submitter) |
| U14_V3 | p0 0x3d0aacb45e026be98a0bf9c7cf1a9f75d00702260c524459f357ba25251b92bc | 22985908 | 3.14.0 | disputeGame | ok | yes | ok | yes (keyed by submitter) |
| U16_V4 | p0 0x1dbccb896b40a00f11dd83dc0efa86a72b59973dd184371688626305607e8a91 | 23490862 | 4.6.0 | disputeGame | ok | yes | ok | yes (keyed by submitter) |
| U16A_V4_1 | p0 0xd77a26c49c5fb5a858654a4b6c6e11bf7bf001b75acc1410ccc1241605f40b4f | 23874872 | 5.0.0 | disputeGame | ok | yes | ok | yes (keyed by submitter) |
| U17_V5 | p0 0x28ab29aae70e62edbebd3218ef9839cd47f42cd029aeacbf9c4a46e132368586 | 24420749 | 5.1.1 | disputeGame | ok | yes | wrapped tx (not attempted) |  |
| U18_V6 | p0 0x0504d6cf4e05bf00223e7e861d8d38587a53ddb97107aec5f8729df3a4d05417 | 25397165 | 5.2.0 | disputeGame | ok | yes | ok | yes (keyed by submitter) |
| U19_V7 | p0 0x595149fd92329f580955797e2d8fcb8d33b5cd78a6b34dd1b9d0c082220018cb | 26048249 | 5.6.1 | disputeGame | ok | yes | ok | yes (keyed by submitter) |
| U20_V8 | p0 0xcb4d1cae41ae4f41058343d205d1e295eb5e4a55a380f45694e2b88991a1651d | 26429992 | 5.8.0 | disputeGame | ok | yes | ok | yes (keyed by submitter) |
| U21_V9 | p0 0x7232c416e0d7c93aab24d0f1cd561c47319eac04cafad7cb2d2def2f716b7f39 | 26434312 | 6.1.0 | disputeGame | ok | yes | ok | yes (keyed by submitter) |
