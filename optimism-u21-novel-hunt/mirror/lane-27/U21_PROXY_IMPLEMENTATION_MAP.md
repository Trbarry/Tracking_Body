# Lane 27 U21 proxy / game implementation map

Independent reads at Ethereum blocks 26430858 (`l1pre`), 26430859 (`l1n`) and 26433900 (`l1`). Source pin: op-contracts v9.0.0, commit `ba6f...` from `LANE_CONTEXT.md`.

## OP Mainnet core

| Contract | Proxy | N-1 implementation/version | N implementation/version | Later state |
|---|---|---|---|---|
| OptimismPortal2 | `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` | `0x100521...`, 5.8.0 | `0xb20b23af6071405c37ddda0c0640e8ebb7899645`, 6.1.0 | same; ASR `0x23B2...D113`, lockbox `0x322b...4D43` |
| AnchorStateRegistry | `0x23B2C62946350F4246f9f9D027e071f0264FD113` | `0x8f40...`, 3.9.0 | `0x2b27299c577d4720100e2735b652444dcea652d0`, 4.0.0 | respected type 9; retirement 1753379243 |
| DisputeGameFactory | `0xe5965Ab5962eDc7477C8520243A95517CD252fA9` | `0x72b971717e088b59f26d4236be222adb6acd393b`, 1.6.1 | unchanged | count 21389 at later block |
| SystemConfig | `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` | — | `0xade27248542c0f3e89b49e4eb76155e267f14377`, 4.3.0 | chain ID 10; INTEROP false |

Portal state pointers did not change at N. The ASR's legacy SystemConfig slot became a spacer and the new ETHLockbox field was populated; pause, guardian and SuperchainConfig resolution therefore moved to the lockbox (`AnchorStateRegistry.sol:25-60,89-144`).

## Registered games at N

| factory key | source identity | implementation | version | bond | deployed runtime hash |
|---:|---|---|---:|---:|---|
| 5 | `SUPER_PERMISSIONED` (`dispute/lib/Types.sol:68-70`) | `0x5C3eb47cB0174aea522a2a9Ae79487139A53D691` | 1.1.0 | 0 | `0xebf3dbbb410aa4e43f71d535fd6a0562eed700dd0de81cbcec047235889a41c9` |
| 9 | `SUPER_CANNON_KONA` (`dispute/lib/Types.sol:80-82`) | `0x19AF533Cc2A2A55786DCB8672aA5717e64213208` | 0.8.0 | 0.08 ETH | `0xa001bf4f37eca0afb87782c343553ea10ae7e8222b8da5b36bc5e1840698539c` |

Types 0, 1, 4, 6, 7, 8 and 10 were unset. Directly calling `gameType()` on either bare implementation returns zero because that getter reads the CWIA immutable suffix; registered clones report their factory key (last 30 OP games all reported 9).

Type 5 is an exact byte-for-byte runtime match to the v9 `SuperPermissionedDisputeGame` artifact. Type 9 matches the v9 `SuperFaultDisputeGame` artifact after filling its four immutable references with the on-chain getter values: max depth 73, split depth 30, maximum clock 302400, extension 10800. Those values are also asserted through a live clone in `SuperRootPrimitives.t.sol`.

## Packed game args

`LibGameArgs.sol:9-23,61-103,116-143` defines the layouts.

Type 5, 40 bytes:

```text
ASR       0x23B2C62946350F4246f9f9D027e071f0264FD113
proposer  0xc27ba3E0Fc01567a5E57Ae0c391AA98cECBA5bE0
```

Type 9, 124 bytes:

```text
absolutePrestate  0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9
VM                0xaCc005DCd857B401e4732E6F7837135A22825cfA
ASR               0x23B2C62946350F4246f9f9D027e071f0264FD113
DelayedWETH       0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162
l2ChainId         0 (chain IDs are in super-root extraData)
```

At N, only two factory configs changed: type-5 proposer `0x473300df21D047806A082244b417f96b32f13A33 -> 0xc27b...5bE0`, and type-9 absolute prestate `0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df -> 0x03e5...37c9`. Implementations and bonds did not change.

## Soneium comparison

Soneium ASR `0x4890928941e62e273dA359374b105F803329F473` respects type 5. Its DGF `0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0` registers the same type-5 implementation, bond 0, with packed args `(Soneium ASR, proposer 0x00c164c4a8ca84385b70eed6eb03ea847c8e1b8)`; type 9 is unset.
