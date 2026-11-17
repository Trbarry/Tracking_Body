# CATK-F all-generation unsafe-target matrix

The address-complete machine inventory is the 379-entry `inventory.curated_addresses` array in
`evidence/withdrawal-object-census.json`. It is built from all four chain deployment/state/history
files and every `evidence/F2-impl-history-*.json`; it includes proxies and historical
implementations. The table below groups those exact addresses by security semantics rather than
reprinting 379 rows.

## Current proxy identities

| Chain | Portal | ETHLockbox | L1 messenger | Standard bridge | ERC721 bridge |
|---|---|---|---|---|---|
| OP | `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` | `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43` | `0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1` | `0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1` | `0x5a7749f83b81B301cAb5f48EB8516B986DAef23D` |
| Ink | `0x5d66C1782664115999C47c9fA5cd031f495D3e4F` | `0xbd4AbB321138e8Eddc399cE64E66451294325a14` | `0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f` | `0x88FF1e5b602916615391F55854588EFcBB7663f0` | `0x661235a238B11191211fa95D4Dd9E423d521E0Be` |
| Soneium | `0x88e529A6ccd302c948689Cd5156C83D4614FAE92` | `0x67B4de6FfA66EF201Ea6099A89cA397D56622E31` | `0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f` | `0xeb9bf100225c214Efc3E7C651ebbaDcF85177607` | `0x5933e323bE8896DfaCd1cD671442F27dAA10a053` |
| Unichain | `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` | `0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5` | `0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6` | `0x81014F44b0a345033bB2b3B21C7a1A308B35fEeA` | `0xD04D0D87E0bd4D2E50286760a3EF323FeA6849Cf` |

## Generation and trust matrix

Historical implementation counts are unique nonzero implementations observed in the F2 histories,
shown as OP/Ink/Soneium/Unichain.

| Target family | Generations/objects covered | Portal-call behavior and exact authority barrier | Shared-state result |
|---|---|---|---|
| OptimismPortal | 13/10/10/10 implementations; stable proxy per chain | OP portal and its current lockbox are blocked by `_isUnsafeTarget` (`OptimismPortal2.sol:846-849`). Sibling portals accept payable deposits. | All three sibling compositions move exactly 1 ETH from OP custody to sibling custody; no value or privilege is created. |
| ETHLockbox | 3/3/3/3 implementations; four proxies | `lockETH` requires `authorizedPortals[msg.sender]`; the 4×4 live matrix is diagonal. `unlockETH` also rejects while `portal.l2Sender != 0xdead` (`ETHLockbox.sol:144-170`). | Current OP lockbox is hard-blocked. Siblings reject OP portal. A modeled retired OP lockbox can only accept attacker-funded value; withdrawal-time unlock fails. |
| L1CrossDomainMessenger | 13/8/8/8 implementations; four effective proxies | First relay requires `msg.sender == portal && portal.l2Sender == L2Messenger` (`L1CrossDomainMessenger.sol:136-138`). Its own unsafe targets are itself and portal. | Raw attacker withdrawal, noncanonical outer sender, and all three sibling messengers fail to gain relay authority. |
| L1StandardBridge / ERC721Bridge | Standard: 11/7/7/7; ERC721: OP 9 plus four current proxies | Requires both exact messenger caller and committed `xDomainMessageSender == otherBridge` (`StandardBridge.sol:111-115`, `ERC721Bridge.sol:64-68`). | Raw portal calls to all eight current bridges fail. Canonical messenger route preserves attacker as sender, so bridge identity still fails. |
| AnchorStateRegistry | Three distinct OP generations plus three sibling current proxies; current-proxy implementation histories 4/4/4/4 | Mutators call `_assertOnlyGuardian`; caller must equal `ethLockbox.guardian()` (`AnchorStateRegistry.sol:158-160,374-378`). | All six deployed registry objects reject the OP portal; no respected type or retirement state changes. |
| DelayedWETH | 13 distinct historical/current objects across generation branches | Payable receive mints WETH to the portal caller. `recover`/`hold` require `proxyAdminOwner()` (`DelayedWETH.sol:113-117,129-133`). | 52 portal/object balances, all portal allowances, and all portal Transfer/Approval histories are empty. Wrap+sweep recovers exactly attacker-funded ETH only. |
| DisputeGameFactory | 6/6/6/6 implementation generations; four proxies | Configuration/ownership is Ownable; the portal is not owner. | All four fork calls fail; ownership unchanged. Direct calls to retired logic have no proxy storage. |
| SystemConfig | 14/10/11/11 implementations; four proxies | Security setters are `onlyOwner` (for example `SystemConfig.sol:342-467`). | All four portal-framed ownership calls fail; owner/config unchanged. |
| ProxyAdmin | Four current chain admins | Ownable; portal is neither owner nor proxy admin owner. | All four ownership calls fail. |
| AddressManager / resolved-proxy registry | Four managers, including OP legacy manager | `setAddress` is owner-gated. | All four reject; name mappings and owners unchanged. |
| Mintable token factories | OP history has 6 implementations; current family included in inventory | Token creation is intentionally permissionless and creates caller-selected token objects; no protocol authorization is granted by portal caller identity. | No shared custody/control surface. |
| Legacy L2OutputOracle, SuperchainConfig, ProtocolVersions and retired logic | All F2-observed addresses included | Proposer/challenger, guardian, owner, or proxy-state checks; no portal-authority predicate. Standalone old implementations do not share proxy storage. | Zero direct or noncanonical proven withdrawals target any curated address. |
| Portal L1→L2 aliases | 4 source portals × 4 destination L2s | L1 aliasing changes caller identity deterministically; it does not equal checked ProxyAdmin/depositor identities. | All 16 aliases have zero balance/code and zero privileged-identity matches. |
| Code-later targets | 66 unique effective targets chronologically compared | One target became a 23-byte EIP-7702 designator. Its withdrawal commits zero value and the same account as sender/target. | Current delegate rejects the selector; messenger records failure; no shared state touched. |

Historical logic addresses can be called as ordinary contracts, but a call to an implementation does
not execute in its former proxy's storage context. The live-object census found no pending direct or
noncanonical proven withdrawal to any of the 379 system addresses.

