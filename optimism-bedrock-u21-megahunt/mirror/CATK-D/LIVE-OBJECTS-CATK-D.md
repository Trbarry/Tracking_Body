# Live objects — CATK-D

All values are passive reads at Ethereum block 26,433,900 unless noted. State-changing calls occurred only inside the local Foundry fork.

## OP Mainnet contracts

| Object | Address / value | Evidence relevant to CATK-D |
|---|---|---|
| OptimismPortal2 proxy | `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` | `version() = 6.1.0`, respected type 9, proof delay 604,800 s, game-finality delay 302,400 s |
| DisputeGameFactory proxy | `0xe5965Ab5962eDc7477C8520243A95517CD252fA9` | `gameCount() = 21,389`; permissionless type-9 creation reproduced |
| AnchorStateRegistry proxy | `0x23B2C62946350F4246f9f9D027e071f0264FD113` | respected type 9; retirement timestamp 1,753,379,243 |
| SystemConfig proxy | `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` | portal source of OP chain ID 10 |
| Type-9 implementation | `0x19AF533Cc2A2A55786DCB8672aA5717e64213208` | `version() = 0.8.0`; init bond 0.08 ETH; max clock 302,400 s; codehash `0xa001bf4f37eca0afb87782c343553ea10ae7e8222b8da5b36bc5e1840698539c` |

Proxy codehashes at the pin are `0x1f958654ab06a152993e7a0ae7b6dbb0d4b19265cc9337b8789fe1353bd9dc35` for the portal proxy and `0xfa8c9db6c6cab7108dea276f4cd09d575674eb0852c0fa3187e59e98ef977998` for the factory/ASR proxy runtime.

## Real invalid game and proof

Factory index 21,288 is game `0xa5714949eb4CD7A9A13adF6854E10a444Ebe3619`:

- status `CHALLENGER_WINS` (1);
- created 1,794,550,859; resolved 1,794,853,307: 302,448 seconds later;
- sequence 2,000,000,000 and root `0xfeca104514ff3df611e1a18755ce30404cc5e3a9080be34dc772a6438d13322a`;
- creator/root claimant `0x7813CC252D34C1f5275A930DF0c308f4cd0B312d`;
- root counterer `0x07b27Bc56ee821e3942B9F6c541027Aee124b9C1`;
- root bond 0.08 ETH; counterer normal-mode credit 0.167594 ETH (therefore at least the root bond).

Fixture `f9.json` is a real 90,000 ETH withdrawal proof bound to this game before it lost. `test_liveChallengerWinsProofIsPermissionlesslyDeletable` deletes that exact live proof from local fork state as an unrelated caller.

## Genuine output-root proof used in the trojan

OP block 159,654,093 (timestamp 1,794,906,963):

- block hash `0x20258d4cae04986a4d3356fd4df51717dee843f6bc36b4ef12504993cccce4d7`;
- state root `0x3e7b8b6fc834bb57f32c62dcb8da803adfaeeb37bb9f99420bdc70f3dacb2fe8`;
- L2ToL1MessagePasser storage root `0x3d89411d2dc3fae78a27b7ded689d8495c79ef79ac9214ad84586457b87cbaab`;
- fixture-f1 withdrawal storage slot `0xbc856e628d55aee9aed0c72e9b242ab9db522b302e1b19b53eb15e9eccc18a9f`, value 1.

The six-node `eth_getProof` response is preserved in `testdata/latest-withdrawal-proof.json`. This proves the malicious game can use the same output root that current tooling recomputes at the game timestamp, rather than an old fixture root paired with a synthetic timestamp.
