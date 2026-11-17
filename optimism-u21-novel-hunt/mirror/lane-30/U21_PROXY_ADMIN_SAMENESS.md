# Lane 30 — ProxyAdmin identity / sameness checks

Pinned source: v9 `ba6fcadb…`.

## Identity decoder

`ProxyAdminOwnedBase.proxyAdmin()` first returns the address in `Constants.PROXY_OWNER_ADDRESS`; if zero, it recognizes the single ResolvedDelegateProxy by its slot-0 string and reads its AddressManager from slot 1 (`ProxyAdminOwnedBase.sol:46-76`). `proxyAdminOwner()` then calls `owner()` on that address (`:40-43`). The contract warns that only standard Proxy and ResolvedDelegateProxy are supported (`:16-19`).

The live ChugSplash L1StandardBridge nevertheless works because its owner is stored in the same EIP-1967 owner slot (`L1ChugSplashProxy.sol:164-169,210-217`). Read-only calls at N:

| Proxy family / proxy | `proxyAdmin()` | `proxyAdminOwner()` |
|---|---|---|
| standard Portal `0xbEb5…` | `0x543bA4…fB04` | `0x5a0Aae…d2A` |
| Resolved L1CDM `0x25ac…` | same | same |
| Chug L1Bridge `0x99C9…` | same | same |
| standard Lockbox `0x322b…` | same | same |

ProxyAdmin `owner()` independently returned the same Safe.

## Every equality/sameness check and its gate

| Check | What it gates | Can an attacker-controlled contract spoof one side? | Killing fact |
|---|---|---|---|
| `ProxyAdminOwnedBase._assertSharedProxyAdminOwner` (`:79-85`) | Generic comparison used below. | Yes: an arbitrary contract can implement `proxyAdminOwner()` and return any address. | It is not itself caller authorization. |
| `ETHLockbox.authorizeLockbox` (`ETHLockbox.sol:184-195`) | Adds a lockbox allowed to call `receiveLiquidity`. | The proposed lockbox can lie. | Function first executes `_assertOnlyProxyAdminOwner()` at `:185-189`. Attacker cannot add the liar. |
| `ETHLockbox.migrateLiquidity` (`:203-215`) | Sends the entire Lockbox balance to `_lockbox.receiveLiquidity()`. | Recipient can lie and is attacker-deployable. | Function first requires the real Lockbox's ProxyAdmin owner at `:204-208`. This is privileged governance, suppressed as an attacker path. |
| `ETHLockbox._authorizePortal` (`:220-234`) | Adds a Portal allowed to lock/unlock ETH. | Proposed Portal can lie. | Reachable only from owner-gated `authorizePortal` (`:124-130`) or admin/owner-gated initializer (`:94-108`). It also checks the Portal's SystemConfig resolves the same SC (`:224-228`). |
| Migrator chain-owner equality (`OPContractsManagerMigrator.sol:287-302`) | Permits SystemConfigs into one planned shared migration. | A fake SystemConfig/ProxyAdmin can report the same owner. | Real mutations call each real chain ProxyAdmin and owner-gated Lockbox/SystemConfig/Portal functions (`:417-466,475-555`). An arbitrary delegatecall wrapper preserves an unprivileged `msg.sender`, so those calls revert. |
| MigrationValidator proxy-admin equalities (`…MigrationValidator.sol:257,449,644,656`) | Reports whether shared DGF/Lockbox and legacy WETH/ASR use expected admins. | Yes. | Read-only/post-state validation; grants no capability. |
| StandardValidator equalities (`StandardValidatorUtils.sol:274,306,362,368,406`) | Reports factory/Portal/WETH/ASR ownership/admin shape. | Yes. | Validation only. |

Other `proxyAdminOwner()` occurrences are direct authorization (`DelayedWETH.sol:114,130`, `L1Block.sol:256`, base checks at `ProxyAdminOwnedBase.sol:88-105`), not A-vs-B sameness.

## Result

The comparator is spoofable as a statement about an untrusted target, but no permissionless path uses it as the sole authority. Exploiting it requires the real ProxyAdmin owner to call the dangerous function or to include the malicious contract in a governance migration. That is privileged misuse, not a bounty candidate. It remains a useful composition primitive if a future external entry point moves the sameness check ahead of, or substitutes it for, caller authorization.
