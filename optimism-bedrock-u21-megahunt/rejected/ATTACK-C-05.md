# ATTACK-C-05 — 183,600 NEW_ACCOUNT_STATE_GAS reserve pushes value withdrawals to fresh accounts over the cap

Model: Opus 5.5. Lane ATK-C.

**Measured** (E3/E4 in `results.jsonl`, real txs):
- Messenger, 1 ETH to a never-touched account: m=0 finalize min 537,760 (relayed); m=15.8M 17,102,209 vs
  17,083,307 for value 0 — no 183.6k term: L1CDM uses `SafeCall.call`, not `callWithMinGas`
  (`src/universal/CrossDomainMessenger.sol:285`); the portal's callWithMinGas target is the L1CDM (has code).
- Plain withdrawal 1 ETH, gasLimit 0: new account 401,924 vs pre-funded 215,460 (+186,464);
  gasLimit 16.2M: 17,120,407 vs 16,933,882 (+186,525). Reserve from `src/libraries/SafeCall.sol:131-132`.

**Band.** Plain value withdrawals with gasLimit ~15.87M..~16.05M to a never-touched account need the 1-wei
pre-fund to fit 2^24. **Barrier:** anyone (victim, relayer, even the attacker) can send 1 wei to the target first,
which permanently sets codehash = keccak("") and removes the reserve; nobody can restore codehash 0 (see
ATTACK-C-09 §3). Above ~16.05M: self-chosen gasLimit, known Low "gas ceiling of withdrawals". KILLED.
