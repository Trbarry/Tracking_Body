# CF2 release DAG: Bedrock/OVM residue through Upgrade 21

Status: independently reconstructed through Ethereum block **26,430,859** (`2026-11-16T23:23:59Z`), with `op-contracts/v9.0.0` at commit `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`. `RELEASE-DAG.json` is the machine-readable ledger; this document explains the graph and the security-relevant state transitions.

## Evidence and method

Source pins:

- `O` = `/home/user/ethereum-optimism/optimism` at `e5423ae69b154100a77361d74eb6d7170b2c34aa`.
- `R` = `/home/user/ethereum-optimism/ext/superchain-registry` at `edd89bd1e5b563b450c6a288f7206f3ef3116be2`.
- `S` = `/home/user/ethereum-optimism/ext/superchain-ops` at `903cefaa0f07738a81f6473a9adc5c3d7161e5a8`.
- `C` = passive `cast` reads through `http://127.0.0.1:7545` (L1) and `:7546` (OP Mainnet L2), never state-changing. The four `impl-history-*.json` files record the block, implementation, `version()`, and transaction for every end-of-block transition found by binary search.
- `T` = named test `CF2-DAG-INTEGRITY` in `verify-release-dag.sh`. It validates all JSON, every node's peeled release tag/full commit, 35 release L1 receipts, the Stage-1 L2 receipt, every raw-history transaction/block pair (including OVM/genesis/replacement objects), and the endpoint. It passes locally.

Key file:line evidence:

- `LEG`: at tag `op-contracts/v1.0.0`, `packages/contracts-bedrock/contracts/legacy/ResolvedDelegateProxy.sol:13-52`; `L1ChugSplashProxy.sol:31-41,193-205,254-259`; `deployment/SystemDictator.sol:218-256,263-313,318-390`. These establish the AddressManager-resolved messenger, ChugSplash implementation slot, OVM cleanup, ownership transfer, and Bedrock initialization.
- `L2TAG`: `GasPriceOracle.sol:24-38` at `op-contracts/v1.1.0`, `v1.2.0`, and `v1.5.0` identifies the Canyon, Ecotone, and Fjord L2 contract-release lineages even though those forks have no distinct L1 proxy transaction.
- `MCP`: at `op-contracts/v1.3.0`, `packages/contracts-bedrock/scripts/Deploy.s.sol:733-774,776-807,853-901` shows the SystemConfig address directory and storage-backed bridge/messenger reinitializers.
- `OPCM1`: `OPContractsManager.sol:460-621` at `op-contracts/v2.0.0`, `:525-674` at `v3.0.0`, and `:597-845` at `v4.0.0` establish U13 replacement-ASR logic, U14 plain upgrades/game rotation, and U16's new ASR plus ETHLockbox/liquidity migration.
- `OPCM2`: at `op-contracts/v9.0.0`, `OPContractsManagerV2.sol:239-307,830-996` separates ordinary `upgrade()` from one-way `migrate()` and enumerates U21 initializers; `OPContractsManagerUtils.sol:305-386` proves the StorageSetter/reset/reinitialize/restore sequence; `OptimismPortal2.sol:707-727` limits proof deletion to challenger-won or blacklisted games.
- `HF`: `R/superchain/configs/mainnet/superchain.toml:6-14`, and `ink.toml`, `soneium.toml`, `unichain.toml:15-24`, pin all inherited and divergent activation times.
- `PRE`: `R/validation/standard/standard-prestates.toml:6-14,414-450,490-498`; `standard-versions-mainnet.toml:9-24` pins late prestates and U21 implementations.
- `N13`: `O/docs/public-docs/notices/archive/upgrade-13.mdx:37-75,97-112`; `N15`: `upgrade-15.mdx:14-23,36-77`; `N16`: `upgrade-16.mdx:21-35,101-125`; `N16a`: `upgrade-16a.mdx:23-44,115-123`; `N17`: `upgrade-17.mdx:9-16,108-157`; `N18`: `upgrade-18.mdx:8-19,29-40,83-123`; `N19`: `upgrade-19.mdx:9-37,60-73,183-205,288-320`; `N20`: `upgrade-20.mdx:24-55,86-112,194-247,300`; `N21`: `O/docs/public-docs/notices/upgrade-21.mdx:23-25,35-75,92-106,172-182`.
- `OPS`: executed task descriptions at `S/src/tasks/eth/000-opcm-upgrade-v200/README.md:5-20`, `003-opcm-upgrade-v300-op-ink-soneium/README.md:5-21`, `009-opcm-update-prestate-v300-op+ink/README.md:5-20`, `017-U16-opcm-upgrade-v400-op-ink/README.md:5-20`, `023-U16a-opcm-upgrade-v410-op-soneium-ink/README.md:5-21`, `053-U19-op-ink-mmz-soneium/README.md:5-30`, `071-U20-op-ink-soneium-uni/README.md:5-43`, and `084-U21-op-ink-soneium-uni/README.md:5-42`.
- `AUD`: audit metadata only—never report bodies—from `O/docs/security-reviews/README.md:8-59`.

## Exact graph

```text
OVM residue -> U1 -> U2 -> U3 -> U4 -> U5 -> U6 -> U7 -> U8 -> U9 -> U10
                                                                    |
                                                                    v
U21 <- U20 <- U19b <- U19-L1 <- U18 <- U17 <- U16a <- U16 <- U15 <- U15a <- U14 <- U13 <- U12 <- U11
                                      ^            |
                                      |            +-- direct U15 -> U16a (other chains only; no lockbox)
                                      +-- U18a Arena-Z-only side branch

U13 -> v2.1.0 -> v2.2.0      (late OPCM-v2 maintenance branch; not target execution)
U14 -> v3.0.1                (late deployment-tooling branch; not target execution)
```

The main line is a dependency/state graph, not a claim that every node changed an L1 implementation. U2/U3/U5/U9 are L2 state-transition/derivation nodes; U12 is L1-Pectra client maintenance; U15/U17/U19b are hardfork activations. The branch edges are first-class because they alter later upgrade assumptions even when the four tracked chains did not take them.

## Release identity, classification, and activation/execution

Full hashes below are peeled commits. A shared tag means that one source release supplied multiple governance steps; it does not imply a second L1 upgrade.

| Node | Proposal / classification | Exact release identity | OP Mainnet execution or activation | Other tracked-chain path |
|---|---|---|---|---|
| OVM | targeted legacy residue | pre-numbering; no semver tag | L1CDM AddressManager transitions begin at blocks 12,686,756/12,706,528; bridge at 12,686,787 | OP only (`LEG`,`C`) |
| U1 | Bedrock #1; migration + hardfork + contracts | `v1.0.0` `a12a09f7000ff785a4058998e09b366cbe5a3ed2` | SystemConfig b17,422,444 tx `0x76bceccd7d44656f5a129a600a6120091570b897c1d45c18cd7134cfe67c2537`; remaining proxies b17,423,158 tx `0xe2ff41f9bdf03d5455f55539b8b9c350276a179ca7f79322e2077d7c1ffb1268`; L2 genesis `1686068903` | OP only (`LEG`,`C`,`T`) |
| U2 | Canyon #2; hardfork | `v1.1.0` `c383eb880f307caa3ca41010ec10f30f08396b2e`; optimism `6cce3728b7bed5e36234aeba3b773e0f97867be3`; op-geth `ed8e9f54ed0a5069e77ea34895ff12a9ac4ca17f` | `1704992401` | Ink/Soneium/Unichain `canyon_time=0` at genesis (`L2TAG`,`HF`) |
| U3 | Delta #3; hardfork | no contract tag; optimism `54a7dbf8aa9b982f9c6a54cbbe448be41c0b7bc7` | `1708560000` | later chains `delta_time=0` (`HF`) |
| U4 | SuperchainConfig #4; contracts-only | `v1.2.0` `856c08bf84d9aa829d1e764fc8e9a37d41960ba0` | SC deploy b19,064,589 tx `0x8ba0e42b89cde22310b644ed30fd44e4a348619a165a54c908e7dc341e9bbd0c`; OP upgrade b19,314,493 tx `0x3f7c36a1d636cdb23bf4f9171c27ebe58b73f4c0e6a33dbaac2c2f3c142faf50` | later chains launched against shared SC (`C`,`T`) |
| U5 | Ecotone #5; hardfork | `v1.2.0` same commit; optimism `f707883038d527cbf1e9f8ea513fe33255deadbc`; op-geth `0402d543c3d0cff3a3d344c0f4f83809edb44f10` | `1710374401` | later chains `ecotone_time=0` (`L2TAG`,`HF`) |
| U6 | MCP #6; contracts-only | `v1.3.0` `e6ef3a900c42c8722e72c2e2314027f85d12ced5` | b19,634,866 tx `0x4758bd62359bc69d7e8a0faaf5308d826379c23258d689a7430d5c0ad0361ad2` | later genesis layouts inherit it (`MCP`,`C`,`T`) |
| U7 | Fault Proofs #7; contracts/protocol | `v1.4.0` `547ea72d9849e13ce169fd31df0f9197651b3f86` | proxies b19,884,570 tx `0x2c16c813ff50e9e09a3c58508a9b90293c896f1f91534d09a5002f50bc8760ff`; OP cutover b20,062,696 tx `0xbe810ed6e1e827930bd46cde42c4883662ddb6d244a26af2f0409cc2782bee61` | later chains launched U7-era (`C`,`T`) |
| U8 | Stage-1 authorities #8; authorization/config | `v1.5.0` `9047beb54c66a5c572784efec8984f259302ec92` | OP-L2 PAO b121,221,987 tx `0x93b7a9956faec114c3bac7fd72479ebdc23f8aace38220f8914cbf6af971bf6e`; guardian b20,063,224 tx `0xe361c0d4ae3aebc94b3f281ee372fbb1cbdb0c33ca8b1b35e7f3b009b2fcbdb0`; threshold b20,063,319 tx `0x50db9c1b9f5a8616f982022429a1d75c35986bcfb67bd1e3358d97ddbe751144` | chain-specific launch ownership (`C`,`T`) |
| U9 | Fjord #9; hardfork + game rotation | `v1.5.0` same commit; optimism `f8143c8cbc4cc0c83922c53f17a1e47280673485`; op-geth `7c2819836018bfe0ca07c4e4955754834ffad4e0` | game b20,270,847 tx `0x7abecacd8b1a54db8f0835a5c82edfab96ff922a41d2faa914c339e3e9319b43`; activation `1720627201` | later chains Fjord at genesis (`L2TAG`,`HF`,`T`) |
| U10 | Granite #10; hardfork + contracts | `v1.6.0` `33f06d2d5e4034125df02264a5ffe84571bd0359`; optimism `a81de910dc2fd9b2f67ee946466f2de70d62611a`; op-geth `0f5b9dcfd2ac66f6fd8faae526b1549721f5f392` | b20,723,924 tx `0x3bd2d811d0298313e6fb75f0e69fb54280c9b4f2e60f8f04472aaa166c285641`; activation `1726070401` | later chains Granite at genesis (`HF`,`C`,`T`) |
| U11 | Holocene #11; hardfork + contracts | `v1.8.0` `2073f4059bd806af3e8b76b820aa3fa0b42016d0` | game b21,580,854 tx `0x22ab07b0bb1bc8504256835d555307ff522b78651dca33c9cd5b05591ca5b4f7`; activation `1736445601`; SystemConfig b21,695,024 tx `0x86da7386a26978c3db89e97c1f4feee613a8a0c07bbe4640624b05276f49c350` | Uni same time/SystemConfig b22,081,789; Soneium `1738573200`/b21,945,575; Ink `1742396400` and skipped SystemConfig 2.3.0 (`HF`,`C`,`T`) |
| U12 | L1 Pectra readiness #12; maintenance | no contract tag; op-geth `v1.101500.0`, op-node `v1.11.0/1.11.1`, op-program `v1.5.0-rc.2`, Kona beta | no dedicated tracked core-proxy tx or L2 activation | all chains consume Pectra L1 interpretation; later game rotations fold it in (`N15`) |
| U13 | OPCM/incident response #13; contracts-only | `v2.0.0` `8d0dd96e494b2ba154587877351e87788336a4ec` | OP/Ink/Soneium b22,182,531 tx `0x5f3530e593bbac37c61dc5b7755b6a40c06c20c1a3a1b13fca5b7d00cde65c29` | Unichain b22,254,924 tx `0x7e5e478cafbe30293645e6972a477f77dcfdc006c4cf1dd248a94e6386d04159` (`OPCM1`,`N13`,`OPS`,`T`) |
| M2.1 | unnumbered OPCM-v2 maintenance | `v2.1.0` `e45b33a0233d172596429676e1d3e89943a17799` (tag commit time 2025-08-14) | no tracked execution | alternate independent-superchain path only (`T`) |
| M2.2 | unnumbered OPCM-v2 maintenance | `v2.2.0` `7fe5151ad73e90ec7aed7452dee863a06c821209` (2025-08-15) | no tracked execution | semver-fix continuation of M2.1 (`T`) |
| U14 | Isthmus L1 contracts/MT-Cannon #14; contracts-only | `v3.0.0` `ef7a933ca7f3d27ac40406f87fea25e0c3ba2016` | OP/Ink/Soneium b22,339,996 tx `0xbe44244e352a9ffa67ad7f7133e9ed014b380e4b1bd789419e6d33aaad780d12` | Uni b22,342,667 tx `0xc74c5e0dddfa9e2d0fd5d902fb7b1aa4cc28ba034ebed7bf3a0aa3a8b8d21b20` (`OPCM1`,`OPS`,`T`) |
| M3.0.1 | unnumbered deploy maintenance | `v3.0.1` `48e36d5c7fe1a0f211d7447939b5978ccf55f281` (2025-09-22) | no tracked execution | arbitrary deployment-gas tooling; runtime source hashes unchanged from v3.0.0 (`T`) |
| U15a | Isthmus prestate/blob fix #15a; maintenance | reuses `v3.0.0` `ef7a...`; op-program `v1.6.0-rc.2` | OP/Ink b22,432,368 tx `0xc4a7089a92c96b83475a7c20e40b4c888a277a90208d649c81df243ecdceb587` | Uni b22,432,925 tx `0xd3247421f6f8039ab186878aa996984a67b3149dd543e688b1d30236516eba00`; Soneium skipped (`N15`,`OPS`,`T`) |
| U15 | Isthmus #15; hardfork | v3 contracts already executed; op-node `v1.13.2`, op-geth `v1.101503.4` | `1746806401` | same for all four (`HF`,`N15`) |
| U16 | interop-ready/Stage-1/Cannon #16; contracts-only | `v4.0.0` `54c19f6acb7a6d3505f884bae601733d3d54a3a6` | OP/Ink b22,990,599 tx `0x46acdce174c8d83ebe2f208d8c76c867e75617483d64c3e407f69ae2f9868716` | Soneium b22,990,670 tx `0xdd89a3933dea0f44e1a461441f3c78e341702e9a4148784780644cdac90148c2`; Uni b22,990,722 tx `0x1f1f283ad793a901a94e11241d46b87cd264b2e276a690b9554148ba56c57959` (`OPCM1`,`N16`,`OPS`,`T`) |
| U16a | maintenance #16a; contracts | `v4.1.0` `594bc933a38425f745b46399a3619bcdeb74965d` | OP/Ink/Soneium b23,491,328 tx `0x744cf7d28324729cace731ac736872da669439a0d380f1f52b8d31af203f7329` | Uni b23,492,571 tx `0xc98240172fa3950ec9c62f32cc09d0eb0ed21684b02f1b2677357674cda64ca5` (`N16a`,`OPS`,`T`) |
| U17 | Jovian/Fusaka readiness #17; hardfork + contracts | `v5.0.0` `d09c836f818c73ae139f60b717654c4e53712743` | OP/Ink/Soneium b23,877,377 tx `0xf556934cb4de1ab40a4cfba17856cd601cbc8b875b96a9ccd8ee32bcd363abf5`; activation `1764691201` | Uni b23,878,509 tx `0x7c9e6b65258838fb38bc0bf584cb0c0802bc0dfbbe877a8639880e2ed88b3aa6`; same activation (`HF`,`N17`,`T`) |
| U18 | CGT v2/Kona #18; contracts-only | `v6.0.0` `018f5ae926ec3277746b56a1c4ddb715c568603d` | OP/Ink b24,421,512 tx `0x8808cd53114e4cf07bfde30daf24f2984d4a40ab09c5ca67bd171ac29d6dbf37` | Uni b24,427,874 tx `0x5672a02ba8c40bd35c87787ceddff5181c588e697a1924be6ea061af71cbb4ca`; Soneium b24,478,557 tx `0xeba2fc77f814ea5de7fc0e3b1496926483d14cf8541633c04aec9d1fec8eaf9c` (`N18`,`T`) |
| U18a | Arena-Z servicer migration; maintenance | no global tag | no target tx | Arena-Z only; disjoint authority/proxy/prestate path |
| U19-L1 | Karst contracts phase #19b | `v7.0.0` `a7c88c8d636ceb9944ea0edaf7d033da258778ab`; OPCMv2 `7.1.17` | OP/Ink/Soneium b25,397,811 tx `0xbfdac60c9687a2e469159bf2458e73de2915a0a5eb53c4991a7ecde2b1fb3f15` | Uni b25,475,307 tx `0xb3c65cbf6285d4b32d576c866fffced1c77747c53163b604e20feb6aad121421` (`N19`,`OPS`,`T`) |
| U19b | Karst activation phase #19b; hardfork | same v7 bundle; op-reth/Kona/op-node | `1783526401` | same for all four (`HF`,`N19`) |
| U20 | super-root games/OPCM v8 #20; contracts-only | `v8.0.0` `f45a5ccfebcdf6da3f5b09cbc512667c063730b7`; OPCMv2 `8.0.1` | all four b26,048,619 tx `0x0a0fe86f7b1a3d3d2d0be990e3f8b15628b885363ae527fa9548cb2c2375741a` | same transaction (`N20`,`OPS`,`T`) |
| U21 | interop readiness #21; contracts-only | `v9.0.0` `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`; OPCMv2 `9.0.3` | all four b26,430,859 tx `0x024770b5fba87683ee1466562eefb1bcb408c29c764e24abd07c7d4050a82a99` | same transaction (`OPCM2`,`N21`,`OPS`,`PRE`,`T`) |

## Per-node cumulative-state ledger

This table deliberately states why each node still matters. “No target execution” is not treated as “cannot matter” unless the branch, persistent state, interpretation, authorization, proof, residue, and later dependency are all addressed.

| Node | Contracts/clients and initializer or transform | Storage / ownership / proof effect; why it remains in the DAG |
|---|---|---|
| OVM | Resolved messenger, AddressManager, ChugSplash bridge. Legacy deployment initialization. | Messenger implementation still lives under `OVM_L1CrossDomainMessenger`; bridge remains the same ChugSplash proxy. Storage/message replay state and proxy-specific authorization survive Bedrock. (`LEG`,`C`) |
| U1 | Initializes SystemConfig, L2OutputOracle, Portal; conditionally initializes L1CDM; upgrades bridge and donates its ETH to Portal. | Preserves OVM proxy identities/storage, zeros deprecated CTC/SCC/BondManager names, transfers AM/bridge ownership to ProxyAdmin. This is the root layout/object transform consumed by all later nodes. (`LEG`) |
| U2 | Shapella/Canyon execution rules, Create2Deployer and L2 GPO/L1Block upgrade transactions; op-node/op-geth. | Changes post-Canyon L2 state interpretation. No L1 proxy change, but every later fault program must reproduce it. (`L2TAG`,`HF`) |
| U3 | Span-batch derivation; op-node/batcher/proposer/geth. | No L1 storage. Historical batch decoding is a permanent derivation and proof dependency. |
| U4 | Deploys/initializes shared SuperchainConfig; reinitializes Portal, messenger, bridges and SystemConfig with it. | Creates global guardian/pause root and shared reference. Pause now gates deposits/messages/withdrawals; shared proxy survives through U21. (`C`) |
| U5 | Blob derivation, BeaconRoots, L1Block/GPO Ecotone transactions; node/geth/batcher. | Stores blob base fee/scalars on L2 and changes DA/fee interpretation. No L1 proxy change; proof programs must consume EIP-4844 inputs. (`L2TAG`,`HF`) |
| U6 | Portal, messenger, bridges/factory, L2OO, SystemConfig; each reinitialized with storage-backed dependencies and SystemConfig address directory. | Moves constructor immutables to proxy storage, enabling shared implementations safely. U13/U16/U19 discover objects through these fields. (`MCP`,`C`) |
| U7 | Initializes DGF, DelayedWETH, first ASR; upgrades Portal/SystemConfig; deploys Cannon games, MIPS, PreimageOracle. | Replaces output-oracle security with game/anchor/proven-withdrawal state. Guardian/permissioned fallback become safety authorities. Output-oracle proofs do not port; re-proving is required. Creates live DGF/game ancestry. |
| U8 | StorageSetter writes SuperchainConfig guardian without changing final v1.1.0 implementation; Safe threshold and L2 PAO owner change. | Guardian becomes `0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2`; Security Council threshold 4→10; L2 PAO owner becomes aliased L1PAO `0x6B1BAE59…`. Foundation becomes DeputyGuardian. No proof invalidation, but all later upgrade/pause authority depends on it. (`C`) |
| U9 | RIP-7212, Brotli, FastLZ fee model; rotates DGF types 0/1. | L2 GPO state and derivation semantics persist; absolute prestate `0x03617abec0b255dc7fc7a0513a2c2220140a1dcd7a1c8eca567659bd67e05cea`. Old game objects survive but no longer receive new instances. |
| U10 | ASR U7 object reinitialized/upgraded 1.0.0→2.0.0; games/MIPS/oracle/node/geth updated. | Anchor recovery authority expands; prestate `0x038512e02c4c3f7bdaec27d00edf55b7155e0905301e1a88083e4e0a6764d54c`; pending proofs reset/reprove. Old ASR object remains a historical proof reference even after U13 replaces it. (`C`) |
| U11 | Holocene derivation; SystemConfig 2.3.0 stores EIP-1559 denominator/elasticity; new MIPS/games. | Prestate `0x03f89406817db1ed7fd8b31e13300444652cdb0b9c509a674de43483b2f83568`. Chain-specific timing/implementation divergence is real; Ink skips 2.3.0 and converges at U13. (`HF`,`C`) |
| U12 | Client maintenance for Pectra `requestsHash`, EIP-7702 batch-candidate handling, and fault-program L1 parsing. No tracked initializer. | No dedicated target core-proxy storage transition. It still matters because current derivation/proof programs interpret Pectra-era L1 blocks; only the claim of a distinct proxy transition is excluded. |
| U13 | First OPCM; upgrades core proxies, replaces ASR with new object, deploys games/DelayedWETH, introduces DeputyPauseModule. | Common anchor, game retirement/respected-at-creation and bond refunds. Deputy gets bounded pause; Guardian retains unpause. Prestate `0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9`. All pending proofs invalidated. Creates OPCM lineage. (`OPCM1`,`N13`) |
| M2.1/M2.2 | OPCM/OPCMInterop conditional superchain/version behavior and semver correction; no target call. | No target persistence, authority, proof, game, root-format or L1/L2 change because tags post-date target U16 and no receipt matches. They can matter only on independent-superchain OPCM-v2 branches, so they remain explicit side nodes. |
| U14 | Plain-upgrades SystemConfig, Portal, messenger/bridges; deploys MIPS64 games; OPCM v3. | Installs operator-fee storage and Pectra/Isthmus-ready contracts. Cannon64 prestate `0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405`; mapping rotates without blanket proof invalidation. Baseline consumed by U15. (`OPCM1`) |
| M3.0.1 | DeployOPChain accepts arbitrary gas; no runtime-contract source-hash delta and no target receipt. | Cannot alter target state/authorization/proofs/path. It matters only to chains deployed through that later tooling branch and is not between U14 and U15 on targets. |
| U15a | `OPCM.updatePrestate` deploys new type 0/1 games; blob-preimage client fix. | DGF mapping rotates to `0x03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6`; core proxies unchanged. Required before Isthmus on permissionless targets; Soneium's permissioned branch skipped it. (`N15`,`OPS`) |
| U15 | Activates Prague-on-L2, operator fee, withdrawals root header, limits and predeploy upgrades. | L2 network transactions activate storage/interpretation installed at U14; proofs require Isthmus-aware U15a program. It cannot collapse into either preparatory predecessor. (`N15`,`HF`) |
| U16 | Upgrades SuperchainConfig/SystemConfig/Portal/bridges/DGF; creates third ASR object, ETHLockbox, new DelayedWETH; migrates Portal ETH. | New custody object and per-chain pause identifier; Stage-1 pause expiration/rules. Prestate `0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8`. All pending withdrawal proofs invalidated. All four tracked chains took this branch. (`OPCM1`,`N16`) |
| U16a | Removes interop withdrawal code; conditional OPCM preserves/wires a U16 lockbox or initializes a direct-U15 chain without one. | Real fork: U16→U16a retains custody and proofs; U15→U16a lacks lockbox and invalidates U15 proofs. Targets took U16 first, so no second invalidation. This path bit is consumed by U21. (`N16a`,`C`) |
| U17 | Core contracts/games plus Jovian clients; minimum base fee, DA-footprint scalar/header, Go1.24/Fusaka parsing. | SystemConfig adds fee fields; owner controls them. Prestate `0x03caa1871bb9fe7f9b11217c245c16e4ded33367df5b3ccb2c6d0a847a217d1b`; no blanket invalidation. Creates semantics used by U18/U19. (`N17`) |
| U18 | OPCM reinitializes core contracts; creator-pattern DGF args; installs type 8 Kona; CGT v2 only for new chains. | Type 0 prestate `0x033c000916b4a88cfffeceddd6cf0f4be3897a89195941e5a7c3f8209b4dbb6e`, type 8 `0x0323914d3050e80c3d09da528be54794fde60cd26849cd3410dde0da7cd7d4fa`. Respected type remains 0 (permissionless) / 1 (Soneium); old withdrawals unchanged. (`N18`,`PRE`) |
| U18a | Arena-Z-only DGF clone-arg proposer and three L2 fee-vault implementation/recipient rotations. | Existing games/prestate unchanged. Chain set is disjoint from all four targets, so it cannot alter their objects, authority, proof validity, root format, or upgrade path; it is a numbering side branch. |
| U19-L1 | First OPCMv2 execution; StorageSetter/reset/reinitialize/restore on core proxies; installs L2CM; rewrites creator-game args. | Permissionless respected type 0→8, type 0 disabled for new games; in-flight type-0 games remain resolvable. Kona prestate `0x0337ecb3604c0b40c352e0c7711beb17a212d583f4fe956fd8d66e29ad5f9025`. Unichain still used separate 3-of-3 PAO here. (`N19`,`OPS`) |
| U19b | Karst L2CM network transactions, Osaka/Fusaka EIPs, gas/pairing caps; op-reth/Kona replace op-geth/op-program. | Activates L2 predeploy/state semantics after L1 preparation. Withdrawals now consume type 8. It is the activation half of the U19 governance bundle, not an independent release. (`N19`,`HF`) |
| U20 | OPCMv2 upgrades Portal/SystemConfig/SC/ASR and registers SUPER_PERMISSIONED 5 / SUPER_CANNON_KONA 9. | ASR anchor/sequence becomes timestamp/super-root; SystemConfig clears batchInbox/overhead. Prestate `0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df`. No shared DGF, no interop, no `migrate()`. Old games/proofs remain valid. Uni had transferred to standard L1PAO. (`N20`,`OPS`,`PRE`) |
| U21 | Ordinary OPCMv2 `upgradeSuperchain` + four `upgrade()` calls; reinitializes Portal, Lockbox, L1CDM, bridges, DGF, DelayedWETH and ASR. | Forces ETH_LOCKBOX; lockbox becomes sole pause identifier. All targets already used lockboxes, so no ETH moved. Type 9 prestate `0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9`. Ships but does not call one-way `migrate()`; existing proofs stay valid. `deleteProvenWithdrawal` affects only challenger-won/blacklisted games. (`OPCM2`,`N21`,`OPS`,`PRE`) |

## Proxy ground truth

The exact addresses, implementation addresses, transactions and timestamps are in the four raw files. End-of-block history intentionally omits transient same-transaction StorageSetter hops; U19-U21's hop/reset/reinitialize/restore sequence is source-evidenced by `OPCM2`.

| OP Mainnet proxy/object | Mechanism | Version@first tracked block → version@endpoint (material middle points are in raw JSON) |
|---|---|---|
| Portal `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` | EIP-1967 | `1.6.0@17423158 → 2.4.0 → 2.5.0 → 3.10.0 → 3.13.0 → 3.14.0 → 4.6.0 → 5.0.0 → 5.1.1 → 5.2.0 → 5.6.1 → 5.8.0 → 6.1.0@26430859` |
| SystemConfig `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` | EIP-1967 | `1.3.0@17422444 → 1.11.0 → 1.12.0 → 2.2.0 → 2.3.0 → 2.4.0 → 2.5.0 → 3.4.0 → 3.7.0 → 3.11.0 → 3.13.1 → 3.14.2 → 4.0.0 → 4.3.0` |
| L1CDM `0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1` | ResolvedDelegateProxy/AddressManager | legacy from b12,686,756; Bedrock `1.4.0`; endpoint `2.13.0`; zero-address pause windows at OVM b13,596,294 and Bedrock b17,422,444 |
| L1StandardBridge `0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1` | legacy ChugSplash proxy/EIP-1967 slot | legacy from b12,686,787; Bedrock `1.1.0`; final implementation `2.8.2@U19` (same implementation retained U20/U21) |
| DGF `0xe5965Ab5962eDc7477C8520243A95517CD252fA9` | EIP-1967 | `1.0.0@U7 → 1.0.1 → 1.2.0 → 1.3.0 → 1.4.0 → 1.6.1@U19`; later state/game mappings change without implementation change |
| ASR | three EIP-1967 objects | U7 `0x18DA…` (`1.0.0→2.0.0`, retired U13); U13 `0x1c68…` (`2.2.2`, retired U16); current U16 `0x23B2C62946350F4246f9f9D027e071f0264FD113` (`3.5.0→3.7.0→3.9.0→4.0.0`) |
| ETHLockbox `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43` | EIP-1967, created U16 | `1.2.0@U16 → 1.3.1@U19 → 2.0.0@U21` |
| SuperchainConfig `0x95703e0982140D16f8eba6d158FccEde42f04a4C` | shared EIP-1967 | `1.1.0@U4`; U8 state-only guardian write; `1.2.0→2.3.0→2.4.0→2.4.2→2.4.3→2.5.0` |

For Ink (genesis L1 b21,344,310), Soneium (b21,314,185), and Unichain (b21,116,363), Portal is `3.10.0@genesis → 3.13.0 → 3.14.0 → 4.6.0 → 5.0.0 → 5.1.1 → 5.2.0 → 5.6.1 → 5.8.0 → 6.1.0`. SystemConfig is `2.2.0@genesis → … → 4.3.0`; Soneium/Unichain include `2.3.0`, while Ink goes directly `2.2.0→2.4.0`. See `impl-history-ink.json`, `impl-history-soneium.json`, and `impl-history-unichain.json` for full addresses/blocks/transactions.

## Audit-title/commit map (`AUD` only)

Per-node audit IDs are exact in `RELEASE-DAG.json`. Titles and audited commits from the README index only:

- OVM: **Rollup** (Trail of Bits, commit unlisted); **OVM and Rollup** (OpenZeppelin, unlisted).
- U1: **Bedrock Contracts** (Zeppelin, unlisted); **OpNode** (Trail of Bits, unlisted); **Bedrock GoLang** (Sigma Prime, unlisted); **Bedrock and Periphery** `93d3bd411a8ae75702539ac9c5fe00bad21d4104`; **Drippie** `2a7be367634f147736f960eb2f38a77291cdfcad`; **Invariant Testing** `b31d35b67755479645dd150e7cc8c6710f0b4a56`; **Deposit Transaction** (unlisted); **Bedrock Updates** `ee96ff8585699b054c95c6ff4a2411ee9fedcc87`; **Bedrock** `3f4b3c328153a8aa03611158b6984d624b17c1d9`; **Bedrock Fixes** `9b9f78c6613c6ee53b93ca43c71bb74479f4b975`.
- U4: **Superchain Config Upgrade** `d1651bb22645ebd41ac4bb2ab4786f9a56fc1003`. U6: **MCP L1** `e6ef3a900c42c8722e72c2e2314027f85d12ced5`. U8: **Pausability** (commit unlisted).
- U7/U10: **Fault Proofs** (Sherlock, unlisted); **Fault proof MIPS** `71b93116738ee98c9f8713b1a5dfe626ce06c1b2`; **Fault proof no-MIPS** `1f7081798ce2d49b8643514663d10681cb853a3d`. U11: **Fault proof MIPS** `52d0e60c16498ad4efec8798e3fc1b36b13f46a2`.
- U13: **DeputyPauseModule** `2f17e6b67c61de5d8073d556272796d201bc740b` (MiloTruck and Radiant Labs); **Incident Response Improvements** `984bae9146398a2997ec13757bfe2438ca8f92eb`; **Upgrade 13** `7d6d15437b7580b022f4c8c1ea9c0cd8d2e587e1`.
- U14/U15: **64-bit Multithreaded Cannon** `cc2715c3d6ebef374451b598f48980ad817e0a0e`; **Multi-thread & 64-bit Cannon** `b8c011f18c79d735e01168345fc1c6f02fac584f`. U15a: **op-program and op-challenger blob preimage handling** `08d81d98237a3077fbc13fcd4b70f2e8d2e14115`.
- U16: **Interop Contracts** `6c80f23ab3074b5c66ff06e390ae2448bd4d2240`; **Interop Portal Contracts (u16)** `9df1fc15d0bf0dc9464db249ce06424607d5f399`, `e4b921c9dbf8cd3a8db20ef4f15e0e2aa495fcc3`, `7cd84fed9554193c2dcd683e1ff2d0e2605448f6`; **Cannon updates to support Go 1.23 and Kona** `4c68444bc9b130e892b52cacf67b31f0424fb6d0`; **Cannon Go 1.23 support fix review** `ffe3d5fed05cabf46a67ea00627a0959c0caa0b5`; **Upgrade 16** `54c19f6acb7a6d3505f884bae601733d3d54a3a6`; **VerifyOPCM** `731280c6fc0ad184d252e0fb1d0ad12b5f59fd60`.
- U16a: **U16a** `475801690f7a451469ee4da87b5fe3c54c92f372`. U17: **Cannon Go 1.24 support** `689111fca9a10e6670ba0b5c7f1a549a212c855b`; **U17** `aeed7033f7f739d8ecd4bd70a42ff09013bbc91e`.
- U18: **Custom Gas Token** `1f888ede1940fce20f71db89fc13039fdd96757e`; **Upgrade 18** `87d406db86907833f75d5c8fb26ade3dcb85eb41`; **Kona** `86910c9112437bbb849eca28961f813c5450e103`.
- U19: **Upgrade 19** `7cbcb58ffb7322343f0ed6b926f65bea7630ce3e`; **OPCMv2** `a00b39720a3f61276d2fa3991abfb672c9dd35ce`; **Interop L2 Contracts (re-review)** `fa9974a2cd38d9e7633a12f9024d52f41de55f86`. U20: **Upgrade 20** `7799a2464f23b4e19abd5e29843545f960e677be`. U21: **Upgrade 21** `8fdb2775612f23a7d51bde6c1f4961faf7e0dd7b`.

No index-table audit entry was assigned to U2/U3/U5/U9/U12, the maintenance tag branches, or U18a.

## Corrections, transitive edges, and limits

Conceptual-lineage corrections:

1. Canyon/Ecotone/Fjord share contract-release tags (`v1.1.0`/`v1.2.0`/`v1.5.0`) for L2 predeploy code but are not separate L1 proxy releases; Delta has no contract tag. Granite combines hardfork and ASR/game changes.
2. U8 is a state/authority transition with the same final SuperchainConfig implementation. U12 is Pectra client/proof maintenance, not the later Holocene SystemConfig transaction.
3. `v2.1.0`, `v2.2.0`, and `v3.0.1` were created later than their apparent numerical position and are branch/tooling releases, not target production steps between U13/U14/U15.
4. U15a is the prestate dependency for U15. U16a is a true fork-and-join; all four targets took U16 first. U18a is Arena-Z-only. U19-L1 and U19b are two phases of one governance bundle.
5. U20 does not enable interop/shared dispute infrastructure. U21 ships `migrate()` but executes only standard upgrades; therefore U21 itself does **not** invalidate existing proofs.

Named transitive edges for the next wave:

- **Create U6 → transform U13 → consume U16/U19:** SystemConfig address directory/storage-backed dependencies become OPCM discovery inputs and later OPCMv2 reinitializer inputs.
- **Create U16 → transform U16a → consume U21:** ETHLockbox custody and the feature-path bit determine whether U21 migrates ETH and which address is the pause identifier. All targets were already lockbox-backed, so U21 moved no ETH.
- **Create U18 → transform U19-L1 → consume U20/U21:** type 8 Kona is introduced, becomes respected, then becomes type 9 super-root Kona with successive prestates/root formats.
- **Create U19-L1 → transform U20 → consume U21/future migration:** Portal game-type root dispatch becomes dual output/super-root support, then an interop-ready—but not activated—migration surface.

Limits:

- No separate U12 target core-proxy transaction was established; the evidence supports client maintenance plus later folded game rotations.
- The sibling-chain raw files intentionally cover only Portal and SystemConfig, as requested. OP Mainnet additionally covers L1CDM, L1StandardBridge, DGF, ETHLockbox, all three ASR objects, and SuperchainConfig.
- U18a execution hashes were not needed to establish any target edge and were not reconstructed.
- Audit report bodies were not opened. No governance/audit finding, contest disclosure, or other worker output was consulted.
