# ATTACK-E-03 — donations / forced ETH / deposits before migrate break pooled solvency or migrate (KILLED)

**Hypothesis.** ETH pushed by an attacker into portals (donateETH), per-chain lockboxes (SELFDESTRUCT), L1CDMs,
L1StandardBridges, registries and every DelayedWETH generation, plus deposits, makes migrate revert, mis-account the
shared lockbox, or leaves value the validator/monitoring miss.

**Sequence executed.** `test/poc/attack-wave/E/test/ATKE_Poison.t.sol::test_E01` P4-P6: 1 ETH donateETH on each portal, 1 ETH forced into each lockbox, L1CDM,
L1SB, 1 wei into OP ASR and OP gen2, 1 ETH deposit per portal, 0.01 ETH deposit + self-unlock on 11 legacy + 2 current
DelayedWETH proxies; then migrate.

**Barrier.** Shared lockbox poisoned == clean + 6 ETH exactly (2 donations + 2 forced + 2 deposits); portals and old
lockboxes end at 0 (asserted). Migrator sweeps `portal.migrateLiquidity()` and `oldLockbox.migrateLiquidity(new)`
(OPContractsManagerMigrator.sol:524, 529-534) by `address(this).balance` (OptimismPortal2.sol:509-510) — surplus
only. L1CDM/L1SB/registry/WETH balances are never read by migrate (access diff: the only differing read is portal
ResourceMetering slot 1, changed by the deposits; writes identical). Gas 3,248,329 clean vs 3,241,632 poisoned.

**Evidence.** forge-E01.txt, E01-poison-vs-clean.txt, E01-access-diff.txt. PASS A test_preMigration_donations_are_swept agrees.
