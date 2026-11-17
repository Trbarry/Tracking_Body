# ATTACK-CATK-F-05 — sibling portal composition / alias privilege

**Hypothesis.** Withdrawing into another chain's portal composes withdrawal and deposit semantics to
duplicate ETH or give the source portal a privileged L2 alias on the destination.

**Experiment.** On the pinned L1 fork, finalize 1 ETH OP withdrawals into each of Ink, Soneium, and
Unichain portals using `depositTransaction`. Passively inspect all 16 source-portal/destination-L2
aliases for code, balance, and privileged identity matches.

**Observed.** Each composition reduces OP lockbox custody by exactly 1 ETH and increases the sibling
lockbox by exactly 1 ETH. All 16 aliases have zero code, zero balance, and match none of the checked
ProxyAdmin owner, L1Block proxyAdminOwner, depositor, or ProxyAdmin identities.

**Barrier.** The call is an ordinary cross-chain transfer funded by the withdrawing user. Aliasing is
deterministic but confers no listed role.

**Decision.** Rejected. Candidate score: **0/10**. Evidence: `portal-alias-census.json` and
`test_siblingPortalCompositionOnlyMovesEqualCustody`.

