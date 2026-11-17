# Lane 30 — OP Mainnet final implementation map

Read with ProxyAdmin `0x543bA4AADBAb8f9025686Bd03993043599c6fB04` via `getProxyImplementation(address)` at N−1 `26430858`, N `26430859`, and later `26433900`. The allowed U21 receipt has 307 logs, including 132 `Upgraded(address)` logs: intermediate StorageSetter/install/restore events across four chains are not final state.

| Proxy | type | N−1 implementation / version | N implementation / version | Final changed? |
|---|---|---|---|---|
| SuperchainConfig `0x95703e0982140D16f8ebA6d158FccEde42f04a4C` | EIP-1967 | `0x5570b1f2b97B1E35b5C6f9Ee76f6cf02c9917504`, 2.4.3 | `0xA303a644cfbC0c34f6a9dBEaFdebA4C967EA01e7`, 2.5.0 | yes |
| SystemConfig `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` | EIP-1967 | `0x670b850A235A6fA98cD7a195eB139D0277E471fA`, 4.0.0 | `0xADe27248542c0F3E89b49e4eB76155e267F14377`, 4.3.0 | yes |
| Portal `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` | EIP-1967 | `0x1005217ad392DC64CEf501FA1777A27D42166748`, 5.8.0 | `0xb20B23af6071405C37dDDA0C0640e8eBb7899645`, 6.1.0 | yes |
| ETHLockbox `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43` | EIP-1967 | `0xb3A24DB07038b51962026329B62E7a965d56A6ad`, 1.3.1 | `0xDF75E6b07E98873E36BA5c05508F80c1454e0aFe`, 2.0.0 | yes |
| L1ERC721Bridge `0x5a7749f83b81b301cab5f48eb8516b986daef23d` | EIP-1967 | `0x9F164f1d02A81e06D639E55F65a87f0070E3Cb2e`, 2.9.1 | same | no; upgrade choreography only |
| MintableERC20Factory `0x75505a97BD334E7BD3C476893285569C4136Fa0F` | EIP-1967 | `0xaAbEA75Da509fA518Fd8a91Eae4BE5813B829b12`, 1.11.0 | same | no |
| DisputeGameFactory `0xe5965Ab5962eDc7477C8520243A95517CD252fA9` | EIP-1967 | `0x72B971717E088B59F26d4236BE222ADB6ACD393b`, 1.6.1 | same | no; type-9 args changed |
| DelayedWETH `0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162` | EIP-1967 | `0xE440CC08A71694C8229323803F59024E3144630e`, 1.5.1 | `0xF024e96317907C3b8d8CB346B9FD9034c8640e15`, 2.0.0 | yes |
| AnchorStateRegistry `0x23B2C62946350F4246f9f9D027e071f0264FD113` | EIP-1967 | `0x8F40Cc98D694AB986F026C5383A181FCc9B6B281`, 3.9.0 | `0x2b27299C577d4720100e2735b652444DcEa652D0`, 4.0.0 | yes |
| L1CrossDomainMessenger `0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1` | ResolvedDelegateProxy | `0x59D497530b00062f40950ba8EaB88868bf7F86f0`, 2.11.1 | `0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448`, 2.13.0 | yes |
| L1StandardBridge `0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1` | ChugSplash | `0xB37a11AadF167B2F0b8dD85372De4bC66CD4A891`, 2.8.2 | same | no |

All N implementations above remained identical at block 26433900. ProxyAdmin and all four tested proxy families resolve owner Safe `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`.

Source routing: `ProxyAdmin.sol:104-130,149-166`; old Chug implementation/owner slots `L1ChugSplashProxy.sol:155-169,199-218`; Resolved proxy name lookup `ResolvedDelegateProxy.sol` plus AddressManager. The final-state distinction matters because a raw receipt-log map would falsely label unchanged proxies as implementation changes.
