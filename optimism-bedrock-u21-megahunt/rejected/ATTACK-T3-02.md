# ATTACK-T3-02 — Fake L2 remote mints an L1-side OptimismMintableERC20 (L1 factory 1.11.0 tokens)

Lane ATK-T3 (bridge token identity / L1ERC721Bridge / OptimismMintableERC20Factory), Opus 5.5 (CLAUDE.md exception, Mythos 5.2 quota until 2026-11-22). Sources: op-contracts v9.0.0 (`/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src`). PoC: `test/poc/attack-wave/T3/test/T3.t.sol`; run output `evidence/attack-wave/T3/forge-final.txt` (9/9 PASS). Kill type: failing experiment + full census.

**Hypothesis.** For an L1 token that is itself an OptimismMintableERC20 (created by the L1 factory), L1SB mints instead of releasing
escrow. If the pair check could be satisfied by an attacker L2 token, or if ERC165 detection could flip (e.g. 30k-gas
`ERC165Checker` staticcall), the attacker could mint arbitrary L1 supply.

**Sequence executed** (`test_B3_l1Mintable_remoteIdentityBound`): M created via the deployed L1 factory with remote R; on L2 the
attacker emits withdrawals for M from FakeMintable(M) and FakeSplit(M, R) (1e30 each); control: the legitimate remote R emits one
for 5. On L1: both fakes portal-finalize and fail (`totalSupply(M) == 0`), the control mints exactly 5. Codeless remote of the real
IBEX token (0xf655…, no code on OP): `L2SB.bridgeERC20To` reverts (OZ 4.7.3 `Address.sol:135` "call to non-contract").

**Barrier.** `StandardBridge.sol:284-290` with `_isCorrectTokenPair` (`:402-408`): the second key must equal M's
`REMOTE_TOKEN`, an immutable (`OptimismMintableERC20.sol:25`, legacy `l1Token()` :132 and `remoteToken()` :144 return the same
immutable). Detection flip: a mis-detected mintable token takes the escrow branch and underflows at `:292` (its pair escrow is 0
because every deposit of it burned), so a flip can only revert. **Census** (`evidence/attack-wave/T3/l1_factory_tokens.json`): the
four L1 factories created 4 tokens (OP only: IBEX, SQUID x2, TWETH2), all with L1 `totalSupply == 0` at 26,433,900; none of the
143 L1 tokens withdrawn since Bedrock is mintable under ERC165Checker semantics (`op_pair_census.json`). No live object, no impact. KILLED.
