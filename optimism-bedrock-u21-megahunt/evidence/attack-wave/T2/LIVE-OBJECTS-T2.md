# LIVE-OBJECTS-T2 — legacy (version-0) and every-era withdrawal objects consumed by v9 (ATK-T2, Opus 5.5)

Sources (read-only, local proxies only): OP L2 `:7546` legacy L2CDM `SentMessage` (L2 0..105,235,062, 53 calls) and
`MessagePassed` (105,235,063..159,654,093, 28 calls); L1 `:7545` L1CDM `RelayedMessage`/`FailedRelayedMessage`
(11.5M..26,433,900; proxy born at 12,686,757), OP portal `WithdrawalProven`/`WithdrawalFinalized`, L1StandardBridge
`ERC20DepositInitiated`/`ERC20WithdrawalFinalized`; storage/`eth_call` at L1 26,433,900 and L2 159,654,093.
Pre-regenesis (OVM 1.0) messages: the migration input `packages/migration-data/data/ovm-messages.json` (17,924 rows,
all `who = L2CDM`, nonces 0..17,923). Scripts: `scripts/attack-wave-T2/`. Raw logs: `raw/*.json.gz` (gunzip before rerun).

## A. Version-0 (migrated legacy) messenger withdrawals — 57,809 objects

Migration recomputed exactly as op-chain-ops `MigrateWithdrawal` (value only for L2StandardBridge
`finalizeETHWithdrawal`, minGasLimit 0, gas = 16·len + 1,300,873). Validated: 1,409 + 204 + 4 portal finalizations and
208 proofs match the computed withdrawal hashes; 13,312 sampled unrelayed objects (all 13,012 value-bearing + 300
random) read `sentMessages == 1` on L2.

| era | class | n | value (ETH) |
|---|---|---:|---:|
| OVM 1.0 | relayed pre-Bedrock (v0 hash successful) | 7,512 | 17,892.92 |
| OVM 1.0 | never relayed, never proven | 10,196 | 464.22 |
| OVM 1.0 | finalized under Bedrock | 204 | 7.92 |
| OVM 1.0 | proven, not finalized | 12 | 1.24 |
| OVM 2.0 | relayed pre-Bedrock only | 12,775 | 264,875.75 |
| OVM 2.0 | relayed pre-Bedrock + portal-finalized (the 4 B-lane double attempts) | 4 | 2.13 |
| OVM 2.0 | relayed pre-Bedrock + proven only | 1 | 0 |
| OVM 2.0 | finalized under Bedrock | 1,409 | 7,036.97 |
| OVM 2.0 | proven, not finalized | 195 | 2.35 |
| OVM 2.0 | never relayed, never proven | 25,501 | 24.09 |

- Every one of the 20,292 legacy `RelayedMessage` hashes on L1 is one of these objects (12,780 OVM 2.0 + 7,512 OVM 1.0)
  and reads `L1CDM.successfulMessages(v0Hash) == true` at 26,433,900 (`legacy-storage-check.json`).
- Largest already-paid objects still provable today: OVM 2.0 nonce 110,269 (35,555.8 ETH, `0x517fccda…`), 109,248
  (20,004.3 ETH), OVM 1.0 nonce 16,753 (599.999 ETH, `0x7a2577cd…`). All revert under v9 (fork tests).
- Unclaimed legacy liability: 13,012 value-bearing never-relayed objects, 491.895 ETH total, all
  L2StandardBridge -> L1StandardBridge `finalizeETHWithdrawal` (largest OVM 1.0 nonce 668, 25.714 ETH, `0x6e15a53c…`).
- Max migrated gasLimit 1,310,665 (< 2^24): the legacy half of ATTACK-C-07 is now scanned.

## B. Bedrock-era MessagePassed — 35,579 objects, all nonce version 1 (inner L2CDM nonces: 35,543 all version 1)

Never finalized: 11,196 (6,253.006 ETH; 2,787 carry value); by era (unproven/proven): Regolith 4,366/3,089,
Canyon-Delta 402/67, Ecotone-Fjord 760/127, Granite 709/220, Holocene 405/76, Isthmus+ 678/297 (the large-value ones are
recent, normal pending withdrawals). 0 target the portal or lockbox; 0 inner targets are the L1CDM or portal; max
gasLimit 8,415,632; 0 `success=false` finalizations. One non-L2CDM sender to the L1CDM: `0xc0d3…0007` (`0x0a123e2e…`,
unproven, CATK-F).

## C. L1StandardBridge legacy pairs — 324 pairs, 294 L1 tokens

`deposits(l1,l2)` at 26,433,900 equals Σdeposits − Σwithdrawals for all 324 pairs; no pair ever withdrew more than it
deposited. 319 pairs hold escrow (155 from the legacy era). L1 tokens that answer ERC165 ILegacyMintableERC20 /
IOptimismMintableERC20 with full ERC165Checker semantics while holding escrow: ONE —
`0x9340857794710bbccf68167222a1DE4F0e269b10` ("Edu", 100,000 supply, `l1Token()` = itself, `l2Bridge()` = 0),
`deposits[EDU][EDU]` = 90,170e18 from 7 deposits at L1 14,932,146.. (pre-Bedrock); the OP L2 token at the same
address is an L2StandardERC20 (l1Token = 0x9340…, l2Bridge = L2StandardBridge) with totalSupply 90,170e18. TheDAO
`0xbb9bc244…` and `0xef2799d1…` return true for every selector incl. 0xffffffff, so ERC165Checker rejects them
(escrow path, as before).
