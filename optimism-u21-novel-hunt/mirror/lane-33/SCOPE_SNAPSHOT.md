# Upgrade 21 scope snapshot — mirror lane 33

**Snapshot date:** 2026-11-17 UTC  
**Lane:** CODEX MIRROR LANE 33, independent mirror of lane 13  
**Target:** Optimism Immunefi programme and Upgrade 21 (`op-contracts/v9.0.0`)  
**Pinned contract commit:** `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`  
**Pinned docs commit:** `e5423ae69b154100a77361d74eb6d7170b2c34aa`

This is a scope record, not a finding. “In scope” below means bounty eligibility still depends on a demonstrated listed impact, the programme rules, and triage. No audit findings were read. The single U21 audit filename/title was recorded without opening the PDF.

## 1. Retrieval ledger

| Item | Canonical source | 2026-11-17 retrieval status |
|---|---|---|
| Programme root | https://immunefi.com/bug-bounty/optimism/ | **LIVE OK**: HTTP 200 after one redirect to `/information/`. |
| Programme information | https://immunefi.com/bug-bounty/optimism/information/ | **LIVE OK**: HTTP 200, server-rendered HTML plus embedded React Server Component JSON; 245,113 bytes; SHA-256 `736fd2202213941f775e4a446bf989512bb636bc38ddd401434a1a2257140d2c`. |
| Programme scope | https://immunefi.com/bug-bounty/optimism/scope/ | **LIVE OK**: HTTP 200, server-rendered HTML plus embedded React Server Component JSON; 297,096 bytes; SHA-256 `141c5ac2c761e99e32e89dc71d1d21f4486af2243c748aea2fdab3881db7d3ba`. The embedded object contained 36 assets, 30 impacts, 10 known issues, reward records, exclusions, and the proxy clause. |
| Discourse search API | https://gov.optimism.io/search.json?q=Upgrade%2021 | **LIVE OK**: HTTP 200 JSON; found topic 10948; SHA-256 `a4045feabd93882ba548b766b73d77685c9f785ab0f55618de81fbfc629c18fb`. |
| U21 Discourse topic API | https://gov.optimism.io/t/upgrade-21-interop-readiness/10948.json | **LIVE OK**: HTTP 200 JSON; SHA-256 `703080e44c7095357a94c52dbe1ac925d1059a88441191e856fd04075a30d577`. |
| Onchain vote page | https://vote.optimism.io/proposals/18704058920168992233750266034048958164367667396985967653465644941701644737084 | **PARTIAL LIVE**: the web renderer/search index returned the official page contents and result; direct `curl -L` returned HTTP 403 with a 70-byte `Forbidden` response. The status and displayed dates below are therefore live-page/search-renderer observations, not a locally archived response. |
| U21 notice | `/home/user/ethereum-optimism/optimism/docs/public-docs/notices/upgrade-21.mdx` | **LOCAL OK, PINNED** at docs commit above. |
| v9 code-hash lock | `/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/snapshots/semver-lock.json` | **LOCAL OK, PINNED** at contract commit above. |
| Execution task | https://github.com/ethereum-optimism/superchain-ops/tree/903cefaa0f07738a81f6473a9adc5c3d7161e5a8/src/tasks/eth/084-U21-op-ink-soneium-uni | **LIVE OK** by shallow HTTPS clone; current commit `903cefaa0f07738a81f6473a9adc5c3d7161e5a8` marks the task executed. |
| Deployed state | `http://127.0.0.1:8547`, Ethereum block 26430859 | **LOCAL READS OK**. Only `eth_call`/`eth_getStorageAt`-equivalent `cast call` and `cast storage` reads were made. |

Machine-readable status and state evidence: `mirror/lane-33/retrieval-manifest.json` and `mirror/lane-33/chain-implementation-map.json`.

## 2. Live Immunefi programme

### 2.1 Headline terms

- Programme: **Optimism**; live since 2022-01-14; live page says last updated 2026-10-13.
- Maximum bounty: **$2,000,042**; rewards are denominated in USD and paid in USDC on Ethereum.
- PoC: **required**. The page requires a PoC demonstrating impact and compliance with Immunefi’s PoC Guidelines and Rules. Cross-domain exploit testing is directed to local/dockerized services and integration tests.
- KYC: required; the page states OptimismPBC requests a W-9 for US residents or W-8 outside the US.
- Smart Contract and Blockchain/DLT Critical/High/Medium impacts use **Primacy of Impact**. Web & App uses **Primacy of Rules**. Testnet and mock files are excluded from Primacy of Impact.
- The live proxy wording is: **“Whenever the asset is a smart contract proxy, its implementation is also in scope.”** The immediately following programme sentence limits ordinary asset-based coverage to entries in the Assets in Scope table. This is why a current implementation behind an explicitly listed proxy is category B below, even if the implementation address is not itself a row.
- Official Protocol Upgrade Proposal calldata and code are additionally covered when the proposal has reached an onchain vote, is posted by OP Labs/Optimism Foundation personnel, or is expressly approved for bounty coverage by them. Governor upgrades and proposal previews are excluded by that clause. U21 satisfies the first two routes.
- The custom chain rule names **OP, Ink, Soneium, and Unichain**. Features active on one of those chains, or planned by governance, can receive the highest-tier impact; an otherwise eligible feature not active there is downgraded one level.

### 2.2 Rewards

| Type | Critical | High | Medium | Primacy |
|---|---:|---:|---:|---|
| Blockchain/DLT | Up to **$2,000,042**; 10% calculation/cap | **$15,000–$50,000** | **$1,000–$15,000** | Impact |
| Smart Contract | Up to **$2,000,042**; 10% of directly affected mainnet funds, capped | **$15,000–$50,000** | **$1,000–$15,000** | Impact |
| Web & App | **$5,000–$50,000** | **$500–$5,000** | **$50–$500** | Rules |

The information page also says Critical awards are capped at 10% of economic damage and remain discretionary, with affected funds plus PR/brand considerations. For Blockchain/DLT, the page describes a funds-at-risk to market-cap ratio using the average of CoinMarketCap and CoinGecko at submission time.

### 2.3 Exact assets in the live embedded table (36)

The spelling, type, target and address below are transcribed from the live embedded object. An Immunefi placeholder is an asset row even though it is not a contract address.

| # | Type | Exact name | Target/address |
|---:|---|---|---|
| 1 | Blockchain/DLT | op-dispute-mon (in scope for impacts listed in the smart contracts section) | https://github.com/ethereum-optimism/optimism/tree/develop/op-dispute-mon |
| 2 | Smart Contract | OptimismPortal | `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` |
| 3 | Smart Contract | ProxyAdmin | `0x543bA4AADBAb8f9025686Bd03993043599c6fB04` |
| 4 | Smart Contract | DisputeGameFactory | `0xe5965Ab5962eDc7477C8520243A95517CD252fA9` |
| 5 | Smart Contract | L2OutputOracle | `0xdfe97868233d1aa22e815a266982f2cf17685a27` |
| 6 | Web & App | Optimism's Community page | https://community.optimism.io/ |
| 7 | Web & App | Optimism's Specs | https://specs.optimism.io/ |
| 8 | Smart Contract | OptimismMintableERC20Factory | `0x75505a97BD334E7BD3C476893285569C4136Fa0F` |
| 9 | Smart Contract | L1CrossDomainMessenger | `0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1` |
| 10 | Smart Contract | PermissionedDisputeGame | `0xE9daD167EF4DE8812C1abD013Ac9570C616599A0` |
| 11 | Web & App | Main OP Labs blog | https://blog.oplabs.co/ |
| 12 | Web & App | Main OP Labs website | https://www.oplabs.co/ |
| 13 | Blockchain/DLT | op-node | https://github.com/ethereum-optimism/optimism/tree/develop/op-node |
| 14 | Smart Contract | DelayedWETH | `0xE497B094d6DbB3D5E4CaAc9a14696D7572588d14` |
| 15 | Web & App | Optimism's Docs | https://docs.optimism.io/ |
| 16 | Web & App | Main Optimism website | https://www.optimism.io/ |
| 17 | Smart Contract | AnchorStateRegistry | `0x18DAc71c228D1C32c99489B7323d441E1175e443` |
| 18 | Web & App | Optimism's Gateway | http://gateway.optimism.io/ |
| 19 | Smart Contract | OptimismPortal Implementation | `0xe2F826324b2faf99E513D16D266c3F80aE87832B` |
| 20 | Smart Contract | FaultDisputeGame | `0x4146DF64D83acB0DcB0c1a4884a16f090165e122` |
| 21 | Web & App | Optimism's Console | https://console.optimism.io/ |
| 22 | Web & App | Optimism's App | https://app.optimism.io/ |
| 23 | Smart Contract | PreimageOracle | `0xD326E10B8186e90F4E2adc5c13a2d0C137ee8b34` |
| 24 | Web & App | Optimism's Careers page | http://jobs.optimism.io/ |
| 25 | Smart Contract | SystemConfig | `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` |
| 26 | Smart Contract | L1ERC721Bridge | `0x5a7749f83b81B301cAb5f48EB8516B986DAef23D` |
| 27 | Smart Contract | L1StandardBridge | `0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1` |
| 28 | Smart Contract | MIPS | `0x0f8EdFbDdD3c0256A80AD8C0F2560B1807873C9c` |
| 29 | Smart Contract | AddressManager | `0xdE1FCfB0851916CA5101820A69b13a4E276bd81F` |
| 30 | Blockchain/DLT | Primacy of Impact | https://immunefi.com |
| 31 | Smart Contract | Primacy of Impact | https://immunefi.com |
| 32 | Smart Contract | PolicyEngineStaking | `0xb5CB7a05DD1311195982A26DFC8222477f9D8179` on OP Mainnet |
| 33 | Blockchain/DLT | op-reth | https://github.com/ethereum-optimism/optimism/tree/develop/rust/op-reth |
| 34 | Web & App | OP Enterprise Dashboard | https://enterprise.optimism.io/ |
| 35 | Web & App | OP Enterprise Dashboard API | https://ope-dashboard-api.optimism.io/ |
| 36 | Web & App | Optimism's Console API | https://dapp-console-api.optimism.io |

### 2.4 Impacts in scope by severity

These are the live programme’s impact labels, grouped by type and severity.

#### Smart Contract — Primacy of Impact

**Critical**

- Protocol insolvency, not including proposer/challenger bonds or fee vaults.
- Loss of user funds by direct theft, not including proposer/challenger bonds or fee vaults.
- Permanent freezing of funds, not including proposer/challenger bonds or fee vaults.

**High**

- Temporary freezing of funds, not including proposer/challenger bonds or fee vaults (for example, recoverable via an upgrade).
- Incorrectly proven withdrawal other than by incorrectly resolved dispute game, mitigated by a delay.
- Incorrectly resolved dispute game, not detected by op-dispute-mon, allows proving invalid withdrawal.

**Medium**

- Incorrectly resolved dispute game, detected by op-dispute-mon, excluding bugs in off-chain components.
- Incorrectly initiated dispute game bond withdrawal other than by incorrectly resolved dispute game, mitigated by a delay.
- Incorrectly resolved dispute game, not detected by op-dispute-mon, does not allow proving invalid withdrawal.
- Direct theft or permanent loss of fee vault funds, excluding missed revenue, unrealized yield, or failure to collect fees from pending transactions.

#### Blockchain/DLT — Primacy of Impact

**Critical**

- Direct loss of funds, not including proposer/challenger bonds or fee vaults.

**High**

- Malicious sequencer/batcher stealing user funds.
- Network unable to confirm any new transactions, including deposits (total network shutdown).
- Freezing of funds where the fix requires an L2 hardfork.

**Medium**

- L2 unable to confirm new transactions while forced inclusion through L1 remains possible.
- Direct theft or permanent loss of fee vault funds, excluding missed revenue, unrealized yield, or failure to collect fees from pending transactions.

#### Web & App — Primacy of Rules

**Critical:** arbitrary system commands; sensitive running-server files or credentials; connected-wallet subdomain takeover; direct theft; malicious transaction alteration/submission through an already connected wallet; malicious HTML/XSS through metadata; multi-user/tenant production-data access, modification or destruction; authenticated actions causing theft or unauthorized onchain transactions; sensitive server configuration, credentials or source code.

**High:** persistent static-content injection/modification without JavaScript; subdomain takeover without an already connected wallet; taking down the application/website.

**Medium:** single-user/tenant production-data access, modification or destruction; authenticated actions lacking a listed Critical consequence.

### 2.5 Known issues (live list; faithful itemization)

The live object contains ten entries. Links and update timestamps are in the embedded object; the first was updated 2026-09-09 and the remaining nine 2026-06-22.

1. Missing zlib error/header validation in kona’s channel decompressor causing cross-client fault-proof divergence.
2. Predictable L1 reorgs allowing dispute-game transaction reordering that can make the honest challenger respond incorrectly and lose its bond while the game still resolves correctly.
3. op-challenger bugs yielding an incorrectly resolved game detected by op-dispute-mon.
4. All upstream-listed devp2p known issues.
5. Bridge token-misconfiguration foot guns, including both/neither side being OptimismMintable and dynamically changing balance tokens.
6. Deposit griefing by filling `MAX_RESOURCE_LIMIT`, partially mitigated by PR 5064.
7. Cross-chain messages with very large data or specific gas causing stuck-fund griefing requiring an upgrade.
8. Irrecoverably stranded ETH when a contract makes a failed portal deposit and the L2 mint goes to its aliased address.
9. The ResolvedDelegateProxy storage-slot-key collision shape, which the programme states does not affect Optimism’s deployed layout.
10. Fake ERC-20 withdrawal through L2StandardBridge, currently stopped at L1StandardBridge; bypassing that L1 protection remains eligible.

This subsection is an item-by-item faithful paraphrase, not represented as a verbatim quotation. The exact source is the live `/information/` embedded `knownIssues` array identified by the hash in §1.

### 2.6 Custom out-of-scope rules (faithful itemization)

The programme’s custom exclusions state:

- Chain assessment focuses on OP, Ink, Soneium and Unichain; inactive/unplanned features are downgraded one level.
- Blockchain/DLT exclusions: user-exposed APIs; operator violations of documented network/proxy best practices; Alt-DA in op-node/op-batcher; end-of-service execution clients such as op-geth; already-public upstream reth reports (simultaneous disclosure to Optimism remains eligible); upstream devp2p known issues; the predictable-L1-reorg bond-loss scenario; and malicious-sequencer derivation discrepancies unless the direct effect is theft of user funds.
- Smart-contract exclusions: third-party custom-token-bridge implementations; op-challenger/off-chain bugs caught by op-dispute-mon; proof-of-whale fault-proof attacks; the protected fake-token withdrawal shape unless L1 protection is bypassed; the non-impacting ResolvedDelegateProxy collision; the contract-depositor alias/stranded-ETH case; large-data/specific-gas cross-chain griefing; `MAX_RESOURCE_LIMIT` deposit griefing; and bridge token-configuration foot guns.
- Web/App exclusions: `explorer.optimism.io`, `testnet-explorer.optimism.io`, `retrofunding.optimism.io`, `public-grafana.optimism.io`, `discord.optimism.io`, `kyc.optimism.io`, `kyb.optimism.io`, `raas.optimism.io`, `contribute.optimism.io`, `superfest.optimism.io`, `welovetheart.optimism.io`, `support.enterprise.optimism.io`; the Auth0-hosted `login.enterprise.optimism.io` page (while Optimism’s tenant configuration and unauthorized dashboard access remain covered); and testnet-faucet allocation abuse absent a genuine authentication flaw.
- Other Optimism-branded assets not controlled by Optimism are excluded.
- Agora operates `vote.optimism.io` and `atlas.optimism.io`; website flaws go to Agora, but direct financial effects on the OP Stack/protocol remain covered through Primacy of Impact.

Default Blockchain/DLT and Smart Contract exclusions additionally cover bad third-party oracle data (without excluding oracle manipulation/flash-loan attacks), basic economic/governance attacks such as 51% attacks, lack of liquidity, Sybil attacks and centralization risks. Default general exclusions cover already-exploited/damaging attacks, leaked credentials, unmodified privileged-address access, external-stablecoin depegs not caused by a code bug, unproven live secrets, best-practice advice, feature requests, test/config-only impacts, and phishing/social engineering.

The live default Web/App exclusions include theoretical reports without proof; physical/local-network access; reflected plain text and self-XSS; OCR-only CAPTCHA bypass; non-impacting CSRF; missing headers/cookie flags without impact; non-confidential server metadata; user enumeration only; abnormal unprompted user actions; TLS best practices; DDoS-only and UI/UX-only effects; browser/plugin defects; non-sensitive API key leakage; browser-bug-dependent exploits; SPF/DMARC/header/scanner-only reports; UI/UX recommendations; and non-future-proof NFT rendering.

This subsection is a faithful itemization rather than a verbatim reproduction. The exact live field is `customOutOfScopeInformation` in the `/scope/` embedded object identified in §1.

### 2.7 Prohibited activities

- Testing deployed code on mainnet or public testnets; testing belongs on local forks.
- Testing with pricing oracles or third-party smart contracts.
- Phishing or social engineering against employees/customers.
- Testing third-party systems/applications, including browser extensions, SSO providers and advertising networks.
- Denial-of-service attacks against project assets.
- Automated service testing that generates significant traffic.
- Public disclosure of an unpatched vulnerability in an embargoed bounty.
- Any other action barred by the Immunefi Rules: https://immunefi.com/rules/

## 3. Upgrade 21 official proposal and execution

### 3.1 Proposal and vote

- **Discourse:** https://gov.optimism.io/t/upgrade-21-interop-readiness/10948 and JSON form above. Topic ID 10948, slug `upgrade-21-interop-readiness`, title **Upgrade 21 - Interop Readiness**. Created `2026-11-04T21:19:51.358Z`; sole post created `2026-11-04T21:19:51.472Z` and updated `2026-11-04T22:56:50.711Z`. Author: AndreaFederici, identified in the post as an OP Labs Senior Solutions Engineer.
- **Proposal type:** Protocol Upgrade. It states U21 is an L1 smart-contract upgrade with no hardfork/activation timestamp, shipped in `op-contracts/v9.0.0`.
- **Vote:** official Agora proposal ID `18704058920168992233750266034048958164367667396985967653465644941701644737084`. The indexed official page displays voting from **11/05 4:55 PM** to **11/11 4:55 PM, 2026**; the live rendered page on 2026-11-17 says **SUCCEEDED / optimistically approved**, ended 4:55 PM Nov 11, 2026, with 0.43% against at retrieval. Direct HTTP retrieval was 403, as recorded in §1.
- **Governance publication:** the proposal action plan says Wednesday, 2026-11-04. The local notice’s provisional table instead says Monday, 2026-11-02 (`upgrade-21.mdx:208-220`); the Discourse API is authoritative for actual publication.

### 3.2 Release, task, chains and dates

- Release tag: `op-contracts/v9.0.0`; same commit as `op-contracts/v9.0.0-rc.1`, abbreviated `ba6fcad`, full pinned commit `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`.
- Official task: `superchain-ops` **`eth/084-U21-op-ink-soneium-uni`**. At commit `903cefaa…`, its README marks it EXECUTED and links transaction `0x024770b5fba87683ee1466562eefb1bcb408c29c764e24abd07c7d4050a82a99` (`README.md:1-14`).
- One `upgradeSuperchain` plus four `upgrade` calls targeted OPCM `0x2d91e6f2bcf6cd1df90e1faf9714e18705ea331f` version 9.0.3 (`README.md:7-21`).
- Mainnet chains: **OP Mainnet (10), Ink (57073), Soneium (1868), Unichain (130)**. The task lists their SystemConfig proxies and respected game types (`README.md:16-35`; `config.toml:11-52`).
- Proposal action plan: audit completed 2026-10-28; proposal 2026-11-04; Sepolia execution 2026-11-09 on OP Sepolia, Ink Sepolia, Soneium Minato, Unichain Sepolia; veto period ended 2026-11-11; mainnet execution targeted and occurred 2026-11-16 on the four mainnet chains.
- Allowed local transaction/receipt evidence confirms status `0x1`, block `26430859`, tx index 358, 6,535,963 gas used and 307 logs.
- The notice confirms no L2 hardfork (`upgrade-21.mdx:23-26,180-183`) and that interop is not activated: U21 does not call migration (`upgrade-21.mdx:57-66`).

### 3.3 Proposal-listed versions and deployed implementation cross-check

The proposal lists the version transitions. The block-N addresses below come from read-only deployed-state resolution, not from assuming an address from source. EIP-1967 pointers were read directly; the messenger and ChugSplash bridge were resolved through ProxyAdmin, consistent with `ProxyAdmin.getProxyImplementation` at `src/universal/ProxyAdmin.sol:101-115` and the legacy proxy mechanisms at `src/legacy/ResolvedDelegateProxy.sol:33-40` and `src/legacy/L1ChugSplashProxy.sol:148-152,199-207`.

| Contract | Proposal transition / final | Block-N deployed address | Cross-check |
|---|---|---|---|
| OPContractsManagerV2 | 8.0.1 → **9.0.3** | direct `0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f` | `version()` = 9.0.3; source `src/L1/opcm/OPContractsManagerV2.sol:164-172`. |
| OPContractsManagerStandardValidator | 3.3.0 → **4.1.1** | direct `0x9E1D01E25f411c5da20C33d1EaDe0F83256d41B2` | OPCM getter + `version()`; source `src/L1/OPContractsManagerStandardValidator.sol:42-50,64-85`. |
| OptimismPortal2 | 5.8.0 → **6.1.0** | `0xb20b23af6071405c37ddda0c0640e8ebb7899645` | OP proxy and all three sibling portals point here; source `src/L1/OptimismPortal2.sol:259-261`. |
| ETHLockbox | 1.3.1 → **2.0.0** | `0xdf75e6b07e98873e36ba5c05508f80c1454e0afe` | All four lockbox proxies point here; source `src/L1/ETHLockbox.sol:81-83`. |
| AnchorStateRegistry | 3.9.0 → **4.0.0** | `0x2b27299c577d4720100e2735b652444dcea652d0` | All four current ASR proxies point here; source `src/dispute/AnchorStateRegistry.sol:25-28`. |
| DelayedWETH | 1.5.1 → **2.0.0** | `0xf024e96317907c3b8d8cb346b9fd9034c8640e15` | OP current proxy read; source `src/dispute/DelayedWETH.sol:32-34`. |
| SystemConfig | 4.0.0 → **4.3.0** | `0xade27248542c0f3e89b49e4eb76155e267f14377` | All four SystemConfig proxies point here; source `src/L1/SystemConfig.sol:178-180`. |
| SuperchainConfig | 2.4.3 → **2.5.0** | `0xa303a644cfbc0c34f6a9dbeafdeba4c967ea01e7` | Shared proxy points here; source `src/L1/SuperchainConfig.sol:54-56`. |
| L1CrossDomainMessenger | 2.11.1 → **2.13.0** | `0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448` | OP ProxyAdmin type RESOLVED, name `OVM_L1CrossDomainMessenger`; source `src/L1/L1CrossDomainMessenger.sol:39-41`. |

The task additionally confirms DGF remains 1.6.1 at implementation `0x72b971…`, L1ERC721Bridge remains 2.9.1 at `0x9f164f…`, L1StandardBridge remains 2.8.2 at `0xB37a11…`, and OptimismMintableERC20Factory remains 1.11.0 at `0xaabea7…`; the task says those bridge/factory implementations are unchanged (`VALIDATION.md:145-160`).

`snapshots/semver-lock.json` is a **source/init-code hash lock, not an address or semantic-version registry**. It does independently enumerate hashes for ETHLockbox (`:6-8`), L1CrossDomainMessenger (`:10-12`), StandardValidator (`:22-24`), Portal (`:26-28`), SuperchainConfig (`:30-32`), SystemConfig (`:34-36`), OPCM (`:38-40`), ASR (`:150-152`), DelayedWETH (`:154-156`) and DGF (`:158-160`). It cannot by itself prove which address was deployed; that is why the chain reads are retained.

### 3.4 Audit references — titles only

- Proposal wording: **Spearbit/Cantina full contracts diff audit for `op-contracts/v8.0.0` → `op-contracts/v9.0.0`**, performed 2026-10-14 through 2026-10-28.
- Published local filename/title: **`2026_11-U21-Cantina.pdf`**.

The PDF was not opened and no finding, severity, conclusion or fix-review content was read.

## 4. Asset eligibility for the U21 deployment

Conservative categories:

- **A — explicitly listed:** exact address is a live Assets in Scope row.
- **B — implementation behind a listed proxy:** exact implementation is covered by the live proxy clause because its proxy is category A. This does not make every proxy using that implementation explicitly listed.
- **C — Primacy of Impact only:** exact address is not a live asset row; eligibility requires a listed Smart Contract/Blockchain impact. U21 proposal code/calldata may provide a second coverage route, shown separately.
- **D — out of scope / unknown:** no reliable asset route was established; do not claim eligibility without programme confirmation or a direct Primacy-of-Impact effect.

### 4.1 OP Mainnet and shared L1 contracts

| Object | Proxy/direct address | Final implementation | Category | U21 proposal code/calldata route | Evidence / conservative conclusion |
|---|---|---|---|---|---|
| OptimismPortal2 | `0xbEb5…06Ed` | `0xb20b…9645` | **A proxy / B impl** | Yes | Exact proxy is asset row 2. Block-N slot + version 6.1.0. The separately listed old implementation `0xe2F8…832B` does not replace the proxy clause for the current implementation. |
| SystemConfig | `0x2290…290` | `0xade2…377` | **A / B** | Yes | Exact proxy is asset row 25; block-N version 4.3.0. |
| ETHLockbox | `0x322b…D43` | `0xdf75…afe` | **C / C** | Yes | Neither address is a live asset row. Scope rests on demonstrated impact and/or official U21 proposal code/calldata. |
| AnchorStateRegistry (current U21 proxy) | `0x23B2…113` | `0x2b27…2D0` | **C / C** | Yes | Live row 17 instead lists `0x18DA…443`; it is not this current proxy. Do not call the current ASR “explicitly listed.” |
| DisputeGameFactory | `0xe596…fA9` | `0x72b9…93b` | **A / B** | Calldata yes; implementation unchanged | Exact proxy is asset row 4; block-N version 1.6.1. |
| SuperchainConfig | `0x9570…a4C` | `0xa303…1e7` | **C / C** | Yes | No exact live asset row; shared proxy upgraded to 2.5.0. |
| L1CrossDomainMessenger | `0x25ac…fA1` | `0x7d4E…448` | **A / B** | Yes | Exact proxy is asset row 9; resolved implementation version 2.13.0. |
| L1StandardBridge | `0x99C9…4bE1` | `0xB37a…A891` | **A / B** | Included in task; impl unchanged | Exact proxy is asset row 27; final version 2.8.2. |
| L1ERC721Bridge | `0x5a77…23D` | `0x9F16…b2e` | **A / B** | Included in task; impl unchanged | Exact proxy is asset row 26; final version 2.9.1. |
| OptimismMintableERC20Factory | `0x7550…Fa0F` | `0xaAbE…b12` | **A / B** | Included in task; impl unchanged | Exact proxy is asset row 8; final version 1.11.0. |
| DelayedWETH (current U21 proxy) | `0x1b6d…3162` | `0xF024…0e15` | **C / C** | Yes | Live row 14 lists a different address, `0xE497…8d14`. Current proxy is not explicitly listed. |
| OPContractsManagerV2 | `0x2d91…331f` direct | — | **C** | **Yes** | Canonical U21 proposal/task target, version 9.0.3, but no exact live asset row. |
| OPContractsManagerStandardValidator | `0x9E1D…41B2` direct | — | **C** | Yes | U21 proposal-listed code, no exact live asset row. |
| ProxyAdmin | `0x543b…fB04` direct | — | **A** | Task authority | Exact live asset row 3. |
| AddressManager | `0xdE1F…d81F` direct | — | **A** | Task state change | Exact live asset row 29. |
| Game type 9 implementation | `0x19AF…208` direct | — | **C** | Existing game re-registered by proposal calldata | Not the FaultDisputeGame address in live row 20. Eligibility needs impact. |
| Game type 5 implementation | `0x5C3e…691` direct | — | **C** | Existing game re-registered by proposal calldata | Not the PermissionedDisputeGame address in live row 10. Eligibility needs impact. |
| Guardian `0x09f7…Af2` | role address | — | **D / unknown as asset** | No | A role is not itself a listed target; leaked/privileged access is excluded. A permissionless bug causing listed impact elsewhere may still use Primacy of Impact. |
| SystemConfig owner `0x847B…9D92` | role/Safe | — | **D / unknown as asset** | No | Same caveat; privileged-only control is not a finding. |
| Base portal `0x4904…E97e` | proxy | not U21 | **D / unknown for this U21 hunt** | No | Base was not in task 084 and is absent from the programme’s four named assessment chains. Do not extrapolate U21 coverage. |

### 4.2 Ink, Soneium and Unichain

No sibling proxy address appears in the live 36-row asset table. The programme nevertheless names all three chains for Primacy-of-Impact assessment, and all are in official U21 proposal calldata.

| Chain | Contract | Proxy | Shared final implementation | Proxy category | Implementation category | U21 route |
|---|---|---|---|---|---|---|
| Ink | SystemConfig | `0x62c0…364` | `0xade2…377` | **C** | **B** because the same implementation is behind explicitly listed OP SystemConfig; sibling use itself still needs impact | Yes |
| Ink | OptimismPortal2 | `0x5d66…e4F` | `0xb20b…9645` | **C** | **B** because the same implementation is behind explicitly listed OP Portal | Yes |
| Ink | ETHLockbox | `0xbd4A…a14` | `0xdf75…afe` | **C** | **C** | Yes |
| Ink | AnchorStateRegistry | `0xEe01…Ae2` | `0x2b27…2D0` | **C** | **C** | Yes |
| Soneium | SystemConfig | `0x7a8e…5c3` | `0xade2…377` | **C** | **B**, same caveat | Yes |
| Soneium | OptimismPortal2 | `0x88e5…E92` | `0xb20b…9645` | **C** | **B**, same caveat | Yes |
| Soneium | ETHLockbox | `0x67B4…E31` | `0xdf75…afe` | **C** | **C** | Yes |
| Soneium | AnchorStateRegistry | `0x4890…473` | `0x2b27…2D0` | **C** | **C** | Yes |
| Unichain | SystemConfig | `0xc407…da6` | `0xade2…377` | **C** | **B**, same caveat | Yes |
| Unichain | OptimismPortal2 | `0x0bd4…A7a2` | `0xb20b…9645` | **C** | **B**, same caveat | Yes |
| Unichain | ETHLockbox | `0x08bA…f5C5` | `0xdf75…afe` | **C** | **C** | Yes |
| Unichain | AnchorStateRegistry | `0x27Cf…AFF9` | `0x2b27…2D0` | **C** | **C** | Yes |

The task independently states the four chains share these final versions (`README.md:23-35`), while the block-N reads verify the pointers rather than assuming task execution succeeded.

## 5. SCOPE PROOF templates, pre-filled

Each report should replace the bracketed impact with the single demonstrated live impact and attach a local-fork trace. Merely naming an eligible class is not proof of impact.

### OptimismPortal

- **Asset:** live-listed Smart Contract proxy `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` (category A); current implementation covered by proxy clause (B).
- **Proposal:** Upgrade 21 topic 10948; succeeded vote ID `187040…37084`; execution tx `0x024770…a99`.
- **Deployed proxy:** `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed`.
- **Implementation:** `0xb20b23af6071405c37ddda0c0640e8ebb7899645`, version 6.1.0 at block 26430859.
- **Affected chain:** OP Mainnet (chain ID 10; L1 contracts on Ethereum).
- **Impact class:** `[Smart Contract Critical — direct theft / permanent freezing / insolvency]` or `[High — temporary freezing / incorrectly proven withdrawal]`, exactly as the PoC demonstrates.

### SystemConfig

- **Asset:** live-listed proxy `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` (A); current implementation (B).
- **Proposal:** same U21 topic, vote and execution.
- **Deployed proxy:** `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290`.
- **Implementation:** `0xade27248542c0f3e89b49e4eb76155e267f14377`, version 4.3.0.
- **Affected chain:** OP Mainnet.
- **Impact class:** `[one demonstrated Smart Contract Critical/High/Medium listed impact]`—configuration inconsistency alone is not enough.

### ETHLockbox

- **Asset:** unlisted current proxy and implementation (C); rely on Primacy of Impact and the official U21 proposal-code route.
- **Proposal:** U21 explicitly makes ETHLockbox custody/pause infrastructure; topic 10948, succeeded vote, tx `0x024770…a99`; notice `upgrade-21.mdx:35-47`.
- **Deployed proxy:** `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43`.
- **Implementation:** `0xdf75e6b07e98873e36ba5c05508f80c1454e0afe`, version 2.0.0.
- **Affected chain:** OP Mainnet.
- **Impact class:** `[Smart Contract Critical — theft/permanent freezing/insolvency]` or `[High — temporary freezing]`, with funds and reachability quantified.

### L1CrossDomainMessenger

- **Asset:** live-listed proxy `0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1` (A); resolved implementation (B).
- **Proposal:** U21 bridge-hardening change; topic 10948; notice `upgrade-21.mdx:50-55,185-194`.
- **Deployed proxy:** `0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1` (ResolvedDelegateProxy).
- **Implementation:** `0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448`, version 2.13.0.
- **Affected chain:** OP Mainnet.
- **Impact class:** `[Smart Contract Critical/High listed funds or withdrawal impact]`; exclude the documented large-data/specific-gas griefing shape.

### AnchorStateRegistry

- **Asset:** current proxy `0x23B2…113` is **not** the live-listed ASR `0x18DA…443`; classify current proxy/implementation C and invoke Primacy of Impact plus U21 proposal code.
- **Proposal:** U21 reinitializes/upgrades ASR; topic 10948; task state change `VALIDATION.md:147-155`; notice `upgrade-21.mdx:44-46`.
- **Deployed proxy:** `0x23B2C62946350F4246f9f9D027e071f0264FD113`.
- **Implementation:** `0x2b27299c577d4720100e2735b652444dcea652d0`, version 4.0.0.
- **Affected chain:** OP Mainnet.
- **Impact class:** `[incorrectly proven withdrawal / invalid dispute-game result / direct funds impact]`, selecting the exact demonstrated severity label.

### DisputeGameFactory

- **Asset:** live-listed proxy `0xe5965Ab5962eDc7477C8520243A95517CD252fA9` (A); implementation (B).
- **Proposal:** U21 re-registers game types/args without changing DGF implementation; topic 10948; task `README.md:23-35`, `VALIDATION.md:145-160`.
- **Deployed proxy:** `0xe5965Ab5962eDc7477C8520243A95517CD252fA9`.
- **Implementation:** `0x72b971717e088b59f26d4236be222adb6acd393b`, version 1.6.1.
- **Affected chain:** OP Mainnet.
- **Impact class:** `[Smart Contract High/Medium dispute-game or withdrawal label]` or a direct Critical funds impact if actually demonstrated; account for the op-dispute-mon known-issue boundary.

## 6. Scope risks for this hunt

1. **Address drift is material.** Current U21 ASR (`0x23B2…`) and DelayedWETH (`0x1b6d…`) do not match the live explicitly listed addresses. Treat them as Primacy-of-Impact/proposal assets, not row-listed assets.
2. **Sibling proxies are not listed.** Ink, Soneium and Unichain are expressly named for impact assessment and U21 calldata, but their exact proxies are category C. The shared Portal/SystemConfig implementation addresses have category-B coverage through the OP proxies; that does not transform sibling proxy addresses into explicit rows.
3. **Governance coverage is narrow.** The live clause covers official proposal calldata/code; it should not be stretched to unrelated legacy state, old game implementations, or Base, which task 084 did not upgrade.
4. **The notice is provisional and stale on publication date.** It says so at `upgrade-21.mdx:28-31`; its Nov 2 target conflicts with the actual Nov 4 topic timestamp. Use the live Discourse/vote/task for actual dates.
5. **Impact remains decisive.** Unlisted-address research can still qualify, but only through a listed PoI impact. Configuration oddities, privileged-only behavior, fee-vault/proposer-bond effects at the wrong severity, and known griefing shapes are poor candidates.
6. **Vote retrieval is partially reproducible.** Direct HTTP was denied; retain the official URL and renderer/search observations, and re-capture via an authorized browser if a submission needs a frozen copy.

