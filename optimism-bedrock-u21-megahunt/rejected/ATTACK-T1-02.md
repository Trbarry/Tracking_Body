# ATTACK-T1-02 — Blacklist check removed from getAnchorRoot: a blacklisted / retired / de-respected anchor seeds new games

Lane ATK-T1, Opus 5.5. Target 2 (row 2). Kill type: failing experiment + privileged precondition + known issue.

**Original safety condition.** U13 5.1.2 fix removed the blacklist test from `getAnchorRoot` (v9 `AnchorStateRegistry.sol:205-213`)
"under the assumption that invalid games are invalidated before they are finalized". New games copy the anchor without
re-validation (`SuperFaultDisputeGame.sol` initialize: `getAnchorRoot()` -> `startingProposal`).

**Sequence executed.**
- `T1_Registry.t.sol::test_T1_02_anchorGamesClean` (L1 @ 26433900): for OP/Ink/Soneium/Unichain the live anchor game
  (0x55A5…6f95, 0x3892…8945, 0x5dFB…C454, 0x944a…AfD5) is claim-valid, not blacklisted, not retired, of the respected type
  (9/9/5/9), bound to its own registry, DEFENDER_WINS, and `getAnchorRoot()` equals its root/sequence.
- Guardian-event scan of the four current ASRs, blocks 22,980,000..26,433,900 (`evidence/attack-wave/T1/asr-guardian-events.json`):
  0 `DisputeGameBlacklisted`, 0 `RetirementTimestampSet`, 0 `RespectedGameTypeSet`. F5 census: blacklisted games = [] on all four.

**Barrier.** The mutation needs (i) an invalid game to become claim-valid (an incorrectly resolved game = fault-proof failure,
not this lane's root cause) and then (ii) a guardian invalidation after it became the anchor (privileged). Neither exists today on
any chain. The residual behaviour (anchor may be a blacklisted/retired game; `getAnchorRoot` ignores the blacklist) is acknowledged:
KNOWN-FINDINGS Part 2 #5 (U13 5.1.2; CC25 3.2.1, 3.2.18; U21 3.2.11) -> -4. Score <= 0.
