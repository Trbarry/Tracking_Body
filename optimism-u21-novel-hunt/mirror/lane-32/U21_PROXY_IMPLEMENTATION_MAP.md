# Lane 32 independent Upgrade 21 proxy/implementation map

Boundary: Ethereum blocks 26430858 (N-1) and 26430859 (N). Evidence is the supplied upgrade receipt plus `mirror/lane-32/test/StateDiff.t.sol`. Every EIP-1967 admin slot read was unchanged.

## Final implementation changes

| Contract class | v8 / N-1 implementation | v9 / N implementation | Result |
|---|---|---|---|
| SuperchainConfig | `0x5570b1f2b97b1e35b5c6f9ee76f6cf02c9917504` | `0xa303a644cfbc0c34f6a9dbeafdeba4c967ea01e7` | changed |
| SystemConfig | `0x670b850a235a6fa98cd7a195eb139d0277e471fa` | `0xade27248542c0f3e89b49e4eb76155e267f14377` | changed on all four chains |
| OptimismPortal2 | `0x1005217ad392dc64cef501fa1777a27d42166748` | `0xb20b23af6071405c37ddda0c0640e8ebb7899645` | changed on all four chains |
| ETHLockbox | `0xb3a24db07038b51962026329b62e7a965d56a6ad` | `0xdf75e6b07e98873e36ba5c05508f80c1454e0afe` | changed on all four chains |
| DelayedWETH | `0xe440cc08a71694c8229323803f59024e3144630e` | `0xf024e96317907c3b8d8cb346b9fd9034c8640e15` | changed on all four chains |
| AnchorStateRegistry | `0x8f40cc98d694ab986f026c5383a181fcc9b6b281` | `0x2b27299c577d4720100e2735b652444dcea652d0` | changed on all four chains |
| L1ERC721Bridge | `0x9f164f1d...` | same | StorageSetter hop only |
| OptimismMintableERC20Factory | `0xaabea75d...` | same | StorageSetter hop only |
| DisputeGameFactory | `0x72b971...` | same | StorageSetter hop only |

The receipt shows an intermediate StorageSetter implementation (`0x2476c911...`) and restoration/final implementation for each of the 33 proxies. A receipt `Upgraded` event is therefore not by itself a final implementation change.

## Proxy set

| Chain | SystemConfig | Portal | Lockbox | L1ERC721Bridge | Mintable factory | DGF | DelayedWETH | ASR |
|---|---|---|---|---|---|---|---|---|
| OP | `0x229047fe...` | `0xbEb5Fc57...` | `0x322b47Ff...` | `0x5a7749f8...` | `0x75505a97...` | `0xe5965Ab5...` | `0x1B6DBF05...` | `0x23B2C629...` |
| Ink | `0x62C0a111...` | `0x5d66C178...` | `0xbd4AbB32...` | `0x661235a2...` | `0xA8B389A8...` | `0x10d7B350...` | `0x57b4C29D...` | `0xEe018bAf...` |
| Soneium | `0x7A8Ed66B...` | `0x88e529A6...` | `0x67B4de6F...` | `0x5933e323...` | `0xc1047e30...` | `0x512A3d2c...` | `0x18fBb58C...` | `0x48909289...` |
| Unichain | `0xc407398d...` | `0x0bd48f6B...` | `0x08bA0023...` | `0xD04D0D87...` | `0xA2B597Ea...` | `0x2F12d621...` | `0x74ad145a...` | `0x27Cf508E...` |

Shared SuperchainConfig proxy: `0x95703e0982140D16f8ebA6d158FccEde42f04a4C`.

## Linear-state changes at N

- Each ETHLockbox slot 3 changed from zero to the shared SuperchainConfig.
- Each DelayedWETH slot 5 changed from zero to its chain's ETHLockbox.
- Each AnchorStateRegistry slot 6 gained its chain's ETHLockbox in the high 20 bytes; the existing retirement timestamp and respected game type remained intact.
- OP Portal slot 1 (resource metering parameters) advanced during the upgrade transaction; no pointer/configuration delta was found there.
- No other selected layout slot changed. Getter checks confirm `ETH_LOCKBOX=true`, `INTEROP=false`, and portal authorization on all four lockboxes.

## Bounded N-to-26433900 observations

No implementation/config correction was observed. Portal balances remained zero. Lockbox balances, DGF game counts, DelayedWETH balances, and current anchor games changed only in patterns consistent with ordinary deposits, game creation/bonds, and anchor advancement. Detailed values are in `LANE-32-report.md`.
