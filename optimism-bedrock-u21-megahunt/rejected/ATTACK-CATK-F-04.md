# ATTACK-CATK-F-04 — registry, WETH, factory, and admin mutation

**Hypothesis.** Portal-framed calls to old/current ASRs, DelayedWETHs, factories, SystemConfigs,
ProxyAdmins, or AddressManagers inherit an authority role or expose pre-existing portal-owned assets.

**Experiment.** Pinned-fork calls to six ASRs, 13 DelayedWETH objects, four dispute factories, four
SystemConfigs, four ProxyAdmins, and four AddressManagers. Separately scan 52 portal/WETH balances,
all live allowances, and portal-related Approval/Transfer events.

**Observed.** ASRs reject the portal as guardian. Factories/configs/admins/managers reject it as owner.
Every portal/WETH balance and allowance is zero and no portal-related token event exists. A payable
withdrawal can mint WETH to the portal, followed by a transfer to the attacker, but the recovered 1
ETH is exactly the attacker's withdrawal value.

**Barrier.** Guardian/owner/proxyAdminOwner checks never recognize a portal. No pre-existing
portal-owned token object exists; the only reachable WETH object is self-funded.

**Decision.** Rejected. Candidate score: **0/10**. Evidence:
`delayed-weth-portal-census.json` and fork tests `test_allASRGenerationsRejectPortalAsGuardian`,
`test_adminTargetsDoNotTreatPortalAsOwner`, and `test_delayedWETHRoundTripCanOnlyRecoverSelfFundedValue`.

