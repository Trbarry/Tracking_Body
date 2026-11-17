# ATTACK-B-06 — Upgrade/migration between forced failure and replay strands the parked value
**Hypothesis.** The planned OPCMv2.migrate (OP+Unichain shared lockbox) sweeps/strands ETH parked in the L1CDM or
makes pending failed messages unreplayable (re-init, pause pointer, portal swap).
**Sequence.** test_E5: f1 (ETH) and f7 (CRV) forced-failed, then migrate executed as the Safe (allowed setup), then
unrelated-EOA replays.
**Barrier.** migrate does not touch L1CDM balance or failed/successful mappings; L1CDM.paused() (systemConfig) false
after migrate; both replays deliver exactly; L1CDM ends at 0. Pause in between only reverts the replay at :222
(retryable). Bytecode scan of every real target (LIVE-OBJECTS-B §C): none depends on portal.l2Sender().
**Evidence.** test/poc/attack-wave/B/ATKB.t.sol::test_E5_forcedFail_then_migrate_then_replay PASS, evidence/attack-wave/B/forge-ATKB-output.txt.
