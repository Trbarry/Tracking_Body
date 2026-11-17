# LIVE OBJECTS — production objects matching attack preconditions

Merged from the per-lane files (paths below are the sources; content copied verbatim).


---

## Source: `evidence/attack-wave/A/LIVE-OBJECTS-A.md`

# LIVE-OBJECTS-A — type-9 games still judged by the OLD prestate (kona-client v1.7.0)

Source: `test/poc/attack-wave/A/census_old_prestate.py` at L1 block 26435056 (ts 1794922007), raw output
`census-26435056.txt`. Prestate `0x031ac6f1…` = superchain-registry `standard-prestates.toml` `[prestates."1.7.0"]
cannon64-kona-interop` (also 1.7.0-rc.2). New `0x03e5a548…` = `[prestates."1.9.0"]`.

Why they match the lane precondition: status IN_PROGRESS, respected type 9 at creation, proper/respected in the
current ASR (forge `test_oldPrestateGamesStillLiveAndRespected`), and any EOA can still open a dispute
(`test_unprivilegedAttackMoveOnOldGame`). Leaf steps would run the OLD program. Totals: OP 70, Ink 7, Unichain 71
(148). Only two have a dispute: Ink 2638 (2 claims; known third-party wrong root, countered) and Unichain 17586
(12 claims; known third-party wrong root). Window closes by time: the newest old game (OP, created 1794870155) is
resolvable at the latest at created + 2 x 302400 s = 1795474955 (2026-11-23 23:02 UTC); after that no old-prestate
game can still be decided.

No exploit follows: no consensus delta between v1.7.0 and v1.9.0 is reachable by an unprivileged party (ATTACK-A-01..05).

| chain | index | proxy | createdAt | claims | root challenger clock used / max |
|---|---|---|---|---|---|
| op | 21377 | `0x675e956b1912df79108408ca524fb37810500d10` | 1794870155 | 1 | 51852/302400 |
| op | 21376 | `0xacef7dccfd06e8a6e61e8411db2e0bd7300ad233` | 1794868151 | 1 | 53856/302400 |
| op | 21375 | `0x3d2291f923c6300abf9163423adcd6475222bd97` | 1794864527 | 1 | 57480/302400 |
| op | 21374 | `0xed801ca7a455d356aa18eb129c3fb1bcf138cf54` | 1794860915 | 1 | 61092/302400 |
| op | 21373 | `0x86512332b510f40bb9361de685ca1e4815dee5fe` | 1794857291 | 1 | 64716/302400 |
| op | 21372 | `0xbec6373fa5b74517350d9cb358a5e7d9f3dab356` | 1794853667 | 1 | 68340/302400 |
| op | 21371 | `0x02b0054371e367cb623068d1b41a41e6122b5228` | 1794850055 | 1 | 71952/302400 |
| op | 21370 | `0xba898b5cbb1b71f8adb7da980f54b3333fea6dcc` | 1794846431 | 1 | 75576/302400 |
| op | 21369 | `0xb6e78e255927efa051603304e6337779351673ca` | 1794842807 | 1 | 79200/302400 |
| op | 21368 | `0xe6635dd0c88121d9d67ba8d6eb0c01d344abde99` | 1794839195 | 1 | 82812/302400 |
| op | 21367 | `0x16a332e6ddf7a0b883134fac1a2d45dfdcad87a8` | 1794835583 | 1 | 86424/302400 |
| op | 21366 | `0x5a93a8d05c29dc4636a6cd6085cd1195170fcd19` | 1794831959 | 1 | 90048/302400 |
| op | 21365 | `0x6c4f912f460337f661f59ea71835872469e54d07` | 1794828347 | 1 | 93660/302400 |
| op | 21364 | `0x4527a4ee6cdb3fc84f5e0d8164de476a5b6d700f` | 1794824723 | 1 | 97284/302400 |
| op | 21363 | `0xf0bab059d64d0fd981cb3936e4b0999c4937ec95` | 1794821099 | 1 | 100908/302400 |
| op | 21362 | `0xb906be0127c8f9e3044daa9e10f6117f6cdc87f8` | 1794817487 | 1 | 104520/302400 |
| op | 21361 | `0x41166652da61ccfd611c2689d3b1c3b42bc58913` | 1794813863 | 1 | 108144/302400 |
| op | 21360 | `0x120f3b5f61febfed1194366fd6976c73a7ef24eb` | 1794810239 | 1 | 111768/302400 |
| op | 21359 | `0xdabd4b65ae61b75bfb63ddfe6531a54fd9597e70` | 1794806627 | 1 | 115380/302400 |
| op | 21358 | `0x43484bcd22c30d53a69dfbd829122e3d75c1e06d` | 1794803003 | 1 | 119004/302400 |
| op | 21357 | `0x1607edd4232b556232c82f441b300bc5bf404700` | 1794799379 | 1 | 122628/302400 |
| op | 21356 | `0x0a2e147ab60edd12889aa9dff28c7a59b2f57bff` | 1794795767 | 1 | 126240/302400 |
| op | 21355 | `0x3612fca1995e2eaa46dc65c882daccc91ebbeace` | 1794792143 | 1 | 129864/302400 |
| op | 21354 | `0x6090329d585a4889e25d0f191332ce9b5295aeb8` | 1794788519 | 1 | 133488/302400 |
| op | 21353 | `0x3869b9e1d60160dc5da914ee9be8baaaf0e91f56` | 1794784907 | 1 | 137100/302400 |
| op | 21352 | `0x70b738192a882889d349dafc67a8245b99d168f2` | 1794781283 | 1 | 140724/302400 |
| op | 21351 | `0x471576814df2b372be3a84c5333c6590e9ea4edc` | 1794777659 | 1 | 144348/302400 |
| op | 21350 | `0x2f55f48e8318a65d374f4113583279fbac8d86fd` | 1794774047 | 1 | 147960/302400 |
| op | 21349 | `0x01a5438720d76b6f6ece15bc3bcfeea905877a48` | 1794770435 | 1 | 151572/302400 |
| op | 21348 | `0xd9680757c24cdc1118d0f767083eef0354268ba7` | 1794766823 | 1 | 155184/302400 |
| op | 21347 | `0x52f23aa10a1dec189f798df52d727974a73d7555` | 1794763199 | 1 | 158808/302400 |
| op | 21346 | `0x831ced87c187697c17fb9ff8e1a4117402256b84` | 1794759587 | 1 | 162420/302400 |
| op | 21345 | `0x3c5166e2372af8392cde3a375e4c913e7d3d8038` | 1794755963 | 1 | 166044/302400 |
| op | 21344 | `0x8f8d84a24c6d44479a89974773c3b2bc3860723c` | 1794752339 | 1 | 169668/302400 |
| op | 21343 | `0xe1adc6eebbea6378befc5510896798bf13b3348e` | 1794748727 | 1 | 173280/302400 |
| op | 21342 | `0x289b26fefa499be24f6fb9e1ff07a565950c6d4c` | 1794745103 | 1 | 176904/302400 |
| op | 21341 | `0x1637da079f68869eb28590c7168d89b49905e568` | 1794741479 | 1 | 180528/302400 |
| op | 21340 | `0xeabaafef8eee36e769e528d0bd916d074c01eb83` | 1794737867 | 1 | 184140/302400 |
| op | 21339 | `0x34f0653c084591e78e558422fa83405c25973e8f` | 1794734255 | 1 | 187752/302400 |
| op | 21338 | `0xd0d611a166c2ec84b2de169b1b6d4fa4fa61a415` | 1794730643 | 1 | 191364/302400 |
| op | 21337 | `0xa780de57006589d149a3658f36e566911e8363a7` | 1794727019 | 1 | 194988/302400 |
| op | 21336 | `0x5846f3793569f135f38359421ec0e6ac05d6ad57` | 1794723407 | 1 | 198600/302400 |
| op | 21335 | `0x82b5f89e818e49026fe8754e96f7ee3de0128c2e` | 1794719783 | 1 | 202224/302400 |
| op | 21334 | `0xdfb160c34c195dcb4b1e564cae86bbe11766f51e` | 1794716159 | 1 | 205848/302400 |
| op | 21333 | `0x2437951011aced2ac9de07791dde970dcf42be48` | 1794712547 | 1 | 209460/302400 |
| op | 21332 | `0x75522a4293bd9889aed50abce6896b66c2c4b594` | 1794708935 | 1 | 213072/302400 |
| op | 21331 | `0xbd608a5355de942370e87e58581888e1558b0b1e` | 1794705323 | 1 | 216684/302400 |
| op | 21330 | `0xf1208563273f4535a66f27c3e485913bcd2727fb` | 1794701699 | 1 | 220308/302400 |
| op | 21329 | `0x52d57410bc4ae0f73eb608cdca7697f823b74b94` | 1794698087 | 1 | 223920/302400 |
| op | 21328 | `0x9061b48e6a580e7dadf61619f684d9de31089a31` | 1794694463 | 1 | 227544/302400 |
| op | 21327 | `0xe3b8f29d7ffbf0e23eeb2b20733f127007005392` | 1794690839 | 1 | 231168/302400 |
| op | 21326 | `0xb48437026688dc642c9c653c21348428b18d51e9` | 1794687227 | 1 | 234780/302400 |
| op | 21325 | `0x37992db2225a89c6a39cecdff9c6e14da302b625` | 1794683603 | 1 | 238404/302400 |
| op | 21324 | `0x0b80869976041a42aff1be1fc0615c16e9127587` | 1794679979 | 1 | 242028/302400 |
| op | 21323 | `0x376aedab5fd05be14f16d07fbd530737ac3f519b` | 1794676367 | 1 | 245640/302400 |
| op | 21322 | `0xe14b40000fa8219a6802f7c3c2230602b65ca06d` | 1794672743 | 1 | 249264/302400 |
| op | 21321 | `0xe550318c54eab7aa04ee1f305544b2263b6eaa1e` | 1794669107 | 1 | 252900/302400 |
| op | 21320 | `0x0fa76e448011b0f317d3a5921705b47cdc109902` | 1794665483 | 1 | 256524/302400 |
| op | 21319 | `0x29f3295d88abc7366bd2f773bc1466f92238df44` | 1794661859 | 1 | 260148/302400 |
| op | 21318 | `0x9a1f4df1504ac6e541404680e0fe4ba3df29fced` | 1794658247 | 1 | 263760/302400 |
| op | 21317 | `0xb66e23508643def3dc4ae57efaadc3e10d8b9a5a` | 1794654623 | 1 | 267384/302400 |
| op | 21316 | `0xfb7e8753ee9eb1a4adae6093d5a171f0950330d8` | 1794650999 | 1 | 271008/302400 |
| op | 21315 | `0xa3c0e28a733db64982f03165e4506e8d55a7e63f` | 1794647387 | 1 | 274620/302400 |
| op | 21314 | `0x7e0db25874f804d39a5874825d407c3d02888ba7` | 1794643763 | 1 | 278244/302400 |
| op | 21313 | `0xa807efb7b1f14f87fc8a8c7ede4354d5c708dd14` | 1794640139 | 1 | 281868/302400 |
| op | 21312 | `0x56edbfbdf987c3751fc7ac135849441a604c5500` | 1794636527 | 1 | 285480/302400 |
| op | 21311 | `0x604a3d4ddbfbd9e79c721f7cdae67367d4c65802` | 1794632903 | 1 | 289104/302400 |
| op | 21310 | `0x42d0c7b4bf515bf95017d686fdf4d56d0d8ce9cb` | 1794629279 | 1 | 292728/302400 |
| op | 21309 | `0x9a6c2181666a999b28a484e629d55ceaad4a58fe` | 1794625667 | 1 | 296340/302400 |
| op | 21308 | `0x5d62795e45fca7bdf9c20a26464e1bb4b4f369ed` | 1794622043 | 1 | 299964/302400 |
| ink | 2638 | `0x40bec00713a38ee5fd697764d50f0055ba4942cc` | 1794857603 | 2 | 64404/302400 |
| ink | 2637 | `0x73f3a9ed6671553e2bd51c80dd5792cb16914a0d` | 1794851363 | 1 | 70644/302400 |
| ink | 2636 | `0x51918a4ebe8440bd9b0f1d29ce4a326c15c47c7f` | 1794808151 | 1 | 113856/302400 |
| ink | 2635 | `0xefe72925d429386949834b780b99a8d13f4e92d7` | 1794764939 | 1 | 157068/302400 |
| ink | 2634 | `0xa820eae432e3459c19008ef7b586272db65e2018` | 1794721715 | 1 | 200292/302400 |
| ink | 2633 | `0x0ee6062e27037cb177187a20ef50f40aad907274` | 1794678491 | 1 | 243516/302400 |
| ink | 2632 | `0x744f0c04b36dae6ede21df1b8e15828f053d54cf` | 1794635279 | 1 | 286728/302400 |
| unichain | 17680 | `0x3073a5f81798e353033ba07cf19b49d6390a68d8` | 1794870011 | 1 | 51996/302400 |
| unichain | 17679 | `0x704f11ecf9dbeddfbf3b87c2e3b5e173cfc49c6c` | 1794866399 | 1 | 55608/302400 |
| unichain | 17678 | `0x3ad66b378a52567bb6bde4bdd232c9637581ec09` | 1794862775 | 1 | 59232/302400 |
| unichain | 17677 | `0xecd171ac0ddd178cb4e369e685e9623ad7416ec7` | 1794859151 | 1 | 62856/302400 |
| unichain | 17676 | `0xa1d458cb44b4311c03d53973b4714ee0df289d4a` | 1794855539 | 1 | 66468/302400 |
| unichain | 17675 | `0x0c92bd34bb3f8b6b2723d994b11d6d9a86d9f0b2` | 1794851915 | 1 | 70092/302400 |
| unichain | 17674 | `0xeaff675c87e1432b6df2b4778601484efbc61d2a` | 1794848303 | 1 | 73704/302400 |
| unichain | 17673 | `0xb82205c61507d056565e6fca684e3de0a640e58c` | 1794844679 | 1 | 77328/302400 |
| unichain | 17672 | `0x53ed381e56ed65e44a3165f7d919cb7b52a3562e` | 1794841055 | 1 | 80952/302400 |
| unichain | 17671 | `0xe061987df9e56e784124c675607fe454f611ee07` | 1794837443 | 1 | 84564/302400 |
| unichain | 17670 | `0x941747c3a6c49da9333acbce30c60cefc9b47197` | 1794833819 | 1 | 88188/302400 |
| unichain | 17669 | `0x3c9febd49cde79d616524e26dd004d265b6f6c66` | 1794830195 | 1 | 91812/302400 |
| unichain | 17668 | `0xaa7e4cc4b8947e89b8c31d88dcc785d8463e8941` | 1794826583 | 1 | 95424/302400 |
| unichain | 17667 | `0x65923fc0d8af611ebd4e78e5030df1e9dc816ed7` | 1794822959 | 1 | 99048/302400 |
| unichain | 17666 | `0x533bf9afa0fde0af311215c337f14df8e03c7a53` | 1794819335 | 1 | 102672/302400 |
| unichain | 17665 | `0xf5899318855023cb4cc0436d10210d8604d08b4e` | 1794815723 | 1 | 106284/302400 |
| unichain | 17664 | `0xe82b14072751f54a284f05623013852aa9003a2c` | 1794812099 | 1 | 109908/302400 |
| unichain | 17663 | `0x894a2d2e05ff0c1044a9a3519c9a429222206933` | 1794808475 | 1 | 113532/302400 |
| unichain | 17662 | `0xda47f80ed2afe1741accce0d20ce5a6a6f7ecf76` | 1794804863 | 1 | 117144/302400 |
| unichain | 17661 | `0xafca034180d92220c607f5e1c18430cbecf4b2c4` | 1794801239 | 1 | 120768/302400 |
| unichain | 17660 | `0xfd0bd99d174758d9dbef1b807de2313448ad115a` | 1794797615 | 1 | 124392/302400 |
| unichain | 17659 | `0x1851f73e89d4eb11bdb05c248ffc4c588ea062e6` | 1794794003 | 1 | 128004/302400 |
| unichain | 17658 | `0xc56edae78f0cd9ed0876647f4cffcff09a238865` | 1794790379 | 1 | 131628/302400 |
| unichain | 17657 | `0x7cb59bd8704713792d2daf7aaa00ba28c2813731` | 1794786755 | 1 | 135252/302400 |
| unichain | 17656 | `0x4e13e32c03d55e55da654473905267e2d9cb468f` | 1794783143 | 1 | 138864/302400 |
| unichain | 17655 | `0xdaca7ca594c5df0dd20b524d35ea0905153075fc` | 1794779519 | 1 | 142488/302400 |
| unichain | 17654 | `0x9b56dfbcb0c9412806ab518bf8b5498428e04549` | 1794775895 | 1 | 146112/302400 |
| unichain | 17653 | `0x7137b361a7d9e31a39970acf1a37a6ba582e314f` | 1794772283 | 1 | 149724/302400 |
| unichain | 17652 | `0xcd89fc3bcf5898c666b1cd4764a0e2b49f3807fc` | 1794768659 | 1 | 153348/302400 |
| unichain | 17651 | `0x765aadaed5d27a616a8af70dfef9bce1ceab8140` | 1794765035 | 1 | 156972/302400 |
| unichain | 17650 | `0x16835ff339746e0f1cd0d9382f19f0b774e41b82` | 1794761423 | 1 | 160584/302400 |
| unichain | 17649 | `0xd0218559d180ed9f6d241b32decda1baec5265aa` | 1794757799 | 1 | 164208/302400 |
| unichain | 17648 | `0x1af49c9ef651a623f7eaf0b99c59b37c7953f074` | 1794754175 | 1 | 167832/302400 |
| unichain | 17647 | `0x973dd439d082e7b524af8bf39018d3dd2b7ffcf7` | 1794750563 | 1 | 171444/302400 |
| unichain | 17646 | `0x040e349657b12e44e6376bb01acdbd48298f948b` | 1794746939 | 1 | 175068/302400 |
| unichain | 17645 | `0x00e3fcce5793a3ed2656e5bf896b9284ba50040f` | 1794743315 | 1 | 178692/302400 |
| unichain | 17644 | `0x32d27afff5b5497b7f34f1c75c050eca00c29586` | 1794739703 | 1 | 182304/302400 |
| unichain | 17643 | `0x451dac81ac55200561e222b60ce3e94bd0970efc` | 1794736079 | 1 | 185928/302400 |
| unichain | 17642 | `0x651f59b677396b5f69356a4a1482e2b754c0d170` | 1794732455 | 1 | 189552/302400 |
| unichain | 17641 | `0x5956312b018e00942c96f6dee586cefb023db31a` | 1794728843 | 1 | 193164/302400 |
| unichain | 17640 | `0xa32ac95d7de2bbb6a8bc3c6785d0ecb2b3b73bbc` | 1794725219 | 1 | 196788/302400 |
| unichain | 17639 | `0xb37d809f3dfc85807372295ac844622c85bd5719` | 1794721595 | 1 | 200412/302400 |
| unichain | 17638 | `0xf8fe5998aa3aa364f0a220a9c0155e522417d9cc` | 1794717983 | 1 | 204024/302400 |
| unichain | 17637 | `0x5d22d047733670ed266896eb6d1208a5dfd20ed3` | 1794714359 | 1 | 207648/302400 |
| unichain | 17636 | `0x04411757bba3da5ec47b825b562d08a4aebfb066` | 1794710735 | 1 | 211272/302400 |
| unichain | 17635 | `0x344ba92facb46a1dc3c07e9c94f8fa70fb0305f0` | 1794707123 | 1 | 214884/302400 |
| unichain | 17634 | `0xc8a9dc9d143cd9eea95ffa957f42a26026a43262` | 1794703499 | 1 | 218508/302400 |
| unichain | 17633 | `0x9aee25e674b401d3cd280d785c40618627ea42b8` | 1794699875 | 1 | 222132/302400 |
| unichain | 17632 | `0xf794d5e45dfb102261b2e75648c77e014569d959` | 1794696263 | 1 | 225744/302400 |
| unichain | 17631 | `0xc0184266b78fb9a934bf2c9515834572bd050d3d` | 1794692639 | 1 | 229368/302400 |
| unichain | 17630 | `0xd9151e10c2752fadc5187dd91a66ac8a4ee46900` | 1794689015 | 1 | 232992/302400 |
| unichain | 17629 | `0x1780e6bca8cb2b757da2100f6118a4b8346069c0` | 1794685403 | 1 | 236604/302400 |
| unichain | 17628 | `0x939a7ff79fe3d77df5be98b33d4b726001a08d85` | 1794681779 | 1 | 240228/302400 |
| unichain | 17627 | `0x76dce9c0a76687276bc633e2da864a03110be32c` | 1794678155 | 1 | 243852/302400 |
| unichain | 17626 | `0xa6286d46516b9500152024b784a20888a7d899d1` | 1794674543 | 1 | 247464/302400 |
| unichain | 17625 | `0x0ec5dc2028aa5afe9087d4f9e39e6c5172d70985` | 1794670919 | 1 | 251088/302400 |
| unichain | 17624 | `0x759c3463145e6dedff2b812e3bbc751885c0ea60` | 1794667307 | 1 | 254700/302400 |
| unichain | 17623 | `0xd6f1b47be44750bae3e3810c83967a422b49f974` | 1794663683 | 1 | 258324/302400 |
| unichain | 17622 | `0x50a4412b71a7cb395bf9e14bdcd5e75a3b0a5321` | 1794660059 | 1 | 261948/302400 |
| unichain | 17621 | `0x27aad4cf253fd47187d90c9f8ac90cf06ad87382` | 1794656435 | 1 | 265572/302400 |
| unichain | 17620 | `0x2e8059dbcd2230528cadd9d7639ade15318a648a` | 1794652823 | 1 | 269184/302400 |
| unichain | 17619 | `0xa9f49bbac95726aa4447eb61140bb77bb8ccc626` | 1794649199 | 1 | 272808/302400 |
| unichain | 17618 | `0x926d17b331c52fa53f1e3f2be4a19a6370b2e46c` | 1794645575 | 1 | 276432/302400 |
| unichain | 17617 | `0x179442b69eefb9fd1dc303f79cbbf291de579981` | 1794641963 | 1 | 280044/302400 |
| unichain | 17616 | `0x14482d0e515ee8b3c80519ee4bec3d4732c5bf5f` | 1794638339 | 1 | 283668/302400 |
| unichain | 17615 | `0x73eea973212474c002325fd9c757e61665c6fff6` | 1794634715 | 1 | 287292/302400 |
| unichain | 17614 | `0x2307b425870f4f1be576f1d8f2ab9ae39a06bfa3` | 1794631103 | 1 | 290904/302400 |
| unichain | 17613 | `0x270f935143276d53467886bf6b5e428abd4fdd17` | 1794627479 | 1 | 294528/302400 |
| unichain | 17612 | `0x9f5ba1b624ae4b7cff2ee8918fb0977d92803c44` | 1794623855 | 1 | 298152/302400 |
| unichain | 17611 | `0xa0c9d853edb8e01a45de937b1f5d2d5d1f42673f` | 1794620243 | 1 | 301764/302400 |
| unichain | 17586 | `0xa41214c2851f0d538b7c6b37fa66e35472ff6f0e` | 1794531755 | 12 | 302400/302400 |


---

## Source: `evidence/attack-wave/B/LIVE-OBJECTS-B.md`

# LIVE-OBJECTS-B — messenger failure census, all four chains (ATK-B)

Scan: `eth_getLogs` via archive proxy :7545, blocks 17,422,444..26,433,900 in 10k windows, addresses =
4 portals + 4 L1CDMs, topics `WithdrawalFinalized(bytes32,bool)` (kept success=false) and
`FailedRelayedMessage(bytes32)`. Every hit decoded from `debug_traceTransaction` (callTracer); mappings
read at 26,433,900. Raw: `scan-failures-all-chains.json`, decoded: `census-decoded.json`, scripts `scan.py`, `decode.py`.

L1CDM addresses / ETH balance @26433900 (also 0 at 18.5M, 20M, 22M): OP 0x25ace71c… 0; Ink 0x69d3Cf86… 0;
Soneium 0x9CF951E3… 0 (no failure ever); Unichain 0x9A3D64E3… 0 (no failure ever).

## A. FailedRelayedMessage — 30 logs, 22 distinct hashes (OP 18, Ink 3)

Value-bearing (all 4 now `successfulMessages = true`, replayed; nothing parked):

| chain | msgHash | first fail block | value (ETH) | target | status @pin |
|---|---|---|---|---|---|
| Ink | 0x940ba5ec…7941 | 22,419,550 | 17.294 | 0x0f703cf7… | delivered |
| Ink | 0xd9204ef4…b8fe | 23,096,290 (+4 failed replays) | 58.326 | 0x0f703cf7… | delivered |
| Ink | 0xfac7aaf7…4445 | 23,175,112 | 15.866 | 0x0f703cf7… | delivered |
| OP | 0x4469d07d…3276 | 26,346,791 (v8) | 236.750 | 0x23CA5E53… | delivered |

Still failed at the pin: 15 OP hashes, ALL value 0 (consistent with L1CDM balance 0). v9 replay by an
unrelated EOA (test_E1): 3 deliver now (0x18b123eb, 0x6c9a36ef, 0x71c9882b: ERC20 via L1StandardBridge,
unclaimed); 12 still fail for target-side reasons:
- `deposits[l1][l2]` underflow in L1StandardBridge (0x1829f5fe token 0xd17d5c95/L2 0x96bBD554, 50,123 units;
  0xe43cf22b token 0xBB9bc244/L2 0x7093f7CC, 5.091): withdrawal of an L2 token pair that was never deposited
  (per-pair accounting working as designed).
- token reverts on transfer (0x2c820221, 0xdc594bf2, 0x09af464a: token 0x48AFbBd3 custom error 0x11bad8f5).
- third-party targets: Hop `TransferRoot already confirmed` (0x33f61390), Synthetix bridge
  `Must be proxy target`/state (0x43e0b785, 0xb53bc394, 0xae100545, 0x9546105b), legacy gateway
  `Invalid l1Token` (0xe208b527), token `SafeMath: subtraction overflow` (0x384bf7ec, L1CDM has no balance).
None is caused by a third party; none carries ETH.

## B. WithdrawalFinalized(success=false) — 4 hits, all OP, all legacy (version-0) migrated withdrawals

| block | withdrawal hash | value | legacy (v0) hash successfulMessages | v1 failed/successful |
|---|---|---|---|---|
| 25,149,695 | 0x50d7b362…6ddd | 0.6087 ETH | true | false/false |
| 25,149,748 | 0x64db0ab9…a7ec | 0.001 ETH | true | false/false |
| 25,163,168 | 0xd3628e07…5977 | 1.5220 ETH | true | false/false |
| 26,139,841 | 0xad0a2811…8ec4 | 0 ETH (legacy WBTC 0.4968 finalizeERC20Withdrawal) | true | false/false |

L1CDM reverted at `legacy withdrawal already relayed` (CrossDomainMessenger.sol:231): these were already
paid by the pre-Bedrock messenger; the v8 portal relocked the ETH into the lockbox (trace: lockbox
0x1ee116bf lockETH after the reverted relay). "Finalized, unknown to messenger" but NO stranded value:
double-withdrawal attempts that failed safely. Under v9 the same input reverts the whole finalize (:652).

## C. Production objects matching the attack precondition (forced-fail victims)

Every proven, mature, unfinalized L2CDM withdrawal on OP/Ink/Unichain (e.g. PASS A fixtures f1..f8,
`withdrawal-fixtures-all.json` class pre_mature_valid: 24 entries incl. 638.18 ETH 0xb16e5fc2…, CRV x9,
LINK 95.4, WBTC-like 0xa693B19d). Targets observed: L1StandardBridge (ETH/ERC20/legacy), 0x23CA5E53 impl
0xc25b0d51 (checks xDomainMessageSender only), Hop, Synthetix, L1ERC721Bridge — bytecode scan: none reads
`portal.l2Sender()` (selector 0x9bf62d82); all read `xDomainMessageSender()`, which a replay sets.


---

## Source: `evidence/attack-wave/C/LIVE-OBJECTS-C.md`

# LIVE-OBJECTS-C — production objects matching ATK-C preconditions

Population scanned (passive reads, local archive proxies):

| Scan | Range | Count | Max gasLimit | Max data | File |
|---|---|---|---|---|---|
| OP Mainnet `MessagePassed` (L2ToL1MessagePasser 0x42…16), every Bedrock-era withdrawal | L2 105,235,063 .. 159,654,093 | 35,579 (== `messageNonce` delta at the two blocks, complete) | 8,415,632 | 644 B | `messagepassed-scan-op.json`, `scan-op.log` |
| OP Mainnet legacy OVM-2 `SentMessage` (L2CDM) → migrated version-0 withdrawals | L2 0 .. 105,235,062 | 39,885 logs (legacy `messageNonce` = 139,885; the 100,000 offset predates the Nov-2021 regenesis and is not visible as logs) | migrated `B0 = 16·len + 1,300,873` → max ≈ 1.31 M (largest message 356 B) | 356 B | `legacy-sentmessage-scan-op.json` |

Edge of the deliverable region (measured at exactly 2^24, `edge-at-cap.jsonl`): withdrawal gasLimit ~16.06M
(m ~15.51M live budget) or ~264 KB nonzero message. The highest gasLimit of any OP Mainnet withdrawal ever
created is 8,415,632 (52% of the edge); the largest payload is 644 B. The objects nearest to the edge are the only ones with `gasLimit > 8M`:

| L2 block | withdrawalHash | kind | minGasLimit | gasLimit | value | status @ L1 26433900 | why it matches |
|---|---|---|---|---|---|---|---|
| 113,711,749 | `0x0adc3473dd8294ee774e763af2c9df4fe95c9f06d8140c61b06394a7fbab0dbe` | L2SB ERC20 withdraw → L1SB `finalizeBridgeERC20` (OS token `0x6100dd79…b771`, 26.5 OS to `0xd130…be91`) | 8,000,000 | 8,415,632 (Bedrock-era budget) | 0 | never proven, not finalized | m inside the forced-fail band (m ≥ 5.76 M for this budget generation) |
| 113,711,767 | `0x908556f7102b5037c6be3d8db42b6e627c439f6128dc79120adad63ea14464e3` | same | 8,000,000 | 8,415,632 | 0 | never proven | same |
| 113,711,779 | `0x5be066c469594a83e76a7b6809ca59e56436b55f464937567119b2eaf2b7bde1` | same | 8,000,000 | 8,415,632 | 0 | never proven | same |
| 113,711,803 | `0x067f9cb922fdfa18d93532ee8d3d2b243226b46c5562b643e4a6f891cd0506cf` | same | 8,000,000 | 8,415,632 | 0 | never proven | same |
| 115,891,218 | `0xd91ec183b9794540ee83f19c9f9ac73f6e351f0433acb7e7c10d270ac1c6b462` | same | 8,000,000 | 8,415,632 | 0 | proven L1 19,274,944, finalized L1 19,531,461 (success) | reference |

"never proven": no `WithdrawalProven` / `WithdrawalProvenExtension1` / `WithdrawalFinalized` log with
that hash on portal `0xbEb5…06Ed` in L1 blocks 18,000,000 .. 26,433,900 (same query returns the
reference object's prove and finalize logs). L1SB `deposits(OS, l2OS)` = 101,175.7 OS ≥ amount.
Decoded structs: `live-objects-8M.json`.


---

## Source: `evidence/attack-wave/D/LIVE-OBJECTS-D.md`

# LIVE-OBJECTS-D — production objects matching the trojan-game preconditions

Scan: `scanproofs.py` + `enrich.py` (this dir) over OptimismPortal 0xbEb5Fc57… `WithdrawalProvenExtension1` logs,
L1 blocks 26383500..26433900 (7 days), via the archive proxy :7545. Output: `op-proofs-selection-scan.json`.
`lag_games` = (newest type-9 game index in the factory at block-1) − (game index in the prove calldata).

| Object | Chain | Address / hash | Block | Why it matches |
|---|---|---|---|---|
| Respected permissionless super type | OP | DGF 0xe5965Ab5…, type 9, bond 0.08 ETH | 26433900 | anyone can register a trojan (PoC) |
| Honest proposal cadence | OP | games 21383..21388, creators 0x4733…3A33 (89/100) and 0xc27b…5bE0 (11/100) | 26433900 | one game every ~3,624 s; `op-last100-games-creators.txt` |
| Proof population | OP | 242 proofs, 39 submitters, 241 direct `proveWithdrawalTransaction` calls | 26384576..26433490 | 137 used the newest game (lag 0), 51 lag 1 → 78% pick from the 1–2 newest games, the fingerprint of latest/random-over-a-small-pool tooling |
| Auto-prover (relayer) | OP | 0x431f5015b7c05fe792aea2a05158919af1e8ddf5 | same window | 135 proofs of L2CDM→L1StandardBridge withdrawals (125 `finalizeBridgeETH`, 8 ERC20) for 74 distinct users, 13.63 ETH; lag 0 ×96, lag 1 ×39; it is the proof submitter (users finalize via external proof or it does) — identity not established on-chain |
| Fixed-old-game provers | OP | 0xa7fad3a7…4dda (27, lag 774), 0xa84ff98f…1ddf (9, lag 643) | same window | always reuse one old resolved game → NOT exposed to trojans |
| Victim fixtures | OP | L1 txs 0xc57d4b53…, 0x815fbca2…, 0x2b8325aa…; fresh L2 tx 0x010c5082… | — | real pending withdrawals used in the PoC |

Ink / Unichain: same type-9 implementation and gameArgs (PRIM-0903), mechanism identical; not scanned for proofs.
Soneium: type 5 (proposer-gated) — not exposed.


---

## Source: `evidence/attack-wave/E/LIVE-OBJECTS-E.md`

# LIVE-OBJECTS-E — production objects matching ATK-E preconditions (L1 block 26433900)

| chain | object | address / id | why it matches | ATK-E result |
|---|---|---|---|---|
| OP | gen-2 ASR v2.2.2 (orphaned U16) | 0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b, anchor 0x9C9ac0A3… | permissionless `setAnchorState` accepts live-registry game #20094 | moved by attacker (P1); never read by migrate (E-01) |
| UNI | gen-2 ASR v2.2.2 | 0xD5D0e176be44E61eaB3Cf1FA8153758dF603376f, anchor 0xcD1f9c0F… | accepts game #16394 | same |
| OP / UNI | gen-0 ASR v2.0.0 | 0x18DAc71c…e443 / 0x318A642d…643B | only writers: game-only `tryUpdateAnchorState`, guardian `setAnchorState` | not writable (E-02) |
| OP / UNI | live per-chain ASR | 0x23B2C629… (anchor 0x55A5CFd4…) / 0x27Cf508E… (anchor 0x944a783a…) | permissionless `setAnchorState`; re-initialised by migrate | no newer claim-valid game in the last 150; carried unchanged (E-04) |
| OP / UNI | per-chain DGF type 9 | 0xe5965Ab5… / 0x2F12d621…, bond 0.08 ETH | permissionless game creation up to the migration block | attacker games inert after migrate (E-05) |
| OP / UNI | per-chain lockbox | 0x322b47Ff… / 0x08bA0023… (182,541 / 18,266 ETH) | swept by migrate; forced-ETH target | conservation exact (E-03) |
| OP / UNI | portals | 0xbEb5Fc57… / 0x0bd48f6B… | `donateETH`, `depositTransaction`; validator MIG-150 | swept; post-migration 1 wei trips validator only (E-08, known) |
| OP | 6 legacy DelayedWETH | 0xE497B094, 0x9F9b897e, 0x82511d49, 0x323dFC63, 0xe214879a, 0xD061AB95 | permissionless deposit/self-unlock | not read by migrate (E-03) |
| UNI | 5 legacy DelayedWETH | 0x7d8Ea656, 0x84B268A4, 0xc9edb4E3, 0xa0157F07, 0x0bdbEc6b | same | same |
| OP / UNI | current DelayedWETH | 0x1B6DBF05… (becomes SHARED) / 0x74ad145a… (orphaned by SC) | re-initialised with the shared lockbox | identical writes clean vs poisoned |
| — | future shared lockbox/ASR/DGF (fork, same block) | 0x8cc1eE88… / 0x8A8053d2… / 0x52006e78… | CREATE2 from the Safe, salt mixes block.timestamp | pre-funding is surplus only (E-06) |


---

## Source: `evidence/attack-wave/F/LIVE-OBJECTS-F.md`

# LIVE-OBJECTS-F — production objects matching ATK-F preconditions

Lane ATK-F, Opus 5.5. Precondition: an unfinalized (or replayable) withdrawal / authority whose L1 target is a system contract or
a contract that trusts the portal or the L1CDM as caller. Sources: L1 archive proxy :7545, OP L2 archive :7546, pinned :8545 (26433900).
Scripts: `scripts/attack-wave-F/{scan_l1_proven.py,curate_set.py,scan_l2_op.py}`.

Address set: 611 addresses from chains/*/{DEPLOYMENT,STATE-U21}.json, chains/*/HISTORY.md, F2 impl/game histories, LANE_CONTEXT,
SCOPE, U21 proxy map, plus 8 DelayedWETH generations and WETH9 (`system-address-set-raw.json`); 477 have code at 26433900
(`system-contract-set.json`).

| Id | Chain | Object | Block | Why it matches | Status / why harmless |
|---|---|---|---|---|---|
| L1-1 | OP / Ink / Soneium / Unichain | 31,804 / 1,054 / 1,925 / 3,692 `WithdrawalProven` with target = own L1CDM, sender = L2CDM | 17.0M..26.43M | target trusts portal | normal messenger path (ATK-B lane); no other sender -> L1CDM |
| L1-2 | OP | hash 0x45fd4bbc…0ebd, sender L2CDM -> 0x394400571c… (16 kB contract, game creator) | 20,873,192 | sender L2CDM with a non-L1CDM target | forged: proven against that creator's own CHALLENGER_WINS game; not finalized |
| L1-3 | OP | hash 0x0cf8309e…7e4a, sender 0x…dEaD -> 0x7813cc25… (EOA) | 26,404,222 | l2Sender == DEFAULT trick | forged (`sentMessages` false on L2), game 0xa5714949… CHALLENGER_WINS; deletable (ATTACK-F-04) |
| L1-4 | OP | hash 0x3e9259dd…73c2, 0x00b700b9… -> WETH9.approve(0x00b700b9…, ~max) | 19,608,765 (L2 118,450,437) | portal-owned allowance | finalized; portal WETH balance 0 |
| L1-5 | OP/Ink/Unichain | 10 proven withdrawals to code-less EOAs (game creators / deployers, mostly from == to) | various | target with no code (could gain code) | no code at 26433900; not system addresses |
| A-1 | Unichain | USDC allowance 0x66ba29ab… -> Unichain L1CDM 0x9a3d64e3…, 9 USDC, balance 2.531863 | 25,084,528 | L1CDM-spendable allowance | live, spendable by any Unichain L2 user (F09 PASS); victim error, rejected (ATTACK-F-05) |
| A-2 | OP | "Nolimit" 0x69eb276b… allowance 2^128 from 0x44afc83b… -> OP portal | 25,867,951 | portal-spendable allowance | spam token, no value |
| P-1 | Soneium | proposer 0x400c164C…E1b8, nonce 8537 == gameCount 8537 (all games by it) | 26,433,900 | tx.origin-authorized type-5 games (respected) | proposer never sent a non-create tx (ATTACK-F-07) |
| L2-1 | OP L2 | `MessagePassed` to any non-L1CDM L1 system contract (477 addresses), L2 105,235,063..159,654,093 | — | unproven object to a system target | 1 hit = L1-4; none to lockboxes, portals, registries, factories, SystemConfig, ProxyAdmin, AddressManager, bridges, WETHs |

Balances held by the 4 portals and 4 L1CDMs (WETH9, USDC, USDT, DAI, wstETH, LINK, DelayedWETH g1 + v2) at 26433900: all 0.
Not scanned: Ink/Soneium/Unichain L2 `MessagePassed` (public RPCs cap eth_getLogs at 1000 blocks; ~30-60M blocks each). Their
proven withdrawals are fully covered by the L1 scan.


---

## Source: `mirror/CATK-A/LIVE-OBJECTS-CATK-A.md`

# CATK-A live old-prestate objects

Pinned passive L1 read: block `26435245` (`2026-11-17T14:04:59Z`). No transaction was sent.

`remaining` is `maxClockDuration - getChallengerDuration(0)` at the pinned block. A zero value proves exhaustion by that block but does not recover the earlier instant when the capped duration was first reached.

The engagement's locked facts classify Ink game 2638 and Unichain game 17586 as countered wrong-root third-party games. This ledger independently pins their current contract state; it does not relabel them as claim-valid.

## ink

Factory `0x10d7B35078d3baabB96Dd45a9143B94be65b12CD`; type-9 results scanned `118`; old-prestate games `117` (status 0/1/2 = `7/9/101`); live old-prestate games `7`; coverage older than the maximum clock: `true`.

| index | game | creator | created UTC | claim seq | start seq | L1 head | remaining | exhaustion if uninterrupted | respected | root claim |
|---:|---|---|---|---:|---:|---|---:|---|---|---|
| 2632 | `0x744f0c04b36dae6ede21df1b8e15828f053d54cf` | `0x3832bfbef03173e4c49a00ec0dd178817a02d177` | 2026-11-14T05:47:59Z | 1794634171 | 1794028902 | `0x35b396ec74daada99ee2371a473be899a7cb9d468b6745f839106015b01e648d` | 13380 | 2026-11-17T17:47:59Z | true | `0xb7b7f47da1d1af9c90eb4b448fc9d41049d55e6757fd785f67b94bf280ac5f37` |
| 2633 | `0x0ee6062e27037cb177187a20ef50f40aad907274` | `0x3832bfbef03173e4c49a00ec0dd178817a02d177` | 2026-11-14T17:48:11Z | 1794677446 | 1794071862 | `0xbf714ac4dffa980c325f1a4d8a48e40019bef492f73d29a27a5ff24cd8337bdf` | 56592 | 2026-11-18T05:48:11Z | true | `0x9040cbafbcef7e52770bd54abf2061c930dce8b25512717d6f723817e1362342` |
| 2634 | `0xa820eae432e3459c19008ef7b586272db65e2018` | `0x3832bfbef03173e4c49a00ec0dd178817a02d177` | 2026-11-15T05:48:35Z | 1794720381 | 1794115377 | `0xc7bcdbf1351be371eef3fa2b60114f07826106dbaf1dee161275ba7ccb5f043e` | 99816 | 2026-11-18T17:48:35Z | true | `0x43836975dc290701e5832da8af2dc19f9cf72018d45c236da02277f5e06099ed` |
| 2635 | `0xefe72925d429386949834b780b99a8d13f4e92d7` | `0x3832bfbef03173e4c49a00ec0dd178817a02d177` | 2026-11-15T17:48:59Z | 1794763931 | 1794158322 | `0x87734593a759cf1e90811a81889359aef0398a073b63b71992dc66a508ca144e` | 143040 | 2026-11-19T05:48:59Z | true | `0x6bfe7b228c88a6c4a6e50f49c79ea1caa50875748a607d02ad91bcbfdd148f4f` |
| 2636 | `0x51918a4ebe8440bd9b0f1d29ce4a326c15c47c7f` | `0x3832bfbef03173e4c49a00ec0dd178817a02d177` | 2026-11-16T05:49:11Z | 1794806886 | 1794201752 | `0x897fac52b441701338456b9c20f4f22ee09314d88aac86a3a0ca0199e92c2be3` | 186252 | 2026-11-19T17:49:11Z | true | `0x3448e565df64d39aa51401397b4ba0bb045ac9942b4b7b46e712a802697e2e95` |
| 2637 | `0x73f3a9ed6671553e2bd51c80dd5792cb16914a0d` | `0x3832bfbef03173e4c49a00ec0dd178817a02d177` | 2026-11-16T17:49:23Z | 1794850266 | 1794244697 | `0x6ab58a85da777ecbf2a72f60f5d5065a06e83f65c6a49f9e38764868a9fdf9c9` | 229464 | 2026-11-20T05:49:23Z | true | `0xf68932ec061396ed7f6cf335807adda85153f381077c4ef5602fdf66c90ea687` |
| 2638 | `0x40bec00713a38ee5fd697764d50f0055ba4942cc` | `0x05f97bc048711287e912a72f4dbaa8faa7599eb5` | 2026-11-16T19:33:23Z | 1794857590 | 1794244697 | `0x1649243f348d434c968390751d1238f2b124843ed2caa1ac7ec37ba079bfdab7` | 235704 | 2026-11-20T07:33:23Z | true | `0xedf7295dc67ef81bfb2791da445ecf59f49a2d3cfb54e359fe5d628a30a5d0bb` |

## op-mainnet

Factory `0xe5965Ab5962eDc7477C8520243A95517CD252fA9`; type-9 results scanned `600`; old-prestate games `585` (status 0/1/2 = `70/4/511`); live old-prestate games `70`; coverage older than the maximum clock: `true`.

| index | game | creator | created UTC | claim seq | start seq | L1 head | remaining | exhaustion if uninterrupted | respected | root claim |
|---:|---|---|---|---:|---:|---|---:|---|---|---|
| 21308 | `0x5d62795e45fca7bdf9c20a26464e1bb4b4f369ed` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-14T02:07:23Z | 1794620587 | 1794012829 | `0x5169f43026cab3e8634c18f7f0cd524b6a737a2e50c8db97aa2e1c7dc20bedaf` | 144 | 2026-11-17T14:07:23Z | true | `0xf303ca463a66848a587fc0370b261dac061ac2cf70a6d46a260cea7445c69e6b` |
| 21309 | `0x9a6c2181666a999b28a484e629d55ceaad4a58fe` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-14T03:07:47Z | 1794624351 | 1794016317 | `0x7a7c8a4e23941f7cde9e0d670786b4dd37fe699349d0ea6ec4bb82fca0fc3e55` | 3768 | 2026-11-17T15:07:47Z | true | `0x5ec580b314d32ff8df7524939e50a27ca6b7f188923fa2b0bf562c82e57c637a` |
| 21310 | `0x42d0c7b4bf515bf95017d686fdf4d56d0d8ce9cb` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-14T04:07:59Z | 1794627987 | 1794019763 | `0xb50111af5b2c2e394641caabfc73c73fc5f7f3f59d9a4f37beff71f40357e82b` | 7380 | 2026-11-17T16:07:59Z | true | `0xc58f835553d264bf047e045675f35e26aa070bb28f6839ed695c005f2a0c6313` |
| 21311 | `0x604a3d4ddbfbd9e79c721f7cdae67367d4c65802` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-14T05:08:23Z | 1794631563 | 1794023299 | `0x56feb5fd58b4e01b80a2ec9311c2e1f356d922d3f26a04908b2a9cd0c0f289f5` | 11004 | 2026-11-17T17:08:23Z | true | `0x61e94c2d27daf94ed1dd1620a2eb748a469689b120670a90916bd4182ae1c4a2` |
| 21312 | `0x56edbfbdf987c3751fc7ac135849441a604c5500` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-14T06:08:47Z | 1794635331 | 1794027029 | `0x81781f5c8f63d02c56355ed3ccd544aa0b9e45af24a84309c33efeaef7ac4a7f` | 14628 | 2026-11-17T18:08:47Z | true | `0xeda39a822cdce954f906b09c1d944d1b4f6257249bbcd1907f7e82d269a979fa` |
| 21313 | `0xa807efb7b1f14f87fc8a8c7ede4354d5c708dd14` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-14T07:08:59Z | 1794638615 | 1794030905 | `0x666a5f00a4a50ee38abcae24bc265be349e15a4768cfddd7f1511bc6e5ff806b` | 18240 | 2026-11-17T19:08:59Z | true | `0xb73edb70a6237cd3f66cc48e4c3e212b1d90800a67c667d28646feaf34d2d91e` |
| 21314 | `0x7e0db25874f804d39a5874825d407c3d02888ba7` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-14T08:09:23Z | 1794642597 | 1794034249 | `0x1487d663b313e018d2ed84bab7a7f13ccc47e73f6dff8446f5d49b69fcbe29b9` | 21864 | 2026-11-17T20:09:23Z | true | `0xec1739a186eb78727c0aba49c061e6838e3d1086daa6d1700cc47125b3e8da8c` |
| 21315 | `0xa3c0e28a733db64982f03165e4506e8d55a7e63f` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-14T09:09:47Z | 1794646375 | 1794038173 | `0xcd085374059ddac4dd9eae9f7f7110c08950f164c7802a972caaeea03c4b9c21` | 25488 | 2026-11-17T21:09:47Z | true | `0x814f6c77c8da6c454452337b71c7944816f30d867cd26170e15e907bc5e06b6b` |
| 21316 | `0xfb7e8753ee9eb1a4adae6093d5a171f0950330d8` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-14T10:09:59Z | 1794649185 | 1794041615 | `0x71a132c9de08a06623b7b0d944bc714ecf12ee6705edbc99146488a2fdcbca25` | 29100 | 2026-11-17T22:09:59Z | true | `0x09682e12b991f52aa0fee8964d5b3aa6176f9b2f4485d321ed70f028071b5581` |
| 21317 | `0xb66e23508643def3dc4ae57efaadc3e10d8b9a5a` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-14T11:10:23Z | 1794653215 | 1794045505 | `0x6070dd6fe9806d725ee9ebb9ada511172e30766ff7190ae985bca4553aa60335` | 32724 | 2026-11-17T23:10:23Z | true | `0x3613024778ab34e601ddcba46a06fd12e23e8ec4c8f4a380a3b82b0e7b650ef7` |
| 21318 | `0x9a1f4df1504ac6e541404680e0fe4ba3df29fced` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-14T12:10:47Z | 1794657197 | 1794048955 | `0x71275a2d2b9920e4cbe7d746387eb8dbf318e83f41a94184aa23dea79ae3f0d0` | 36348 | 2026-11-18T00:10:47Z | true | `0x73b960ed4123f2d71e7abbb5d4e1aa7e0469e89c0639c665242b2c1f618fbe9d` |
| 21319 | `0x29f3295d88abc7366bd2f773bc1466f92238df44` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-14T13:10:59Z | 1794660457 | 1794052393 | `0x994dd1a3fb841b2b487819abbe9e899ca1160562cba2ac4d3e1078bf74fbba59` | 39960 | 2026-11-18T01:10:59Z | true | `0x392aafad8ff0759e426317e62024339d953e389ceba6c9a73e3106f560b552d0` |
| 21320 | `0x0fa76e448011b0f317d3a5921705b47cdc109902` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-14T14:11:23Z | 1794663955 | 1794056249 | `0xad766108915690651d99c7b68ef94891ae0e23149f85dba1eee6538322d0bf36` | 43584 | 2026-11-18T02:11:23Z | true | `0x6b2f1cc86811046a3fa814b53f89c3c0610a9c365e8aed35b476ce55b5588370` |
| 21321 | `0xe550318c54eab7aa04ee1f305544b2263b6eaa1e` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-14T15:11:47Z | 1794667471 | 1794059403 | `0x0356c805fc045c91e0545b83371e19b7be7a260aa595c834cec2a43ce52be760` | 47208 | 2026-11-18T03:11:47Z | true | `0x4d67f4359030649d4f2b51cc542869b31632981a40d9623d7e70a00dbecefa2a` |
| 21322 | `0xe14b40000fa8219a6802f7c3c2230602b65ca06d` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-14T16:12:23Z | 1794671337 | 1794063261 | `0x110ceb7d56084502e94458350b876b1a1799ff3bef5c3e1214bdc96204a3d5fc` | 50844 | 2026-11-18T04:12:23Z | true | `0x7cd12c583917b5cc04a44aa46850f961ffba96d04a751d8ba7b57a07c6fec4dc` |
| 21323 | `0x376aedab5fd05be14f16d07fbd530737ac3f519b` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-14T17:12:47Z | 1794674869 | 1794066763 | `0x5c7eced9ca50ea0569eae44cef8f5f17c38d66da7beaf640d9296c1b217126f1` | 54468 | 2026-11-18T05:12:47Z | true | `0xd1086baf1c71fc2c7c5c9be8e5567558ea2744aa7a61d4ca27eff6f6c277b320` |
| 21324 | `0x0b80869976041a42aff1be1fc0615c16e9127587` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-14T18:12:59Z | 1794678661 | 1794070465 | `0x7f32042d479ce14b1fd1905cf76f0d48dd3220f24f172300a17eaa6c3a4502e1` | 58080 | 2026-11-18T06:12:59Z | true | `0x2f8dc3c66a0c192beee7d4d3e9c1bd202e089e1bdb6542dac28ce3eb2bdd0993` |
| 21325 | `0x37992db2225a89c6a39cecdff9c6e14da302b625` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-14T19:13:23Z | 1794682085 | 1794073893 | `0x0c8bf2cd20e5b5fbf7998e60d241da7d07941e3b9bfe1ff05e0e3e2e541daa08` | 61704 | 2026-11-18T07:13:23Z | true | `0xda334ac7b9e04e6949337d92c66d42987c4bed3b97c99b676e9c509a0b91d2c2` |
| 21326 | `0xb48437026688dc642c9c653c21348428b18d51e9` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-14T20:13:47Z | 1794685749 | 1794077763 | `0x69cb0889ab3a760e6aaaa9cd6f20c3de8ef1740b68b5ef82379f662db2de4a90` | 65328 | 2026-11-18T08:13:47Z | true | `0x2b118aa7fdf43d5d14c18a62275b9a9f905ea2b6f98a530430c8b343d7edbc57` |
| 21327 | `0xe3b8f29d7ffbf0e23eeb2b20733f127007005392` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-14T21:13:59Z | 1794689303 | 1794081575 | `0x1ea58a7377e674c1814d56a7abeca3eb143783b5ae42527b36fde83a1e658cdb` | 68940 | 2026-11-18T09:13:59Z | true | `0x702066da38fd24f96d7f955a81c588ed2d6d225c05a2db0830d221a4e8360d88` |
| 21328 | `0x9061b48e6a580e7dadf61619f684d9de31089a31` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-14T22:14:23Z | 1794692927 | 1794084901 | `0x974350dfbb129882462cd4dd7afd6c2baf1050447fcd18b4d57548766ff247d1` | 72564 | 2026-11-18T10:14:23Z | true | `0xbc31585e5a001fabb7349aa37ad7a1d93c201c809944e57f232cd0fcc38041a1` |
| 21329 | `0x52d57410bc4ae0f73eb608cdca7697f823b74b94` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-14T23:14:47Z | 1794696755 | 1794088881 | `0x9e37c4fe4c3dba6b2e852852ab0dbfe53c4ea2ddcaf26bf7229d87549920100c` | 76188 | 2026-11-18T11:14:47Z | true | `0x6ed097aac01121284408a4291fd9ecbe2e0324dbb870c25f40a50424848597f6` |
| 21330 | `0xf1208563273f4535a66f27c3e485913bcd2727fb` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-15T00:14:59Z | 1794699979 | 1794092351 | `0xbae04a11d437fd2645449a240875a57eeb7b20b23d71609236cbadd7bae1343f` | 79800 | 2026-11-18T12:14:59Z | true | `0x600369e74a90c4fdfc3061ac3fffe83869549791f2fc2e56471da7422e7ee4a3` |
| 21331 | `0xbd608a5355de942370e87e58581888e1558b0b1e` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-15T01:15:23Z | 1794704201 | 1794096205 | `0x9cd009a2a1ce1b1a3990b52d0c5dc18e2d351452b2418caccc3986d8d5622afd` | 83424 | 2026-11-18T13:15:23Z | true | `0x3bfd30572eaf28683d6e68d150f10efaca0ed4c53fdc87797da2a6752232803d` |
| 21332 | `0x75522a4293bd9889aed50abce6896b66c2c4b594` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-15T02:15:35Z | 1794707397 | 1794099649 | `0x54ec4863f3f180c9e5269ff1c856fb7a46b1e6f57c59cd8d6b0f496981120b68` | 87036 | 2026-11-18T14:15:35Z | true | `0x018a05a214696b8584b425742bf6881ddc9efa5dd544a8951223235a24fbb100` |
| 21333 | `0x2437951011aced2ac9de07791dde970dcf42be48` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-15T03:15:47Z | 1794711177 | 1794103117 | `0xde632d006d790c262fa6f3d41caea07689f4649bdc76d4be129b61219f19500d` | 90648 | 2026-11-18T15:15:47Z | true | `0x3ccfd7f561d96d016804f93823875664ed430c0f3c5e135f057b68e8b796ba52` |
| 21334 | `0xdfb160c34c195dcb4b1e564cae86bbe11766f51e` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-15T04:15:59Z | 1794714539 | 1794106917 | `0x33b32b5750c9cc8703e6aa82392af8fd03c758e7a43c8a9e542c6c283d81639f` | 94260 | 2026-11-18T16:15:59Z | true | `0x2a14c3ff8dce38ebf47deff0ce08e58e14ce3b1ee65edf91ca348c8848c39777` |
| 21335 | `0x82b5f89e818e49026fe8754e96f7ee3de0128c2e` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-15T05:16:23Z | 1794718447 | 1794110617 | `0xc8da51c5d548e902dc58ba3b31b3f37136c42e8b0503ce9aa536ce628f1409d2` | 97884 | 2026-11-18T17:16:23Z | true | `0xd17d528aab30a92ad4ef74dd694cd33e8a0df71437d93dbe0934feb660066e5c` |
| 21336 | `0x5846f3793569f135f38359421ec0e6ac05d6ad57` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-15T06:16:47Z | 1794722111 | 1794113855 | `0xa34530b82386b972861bf9e4915ac0fab35e97e575d8d7cde8bbf00b45628aa5` | 101508 | 2026-11-18T18:16:47Z | true | `0x6782d1bc56706ce4b531073f7571491f56e794034d1857ad87ba442930fe25c5` |
| 21337 | `0xa780de57006589d149a3658f36e566911e8363a7` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-15T07:16:59Z | 1794725579 | 1794117687 | `0x83d18e06704b53b5b12fd3101f4406e88f0c7784d9af4ea2b4f845686fa04936` | 105120 | 2026-11-18T19:16:59Z | true | `0x649ae36d8bea0ebed571b6b7cbcf3e9077742c6fb16e7e1d6d7451a2fc2d344e` |
| 21338 | `0xd0d611a166c2ec84b2de169b1b6d4fa4fa61a415` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-15T08:17:23Z | 1794729421 | 1794121545 | `0xbff1031d0af78f699de8d08a701e3b38bbc52cb90eef00fa885d1f3edb5b7567` | 108744 | 2026-11-18T20:17:23Z | true | `0xc6f2c9a985a99e515986355a7783b265b835ab9af46c962c5d6169ce34d07cc5` |
| 21339 | `0x34f0653c084591e78e558422fa83405c25973e8f` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-15T09:17:35Z | 1794732711 | 1794124993 | `0x68bef01f6709b39b91b4bddd4106eccc384e456074adf824109c355513d821c0` | 112356 | 2026-11-18T21:17:35Z | true | `0x5a07f47b8575699928c7f68fa5bcf22f7bedd56aae77d6b9856de3cd55671e9d` |
| 21340 | `0xeabaafef8eee36e769e528d0bd916d074c01eb83` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-15T10:17:47Z | 1794736693 | 1794128837 | `0x9593c76abb8feb49cb1587f756e5a8dc3082fdf1b5c840ccedd5e97cae68d49b` | 115968 | 2026-11-18T22:17:47Z | true | `0x8c4783a0edc32ce84b006b670b6ab4ca15949f93cd3a7435d3f1b473ccd90798` |
| 21341 | `0x1637da079f68869eb28590c7168d89b49905e568` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-15T11:17:59Z | 1794740465 | 1794132075 | `0x4183792e9c4354c9a56f7162af05f79d63cac7598cd1a36307e681d6ef238f30` | 119580 | 2026-11-18T23:17:59Z | true | `0xab4097b1991980ce1b26e284c7cdf16e2ba010ad974386d2bc6fa36ead6ce751` |
| 21342 | `0x289b26fefa499be24f6fb9e1ff07a565950c6d4c` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-15T12:18:23Z | 1794743465 | 1794135685 | `0x254b2995466c90331db1f85b37fb7a5a3c8373fc24edad521a9478d1ecd42c9d` | 123204 | 2026-11-19T00:18:23Z | true | `0xe3cdb11acba090e579a22defe5a29a01697564e25b4500e17e491effbc32adf4` |
| 21343 | `0xe1adc6eebbea6378befc5510896798bf13b3348e` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-15T13:18:47Z | 1794747421 | 1794139211 | `0xf91c9981498c9f36433ce39e15da50e8f05685c34dcd9201caab9c0a99dc7058` | 126828 | 2026-11-19T01:18:47Z | true | `0x7539f326d9f7126c0116f062f575b290bb16a195cce3afda550b3e6727d37605` |
| 21344 | `0x8f8d84a24c6d44479a89974773c3b2bc3860723c` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-15T14:18:59Z | 1794750915 | 1794143027 | `0x9c90e015e794e9b1791d21133ef8fb23cb543e0657ac20e1b5f7f174bb00a994` | 130440 | 2026-11-19T02:18:59Z | true | `0x314e4bb1d63c3fef3223c8edca7401625cda101880585d414d68ce85c42ef004` |
| 21345 | `0x3c5166e2372af8392cde3a375e4c913e7d3d8038` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-15T15:19:23Z | 1794754609 | 1794146459 | `0xecdaeef9e78441c7c8f1a7342078f46c9a6c9861d7e855f2d47eae33bbbcacd1` | 134064 | 2026-11-19T03:19:23Z | true | `0x12c4b15fbae8caa9557945fc17a1ad1afc6ff980e567b1ae4c1734da4667b855` |
| 21346 | `0x831ced87c187697c17fb9ff8e1a4117402256b84` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-15T16:19:47Z | 1794758225 | 1794150311 | `0x84f92ed2f8bf16ab39337124f764cad9618159c9b523199c8fc9037f8bf973f6` | 137688 | 2026-11-19T04:19:47Z | true | `0xedfe1f9b87c0cd89b6ad536179ca3f6c3b1a015c0c8bee17846b33b30505f5a7` |
| 21347 | `0x52f23aa10a1dec189f798df52d727974a73d7555` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-15T17:19:59Z | 1794761537 | 1794153657 | `0x988a79f6921c1688219329857a4394a5e2759b2fd715866da1f2fc0c0e7189a3` | 141300 | 2026-11-19T05:19:59Z | true | `0x7d55081a756d1fc460e2eecb2eb0c9a723887baa39f5e6eb91b122f61e7b0a36` |
| 21348 | `0xd9680757c24cdc1118d0f767083eef0354268ba7` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-15T18:20:23Z | 1794765237 | 1794157635 | `0x98d9abc03cc5c222a6ae573a6660a6b1dd39a1b7102b13761336f55acf0d11a7` | 144924 | 2026-11-19T06:20:23Z | true | `0x8e8f1c7a4b0b420a161ebd26079b70e850fb0ee43b755c301173af9d61e1b02e` |
| 21349 | `0x01a5438720d76b6f6ece15bc3bcfeea905877a48` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-15T19:20:35Z | 1794768695 | 1794161085 | `0x6270f61761c70cd4bb31dcc39fc542671fcaed17e2e2d8110b0849108532fb61` | 148536 | 2026-11-19T07:20:35Z | true | `0x5efb1031b22f6517887742294dcfc264fc86149729cefa6220afe10c9f237882` |
| 21350 | `0x2f55f48e8318a65d374f4113583279fbac8d86fd` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-15T20:20:47Z | 1794772435 | 1794164457 | `0x16ae896c58a41b9346764e5f0298b7676a6c22523dc1a39d3300fe1068455994` | 152148 | 2026-11-19T08:20:47Z | true | `0xf193a51e29ae04a209454c24ceb4d7cf4252ff6d5121f0a5355567a8fc5cdcc2` |
| 21351 | `0x471576814df2b372be3a84c5333c6590e9ea4edc` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-15T21:20:59Z | 1794776085 | 1794168399 | `0x835df05a801aa74af0a55ab97e07133283d8fbd59e7678c56b4283ffb6d5b02e` | 155760 | 2026-11-19T09:20:59Z | true | `0x5236832abcb015193323117214b2234d17a85e03a38958e12ed411dbd0953171` |
| 21352 | `0x70b738192a882889d349dafc67a8245b99d168f2` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-15T22:21:23Z | 1794779921 | 1794171611 | `0x292cf8fadef4bfefb0f68496640c9eee676c01d61a795c7fbdb457a4bf4f7b49` | 159384 | 2026-11-19T10:21:23Z | true | `0x62d7eaa27449505e202dcf7463ac2f11371357af6ca3988809d1f29967102a56` |
| 21353 | `0x3869b9e1d60160dc5da914ee9be8baaaf0e91f56` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-15T23:21:47Z | 1794783427 | 1794175601 | `0x5109c6a5478cf04213bfb2d2caccfc35bde8d963fb446c99518da7813afe9a18` | 163008 | 2026-11-19T11:21:47Z | true | `0x4285c17123bd0066b9a431a310691b878b30f2766ee16f6c800eb0fc376b77d5` |
| 21354 | `0x6090329d585a4889e25d0f191332ce9b5295aeb8` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-16T00:21:59Z | 1794787081 | 1794179039 | `0x226ab5e19ddffe3465151ba3adb5ec653d075acf373b387bd74224be32273149` | 166620 | 2026-11-19T12:21:59Z | true | `0xdd18a90b6a0e7ff8ce34ff171240227c0499ccfb525ff4428183f39f40f6390c` |
| 21355 | `0x3612fca1995e2eaa46dc65c882daccc91ebbeace` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-16T01:22:23Z | 1794790749 | 1794182533 | `0x454428ff44f2df63e93efe63b0cd2004b08812a27963c0f50b912d4288f70857` | 170244 | 2026-11-19T13:22:23Z | true | `0x4e11f726878c1f9e42c62eced1d350ccbcaf49a516d1c95f9fc5d0055a7bebdd` |
| 21356 | `0x0a2e147ab60edd12889aa9dff28c7a59b2f57bff` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-16T02:22:47Z | 1794794253 | 1794186435 | `0x9397054ac425bfd480826ddfa08fa1f45449d1f9f7e6ccdd0e176ec6cc67c8de` | 173868 | 2026-11-19T14:22:47Z | true | `0x44b6fe351a256482e31222ee9f4fc0c4298dcc9a3b356bdfad9825d4cdf2760f` |
| 21357 | `0x1607edd4232b556232c82f441b300bc5bf404700` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-16T03:22:59Z | 1794798123 | 1794190065 | `0x69869c2202b69959ae1e7d9ff7f40af87a32a0c13b00a376da69ed58948f8c0c` | 177480 | 2026-11-19T15:22:59Z | true | `0xe45d89efc728f21e4de2278eebd0ce0b22655083889dd686d03f9bd2c898324f` |
| 21358 | `0x43484bcd22c30d53a69dfbd829122e3d75c1e06d` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-16T04:23:23Z | 1794801573 | 1794193701 | `0xfa3ed166d1b7037d1f9f2edfacb1a1f66c707c1eeb5a2a41f7dd2cb2211c4781` | 181104 | 2026-11-19T16:23:23Z | true | `0xe311e7408102517647122f504e0987cbd0bf6a1b6a1945cf5ce611d5d1c693db` |
| 21359 | `0xdabd4b65ae61b75bfb63ddfe6531a54fd9597e70` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-16T05:23:47Z | 1794805259 | 1794196959 | `0xad72c95148ceff26fc39da5bc31e1c440c0c0e96a16844af6bf662171017a667` | 184728 | 2026-11-19T17:23:47Z | true | `0x6ad5c0d51675cc21b6d40df4ac6d72224a02ca04c4fed6129f6c965c6333f6f4` |
| 21360 | `0x120f3b5f61febfed1194366fd6976c73a7ef24eb` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-16T06:23:59Z | 1794808875 | 1794201017 | `0x445a1981390622122864370751c9578fbad5221192b365923045c05e0a9716d1` | 188340 | 2026-11-19T18:23:59Z | true | `0x50c40317f159827a7df1743e4a46befd2bf7a588851b95e1fe996e4ba5c20820` |
| 21361 | `0x41166652da61ccfd611c2689d3b1c3b42bc58913` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-16T07:24:23Z | 1794812741 | 1794204457 | `0x1059ea2ee5692d5f2f577dae55f7ee9f5b3d78e4025ad1454f312f439a8c828d` | 191964 | 2026-11-19T19:24:23Z | true | `0xd464a8c7999620e64dcf094654426182cd719aea5fc510c85ca756380de9d759` |
| 21362 | `0xb906be0127c8f9e3044daa9e10f6117f6cdc87f8` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-16T08:24:47Z | 1794815909 | 1794207903 | `0x6461b1a35871848b526dc24ca8ce7cc0e3b23708097747a70ac91fc42f88f66b` | 195588 | 2026-11-19T20:24:47Z | true | `0x347e56e83005f71e3f9a083cc125edb0e62d53ddd58976ed21dab4a536992bef` |
| 21363 | `0xf0bab059d64d0fd981cb3936e4b0999c4937ec95` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-16T09:24:59Z | 1794819973 | 1794211693 | `0xdfbdfb3468e236cd5a52da161a098dd765fcf5178ccbd11c7161267049165be1` | 199200 | 2026-11-19T21:24:59Z | true | `0x42eba9b17bf5d72f22c610647f326919a925e5c6ba4ccc56c0da77e234c57d56` |
| 21364 | `0x4527a4ee6cdb3fc84f5e0d8164de476a5b6d700f` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-16T10:25:23Z | 1794823459 | 1794215227 | `0x06c7688f651ee2aeb921ee73809b63a80c1ff8a28f63b36e9f988e9a339e48c5` | 202824 | 2026-11-19T22:25:23Z | true | `0x6259967f3acbefaa9a53b71e230e564832003fcb0fb2ffd7fb0d1e06e3aa1d97` |
| 21365 | `0x6c4f912f460337f661f59ea71835872469e54d07` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-16T11:25:47Z | 1794827327 | 1794218909 | `0x90d86442e447acb324042ea37573c0029a503353f1a818a7acf52ae8ef691eb2` | 206448 | 2026-11-19T23:25:47Z | true | `0x3aa05630f10b98dc0ae2ed47934feced48e2ef7f5de5519b80d8ef333092e17d` |
| 21366 | `0x5a93a8d05c29dc4636a6cd6085cd1195170fcd19` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-16T12:25:59Z | 1794830753 | 1794222525 | `0x84788852076ecb8e7451a063f9f6bba92eff45521d810fd62b851692ec945759` | 210060 | 2026-11-20T00:25:59Z | true | `0x3d18c3ad5f6035067b159ec3c0d3b5b343843fa18d3fc35fc137ec4b7c0581a9` |
| 21367 | `0x16a332e6ddf7a0b883134fac1a2d45dfdcad87a8` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-16T13:26:23Z | 1794834079 | 1794226377 | `0x7e00cc91954fa1f2dc2720ced38a863544863fc9172d97b8996ba9902ddf83bb` | 213684 | 2026-11-20T01:26:23Z | true | `0x272bb328daee4bd390c20bce6cc9a8ebd8dd291c000e1bd6da4c82f144a52d5d` |
| 21368 | `0xe6635dd0c88121d9d67ba8d6eb0c01d344abde99` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-16T14:26:35Z | 1794837703 | 1794229779 | `0x4558951495bf3476bf6eeedb1fa4a65662ecc8901de4d04bd32b3a5439f58e9f` | 217296 | 2026-11-20T02:26:35Z | true | `0x454c43883362e934d58868a96f4636e8e43df6a0d4ec67c123905eb5579e8aae` |
| 21369 | `0xb6e78e255927efa051603304e6337779351673ca` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-16T15:26:47Z | 1794841417 | 1794233245 | `0x098322dedd8444feab1a19b9ff309e955c6979eb6c4cd7d3e8cc485784e5ceb1` | 220908 | 2026-11-20T03:26:47Z | true | `0x09a06d34868a6bbf234b00768057baf600693fa2a0a5cb3b0256e51338c379f1` |
| 21370 | `0xba898b5cbb1b71f8adb7da980f54b3333fea6dcc` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-16T16:27:11Z | 1794844823 | 1794237095 | `0x26948024c153a6fbcc2811b645114db78677d958029ecc7a1157b09b659d5a28` | 224532 | 2026-11-20T04:27:11Z | true | `0x09b37b5cec1ab08b3493553faab19ef34bc439705b9d6f7ecabdf7ab32231254` |
| 21371 | `0x02b0054371e367cb623068d1b41a41e6122b5228` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-16T17:27:35Z | 1794848809 | 1794240307 | `0x3001c19939c0bda657b42723b64205f9bc401da740dc0c21f16990355f2c9808` | 228156 | 2026-11-20T05:27:35Z | true | `0x4c769b3b4110dbefcd956b31c16298da5b50c4c02cd86110b5614616ed8426e2` |
| 21372 | `0xbec6373fa5b74517350d9cb358a5e7d9f3dab356` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-16T18:27:47Z | 1794852035 | 1794244171 | `0x4a65bc2d42a0048109076e1f9daf50ae65f2beef2d2f2a93f916ceab97c6431c` | 231768 | 2026-11-20T06:27:47Z | true | `0xd4d07e09fd99450785674b96eb78c8daa6fbc00d184b4b3d718a2e6e7092e961` |
| 21373 | `0x86512332b510f40bb9361de685ca1e4815dee5fe` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-16T19:28:11Z | 1794856099 | 1794247695 | `0xcbbe140542ea731cb88a6930e0e388f97ec736ff8c6bb959798e2cd65603271f` | 235392 | 2026-11-20T07:28:11Z | true | `0x80f5d89781b95fd956cd06d8075ca3441ee2332b5510dd7c23c49fec5047f0ca` |
| 21374 | `0xed801ca7a455d356aa18eb129c3fb1bcf138cf54` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-16T20:28:35Z | 1794859883 | 1794251427 | `0xe9d84880034ec9649338983f04e2c210c0390bbc89c14dbcfacc3aca09b5e247` | 239016 | 2026-11-20T08:28:35Z | true | `0xbc92ac5308b4f4edaf7e8a79ab0400302170438466f4ddbea7ad10f4ad540d61` |
| 21375 | `0x3d2291f923c6300abf9163423adcd6475222bd97` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-16T21:28:47Z | 1794863317 | 1794255125 | `0xc49944239d916a5b62cd4677ac99f7d8b1ac44f62cd435e6b3fd65d48fe48283` | 242628 | 2026-11-20T09:28:47Z | true | `0x796eeee079c343d544efee0c714c5444b8ce9b0d0bd36004c545ed1bb5308141` |
| 21376 | `0xacef7dccfd06e8a6e61e8411db2e0bd7300ad233` | `0x473300df21d047806a082244b417f96b32f13a33` | 2026-11-16T22:29:11Z | 1794866823 | 1794258467 | `0x545d9188f63831692878a11aa612846b0be922f7c75fb45ebd59550b0b65ae70` | 246252 | 2026-11-20T10:29:11Z | true | `0xb47e51b195688553600a201aea87c0819e9d73c8c7efe5957b56bd169c05c991` |
| 21377 | `0x675e956b1912df79108408ca524fb37810500d10` | `0xc27ba3e0fc01567a5e57ae0c391aa98cecba5be0` | 2026-11-16T23:02:35Z | 1794868743 | 1794262423 | `0x3279c57099aabf9a17de5d1192d906e4664fb71eed04071d2ef3c4922670b82f` | 248256 | 2026-11-20T11:02:35Z | true | `0x3c35e3118a9795065e6283c0b2efb02330e19e1c6ee96842a8d0088314affda7` |

## unichain

Factory `0x2F12d621a16e2d3285929C9996f478508951dFe4`; type-9 results scanned `600`; old-prestate games `586` (status 0/1/2 = `70/11/505`); live old-prestate games `70`; coverage older than the maximum clock: `true`.

| index | game | creator | created UTC | claim seq | start seq | L1 head | remaining | exhaustion if uninterrupted | respected | root claim |
|---:|---|---|---|---:|---:|---|---:|---|---|---|
| 17586 | `0xa41214c2851f0d538b7c6b37fa66e35472ff6f0e` | `0x9995c45126e493a80af417eb3f3328a1e4511543` | 2026-11-13T01:02:35Z | 1794531731 | 1793923307 | `0xe698792cf583207b99fccd19a7fc0ec6a75b6176c2f5821883375d45c859b8ca` | 0 | exhausted by pinned block | true | `0x384e8ef313b6a23e2b1d474c162cbbed22337e8c6842bf5258fa9caea4a42dc2` |
| 17612 | `0x9f5ba1b624ae4b7cff2ee8918fb0977d92803c44` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-14T02:37:35Z | 1794622487 | 1794014187 | `0x43f1aee2976c0c1664a685b1c04f44817368b6aa511ca8e3288b6c7c71fa7076` | 1956 | 2026-11-17T14:37:35Z | true | `0x4b3a2a447bdc553f5a50d823b08e8dfc13c72f18ae07534356d2a548147aeae9` |
| 17613 | `0x270f935143276d53467886bf6b5e428abd4fdd17` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-14T03:37:59Z | 1794626093 | 1794017362 | `0x03c571bd8c0a303c059032e2b0d4776a3dd0f22deeb9610a7cb676b286e13c39` | 5580 | 2026-11-17T15:37:59Z | true | `0x2ae36cf6d7bd05874a34f8d802ed2785d90ef2cac3986020fe4d0d88ba87b561` |
| 17614 | `0x2307b425870f4f1be576f1d8f2ab9ae39a06bfa3` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-14T04:38:23Z | 1794629950 | 1794021632 | `0xf0fc35db0d028f788b36a9f828787c9868017b3049101693797ee92fa8fdd9af` | 9204 | 2026-11-17T16:38:23Z | true | `0xca50121f2ec2313dd65c219317551509507c301cbb1f3a076bf080d2ad70ceee` |
| 17615 | `0x73eea973212474c002325fd9c757e61665c6fff6` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-14T05:38:35Z | 1794633062 | 1794025377 | `0xe209d10b272725d0567ac2097b7fd601127b04c17f2d75302c5e57575c2996d1` | 12816 | 2026-11-17T17:38:35Z | true | `0x5b10a3f9203c0fc03b7cdbd05c886329aed3c450767e625ba6a5964bad2f70a1` |
| 17616 | `0x14482d0e515ee8b3c80519ee4bec3d4732c5bf5f` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-14T06:38:59Z | 1794636787 | 1794028557 | `0xacef4d78f64c1dcfde08995bdfa5d1314a968bbeb1c0754bba6879f8bcb84ae3` | 16440 | 2026-11-17T18:38:59Z | true | `0x589ba6c2284530c3de79e7fb8948b7ac5d964774eca2113c2a6d06177ab03eb4` |
| 17617 | `0x179442b69eefb9fd1dc303f79cbbf291de579981` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-14T07:39:23Z | 1794640507 | 1794032272 | `0x53144b96d43be6c0997f59e089b44a5a0ee7aaa0cf766da132c5ba7046982d04` | 20064 | 2026-11-17T19:39:23Z | true | `0x31d4d7e8f8885a125d8da365c06481e36a2a4ad51da38527cf25dfa14701aa33` |
| 17618 | `0x926d17b331c52fa53f1e3f2be4a19a6370b2e46c` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-14T08:39:35Z | 1794644207 | 1794035467 | `0x4b23897150fdafd3cd1bf60458991d026e3172a2c1a212958ef16a525591d52b` | 23676 | 2026-11-17T20:39:35Z | true | `0x3e81c1852897c44b7f2de4dd0fb34db66873183918aee13dc0704c423dbb29ba` |
| 17619 | `0xa9f49bbac95726aa4447eb61140bb77bb8ccc626` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-14T09:39:59Z | 1794647912 | 1794039707 | `0x31dfc967cfad0169a36bd39ddba741bce829f98579b6df834af8088fc7537af6` | 27300 | 2026-11-17T21:39:59Z | true | `0xa8f54ed1312317380aa89b958f2ca3127dbbaaa25a02fb2e6d9e81b01267e395` |
| 17620 | `0x2e8059dbcd2230528cadd9d7639ade15318a648a` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-14T10:40:23Z | 1794651537 | 1794043457 | `0x8e955481bdfc5acb7fa9558da6a0493435b11ad27603f6423645652d3cd8615a` | 30924 | 2026-11-17T22:40:23Z | true | `0x6c7b19a96deaed0eff93d8b9f08d7900251454b11f19d3d896ef27b0fbf92003` |
| 17621 | `0x27aad4cf253fd47187d90c9f8ac90cf06ad87382` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-14T11:40:35Z | 1794655252 | 1794046692 | `0x6ca7d534173d3f845f98d5b4e7c408eb05aeb0b6f7cd7ae187f2b20b7cab03fc` | 34536 | 2026-11-17T23:40:35Z | true | `0x5b2fdeb8bd03b01c5c8d78faff25cbf5390b5739b7641fa8cdf68e4ffbf98685` |
| 17622 | `0x50a4412b71a7cb395bf9e14bdcd5e75a3b0a5321` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-14T12:40:59Z | 1794658967 | 1794050417 | `0x67c99528ab11c2cf6b326b311f937c3cb529b87f0455dc5069a6281f3783d4b4` | 38160 | 2026-11-18T00:40:59Z | true | `0xc504c75092c2fe4464d5c1491aa43205570eae93037dd9b140868c995c3c3b03` |
| 17623 | `0xd6f1b47be44750bae3e3810c83967a422b49f974` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-14T13:41:23Z | 1794662347 | 1794053602 | `0xeada0b6dd29a39c302b87868dfc126bcaba95c7706ad88571fb67a413e9ed3e9` | 41784 | 2026-11-18T01:41:23Z | true | `0xf78ab0296909ae380a84965f1c162b4984c7b2fdc57a217724c6598e98da139b` |
| 17624 | `0x759c3463145e6dedff2b812e3bbc751885c0ea60` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-14T14:41:47Z | 1794665812 | 1794057847 | `0xa55d25c1c6e887bbefcc531c8ad8ba706d9e428faffac4674ba318cfcd547517` | 45408 | 2026-11-18T02:41:47Z | true | `0x2ae5058b35f734a6b90b15f237617943329dfd636f3aece20dee1a6672fc3607` |
| 17625 | `0x0ec5dc2028aa5afe9087d4f9e39e6c5172d70985` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-14T15:41:59Z | 1794669907 | 1794061552 | `0xcab1a0d122c718e51154a50dd339f7d01de1e51e7ed5699d6c642733aafc0c44` | 49020 | 2026-11-18T03:41:59Z | true | `0xa3a8eb1a7669b9ec55e2ccc3b4558533e8970e7d659859ab3ae9cb442a40a021` |
| 17626 | `0xa6286d46516b9500152024b784a20888a7d899d1` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-14T16:42:23Z | 1794673122 | 1794064737 | `0x73d8ab4b05be7addf2af3195f79738628779c4c04014ff67327d91436d51655c` | 52644 | 2026-11-18T04:42:23Z | true | `0xed51429d26b7637e5e052263a8026b7ea4a14af5f767c3b544c8cc237f582e4e` |
| 17627 | `0x76dce9c0a76687276bc633e2da864a03110be32c` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-14T17:42:35Z | 1794677111 | 1794068442 | `0x5e0f677f46ced27e8fd97937c353565cca89b3f8abe5b0f2a70a9fb6f4b630d8` | 56256 | 2026-11-18T05:42:35Z | true | `0x21c3712f13e297089f3cf07f7a5a4b7be68785a92fddd0f504063f8a5be82616` |
| 17628 | `0x939a7ff79fe3d77df5be98b33d4b726001a08d85` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-14T18:42:59Z | 1794680557 | 1794072152 | `0x2f3073087bbf47365e502424ffecd4d16e59ecf88d2564c1349a15c2d60e7a8b` | 59880 | 2026-11-18T06:42:59Z | true | `0xb76e354ad55471d2a65ef920b5314ab630dc4527f58efcf30c012e8d4cadae47` |
| 17629 | `0x1780e6bca8cb2b757da2100f6118a4b8346069c0` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-14T19:43:23Z | 1794684177 | 1794075857 | `0xde366402543d681a6b1f13a066bc6d3f47f1f7d2375ead22bdb8accb85b39ddb` | 63504 | 2026-11-18T07:43:23Z | true | `0x591adff1ed7274eb8bce8f3fe1888ed9bc69e52472169fb42ee52760fece85c8` |
| 17630 | `0xd9151e10c2752fadc5187dd91a66ac8a4ee46900` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-14T20:43:35Z | 1794687707 | 1794079612 | `0x123602bcb294aff15ebc68da90eac664553e05148139e5f3de9cfd87d8f83780` | 67116 | 2026-11-18T08:43:35Z | true | `0x3e5bc6a643c60c7e7f6f02dece20048451594fd1b84498579817d8c59d3df9cf` |
| 17631 | `0xc0184266b78fb9a934bf2c9515834572bd050d3d` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-14T21:43:59Z | 1794691151 | 1794083322 | `0xa08fcf7acccdb2ac72528d7bf0609e224365ac78a6a7197236cf22dedbc16521` | 70740 | 2026-11-18T09:43:59Z | true | `0xe63d429e287ca744510eeb60abb34d47b48306c1fd9a04637a52e20e90652c0d` |
| 17632 | `0xf794d5e45dfb102261b2e75648c77e014569d959` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-14T22:44:23Z | 1794695097 | 1794086502 | `0x19ffe1375bd782b36ce45c4864bfb97c8d6a4520caa12c387a2e37986133f98e` | 74364 | 2026-11-18T10:44:23Z | true | `0x3c9cb865ccb6b7292ef831d8969e1aef9640cf80d9f7bb6ec5a6ad3db74de544` |
| 17633 | `0x9aee25e674b401d3cd280d785c40618627ea42b8` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-14T23:44:35Z | 1794698267 | 1794090222 | `0x48990dca65cc5e6fc080959f0df5133aa4c610f84f91e7eaa810bcb565434374` | 77976 | 2026-11-18T11:44:35Z | true | `0x5293e4a5c6f6a0eeb1b8952d4795e88c9b7bb94a137ab4ed0c51ff62825748ef` |
| 17634 | `0xc8a9dc9d143cd9eea95ffa957f42a26026a43262` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-15T00:44:59Z | 1794702487 | 1794093427 | `0xe4b319512d28a453da61665a96e49b449ace6b5ae492c6177ee999e7d8f888b5` | 81600 | 2026-11-18T12:44:59Z | true | `0x5fab1db4d54abf58fba24f6433f91517b9a338afed8a9d93bf20fc9b12095625` |
| 17635 | `0x344ba92facb46a1dc3c07e9c94f8fa70fb0305f0` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-15T01:45:23Z | 1794705835 | 1794097172 | `0x6766cc58115bd4f22201f0d542a09c35bfdec5181f9f535f058d4615231c7c16` | 85224 | 2026-11-18T13:45:23Z | true | `0x6faf59b9027f08ab24d87311c98b7e6ea9226a46caa1689bbe4c1c25b291b011` |
| 17636 | `0x04411757bba3da5ec47b825b562d08a4aebfb066` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-15T02:45:35Z | 1794709167 | 1794100892 | `0x46cadb03ebe187c78ce430d4e8239bf99d6feb431883d28dc17f5499a7942462` | 88836 | 2026-11-18T14:45:35Z | true | `0x6557c161257bc30cc9567d52aac7fc4dcb8cf07b727d16ddf75ac954819cdbb9` |
| 17637 | `0x5d22d047733670ed266896eb6d1208a5dfd20ed3` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-15T03:45:59Z | 1794712932 | 1794104597 | `0xf5820fe49ba04afeb08280af4d91e5e050645d5bb2d439e61dfeab40d018a098` | 92460 | 2026-11-18T15:45:59Z | true | `0xb5f0b3b8560614ea6acbfa10923fa3d26e57e4c9a8a349048dfa75ad39ec1472` |
| 17638 | `0xf8fe5998aa3aa364f0a220a9c0155e522417d9cc` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-15T04:46:23Z | 1794716452 | 1794108297 | `0x2974f7c708788f8866f00c785146540cf0337b4cbb696bcafae6acef67f1e509` | 96084 | 2026-11-18T16:46:23Z | true | `0x663233cc900440c989a2cce0d4953c92b0d4f1fb9961556c564dfcb579947761` |
| 17639 | `0xb37d809f3dfc85807372295ac844622c85bd5719` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-15T05:46:35Z | 1794720147 | 1794111512 | `0xfab97b6935ec0e15effa18eda84a0c91cb174c5d4747e372d3ec6f4b68145927` | 99696 | 2026-11-18T17:46:35Z | true | `0x424a719f3ca0839e4f9adbe379f0cd7688e734c760774c4f03633e06565650b5` |
| 17640 | `0xa32ac95d7de2bbb6a8bc3c6785d0ecb2b3b73bbc` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-15T06:46:59Z | 1794723895 | 1794115292 | `0x092f0d642d0c79bc53b0829a27d500819508ec9721123a27ef29d798ee602c46` | 103320 | 2026-11-18T18:46:59Z | true | `0xb3eb332b13f10177d7d914211cd42531d68926bc7710f79bafadcef343dc9c04` |
| 17641 | `0x5956312b018e00942c96f6dee586cefb023db31a` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-15T07:47:23Z | 1794727782 | 1794118987 | `0x1720b263c0e8fa2fe9f30b481c8c14df3c0d8808d714d98b5e9fbd451f91de8c` | 106944 | 2026-11-18T19:47:23Z | true | `0x098f63de7a4348fc243e8c9bb24239a5b404474fe204c59a7d35c9465dc26d2d` |
| 17642 | `0x651f59b677396b5f69356a4a1482e2b754c0d170` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-15T08:47:35Z | 1794730987 | 1794122682 | `0x9a2d0146f40605af76f00580403ca0c7a6e6f72ed5c8e04b6cd405e9e01327a8` | 110556 | 2026-11-18T20:47:35Z | true | `0xe4acf6f56b38e26307d7eff24d1479fbe599efec31619cd2bdc509f89591a5cf` |
| 17643 | `0x451dac81ac55200561e222b60ce3e94bd0970efc` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-15T09:47:59Z | 1794734687 | 1794126402 | `0xe7aede8233a30272a79c5f3a76f74ec72e56f4e83ac6742bf1c9e309ea84ef75` | 114180 | 2026-11-18T21:47:59Z | true | `0x150e5f0a05c14da06ebf52ae08879f6338dfb80e5ffb18cb94fb1a8d300118d7` |
| 17644 | `0x32d27afff5b5497b7f34f1c75c050eca00c29586` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-15T10:48:23Z | 1794738392 | 1794129597 | `0xc5cd623f193320213907fe0212b57734dfc7fb66e7160132a77384fae7da41d4` | 117804 | 2026-11-18T22:48:23Z | true | `0x66a14a911f71ba757bbe5733dfd24ef8c0ce2f86be69bb56181670847362900c` |
| 17645 | `0x00e3fcce5793a3ed2656e5bf896b9284ba50040f` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-15T11:48:35Z | 1794741582 | 1794133832 | `0x77347f7076151df3ef6d70fb0abe062bd5c592796990b7f42e34733e858a7906` | 121416 | 2026-11-18T23:48:35Z | true | `0x5265ded843f6218da85fc92e4f3c5a7782a688ad30c3a951af124c264d4e7583` |
| 17646 | `0x040e349657b12e44e6376bb01acdbd48298f948b` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-15T12:48:59Z | 1794745817 | 1794137022 | `0x0d07acdc2db44c99387207ea2ef01be890464b4a5e17a9c013b1d0f877395d2e` | 125040 | 2026-11-19T00:48:59Z | true | `0x80363c1685c9ecf13d0f00f999b220520932df585013a03440acb0e89ad561cf` |
| 17647 | `0x973dd439d082e7b524af8bf39018d3dd2b7ffcf7` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-15T13:49:23Z | 1794748997 | 1794140717 | `0x859db19a329d0caed99f5fccb44d293d462d8427dd3564c0dd07f86be281c172` | 128664 | 2026-11-19T01:49:23Z | true | `0x94f92008e1a83de9a3fe04a4b73fbf256ee2f8f9a7834e791ed21483f45263b0` |
| 17648 | `0x1af49c9ef651a623f7eaf0b99c59b37c7953f074` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-15T14:49:35Z | 1794752717 | 1794144427 | `0x3a48218e5f59fcca9cc757e05a4a4806f2099e6037f02b6680e2c6ede129b7f0` | 132276 | 2026-11-19T02:49:35Z | true | `0x9145c7c7b6ff7668df25e8bfdd40e18341ac6332c0577546a8ed92e1941d6595` |
| 17649 | `0xd0218559d180ed9f6d241b32decda1baec5265aa` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-15T15:49:59Z | 1794756422 | 1794148137 | `0xa035dbb685fb0b9693a991242334a3488ef2001f5b75b6a432cdde9886e92ccf` | 135900 | 2026-11-19T03:49:59Z | true | `0x39a5a4b394afe6ae37bf0692a22ebba836d4c97c8dcf012427bd8154ff62273b` |
| 17650 | `0x16835ff339746e0f1cd0d9382f19f0b774e41b82` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-15T16:50:23Z | 1794760132 | 1794151877 | `0xd3e07e627bc229c9ad148eed7216e5ba62073e76dd31a3bf3d31d498347a83be` | 139524 | 2026-11-19T04:50:23Z | true | `0xd2bc8e23bc4c846c004f70ddcc33c94ae362e20aad8a53e3469826a23b8531a7` |
| 17651 | `0x765aadaed5d27a616a8af70dfef9bce1ceab8140` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-15T17:50:35Z | 1794763857 | 1794155577 | `0x28756d072f0b8ee9b719c1827ac42b43cebba2f425f0870950230dadf497a8d3` | 143136 | 2026-11-19T05:50:35Z | true | `0xd537b668f811ecf23641f930ad8f0bd5ece9ce8518bab390d3e009fd6fe896dc` |
| 17652 | `0xcd89fc3bcf5898c666b1cd4764a0e2b49f3807fc` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-15T18:50:59Z | 1794767037 | 1794158752 | `0x5b2e54348cf474fead73f745e8e5021912369963f03df4c4d24d9b0a7df4c0be` | 146760 | 2026-11-19T06:50:59Z | true | `0x6572187959689338dd271cae25aa2ea095d617ad254791da7694bc1e9c0f3b26` |
| 17653 | `0x7137b361a7d9e31a39970acf1a37a6ba582e314f` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-15T19:51:23Z | 1794771257 | 1794162987 | `0x9c3386ac233a81685a023613958553eda77a4ba39192699c62198aa9af2533e7` | 150384 | 2026-11-19T07:51:23Z | true | `0xb5b75f086510a06d358d9000feb8d86643709d06f4cc45aa96f41e385d16b1cc` |
| 17654 | `0x9b56dfbcb0c9412806ab518bf8b5498428e04549` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-15T20:51:35Z | 1794774417 | 1794166172 | `0xf5343f9e739a84e6492b11443fcec1065e42e61c7cb8bb89b3b580f48c8592ac` | 153996 | 2026-11-19T08:51:35Z | true | `0xe572e5a505c7c47472379af1c2873102194d43c986cfb8dff3d0e1d6e0cdb168` |
| 17655 | `0xdaca7ca594c5df0dd20b524d35ea0905153075fc` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-15T21:51:59Z | 1794778122 | 1794169927 | `0x1de344fdb0059a4aafac8dfdd50c4c21804ff8cab4b7fb57f2abaaf599334181` | 157620 | 2026-11-19T09:51:59Z | true | `0x84b7922d0ed29d7a41f62a0587540984297787b178eb0b8d8b6bf4f5a66bb025` |
| 17656 | `0x4e13e32c03d55e55da654473905267e2d9cb468f` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-15T22:52:23Z | 1794781852 | 1794173067 | `0x353b0e3eab07daefdd5075c2859b328337a1659295f15aabc3259618f3d0a043` | 161244 | 2026-11-19T10:52:23Z | true | `0xd1f034b079acd9f3dec751cd6c4658451e4ff51ba8094528decee0bc9bf5e075` |
| 17657 | `0x7cb59bd8704713792d2daf7aaa00ba28c2813731` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-15T23:52:35Z | 1794785022 | 1794177427 | `0x03f5fc9e2fd9858261fbb0cdd583ce6411666c8f6c04b80696e29cd3386c9ecd` | 164856 | 2026-11-19T11:52:35Z | true | `0x65649aaa2b752cc3102229d08a1a34e865a306b0e43236c91c59849a21982867` |
| 17658 | `0xc56edae78f0cd9ed0876647f4cffcff09a238865` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-16T00:52:59Z | 1794789257 | 1794180707 | `0xa8475a6fb3e28689f15d76ffbb13f62fe24cb0bb30ac9c3a9cd2a2152e5b7ed1` | 168480 | 2026-11-19T12:52:59Z | true | `0xe7c5db31c77cc266d1e6946b834f2c7f6183dc581240ac5efcb45b35085ca6a9` |
| 17659 | `0x1851f73e89d4eb11bdb05c248ffc4c588ea062e6` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-16T01:53:23Z | 1794792452 | 1794184447 | `0x09d287079bd9b5cf255f93239e832903b50c64717c10ff3fa0cf33b8ede184e5` | 172104 | 2026-11-19T13:53:23Z | true | `0x2a756810de9ca69983e02da14a22028eb2cda48590483b330af421e1b5a08287` |
| 17660 | `0xfd0bd99d174758d9dbef1b807de2313448ad115a` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-16T02:53:35Z | 1794796157 | 1794187492 | `0xa025fc757f449d6cbb5f3e9cc48d11af7a31e89fadae8408ebd3dfd7b4174721` | 175716 | 2026-11-19T14:53:35Z | true | `0xf318a0f0f1684fdb2791b3d9affe24f486079bd2afc2ba6d4563c33487543c95` |
| 17661 | `0xafca034180d92220c607f5e1c18430cbecf4b2c4` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-16T03:53:59Z | 1794799867 | 1794191372 | `0x4628deadff6da2081e78eb2ff565e671d78753ae70a2b6980f59dacd00597bb4` | 179340 | 2026-11-19T15:53:59Z | true | `0x03c28240f8ff38d0cbf7e23c99fba85e63cbb7567131cf5c6aeed69b47a825d1` |
| 17662 | `0xda47f80ed2afe1741accce0d20ce5a6a6f7ecf76` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-16T04:54:23Z | 1794803562 | 1794195607 | `0xc9c177dca10fbf407d32e7c36af8b0b78b93f32133a80e5b3714b053c720c652` | 182964 | 2026-11-19T16:54:23Z | true | `0x57ce59ab0d5b698bf5a0be075406007bd71310485b24d14678dee50515667a3a` |
| 17663 | `0x894a2d2e05ff0c1044a9a3519c9a429222206933` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-16T05:54:35Z | 1794807257 | 1794198787 | `0x0333278a8170400b6dcd175c69f83d9a1299e984cf2435641043883d9f16c517` | 186576 | 2026-11-19T17:54:35Z | true | `0x0a509a5cef9059eaa7bbd116f26fd9eb6f4945b5a082c57bfd8e32364d8beddc` |
| 17664 | `0xe82b14072751f54a284f05623013852aa9003a2c` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-16T06:54:59Z | 1794810967 | 1794202497 | `0x3a952c8716a594527b4623b81568f347c7e0e18c32eaee28092057a5aa58b184` | 190200 | 2026-11-19T18:54:59Z | true | `0x4b4233b8734c2d962d5830af573185f39d9e7542f4c217501e7ec91a5860beef` |
| 17665 | `0xf5899318855023cb4cc0436d10210d8604d08b4e` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-16T07:55:23Z | 1794814662 | 1794205977 | `0x3a0a3baa203396d8f5f6229a76229578e6522747ec3587f4f1db0bc5c0822dda` | 193824 | 2026-11-19T19:55:23Z | true | `0x7bb473c72162c71113ef7c8043fa00ca51cf7fe72790f6ea8f6fae1e616ff6f6` |
| 17666 | `0x533bf9afa0fde0af311215c337f14df8e03c7a53` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-16T08:55:35Z | 1794817832 | 1794209697 | `0x647f715e87bc2959dd5bf61fc5918dab7f48e0224571bb3a103f969def62c6a4` | 197436 | 2026-11-19T20:55:35Z | true | `0x76078e6b5dc6fd66c1d965e61413f482ce2a984c472c489d3a37b9958d6ccc63` |
| 17667 | `0x65923fc0d8af611ebd4e78e5030df1e9dc816ed7` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-16T09:55:59Z | 1794821527 | 1794213272 | `0x60290ad173a3d26ed8b399d510787b29f56338a5606e8bc94f92540f276f79cd` | 201060 | 2026-11-19T21:55:59Z | true | `0x14649ec7004a83e161056fdb286aa0f8c69b34b82beedddb7965411c451b3216` |
| 17668 | `0xaa7e4cc4b8947e89b8c31d88dcc785d8463e8941` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-16T10:56:23Z | 1794825222 | 1794217125 | `0x38a40b497d62da00df2b4353ec7b303ac74cda6d6ae7dd0ba994d09ded75f532` | 204684 | 2026-11-19T22:56:23Z | true | `0x810a5581b3ee027d4400b13307a414073254a11b2d39d3cdbf78a3347e217857` |
| 17669 | `0x3c9febd49cde79d616524e26dd004d265b6f6c66` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-16T11:56:35Z | 1794828932 | 1794220437 | `0x7dd88fe5e812754ec26dc429632a8fc668058d0a2e2643e2bbeeed022c3b0ef1` | 208296 | 2026-11-19T23:56:35Z | true | `0xf38d1202e37fdb16b2c14f9d950f2b53466053e25939e465833649e4a1d49f0f` |
| 17670 | `0x941747c3a6c49da9333acbce30c60cefc9b47197` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-16T12:56:59Z | 1794832642 | 1794224082 | `0x5de30a8222504c52a24fa38ab65a96ce7f64ba0e5e55abfe4f227b3d27a0f4b4` | 211920 | 2026-11-20T00:56:59Z | true | `0x2ccd7210208c1857657083717d14ebe478345f79a85e5931839eb5fb1dec1049` |
| 17671 | `0xe061987df9e56e784124c675607fe454f611ee07` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-16T13:57:23Z | 1794836362 | 1794227792 | `0x796d33271d018e88f85677d3651f210bc3deb970a04cb9118731b0a557cdf667` | 215544 | 2026-11-20T01:57:23Z | true | `0x0781f29b0e9cfa51bf4b36273dc8d72a201d5bbd417b38e14b079b14f9946c35` |
| 17672 | `0x53ed381e56ed65e44a3165f7d919cb7b52a3562e` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-16T14:57:35Z | 1794839842 | 1794231497 | `0xec5308d68862e01b65ff1cc26c3775455fc6dbf0977fc06e37e7f07602f2b062` | 219156 | 2026-11-20T02:57:35Z | true | `0xfa6ca9ec824865b2d2f73c655b04b02b223bdc3f023eb0edb339732e7c010e6f` |
| 17673 | `0xb82205c61507d056565e6fca684e3de0a640e58c` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-16T15:57:59Z | 1794843032 | 1794235207 | `0x17d192af8379c8dd65a53c73a8675a19c4a41767d822341ccece81e2d10d714f` | 222780 | 2026-11-20T03:57:59Z | true | `0xe7117afe09c1f44efa2a9f5baa2b9bff0ff30110b0bf243124a4599e62ac1b0e` |
| 17674 | `0xeaff675c87e1432b6df2b4778601484efbc61d2a` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-16T16:58:23Z | 1794847292 | 1794238412 | `0xfc9ff940449da27de97785f9b297f81ed5e0e62aa10e4dc0de08f699b5bbc020` | 226404 | 2026-11-20T04:58:23Z | true | `0x25dff2c7532f5b7a7d5fb8e61c0f18afd6342480d202b6cf9f03c1f60769fd50` |
| 17675 | `0x0c92bd34bb3f8b6b2723d994b11d6d9a86d9f0b2` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-16T17:58:35Z | 1794850497 | 1794242167 | `0x7809b3712fe6a841625c34d3a0cf8af7ddefef7990e874b6cdc9a20d8a1b4065` | 230016 | 2026-11-20T05:58:35Z | true | `0xe5b0f334e6a66d9be18cf8fb1688363f120fd6f6eb8979a3397323cea16a6426` |
| 17676 | `0xa1d458cb44b4311c03d53973b4714ee0df289d4a` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-16T18:58:59Z | 1794854232 | 1794245852 | `0xdfe98f24a42ce47c5600a80971b38a7cc6d7694087b62b798aa3affc2a6130eb` | 233640 | 2026-11-20T06:58:59Z | true | `0x96d5f3c9708df567b881fdcdb9f642a0988920398212d8b747c41a26c45d5640` |
| 17677 | `0xecd171ac0ddd178cb4e369e685e9623ad7416ec7` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-16T19:59:11Z | 1794857962 | 1794249567 | `0x8aa9a47c0be0adb4966110df5f4da23f63623d479f4bdb9d194b316283e968bf` | 237252 | 2026-11-20T07:59:11Z | true | `0x2c284781874c2abae580ef9774491b4983eeddf74f96d858232006b24a94c431` |
| 17678 | `0x3ad66b378a52567bb6bde4bdd232c9637581ec09` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-16T20:59:35Z | 1794861127 | 1794253262 | `0x6694bdd5550c3b84aebbc1e8a71c1e74828a1c695210dd5442cebc8c83447ba1` | 240876 | 2026-11-20T08:59:35Z | true | `0xe9b9b2f21bad325333205b9a2fa6e400394dcfac6fb5fd4f7188202181917c90` |
| 17679 | `0x704f11ecf9dbeddfbf3b87c2e3b5e173cfc49c6c` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-16T21:59:59Z | 1794865362 | 1794256987 | `0x84e18b94f6cae20a374e4faba8efc031bbe4aac251807b2563937eb7b9c74186` | 244500 | 2026-11-20T09:59:59Z | true | `0x1116d7518103be0d1e3343710421b2d71ca01435140115b9853c259d7f48f71a` |
| 17680 | `0x3073a5f81798e353033ba07cf19b49d6390a68d8` | `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7` | 2026-11-16T23:00:11Z | 1794868732 | 1794260672 | `0xf190a2d0291ab7804782eec7bd6d10f8d9bc99f775ee1143c9b16a5a4c1112bd` | 248112 | 2026-11-20T11:00:11Z | true | `0xe9341e1cb3aa0da56b6027d1f0df496885a81fea18c901b2737997e90f389096` |

Total live old-prestate games: **147**.


---

## Source: `mirror/CATK-B/LIVE-OBJECTS-CATK-B.md`

# CATK-B live-object census

Cutoff: Ethereum block **26,433,900**. RPC: read-only proxy `:7545`. Both event scans covered 907 ranges of at most 10,000 blocks, with zero errors. All amounts below are relay ETH, not token amounts encoded in calldata.

## Exhaustive event population

| Chain | Portal | Birth | `WithdrawalFinalized` | `success=false` | L1CDM `FailedRelayedMessage` events / unique |
|---|---|---:|---:|---:|---:|
| OP | `0xbEb5…106Ed` | 17,365,802 | 26,000 | 4 | 23 / 19 |
| Ink | `0x5d66…D3e4F` | 21,344,310 | 919 | 0 | 7 / 3 |
| Soneium | `0x88e5…AE92` | 21,314,185 | 1,580 | 0 | 0 / 0 |
| Unichain | `0x0bd4…A7a2` | 21,116,371 | 3,508 | 0 | 0 / 0 |

There are 22 unique failed-message hashes: 7 later succeeded and 15 remain unsuccessful. All four L1CDM balances are exactly zero at the cutoff. Because every non-reverting relay exit writes one mapping and v9 reverts a failed L2CDM portal call, the exhaustive four-event `success=false` set is the only possible neither-mapping set. Each is actually a version-0 duplicate whose old hash was already successful.

## Nonzero-value failures (all later settled)

| Chain | Message hash | ETH | First failure | First success | Delay | Replay caller |
|---|---|---:|---:|---:|---:|---|
| OP | `0x4469d07d864c41bc36ce454810ca41b0aab298b8a997658cb49d9219da263276` | 236.749727508928692667 | 26,346,791 | 26,357,020 | 10,229 blocks | `0xb7b51e…07529` |
| Ink | `0x940ba5ec73a0003ac5147379a5c1d8665ffb674cd11b89d3b87b69bb0cd57941` | 17.294485522346960448 | 22,419,550 | 22,425,052 | 5,502 | `0x63c99b…db864` |
| Ink | `0xd9204ef4371eca7b4f54ecc662bbddb826f9eafb959739adda4f88cf4d07b8fe` | 58.326225035908748465 | 23,096,290 | 23,096,380 | 90 | `0x63c99b…db864` |
| Ink | `0xfac7aaf73dc66ed712f0d756d6b0432ded6189e3ba77591daaf2557354c84445` | 15.865961601206262980 | 23,175,112 | 23,175,119 | 7 | `0x63c99b…db864` |

Total: **328.236399668390660000 ETH**. Every row is `failed=true, successful=true`; every successful replay transaction supplied zero ETH and called the messenger directly.

## Portal `success=false` population

| Block | Withdrawal hash | ETH | Old message hash state | Barrier |
|---:|---|---:|---|---|
| 25,149,695 | `0x50d7b36248d6690bd50386f31cdbae2c0844fa4e01f86babac82b7206bbf6ddd` | 0.608658420630034106 | `0x15b9…402d` successful | legacy already relayed |
| 25,149,748 | `0x64db0ab9509c1dcd15a09cb23d8f24f88cd508a1b314d4d154c1336213d7a7ec` | 0.001 | `0x128a…5b7f` successful | legacy already relayed |
| 25,163,168 | `0xd3628e076f6b807297b42b7780a867b7762999081ebee4d0342529cf9aa65977` | 1.521959602251578445 | `0xcd29…860f` successful | legacy already relayed |
| 26,139,841 | `0xad0a2811460d8a7f4ef1c467171ee312fb9b85f9ca8965fa44a7e9542cc68ec4` | 0 | `0xaef8…574f` successful | legacy already relayed |

Their v1 hashes have neither mapping both immediately before the event and at the cutoff, but v0 is the protocol-correct identity for these nonce-version-0 messages.

## Fifteen currently unsuccessful messages

All are OP and carry zero relay ETH. Chronological and reverse full-gas replay produce the same three recoveries, proving order independence for this population.

| First failure | Message hash | Selector / target | Current replay |
|---:|---|---|---|
| 17,941,194 | `0x18b123eba23716f71c057e6aea971962e44dd5ff7060a448940f3b70cc544c25` | `0x0166a07a` / L1StandardBridge | succeeds |
| 18,080,973 | `0x1829f5fef01c789059b15c617fb80c38c9d5878d28711b0ac56029c924cd2b92` | `0x0166a07a` / L1StandardBridge | bare token revert |
| 18,837,534 | `0x6c9a36ef9b84c9b81e771d69cb3510a754dc27a0c8d7107d0ff886eeffd0623d` | `0x0166a07a` / L1StandardBridge | succeeds |
| 20,350,732 | `0x71c9882b0173bb6c4f718642f0e20c3171c2669c9e4ef0ef99d64ee958ee4162` | `0x0166a07a` / L1StandardBridge | succeeds |
| 22,046,337 | `0x33f61390a17c6fc32db1a11557ae861c762d6784a3f4a493138c38051faee088` | `0xef6ebe5e` / `0xb890…727f` | transfer root already confirmed |
| 22,774,953 | `0x2c820221fbef636211cbff87243f637325f124f5e6c27c91929cb4854000f60f` | `0x0166a07a` / L1StandardBridge | `TransfersBlocked()` |
| 22,775,135 | `0xdc594bf2048e71225a1d0bebeab1a81e0e77bef9227e6770a41916396af859d7` | `0x0166a07a` / L1StandardBridge | `TransfersBlocked()` |
| 22,863,733 | `0x09af464ae93df20c9d7d768402753578bd7aef7eebfc2f7b1e8a37eb77280ff1` | `0x0166a07a` / L1StandardBridge | `TransfersBlocked()` |
| 24,678,043 | `0xe43cf22b3252c92cce6b3884f541ac9986c6859fd0b4421f8ab0a13db78c8802` | `0x0166a07a` / L1StandardBridge | arithmetic underflow |
| 24,678,434 | `0xe208b5278fff03643885102e09614d11a39aa3ec0efc3418e9f31170b1dc566f` | `0xa9f9e675` / `0xaba2…f128` | invalid L1 token |
| 25,271,086 | `0x384bf7ec98f1b63104cf6867d15a537510d99750345268f05b15175f07e2dd1e` | `0xa9059cbb` / `0x9175…c9d0` | subtraction overflow |
| 25,475,826 | `0x43e0b78554c436637d3a3f6383edce9dd460777a14776a6b035c604c38bd0deb` | `0xa6492fe2` / `0x39ea…e48f` | must be proxy target |
| 26,100,288 | `0xb53bc394addf5cc3467d06f5a06b44cbcbd7f12d71cce812afe5f6f51b65f403` | same | must be proxy target |
| 26,102,366 | `0xae1005458951d769f4f18048ee0fab273be75169c397e0c0fbdc34b8b9081a7d` | same | must be proxy target |
| 26,385,051 | `0x9546105b80a67d2890768f2cf1c9bfdbc6d855ed8e8d7f47373d491b8bb11312` | same | must be proxy target |

Three additional zero-ETH hashes already succeeded after failure: `0xc510…0454`, `0xd965…e2a9`, and `0xda5b…d616`.

Machine evidence: `failure-census-enriched.json`, `value-message-replays.json`, `active-zero-value-replays.json`, and `active-zero-value-replay-traces.json`.


---

## Source: `mirror/CATK-D/LIVE-OBJECTS-CATK-D.md`

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


---

## Source: `mirror/CATK-E/LIVE-OBJECTS-CATK-E.md`

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


---

## Source: `mirror/CATK-F/LIVE-OBJECTS-CATK-F.md`

# CATK-F live withdrawal objects

## Verdict

No unfinalized OP withdrawal at the pin gives an unprivileged sender authority over shared protocol
state. The live population contains expected bridge messages plus four bridge-targeted messages whose
committed L2 sender is not the canonical bridge; those four fail the bridge identity check.

Pins: OP L2 blocks `105235063..159654093`; Ethereum L1 block `26433900`. Collection used only
read-only JSON-RPC. Full rows and transaction hashes are in
`evidence/withdrawal-object-census.json`.

## Population census

| Population | Count | Result |
|---|---:|---|
| All OP `MessagePassed` events | 35,579 | Complete genesis-to-pin range |
| Outer target = canonical L1 messenger | 35,544 | 35,543 have canonical L2 messenger sender |
| Direct/non-messenger withdrawals | 35, 22 unique targets | 0 match the 379-address curated current/historical system inventory |
| L1 `WithdrawalProven*` events | 31,839 | 30,093 distinct proven withdrawals |
| Distinct finalized withdrawals | 26,000 | Joined by withdrawal hash |
| Distinct proven but never finalized | 4,093 | 4,080 target the canonical messenger |
| Noncanonical L1 proof events | 35, 32 distinct | 0 curated system targets |
| Decoded canonical relay payloads | 35,544 | 0 decode failures |
| Inner targets matching system inventory | 23,145 | Mostly canonical bridges |
| Unfinalized inner system messages | 3,702 | 682 proven; 3,020 not yet proven |

### Unfinalized inner system messages

| L1 target | Committed L2 sender | Proven | Unproven | Security meaning |
|---|---|---:|---:|---|
| OP L1StandardBridge | L2StandardBridge `0x4200…0010` | 676 | 2,998 | Expected bridge path |
| OP L1ERC721Bridge | L2ERC721Bridge `0x4200…0014` | 2 | 22 | Expected bridge path |
| OP L1StandardBridge | `0x2d2f…44cd` | 3 | 0 | Cannot satisfy `otherBridge` |
| OP L1StandardBridge | `0xece2…3504` | 1 | 0 | Cannot satisfy `otherBridge` |

`StandardBridge.onlyOtherBridge` requires both `msg.sender == messenger` and the messenger's committed
`xDomainMessageSender == otherBridge` (`StandardBridge.sol:111-115`). The fork suite proves that an
attacker may choose the L1 bridge as target but cannot choose the inner sender independently.

## Portal/caller-trust objects

- The only v9 runtime consumers found for `portal.l2Sender()` are L1CrossDomainMessenger and
  ETHLockbox. Messenger ingress requires both the exact portal and L2 messenger
  (`L1CrossDomainMessenger.sol:136-138`). Lockbox unlock additionally requires the portal's
  `l2Sender` to be the default sentinel, which is false during a withdrawal
  (`ETHLockbox.sol:157-174`).
- One withdrawal targets the canonical messenger with a noncanonical outer sender
  (`0xc0d3…0007`); it is unproven and cannot enter the first-relay branch.
- All 16 current source-portal/destination-L2 aliases have zero balance, no code, and match no checked
  privileged identity (`evidence/portal-alias-census.json`).
- Across 13 historical/current DelayedWETH objects and four portals: 52 portal balances, every live
  allowance, and every portal-involved Approval/Transfer event are zero/absent
  (`evidence/delayed-weth-portal-census.json`).

## Code-later object

Exactly one of 66 unique effective targets had no code at initiation and code at the L1 pin:
`0x00C7…23bC`. Withdrawal `0x21dee2…902e` is unproven, zero-value, and commits that same account as
both sender and target with selector `0x06684706`. Its current 23-byte EIP-7702 designator rejects the
selector in the pinned fork; L1 messenger marks the message failed. It cannot affect shared state and
is the account's own self-message.



---

## Source: `mirror/CATK-C/evidence/LIVE-OBJECTS-CATK-C.md`

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

