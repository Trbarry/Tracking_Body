# SCOPE SNAPSHOT — Optimism Upgrade 21 novel-bug hunt

**Snapshot date: 2026-11-17** (all retrievals between 09:42 and 09:50 UTC). Lane: SCOPE.
Engagement facts: `/home/user/Tracking_Body/optimism-u21-novel-hunt/LANE_CONTEXT.md`.

Conventions used in this file:

- **LIVE** = read by this lane, today, from the primary source named in the row.
- **LIVE (summarised)** = fetched today, but through a tool that returns a model summary instead of the raw page.
- **UNVERIFIED-AGAINST-LIVE-PAGE** = not read from the live Immunefi programme page. Nothing in sections 1.1–1.12 carries this label: every programme fact there was read from the live page payload.
- Text inside fenced `text` blocks is **verbatim** from the source (programme markdown as served, unedited).
- "On-chain" = `cast` reads against the shared local fork `l1` (`http://127.0.0.1:8545`, Ethereum mainnet pinned at block `26433900`) or `l1pre` (block `26430858`). Read-only; nothing was sent anywhere.
- No audit report was opened. Audit references are titles and index metadata only.

## 0. Retrieval log

| # | Item | URL | Method | Result |
|---|---|---|---|---|
| 1 | Immunefi programme root | https://immunefi.com/bug-bounty/optimism/ | `curl -sSL` via proxy | HTTP 307 -> `/bug-bounty/optimism/information/`, then HTTP 200 (245,114 bytes). LIVE |
| 2 | Immunefi Information page | https://immunefi.com/bug-bounty/optimism/information/ | `curl -sSL` | HTTP 200 (245,113 bytes). LIVE |
| 3 | Immunefi Scope page | https://immunefi.com/bug-bounty/optimism/scope/ | `curl -sSL` | HTTP 200 (297,097 bytes). LIVE |
| 4 | Immunefi Resources page | https://immunefi.com/bug-bounty/optimism/resources/ | `curl -sSL` | HTTP 200 (198,965 bytes). LIVE |
| 5 | Legacy URL used by Optimism docs | https://immunefi.com/bounty/optimism/ | `curl -sSL` | HTTP 200 after redirect to item 2. LIVE |
| 6 | Governance forum search | https://gov.optimism.io/search.json?q=Upgrade%2021 (and `q=op-contracts%2Fv9.0.0`) | `curl -sSL` | HTTP 200. LIVE |
| 7 | U21 proposal topic | https://gov.optimism.io/t/upgrade-21-interop-readiness/10948 (`.json` and `/raw/10948`) | `curl -sSL` | HTTP 200. LIVE |
| 8 | Forum categories 47 / 58 / 88 | https://gov.optimism.io/c/58/show.json etc. | `curl -sSL` | HTTP 200. LIVE |
| 9 | Onchain vote list | https://vote.optimism.io/proposals | `curl`: **HTTP 403 Forbidden**. WebFetch: OK | LIVE (summarised) |
| 10 | U21 notice (repo) | `/home/user/ethereum-optimism/optimism/docs/public-docs/notices/upgrade-21.mdx` @ `e5423ae6` | local read | OK |
| 11 | U21 notice (site) | https://docs.optimism.io/notices/upgrade-21 | `curl -sSL` | HTTP 200; same content as item 10 for the lines checked. LIVE |
| 12 | Superchain registry standard versions | https://raw.githubusercontent.com/ethereum-optimism/superchain-registry/7e1be4543c870ec5ac3353ab0ecf4deab100602c/validation/standard/standard-versions-mainnet.toml | `curl -sSL` | HTTP 200 (56,716 bytes); byte-identical at `4c273edd…` (the commit the monorepo submodule pins). LIVE |
| 13 | superchain-ops task | https://github.com/ethereum-optimism/superchain-ops/tree/903cefaa0f07738a81f6473a9adc5c3d7161e5a8/src/tasks/eth/084-U21-op-ink-soneium-uni | sparse `git clone` (GitHub REST API returned **HTTP 403**, repo not enabled for the session) | OK. LIVE |
| 14 | Monorepo `SECURITY.md` | `/home/user/ethereum-optimism/optimism/SECURITY.md` -> https://github.com/ethereum-optimism/.github/blob/master/SECURITY.md | local read + `curl` raw (HTTP 200) | OK |
| 15 | Docs security policy | `/home/user/ethereum-optimism/optimism/docs/public-docs/op-stack/security/security-policy.mdx` | local read | OK |
| 16 | v9 semver lock | `/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/snapshots/semver-lock.json` @ `ba6fcadb` | local read | OK |
| 17 | Chain state | `l1` @ 26433900, `l1pre` @ 26430858 | `cast call` / `cast storage` | OK |

The Immunefi pages are a Next.js App Router shell: there is no `__NEXT_DATA__`; the programme data is in the
`self.__next_f.push([...])` flight payload. The `bounty` object was decoded from the Scope page payload and its text
references resolved. Saved copies (first 16 hex of SHA-256):

| File under `/home/user/Tracking_Body/optimism-u21-novel-hunt/evidence/scope/` | SHA-256 prefix |
|---|---|
| `immunefi-optimism-scope.html` | `63f93f9dd14e9262` |
| `immunefi-optimism-information.html` | `787745c80ead7f1d` |
| `immunefi-optimism-bounty-object.json` (decoded payload, all fields) | `10c3181090b5a862` |
| `gov-topic-10948-upgrade-21.raw.md` | `c38d49f57f41b3bf` |
| `gov-topic-10948-upgrade-21.json` | `703080e44c709535` |
| `superchain-registry-7e1be45-standard-versions-mainnet.toml` | `109f99ec9a692a50` |
| `superchain-ops-903cefa-eth-084-README.md` | `cfbd014397d204b5` |
| `superchain-ops-903cefa-eth-084-config.toml` | `85880a8c8db36dcd` |
| `ethereum-optimism-dotgithub-SECURITY.md` | `d3287ac791fd815a` |

---

## 1. Immunefi Optimism bug bounty programme (LIVE)

Source for everything in 1.1–1.12: https://immunefi.com/bug-bounty/optimism/scope/ and `/information/`, retrieved 2026-11-17.

### 1.1 Programme metadata

| Field | Value |
|---|---|
| Project / slug | Optimism / `optimism` |
| Maximum bounty | $2,000,042 |
| Live since | 2022-01-14T07:00:00.000Z |
| Last updated (programme) | `2026-10-13T10:50:37.987Z` (rendered as "13 October 2026") — **before** the U21 proposal (2026-11-04) and execution (2026-11-16) |
| Paused | `pausedAt` = None |
| Primacy (programme-level field) | `primacy_of_impact` |
| PoC | `proofOfConceptType` = `required`; page badge "PoC Required" |
| KYC | `kyc` = True; page badge "KYC required" |
| Submission fee | `isPayToSubmit` = True, `payToSubmitFeeUsdc` = 50 |
| Reward token | USDC on Ethereum, denominated in USD |
| Triage | Triaged by Immunefi; features: Subscription Plan: Essential, Pay to Mediate, Pay to Submit, Managed Triage: Expert Assessment |
| Programme types | Smart Contract, Websites and Applications, Blockchain/DLT |
| General tags | Triaged by Immunefi, Immunefi Standard, KYC Required, Paid Submissions, PoC Required, Primacy of Impact |
| Responsible publication | `category_3` |
| Network type | `mainnet` |
| Safe Harbor | `isSafeHarborActive` = False |
| Codebases listed | Optimism smart contracts: https://github.com/ethereum-optimism/optimism; Documentation and further resources: https://docs.optimism.io |
| Documentation listed | Previous Audits: https://docs.optimism.io/stack/security/audits-report |
| Raw fields recorded without interpretation | `attackTimeInterval` = 1, `reductionPercentage` = 1 |

### 1.2 Assets in scope (all 36 rows of the live table)

The "On-chain today" column is this lane's annotation (fork `l1`, block 26433900), not programme text.


**Smart Contract** (19 rows)

| Name (as listed) | Target | Added | On-chain today |
|---|---|---|---|
| SystemConfig | `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` (etherscan.io) | 2024-03-11 | Proxy -> impl `0xade27248542c0f3e89b49e4eb76155e267f14377`, 4.3.0 (U21). CURRENT. |
| L2OutputOracle | `0xdfe97868233d1aa22e815a266982f2cf17685a27` (etherscan.io) | 2024-03-11 | Proxy -> impl `0xf243bed163251380e78068d317ae10f26042b292`, 1.8.0. Legacy (pre-fault-proof); not touched by U21. |
| OptimismPortal | `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` (etherscan.io) | 2024-03-11 | EIP-1967 proxy -> impl `0xb20b23af6071405c37ddda0c0640e8ebb7899645`, `version()` 6.1.0 (U21). CURRENT. |
| L1CrossDomainMessenger | `0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1` (etherscan.io) | 2024-03-11 | ResolvedDelegateProxy; AddressManager `OVM_L1CrossDomainMessenger` -> impl `0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448`, 2.13.0 (U21). CURRENT. |
| L1ERC721Bridge | `0x5a7749f83b81B301cAb5f48EB8516B986DAef23D` (etherscan.io) | 2024-03-11 | Proxy -> impl `0x9f164f1d02a81e06d639e55f65a87f0070e3cb2e`, 2.9.1 (U21). CURRENT. |
| L1StandardBridge | `0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1` (etherscan.io) | 2024-03-11 | L1ChugSplashProxy -> impl `0xb37a11aadf167b2f0b8dd85372de4bc66cd4a891`, 2.8.2 (U21). CURRENT. |
| OptimismMintableERC20Factory | `0x75505a97BD334E7BD3C476893285569C4136Fa0F` (etherscan.io) | 2024-03-11 | Proxy -> impl `0xaabea75da509fa518fd8a91eae4be5813b829b12`, 1.11.0 (U21). CURRENT. |
| ProxyAdmin | `0x543bA4AADBAb8f9025686Bd03993043599c6fB04` (etherscan.io) | 2024-03-11 | Not a proxy. `owner()` = `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`. CURRENT. |
| AddressManager | `0xdE1FCfB0851916CA5101820A69b13a4E276bd81F` (etherscan.io) | 2024-03-11 | Not a proxy (Lib_AddressManager). CURRENT. |
| OptimismPortal Implementation | `0xe2F826324b2faf99E513D16D266c3F80aE87832B` (etherscan.io) | 2024-05-29 | Bare implementation, 3.10.0. STALE: the portal proxy now points at `0xb20b23af…` (6.1.0). |
| DisputeGameFactory | `0xe5965Ab5962eDc7477C8520243A95517CD252fA9` (etherscan.io) | 2024-05-29 | Proxy -> impl `0x72b971717e088b59f26d4236be222adb6acd393b`, 1.6.1 (U21). CURRENT. |
| MIPS | `0x0f8EdFbDdD3c0256A80AD8C0F2560B1807873C9c` (etherscan.io) | 2025-10-03 | Bare contract, 1.0.1. STALE: registry `op-contracts/v9.0.0` MIPS is `0xacc005dcd857b401e4732e6f7837135a22825cfa` (1.10.1). |
| PreimageOracle | `0xD326E10B8186e90F4E2adc5c13a2d0C137ee8b34` (etherscan.io) | 2025-10-03 | Bare contract, 1.0.0. STALE: registry `op-contracts/v9.0.0` PreimageOracle is `0x1e1d73536a081ef2f355d29794547a9770aeb1e0` (1.1.5). |
| DelayedWETH | `0xE497B094d6DbB3D5E4CaAc9a14696D7572588d14` (etherscan.io) | 2025-10-03 | Proxy -> impl `0x97988d5624f1ba266e1da305117bcf20713bee08`, 1.0.0. STALE: `SystemConfig.delayedWETH()` now returns `0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162` (2.0.0). |
| AnchorStateRegistry | `0x18DAc71c228D1C32c99489B7323d441E1175e443` (etherscan.io) | 2025-10-03 | Proxy -> impl `0x1b5cc028a4276597c607907f24e1ac05d3852cfc`, 2.0.0. STALE: `OptimismPortal.anchorStateRegistry()` now returns `0x23B2C62946350F4246f9f9D027e071f0264FD113` (4.0.0). |
| PermissionedDisputeGame | `0xE9daD167EF4DE8812C1abD013Ac9570C616599A0` (etherscan.io) | 2025-10-03 | Bare implementation, `version()` 1.2.0. STALE: not `gameImpls(t)` for any type on the OP Mainnet DGF at block 26433900 (only types 5 and 9 are set). |
| FaultDisputeGame | `0x4146DF64D83acB0DcB0c1a4884a16f090165e122` (etherscan.io) | 2025-10-03 | Bare implementation, 1.2.0. STALE: not registered in the OP Mainnet DGF at block 26433900. |
| Primacy of Impact | Primacy of Impact placeholder (`isPrimacyOfImpact` = true; url `https://immunefi.com`) | 2026-03-11 | — |
| PolicyEngineStaking | `0xb5CB7a05DD1311195982A26DFC8222477f9D8179` (optimistic.etherscan.io) | 2026-05-21 | On OP Mainnet (L2), not read in this lane. |

**Blockchain/DLT** (4 rows)

| Name (as listed) | Target | Added |
|---|---|---|
| op-node | https://github.com/ethereum-optimism/optimism/tree/develop/op-node | 2024-05-29 |
| op-dispute-mon (in scope for impacts listed in the smart contracts section) | https://github.com/ethereum-optimism/optimism/tree/develop/op-dispute-mon | 2024-05-29 |
| Primacy of Impact | Primacy of Impact placeholder (`isPrimacyOfImpact` = true; url `https://immunefi.com`) | 2026-03-11 |
| op-reth | https://github.com/ethereum-optimism/optimism/tree/develop/rust/op-reth | 2026-06-12 |

**Web & App** (13 rows)

| Name (as listed) | Target | Added |
|---|---|---|
| Main Optimism website | https://www.optimism.io/ | 2025-10-03 |
| Optimism's Gateway | http://gateway.optimism.io/ | 2025-10-03 |
| Optimism's App | https://app.optimism.io/ | 2025-10-03 |
| Optimism's Docs | https://docs.optimism.io/ | 2025-10-03 |
| Optimism's Specs | https://specs.optimism.io/ | 2025-10-03 |
| Optimism's Console | https://console.optimism.io/ | 2025-10-03 |
| Optimism's Community page | https://community.optimism.io/ | 2025-10-03 |
| Optimism's Careers page | http://jobs.optimism.io/ | 2025-10-03 |
| Main OP Labs website | https://www.oplabs.co/ | 2025-10-03 |
| Main OP Labs blog | https://blog.oplabs.co/ | 2025-10-03 |
| OP Enterprise Dashboard | https://enterprise.optimism.io/ | 2026-08-13 |
| OP Enterprise Dashboard API | https://ope-dashboard-api.optimism.io/ | 2026-08-13 |
| Optimism's Console API | https://dapp-console-api.optimism.io | 2026-08-13 |

Not in the live asset table (checked by address and by name): **ETHLockbox** (any chain), **SuperchainConfig**,
**OPContractsManager / OPCM**, the current OP Mainnet **AnchorStateRegistry** `0x23B2C629…`, the current OP Mainnet
**DelayedWETH** `0x1B6DBF05…`, the current game implementations, the current MIPS64 / PreimageOracle, and every
Ink / Soneium / Unichain / Base address. All listed `etherscan.io` addresses are L1 contracts of OP Mainnet (chain 10); the one `optimistic.etherscan.io` row is an L2 contract.

### 1.3 Asset rule (verbatim, "Assets Body")

```text
**Whenever the asset is a smart contract proxy, its implementation is also in scope.**

However, only those in the Assets in Scope table are considered as in-scope of the bug bounty program.
```

### 1.4 Impacts in scope


**Smart Contract**

| Severity | Impact (verbatim) |
|---|---|
| Critical | Protocol insolvency, not including proposer/challenger bonds or fee vaults |
| Critical | Loss of user funds by direct theft, not including proposer/challenger bonds or fee vaults |
| Critical | Permanent freezing of funds, not including proposer/challenger bonds or fee vaults |
| High | Temporary freezing of funds, not including proposer/challenger bonds or fee vaults (e.g. recoverable via an upgrade) |
| High | Incorrectly proven withdrawal other than by incorrectly resolved dispute game, mitigated by a delay |
| High | Incorrectly resolved dispute game, not detected by op-dispute-mon, allows proving invalid withdrawal |
| Medium | Incorrectly resolved dispute game, detected by op-dispute-mon, excluding bugs in off-chain components |
| Medium | Incorrectly initiated dispute game bond withdrawal other than by incorrectly resolved dispute game, mitigated by a delay |
| Medium | Incorrectly resolved dispute game, not detected by op-dispute-mon, does not allow proving invalid withdrawal |
| Medium | Direct theft or permanent loss of fee vault funds (excluding missed revenue, unrealized yield, or failure to collect fees from pending transactions) |

**Blockchain/DLT**

| Severity | Impact (verbatim) |
|---|---|
| Critical | Direct loss of funds, not including proposer/challenger bonds or fee vaults |
| High | Malicious sequencer/batcher stealing user funds |
| High | Network not being able to confirm any new transactions, including deposits (Total network shutdown) |
| High | Freezing of funds (fix requires L2 hardfork) |
| Medium | Network not being able to confirm new transactions on L2, while forced-inclusion via L1 is still possible |
| Medium | Direct theft or permanent loss of fee vault funds (excluding missed revenue, unrealized yield, or failure to collect fees from pending transactions) |

**Web & App**

| Severity | Impact (verbatim) |
|---|---|
| Critical | Execute arbitrary system commands |
| Critical | Retrieve sensitive data/files from a running server, such as: - /etc/shadow - database passwords - blockchain keys (this does not include non-sensitive environment variables, open source code, or usernames) |
| Critical | Subdomain takeover with already-connected wallet interaction |
| Critical | Direct theft of user funds |
| Critical | Malicious interactions with an already-connected wallet, such as: - Modifying transaction arguments or parameters - Substituting contract addresses - Submitting malicious transactions |
| Critical | Injection of malicious HTML or XSS through metadata |
| Critical | Unauthorized access to, modification of, or destruction of production user or tenant data, where a single exploitation affects multiple users or tenants, as distinct from an attack that must be repeated for each additional victim |
| Critical | Taking or modifying authenticated actions on behalf of other users, where the action results in direct theft of funds or execution of an unauthorized onchain transaction |
| Critical | Retrieve sensitive data/files from a running server, such as server configuration, credentials, or source code (excluding production user or tenant data) |
| High | Injecting/modifying the static content on the target application without JavaScript (persistent), such as: - HTML injection without JavaScript - Replacing existing text with arbitrary text - Arbitrary file uploads, etc. |
| High | Subdomain takeover without already-connected wallet interaction |
| High | Taking down the application/website |
| Medium | Unauthorized access to, modification of, or destruction of production user or tenant data, where a single exploitation affects one user or tenant |
| Medium | Taking or modifying authenticated actions on behalf of other users, where the action does not result in any impact listed at critical severity |

Line breaks inside an impact are shown as spaces in these tables; the wording is otherwise unchanged. There is no Low tier for any category. Every impact row carries `isEligibleForRewardByImpact` = false and
`discretionaryRewardAmount` = null in the payload; the meaning of the first flag is not documented on the page and is
recorded here without interpretation.

### 1.5 Rewards

| Category | Severity | Model | Min | Max | Primacy label on page |
|---|---|---|---|---|---|
| Blockchain/DLT | Critical | up_to (10% of funds directly affected) | — | $2,000,042 | Primacy of Impact |
| Blockchain/DLT | High | range | $15,000 | $50,000 | Primacy of Impact |
| Blockchain/DLT | Medium | range | $1,000 | $15,000 | Primacy of Impact |
| Smart Contract | Critical | up_to (10% of funds directly affected) | — | $2,000,042 | Primacy of Impact |
| Smart Contract | High | range | $15,000 | $50,000 | Primacy of Impact |
| Smart Contract | Medium | range | $1,000 | $15,000 | Primacy of Impact |
| Web & App | Critical | range | $5,000 | $50,000 | Primacy of Rules |
| Web & App | High | range | $500 | $5,000 | Primacy of Rules |
| Web & App | Medium | range | $50 | $500 | Primacy of Rules |

Rendered text on the Information page: Smart Contract critical — "Mainnet assets: Reward amount is 10% of the funds
directly affected up to a maximum of: $2,000,042". Blockchain/DLT critical — "Reward amount is 10% of the funds
directly affected, capped at the maximum critical reward of: $2,000,042. The reward is dependent on the ratio between
the funds at risk, which includes all affected projects on top of the respective blockchain/DLT, and the market cap
according to the average between CoinMarketCap.com and CoinGecko.com, calculated at the time the bug report is submitted."
No minimum is stated for Critical in either category.

### 1.6 Rewards body, PoC requirement, KYC, and the Governance Proposals clause (verbatim)

```text
__Rewards by Threat Level__:

A PoC, demonstrating the bug's impact, is required for this program and has to comply with the [Immunefi PoC Guidelines and Rules](https://immunefisupport.zendesk.com/hc/en-us/articles/9946217628561-Proof-of-Concept-PoC-Guidelines-and-Rules).

For KYC, OptimismPBC will request a W-9 if you reside in the US or a W-8 if you reside outside the US.

Critical vulnerabilities are further capped at 10% of economic damage, with the main consideration being the funds affected in addition to PR and brand considerations, at the discretion of the team.

For web application reports, the sensitivity of the data involved determines the position within the reward range. Disclosure of personal information or confidential customer organization data is awarded towards the top of the range.

For testing any exploits involving cross-domain transactions, we recommend working with our [dockerized services](https://github.com/ethereum-optimism/optimism/blob/6f8e432506a5f4ba094f091b22a0bb6acc53fdac/ops/README.md) and modifying our [integration tests](https://github.com/ethereum-optimism/optimism/blob/6f8e432506a5f4ba094f091b22a0bb6acc53fdac/integration-tests/test/bridged-tokens.spec.ts)

__Governance Proposals:__

In addition to the above assets listed, the calldata and code for the latest Protocol Upgrade Proposals (not for Governor Upgrade proposals, or proposal previews) is also in scope. This must be an official governance proposal, meaning it has either (1) moved to onchain vote appearing on vote.optimism.io, or (2) has been posted by someone from OP Labs or the Optimism Foundation, or (3) a comment has been left by someone from OP Labs or the Optimism Foundation indicating it's eligible for the bounty. The latest in-flight governance proposal can be found at https://gov.optimism.io/c/88-category/technical-proposals/47.
```

### 1.7 Programme overview and Primacy of Impact vs Primacy of Rules (verbatim)

```text
Optimism is a project dedicated to scaling Ethereum's technology and expanding its ability to coordinate people from across the world to build effective decentralized economies and governance systems. 

The OP Stack is the modular, decentralized software stack that powers Optimism, forms the backbone of blockchains like OP Mainnet and Base, and is maintained by the Optimism Collective . 

The first release of the OP Stack codebase is called Bedrock. The Bedrock release primarily consists of the core software required to run L2 blockchains and was originally designed to power an upgrade to the OP Mainnet network. Bedrock improves on its predecessor by reducing transaction fees using optimized batch compression and Ethereum as a data availability layer; shortening delays of including L1 transactions in rollups by handling L1 re-orgs more gracefully; enabling modular proof systems through code re-use; and improving node performance by removing technical debt.

To read more about Optimism, please visit [https://www.optimism.io/](https://www.optimism.io/). To learn about the OP Stack, please visit [https://stack.optimism.io/](https://stack.optimism.io/). 

This bounty program is focused on preventing

- Theft of assets held in their smart contracts;
- Theft, freezing or other loss of funds due to vulnerabilities in the smart contracts’ or the critical blockchain client services (op-node and op-geth).

__Primacy of Impact vs Primacy of Rules__

Optimism adheres to the Primacy of Impact for the following impacts:

- Smart Contract  —  Critical
- Smart Contract  —  High
- Smart Contract  —  Medium
- Blockchain/DLT  —  Critical
- Blockchain/DLT  —  High
- Blockchain/DLT  —  Medium 

Primacy of Impact means that the impact is prioritized rather than a specific asset. This encourages security researchers to report on all bugs with an in-scope impact, even if the affected assets are not in scope. 

For more information, please see [Best Practices: Primacy of Impact](https://immunefisupport.zendesk.com/hc/en-us/articles/12340245635089-Best-Practices-Primacy-of-Impact)

When submitting a report on Immunefi’s dashboard, the security researcher should select the Primacy of Impact asset placeholder. If the team behind this project has multiple programs, those other programs are not covered under Primacy of Impact for this program. Instead, check if those other projects have a bug bounty program on Immunefi.

If the project has any testnet and/or mock files, those will not be covered under Primacy of Impact.

All other impacts are considered under the Primacy of Rules, which means that they are bound by the terms and conditions set within this program.
```

### 1.8 Programme-specific out-of-scope and rules, including the Chains clause (verbatim)

```text
__Chains__:
* When assessing impact for a bug, it will be primarily assessed against the impact it has on the following live chains: OP, Ink, Soneium, and Unichain. Each chain is identified by their entries in the superchain-registry (https://github.com/ethereum-optimism/superchain-registry/).
* A feature actively in use on at least one of these chains, or planned to be in use according to a governance proposal, is eligible for the highest tier impacts. A feature not actively in use on these chains will have its impact downgraded by one level.

The following are considered out-of-scope for the bug bounty:

__Blockchain / DLT__:
- Vulnerabilities requiring the user to have publicly exposed an API, such as JSON-RPC or the Beacon API
- Vulnerabilities requiring the chain operator to violate recommended best practices as described on our docs website, for example around network topology, proxy configuration and so on. See here https://docs.optimism.io/chain-operators/reference/architecture#network-design-example
- The Alt-DA feature of op-node and op-batcher.
- All execution layer clients which have reached end-of-service (e.g. op-geth).
- op-reth depends on several crates sourced from https://github.com/paradigmxyz/reth/. Issues which are responsibly disclosed to the upstream reth team or the Ethereum Foundation Bug Bounty Program (https://bbp-form.ethereum.org/) cannot be "replayed" against Optimism’s bug bounty program if the vulnerability has already been made public. If the vulnerability is disclosed to Optimism at the same time as upstream, the vulnerability is eligible for the bug bounty program.
 - All currently known issues with devp2p here: [https://github.com/ethereum/devp2p/blob/master/rlpx.md#known-issues-in-the-current-version](https://github.com/ethereum/devp2p/blob/master/rlpx.md#known-issues-in-the-current-version)
- There are scenarios where, if an attacker can predict an L1 reorg, they could exploit it to reorder dispute game transactions in a way that causes the honest challenger to respond incorrectly and therefore lose its bond — although the dispute game itself will still resolve correctly.
- *Clarification regarding malicious sequencer/batcher bugs*: the Default Blockchain/DLT out-of-scope item "Impacts caused by attacks requiring access to leaked keys/credentials" in particular puts malicious sequencer/batcher bugs out of scope. However, we put a sub-class of these bugs back into scope with "Malicious sequencer/batcher stealing user funds".
   - This **doesn't** generally move any derivation discrepancies that only a malicious sequencer/batcher can trigger in scope, like bugs where op-node, kona-node or kona-client disagree on the validity or interpretation of batcher transactions, frames, channels or batches. Only if the direct impact is stealing of user funds is such a bug in scope.

__Smart Contracts__:
- Vulnerabilities in the implementation of ‘custom token bridges’ which are written by third parties for bridging tokens to their network
- Bugs in op-challenger or other off-chain components that result in "Incorrectly resolved dispute game, detected by op-dispute-mon".
- Proof of whale based attacks on Fault Proofs.
- There appears to be an obvious bug which would allow an attacker to withdraw a fake ERC20 token from L2 in exchange for a real ERC20 (such as WBTC) token on L1. There is no check in the L2StandardBridge, however the withdrawal is prevented from finalizing by a check in the L1StandardBridge. Naturally if you do find a way to circumvent our protections, then we would reward you.
- A bug in ResolvedDelegateProxy.sol which could result in a storage slot key collision overwriting the address of the implementation. This bug is dependent on the layout of the implementation contract, and Optimism is not affected.
- There is an edge case in which ETH deposited to the OptimismPortal by a contract can be irrecoverably stranded:
  - When a deposit transaction fails to execute, the sender’s account balance is still credited with the mint value. However, if the deposit’s L1 sender is a contract, the tx.origin on L2 will be aliased, and this aliased address will receive the minted on L2. In general the contract on L1 will not be able to recover these funds. We have documented this risk and encourage users to take advantage of our CrossDomainMessenger contracts which provide additional safety measures.
- Sending cross-chain messages with very large amounts of data, or very specific amounts of gas can open up griefing attacks causing the sender’s funds to be stuck and requiring an upgrade to release them.
- Deposit transactions can be griefed at a cost to the attacker, by filling up the MAX_RESOURCE_LIMIT. This issue is mitigated by PR 5064, which does not completely resolve the issue but does increase the cost of a sustained griefing attack. A more complete fix will require architectural changes.
- There are various ‘foot guns’ in the bridge which may arise from misconfiguration of a token. To minimize complexity our bridge design does not try to prevent all forms of developer and user error. Examples of such foot guns include:
  - Having both (or neither of) the local and remote tokens be OptimismMintable.
  - Tokens which dynamically alter the amount of a token held by an account, such as fee-on-transfer and rebasing tokens.

__Web & App__:
- explorer.optimism.io
- testnet-explorer.optimism.io
- retrofunding.optimism.io
- public-grafana.optimism.io
- discord.optimism.io
- kyc.optimism.io
- kyb.optimism.io
- raas.optimism.io
- contribute.optimism.io
- superfest.optimism.io
- welovetheart.optimism.io
- support.enterprise.optimism.io
- login.enterprise.optimism.io, the Auth0-hosted login page for enterprise.optimism.io. The page itself is operated by Auth0 and is out of scope. Optimism's own Auth0 tenant configuration remains in scope, including allowed callback URLs, allowed web origins, connection settings, actions and rules, and any custom login page template, as does any vulnerability that results in unauthorized access to enterprise.optimism.io.
- Abuse of testnet faucet allocations on console.optimism.io, including bypassing or spoofing drip eligibility criteria. Testnet funds have no market value, so this is not treated as theft of user funds. Genuine authentication flaws in the faucet's identity flow remain in scope at the applicable severity.


- Additionally, any other asset belonging to Optimism but not under Optimism’s control will also be out of scope.

__The following domains, operated by Agora__:
- vote.optimism.io
- atlas.optimism.io

*Security researchers who discover vulnerabilities on these domains are encouraged to report them directly to Agora at security@voteagora.com. However, if a vulnerability on these domains leads to a direct financial impact on the OP Stack or the Optimism protocol itself, the impact remains in scope under the Primacy of Impact and should be submitted through this bug bounty program.*
```

### 1.9 Default out-of-scope lists (verbatim)

General:

```text
- Impacts requiring attacks that the reporter has already exploited themselves, leading to damage
- Impacts caused by attacks requiring access to leaked keys/credentials
- Impacts caused by attacks requiring access to privileged addresses (including, but not limited to: governance and strategist contracts) without additional modifications to the privileges attributed
- Impacts relying on attacks involving the depegging of an external stablecoin where the attacker does not directly cause the depegging due to a bug in code
- Mentions of secrets, access tokens, API keys, private keys, etc. in Github will be considered out of scope without proof that they are in-use in production
- Best practice recommendations
- Feature requests
- Impacts on test files and configuration files unless stated otherwise in the bug bounty program
- Impacts requiring phishing or other social engineering attacks against project's employees and/or customers
```

Smart Contract (the Blockchain/DLT default list is character-identical):

```text
- Incorrect data supplied by third party oracles
  - Not to exclude oracle manipulation/flash loan attacks
- Impacts requiring basic economic and governance attacks (e.g. 51% attack)
- Lack of liquidity impacts
- Impacts from Sybil attacks
- Impacts involving centralization risks
```

Web & App:

```text
- Theoretical impacts without any proof or demonstration
- Impacts involving attacks requiring physical access to the victim device
- Impacts involving attacks requiring access to the local network of the victim
- Reflected plain text injection (e.g. url parameters, path, etc.)
  - This does not exclude reflected HTML injection with or without JavaScript
  - This does not exclude persistent plain text injection
- Any impacts involving self-XSS
- Captcha bypass using OCR without impact demonstration
- CSRF with no state modifying security impact (e.g. logout CSRF)
- Impacts related to missing HTTP Security Headers (such as X-FRAME-OPTIONS) or cookie security flags (such as “httponly”) without demonstration of impact
- Server-side non-confidential information disclosure, such as IPs, server names, and most stack traces
- Impacts causing only the enumeration or confirmation of the existence of users or tenants
- Impacts caused by vulnerabilities requiring un-prompted, in-app user actions that are not part of the normal app workflows
- Lack of SSL/TLS best practices
- Impacts that only require DDoS
- UX and UI impacts that do not materially disrupt use of the platform
- Impacts primarily caused by browser/plugin defects
- Leakage of non sensitive API keys (e.g. Etherscan, Infura, Alchemy, etc.)
- Any vulnerability exploit requiring browser bugs for exploitation (e.g. CSP bypass)
- SPF/DMARC misconfigured records)
- Missing HTTP Headers without demonstrated impact
- Automated scanner reports without demonstrated impact
- UI/UX best practice recommendations
- Non-future-proof NFT rendering
```

### 1.10 Known Issues table (verbatim, all 10 rows)

| Category | Description (verbatim) | Link | Last updated |
|---|---|---|---|
| Blockchain/DLT | Missing zlib error/header validation in kona's channel decompressor leads to cross-client fault-proof divergence | https://bugs.immunefi.com/magnus/855/projects/355/reports/84201 | 2026-09-09 |
| Blockchain/DLT | There are scenarios where, if an attacker can predict an L1 reorg, they could exploit it to reorder dispute game transactions in a way that causes the honest challenger to respond incorrectly and therefore lose its bond — although the dispute game itself will still resolve correctly. | programme out-of-scope section (text-fragment link to the Scope page) | 2026-06-22 |
| Blockchain/DLT | Bugs in op-challenger that result in an "Incorrectly resolved dispute game, detected by op-dispute-mon" — these are considered known due to the existing ability to detect and resolve them via op-dispute-mon. | programme out-of-scope section (text-fragment link to the Scope page) | 2026-06-22 |
| Blockchain/DLT | All currently known issues with devp2p, as documented in the upstream list are considered known and ineligible for a reward. | https://github.com/ethereum/devp2p/blob/master/rlpx.md#known-issues-in-the-current-version | 2026-06-22 |
| Smart Contract | Various bridge "foot guns" arising from token misconfiguration, which the bridge intentionally does not try to prevent — for example: having both (or neither) of the local and remote tokens be OptimismMintable; or tokens that dynamically alter balances, such as fee-on-transfer and rebasing tokens. | programme out-of-scope section (text-fragment link to the Scope page) | 2026-06-22 |
| Smart Contract | Deposit transactions can be griefed at a cost to the attacker by filling up the MAX_RESOURCE_LIMIT. Mitigated (but not fully resolved) by PR 5064, which increases the cost of a sustained griefing attack; a complete fix requires architectural changes. | programme out-of-scope section (text-fragment link to the Scope page) | 2026-06-22 |
| Smart Contract | Sending cross-chain messages with very large amounts of data, or very specific amounts of gas, can open griefing attacks that cause the sender's funds to be stuck and require an upgrade to release them. | programme out-of-scope section (text-fragment link to the Scope page) | 2026-06-22 |
| Smart Contract | Edge case where ETH deposited to the OptimismPortal by a contract can be irrecoverably stranded — a failed deposit transaction still credits the sender's account with the mint value, but if the L1 sender is a contract, the L2 tx.origin is aliased and the minted ETH is sent to the aliased address, which generally cannot recover it. Documented; users are encouraged to use the CrossDomainMessenger contracts. | programme out-of-scope section (text-fragment link to the Scope page) | 2026-06-22 |
| Blockchain/DLT | A bug in ResolvedDelegateProxy.sol that could cause a storage-slot key collision overwriting the implementation address. The bug depends on the implementation contract's storage layout; Optimism is not affected. | programme out-of-scope section (text-fragment link to the Scope page) | 2026-06-22 |
| Smart Contract | Fake ERC-20 withdrawal via L2StandardBridge — there is no check in L2StandardBridge preventing an attacker from withdrawing a fake ERC-20 token from L2 in exchange for a real ERC-20 (e.g. WBTC) on L1; the withdrawal is currently blocked from finalizing by a check in L1StandardBridge. (Circumventing the L1 protection would be eligible for a reward.) | programme out-of-scope section (text-fragment link to the Scope page) | 2026-06-22 |

### 1.11 Prohibited activities (verbatim)

```text
- Any testing on mainnet or public testnet deployed code; all testing should be done on local-forks of either public testnet or mainnet
- Any testing with pricing oracles or third-party smart contracts
- Attempting phishing or other social engineering attacks against our employees and/or customers
- Any testing with third-party systems and applications (e.g. browser extensions) as well as websites (e.g. SSO providers, advertising networks)
- Any denial of service attacks that are executed against project assets
- Automated testing of services that generates significant amounts of traffic
- Public disclosure of an unpatched vulnerability in an embargoed bounty
- [Any other actions prohibited by the Immunefi Rules](https://immunefi.com/rules/)
```

`customProhibitedActivities` is an empty list: the programme adds nothing to the Immunefi default list.

### 1.12 Feasibility limitations (verbatim)

```text
The project may be receiving reports that are valid (the bug and attack vector are real) and cite assets and impacts that are in scope, but there may be obstacles or barriers to executing the attack in the real world. In other words, there is a question about how feasible the attack really is. Conversely, there may also be mitigation measures that projects can take to prevent the impact of the bug, which are not feasible or would require unconventional action and hence, should not be used as reasons for downgrading a bug's severity.
Therefore, Immunefi has developed a set of feasibility limitation standards which by default states what security researchers, as well as projects, can or cannot cite when reviewing a bug report.
- [Chain Rollbacks](https://immunefisupport.zendesk.com/hc/en-us/articles/16913153448721-Chain-Rollbacks)
- [Pre-Impact Bug Monitoring](https://immunefisupport.zendesk.com/hc/en-us/articles/19430444320401-Pre-Impact-Bug-Monitoring)
- [Attack Investment Amount](https://immunefisupport.zendesk.com/hc/en-us/articles/17243068885265-Attack-Investment-Amount)
- [Attacks With A Financial Risk To The Attacker](https://immunefisupport.zendesk.com/hc/en-us/articles/17454897136401-Attacks-With-A-Financial-Risk-To-The-Attacker)
- [When Is An Impactful Attack Downgraded To Griefing?](https://immunefisupport.zendesk.com/hc/en-us/articles/17455102268305-When-Is-An-Impactful-Attack-Downgraded-To-Griefing)
```

### 1.13 What the programme says about upgraded implementations and contracts behind listed proxies

Three pieces of live text govern this, and they pull in different directions:

1. **Proxy rule** (1.3): "Whenever the asset is a smart contract proxy, its implementation is also in scope." A new
   implementation behind a *listed* proxy is therefore in scope without the table being edited.
2. **Table-only rule** (1.3, next sentence): "However, only those in the Assets in Scope table are considered as
   in-scope of the bug bounty program." A proxy that is not in the table is not a listed asset, even if a listed
   contract calls it.
3. **Governance Proposals clause** (1.6): "In addition to the above assets listed, the calldata and code for the
   latest Protocol Upgrade Proposals (not for Governor Upgrade proposals, or proposal previews) is also in scope",
   subject to the three "official proposal" tests. This is the only wording that reaches upgrade code outside the table.
4. **Primacy of Impact** (1.7) applies to Smart Contract and Blockchain/DLT Critical/High/Medium and covers
   "all bugs with an in-scope impact, even if the affected assets are not in scope", excluding testnet and mock files.
   The dashboard asset to select is the "Primacy of Impact" placeholder.

There is **no** wording on the live page that says "contracts behind listed proxies" or "dependencies of listed
contracts" are in scope, and no wording about what happens to the Governance Proposals clause once a proposal has
executed. The clause's own pointer ("The latest in-flight governance proposal can be found at …/technical-proposals/47")
uses the word "in-flight". Section 5 treats both points as scope risk.

### 1.14 Other official sources (not the programme page)

These do not define scope; they are recorded because they describe how the programme is applied.

| Source | Text relevant to scope | Status |
|---|---|---|
| `/home/user/ethereum-optimism/optimism/SECURITY.md` @ `e5423ae6` | One line: "Please see our security policy document [here](https://github.com/ethereum-optimism/.github/blob/master/SECURITY.md)." | local read |
| https://github.com/ethereum-optimism/.github/blob/master/SECURITY.md | "Testing the vulnerability on the mainnet or testnet" disqualifies from a reward. "We have a bounty program with a maximum payout of $2,000,042." Website / non-critical infrastructure findings: "maximum payout of $50,000". | LIVE (raw file, HTTP 200) |
| `docs/public-docs/op-stack/security/security-policy.mdx` @ `e5423ae6` | "**Do not** test the vulnerability on a publicly available network, either the testnet or the mainnet." Under "Unscoped bugs": "…even if that component is not covered by an existing bug bounty, please report it via the Immunefi program. The impact of any and all reported issues will be considered and the program has previously rewarded security researchers for bugs not within its stated scope." | local read |

The "Unscoped bugs" sentence is a statement of practice in Optimism's docs, **UNVERIFIED-AGAINST-LIVE-PAGE** as a
programme term: the Immunefi page does not repeat it, and it promises consideration, not a reward.

---

## 2. Upgrade 21 Protocol Upgrade Proposal

### 2.1 The proposal (LIVE)

| Field | Value |
|---|---|
| Title | "Upgrade 21 - Interop Readiness" |
| URL | https://gov.optimism.io/t/upgrade-21-interop-readiness/10948 |
| Forum category | id 58 "Protocol Upgrade", child of id 88 "Proposals". Not in id 47 "Technical Proposals" (also a child of 88), which is the category the Immunefi clause links to. |
| Created | 2026-11-04T21:19:51Z; last edit 2026-11-04T22:56:50Z (post version 3) |
| Replies | none (`posts_count` = 1), so no OP Labs / Foundation eligibility comment exists |
| Author | forum user `AndreaFederici`; post opens "I'm Andrea Federici, Senior Solutions Engineer at OP Labs. I prepared this proposal in collaboration with Matthew Cruz from the OP Labs team." Forum account: trust level 4, no staff flag, no group flair — the OP Labs affiliation is self-declared in the post body. |
| Proposal type | "Protocol Upgrade" (first line of the post) |
| Charter | scoped to the Standard Rollup Charter |
| Code tag | `op-contracts/v9.0.0`, "the same commit as `op-contracts/v9.0.0-rc.1` (`ba6fcad`), so the contracts deployed from rc.1 are the final release" |
| OPCM | `0x2d91e6f2bcf6cd1df90e1faf9714e18705ea331f` on Ethereum mainnet, version 9.0.3, "deployed on October 30, 2026" (Sepolia: `0x160f0fe4dc1b3f4026687e8dd4b7f800879939cc`) |
| Stated version changes | `OPContractsManagerV2` 8.0.1 -> 9.0.3, `OptimismPortal2` 5.8.0 -> 6.1.0, `ETHLockbox` 1.3.1 -> 2.0.0, `AnchorStateRegistry` 3.9.0 -> 4.0.0, `DelayedWETH` 1.5.1 -> 2.0.0, `OPContractsManagerStandardValidator` 3.3.0 -> 4.1.1, `SystemConfig` 4.0.0 -> 4.3.0, `SuperchainConfig` 2.4.3 -> 2.5.0, `L1CrossDomainMessenger` 2.11.1 -> 2.13.0 |
| Implementation addresses in the post | none inline; the post links the superchain-registry `standard-versions-mainnet.toml` at commit `7e1be4543c870ec5ac3353ab0ecf4deab100602c` (table in 2.4) |
| Absolute prestate | `kona-client/v1.9.0` `cannon64-kona-interop` `0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9`, re-registered for `SUPER_CANNON_KONA` on each permissionless chain |
| Calldata | one `Multicall3DelegateCall.aggregate3` (selector `0x82ad56cb`) from the L1 ProxyAdminOwner: `OPCM.upgradeSuperchain` on the shared `SuperchainConfig`, then `OPCM.upgrade` for OP Mainnet, Ink, Soneium and Unichain. Full hex is in the post (17,352 hex chars after `0x`). |
| superchain-ops task | "superchain-ops task `eth/084`" -> `src/tasks/eth/084-U21-op-ink-soneium-uni` |
| Chains (mainnet) | OP Mainnet, Ink, Soneium, Unichain. Sepolia: OP Sepolia, Ink Sepolia, Soneium Minato, Unichain Sepolia. |
| Timeline in the post | published Wed 2026-11-04; Sepolia execution Mon 2026-11-09; veto period ends Wed 2026-11-11; mainnet execution Mon 2026-11-16 |
| Stated effect on these chains | "The chains in this proposal already use an `ETHLockbox`, so no ETH moves and their pause identifier is unchanged." "Existing proofs and in-flight withdrawals remain valid." |

Pull requests named in the post (ethereum-optimism/optimism): #22805, #22760 (ETHLockbox / pause identifier), #22669
(`deleteProvenWithdrawal`), #22939, #22959, #22919, #22471, #23134 (OPCM / StandardValidator). Specs: specs#951, specs#936.
These were not opened by this lane.

**Onchain vote — LIVE (summarised).** https://vote.optimism.io/proposals lists "Upgrade 21 - Interop Readiness" as an
Optimistic Proposal by The Optimism Foundation, status succeeded, ended "4:55 pm, Nov 11, 2026", 0.43% against with 20%
needed to defeat, proposal id `18704058920168992233750266034048958164367667396985967653465644941701644737084`.
Direct `curl` of that page returned HTTP 403; the facts above come from a WebFetch summary, so the id and percentages
should be re-read in a browser before being quoted in a report.

**Audit references (titles only; no report was opened).**

- In the post: "Spearbit/Cantina audited the full contracts diff since `op-contracts/v8.0.0`, from October 14 to
  October 28, 2026; the fix review is in progress and the report will be published in the optimism monorepo security
  reviews before mainnet execution."
- Monorepo index `docs/security-reviews/README.md` @ `e5423ae6`, last row: 2026-11 | Cantina | "Upgrade 21" |
  `2026_11-U21-Cantina.pdf` | commit `8fdb2775612f23a7d51bde6c1f4961faf7e0dd7b` | `op-contracts/v9.0.0`.
  The index commit (`8fdb2775…`) is not the release commit (`ba6fcadb…`); which one is the audited commit and which the
  fix commit is a question for the later novelty phase.
- Also linked in the post: an OP Labs threat-modelling blog post (URL slug `using-threat-modelling-as-a-strategic-development-tool`; not fetched).

### 2.2 Does U21 meet the Immunefi "official governance proposal" tests?

| Test in the clause | U21 | Evidence |
|---|---|---|
| "the latest Protocol Upgrade Proposals (not … Governor Upgrade proposals, or proposal previews)" | Yes: it is the newest topic in the Protocol Upgrade category; every newer upgrade topic on the forum is a "Maintenance Upgrade Proposal" (e.g. topic 10978, 2026-11-09) | category 58 listing, forum search |
| (1) "moved to onchain vote appearing on vote.optimism.io" | Yes | vote list, LIVE (summarised) |
| (2) "posted by someone from OP Labs or the Optimism Foundation" | Yes by the post's own statement; not confirmed by a forum staff badge | post body, user JSON |
| (3) eligibility comment from OP Labs / Foundation | No comment exists | `posts_count` = 1 |

Only one test needs to hold ("either (1) … or (2) … or (3)").

### 2.3 Cross-check: proposal vs notice vs registry vs superchain-ops vs chain

| Fact | Proposal (2.1) | Notice `upgrade-21.mdx` | Registry / superchain-ops | Chain (LANE_CONTEXT + this lane's reads) | Match |
|---|---|---|---|---|---|
| Release | `op-contracts/v9.0.0`, commit `ba6fcad` | `op-contracts/v9.0.0` (no commit) | registry comment: "OPCM deployed 2026-10-30 from tag op-contracts/v9.0.0-rc.1 (ba6fcadbc57eb99918c5b0f14f57c72527f531e3)"; v9.0.0 = "Final release of v9.0.0-rc.1 (same commit, contracts not redeployed)" | local worktree `op-v9.0.0` HEAD = `ba6fcadbc57eb99918c5b0f14f57c72527f531e3` | yes |
| OPCM | `0x2d91e6f2…331f`, 9.0.3 | names `OPContractsManagerV2` only | registry `op_contracts_manager` 9.0.3 `0x2d91e6f2…`; ops `config.toml` `OPCM = 0x2d91e6f2…` | `version()` = 9.0.3 at that address | yes |
| Executing account | "the L1 ProxyAdminOwner" | — | ops README: L1PAO `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`, nested 2-of-2 | tx `to` = `0x5a0aae59…`; `owner()` of all four chains' ProxyAdmins = `0x5a0Aae59…` | yes |
| Calldata | hex in post | — | ops task builds the same call | the post's calldata (without `0x`) is a **verbatim substring of the executed tx input** (checked against `evidence/u21-upgrade-tx.json`) | yes |
| Execution | "Mainnet execution: Monday, Nov 16, 2026" | target Mon 2026-11-16 | ops README "Status: EXECUTED" -> tx `0x024770b5fba87683ee1466562eefb1bcb408c29c764e24abd07c7d4050a82a99` | same tx, block 26430859, 2026-11-16 23:23:59 UTC | yes |
| Chains | OP Mainnet, Ink, Soneium, Unichain | "OP, Ink, Unichain, and Soneium" (registry permissionless chains) | ops: chain ids 10, 57073, 1868, 130 with the four SystemConfig proxies | the four SystemConfig proxies report 4.3.0 and `l2ChainId` 57073 / 1868 / 130 for the siblings | yes |
| Respected game types | — | — | ops: OP, Ink, Unichain type 9; Soneium type 5 | OP `respectedGameType` = 9; Soneium DGF `gameImpls(9)` = 0 | yes |
| Prestate | `0x03e5a548…37c9` | same | ops `cannonKonaPrestate` same | not re-read by this lane | consistent |
| ETH movement | none on these chains | lockbox chains "keep ETH where it is" | ops: "no ETH moves" | portal balance 0 before and after; lockbox 182,541.07 ETH at 26433900 | yes |
| Interop | "ahead of interop" | "Upgrade 21 does not call the migration, and it does not activate interop." | — | `INTEROP` = false (LANE_CONTEXT) | yes |

Discrepancies found:

- **Publication date.** The notice's timing table says "Governance proposal published — Monday, November 2, 2026".
  The forum topic was created 2026-11-04 and its own action plan says "Wednesday, Nov 4, 2026".
- **Notice is still marked provisional** ("contract and component versions will be added when the release candidates
  are published"; "The Governance proposal and onchain vote will be linked here when they are published"), on both the
  repo copy (`date: 2026-11-16`) and the live docs page. It lists no versions or addresses.
- **Registry commit.** The proposal cites registry commit `7e1be454…`; the ops README cites `41553edc…` for the same
  file. The file at `7e1be454…` is byte-identical to the one at `4c273edd…` (monorepo submodule pin). `41553edc…` was not fetched.
- **Ops task adds one fact the proposal's summary does not state**: on OP Mainnet the upgrade rotates the
  `SUPER_PERMISSIONED` proposer from `0x473300df21D047806A082244b417f96b32f13A33` to `0xc27ba3E0Fc01567a5E57Ae0c391AA98cECBA5bE0`
  (the address is visible in the proposal calldata).

### 2.4 Version table for `op-contracts/v9.0.0`

Sources: (S) `semver-lock.json` + source `version` constant in `/home/user/ethereum-optimism/op-v9.0.0` @ `ba6fcadb`;
(R) superchain-registry `standard-versions-mainnet.toml` @ `7e1be454`, entry `["op-contracts/v9.0.0"]`, with the
`["op-contracts/v8.0.0"]` entry for comparison; (C) OP Mainnet on `l1` @ 26433900.

| Contract | (S) v9 source | (R) v9.0.0 version / address | (R) v8.0.0 address | (C) OP Mainnet proxy -> implementation, `version()` | Implementation changed by U21 |
|---|---|---|---|---|---|
| OptimismPortal2 | 6.1.0 | 6.1.0 / `0xb20b23af6071405c37ddda0c0640e8ebb7899645` | `0x1005217a…` (5.8.0) | `0xbEb5Fc57…` -> `0xb20b23af…`, 6.1.0 (5.8.0 on `l1pre`) | yes |
| SystemConfig | 4.3.0 | 4.3.0 / `0xade27248542c0f3e89b49e4eb76155e267f14377` | `0x670b850a…` (4.0.0) | `0x229047fe…` -> `0xade27248…`, 4.3.0 | yes |
| ETHLockbox | 2.0.0 | 2.0.0 / `0xdf75e6b07e98873e36ba5c05508f80c1454e0afe` | `0xb3a24db0…` (1.3.1) | `0x322b47Ff…` -> `0xdf75e6b0…`, 2.0.0 (1.3.1 on `l1pre`) | yes |
| AnchorStateRegistry | 4.0.0 | 4.0.0 / `0x2b27299c577d4720100e2735b652444dcea652d0` | `0x8f40cc98…` (3.9.0) | `0x23B2C629…` -> `0x2b27299c…`, 4.0.0 | yes |
| DelayedWETH | 2.0.0 | 2.0.0 / `0xf024e96317907c3b8d8cb346b9fd9034c8640e15` | `0xe440cc08…` (1.5.1) | `0x1B6DBF05…` -> `0xf024e963…`, 2.0.0 | yes |
| L1CrossDomainMessenger | 2.13.0 | 2.13.0 / `0x7d4ec7fb1a1b9e6d61c04d5e21e3d68cff639448` | `0x59d49753…` (2.11.1) | `0x25ace71c…` (AddressManager) -> `0x7d4Ec7fB…`, 2.13.0 | yes |
| SuperchainConfig | 2.5.0 | 2.5.0 / `0xa303a644cfbc0c34f6a9dbeafdeba4c967ea01e7` | `0x5570b1f2…` (2.4.3) | `0x95703e09…` -> `0xa303a644…`, 2.5.0 | yes |
| OPContractsManagerV2 | 9.0.3 | 9.0.3 / `0x2d91e6f2bcf6cd1df90e1faf9714e18705ea331f` | `0x1951828c…` (8.0.1) | `0x2d91e6F2…`, 9.0.3 (not proxied) | new contract |
| OPContractsManagerStandardValidator | 4.1.1 | not in the registry entry | — | not read | — |
| DisputeGameFactory | 1.6.1 | 1.6.1 / `0x72b971717e088b59f26d4236be222adb6acd393b` | same address | `0xe5965Ab5…` -> `0x72b97171…`, 1.6.1 | **no** (same address in v8 and v9) |
| L1StandardBridge | 2.8.2 | 2.8.2 / `0xb37a11aadf167b2f0b8dd85372de4bc66cd4a891` | same address | `0x99C9fc46…` -> `0xb37a11aa…`, 2.8.2 | **no** |
| L1ERC721Bridge | 2.9.1 | 2.9.1 / `0x9f164f1d02a81e06d639e55f65a87f0070e3cb2e` | same address | `0x5a7749f8…` -> `0x9f164f1d…`, 2.9.1 | **no** |
| OptimismMintableERC20Factory | 1.11.0 | 1.11.0 / `0xaabea75da509fa518fd8a91eae4be5813b829b12` | same address | `0x75505a97…` -> `0xaabea75d…`, 1.11.0 | **no** |
| MIPS64 | 1.10.1 | 1.10.1 / `0xacc005dcd857b401e4732e6f7837135a22825cfa` | same address | `version()` 1.10.1 at that address | **no** |
| PreimageOracle | 1.1.5 | 1.1.5 / `0x1e1d73536a081ef2f355d29794547a9770aeb1e0` | same address | `version()` 1.1.5 at that address | **no** |
| FaultDisputeGame | 2.4.2 | 2.4.2 / no address | — | no game type on the OP Mainnet DGF uses it | n/a |
| PermissionedDisputeGame | 2.4.0 | 2.4.0 / no address | — | no game type on the OP Mainnet DGF uses it | n/a |
| SuperFaultDisputeGame | 0.8.0 | not in the registry entry | — | `gameImpls(9)` = `0x19AF533Cc2A2A55786DCB8672aA5717e64213208`, `version()` 0.8.0; **same address on `l1pre`** | **no** |
| SuperPermissionedDisputeGame | 1.1.0 | not in the registry entry | — | `gameImpls(5)` = `0x5C3eb47cB0174aea522a2a9Ae79487139A53D691`, `version()` 1.1.0; **same address on `l1pre`** | **no** |
| ZKDisputeGame | 2.1.0 | not in the registry entry | — | not registered (types 0–4, 6–8, 10–12 return zero) | n/a |

Consequences for the hunt:

- U21 put new bytecode behind six proxies per chain (portal, SystemConfig, lockbox, ASR, DelayedWETH, L1CDM) plus
  the shared SuperchainConfig, and introduced a new OPCM. That is the "code for the proposal".
- DisputeGameFactory, L1StandardBridge, L1ERC721Bridge, OptimismMintableERC20Factory, MIPS64, PreimageOracle and both
  registered game implementations are **the same deployed contracts as before U21**. LANE_CONTEXT §2 lists source
  changes v8 -> v9 in several of these files; whatever those changes are, they are not live unless a bytecode
  comparison shows otherwise. The game contracts were identified here by `version()` only, not by bytecode.
- Contracts LANE_CONTEXT §3 left unidentified: `0x5a7749f8…` = L1ERC721Bridge, `0x75505a97…` =
  OptimismMintableERC20Factory, `0x1b6dbf05…` = DelayedWETH (`SystemConfig.delayedWETH()`).

Sibling chains on `l1` @ 26433900 (all four ProxyAdmins are owned by `0x5a0Aae59…`; all share
`SuperchainConfig` `0x95703e09…`; portal / SystemConfig / lockbox / ASR / DGF implementations are the **same addresses**
as OP Mainnet):

| Chain | SystemConfig | Portal | ETHLockbox | ASR | DGF | L1CDM | L1StandardBridge | DelayedWETH | `gameImpls(9)` / `(5)` |
|---|---|---|---|---|---|---|---|---|---|
| Ink 57073 | `0x62c0a111929fa32cec2f76adba54c16afb6e8364` | `0x5d66C1782664115999C47c9fA5cd031f495D3e4F` | `0xbd4AbB321138e8Eddc399cE64E66451294325a14` | `0xEe018bAf058227872540AC60eFbd38b023d9dAe2` | `0x10d7B35078d3baabB96Dd45a9143B94be65b12CD` | `0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f` | `0x88FF1e5b602916615391F55854588EFcBB7663f0` | `0x57b4C29DAee99a28E6E86778b499361294c134eA` | `0x19AF533C…` / `0x5C3eb47c…` |
| Soneium 1868 | `0x7a8ed66b319911a0f3e7288bddab30d9c0c875c3` | `0x88e529A6ccd302c948689Cd5156C83D4614FAE92` | `0x67B4de6FfA66EF201Ea6099A89cA397D56622E31` | `0x4890928941e62e273dA359374b105F803329F473` | `0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0` | `0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f` | `0xeb9bf100225c214Efc3E7C651ebbaDcF85177607` | `0x18fBb58C366e21F395DdEc7cBa0510a2D9116B47` | zero / `0x5C3eb47c…` |
| Unichain 130 | `0xc407398d063f942febbcc6f80a156b47f3f1bda6` | `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` | `0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5` | `0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9` | `0x2F12d621a16e2d3285929C9996f478508951dFe4` | `0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6` | `0x81014F44b0a345033bB2b3B21C7a1A308B35fEeA` | `0x74ad145aC900F1DD5551F0C9E143314DC4022FCf` | `0x19AF533C…` / `0x5C3eb47c…` |

---

## 3. Asset-eligibility table for the hunt

Classes:
**(a)** explicitly listed in the live Immunefi asset table (a listed proxy carries its current implementation by the proxy rule);
**(b)** not listed, but its code or configuration is U21 upgrade code/calldata, so the Governance Proposals clause is the argument;
**(c)** reachable only through Primacy of Impact (Smart Contract Critical/High/Medium);
**(d)** out of scope, or no basis found.
Where two classes are given, the first is the primary argument and the second the fallback. Classification is this
lane's reading of the live text; triage decides.

### 3.1 OP Mainnet (chain 10)

| Contract | Proxy | Implementation (v9) | Class | Evidence |
|---|---|---|---|---|
| OptimismPortal2 | `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` | `0xb20b23af6071405c37ddda0c0640e8ebb7899645` 6.1.0 | **(a)** | Asset row "OptimismPortal", etherscan `0xbEb5…06Ed`, added 2024-03-11 + proxy rule. The separate row "OptimismPortal Implementation" `0xe2F82632…` is a stale 3.10.0 implementation and adds nothing. |
| SystemConfig | `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` | `0xade27248542c0f3e89b49e4eb76155e267f14377` 4.3.0 | **(a)** | Asset row "SystemConfig", added 2024-03-11 + proxy rule. |
| L1CrossDomainMessenger | `0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1` (ResolvedDelegateProxy) | `0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448` 2.13.0 | **(a)** | Asset row "L1CrossDomainMessenger", added 2024-03-11 + proxy rule. AddressManager `0xdE1FCfB0…` is also listed. |
| DisputeGameFactory | `0xe5965Ab5962eDc7477C8520243A95517CD252fA9` | `0x72b971717e088b59f26d4236be222adb6acd393b` 1.6.1 | **(a)** | Asset row "DisputeGameFactory", added 2024-05-29 + proxy rule. Implementation not changed by U21 (2.4). |
| L1StandardBridge | `0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1` (L1ChugSplashProxy) | `0xb37a11aadf167b2f0b8dd85372de4bc66cd4a891` 2.8.2 | **(a)** | Asset row "L1StandardBridge", added 2024-03-11. Implementation not changed by U21. |
| L1ERC721Bridge | `0x5a7749f83b81B301cAb5f48EB8516B986DAef23D` | `0x9f164f1d02a81e06d639e55f65a87f0070e3cb2e` 2.9.1 | **(a)** | Asset row "L1ERC721Bridge", added 2024-03-11. Implementation not changed by U21. |
| OptimismMintableERC20Factory | `0x75505a97BD334E7BD3C476893285569C4136Fa0F` | `0xaabea75da509fa518fd8a91eae4be5813b829b12` 1.11.0 | **(a)** | Asset row "OptimismMintableERC20Factory", added 2024-03-11. Implementation not changed by U21. |
| ProxyAdmin | `0x543bA4AADBAb8f9025686Bd03993043599c6fB04` (not a proxy) | — | **(a)** | Asset row "ProxyAdmin", added 2024-03-11. State-changing functions are `onlyOwner` in the v9 `ProxyAdmin.sol` source (deployed bytecode not compared); default out-of-scope "attacks requiring access to privileged addresses" applies. |
| **ETHLockbox** | `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43` | `0xdf75e6b07e98873e36ba5c05508f80c1454e0afe` 2.0.0 | **(b)**, fallback **(c)** — **not (a)** | No asset row by name or address. (b): implementation is `eth_lockbox` in the registry's `op-contracts/v9.0.0` entry and was installed by the proposal's `OPCM.upgrade(0x229047fe…)` call. (c): it holds ~182,541 ETH of user deposits and is `OptimismPortal.ethLockbox()` of the listed portal, so "Loss of user funds by direct theft" / "Permanent freezing of funds" are in-scope impacts. The proxy itself predates U21. |
| **AnchorStateRegistry** (current) | `0x23B2C62946350F4246f9f9D027e071f0264FD113` | `0x2b27299c577d4720100e2735b652444dcea652d0` 4.0.0 | **(b)**, fallback **(c)** — **not (a)** | The asset row "AnchorStateRegistry" is `0x18DAc71c228D1C32c99489B7323d441E1175e443`, a different proxy (2.0.0) that the portal no longer uses. The live ASR `0x23B2…` is `OptimismPortal.anchorStateRegistry()`; its implementation is `anchor_state_registry` in the v9.0.0 registry entry. |
| SuperchainConfig | `0x95703e0982140D16f8ebA6d158FccEde42f04a4C` | `0xa303a644cfbc0c34f6a9dbeafdeba4c967ea01e7` 2.5.0 | **(b)**, fallback **(c)** | Not listed. First call of the proposal calldata is `OPCM.upgradeSuperchain` on this address. Pause paths are Guardian-gated. |
| DelayedWETH (current) | `0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162` | `0xf024e96317907c3b8d8cb346b9fd9034c8640e15` 2.0.0 | **(b)**, fallback **(c)** | The asset row "DelayedWETH" is `0xE497B094…` (1.0.0), a different proxy. Note every Critical/High funds impact says "not including proposer/challenger bonds or fee vaults"; bond-only loss maps at most to the Medium "Incorrectly initiated dispute game bond withdrawal…" impact. |
| OPContractsManagerV2 | `0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f` (not a proxy) | — | **(b)**, fallback **(c)** | Not listed. It is the target of all five calls in the proposal calldata, i.e. the proposal's "code". `upgrade` / `upgradeSuperchain` / `migrate` are meaningful only when DELEGATECALLed by the ProxyAdminOwner; a finding needs a permissionless path. `migrate` is not in use: one-level downgrade under the Chains clause unless a governance proposal plans it. |
| SuperFaultDisputeGame (type 9) | `0x19AF533Cc2A2A55786DCB8672aA5717e64213208` (implementation, cloned per game) | — | **(c)** only | Not listed: the rows "FaultDisputeGame" `0x4146DF64…` and "PermissionedDisputeGame" `0xE9daD167…` are other, unregistered contracts. Same address before and after U21, so it is not upgrade code. The proposal does re-register its game args (prestate), which is calldata (b). |
| SuperPermissionedDisputeGame (type 5) | `0x5C3eb47cB0174aea522a2a9Ae79487139A53D691` | — | **(c)** only | As above. Not the respected type on OP Mainnet (respected = 9); creation is proposer-only per the ops README. |
| MIPS64 / PreimageOracle | `0xacc005dcd857b401e4732e6f7837135a22825cfa` / `0x1e1d73536a081ef2f355d29794547a9770aeb1e0` | — | **(c)** only | The rows "MIPS" `0x0f8EdFbD…` (1.0.1) and "PreimageOracle" `0xD326E10B…` (1.0.0) are older contracts. Unchanged by U21. |
| Listed-but-stale: ASR `0x18DAc71c…`, DelayedWETH `0xE497B094…`, FDG `0x4146DF64…`, PDG `0xE9daD167…`, MIPS `0x0f8EdFbD…`, PreimageOracle `0xD326E10B…`, portal impl `0xe2F82632…`, L2OutputOracle `0xdfe97868…` | — | — | **(a)** formally, low value | Still in the table, so a finding on them is formally in scope, but impact must be real on today's system. Not U21 targets. |
| Guardian `0x09f7150D…`, SystemConfig owner `0x847B5c17…`, ProxyAdminOwner Safe `0x5a0Aae59…` | — | — | **(d)** | Privileged roles, not assets. Default out-of-scope: "Impacts caused by attacks requiring access to privileged addresses…". |
| Intermediate implementation `0x2476c911e6d4d9411e677d8faf15a64ac1fdeee8` (LANE_CONTEXT: "probably StorageSetter") | — | — | **(d)** unknown | Not listed, not identified by this lane. Only relevant if a proxy can be left pointing at it. |

### 3.2 Sibling chains upgraded by the same transaction

| Chain | Contracts (addresses in 2.4) | Class | Evidence |
|---|---|---|---|
| Ink (57073) | SystemConfig, Portal, ETHLockbox (~23,089 ETH), ASR, DGF, L1CDM, bridges, DelayedWETH | **(b)** + **(c)** — **not (a)** | No Ink address is in the asset table. (b): the proposal calldata contains `OPCM.upgrade` for SystemConfig `0x62c0a111…`. (c): Chains clause — impact "will be primarily assessed against … OP, Ink, Soneium, and Unichain". The implementations behind these proxies are the same contracts as behind the listed OP Mainnet proxies. |
| Soneium (1868) | same set; ETHLockbox ~2,196 ETH; respected type 5 (permissioned), no type 9 | **(b)** + **(c)** — **not (a)** | As Ink, with SystemConfig `0x7a8ed66b…`. A Soneium-only path through the permissioned game needs the proposer role, which is privileged. |
| Unichain (130) | same set; ETHLockbox ~18,266 ETH; respected type 9 | **(b)** + **(c)** — **not (a)** | As Ink, with SystemConfig `0xc407398d…`. |
| Base | Portal `0x49048044D57e1C92A77f79988d21Fa8fAF74E97e` (6.0.1 per LANE_CONTEXT) | **(d)** for this hunt | Not in the U21 transaction, not in the asset table, not one of the four chains in the Chains clause. The clause says "primarily", so impact on Base is not excluded in terms, but nothing on the page includes it. Not checked: whether Base has its own programme. |
| Any other Superchain / OP Stack chain | — | **(d)** | Same reasoning. Do not assume every chain in the superchain-registry is eligible. |

Reporting rule that follows: if a bug reproduces on OP Mainnet through a listed proxy, file it against that proxy
and cite sibling chains as additional impact. If it exists only on a sibling chain, or only in ETHLockbox / ASR /
SuperchainConfig / DelayedWETH / OPCM, file it under the "Primacy of Impact" placeholder and cite the Governance
Proposals clause in the scope proof.

---

## 4. SCOPE PROOF template

Every candidate report fills this block. A field left as `TODO` means the candidate is not ready to submit.

```
SCOPE PROOF
Asset (as named on Immunefi):        <row name + address from section 1.2, or "Primacy of Impact (Smart Contract)">
Asset class (section 3):             <(a) | (b) | (c)>  and one sentence of evidence
Proposal:                            Upgrade 21 - Interop Readiness, https://gov.optimism.io/t/upgrade-21-interop-readiness/10948
                                     op-contracts/v9.0.0 @ ba6fcadbc57eb99918c5b0f14f57c72527f531e3
                                     executed in 0x024770b5fba87683ee1466562eefb1bcb408c29c764e24abd07c7d4050a82a99 (block 26430859)
Deployed proxy:                      <address> (chain 1)
Implementation:                      <address>, version() = <x.y.z>, read at block <n>; bytecode matches v9 build: <yes/no/not checked>
Affected chain(s):                   <OP Mainnet 10 | Ink 57073 | Soneium 1868 | Unichain 130>; state verified per chain: <yes/no>
Feature in use on those chains:      <yes | no -> severity drops one level (Chains clause)>
Impact class (verbatim from 1.4):    <e.g. "Loss of user funds by direct theft, not including proposer/challenger bonds or fee vaults">
Severity claimed:                    <Critical | High | Medium>
Funds directly affected:             <amount, source of the number>  (Critical reward = 10% of this, capped at $2,000,042)
Known-issue check (1.8, 1.10):       <each relevant row, and why the finding is not that row>
Out-of-scope check (1.8, 1.9):       <privileged address? bonds/fee vault only? griefing only? operator misconfiguration?>
Permissionless:                      <yes | no — which role>
PoC:                                 <path to forge test>; runs on a local fork only; fork block <n>
Prohibited-activity check (1.11):    no transaction sent to mainnet or a public testnet: <confirmed>
```

Pre-filled for the most likely assets (OP Mainnet, read on `l1` @ 26433900; `Impact class`, `Severity`, `Funds` and the
check rows stay `TODO` until there is a finding):

```
SCOPE PROOF — OptimismPortal
Asset (as named on Immunefi):        "OptimismPortal" https://etherscan.io/address/0xbEb5Fc579115071764c7423A4f12eDde41f106Ed (Smart Contract, added 2024-03-11)
Asset class:                         (a) listed proxy; "Whenever the asset is a smart contract proxy, its implementation is also in scope."
Proposal:                            Upgrade 21 (as above); OptimismPortal2 5.8.0 -> 6.1.0
Deployed proxy:                      0xbEb5Fc579115071764c7423A4f12eDde41f106Ed
Implementation:                      0xb20b23af6071405c37ddda0c0640e8ebb7899645, version() = 6.1.0; registry optimism_portal v9.0.0 same address
Affected chain(s):                   OP Mainnet 10. Same implementation behind Ink 0x5d66C178…, Soneium 0x88e529A6…, Unichain 0x0bd48f6B… (not listed assets)
Feature in use:                      deposits, prove/finalize, deleteProvenWithdrawal: yes. INTEROP / migrate paths: no
Impact class candidates:             Critical "Loss of user funds by direct theft…" | Critical "Permanent freezing of funds…" | Critical "Protocol insolvency…" |
                                     High "Temporary freezing of funds… (e.g. recoverable via an upgrade)" | High "Incorrectly proven withdrawal other than by incorrectly resolved dispute game, mitigated by a delay"
Funds reference:                     portal balance 0; custody is ETHLockbox 0x322b47Ff… (182,541.07 ETH)
Known issues to rule out:            MAX_RESOURCE_LIMIT deposit griefing; aliased-sender stranded ETH; large-data / specific-gas message griefing
```

```
SCOPE PROOF — SystemConfig
Asset (as named on Immunefi):        "SystemConfig" https://etherscan.io/address/0x229047fed2591dbec1eF1118d64F7aF3dB9EB290 (added 2024-03-11)
Asset class:                         (a) listed proxy + proxy rule
Proposal:                            Upgrade 21; SystemConfig 4.0.0 -> 4.3.0
Deployed proxy:                      0x229047fed2591dbec1eF1118d64F7aF3dB9EB290
Implementation:                      0xade27248542c0f3e89b49e4eb76155e267f14377, version() = 4.3.0
Affected chain(s):                   OP Mainnet 10 (siblings: Ink 0x62c0a111…, Soneium 0x7a8ed66b…, Unichain 0xc407398d… — not listed)
Feature in use:                      ETH_LOCKBOX = true; INTEROP = false; CUSTOM_GAS_TOKEN = false
Impact class candidates:             as OptimismPortal, plus Blockchain/DLT High "Network not being able to confirm any new transactions, including deposits"
Out-of-scope to rule out:            owner 0x847B5c17… and ProxyAdminOwner paths are privileged
```

```
SCOPE PROOF — ETHLockbox
Asset (as named on Immunefi):        NOT LISTED. Select "Primacy of Impact" (Smart Contract)
Asset class:                         (b) Governance Proposals clause: implementation installed by the U21 calldata, eth_lockbox 2.0.0 in registry op-contracts/v9.0.0;
                                     fallback (c) Primacy of Impact. Also: it is ethLockbox() of the listed OptimismPortal and holds the portal's ETH
Proposal:                            Upgrade 21; ETHLockbox 1.3.1 -> 2.0.0; "ETHLockbox as custody and pause identifier"
Deployed proxy:                      0x322b47Ff1FA8D5611F761e3E275C45B71b294D43 (proxy predates U21)
Implementation:                      0xdf75e6b07e98873e36ba5c05508f80c1454e0afe, version() = 2.0.0
Affected chain(s):                   OP Mainnet 10 (182,541.07 ETH). Ink 0xbd4AbB32… (~23,089), Soneium 0x67B4de6F… (~2,196), Unichain 0x08bA0023… (~18,266)
Feature in use:                      yes on all four chains (proposal: "The chains in this proposal already use an ETHLockbox")
Impact class candidates:             Critical "Loss of user funds by direct theft…" | Critical "Permanent freezing of funds…" | Critical "Protocol insolvency…" | High "Temporary freezing of funds…"
Scope argument to include verbatim:  the Governance Proposals paragraph (1.6) and the Primacy of Impact paragraph (1.7)
```

```
SCOPE PROOF — L1CrossDomainMessenger
Asset (as named on Immunefi):        "L1CrossDomainMessenger" https://etherscan.io/address/0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1 (added 2024-03-11)
Asset class:                         (a) listed proxy (ResolvedDelegateProxy via AddressManager 0xdE1FCfB0…, also listed) + proxy rule
Proposal:                            Upgrade 21; L1CrossDomainMessenger 2.11.1 -> 2.13.0; "L1 bridge hardening"
Deployed proxy:                      0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1
Implementation:                      0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448 (AddressManager "OVM_L1CrossDomainMessenger"), version() = 2.13.0
Affected chain(s):                   OP Mainnet 10 (siblings: Ink 0x69d3Cf86…, Soneium 0x9CF951E3…, Unichain 0x9A3D64E3… — not listed)
Feature in use:                      yes
Impact class candidates:             Critical theft / permanent freezing | High "Temporary freezing of funds… (e.g. recoverable via an upgrade)"
Known issues to rule out:            "Sending cross-chain messages with very large amounts of data, or very specific amounts of gas…" (stuck funds needing an upgrade — excluded);
                                     ResolvedDelegateProxy storage-slot collision; token foot-guns; fake-ERC20 withdrawal blocked on L1.
                                     U21 documents as intended: a messenger withdrawal that can never be relayed stays proven but unfinalized
```

```
SCOPE PROOF — AnchorStateRegistry
Asset (as named on Immunefi):        The listed "AnchorStateRegistry" is 0x18DAc71c228D1C32c99489B7323d441E1175e443 — NOT the live registry.
                                     For the live one select "Primacy of Impact" (Smart Contract)
Asset class:                         (b) Governance Proposals clause (anchor_state_registry 4.0.0 in registry op-contracts/v9.0.0), fallback (c).
                                     It is anchorStateRegistry() of the listed OptimismPortal
Proposal:                            Upgrade 21; AnchorStateRegistry 3.9.0 -> 4.0.0 (pause identifier moves to the lockbox)
Deployed proxy:                      0x23B2C62946350F4246f9f9D027e071f0264FD113
Implementation:                      0x2b27299c577d4720100e2735b652444dcea652d0, version() = 4.0.0
Affected chain(s):                   OP Mainnet 10 (siblings: Ink 0xEe018bAf…, Soneium 0x48909289…, Unichain 0x27Cf508E…)
Feature in use:                      yes
Impact class candidates:             High "Incorrectly proven withdrawal other than by incorrectly resolved dispute game, mitigated by a delay" |
                                     High "Incorrectly resolved dispute game, not detected by op-dispute-mon, allows proving invalid withdrawal" |
                                     Medium "…does not allow proving invalid withdrawal" | Medium "Incorrectly resolved dispute game, detected by op-dispute-mon, excluding bugs in off-chain components" |
                                     Critical theft / freezing if the delay and Guardian mitigations are bypassed
Known issues to rule out:            op-challenger bugs detected by op-dispute-mon; L1-reorg bond loss; "Proof of whale based attacks on Fault Proofs"
```

```
SCOPE PROOF — DisputeGameFactory
Asset (as named on Immunefi):        "DisputeGameFactory" https://etherscan.io/address/0xe5965Ab5962eDc7477C8520243A95517CD252fA9 (added 2024-05-29)
Asset class:                         (a) listed proxy + proxy rule. Implementation is NOT new in U21 (same address in registry v8.0.0 and v9.0.0)
Proposal:                            Upgrade 21 re-registers game args only (SUPER_CANNON_KONA prestate 0x03e5a548…37c9; SUPER_PERMISSIONED proposer on OP Mainnet)
Deployed proxy:                      0xe5965Ab5962eDc7477C8520243A95517CD252fA9
Implementation:                      0x72b971717e088b59f26d4236be222adb6acd393b, version() = 1.6.1
Registered games:                    type 9 -> 0x19AF533Cc2A2A55786DCB8672aA5717e64213208 (0.8.0, bond 0.08 ETH); type 5 -> 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691 (1.1.0, bond 0).
                                     Neither game implementation is a listed asset -> Primacy of Impact for bugs inside the game contracts
Affected chain(s):                   OP Mainnet 10 (siblings: Ink 0x10d7B350…, Soneium 0x512A3d2c…, Unichain 0x2F12d621…)
Impact class candidates:             the four dispute-game impacts (High/Medium) in 1.4; Medium "Incorrectly initiated dispute game bond withdrawal other than by incorrectly resolved dispute game, mitigated by a delay"
Out-of-scope to rule out:            every Critical/High funds impact excludes "proposer/challenger bonds or fee vaults"
```

---

## 5. Scope risks for this hunt

1. **ETHLockbox is not a listed asset on any chain.** The contract that holds the ETH (182,541 on OP Mainnet) is covered
   only by the Governance Proposals clause and by Primacy of Impact. Both are real terms of the live programme, and the
   impacts (theft, freezing, insolvency) are listed at Critical, so the risk is of argument at triage, not of a clear exclusion.
2. **The asset table is stale relative to chain state.** Programme last updated 2026-10-13. The listed AnchorStateRegistry,
   DelayedWETH, FaultDisputeGame, PermissionedDisputeGame, MIPS, PreimageOracle and "OptimismPortal Implementation" rows
   point at contracts the live system no longer uses. The live ASR, DelayedWETH, both registered game implementations,
   MIPS64 and PreimageOracle are unlisted. Dispute-layer findings will mostly have to be filed under Primacy of Impact.
3. **"Latest in-flight" wording.** U21 executed on 2026-11-16. The clause covers "the latest Protocol Upgrade Proposals"
   and U21 is still the latest, but the page gives no rule for an executed proposal. For the three listed proxies whose
   implementation changed (portal, SystemConfig, L1CDM) this does not matter (proxy rule). For ETHLockbox / ASR / SuperchainConfig / DelayedWETH / OPCM it is
   the difference between class (b) and class (c).
4. **Sibling chains are named for impact assessment, not as assets.** Ink, Soneium and Unichain addresses are in no
   asset row. A finding that exists only through a sibling chain's configuration needs Primacy of Impact. Base and all
   other chains have no basis on the page.
5. **One-level downgrade for features not in use.** `INTEROP` is false and `OPContractsManagerV2.migrate` has not been
   called on any of the four chains; the notice says U21 "does not call the migration". A bug that needs the interop /
   shared-lockbox / migration path drops one severity level unless a governance proposal plans that feature. Forum topic
   10919 ("Towards Mainnet Interop: Introducing the Inaugural Unichain and OP Mainnet set", 2026-10-22) exists; it was
   not read and whether it counts as a governance proposal for this purpose is open.
6. **Exclusions that sit directly on the U21 changes.**
   - Messenger gas work (`LOCAL_*` / `REMOTE_*` constants, portal revert on failed relay): the known issue "very large
     amounts of data, or very specific amounts of gas … causing the sender's funds to be stuck and requiring an upgrade
     to release them" is excluded, and U21 documents "stays proven but unfinalized" as intended.
   - Bonds and fee vaults are carved out of every Critical/High funds impact; DelayedWETH bond theft is Medium at most.
   - "Incorrectly resolved dispute game, detected by op-dispute-mon" is Medium, and op-challenger / off-chain causes are excluded.
   - "Proof of whale based attacks on Fault Proofs" is excluded.
   - Anything requiring Guardian, SystemConfig owner, ProxyAdminOwner, proposer or challenger keys falls under the default
     privileged-address exclusion; `OPContractsManagerV2` entry points are in this group.
7. **Process terms.** PoC is required; KYC is required (W-9 / W-8); each submission costs 50 USDC; Critical pays 10% of
   funds directly affected up to $2,000,042 with no stated minimum; testing on mainnet or public testnets is prohibited
   and, per Optimism's own policy, forfeits the reward.

Items not verified by this lane: the raw vote.optimism.io page (HTTP 403 to `curl`; summary only); registry commit
`41553edc…`; bytecode equality of deployed implementations against the v9 build; `OPContractsManagerStandardValidator`
address; whether Base runs a separate bounty programme.
