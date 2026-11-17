# ATTACK-T3-04 — Census: L1 releases exceed what was deposited for a pair (deposits[l1][l2] vs L2 supply)

Lane ATK-T3 (bridge token identity / L1ERC721Bridge / OptimismMintableERC20Factory), Opus 5.5 (CLAUDE.md exception, Mythos 5.2 quota until 2026-11-22). Sources: op-contracts v9.0.0 (`/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src`). PoC: `test/poc/attack-wave/T3/test/T3.t.sol`; run output `evidence/attack-wave/T3/forge-final.txt` (9/9 PASS). Kill type: full census of the active pair population (read-only).

**Hypothesis.** Some pair's L2 supply exceeds its L1 escrow (insolvency of the pair), or some L1 escrow is releasable to someone
who never deposited.

**Executed.** `deposits[l1][l2]` (slot 2) at L1 26,433,900 vs OP `totalSupply` at 159,654,093 for the 143 pairs
(`evidence/attack-wave/T3/op_pair_census.json`, summary in `LIVE-OBJECTS-T3.md` section 2).

**Result.** 131 pairs: L2 supply <= L1 escrow. 7 pairs with L2 supply > escrow or a codeless L2 token: all one self-test series
("pWBTC" x6, "VIC"; custom 961-byte L2 tokens with no-op burn, not factory-deployed, custom L1 tokens): each pair's withdrawals are
bounded by that pair's own deposit (escrow never negative) — the real-world twin of `test_B2`. Wrong-pair escrows (USDC -> native
USDC 205.75; DAI -> OP DAI 61,210.94; SNX 102.545; rETH confusion 8.893): a third party can release them only by escrowing the named
L2 token 1:1 in the L2StandardBridge, which in turn funds the depositor's replayable L2 message.

**Barrier.** Per-pair accounting `StandardBridge.sol:292/362` on both chains. The wrong-pair case is the documented foot gun
"Having both (or neither of) the local and remote tokens be OptimismMintable" (SCOPE 1.10, KNOWN, -4), caused by the depositor's own
choice (-4), with impact running through third-party tokens (CADRE-LEGAL 4: out of authorization, not tested on a fork). KILLED.
