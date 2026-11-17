# LIVE-OBJECTS-T3 — production objects matching T3 attack preconditions (read-only census)

Pins: L1 26,433,900 (via :7545 / :8545), OP 159,654,093 (via :7546 / :9545). Model: Opus 5.5.

## 1. L1 OptimismMintableERC20 tokens (precondition of "fake remote mints an L1 token")

`OptimismMintableERC20Created` on the four L1 factories, blocks 17,000,000..26,433,900 (`l1_factory_tokens.json`):
OP 4, Ink 0, Soneium 0, Unichain 0. Every one has L1 `totalSupply() == 0` at 26,433,900 -> nothing to inflate.

| L1 token | symbol | remoteToken (OP) | remote code on OP | L1 supply |
|---|---|---|---|---|
| 0x1287c312ba284ddbc6f7506f38382428174cab14 | IBEX | 0xf655c8567e0f213e6c634cd2a68d992152161dc6 | none | 0 |
| 0x8c21c7a7ec0190636ef181a50c2e30c55c263ed3 | SQUID | 0x6e58089d8e8f664823d26454f49a5a0f2ff697fe | none | 0 |
| 0x19638baef31dab2774f857d1a50194e41b1e71b2 | SQUID | 0x8c21c7a7ec0190636ef181a50c2e30c55c263ed3 (an L1 address) | none | 0 |
| 0xc9b2578df7f96323927ef5d71e100a847fc998db | TWETH2 | 0xe9e51a0bfa37fcb2c98dd998e5856aa0e1ea7568 ("WTEST", supply 0) | yes | 0 |

All 143 L1 tokens that received an L1StandardBridge withdrawal since Bedrock are NON-mintable under the bridge's
ERC165Checker semantics (TheDAO 0xbb9bc244… answers `supportsInterface` true for every id including 0xffffffff,
hence is treated as non-ERC165 by both deposit and finalize; consistent).

## 2. deposits[l1][l2] vs OP L2 totalSupply (`op_pair_census.json`, 143 pairs with >=1 withdrawal since Bedrock)

- 131 pairs: L2 mintable, remote == l1, L2 supply <= L1 escrow (difference = in-flight withdrawals / failed deposits).
  Largest: 0x15ee120f…/0x5029c236… escrow 2.319e27 vs supply 2.191e27; 0x8b21e9b7… 9.029e26 vs 9.020e26; etc.
- 0 pairs where a real L2 token's legacy `l1Token()` and new `remoteToken()` disagree (139 mintable L2 tokens).
- 7 pairs with L2 supply > L1 escrow or a now-codeless L2 token: ALL are one self-test series ("pWBTC" x6, "VIC")
  with custom 961-byte L2 tokens (`bridge()` = L2SB, no `symbol`, no-op burn, not factory-deployed), custom L1 tokens,
  3-4 withdrawals each, every withdrawal bounded by that pair's own deposit — the real-world twin of `test_B2`.
  Pairs: 0x713d39e1…/0xbf650846…, 0xff721c66…/0x7067e441…, 0x99aee709…/0xd8f3012b…, 0x7dabed52…/0xda155dd4…,
  0x3dbf9c3f…/0x6af5a2f1…, 0xb7b54c52…/0x7c1d54d1…, 0xfd4a7b71…/0x712f8468… (L2 codeless at the pin).
- Wrong-pair ("neither mintable" / wrong remote) escrows — KNOWN foot gun, user error, third-party tokens, passive
  context only (never tested on a fork):
  | L1 token | L2 token named by depositor | escrow at 26,433,900 | withdrawn since Bedrock |
  |---|---|---|---|
  | USDC 0xa0b86991… | Circle native USDC 0x0b2c639c… (non-mintable) | 205.752667 USDC | 308,472.3 USDC (3 withdrawals) |
  | DAI 0x6b175474… | OP DAI 0xda10009c… (non-mintable, custom bridge) | 61,210.94 DAI | 409,213.4 DAI (3) |
  | SNX 0xc011a73e… | OP SNX 0x8700daec… (non-mintable, custom bridge) | 102.545 SNX | 344.22 SNX (5) |
  | 0x9559aaa8… | OP rETH 0x9bcef72b… (mintable, l1Token = 0xae78736c…) | 8.893 | 0.444 (1: portal finalize tx 0xc9cc1f8f… @17,569,261; L2SB v1.13 cannot emit this pair, consistent with a migrated pre-Bedrock bounce-back, not decoded) |
  Mechanism: the L2 finalize of such a deposit reverts (L2 `deposits` underflow / wrong remote) and stays replayable;
  anyone who escrows the named L2 token in the L2StandardBridge 1:1 releases the L1 escrow and thereby funds the
  depositor's replay on L2. Out of authorization as an attack (impact runs through third-party tokens and the
  depositor's own error) and KNOWN (SCOPE.md 1.10 "neither ... OptimismMintable").

## 3. L1ERC721Bridge escrow (`l1_erc721_events.json.gz`, `erc721_outstanding.json`, `erc721_flags.json`, `erc721_owners.json.gz`)

- Events (blocks 15,000,000..26,433,900): OP 14,661 `ERC721BridgeInitiated`, 398 `ERC721BridgeFinalized`
  (first 15,678,685, last 19,799,374); Ink/Soneium/Unichain 0.
- Outstanding escrow keys (init without later fin): 14,263 over 2,297 (local, remote) pairs; largest
  0xe42cad6f…/0x899edc47… with 3,336 ids (sample id 24900 used in `test_C2`).
- `deposits[local][remote][id]` (slot 49) == true for 14,263 / 14,263 at 26,433,900 — including the pre-Bedrock
  (2022) deposits: the slot-49 layout is continuous since the first deployment.
- ownerOf(id) == bridge for 14,261. Two anomalies, both third-party NFT logic (out of authorization, not tested):
  0x1546d5c0…/0xfd551fff… id 283 (`ownerOf` reverts), 0xfeed43f8…/0xe6a2987d… id 1280 (owner 0xe9accaef…,
  no bridge finalization event). A future L2 burn for these would fail on L1 at the NFT's own transfer (replayable).

## 4. Pause source

L1StandardBridge.systemConfig() == L1ERC721Bridge.systemConfig() == OptimismPortal.systemConfig()
== 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290; both bridges `paused() == false` (`test_C3`).
