# ATTACK-T3-03 — Legacy vs new interface disagreement on a real L2 token rebinds its L1 identity

Lane ATK-T3 (bridge token identity / L1ERC721Bridge / OptimismMintableERC20Factory), Opus 5.5 (CLAUDE.md exception, Mythos 5.2 quota until 2026-11-22). Sources: op-contracts v9.0.0 (`/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src`). PoC: `test/poc/attack-wave/T3/test/T3.t.sol`; run output `evidence/attack-wave/T3/forge-final.txt` (9/9 PASS). Kill type: full-population census + code barrier.

**Hypothesis.** `_isCorrectTokenPair` uses `l1Token()` when the legacy interface is reported, else `remoteToken()`
(`StandardBridge.sol:402-408`). A real L2 token reporting both, with different answers, would let a holder withdraw against a
different L1 pair than the one it was minted for.

**Executed.** Read-only census of all 143 (L1, L2) pairs with an L1StandardBridge withdrawal since Bedrock
(`scripts/pair_census.py`, `erc165_fix.py`; OP @159,654,093): 139 L2 tokens are mintable under ERC165Checker semantics
(90 legacy-only L2StandardERC20, 47 both, 1 new-only); 0 disagree between `l1Token()` and `remoteToken()`; 138 of 139 point
to the L1 token of their pair (the exception is the wrong-pair rETH escrow, ATTACK-T3-04). Attacker-controlled disagreement
(FakeSplit with l1Token = X, remoteToken = HL2) was executed in `test_B1` and fails on L1 (ATTACK-T3-01).

**Barrier.** Whatever address the L2 token reports, the L1 escrow key is (L1 token, address of the L2 token acted on)
(`StandardBridge.sol:292`); a disagreement only selects which L1 token the message names, and that L1 token's escrow for this
exact L2 address is the only one reachable. No real disagreeing token exists. KILLED.
