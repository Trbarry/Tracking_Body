# ATTACK-T2-05 — A withdrawal of a legacy L1StandardBridge pair releases more than was deposited for that pair

Model: Opus 5.5. Verdict: **KILLED — invariant barrier + full population read.**

Hypothesis: legacy `deposits[l1][l2]` entries and OVM-era L2 tokens (`l1Token()` vs `remoteToken()`, ERC165
detection) let a withdrawal debit a pair it does not belong to, or release beyond the pair's escrow.

Barrier: escrow release is `deposits[_localToken][_remoteToken] -= _amount` with checked arithmetic, keyed by the exact
pair committed in the L2 message (`/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/universal/StandardBridge.sol:292`); the mintable branch never touches escrow
(:284-290); `_isCorrectTokenPair` checks the legacy interface first and `l1Token()` (:402-408). Population: for all
324 pairs ever seen on the OP L1StandardBridge, `deposits(l1,l2)` at 26,433,900 equals Σ ERC20DepositInitiated −
Σ ERC20WithdrawalFinalized exactly (0 mismatches) and no pair ever withdrew more than it deposited. Negative control:
`::test_T2c_negativeControl_nonMintableLegacyPair_releases` (legacy WBTC pair releases exactly 1e8 and debits only its pair).

Evidence: `evidence/attack-wave/T2/l1sb-pairs.json`, `scripts/attack-wave-T2/bridge_pairs.py`. Dual-interface tokens with
`l1Token() != remoteToken()` would only affect the token's own pair (and are third-party token logic, out of authorization).

L2-side cross-check (`scripts/attack-wave-T2/l2_supply_vs_escrow.py`, `evidence/attack-wave/T2/l2-supply-vs-escrow.json`):
of 289 escrowed pairs whose OP L2 token points back to the L1 token, 161 have L2 totalSupply == escrow, 120 below
(pending withdrawals), 8 above. Those 8 are not bridge over-mints: BitBTC `0xc98b98d1…` is minted by its own bridge
`0x158F5130…` (third-party, out of authorization); for the 7 recent tokens (first deposit L1 26,114,9xx) the reported
`totalSupply()` is non-standard — for `0x7c1d54d1…` the L2 Transfer log sum is 2 mints (2,000) − 13 burns (1,222.15) =
777.85 < L1 escrow 1,610 (finalized L1 releases 390), i.e. solvent.
