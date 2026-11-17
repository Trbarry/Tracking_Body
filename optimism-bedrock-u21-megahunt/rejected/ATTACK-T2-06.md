# ATTACK-T2-06 — Pre-Bedrock escrow of a pair whose L1 token v9 now classifies as OptimismMintable is frozen

Model: Opus 5.5. Verdict: **KILLED — real meaning change, no eligible impact, no attacker (score 1 < 7).**

Hypothesis (legacy carry-through): the pre-Bedrock L1StandardBridge escrowed every deposit; the Bedrock+ bridge decides
per call, via ERC165 on the L1 token (`/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/universal/StandardBridge.sol:284,391-394`), whether to mint or release. An
escrow written under the old meaning for an L1 token that answers ILegacyMintableERC20 can no longer be released.

Result: the meaning change is REAL and exists for exactly one object. Of 294 L1 tokens with escrow, only
`0x9340857794710bbccf68167222a1DE4F0e269b10` ("Edu", total supply 100,000, `l1Token()` = itself, `l2Bridge()` = 0)
passes full ERC165Checker semantics; `deposits[EDU][EDU]` = 90,170e18 (7 deposits from L1 14,932,146, pre-Bedrock) and
the OP L2 twin at the same address has totalSupply 90,170e18. Under v9 every withdrawal of that pair takes the mint
branch, passes the pair check (self-referential `l1Token`), and reverts in the token's own `mint` (0x58973715): the
escrow has no release path and L2 holders' withdrawals burn on L2 and fail on L1 (replay always fails).
`test_T2c_legacyEscrowPair_reclassifiedMintable_frozen` PASS (vehicle: vm.store L1CDM.xDomainMsgSender slot 204 +
prank L1CDM to enter `onlyOtherBridge`).

Why killed: no attacker and no permissionless entry (the state was created by the token deployer's own self-referential
L2StandardERC20-on-L1 construction and its holders' deposits, -4 victim-selected object); no evidence the token has any
value (unlisted, 100k supply; no third-party price source consulted, by rule) -> no eligible SCOPE 1.4 impact (-3);
the bridge behaviour is the documented Bedrock classification rule. TheDAO `0xbb9bc244…` and `0xef2799d1…` also
answer `supportsInterface` true, but for 0xffffffff too, so ERC165Checker rejects them and their escrow is releasable.
Score: +2 reachable state, +2 deterministic PoC, +1 cross-version root cause, +1 novelty, -4, -3 = -1 (reject).
Open question for the researcher: whether a Primacy-of-Impact report of a frozen pre-Bedrock escrow with no market value
is worth submitting (not recommended).

Evidence: `evidence/attack-wave/T2/l1sb-pairs.json`, LIVE-OBJECTS-T2 section C, fork-test output.
