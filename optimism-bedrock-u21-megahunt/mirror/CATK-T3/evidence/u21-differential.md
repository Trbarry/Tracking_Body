# U21 N-1 -> N bridge differential

Pins: N-1 = L1 block 26,430,858 (`:8546`); N = block 26,430,859 (`:8547`).

For OP, Ink, Soneium and Unichain, all three target proxies resolve to the same implementation on both sides:

| Target | N-1 implementation/version | N implementation/version |
|---|---|---|
| L1StandardBridge | `0xb37a11aadf167b2f0b8dd85372de4bc66cd4a891` / 2.8.2 | identical |
| L1ERC721Bridge | `0x9f164f1d02a81e06d639e55f65a87f0070e3cb2e` / 2.9.1 | identical |
| OptimismMintableERC20Factory | `0xaabea75da509fa518fd8a91eae4be5813b829b12` / 1.11.0 | identical |

All four L1CrossDomainMessenger proxies changed, via their AddressManagers, from the same implementation
`0x59D497530b00062f40950ba8EaB88868bf7F86f0` (2.11.1) to
`0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448` (2.13.0). The v8->v9 source delta changes local/remote relay gas budgets
(L1 reserve 40,000 -> 135,000 and check buffer 5,000 -> 15,000) and `baseGas`; it does not change message hashes,
sender/target checks, calldata interpretation, bridge selectors, token order, recipient, or replay keys. The portal
forwards all remaining gas; a committed gas limit is a floor.

## Real in-flight differential

Both objects were proven with a real storage proof against real game 21,377 / OP output root
`0xa72ec9c6fed5b4243ca91cbea9a1bfb2474e228d1e659ac108e027cdc9537f87` (L2 block 159,634,983), resolved honestly in
the fork, matured, and finalized by an unprivileged address.

1. ERC721 withdrawal `0x466d8922…5d4c5`, initiated at OP block 105,482,729: exact pair
   `0x932261…48bF / 0x779f25…9959`, token 36,383. Under Portal 5.8.0 and 6.1.0 alike, the exact deposit bit changes
   true -> false, ownership moves from the bridge to committed recipient `0x1129DA…b3ec`, and a second finalize fails.
2. Migrated OVM ERC20 withdrawal `0xcd782207…dae67`, nonce 100,135, legacy selector `0xa9f9e675`
   (`finalizeERC20Withdrawal`), 100 USDT. Under both portals, only
   `deposits[USDT][0x94b008…58e58]` decreases by 100,000,000 base units, the committed recipient receives exactly that
   amount, the versioned relay hash is marked successful, and replay fails.

Conclusion: U21 changes relay gas accounting, not the meaning of either old bridge message.
