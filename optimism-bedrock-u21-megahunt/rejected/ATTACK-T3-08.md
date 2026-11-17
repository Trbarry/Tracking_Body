# ATTACK-T3-08 — OptimismMintableERC20Factory: squat / rebind a token's remote identity or bridge

Lane ATK-T3 (bridge token identity / L1ERC721Bridge / OptimismMintableERC20Factory), Opus 5.5 (CLAUDE.md exception, Mythos 5.2 quota until 2026-11-22). Sources: op-contracts v9.0.0 (`/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src`). PoC: `test/poc/attack-wave/T3/test/T3.t.sol`; run output `evidence/attack-wave/T3/forge-final.txt` (9/9 PASS). Kill type: failing experiment on deployed factory 1.11.0 (L1).

**Hypothesis.** A front-runner creates a token at the CREATE2 address an honest deployer expects with different parameters, or the
factory's `bridge` / a token's `REMOTE_TOKEN` can be changed after creation.

**Executed** (`test_F1_factory_identity_cannotBeRebound`): `bridge() == L1StandardBridge`; `initialize(attacker)` refused;
attacker pre-creates (remote, "Tok", "TOK"); the honest identical creation reverts (CREATE2 collision) but the existing token has the
same remote, bridge, legacy/new identity and `deployments` entry; no setter exists; `mint` by non-bridge reverts.

**Barrier.** Salt = keccak(remote, name, symbol, decimals) with no msg.sender (`OptimismMintableERC20Factory.sol:129-132`), so the
address commits to every identity field and to the factory's immutable-per-deployment `bridge`; `REMOTE_TOKEN`/`BRIDGE` are
immutables (`OptimismMintableERC20.sol:25-28`); `initializer` (`:65`). Squatting only pre-deploys the identical contract. KILLED.
