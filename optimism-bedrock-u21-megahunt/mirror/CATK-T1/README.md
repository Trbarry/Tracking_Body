# CATK-T1 — fix-regression mirror

Independent Codex mirror of lane T1, executed only against the private pinned L1 fork at block
26,433,900. No transaction was signed or broadcast and no public endpoint was mutated.

## Exact reproduction

The runnable harness is `/home/user/u21-work/codex-CATK-T1/h`. From that directory:

```sh
forge test -j 1 --match-path test/FixRegressionCATKT1.t.sol -vv
```

Expected result: `15 passed; 0 failed; 0 skipped`. The test source preserved here has SHA-256
`235df5bc8f89bf25695797e3bba3fb9181f820b4ec00a218570a29f3c7c80ca7`.

The suite changes state only inside Foundry fork snapshots. The attacker is the unprivileged EOA
`0x00000000000000000000000000000000000A11cE`. It does not use `vm.store` or impersonate a
privileged role. Fixture `f9` is a real countered 90,000 ETH proof, but the test only deletes its
already-invalid proof record in a local fork; no value transfer is attempted.

## Contents

- `test/FixRegressionCATKT1.t.sol`: the 15 deployed-bytecode experiments.
- `test/helpers/U21Fixtures.sol`: copied real-withdrawal helper.
- `evidence/withdrawal-fixtures/f{1,5,9}.json`: copied, immutable production-object inputs.
- `evidence/forge-output.txt`: final passing run.
- `FIX-CONDITION-MAP.md`: condition, v9 dependency, changed precondition, and exact barrier per target.

