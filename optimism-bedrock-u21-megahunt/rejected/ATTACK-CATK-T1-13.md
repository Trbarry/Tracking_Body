# ATTACK-CATK-T1-13 — validator-only bindings

## Hypothesis

An attacker changes `SystemConfig.l2ChainId`/portal or the factory's respected implementation after
validation, causing a game/root from another domain to authorize a withdrawal.

## Original condition and changed precondition

The deployment validator assumes these bindings are correct. In v9, `l2ChainId` and portal are
written by the guarded initializer (`SystemConfig.sol:203-248`), while factory implementations are
owner-only (`DisputeGameFactory.sol:302-325`). Unlike a malformed-selector check, the mutation sends
a fully ABI-valid initializer with a changed chain ID and portal, plus the live setter call.

## Exact sequence and result

For all four chains, assert deployed `l2ChainId`, portal and respected implementation. From the
attacker: (a) call `setImplementation(type,attacker)`; (b) call the complete SystemConfig initializer
with `l2ChainId+1`, attacker portal/config. All eight calls revert. Every binding remains unchanged.

## Barrier and evidence

Reaching either writer needs factory ownership or ProxyAdmin/owner authority. All four production
values are correct at the pin; arbitrary privileged misconfiguration is excluded and the validator
blind spot is known. Test `test_T13_validatorBindingsCannotBeChangedByAttacker` passes at
`mirror/CATK-T1/test/FixRegressionCATKT1.t.sol:546`. Privileged-only/absent-state kill; no candidate.

