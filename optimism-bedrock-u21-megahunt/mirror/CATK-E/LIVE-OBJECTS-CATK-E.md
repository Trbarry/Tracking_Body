# CATK-E live-object census

Pinned state: Ethereum block `26433900`, timestamp `2026-11-17T09:34:35Z`, hash
`0xf5b501c77cfc14ad3f0ea6a0ba2a7b91b510bab4bc91de5da99b052aa257507e`.
All reads were passive against the shared fork. All mutations below were executed only inside
Foundry-local fork state.

## Planned migration actors

| Role | Address | Pinned fact |
|---|---|---|
| OPCM | `0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f` | `version() = 9.0.3` |
| ProxyAdmin-owner Safe | `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` | sole modeled privileged caller; used only for the documented delegatecall |
| OP SystemConfig | `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` | L2 chain ID 10 |
| Unichain SystemConfig | `0xc407398d063f942feBbcC6F80a156b47F3f1BDA6` | L2 chain ID 130 |

## ASR and factory lineage

| Chain | Generation | ASR | Version | Factory/game range | Attacker-relevant state |
|---|---|---|---|---|---|
| OP | gen 1 | `0x18DAc71c228D1C32c99489B7323d441E1175e443` | 2.0.0 | DGF `0xe5965Ab5962eDc7477C8520243A95517CD252fA9`, 0..7109 | `tryUpdateAnchorState` requires the registered game itself as caller; guardian-only `setAnchorState` |
| OP | gen 2 | `0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b` | 2.2.2 | same DGF, 7110..9827 | public `setAnchorState`; moved from sequence `138585637` to `155450031` with live type-8 game `0x4ffb1A59A7D81876377A74b59869670d8192abFf` |
| OP | live | `0x23B2C62946350F4246f9f9D027e071f0264FD113` | 4.0.0 | same DGF, 9828..21388 | public `setAnchorState` for a finalized newer game; slot 2 is `anchorGame` |
| Unichain | gen 1 | `0x318a642db9e24a85318b8bf18efd5287ba38643b` | 2.0.0 | DGF `0x2F12d621a16e2d3285929C9996f478508951dFe4`, 0..3730 | same game-caller/guardian barriers |
| Unichain | gen 2 | `0xd5d0e176be44e61eab3cf1fa8153758df603376f` | 2.2.2 | same DGF, 3731..6185 | moved from sequence `22024228` to `58101694` with live type-8 game `0x6426Ea5B64172568F6544583D4aa65c67FC01d6a` |
| Unichain | live | `0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9` | 4.0.0 | same DGF, 6186..17690 | same public finalized-game update path |

Both gen-2 registries return `true` from `isGameClaimValid` for the live type-9 anchor game, but
`setAnchorState` reverts because v2.2.2 calls the legacy `l2BlockNumber()` selector while type-9
Super games expose `l2SequenceNumber()`. The type-8 games above prove that the registries are still
permissionlessly writable through a selector-compatible candidate.

At the pinned block both factories have type 9 registered with a `0.08 ETH` initial bond. Types 0
and 1 are unset; attacker `create(0,...)` and `create(1,...)` revert. Type 5 is registered, but an
ordinary attacker's clone initialization rejects the non-proposer origin. Factory setters remain
owner-only.

## Portals and ETHLockboxes

| Chain | Portal | Current lockbox | Pinned balance |
|---|---|---|---:|
| OP | `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` | `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43` | about 182,541.068 ETH |
| Unichain | `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` | `0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5` | about 18,266.158 ETH |

Permissionless state tested: portal deposits, portal donations, fabricated proof records backed by
attacker-created games, and forced ETH to portals/lockboxes. Direct lockbox `lockETH`,
`receiveLiquidity`, `unlockETH`, authorization, and liquidity migration are caller-gated. Sticky
authorization after migration therefore does not give an EOA a new call right.

At the pinned timestamp the deterministic shared proxies in the fork execution are:

- ETHLockbox `0x8cc1eE887517E6964Ae6C9258784ac74B7E73FCA`
- ASR `0x8A8053d2ea2De277519b2d5C9684231e471B0C34`
- DGF `0x52006e78ADE25f53fE21c5a04Cf6662cc8E5b16d`

They are timestamp-dependent and are not deployed in production. Pre-funding all three empty
addresses did not block CREATE2 or alter the supplied anchor root.

## DelayedWETH lineage

Attacker-writable storage on every version is confined to caller-owned WETH balance, allowance, and
`withdrawals[msg.sender][subAccount]`. `initialize`, `hold`, and `recover` are privileged.

| Chain | Address | Version/status | Pinned ETH |
|---|---|---|---:|
| OP | `0xe497b094d6dbb3d5e4caac9a14696d7572588d14` | 1.0.0 legacy | 0.16 |
| OP | `0x9f9b897e37de5052cd70db6d08474550ddb07f39` | 1.1.0 legacy | 0 |
| OP | `0x82511d494b5c942be57498a70fdd7184ee33b975` | 1.1.0 legacy | 0.08 |
| OP | `0x323dfc63c9b83cb83f40325aab74b245937cbdf0` | 1.3.0 legacy | 0.08 |
| OP | `0xe214879ad573693a4c49f7654449caa455cde34f` | 1.5.0 legacy | 0 |
| OP | `0xd061ab95069987868768818cc1248705351e2d0e` | 1.5.0 legacy | 0 |
| OP | `0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162` | 2.0.0 live/reused | 20.662782 |
| Unichain | `0x7d8ea656d7417229f420b0c87f6428baa8499d70` | 1.1.0 legacy | 0 |
| Unichain | `0x84b268a4101a8c8e3ccb33004f81ed08202ba124` | 1.3.0 legacy | 0 |
| Unichain | `0xc9edb4e340f4e9683b4557bd9db8f9d932177c86` | 1.3.0 legacy | 0.08 |
| Unichain | `0xa0157f0730dea8d1a5c358dc1d340a05d8796c23` | 1.5.0 legacy | 0 |
| Unichain | `0x0bdbec6bd35571f97f96f3ed21822a4f2e071a3c` | 1.5.0 legacy | 0 |
| Unichain | `0x74ad145aC900F1DD5551F0C9E143314DC4022FCf` | 2.0.0 live/becomes orphan | 21.419797 |

CATK-E mutated all eleven legacy proxies through deposit, approval, transfer, transferFrom, unlock,
and delayed withdrawal. `vm.record` then observed zero reads and zero writes to every one during
migration. The two live proxies were reinitialized; all user balances and unlock records survived,
and both remained redeemable after Unichain's SystemConfig was repointed to OP's proxy.
