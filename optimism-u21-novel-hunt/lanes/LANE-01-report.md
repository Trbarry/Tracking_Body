# LANE 01 report - Upgrade Executor (U21 / op-contracts v9.0.0)

Scope: reconstruct what tx `0x024770b5...2a99` (block 26430859) did, attribute every storage change, and hunt for flaws in the execution and in the state it left. Blind-first: only v8/v9 source, the U21 notice and chain state were used.

Result in one line: **no vulnerability found in the upgrade execution or the state it left**; the execution is internally consistent on all four chains. Three low-value primitives and eleven recorded dead ends. No candidate.

Companion artifacts: `U21_PROXY_IMPLEMENTATION_MAP.md`, `U21_INITIALIZER_CALLS.md` (repo root of the hunt). PoC/evidence: `test/poc/lane01/`, `evidence/lane01-*`.

## 1. Method

1. Decoded the tx input (Safe `execTransaction` -> Multicall3DelegateCall `aggregate3` -> 5 OPCM calls) with the v9 ABIs.
2. Replayed the exact input on a forge fork of N-1 with state-diff recording (`Lane01_Replay.t.sol::test_replay_statediff`): 561 SSTOREs, 46 accounts, 339 distinct slots. Saved the `-vvvv` trace (3,971 lines).
3. Compared the replay end state with real block N (`l1n`) for all 339 slots: 0 mismatches. Compared N with 26433900: 0 differences. (The replay runs on end-of-N-1 state, not on the state after the 358 preceding txs of block N; the 0-mismatch result shows none of those txs touched a written slot.)
4. Read every zero-argument getter of the v8 and v9 ABIs on all 41 proxies at N-1, N and 26433900 (`evidence/lane01-getter-graph-pre-N-post.json`).
5. Verified 23 deployed contracts byte-for-byte against the local v9 build (immutables masked).
6. Ran the on-chain v9 `OPContractsManagerStandardValidator` against each chain.
7. Fork tests for the permissionless surface (`Lane01_Negatives.t.sol`, 5 tests, all pass).

Not done / limits: legacy contracts of Ink, Soneium and Unichain (old DelayedWETH/ASR proxies) were not enumerated; the kona prestate change was not analysed; the Safe nonce at 26433900 could not be read (upstream 429) - the absence of follow-up governance activity is inferred from unchanged state, not from the nonce.

## 2. What the tx did (state machine)

Per chain, `OPContractsManagerV2.upgrade` (`OPContractsManagerV2.sol:244-276`) -> `_loadChainContracts` (384-546, reads every sibling from SystemConfig / Portal) -> `_loadFullConfig` (552-682, reads every config value back from the chain, only `startingRespectedGameType` overridden) -> `_apply` (803-1028).

`_apply` order: validate config -> require SuperchainConfig version >= impl version (818) -> require permitted upgrade sequence (827; 8.0.1 -> 9.0.3 is "next major") -> re-init SystemConfig -> (ETH_LOCKBOX already on, no setFeature) -> re-init Portal -> re-init ETHLockbox -> (no migrateLiquidity) -> re-init L1xDM, L1StandardBridge, L1ERC721Bridge, OptimismMintableERC20Factory, DisputeGameFactory, DelayedWETH, AnchorStateRegistry -> set/unset 6 game types + clear SUPER_CANNON.

Each re-init is the 7-step StorageSetter dance of `OPContractsManagerUtils.upgrade` (312-387); see the table in `U21_PROXY_IMPLEMENTATION_MAP.md` section 1 for the log-to-instruction mapping (the "Upgraded twice" pattern).

Net effect of U21 on each chain (everything else was rewritten with identical values):

| What | Before | After |
|---|---|---|
| SuperchainConfig impl | 2.4.3 | 2.5.0 (adds `isLocalOrGlobalPaused`) |
| SystemConfig impl / `lastUsedOPCM` | 4.0.0 / OPCM 8.0.1 | 4.3.0 / OPCM 9.0.3 |
| OptimismPortal2 impl | 5.8.0 | 6.1.0 |
| ETHLockbox impl / new slot 3 | 1.3.1 / - | 2.0.0 / `superchainConfig` |
| L1CrossDomainMessenger impl | 2.11.1 | 2.13.0 |
| DelayedWETH impl / new slot 5 | 1.5.1 / - | 2.0.0 / `ethLockbox` |
| AnchorStateRegistry impl / slot 6 upper 20 bytes | 3.9.0 / 0 | 4.0.0 / `ethLockbox` |
| DGF `gameArgs(9)` prestate (OP, Ink, Unichain) | `0x031ac6f1...` | `0x03e5a548...` |
| DGF `gameArgs(5)` proposer (OP only) | `0x473300df...` | `0xc27ba3E0...` |
| L1StandardBridge, L1ERC721Bridge, OptimismMintableERC20Factory, DGF impls, all game impls, MIPS | unchanged addresses | unchanged |

## 3. Invariants checked (all hold at N and at 26433900)

I1. Every touched proxy ends on its v9 implementation; none on StorageSetter. (41/41)
I2. `_initialized == initVersion()` on every proxy; `_initialized == 0xff` on every implementation. (41/41, 11/11)
I3. Every initializer argument that is an address points at the same chain's sibling, the shared SuperchainConfig, the Safe, or the OPCM. (decoded args, `U21_INITIALIZER_CALLS.md` section 3)
I4. Post-state wiring graph has no cross-chain and no stale pointer (table below; 68 address getters x 4 chains, 0 anomalies), including the ASR and DelayedWETH embedded in `gameArgs(5)`/`gameArgs(9)`.
I5. ProxyAdmin of each proxy == the chain's ProxyAdmin; ProxyAdmin owner == Safe; AddressManager owner == the chain's ProxyAdmin; `ProxyAdmin.isUpgrading() == false`.
I6. `ETHLockbox.authorizedPortals` is true only for the own portal (4x4 matrix), `authorizedLockboxes` false for all 4x4.
I7. Features: ETH_LOCKBOX true, INTEROP false, CUSTOM_GAS_TOKEN false on all four, before and after.
I8. Portal ETH balance 0 before and after on all four; lockbox balances unchanged by the tx (OP +4.2 ETH inside block N comes from other txs).
I9. No pause active on any old or new identifier (address(0), 4 portals, 4 lockboxes: `expiration == 0`) before or after.
I10. On-chain StandardValidator v4.1.1 `validate((sysCfg, 0, 0x03e5a548..., chainId, proposer), true)` returns `""` for OP, Ink and Unichain at 26433900 (OP also checked at N). Soneium returns `"SCKDG-SHAPE,SCKDG-10"` solely because it does not register SUPER_CANNON_KONA (permissioned chain, respected type 5) - a standard-config deviation that existed before U21, not something the upgrade introduced.
I11. Deployed code == v9 build for all 23 contracts checked.

## 4. Post-upgrade wiring graph (block N; identical at 26433900 except `anchorGame`)

Labels are resolved against the same chain's contract set; a pointer to another chain's contract would have been flagged. None was.

| Getter | OP Mainnet (10) | Ink (57073) | Soneium (1868) | Unichain (130) |
|---|---|---|---|---|
| SystemConfig.delayedWETH | `0x1B6DBF05..` DelayedWETH | `0x57b4C29D..` DelayedWETH | `0x18fBb58C..` DelayedWETH | `0x74ad145a..` DelayedWETH |
| SystemConfig.disputeGameFactory | `0xe5965Ab5..` DisputeGameFactory | `0x10d7B350..` DisputeGameFactory | `0x512A3d2c..` DisputeGameFactory | `0x2F12d621..` DisputeGameFactory |
| SystemConfig.guardian | `0x09f7150D..` Guardian | `0x09f7150D..` Guardian | `0x09f7150D..` Guardian | `0x09f7150D..` Guardian |
| SystemConfig.l1CrossDomainMessenger | `0x25ace71c..` L1CrossDomainMessenger | `0x69d3Cf86..` L1CrossDomainMessenger | `0x9CF951E3..` L1CrossDomainMessenger | `0x9A3D64E3..` L1CrossDomainMessenger |
| SystemConfig.l1ERC721Bridge | `0x5a7749f8..` L1ERC721Bridge | `0x661235a2..` L1ERC721Bridge | `0x5933e323..` L1ERC721Bridge | `0xD04D0D87..` L1ERC721Bridge |
| SystemConfig.l1StandardBridge | `0x99C9fc46..` L1StandardBridge | `0x88FF1e5b..` L1StandardBridge | `0xeb9bf100..` L1StandardBridge | `0x81014F44..` L1StandardBridge |
| SystemConfig.lastUsedOPCM | `0x2d91e6F2..` OPCM v9.0.3 | `0x2d91e6F2..` OPCM v9.0.3 | `0x2d91e6F2..` OPCM v9.0.3 | `0x2d91e6F2..` OPCM v9.0.3 |
| SystemConfig.optimismMintableERC20Factory | `0x75505a97..` OptimismMintableERC20Factory | `0xA8B389A8..` OptimismMintableERC20Factory | `0xc1047e30..` OptimismMintableERC20Factory | `0xA2B597Ea..` OptimismMintableERC20Factory |
| SystemConfig.optimismPortal | `0xbEb5Fc57..` OptimismPortal2 | `0x5d66C178..` OptimismPortal2 | `0x88e529A6..` OptimismPortal2 | `0x0bd48f6B..` OptimismPortal2 |
| SystemConfig.owner | `0x847B5c17..` SystemConfig owner (Foundation Safe) | `0x847B5c17..` SystemConfig owner (Foundation Safe) | `0x509182eC..` SystemConfig owner (Soneium) | `0x847B5c17..` SystemConfig owner (Foundation Safe) |
| SystemConfig.proxyAdmin | `0x543bA4AA..` ProxyAdmin(OP) | `0xd56045E6..` ProxyAdmin(Ink) | `0x89889B56..` ProxyAdmin(Soneium) | `0x3B73Fa8d..` ProxyAdmin(Unichain) |
| SystemConfig.proxyAdminOwner | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe |
| SystemConfig.superchainConfig | `0x95703e09..` SuperchainConfig | `0x95703e09..` SuperchainConfig | `0x95703e09..` SuperchainConfig | `0x95703e09..` SuperchainConfig |
| SystemConfig.unsafeBlockSigner | `0xAAAA45d9..` unsafeBlockSigner | `0x7b322282..` unsafeBlockSigner | `0x7c2Bd59e..` unsafeBlockSigner | `0xFaACA0A1..` unsafeBlockSigner |
| OptimismPortal2.anchorStateRegistry | `0x23B2C629..` AnchorStateRegistry | `0xEe018bAf..` AnchorStateRegistry | `0x48909289..` AnchorStateRegistry | `0x27Cf508E..` AnchorStateRegistry |
| OptimismPortal2.disputeGameFactory | `0xe5965Ab5..` DisputeGameFactory | `0x10d7B350..` DisputeGameFactory | `0x512A3d2c..` DisputeGameFactory | `0x2F12d621..` DisputeGameFactory |
| OptimismPortal2.ethLockbox | `0x322b47Ff..` ETHLockbox | `0xbd4AbB32..` ETHLockbox | `0x67B4de6F..` ETHLockbox | `0x08bA0023..` ETHLockbox |
| OptimismPortal2.guardian | `0x09f7150D..` Guardian | `0x09f7150D..` Guardian | `0x09f7150D..` Guardian | `0x09f7150D..` Guardian |
| OptimismPortal2.l2Sender | `0x00000000..` DEFAULT_L2_SENDER | `0x00000000..` DEFAULT_L2_SENDER | `0x00000000..` DEFAULT_L2_SENDER | `0x00000000..` DEFAULT_L2_SENDER |
| OptimismPortal2.proxyAdmin | `0x543bA4AA..` ProxyAdmin(OP) | `0xd56045E6..` ProxyAdmin(Ink) | `0x89889B56..` ProxyAdmin(Soneium) | `0x3B73Fa8d..` ProxyAdmin(Unichain) |
| OptimismPortal2.proxyAdminOwner | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe |
| OptimismPortal2.superchainConfig | `0x95703e09..` SuperchainConfig | `0x95703e09..` SuperchainConfig | `0x95703e09..` SuperchainConfig | `0x95703e09..` SuperchainConfig |
| OptimismPortal2.systemConfig | `0x229047fe..` SystemConfig | `0x62C0a111..` SystemConfig | `0x7A8Ed66B..` SystemConfig | `0xc407398d..` SystemConfig |
| ETHLockbox.guardian | `0x09f7150D..` Guardian | `0x09f7150D..` Guardian | `0x09f7150D..` Guardian | `0x09f7150D..` Guardian |
| ETHLockbox.proxyAdmin | `0x543bA4AA..` ProxyAdmin(OP) | `0xd56045E6..` ProxyAdmin(Ink) | `0x89889B56..` ProxyAdmin(Soneium) | `0x3B73Fa8d..` ProxyAdmin(Unichain) |
| ETHLockbox.proxyAdminOwner | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe |
| ETHLockbox.superchainConfig | `0x95703e09..` SuperchainConfig | `0x95703e09..` SuperchainConfig | `0x95703e09..` SuperchainConfig | `0x95703e09..` SuperchainConfig |
| L1CrossDomainMessenger.OTHER_MESSENGER | `0x42000000..` L2CrossDomainMessenger predeploy | `0x42000000..` L2CrossDomainMessenger predeploy | `0x42000000..` L2CrossDomainMessenger predeploy | `0x42000000..` L2CrossDomainMessenger predeploy |
| L1CrossDomainMessenger.PORTAL | `0xbEb5Fc57..` OptimismPortal2 | `0x5d66C178..` OptimismPortal2 | `0x88e529A6..` OptimismPortal2 | `0x0bd48f6B..` OptimismPortal2 |
| L1CrossDomainMessenger.otherMessenger | `0x42000000..` L2CrossDomainMessenger predeploy | `0x42000000..` L2CrossDomainMessenger predeploy | `0x42000000..` L2CrossDomainMessenger predeploy | `0x42000000..` L2CrossDomainMessenger predeploy |
| L1CrossDomainMessenger.portal | `0xbEb5Fc57..` OptimismPortal2 | `0x5d66C178..` OptimismPortal2 | `0x88e529A6..` OptimismPortal2 | `0x0bd48f6B..` OptimismPortal2 |
| L1CrossDomainMessenger.proxyAdmin | `0x543bA4AA..` ProxyAdmin(OP) | `0xd56045E6..` ProxyAdmin(Ink) | `0x89889B56..` ProxyAdmin(Soneium) | `0x3B73Fa8d..` ProxyAdmin(Unichain) |
| L1CrossDomainMessenger.proxyAdminOwner | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe |
| L1CrossDomainMessenger.superchainConfig | `0x95703e09..` SuperchainConfig | `0x95703e09..` SuperchainConfig | `0x95703e09..` SuperchainConfig | `0x95703e09..` SuperchainConfig |
| L1CrossDomainMessenger.systemConfig | `0x229047fe..` SystemConfig | `0x62C0a111..` SystemConfig | `0x7A8Ed66B..` SystemConfig | `0xc407398d..` SystemConfig |
| L1StandardBridge.MESSENGER | `0x25ace71c..` L1CrossDomainMessenger | `0x69d3Cf86..` L1CrossDomainMessenger | `0x9CF951E3..` L1CrossDomainMessenger | `0x9A3D64E3..` L1CrossDomainMessenger |
| L1StandardBridge.OTHER_BRIDGE | `0x42000000..` L2StandardBridge predeploy | `0x42000000..` L2StandardBridge predeploy | `0x42000000..` L2StandardBridge predeploy | `0x42000000..` L2StandardBridge predeploy |
| L1StandardBridge.l2TokenBridge | `0x42000000..` L2StandardBridge predeploy | `0x42000000..` L2StandardBridge predeploy | `0x42000000..` L2StandardBridge predeploy | `0x42000000..` L2StandardBridge predeploy |
| L1StandardBridge.messenger | `0x25ace71c..` L1CrossDomainMessenger | `0x69d3Cf86..` L1CrossDomainMessenger | `0x9CF951E3..` L1CrossDomainMessenger | `0x9A3D64E3..` L1CrossDomainMessenger |
| L1StandardBridge.otherBridge | `0x42000000..` L2StandardBridge predeploy | `0x42000000..` L2StandardBridge predeploy | `0x42000000..` L2StandardBridge predeploy | `0x42000000..` L2StandardBridge predeploy |
| L1StandardBridge.proxyAdmin | `0x543bA4AA..` ProxyAdmin(OP) | `0xd56045E6..` ProxyAdmin(Ink) | `0x89889B56..` ProxyAdmin(Soneium) | `0x3B73Fa8d..` ProxyAdmin(Unichain) |
| L1StandardBridge.proxyAdminOwner | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe |
| L1StandardBridge.superchainConfig | `0x95703e09..` SuperchainConfig | `0x95703e09..` SuperchainConfig | `0x95703e09..` SuperchainConfig | `0x95703e09..` SuperchainConfig |
| L1StandardBridge.systemConfig | `0x229047fe..` SystemConfig | `0x62C0a111..` SystemConfig | `0x7A8Ed66B..` SystemConfig | `0xc407398d..` SystemConfig |
| L1ERC721Bridge.MESSENGER | `0x25ace71c..` L1CrossDomainMessenger | `0x69d3Cf86..` L1CrossDomainMessenger | `0x9CF951E3..` L1CrossDomainMessenger | `0x9A3D64E3..` L1CrossDomainMessenger |
| L1ERC721Bridge.OTHER_BRIDGE | `0x42000000..` L2ERC721Bridge predeploy | `0x42000000..` L2ERC721Bridge predeploy | `0x42000000..` L2ERC721Bridge predeploy | `0x42000000..` L2ERC721Bridge predeploy |
| L1ERC721Bridge.messenger | `0x25ace71c..` L1CrossDomainMessenger | `0x69d3Cf86..` L1CrossDomainMessenger | `0x9CF951E3..` L1CrossDomainMessenger | `0x9A3D64E3..` L1CrossDomainMessenger |
| L1ERC721Bridge.otherBridge | `0x42000000..` L2ERC721Bridge predeploy | `0x42000000..` L2ERC721Bridge predeploy | `0x42000000..` L2ERC721Bridge predeploy | `0x42000000..` L2ERC721Bridge predeploy |
| L1ERC721Bridge.proxyAdmin | `0x543bA4AA..` ProxyAdmin(OP) | `0xd56045E6..` ProxyAdmin(Ink) | `0x89889B56..` ProxyAdmin(Soneium) | `0x3B73Fa8d..` ProxyAdmin(Unichain) |
| L1ERC721Bridge.proxyAdminOwner | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe |
| L1ERC721Bridge.superchainConfig | `0x95703e09..` SuperchainConfig | `0x95703e09..` SuperchainConfig | `0x95703e09..` SuperchainConfig | `0x95703e09..` SuperchainConfig |
| L1ERC721Bridge.systemConfig | `0x229047fe..` SystemConfig | `0x62C0a111..` SystemConfig | `0x7A8Ed66B..` SystemConfig | `0xc407398d..` SystemConfig |
| OptimismMintableERC20Factory.BRIDGE | `0x99C9fc46..` L1StandardBridge | `0x88FF1e5b..` L1StandardBridge | `0xeb9bf100..` L1StandardBridge | `0x81014F44..` L1StandardBridge |
| OptimismMintableERC20Factory.bridge | `0x99C9fc46..` L1StandardBridge | `0x88FF1e5b..` L1StandardBridge | `0xeb9bf100..` L1StandardBridge | `0x81014F44..` L1StandardBridge |
| OptimismMintableERC20Factory.proxyAdmin | `0x543bA4AA..` ProxyAdmin(OP) | `0xd56045E6..` ProxyAdmin(Ink) | `0x89889B56..` ProxyAdmin(Soneium) | `0x3B73Fa8d..` ProxyAdmin(Unichain) |
| OptimismMintableERC20Factory.proxyAdminOwner | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe |
| DisputeGameFactory.owner | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe |
| DisputeGameFactory.proxyAdmin | `0x543bA4AA..` ProxyAdmin(OP) | `0xd56045E6..` ProxyAdmin(Ink) | `0x89889B56..` ProxyAdmin(Soneium) | `0x3B73Fa8d..` ProxyAdmin(Unichain) |
| DisputeGameFactory.proxyAdminOwner | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe |
| DelayedWETH.config | `0x95703e09..` SuperchainConfig | `0x95703e09..` SuperchainConfig | `0x95703e09..` SuperchainConfig | `0x95703e09..` SuperchainConfig |
| DelayedWETH.ethLockbox | `0x322b47Ff..` ETHLockbox | `0xbd4AbB32..` ETHLockbox | `0x67B4de6F..` ETHLockbox | `0x08bA0023..` ETHLockbox |
| DelayedWETH.proxyAdmin | `0x543bA4AA..` ProxyAdmin(OP) | `0xd56045E6..` ProxyAdmin(Ink) | `0x89889B56..` ProxyAdmin(Soneium) | `0x3B73Fa8d..` ProxyAdmin(Unichain) |
| DelayedWETH.proxyAdminOwner | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe |
| AnchorStateRegistry.anchorGame | `0x51024A83..` anchorGame | `0x7A5559F3..` anchorGame | `0xa64e0DAf..` anchorGame | `0x55AE7D93..` anchorGame |
| AnchorStateRegistry.disputeGameFactory | `0xe5965Ab5..` DisputeGameFactory | `0x10d7B350..` DisputeGameFactory | `0x512A3d2c..` DisputeGameFactory | `0x2F12d621..` DisputeGameFactory |
| AnchorStateRegistry.ethLockbox | `0x322b47Ff..` ETHLockbox | `0xbd4AbB32..` ETHLockbox | `0x67B4de6F..` ETHLockbox | `0x08bA0023..` ETHLockbox |
| AnchorStateRegistry.proxyAdmin | `0x543bA4AA..` ProxyAdmin(OP) | `0xd56045E6..` ProxyAdmin(Ink) | `0x89889B56..` ProxyAdmin(Soneium) | `0x3B73Fa8d..` ProxyAdmin(Unichain) |
| AnchorStateRegistry.proxyAdminOwner | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe | `0x5a0Aae59..` PAO Safe |
| AnchorStateRegistry.superchainConfig | `0x95703e09..` SuperchainConfig | `0x95703e09..` SuperchainConfig | `0x95703e09..` SuperchainConfig | `0x95703e09..` SuperchainConfig |

Additional edges: `gameArgs(5)` = (own ASR, proposer); `gameArgs(9)` = (prestate, MIPS64 `0xaCc005DC...`, own ASR, own DelayedWETH, chainId 0) on OP/Ink/Unichain. MIPS64.oracle = PreimageOracle `0x1E1d7353...` (shared). ETHLockbox/ASR/DelayedWETH no longer expose `systemConfig()` (ASR and lockbox revert; DelayedWETH's payable fallback returns empty success, see PRIM-0103).

## 5. Hunt log

| Idea | Outcome | Killing fact |
|---|---|---|
| Re-run an initializer (anyone / PAO / ProxyAdmin) | dead, REJ-0101 | `_initialized == initVersion()`; `reinitializer` reverts; test over 41 proxies x 3 callers |
| Direct CALL or attacker DELEGATECALL of OPCM entry points; direct CALL of unguarded `Utils.upgrade` | dead, REJ-0102 | `OPContractsManagerV2_OnlyDelegateCall` (`:1074-1078`); `Ownable: caller is not the owner` from ProxyAdmin |
| Proxy left on StorageSetter / partial bundle reachable | dead, REJ-0103 | atomic tx; impl slots final; replay == N |
| Stale or cross-chain pointer | dead, REJ-0104 | wiring table, 0 anomalies; validator `""` |
| Implementation left initializable | dead, REJ-0105 | slot 0 = 0xff on all 11 |
| Unexpected / missing storage change | dead, REJ-0106 | 339 slots attributed; only stale words are private spacers |
| Pause dropped by identifier consolidation | dead, REJ-0107 | no pause timestamp set on any identifier at N-1 |
| New lockbox needs SuperchainConfig >= 2.5.0 (`isLocalOrGlobalPaused`) - ordering hazard | dead, REJ-0108 | call 0 upgrades SuperchainConfig first; `_apply:818` enforces it for any other caller |
| Pre-U21 games break against ASR v4 / DelayedWETH v2 (removed getters) | dead, REJ-0109 | games never call `systemConfig()`; a pre-U21 game became OP anchor after U21 |
| `deploy()` permissionless: OPCM authority or CREATE2 collision against live chains | dead, REJ-0110 | deployer/salt differ; OPCM owns nothing persistent |
| Validator checks X while upgrade mutates Y | dead, REJ-0111 | validator derives every address from the same SystemConfig the OPCM used; only proposer and prestate are caller-supplied expectations |
| Legacy output-root games still claim-valid after U21 | primitive, PRIM-0101 | `isGameClaimValid` true for type-0 and type-8 games |
| Old-prestate type-9 games in flight across U21 | primitive, PRIM-0102 | idx 21370-21377 IN_PROGRESS with `0x031ac6f1...` |
| DelayedWETH fallback swallows unknown selectors | primitive, PRIM-0103 | `systemConfig()` returns empty success |

## 6. Observations that are not findings

- The `PermittedProxyDeployment = "ETHLockbox"` instruction was passed for all four chains although every chain already had a lockbox. It was a no-op, but had `portal.ethLockbox()` returned zero the OPCM would have silently deployed a fresh empty lockbox instead of reverting with `ProxyMustLoad`. Operator-side only.
- OP Mainnet's SUPER_PERMISSIONED proposer was rotated inside the upgrade tx to an EOA with nonce 1. Type 5 is not the respected type on OP (9 is), its bond is 0, and only that proposer can create type-5 games. Privileged configuration; no permissionless angle.
- Seven "v9" implementations are the v8 deployments (byte-identical). Lanes diffing v8 -> v9 source for L1StandardBridge, L1ERC721Bridge, DisputeGameFactory, FaultDisputeGame, SuperPermissionedDisputeGame, MIPS64, PreimageOracle should treat those diffs as formatting: the deployed code did not change.
- `SUPER_ROOT_GAMES_MIGRATION` is hard-wired true in `DevFeatures.isDevFeatureEnabled` (`DevFeatures.sol:57-62`) although the container's bitmap is 0; super-root mode is therefore the production default in both OPCM and validator.
- `clearedGameTypes()` (used by `migrate`) and the upgrade loop cover types 0, 1, 8, 4, 5, 9, 10 only. Types 2, 3, 6, 7 are unset on all four factories today, so nothing survives; a chain that had one registered would keep it through `migrate`.
- All four chains use the same type-9 prestate, the same game implementation and chain-id word 0; what binds a super game to a chain is only the ASR in its args and the chain set of the anchor super root. Out of this lane's scope; noted for the dispute-game lanes.

## 7. Open questions for other lanes

1. PRIM-0101: is there any type-0/8 game on any of the four chains that resolved DEFENDER_WINS with a questionable claim and was neither blacklisted nor retired? They are all still provable through the portal's non-super branch (`OptimismPortal2.sol` prove path, `rootClaim()` used directly).
2. PRIM-0102: what did kona-client v1.9.0 fix relative to the prestate `0x031ac6f1...`? Games on the old prestate keep resolving for at least 3.5 days after U21 and stay valid for proofs afterwards.
3. Planned `migrate` (OP + Unichain): chain[0]'s DelayedWETH `0x1B6DBF05...` becomes the WETH of the shared factory while it still holds bonds of in-flight per-chain games; the per-chain ASRs are re-pointed at the shared lockbox; `isGameRegistered` no longer checks the game's ASR. Worth one adversarial pass with games created just before the migration.
