# ATTACK-CATK-T3-03 — Public mintable factory rebinds one remote identity

Model: Codex, configured by the worker brief as `gpt-daybreak-blue-latest`.

Verdict: **KILLED — immutable identity and distinct local pair keys.**

## Hypothesis

Because OptimismMintableERC20Factory is public and accepts arbitrary metadata, an attacker creates a second local token
for a real remote token, rebinds the first token, mints without the bridge, or uses the duplicate to consume canonical
escrow.

## Exact sequence tried

On deployed L1 and L2 factories, create two tokens with the same remote address but different names/symbols. Compare
addresses, factory `deployments`, legacy and modern getters, and bridge getter; attempt a nonexistent remote setter,
repeat the exact CREATE2 tuple, and call `mint` as the unprivileged deployer. On L1, compare canonical and newly created
pair mappings.

## Barrier

The salt includes `(remote,name,symbol,decimals)`, so differing metadata produces distinct local addresses and an exact
tuple collision reverts (`OptimismMintableERC20Factory.sol:118-143`). `BRIDGE` and `REMOTE_TOKEN` are constructor
immutables (`OptimismMintableERC20.sol:65-77`); both identity getters return that same value, and only the immutable
bridge mints/burns (`:43-46,102-145`). Exact-pair accounting isolates every duplicate local address.

## Evidence

- PASS: `test_factory_sameRemoteCreatesDistinctImmutableIdentities`.
- PASS: `test_l2FactoryTokens_haveImmutableIdentityButNoCanonicalPairEscrow`.
- `mirror/CATK-T3/evidence/fork-test-result.md`.
