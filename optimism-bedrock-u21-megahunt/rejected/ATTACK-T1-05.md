# ATTACK-T1-05 — Pause identifier follows a mutable pointer: a value path resolves pause through a different chain

Lane ATK-T1, Opus 5.5. Target 5 (row 6). Kill type: failing experiment (four chains) + privileged writers.

**Original safety condition.** Spearbit 2025-05 5.1.3 fix guarded one writer (`migrateToSuperRoots`, now `migrateToSharedDisputeGame`
`OptimismPortal2.sol:537`). Other writers of the pause identifier: portal `initialize` (:273-302, ProxyAdmin-gated), ASR/DelayedWETH
`initialize` (gated), `SystemConfig.optimismPortal` (gated). v9 consumers: portal `paused()` :306 (= `ethLockbox.paused()`), ASR
:136, SystemConfig :574 (`optimismPortal().ethLockbox().paused()`), L1CDM/L1SB/L1ERC721 (`systemConfig.paused()`), DelayedWETH v2
(`ethLockbox.paused()`), games via their registry.

**Sequence executed** (`T1_Portal.t.sol::test_T1_04_pausePointerGraph`, L1 @ 26433900, OP/Ink/Soneium/Unichain): portal.ethLockbox ==
ASR.ethLockbox == SystemConfig(portal).optimismPortal().ethLockbox() == DelayedWETH(SystemConfig.delayedWETH()).ethLockbox();
L1CDM, L1StandardBridge, L1ERC721Bridge all point at the same SystemConfig; the type-9 anchor game's WETH is that DelayedWETH;
one SuperchainConfig; `pauseTimestamps(address(0))`, `(lockbox)`, `(retired portal identifier)` all 0.

**Barrier.** Every value-exit consumer on every chain resolves to the same identifier, and every writer of a pointer in the chain is
ProxyAdmin/owner-gated (T1-06 shows every `initialize` refuses an unprivileged caller). Divergence needs a privileged write (-5);
pauses under the retired portal identifier are KNOWN (U21 3.1.2, 3.2.14). Legacy DelayedWETH generations hold bonds only
(ATTACK-T1-15). Score <= 0.
