# ATTACK-E-04 — advancing the live per-chain ASR anchor before migrate changes the re-initialised legacy ASR or the shared anchor (KILLED)

**Hypothesis.** `setAnchorState` on the live OP/Unichain ASR (permissionless) before migrate makes the legacy-ASR
re-initialisation revert (`AnchorStateRegistry_InvalidAnchorGame`) or carry a poisoned root into the shared domain.

**Sequence executed.** `test/poc/attack-wave/E/test/ATKE_Poison.t.sol::test_E01` P3 scanned the last 150 games of each factory: no claim-valid type-9 game newer
than the anchor exists at 26433900 (anchor already latest). The anchor that IS carried is compared: old OP/UNI ASR
anchorGame after poisoned migrate == pre-migrate value (asserted), and shared anchor root/seq identical to clean.

**Barrier.** Migrator re-initialises the legacy ASR with `oldASR.getStartingAnchorRoot()` (OPContractsManagerMigrator.sol:547-555, arg at :553)
so `rootChanged == false` and the anchor check is skipped (/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/dispute/AnchorStateRegistry.sol:113-121). The shared
ASR is fresh (anchorGame 0), starting root from input. The anchor can only advance via a claim-valid game, all of
which have header-derived roots (F5). Same barrier for the later standard `upgrade()`: it loads the existing starting
root unless governance overrides it (OPContractsManagerV2.sol:654-658); a governance override behind an honestly advanced
anchor is a self-inflicted, retryable revert (no eligible impact).

**Evidence.** forge-E01.txt, E01-poison-vs-clean.txt.
