# CATK-C deployed-fork harness

This is the independent CATK-C mirror harness for the OP Stack L2-to-L1 gas-cap lane. It calls the deployed proxy bytecode on the pinned local forks. It never broadcasts a transaction.

Harness source executed:

`/home/user/u21-work/codex-CATK-C/h/test/GasCapCATKC.t.sol`

Mirror SHA-256:

`43f7dec0039cb90191ba636e9fe2790f81d995937b9e05273fa18064ff5eabd5`

Exact final commands:

```bash
cd /home/user/u21-work/codex-CATK-C/h
forge fmt --check test/GasCapCATKC.t.sol
forge test -j 1 --match-path test/GasCapCATKC.t.sol -vv
```

The harness expects the template aliases `l1 = http://127.0.0.1:8545` and `l2 = http://127.0.0.1:9545`. It writes only ephemeral Forge fork state.

State fabrication is deliberately narrow and disclosed in the test:

- `provenWithdrawals` is populated with `vm.store` solely to reach deployed `OptimismPortal2` finalization gas behavior without constructing an MPT proof.
- Isolated direct-replay edge probes populate `failedMessages` with `vm.store` as a measurement vehicle.
- The decisive forced-failure test does **not** fabricate `failedMessages`: the first capped portal transaction creates it, and the immediately following capped direct replay consumes that real state.

