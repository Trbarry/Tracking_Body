# LIVE OBJECTS — CATK-C

## Fork anchors

| Chain | Local read-only fork | Pinned block | Relevance |
|---|---:|---:|---|
| Ethereum mainnet | `127.0.0.1:8545` | 26,433,900 | Post-Upgrade-21 deployed L1 contracts |
| OP Mainnet | `127.0.0.1:9545` | 159,654,093 | Live L2 message-creation constraints |

Block numbers were confirmed with passive `cast block-number` reads. No state-changing RPC was sent.

## Production objects exercised

| Chain | Object | Address | Passive/deployed evidence | Why it matches |
|---|---|---|---|---|
| L1 | OptimismPortal2 proxy | `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` | version `6.1.0`; ERC-1967 implementation `0xb20b23af6071405c37ddda0c0640e8ebb7899645` | Real withdrawal-finalization entry point and outer `SafeCall` |
| L1 | L1CrossDomainMessenger proxy | `0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1` | version `2.13.0`; proxy code hash `0xb0c4b194c89123018def44d064c2c21146b7d8c673709213a7567f64f5063cb2` | Real relay and replay implementation path |
| L1 | L1StandardBridge proxy | `0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1` | version `2.8.2`; ERC-1967 implementation `0xb37a11aadf167b2f0b8dd85372de4bc66cd4a891` | Deployed `finalizeBridgeETH` consumer |
| L1 | SystemConfig | `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` | Called by deployed portal | Portal dependency |
| L1 | ETHLockbox | `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43` | Called by deployed portal | Value-bearing finalization dependency |
| L1 | AnchorStateRegistry | `0x23B2C62946350F4246f9f9D027e071f0264FD113` | Called by deployed portal | Proof-validity dependency |
| L1 | Resolved game | `0x55A5CFd4270340b3822BB9D8eebdb450ac206f95` | game type `9`, status `2`, `createdAt=1794299939` | Real mature game used by the proof-state vehicle |
| L2 | L2CrossDomainMessenger proxy | `0x4200000000000000000000000000000000000007` | version `2.2.1`; implementation `0x250af3f400cf8aac8d410c90f1ba3968dd87df96` | Live message creator and `baseGas` formula |
| L2 | L2StandardBridge | `0x4200000000000000000000000000000000000010` | Encoded as the authenticated bridge sender | Real bridge authentication precondition |

The L2 messenger live getters returned `200000`, `40000`, `40000`, and `5000` for constant overhead, call overhead, reserved gas, and check buffer. `baseGas("",0)` returned `310160`.

New-account fixture `0xb2eDE3e5C0cAe13eF1EBA58B223f3bfFC6F856e2` had code `0x`, balance `0`, and nonce `0` at L1 block 26,433,900.

All address calls in `GasCapCATKC.t.sol` execute deployed proxy/delegate bytecode. The only synthetic object is the local `BurnAllGas` target, used solely to model a target that consumes its entire allowance.

