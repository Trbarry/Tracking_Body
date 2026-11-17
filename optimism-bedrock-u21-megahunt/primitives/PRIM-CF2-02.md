# PRIM-CF2-02 — Legacy proxy dialect is persistent protocol state

## Primitive

Proxy identity and dispatch dialect can survive every implementation upgrade and remain an input to current upgrade authorization. A current-version implementation does not imply a current proxy mechanism.

## Three-hop edge

- Create before Bedrock: L1CDM uses `ResolvedDelegateProxy`, resolving a name through AddressManager; L1StandardBridge uses `L1ChugSplashProxy` with EIP-1967 implementation/owner slots (`ResolvedDelegateProxy.sol:13-52`, `L1ChugSplashProxy.sol:31-41,193-205,254-259` at `op-contracts/v1.0.0`).
- Transform at Bedrock/U6: SystemDictator registers proxy types/names and transfers AddressManager/bridge ownership to ProxyAdmin; MCP later reinitializes storage-backed dependencies without replacing proxy identities (`SystemDictator.sol:218-256,318-390`; `Deploy.s.sol:776-807,853-901` at the pinned tags).
- Consume through U21: OPCMv2 routes upgrades through ProxyAdmin, uses a StorageSetter to reset initializer bytes, then restores the real implementation (`OPContractsManagerUtils.sol:305-386` at `op-contracts/v9.0.0`).

## Locked target facts

At block 26,430,859, OP Mainnet L1CDM is still `0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1` resolving `OVM_L1CrossDomainMessenger`; L1StandardBridge is still ChugSplash proxy `0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1`. Their full 2021→U21 implementation histories are in `impl-history-op-mainnet.json` and receipt-checked by `CF2-DAG-INTEGRITY`.

## Audit use

For every upgrade or ownership transfer, partition targets by proxy dialect. Verify implementation-name mapping, AddressManager ownership, ProxyAdmin `proxyType`, ChugSplash owner/admin slot, initializer offset, transient StorageSetter behavior, and end-of-block implementation independently. Never infer one dialect's authorization or event semantics from another.

## Outcome

Mechanism established; no admin-routing or initializer-offset exploit was demonstrated in the executed U21 path.
