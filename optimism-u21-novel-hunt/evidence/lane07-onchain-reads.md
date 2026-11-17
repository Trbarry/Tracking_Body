# Lane 07 — on-chain reads (fork `l1` @ 26433900 unless noted; `l1pre` = 26430858, `l1n` = 26430859)

## Game types on the OP Mainnet factory 0xe5965Ab5… (v1.6.1, owner Safe 0x5a0Aae59…, gameCount 21389)
| type | impl | version | bond | gameArgs |
|---|---|---|---|---|
| 5 SUPER_PERMISSIONED | 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691 | 1.1.0 | 0 | ASR 0x23b2c629… ‖ proposer 0xc27ba3e0fc01567a5e57ae0c391aa98cecba5be0 (pre-U21: 0x473300df21d047806a082244b417f96b32f13a33) |
| 9 SUPER_CANNON_KONA | 0x19AF533Cc2A2A55786DCB8672aA5717e64213208 | 0.8.0 | 0.08 ETH | prestate 0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9 (pre-U21: 0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df) ‖ vm 0xaCc005DC… (MIPS64 1.10.1, oracle 0x1E1d7353… v1.1.5, challengePeriod 86400) ‖ ASR 0x23b2c629… ‖ DelayedWETH 0x1B6DBF05… (v2.0.0, delay 302400) ‖ l2ChainId 0 |
| 0,1,2,3,4,6,7,8,10,254,255,1337 | unset | | 0 | 0x |
Type-9 impl immutables: splitDepth 30, maxGameDepth 73, maxClockDuration 302400, clockExtension 10800.
Same impls / prestate on Ink (DGF 0x10d7B350…) and Unichain (DGF 0x2F12d621…), each with its own ASR + DelayedWETH in the
args; Soneium (DGF 0x512A3d2c…) has only type 5 (proposer 0x400c164c…), respected = 5. Type-5 proposers: Ink 0x3832bfbe…,
Unichain 0x86b392ca….

## Deployed bytecode vs local v9 build (forge-artifacts, immutables masked) — 0 differing bytes, metadata included
SuperFaultDisputeGame 0x19AF533C… (21802 bytes), SuperPermissionedDisputeGame 0x5C3eb47c… (4516), AnchorStateRegistry impl
0x2b27299c… (7311), DisputeGameFactory impl 0x72b97171… (8032), OptimismPortal2 impl 0xb20b23af… (23173).

## AnchorStateRegistry 0x23B2C629… storage, N-1 → N → 26433900
| slot | N-1 | N | 26433900 |
|---|---|---|---|
| 0 | 0x…229047fed2591dbec1ef1118d64f7af3db9eb290 0001 (legacy systemConfig spacer, _initialized=1) | same | same |
| 1 disputeGameFactory | 0xe5965ab5… | same | same |
| 2 anchorGame | 0x51024a83c2f94c8e70014a732d3e2559cdceeb1d | same | 0x55a5cfd4270340b3822bb9d8eebdb450ac206f95 |
| 3-4 startingAnchorRoot | (0xbd4aeba9…1d68, 0x6a9f9367 = 1788842855) | same | same |
| 5 blacklist mapping base | 0 | 0 | 0 |
| 6 | 0x…688271ab 00000009 | 0x322b47ff1fa8d5611f761e3e275c45b71b294d43 00000000688271ab 00000009 | same |
Slot 6 = respectedGameType 9 | retirementTimestamp 1753379243 | (new) ethLockbox. Version 3.9.0 → 4.0.0.

## Anchor game 0x55A5CFd4… (type 9, SFDG 0.8.0)
rootClaim 0xca640c8d…6fbc, l2SequenceNumber 1794298459, createdAt 1794299939, resolvedAt 1794602387, DEFENDER_WINS,
extraData 0x01 ‖ 000000006af2d25b ‖ chainId 0x…0a ‖ 0x58648b6e1df970401860595dde26ce93445414d711e181368e4c78c6c9bacfdf (73 bytes).
Block 26433900 timestamp 1794908075 ⇒ anchor lag 609,616 s (7.05 d).

## Factory history (OP Mainnet)
idx 0 type 0 (2024-05); idx 2000 type 1; idx 5000-17534 type 0; idx 18000-20094 type 8; idx 20095 (created 1790269415) onward
type 9. First non-retired idx 9828 (created 1753381655). Unichain: first non-retired idx 6186, type 8 from ~14.8k, type 9 from ~16.7k.
Last 99 games (idx 21290-21388): all type 9, creators only 0x473300df… (≤ idx 21378) and 0xc27ba3E0… (≥ idx 21379), no game
with more than the root claim, 85 IN_PROGRESS / 14 DEFENDER_WINS / 0 CHALLENGER_WINS, all respected-when-created,
prestate 0x031ac6f1… up to idx 21377 and 0x03e5a548… from idx 21378 (created 1794871775, ~5 min after the U21 tx).
Old games: idx 17500 (type 0, FDG 2.2.0, seq 152687615) and idx 19000 (type 8, FDG 2.4.2, seq 155386797): ASR 0x23B2…,
DEFENDER_WINS, isGameProper = isGameClaimValid = true.

## Per-chain wiring (Recon test output is appended to lane07-forge-results.txt)
All four chains: SystemConfig 4.3.0, portal 6.1.0, ASR 4.0.0, lastUsedOPCM 0x2d91e6F2… (9.0.3), same SuperchainConfig
0x95703e09…, four different ProxyAdmins with the same owner Safe 0x5a0Aae59…; SystemConfig.l2ChainId = 10 / 57073 / 1868 / 130.
