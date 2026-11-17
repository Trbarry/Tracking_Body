# ATTACK-CATK-T3-01 — Fake L2 token redirects withdrawal into canonical L1 escrow

Model: Codex, configured by the worker brief as `gpt-daybreak-blue-latest`.

Verdict: **KILLED — exact-pair accounting barrier.**

## Hypothesis

An unprivileged attacker deploys an L2 ERC20 that reports a real L1 token through either `l1Token()` or
`remoteToken()`, advertises the matching ERC165 interface, burns attacker-created units through L2StandardBridge, and
causes L1StandardBridge to release tokens deposited for the canonical L2 representation. Variants tested: legacy-only,
modern-only, and both interfaces with disagreeing getters.

## Exact sequence tried

On the pinned OP fork, deploy each token from an unprivileged test contract; call deployed L2StandardBridge
`bridgeERC20To(fake, USDT, ...)`; then switch to the pinned L1 fork and compare the canonical USDT mapping with each
fake-address mapping. A dual token was also called with the modern getter's conflicting address.

## Barrier

L1 finalization for the real, non-mintable L1 token subtracts
`deposits[_localToken][_remoteToken]` with checked arithmetic before transfer
(`op-v9.0.0/.../StandardBridge.sol:291-293`). The message preserves the fake L2 address, so it addresses
`deposits[USDT][fake] == 0`, never `deposits[USDT][canonicalL2] > 0`. Authentication cannot change either argument.
The conflicting dual-interface call is rejected earlier because legacy identity has deterministic precedence
(`StandardBridge.sol:402-407`).

## Evidence

- PASS: `CATKT3FakeL2ForkTest::test_fakeL2Tokens_allInterfaceShapesRemainPairIsolatedOnL1`.
- `mirror/CATK-T3/evidence/fork-test-result.md`.
- Negative control: the same test confirms the canonical USDT mapping is nonzero.

This changes the known fake-token precondition by exercising every interface shape, but finds no L1-protection bypass.
