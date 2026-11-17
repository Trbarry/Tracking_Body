# Lane 31 U21 proxy and state map

All values below were independently read with passive `cast` calls from exact state N-1 (`:8546`), N (`:8547`), and later post (`:8545`). Complete unabridged output is `onchain-state-reads.txt`.

## Relevant proxy implementations

| Proxy | N-1 implementation | N implementation | Later post | Observation |
|---|---|---|---|---|
| OptimismPortal2 `0xbEb5...106Ed` | `0x1005217ad392dc64cef501fa1777a27d42166748` | `0xb20b23af6071405c37ddda0c0640e8ebb7899645` | same as N | `5.8.0 -> 6.1.0` |
| SystemConfig `0x2290...B290` | `0x670b850a235a6fa98cd7a195eb139d0277e471fa` | `0xade27248542c0f3e89b49e4eb76155e267f14377` | same | upgraded |
| ETHLockbox `0x322b...4D43` | `0xb3a24db07038b51962026329b62e7a965d56a6ad` | `0xdf75e6b07e98873e36ba5c05508f80c1454e0afe` | same | `1.3.1 -> 2.0.0` |
| AnchorStateRegistry `0x23B2...D113` | `0x8f40cc98d694ab986f026c5383a181fcc9b6b281` | `0x2b27299c577d4720100e2735b652444dcea652d0` | same | upgraded |
| DisputeGameFactory `0xe596...fA9` | `0x72b971717e088b59f26d4236be222adb6acd393b` | same | same | no implementation change |
| SuperchainConfig `0x9570...4a4C` | `0x5570b1f2b97b1e35b5c6f9ee76f6cf02c9917504` | `0xa303a644cfbc0c34f6a9dbeafdeba4c967ea01e7` | same | upgraded |
| L1CrossDomainMessenger `0x25ac...fA1` | AddressManager target `0x59D497530b00062f40950ba8EaB88868bf7F86f0` | `0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448` | same | `2.11.1 -> 2.13.0` |

The messenger is a `ResolvedDelegateProxy`, not EIP-1967: its fallback resolves `OVM_L1CrossDomainMessenger` through AddressManager (`/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/legacy/ResolvedDelegateProxy.sol:12-40`). The AddressManager was read at `0xdE1FCfB0851916CA5101820A69b13a4E276bd81F`.

## Relevant exact storage and configuration

| Read | N-1 | N | Interpretation |
|---|---|---|---|
| Portal slot 0 | `0x...03` | same | initializer state unchanged |
| Portal slot 1 | `0x0000000001934d6e000000000007e376...3b9aca00` | `0x0000000001934d8b000000000007df76...3b9aca00` | resource-metering previous block/base gas fields advanced during upgrade |
| Portal ETHLockbox | `0x322b...4D43` | same | OP already used this lockbox |
| Portal SuperchainConfig | `0x9570...4a4C` | same | wiring preserved |
| Portal guardian | `0x09f7...dAf2` | same | getter existed on both versions and resolves same guardian |
| Lockbox slot 0 | `0x...229047...b2900001` | same | legacy SystemConfig/initialization packing preserved |
| Lockbox slot 3 | zero | `0x...95703e...f04a4c` | new SuperchainConfig pointer initialized |
| Lockbox authorized portal | true | true | custody authority preserved |
| `ETH_LOCKBOX` feature | true | true | already active before U21 |
| `INTEROP` / `CUSTOM_GAS_TOKEN` at N | n/a | false / false | no interop migration, ordinary ETH mode |
| Portal balance | 0 | 0 | no portal custody migration for OP |
| Lockbox balance | 182416306525160721816415 | 182420511216757812708529 | ordinary intervening bridge flows; no portal balance moved |

At N, `paused()` is false on portal and lockbox. Guardian and SuperchainConfig resolve through the new lockbox configuration. V9 portal pause getters are at `OptimismPortal2.sol:304-329`; lockbox pause/guardian at `ETHLockbox.sol:111-121`.

## Messenger constants across L1 and L2

Public alias getters and `baseGas(0x,200000)` are identical before and after U21 and on live OP Mainnet L2:

| Endpoint | Version | Constant / call / reserved / buffer | `baseGas` |
|---|---|---|---:|
| L1 N-1 | 2.11.1 | 200000 / 40000 / 40000 / 5000 | 513334 |
| L1 N | 2.13.0 | 200000 / 40000 / 40000 / 5000 | 513334 |
| L2 live | 2.2.1 | 200000 / 40000 / 40000 / 5000 | 513334 |

This does not mean local execution reserves stayed unchanged. V9 intentionally splits local from remote and uses L1-local 135,000/15,000 internally while preserving the remote aliases (`L1CrossDomainMessenger.sol:43-74,117-152`; `GasConstants.sol:49-78`).

## N -> later post

No listed implementation changed between N and block 26433900. Lockbox balance increased through ordinary activity. The core tests therefore use N for exact upgrade differentials and the later fork for newly proved post-U21 fixtures.
