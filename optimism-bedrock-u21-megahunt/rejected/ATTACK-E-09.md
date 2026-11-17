# ATTACK-E-09 — sticky authorization of the retired per-chain lockbox after migrate (KILLED: known, self-harm only)

**Hypothesis.** After migrate `oldLockbox.authorizedPortals[portal]` stays true and the retired lockbox is no longer an
unsafe target; combined with the attacker poison set it lets value leave the shared pool.

**Barrier.** A withdrawal can only `lockETH` its OWN value into the retired lockbox; `unlockETH` from inside a
withdrawal reverts `ETHLockbox_NoWithdrawalTransactions` (ETHLockbox.sol:157-178); only the owner sweeps it back.
Executed in PASS A `Lane09PostMigration.t.sol::test_post_target_oldLockbox_lockSucceeds_unlockBlocked` (PRIM-0901) and
acknowledged in the U21 audit Lows ("permanent lockbox portal authorizations"). None of P1..P7 adds an unlock path
(E-01 access diff: no new account or slot).
