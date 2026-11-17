# Lane 30 — old primitives newly surrounded by U21

Baseline: v7 `a7c88c8d636ceb9944ea0edaf7d033da258778ab`, v8 `f45a5ccfebcdf6da3f5b09cbc512667c063730b7`, v9 `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`. Hashes below are the first 12 hex characters of SHA-256 over the file at each commit. Equal triples are byte-for-byte source identity, not merely semantic equivalence.

| Old file | v7 | v8 | v9 | U21 reachability |
|---|---:|---:|---:|---|
| `src/L1/ResourceMetering.sol` | `97411c4d1076` | same | same | Inherited by changed `OptimismPortal2`; its `metered` body runs after the deposit body (`ResourceMetering.sol:64-75`, `OptimismPortal2.sol:741-795`). |
| `src/universal/Proxy.sol` | `a124473ec747` | same | same | Wraps standard U21 proxies; implementation/admin dispatch remains the old trust boundary (`Proxy.sol:23-33`). |
| `src/legacy/ResolvedDelegateProxy.sol` | `24d4f783d114` | same | same | Live L1CrossDomainMessenger proxy; U21 changes its AddressManager-resolved implementation. |
| `src/legacy/L1ChugSplashProxy.sol` | `77780b5462aa` | same | same | Live L1StandardBridge proxy; owner slot is also consumed by `ProxyAdminOwnedBase`. |
| `src/legacy/AddressManager.sol` | `786e543f7342` | same | same | Resolves the L1CrossDomainMessenger implementation and owner. |
| `src/universal/StandardBridge.sol` | `7148784212c6` | same | same | Changed L1StandardBridge inherits it (`L1StandardBridge.sol:28`); token and ETH transfer machinery remains old. |
| `src/universal/OptimismMintableERC20Factory.sol` | `d999e5f688c0` | same | same | Reinitialized during upgrade choreography, but final implementation is unchanged v1.11.0. |
| `src/universal/ReinitializableBase.sol` | `0bf64aa25763` | same | same | Changed Portal, SystemConfig, bridges, Lockbox, ASR, DelayedWETH and DGF use its immutable init version. |
| `src/libraries/Hashing.sol` | `35966dc33b11` | same | same | Changed Portal still hashes withdrawals/output roots at `OptimismPortal2.sol:448-453,604`. |
| `src/libraries/Encoding.sol` | `d0dc53ef106a` | same | same | Changed cross-domain messenger retains V0/V1 wire encoding (`Encoding.sol:58-120`). |
| `src/libraries/Types.sol` | `100f2f7f3183` | same | same | Changed Portal still decodes/hashes unchanged withdrawal structs. This is distinct from changed `src/dispute/lib/Types.sol`. |
| `src/libraries/trie/MerkleTrie.sol` | `9ce13ec20148` | same | same | Portal proofs enter it through SecureMerkleTrie (`OptimismPortal2.sol:466-474`). |
| `src/libraries/trie/SecureMerkleTrie.sol` | `755f79cb43e8` | same | same | Same proof path. |
| `src/libraries/rlp/RLPWriter.sol` | `a4abc51a7105` | same | same | Old trie/RLP encoding dependency; no U21 semantic change. |
| `src/libraries/Bytes.sol` | `235a1dcaf00f` | same | same | Old trie byte/nibble machinery. |
| `src/vendor/AddressAliasHelper.sol` | `5e50ac377582` | same | same | Deposit sender aliasing remains at `OptimismPortal2.sol:781-785`. |
| `src/libraries/EOA.sol` | `65c83beb99d3` | same | same | Same deposit alias decision. |
| `src/libraries/Storage.sol` | `b090c231f8f2` | same | same | Changed SystemConfig and semantically unchanged ProxyAdminOwnedBase read old deterministic slots. |
| `src/universal/WETH98.sol` | `e6bd6c08c89b` | same | same | Changed DelayedWETH v2.0.0 still inherits this custody/accounting base (`DelayedWETH.sol:25`). |

Two named items are not unchanged: `src/L1/SuperchainConfig.sol` hashes `632a3c84314c / 4782cfbc3967 / 09b59e3a80cd`; `src/dispute/lib/Types.sol` gains `clearedGameTypes()` in v9. `ProxyAdminOwnedBase.sol` has a formatting-only v8→v9 diff, so its bytecode behavior is unchanged but the file is not byte-identical.

## Historical boundaries that matter

1. **Old metering after a new-looking external call.** `ResourceMetering.metered` deliberately executes `_` first and `_metered` second (`ResourceMetering.sol:66-75`). The Lockbox call precedes Portal validation (`OptimismPortal2.sol:756-779`). However, this exact order already exists in v8 (`v8 OptimismPortal2.sol:684-721`), and OP had `ETH_LOCKBOX=true` at N−1. It is not newly exposed by U21.
2. **Fixed clone code/arguments around mutable singletons.** DGF snapshots `gameArgs` into immutable clone calldata (`DisputeGameFactory.sol:174-216`), while ASR and DelayedWETH are proxies. U21 changed those proxies under 84 sampled in-progress games without changing their addresses.
3. **Legacy proxy identity consumed as authorization metadata.** `ProxyAdminOwnedBase.proxyAdmin()` first reads the EIP-1967 owner slot, then has a special ResolvedDelegateProxy decoder (`ProxyAdminOwnedBase.sol:46-76`). The ChugSplash bridge is outside the stated supported set but happens to use the same EIP-1967 owner slot (`L1ChugSplashProxy.sol:164-169,210-217`). Live reads confirm all three proxy families resolve to the same ProxyAdmin/owner.
4. **Old WETH accounting under a new pause identifier.** DelayedWETH v2 preserves WETH98 balances and withdrawal mappings but replaces the SystemConfig read path with ETHLockbox (`DelayedWETH.sol:42-48,72-108`). The storage spacer preserves the old pointer rather than reinterpreting it.

No old primitive above yielded a permissionless, production-reachable invariant break. The reusable boundaries are recorded as PRIM-3001 through PRIM-3006.
