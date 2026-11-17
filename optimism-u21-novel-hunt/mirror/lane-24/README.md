# Lane 24 artifact index

- `tests/WithdrawalFinalization24.t.sol` — 17-case deployed-code fork suite.
- `FORK_TEST_RESULTS.md` — outcomes and mocking/storage-overlay boundary.
- `REAL_WITHDRAWAL_EVIDENCE.md` — decoded real proof, two real failed-message histories, and historical false-finalization scan.
- `CHAIN_STATE_READS.md` — N-1/N/later configuration reads.
- `U21_PROXY_IMPLEMENTATION_MAP.md` — lane-local implementation map.
- `SOURCE_DIFF_NOTES.md` — v7/v8/v9 semantic and storage-layout diff.
- `artifacts/evidence-index.json` — machine-readable evidence index.

The working harness is `/home/user/u21-work/codex-24/h`. Its `foundry.toml` adds `l1n` and the lane-private `lane24` endpoint. The executed command was:

```sh
forge test --match-path test/WithdrawalFinalization24.t.sol -vv -j 1
```

The test's arbitrary-withdrawal cases install only proof-record storage. The real historical cases require no synthetic proof slot. See `FORK_TEST_RESULTS.md` before treating any mocked/overlaid condition as production evidence.
