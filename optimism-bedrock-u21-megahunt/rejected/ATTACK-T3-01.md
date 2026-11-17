# ATTACK-T3-01 — Attacker-deployed L2 token (any interface answers) releases a real L1 token's escrow

Lane ATK-T3 (bridge token identity / L1ERC721Bridge / OptimismMintableERC20Factory), Opus 5.5 (CLAUDE.md exception, Mythos 5.2 quota until 2026-11-22). Sources: op-contracts v9.0.0 (`/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src`). PoC: `test/poc/attack-wave/T3/test/T3.t.sol`; run output `evidence/attack-wave/T3/forge-final.txt` (9/9 PASS). Kill type: failing experiment on deployed bytecode (L2 OP 159,654,093 + L1 26,433,900).

**Hypothesis.** The L2StandardBridge trusts the L2 token's own ERC165 / `l1Token()` / `remoteToken()` answers and its
`burn`/`transferFrom` (known: "fake ERC-20 withdrawal ... blocked by a check in L1StandardBridge", SCOPE 1.10). An L2 token
that answers differently per interface (legacy vs new), only the new interface, or no ERC165 at all (escrow path with a fake
`transferFrom`), or the legacy `withdrawTo` entry, could make L1 release an honest pair's escrow.

**Sequence executed** (`test_B1_fakeL2Tokens_cannotReleaseHonestEscrow`):
1. L1: honest user escrows 1000 X with its legitimate L2 factory token HL2 (`deposits[X][HL2] = 1000e18`).
2. L2 (deployed L2SB 1.13.2): attacker deploys FakeMintable (both ifaces, l1Token = remoteToken = X, no-op burn), FakeSplit
   (l1Token = X, remoteToken = **HL2**), FakeNewOnly (0xec4fc8e3 only), FakeEscrow (no ERC165, transferFrom returns true), and uses
   `bridgeERC20To` x4 + legacy `withdrawTo`. Each emits a real `MessagePassed` with `finalizeBridgeERC20(X, <fake>, …)`:
   the L2 address in the message is always the token the L2 bridge acted on (asserted), never HL2.
   Negative control: `bridgeERC20To(HL2, X, …)` by the attacker reverts (burn of a balance he does not hold).
3. L1: each withdrawal is finalized through the real portal -> L1CDM 2.13.0 -> L1SB 2.8.2 (impl 0xB37a11…).

**Result.** 5/5 portal-finalized, 5/5 `failedMessages`, 5/5 replays by the attacker fail again; attacker X balance 0; escrow
1000e18 and `deposits[X][HL2]` unchanged. Trace (`evidence/attack-wave/T3/trace-test_B1.txt`): `finalizeBridgeERC20` ->
`panic: arithmetic underflow or overflow (0x11)`.

**Barrier.** `src/universal/StandardBridge.sol:292` — `deposits[_localToken][_remoteToken] - _amount` (checked arithmetic) keyed
by the exact (L1 token, L2 token) pair; the L2 key is the address the L2 bridge burned/escrowed (`StandardBridge.sol:369-384`,
L2 `L2StandardBridge.sol:166` for `withdraw*`). Interface answers only decide the L2-side path, never the L1 key.
Positive control `test_B2`: a self-funded fake pair withdraws exactly its own deposit and one unit more fails — the barrier is exact.
Score: permissionless +2, but no eligible impact (-3), known class (-4). KILLED.
