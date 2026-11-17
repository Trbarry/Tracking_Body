# Lane 25 chain reads

All RPC operations below were passive reads. Shared forks were never mutated. The primary state boundary is Ethereum block 26430858 (`l1pre`) to the end of block 26430859 (`l1n`); `l1` is block 26433900.

## Proxy and storage boundary

EIP-1967 implementation slot reads:

| Contract | N-1 implementation / version | N implementation / version | Later |
|---|---|---|---|
| OP Mainnet Portal `0xbEb5…06Ed` | `0x1005217ad392dc64cef501fa1777a27d42166748`, `5.8.0` | `0xb20b23af6071405c37ddda0c0640e8ebb7899645`, `6.1.0` | same as N |
| ASR `0x23B2…D113` | `0x8f40cc98d694ab986f026c5383a181fcc9b6b281`, `3.9.0` | `0x2b27299c577d4720100e2735b652444dcea652d0`, `4.0.0` | same as N |
| DGF `0xe596…2fA9` | `0x72b971717e088b59f26d4236be222adb6acd393b`, `1.6.1` | unchanged | unchanged |

The portal's raw slots `0, 50..63` were identical at N-1 and N. In particular, slot 57 (the nested `provenWithdrawals` mapping), slot 60 (`proofSubmitters`), slot 62 (ASR), and slot 63 (lockbox) did not move. The v8 and v9 `snapshots/storageLayout/OptimismPortal2.json` files are byte-identical.

ASR slot 6 was the only lifecycle-relevant raw storage change:

```text
N-1  0x000000000000000000000000000000000000000000000000688271ab00000009
N    0x322b47ff1fa8d5611f761e3e275c45b71b294d4300000000688271ab00000009
```

This preserves respected type 9 and retirement timestamp `1753379243`, while adding the chain lockbox at offset 12. ASR slot 0 preserves the old SystemConfig address as the v9 spacer. The anchor game changed only later, from `0x51024a83…` at N to `0x55A5CFd4…` by block 26433900.

## Real v8 proof preserved at N

`WithdrawalProvenExtension1`:

```text
proof block      26429408 (0x19347e0), before U21
proof tx         0x2ac4751f6b16a0e700be8d8760ef7e474e17dd7cc68871fa46cdfd76168fc2f1
withdrawal hash  0x8df3d52a499b3881a91e2a38a6eb46d136d7b47d5abb52685965acc39b1df241
submitter        0x6A9C2449c32779F89d0CcAfd746152e237c1BDf2
stored game      0xbEc6373FA5B74517350D9CB358a5e7D9F3DaB356
stored timestamp 1794853991
```

At N-1, N, and block 26433900 the packed mapping value was unchanged. At all three snapshots the game was type 9, `status() == IN_PROGRESS`, `createdAt == 1794853667`, `resolvedAt == 0`, `wasRespectedGameTypeWhenCreated == true`, registered and proper. The new delete call at N reverts `OptimismPortal_DisputeGameNotInvalidated`; the mapping and submitter array remain unchanged.

## Real proof made under v8 and finalized under v9

Proof event:

```text
proof block      26377651 (0x1927db3)
proof timestamp  1794231107
proof tx         0x0495619a259beb31bd75aaa56509fe29d3f8cf44a5ea07d1e79c506eec7d97b7
withdrawal hash  0x6d7c43da9a7a7c3ce288cf3c41cbc55644ac6c5128696d4e8ecbaf1243e74af4
submitter        0xBF84721Cc6A0D4895d0f186498C7382c489878E3
stored game      0xFd0C8dD55d270916fb1097C27D217A06162537D6
```

U21 block timestamp was `1794871439`. At N, portal version was `6.1.0`, the proof still pointed to the same game/timestamp, and `finalizedWithdrawals[hash] == false`.

Finalization event:

```text
finalize block   26432294 (0x1935326), after U21
finalize tx      0x734db37e47600647232f304e504850c5532544ca9ccedd4a53487ebf68fb77af
event success    true
```

The transaction calls `finalizeWithdrawalTransactionExternalProof` and explicitly supplies the same proof submitter. At block 26433900, `finalizedWithdrawals[hash] == true` while the proof mapping remains intact. Fork test `test_crossVersionProofFinalizedUnderV9` reproduces the N/later state transition.

## Production game configuration

Unchanged across N-1, N, and later on OP Mainnet:

| Type | implementation | init bond |
|---:|---|---:|
| 0 | zero | 0 |
| 1 | zero | 0 |
| 5 | `0x5C3eb47cB0174aea522a2a9Ae79487139A53D691` | 0 |
| 9 | `0x19AF533Cc2A2A55786DCB8672aA5717e64213208` | `0.08 ether` |

The ASR respected type is 9. Clearing type 0/1 implementation pointers does not alter existing clone code, factory registration records, or the per-game creation-time respect bit.

At N, Soneium's portal is also `6.1.0`; its ASR respects type 5, its DGF type-5 implementation is `0x5C3e…D691`, and its type-5 bond is zero. `SuperPermissionedDisputeGame.initialize` restricts creation to its proposer and immediately fixes status to `DEFENDER_WINS`, so deletion requires a later blacklist.

## Deletion events

There were no `WithdrawalProofDeleted` logs on the OP Mainnet portal from block 26430859 through 26433900.

