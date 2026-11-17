# Lane 23 independent U21 proxy / storage map

This map was reconstructed independently from the 307-log U21 receipt, proxy
implementation slots, version getters, SystemConfig/portal getters, and raw storage
at blocks 26430858 and 26430859. Intermediate implementation
`0x2476c911e6d4d9411e677d8faf15a64ac1fdeee8` is a transaction-local StorageSetter;
the end-of-block implementation and state are controlling.

## Final common implementations relevant to custody

| Contract family | Final implementation | Post version | Boundary observation |
|---|---|---:|---|
| OptimismPortal2 | `0xb20b23af6071405c37ddda0c0640e8ebb7899645` | 6.1.0 | OP pre impl `0x1005217ad392dc64cef501fa1777a27d42166748`, v5.8.0 |
| ETHLockbox | `0xdf75e6b07e98873e36ba5c05508f80c1454e0afe` | 2.0.0 | OP pre impl `0xb3a24db07038b51962026329b62e7a965d56a6ad`, v1.3.1 |
| SystemConfig | `0xade27248542c0f3e89b49e4eb76155e267f14377` | 4.3.0 | OP pre impl `0x670b850a235a6fa98cd7a195eb139d0277e471fa`, v4.0.0 |
| AnchorStateRegistry | `0x2b27299c577d4720100e2735b652444dcea652d0` | 4.0.0 | Now stores its lockbox pointer |
| DisputeGameFactory | `0x72b971717e088b59f26d4236be222adb6acd393b` | 1.6.1 | Implementation unchanged |
| SuperchainConfig | `0xa303a644cfbc0c34f6a9dbeafdeba4c967ea01e7` | 2.5.0 | Shared proxy upgraded once |

The OP L1CrossDomainMessenger version changes 2.11.1 -> 2.13.0 through its
ResolvedDelegateProxy/AddressManager indirection. L1StandardBridge remains version
2.8.2 and its deployed implementation is unchanged; the receipt still runs the
initialization/upgrade choreography across each chain.

## Forty chain-local proxies plus shared SuperchainConfig

| Family | OP | Ink | Soneium | Unichain |
|---|---|---|---|---|
| SystemConfig | `0x229047fed2591dbec1ef1118d64f7af3db9eb290` | `0x62c0a111929fa32cec2f76adba54c16afb6e8364` | `0x7a8ed66b319911a0f3e7288bddab30d9c0c875c3` | `0xc407398d063f942febbcc6f80a156b47f3f1bda6` |
| Portal | `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` | `0x5d66C1782664115999C47c9fA5cd031f495D3e4F` | `0x88e529A6ccd302c948689Cd5156C83D4614FAE92` | `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` |
| Lockbox | `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43` | `0xbd4AbB321138e8Eddc399cE64E66451294325a14` | `0x67B4de6FfA66EF201Ea6099A89cA397D56622E31` | `0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5` |
| ASR | `0x23B2C62946350F4246f9f9D027e071f0264FD113` | `0xEe018bAf058227872540AC60eFbd38b023d9dAe2` | `0x4890928941e62e273dA359374b105F803329F473` | `0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9` |
| DGF | `0xe5965Ab5962eDc7477C8520243A95517CD252fA9` | `0x10d7B35078d3baabB96Dd45a9143B94be65b12CD` | `0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0` | `0x2F12d621a16e2d3285929C9996f478508951dFe4` |

The shared SuperchainConfig proxy is
`0x95703e0982140D16f8ebA6d158FccEde42f04a4C`. The remaining five chain-local
families touched per chain are L1CrossDomainMessenger, L1ERC721Bridge,
L1StandardBridge, OptimismMintableERC20Factory, and DelayedWETH. This lane's value
claims do not depend on their sibling-chain addresses, so they are deliberately not
reproduced here. OP addresses used in tests are L1CrossDomainMessenger
`0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1`, L1StandardBridge
`0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1`, L1ERC721Bridge
`0x5a7749f83b81b301cab5f48eb8516b986daef23d`, mintable factory
`0x75505a97bd334e7bd3c476893285569c4136fa0f`, and DelayedWETH
`0x1b6dbf05eaf22d4e70dc993e8a19dd9f3dcb3162`.

## Raw storage delta accounting

A declared-static-slot scan over all 41 touched proxies found:

- Every lockbox slot 3 changes from zero to the shared SuperchainConfig address.
- Every ASR slot 6 gains its chain's lockbox pointer.
- Every DelayedWETH slot 5 gains its chain's lockbox pointer.
- OP portal slot 1 changes because of the ordinary deposit/resource-metering
  transaction at index 341, before U21; it is not upgrade-created custody state.
- OP messenger slot 205 increments by one from an ordinary cross-domain deposit in
  the same block, not from U21.
- No declared static SystemConfig slot changes N-1 -> N, and no other declared
  static slot in the touched proxies changes.
- DGF mapping state changes for OP game types 5 and 9 and Unichain game type 9;
  Ink and Soneium getter values do not change. These are game configuration writes,
  not ETH custody movement.

Portal/lockbox pointer and authorization are unchanged on all four chains. INTEROP
remains false, so U21 did not run the future shared-lockbox migration.

