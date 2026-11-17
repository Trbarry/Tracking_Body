# Lane 26 — verification log

Harness: `/home/user/u21-work/codex-26/h`; RPC `l1n=http://127.0.0.1:8547`. No transaction was broadcast. `vm.prank`, `vm.store`, `vm.warp`, feature writes, pauses, and deposits existed only inside disposable in-process forks.

## Final runs

Final aggregate run: **11 passed, 0 failed** (10 lane tests plus the template sanity test).

* `forge test --match-path test/FeatureStateMachine.t.sol -vv`: **4 passed, 0 failed**.
  * rejects attacker and SystemConfig-owner feature writes;
  * proves ETH_LOCKBOX and INTEROP one-way;
  * proves CGT and unknown flags reversible by PA owner, including runtime Portal effect with production lockbox liquidity;
  * proves 21m/500m gas-limit bounds.
* `forge test --match-path test/PauseMatrix.t.sol -vv`: **5 passed, 0 failed**.
  * four-chain resolver fan-out;
  * old Portal identifier inert after U21;
  * expiry/extend/unpause semantics;
  * synthetic CGT still uses lockbox pause ID;
  * real-contract value-path matrix, including closed legacy game bookkeeping nuance.
* `forge test --match-path test/StorageDiff.t.sol -vv`: **1 passed, 0 failed**.
  * independent N-1/N relevant proxy storage and implementation diff.

A separate high-volume N-to-26,433,900 raw-slot sweep was abandoned after the shared archival backend returned HTTP 429 after dozens of matching reads; no assertion mismatch occurred. Lower-volume passive getters for every field reported in `ONCHAIN_SYSTEMCONFIG_STATE.md` matched. This infrastructure failure is not counted as a protocol test failure.

## Fork-test fidelity limits

The pause/value tests call deployed proxies and bytecode. Only the legitimate bridge relay context was primed with `vm.store` to reach bridge pause guards; no outcome relies on a mocked contract. The CGT test is explicitly a PA-owner-forced state on OP, because none of the four governed chains is a CGT chain. No exact future OP+Unichain shared-lockbox migration calldata existed at the research block, so migration conclusions are source/state-machine results rather than claims from a production migration fork.
