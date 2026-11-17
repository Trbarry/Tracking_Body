# U21 initializer calls — mirror lane 21

This is the exact `ProxyAdmin.upgradeAndCall` sequence extracted from the executed call trace. Raw calldata and structured values are in [decoded-initializers.json](artifacts/decoded-initializers.json); the outer Safe/aggregate/OPCM inputs are in [decoded-transaction.json](artifacts/decoded-transaction.json).

## OPCM inputs

The Safe delegatecalled `0x93dc480940585D9961bfcEab58124fFD3d60f76a.aggregate3`, whose five entries all targeted OPCMv2 `0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f` with `allowFailure=false`:

1. `upgradeSuperchain((address,(string,bytes)[]))`: SuperchainConfig `0x95703e0982140D16f8ebA6d158FccEde42f04a4C`; no extra instructions.
2. OP Mainnet `upgrade`: SystemConfig `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290`.
3. Ink `upgrade`: SystemConfig `0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364`.
4. Soneium `upgrade`: SystemConfig `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3`.
5. Unichain `upgrade`: SystemConfig `0xc407398d063f942feBbcC6F80a156b47F3f1BDA6`.

For all four chain upgrades, game types 0, 1, 8, and 10 were disabled with zero bond/empty args. Type 5 was enabled with zero bond and proposer respectively `0xc27ba3e0fc01567a5e57ae0c391aa98cecba5be0`, `0x3832bfbef03173e4c49a00ec0dd178817a02d177`, `0x400c164c4a8ca84385b70eed6eb03ea847c8e1b8`, and `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7`. Type 9 was enabled on OP/Ink/Unichain with bond `80000000000000000` wei and prestate `0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9`; it was disabled on Soneium. The respected-type override was 9/9/5/9. Each call also supplied `PermittedProxyDeployment = bytes("ETHLockbox") = 0x4554484c6f636b626f78`. OPCMv2 validates and applies these at `OPContractsManagerV2.sol:684-796` and `:961-996`.

## Exact initializer sequence

| # | Chain | Contract / target | initializer | exact decoded arguments | init byte pre→post |
|---:|---|---|---|---|---:|
| 0 | Superchain | `SuperchainConfig`<br>`0x95703e0982140D16f8ebA6d158FccEde42f04a4C` | `initialize(address)` | `["0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2"]` | 2→2 |
| 1 | OP Mainnet | `SystemConfig`<br>`0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` | `initialize(address,uint32,uint32,bytes32,uint64,address,(uint32,uint8,uint8,uint32,uint32,uint128),(address,address,address,address,address,address,address),uint256,address)` | `["0x847B5c174615B1B7fDF770882256e2D3E95b9D92",5227,1014213,"0x0000000000000000000000006887246668a3b87f54deb3b94ba47a6f63f32985",40000000,"0xAAAA45d9549EDA09E70937013520214382Ffc4A2",[20000000,10,8,1000000000,1000000,"340282366920938463463374607431768211455"],["0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1","0x5a7749f83b81B301cAb5f48EB8516B986DAef23D","0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1","0xbEb5Fc579115071764c7423A4f12eDde41f106Ed","0x75505a97BD334E7BD3C476893285569C4136Fa0F","0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162","0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f"],10,"0x95703e0982140D16f8ebA6d158FccEde42f04a4C"]` | 3→3 |
| 2 | OP Mainnet | `OptimismPortal2`<br>`0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` | `initialize(address,address,address)` | `["0x229047fed2591dbec1eF1118d64F7aF3dB9EB290","0x23B2C62946350F4246f9f9D027e071f0264FD113","0x322b47Ff1FA8D5611F761e3E275C45B71b294D43"]` | 3→3 |
| 3 | OP Mainnet | `ETHLockbox`<br>`0x322b47Ff1FA8D5611F761e3E275C45B71b294D43` | `initialize(address,address[])` | `["0x95703e0982140D16f8ebA6d158FccEde42f04a4C",["0xbEb5Fc579115071764c7423A4f12eDde41f106Ed"]]` | 1→1 |
| 4 | OP Mainnet | `L1CrossDomainMessenger`<br>`0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1` | `initialize(address,address)` | `["0x229047fed2591dbec1eF1118d64F7aF3dB9EB290","0xbEb5Fc579115071764c7423A4f12eDde41f106Ed"]` | 3→3 |
| 5 | OP Mainnet | `L1StandardBridge`<br>`0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1` | `initialize(address,address)` | `["0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1","0x229047fed2591dbec1eF1118d64F7aF3dB9EB290"]` | 3→3 |
| 6 | OP Mainnet | `L1ERC721Bridge`<br>`0x5a7749f83b81B301cAb5f48EB8516B986DAef23D` | `initialize(address,address)` | `["0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1","0x229047fed2591dbec1eF1118d64F7aF3dB9EB290"]` | 3→3 |
| 7 | OP Mainnet | `OptimismMintableERC20Factory`<br>`0x75505a97BD334E7BD3C476893285569C4136Fa0F` | `initialize(address)` | `["0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1"]` | 1→1 |
| 8 | OP Mainnet | `DisputeGameFactory`<br>`0xe5965Ab5962eDc7477C8520243A95517CD252fA9` | `initialize(address)` | `["0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A"]` | 1→1 |
| 9 | OP Mainnet | `DelayedWETH`<br>`0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162` | `initialize(address)` | `["0x322b47Ff1FA8D5611F761e3E275C45B71b294D43"]` | 1→1 |
| 10 | OP Mainnet | `AnchorStateRegistry`<br>`0x23B2C62946350F4246f9f9D027e071f0264FD113` | `initialize(address,address,(bytes32,uint256),uint32)` | `["0x322b47Ff1FA8D5611F761e3E275C45B71b294D43","0xe5965Ab5962eDc7477C8520243A95517CD252fA9",["0xbd4aeba96e33ef5582e14257fb776b3223ad45934ccd368c2f3084c8b75c1d68",1788842855],9]` | 1→1 |
| 11 | Ink | `SystemConfig`<br>`0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364` | `initialize(address,uint32,uint32,bytes32,uint64,address,(uint32,uint8,uint8,uint32,uint32,uint128),(address,address,address,address,address,address,address),uint256,address)` | `["0x847B5c174615B1B7fDF770882256e2D3E95b9D92",4424,810831,"0x0000000000000000000000006db6161fc5662450e801398bad62dd9921216b98",30000000,"0x7b322282DF45E537E5de76D60E1432Db3cF3F8E1",[20000000,10,8,1000000000,1000000,"340282366920938463463374607431768211455"],["0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f","0x661235a238B11191211fa95D4Dd9E423d521E0Be","0x88FF1e5b602916615391F55854588EFcBB7663f0","0x5d66C1782664115999C47c9fA5cd031f495D3e4F","0xA8B389A82e088b164cD03230e900980CcED34d29","0x57b4C29DAee99a28E6E86778b499361294c134eA","0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f"],57073,"0x95703e0982140D16f8ebA6d158FccEde42f04a4C"]` | 3→3 |
| 12 | Ink | `OptimismPortal2`<br>`0x5d66C1782664115999C47c9fA5cd031f495D3e4F` | `initialize(address,address,address)` | `["0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364","0xEe018bAf058227872540AC60eFbd38b023d9dAe2","0xbd4AbB321138e8Eddc399cE64E66451294325a14"]` | 3→3 |
| 13 | Ink | `ETHLockbox`<br>`0xbd4AbB321138e8Eddc399cE64E66451294325a14` | `initialize(address,address[])` | `["0x95703e0982140D16f8ebA6d158FccEde42f04a4C",["0x5d66C1782664115999C47c9fA5cd031f495D3e4F"]]` | 1→1 |
| 14 | Ink | `L1CrossDomainMessenger`<br>`0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f` | `initialize(address,address)` | `["0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364","0x5d66C1782664115999C47c9fA5cd031f495D3e4F"]` | 3→3 |
| 15 | Ink | `L1StandardBridge`<br>`0x88FF1e5b602916615391F55854588EFcBB7663f0` | `initialize(address,address)` | `["0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f","0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364"]` | 3→3 |
| 16 | Ink | `L1ERC721Bridge`<br>`0x661235a238B11191211fa95D4Dd9E423d521E0Be` | `initialize(address,address)` | `["0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f","0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364"]` | 3→3 |
| 17 | Ink | `OptimismMintableERC20Factory`<br>`0xA8B389A82e088b164cD03230e900980CcED34d29` | `initialize(address)` | `["0x88FF1e5b602916615391F55854588EFcBB7663f0"]` | 1→1 |
| 18 | Ink | `DisputeGameFactory`<br>`0x10d7B35078d3baabB96Dd45a9143B94be65b12CD` | `initialize(address)` | `["0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A"]` | 1→1 |
| 19 | Ink | `DelayedWETH`<br>`0x57b4C29DAee99a28E6E86778b499361294c134eA` | `initialize(address)` | `["0xbd4AbB321138e8Eddc399cE64E66451294325a14"]` | 1→1 |
| 20 | Ink | `AnchorStateRegistry`<br>`0xEe018bAf058227872540AC60eFbd38b023d9dAe2` | `initialize(address,address,(bytes32,uint256),uint32)` | `["0xbd4AbB321138e8Eddc399cE64E66451294325a14","0x10d7B35078d3baabB96Dd45a9143B94be65b12CD",["0x25b22a0c711fa1d01b3cdb95fb98c0e7ff003b00909bfe8fade3507a6e62d44e",1788848282],9]` | 1→1 |
| 21 | Soneium | `SystemConfig`<br>`0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3` | `initialize(address,uint32,uint32,bytes32,uint64,address,(uint32,uint8,uint8,uint32,uint32,uint128),(address,address,address,address,address,address,address),uint256,address)` | `["0x509182eC226b3B71D36A3255A80EF0b1A9D43033",9736,1540079,"0x0000000000000000000000006776be80dbada6a02b5f2095cf13734ac303b8d1",40000000,"0x7c2Bd59ee2a2C7391c9A240132f26071e9546262",[20000000,10,8,1000000000,1000000,"340282366920938463463374607431768211455"],["0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f","0x5933e323bE8896DfaCd1cD671442F27dAA10a053","0xeb9bf100225c214Efc3E7C651ebbaDcF85177607","0x88e529A6ccd302c948689Cd5156C83D4614FAE92","0xc1047e30EFC9E172cFe7aa0219895B6a43fC415F","0x18fBb58C366e21F395DdEc7cBa0510a2D9116B47","0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f"],1868,"0x95703e0982140D16f8ebA6d158FccEde42f04a4C"]` | 3→3 |
| 22 | Soneium | `OptimismPortal2`<br>`0x88e529A6ccd302c948689Cd5156C83D4614FAE92` | `initialize(address,address,address)` | `["0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3","0x4890928941e62e273dA359374b105F803329F473","0x67B4de6FfA66EF201Ea6099A89cA397D56622E31"]` | 3→3 |
| 23 | Soneium | `ETHLockbox`<br>`0x67B4de6FfA66EF201Ea6099A89cA397D56622E31` | `initialize(address,address[])` | `["0x95703e0982140D16f8ebA6d158FccEde42f04a4C",["0x88e529A6ccd302c948689Cd5156C83D4614FAE92"]]` | 1→1 |
| 24 | Soneium | `L1CrossDomainMessenger`<br>`0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f` | `initialize(address,address)` | `["0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3","0x88e529A6ccd302c948689Cd5156C83D4614FAE92"]` | 3→3 |
| 25 | Soneium | `L1StandardBridge`<br>`0xeb9bf100225c214Efc3E7C651ebbaDcF85177607` | `initialize(address,address)` | `["0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f","0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3"]` | 3→3 |
| 26 | Soneium | `L1ERC721Bridge`<br>`0x5933e323bE8896DfaCd1cD671442F27dAA10a053` | `initialize(address,address)` | `["0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f","0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3"]` | 3→3 |
| 27 | Soneium | `OptimismMintableERC20Factory`<br>`0xc1047e30EFC9E172cFe7aa0219895B6a43fC415F` | `initialize(address)` | `["0xeb9bf100225c214Efc3E7C651ebbaDcF85177607"]` | 1→1 |
| 28 | Soneium | `DisputeGameFactory`<br>`0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0` | `initialize(address)` | `["0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A"]` | 1→1 |
| 29 | Soneium | `DelayedWETH`<br>`0x18fBb58C366e21F395DdEc7cBa0510a2D9116B47` | `initialize(address)` | `["0x67B4de6FfA66EF201Ea6099A89cA397D56622E31"]` | 1→1 |
| 30 | Soneium | `AnchorStateRegistry`<br>`0x4890928941e62e273dA359374b105F803329F473` | `initialize(address,address,(bytes32,uint256),uint32)` | `["0x67B4de6FfA66EF201Ea6099A89cA397D56622E31","0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0",["0x08a53686fd0b1671ff7b89c3a994582503f15f7be00f0f2e7c9f0d3b187ab124",1788848425],5]` | 1→1 |
| 31 | Unichain | `SystemConfig`<br>`0xc407398d063f942feBbcC6F80a156b47F3f1BDA6` | `initialize(address,uint32,uint32,bytes32,uint64,address,(uint32,uint8,uint8,uint32,uint32,uint128),(address,address,address,address,address,address,address),uint256,address)` | `["0x847B5c174615B1B7fDF770882256e2D3E95b9D92",2000,900000,"0x0000000000000000000000009ef649e8746cc47a17708a5e86b2d66c7f6c00d1",60000000,"0xFaACA0A10e4a23C5E01485DE07767547d4D8056D",[20000000,10,8,1000000000,1000000,"340282366920938463463374607431768211455"],["0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6","0xD04D0D87E0bd4D2E50286760a3EF323FeA6849Cf","0x81014F44b0a345033bB2b3B21C7a1A308B35fEeA","0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2","0xA2B597EaeAcb6F627e088cbEaD319e934ED5edad","0x74ad145aC900F1DD5551F0C9E143314DC4022FCf","0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f"],130,"0x95703e0982140D16f8ebA6d158FccEde42f04a4C"]` | 3→3 |
| 32 | Unichain | `OptimismPortal2`<br>`0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` | `initialize(address,address,address)` | `["0xc407398d063f942feBbcC6F80a156b47F3f1BDA6","0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9","0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5"]` | 3→3 |
| 33 | Unichain | `ETHLockbox`<br>`0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5` | `initialize(address,address[])` | `["0x95703e0982140D16f8ebA6d158FccEde42f04a4C",["0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2"]]` | 1→1 |
| 34 | Unichain | `L1CrossDomainMessenger`<br>`0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6` | `initialize(address,address)` | `["0xc407398d063f942feBbcC6F80a156b47F3f1BDA6","0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2"]` | 3→3 |
| 35 | Unichain | `L1StandardBridge`<br>`0x81014F44b0a345033bB2b3B21C7a1A308B35fEeA` | `initialize(address,address)` | `["0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6","0xc407398d063f942feBbcC6F80a156b47F3f1BDA6"]` | 3→3 |
| 36 | Unichain | `L1ERC721Bridge`<br>`0xD04D0D87E0bd4D2E50286760a3EF323FeA6849Cf` | `initialize(address,address)` | `["0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6","0xc407398d063f942feBbcC6F80a156b47F3f1BDA6"]` | 3→3 |
| 37 | Unichain | `OptimismMintableERC20Factory`<br>`0xA2B597EaeAcb6F627e088cbEaD319e934ED5edad` | `initialize(address)` | `["0x81014F44b0a345033bB2b3B21C7a1A308B35fEeA"]` | 1→1 |
| 38 | Unichain | `DisputeGameFactory`<br>`0x2F12d621a16e2d3285929C9996f478508951dFe4` | `initialize(address)` | `["0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A"]` | 1→1 |
| 39 | Unichain | `DelayedWETH`<br>`0x74ad145aC900F1DD5551F0C9E143314DC4022FCf` | `initialize(address)` | `["0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5"]` | 1→1 |
| 40 | Unichain | `AnchorStateRegistry`<br>`0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9` | `initialize(address,address,(bytes32,uint256),uint32)` | `["0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5","0x2F12d621a16e2d3285929C9996f478508951dFe4",["0xaf64a866304eb17696278d26290bb172aa941eac3370d9bc8bd313d492beb7d3",1788848651],9]` | 1→1 |

## SystemConfig tuple labels

The long SystemConfig argument order is: owner; basefee scalar; blob-basefee scalar; batcher hash; gas limit; unsafe signer; resource config `[maxResourceLimit, elasticityMultiplier, baseFeeMaxChangeDenominator, minimumBaseFee, systemTxMaxGas, maximumBaseFee]`; addresses `[messenger, ERC721 bridge, standard bridge, portal, mintable factory, DelayedWETH, OPCM]`; L2 chain ID; shared SuperchainConfig. The initializer writes exactly those fields at `SystemConfig.sol:203-248`, while the dispute-game factory reference remains in its established slot and was independently checked through its getter.

## Initializer guards and implementation locks

Every reinitializer checks that the call comes from its ProxyAdmin or ProxyAdmin owner. The relevant constructor/initializer ranges are: SuperchainConfig `:59-67`; SystemConfig `:186-219`; OptimismPortal2 `:265-282`; ETHLockbox `:87-102`; L1CrossDomainMessenger `:80-89`; L1StandardBridge `:97-112`; L1ERC721Bridge `:43-58`; OptimismMintableERC20Factory `:59-66`; DisputeGameFactory `:82-94`; DelayedWETH `:51-60`; AnchorStateRegistry `:84-104`. Each constructor disables initializers. On-chain, all 41 proxy initializer bytes were unchanged N-1→N and every distinct final implementation had `0xff` at its correct initializer byte (messenger offset 20; all others offset 0). Fork test `test_proxyAndImplementationInitializersAreNotReRunnable` confirms both proxy and singleton calls revert.

## StorageSetter writes and four transitions

For every target, Utils first installs StorageSetter, reads slot 0, and writes

`slot0 := slot0 & ~(0xff << (8 * offset))`.

Offset is 20 only for the resolved messenger and 0 for every other target. It then installs the selected implementation with the initializer calldata above, re-installs StorageSetter to verify the OZ-v5 Initializable namespace is still zero, and finally restores the selected implementation without calldata. The exact logic is `OPContractsManagerUtils.sol:352-386`; the messenger offset selection is `OPContractsManagerV2.sol:899-908`. The second setter pass is a read/check, not another arbitrary data mutation. Raw pre/post slot-0 words are in [proxy-implementation-map.json](artifacts/proxy-implementation-map.json).

## Postconditions

No implementation singleton was left initializable. No proxy initializer became publicly re-runnable. All 283 zero-input address getters, the four-by-four portal authorization matrix, and the lockbox authorization matrix matched the intended same-chain/shared wiring at N and later; see [post-upgrade-wiring.json](artifacts/post-upgrade-wiring.json).

