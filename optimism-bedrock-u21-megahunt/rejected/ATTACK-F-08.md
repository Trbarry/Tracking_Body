# ATTACK-F-08 — L2 withdrawal to an address that becomes a portal-trusting contract later (past or future CREATE/CREATE2)

Lane ATK-F, Opus 5.5. Kill type: full-population scan + code barrier.

**Hypothesis.** A withdrawal initiated when the target had no code (or a future predictable address) is finalized after a system
contract that trusts the portal is deployed there.

**Scan.** OP Mainnet L2 `MessagePassed` (L2 blocks 105,235,063..159,654,093, :7546) with target in the 477 L1 system addresses
that have code today (all four chains, every generation; L1CDMs excluded) -> 1 hit, WETH9.approve (L2 block 118,450,437), finalized.
Since the filter uses today's addresses, any withdrawal initiated before one of them gained code is included. L1 `WithdrawalProven`
on the four portals with target in the 611-address set: only own-L1CDM targets plus 10 code-less EOAs and 2 forged proofs.
Ink/Soneium/Unichain L2 history not scannable passively (public RPC 1000-block log cap); their proven withdrawals are covered on L1.

**Barrier (future addresses).** The only contracts in any tag v1.0.0..v9.0.0 that trust the portal are ETHLockbox (requires
l2Sender == DEFAULT during a call, ETHLockbox.sol:169) and L1CrossDomainMessenger (requires l2Sender == L2CDM,
L1CrossDomainMessenger.sol:137); neither condition is producible by an attacker-sent withdrawal. Future OPCM deployments come
from the owner Safe with a timestamp-salted CREATE2 (C10/C14).
