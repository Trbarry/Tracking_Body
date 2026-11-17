# ATTACK-CATK-F-02 — current or retired lockbox drain

**Hypothesis.** A withdrawal can target a lockbox omitted from the portal's two-address unsafe-target
set and exploit the lockbox's trust in `msg.sender == portal`.

**Experiment.** Fork calls to the current lockbox, all three sibling lockboxes, and a vehicle that
changes only the local portal lockbox pointer so the deployed OP lockbox models a retired lockbox.
Read the complete 4×4 live authorization matrix.

**Observed.** Current OP lockbox is hard-blocked. Authorization is strictly diagonal, so sibling
lockboxes reject the OP portal and the portal relocks failed value. In the retired model, `lockETH`
accepts the still-authorized OP portal, but this only adds the withdrawal's own ETH. `unlockETH`
reverts because `portal.l2Sender()` is not the default sentinel while a withdrawal executes.

**Barrier.** `ETHLockbox.sol:168-170` explicitly forbids unlocks during withdrawal execution. The only
successful retired-lockbox transition is self-donation.

**Decision.** Rejected. Candidate score: **0/10**. Evidence: fork tests
`test_currentPortalAndCurrentLockboxAreHardBlocked`,
`test_siblingLockboxRejectsOPPortalAndValueIsRelocked`, and
`test_futureRetiredLockboxAcceptsLockButCannotBeUnlockedInWithdrawal`.

