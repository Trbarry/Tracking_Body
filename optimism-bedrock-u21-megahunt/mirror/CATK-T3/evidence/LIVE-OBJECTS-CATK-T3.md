# Live objects used by CATK-T3

## In-scope deployments (L1)

| Chain | L1StandardBridge | L1ERC721Bridge | Mintable factory |
|---|---|---|---|
| OP | `0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1` | `0x5a7749f83b81B301cAb5f48EB8516B986DAef23D` | `0x75505a97BD334E7BD3C476893285569C4136Fa0F` |
| Ink | `0x88FF1e5b602916615391F55854588EFcBB7663f0` | `0x661235a238B11191211fa95D4Dd9E423d521E0Be` | `0xA8B389A82e088b164cD03230e900980CcED34d29` |
| Soneium | `0xeb9bf100225c214Efc3E7C651ebbaDcF85177607` | `0x5933e323bE8896DfaCd1cD671442F27dAA10a053` | `0xc1047e30EFC9E172cFe7aa0219895B6a43fC415F` |
| Unichain | `0x81014F44b0a345033bB2b3B21C7a1A308B35fEeA` | `0xD04D0D87E0bd4D2E50286760a3EF323FeA6849Cf` | `0xA2B597EaeAcb6F627e088cbEaD319e934ED5edad` |

The twelve proxies share the implementations listed in `u21-differential.md` at N-1, N, and block 26,433,900.

## Real withdrawal objects

- ERC721: L2 tx `0x7a260061c7118e77088ff565f1567a79ca03a515e0b71bfeffccb250c0ad02cd`, withdrawal
  `0x466d8922599f681d406b75df268d8d7a5b97a3a85dccb42dd0480899f615d4c5`. At the L1 pin, the exact deposit bit is
  true and token 36,383 is owned by L1ERC721Bridge.
- Legacy ERC20: L2 tx `0x2f5d69c76910bbdbcca251a1c762e222baaf936bfd6b3f9823d98d563599a831`, migrated withdrawal
  `0xcd78220755a5402299f3284f175eb43f8627fb600f03225a5db2745d4bfdae67`. It calls the legacy wrapper for the exact
  USDT pair and was unrelayed/unfinalized at the pin.
- Proof vehicle: dispute game 21,377 at `0x675E956B1912Df79108408CA524fB37810500d10`; output root and storage proofs
  are reproduced in `poc/test/fixtures/`.

## Accounting objects

The 11 highest-activity OP bridge pairs are enumerated in `top-pair-census.md`; each has a live nonzero exact-pair
mapping at block 26,433,900 and a linked L2 supply read at block 159,654,093. They are passive context only; no
third-party token logic was tested as an attack target.
