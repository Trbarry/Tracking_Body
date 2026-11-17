# Lane 26 — independent N-1 to N storage/implementation diff

`StorageDiff.t.sol` compared all ordinary storage slots covering each relevant proxy layout, EIP-1967 implementation slots, SystemConfig deterministic address slots, and the three named feature mapping entries between blocks 26,430,858 and 26,430,859.

| Proxy kind | Implementation before | Implementation after | Relevant data mutation |
|---|---|---|---|
| SuperchainConfig | `0x5570b1f2b97b1e35b5c6f9ee76f6cf02c9917504` | `0xa303a644cfbc0c34f6a9dbeafdeba4c967ea01e7` | No pause timestamp/guardian mutation found |
| SystemConfig (all 4) | `0x670b850a235a6fa98cd7a195eb139d0277e471fa` | `0xade27248542c0f3e89b49e4eb76155e267f14377` | `lastUsedOPCM` only: `0x1951...896a -> 0x2d91...331f` |
| OptimismPortal (all 4) | `0x1005217ad392dc64cef501fa1777a27d42166748` | `0xb20b23af6071405c37ddda0c0640e8ebb7899645` | No pointer/config slot mutation from U21 |
| ETHLockbox (all 4) | `0xb3a24db07038b51962026329b62e7a965d56a6ad` | `0xdf75e6b07e98873e36ba5c05508f80c1454e0afe` | slot 3 populated with common SuperchainConfig |
| AnchorStateRegistry (all 4) | `0x8f40cc98d694ab986f026c5383a181fcc9b6b281` | `0x2b27299c577d4720100e2735b652444dcea652d0` | slot 6 appended each chain's lockbox while preserving packed game state |
| DelayedWETH (all 4) | `0xe440cc08a71694c8229323803f59024e3144630e` | `0xf024e96317907c3b8d8cb346b9fd9034c8640e15` | slot 5 appended each chain's lockbox |

No SystemConfig feature, identity, owner, fee, resource, address, or pause-related field changed. Messenger and bridge cached references did not change.

Two N-1/N differences are unrelated same-block activity, not U21: OP Portal resource-metering slot 1 and OP L1CDM message nonce changed in ordinary deposit transaction `0x762e0faad7b2a2800bb7348e7444a4a0d76b7c5c1b43b84b6bc56c19326cfda2` at transaction index 341. U21 is index 358.

The pointer changes match the v9 initializer design: Lockbox stores SuperchainConfig (`src/L1/ETHLockbox.sol:91-109`), ASR stores lockbox (`src/dispute/AnchorStateRegistry.sol:89-108`), and DelayedWETH stores lockbox (`src/dispute/DelayedWETH.sol:47-64`).
