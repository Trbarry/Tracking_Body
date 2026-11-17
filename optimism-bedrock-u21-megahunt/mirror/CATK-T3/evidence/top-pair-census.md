# OP L1StandardBridge top-pair census

Selection: the 11 exact `(L1 token, L2 token)` pairs with the greatest number of legacy bridge deposit/withdrawal
events through L1 block 26,433,900. Discovery reused the already-bounded local scan (12,600,000..26,433,900; 28
`eth_getLogs` chunks per event) and aggregated it offline. Every value below was then checked directly against
`deposits(l1,l2)` on the pinned L1 fork (`:8545`, block 26,433,900); L2 supply was read from `:9545`, block
159,654,093. Values are base units.

| Pair | dep/wd events | event deposits - withdrawals | on-chain `deposits` | L2 `totalSupply` | escrow - supply |
|---|---:|---:|---:|---:|---:|
| USDT | 35,355 / 1,471 | 175429844402711 | 175429844402711 | 144871271189513 | 30558573213198 |
| USDC | 23,730 / 3,730 | 18706080388687 | 18706080388687 | 18652197988681 | 53882400006 |
| WBTC | 4,684 / 1,678 | 49569881315 | 49569881315 | 49384890678 | 184990637 |
| CRV | 2,525 / 325 | 6515889347845716991491923 | 6515889347845716991491923 | 6510261766256544143428092 | 5627581589172848063831 |
| WLD | 1,676 / 746 | 497918468315641545002361804 | 497918468315641545002361804 | 496579483200689057913572141 | 1338985114952487088789663 |
| PERP | 1,362 / 864 | 1351161824831284175994777 | 1351161824831284175994777 | 1332468658738501368778788 | 18693166092782807215989 |
| LINK | 1,122 / 993 | 173727482078080454889644 | 173727482078080454889644 | 172487572589994159180572 | 1239909488086295709072 |
| BAL | 1,293 / 664 | 94551031181588042435623 | 94551031181588042435623 | 94337432539024926311624 | 213598642563116123999 |
| rETH | 1,037 / 753 | 2332113297262796791235 | 2332113297262796791235 | 2313656578850171236662 | 18456718412625554573 |
| LUSD | 939 / 790 | 82877050046839469299276 | 82877050046839469299276 | 78932452885588443111526 | 3944597161251026187750 |
| AAVE | 1,154 / 461 | 4833765442931523681082 | 4833765442931523681082 | 4711811019798523934463 | 121954423132999746619 |

Result: 11/11 event nets equal the exact mapping entry; 11/11 have L2 supply **below**, never above, L1 escrow. The
positive gap is compatible with L2 burns whose L1 withdrawals remain pending (and other non-release states); it cannot
enable over-release because finalization first subtracts from that exact mapping entry with checked arithmetic.

Exact pairs, in the same order:

- USDT `0xdAC17F…31ec7` / `0x94b008…58e58`
- USDC `0xA0b869…6eB48` / `0x7F5c764…1607`
- WBTC `0x2260FA…C599` / `0x68f180…2095`
- CRV `0xD533a9…cd52` / `0x099420…Fb53`
- WLD `0x163f8c…8753` / `0xdc6ff4…26f1`
- PERP `0xbC3966…3447` / `0x9e1028…40e0`
- LINK `0x514910…86CA` / `0x350a79…a7f6`
- BAL `0xba1000…24e3D` / `0xfe8b12…9921`
- rETH `0xae7873…6393` / `0x9bcef7…b81d`
- LUSD `0x5f9880…8bA0` / `0xc40f94…2819`
- AAVE `0x7Fc665…DaE9` / `0x76fb31…9278`
