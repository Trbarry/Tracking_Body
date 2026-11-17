# Source lineage and invariant barriers

## StandardBridge / identity

Across `op-contracts/v2.0.0` through `op-contracts/v9.0.0`, the exact `universal/StandardBridge.sol` content has the
same digest (`dcbe67cc4ff1169ddc7e119578bb7456c9ac1ae88d704310d1f12efcf3e6e208`, `git show` content). Current v9:

- `finalizeBridgeERC20` is `onlyOtherBridge`; mintable tokens require `_isCorrectTokenPair`; non-mintable tokens
  subtract `deposits[local][remote]` before transfer (`StandardBridge.sol:272-298`).
- `_isOptimismMintableERC20` accepts legacy **or** modern ERC165 (`:391-394`).
- `_isCorrectTokenPair` deliberately gives the legacy interface precedence and compares `l1Token()`; only otherwise
  does it compare `remoteToken()` (`:402-407`).
- Legacy `L1StandardBridge.finalizeERC20Withdrawal` forwards the same ordered pair unchanged to
  `finalizeBridgeERC20` (`L1StandardBridge.sol:235-246`).

Thus an attacker-created L2 token can name a real L1 token and produce a message, but the L1 escrow branch addresses
`deposits[realL1][attackerL2]`, not `deposits[realL1][canonicalL2]`.

## Mintable factory / token

Factory 1.10.1 -> 1.10.2 changed only semver; 1.11.0 added initializer authorization via
`ProxyAdminOwnedBase`. CREATE2 identity remains salted by `(remote,name,symbol,decimals)`, and every deployed token
receives immutable `BRIDGE` and `REMOTE_TOKEN` (`OptimismMintableERC20Factory.sol:118-143`,
`OptimismMintableERC20.sol:65-77`). Both legacy and modern getters return that same immutable remote (`:121-145`),
and only the immutable bridge may mint or burn (`:43-46,102-115`). Multiple representations of one remote are
possible, but they have distinct local addresses and therefore distinct pair identities.

## L1ERC721Bridge

Deployed lineage: 2.3.1 -> 2.4.0 (semver only); 2.7.0 moved pause lookup from direct SuperchainConfig to
SystemConfig and added guarded reinitialization; 2.8.0 changed initializer version; 2.9.0 removed obsolete `upgrade`;
2.9.1 moved `ProxyAdminOwnedBase`; v7-v9 logic is byte-for-byte identical apart from formatting. None changed the
escrow key or finalize ordering.

Current v9 keys escrow by `(local,remote,tokenId)` (`L1ERC721Bridge.sol:28`). Finalize requires the exact bit, clears it
before the external `safeTransferFrom`, and transfers only to the message-committed `_to` (`:88-117`). The real-object
fork tests additionally prove the portal and messenger deliver it once, to that recipient, under both N-1 and N.
