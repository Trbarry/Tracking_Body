# ATTACK-T1-13 — Bindings that exist only in the validator (game registry == portal registry; SystemConfig.l2ChainId)

Lane ATK-T1, Opus 5.5. Target 13 (rows 21/22). Kill type: failing experiment, four chains.

**Condition.** U20 3.1.6 / 3.1.3: ANCHORP-70 and SYSCON-140 are off-chain validator checks only. The portal consumes
`systemConfig.l2ChainId()` to select the per-chain root of a super game (`OptimismPortal2.sol:442`) and trusts the registry of the
game only through the factory UUID.

**Executed** (`T1_Registry.t.sol::test_T1_01_…`, L1 @ 26433900): `SystemConfig.l2ChainId()` == 10 / 57073 / 1868 / 130;
portal.DGF == ASR.DGF == SystemConfig.DGF; every live `gameArgs` names the portal's ASR only; an attacker type-9 game's
`rootClaimByChainId` returns the attacker's entry only for the portal's own chain id and reverts for the three sibling ids;
cross-registry `isGameRegistered` is diagonal.

**Barrier.** The state the validator would check is correct on every chain today; changing either binding needs a ProxyAdmin/owner
write (privileged, -5) — the validator gap only matters for "any state not produced by the standard OPCM flow", which no live chain
has. Known: U20 3.1.3, 3.1.6; U21 3.1.18 (Part 2 #7). Output: `evidence/attack-wave/T1/T1_Registry.out.txt`.
