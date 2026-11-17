# CATK-T3 fork reproducer

Run:

```bash
cd /home/user/Tracking_Body/optimism-bedrock-u21-megahunt/mirror/CATK-T3/poc
forge test -j 1 --match-path test/CATK_T3.t.sol -vv
```

Expected: 3 suites, 11 tests passed, 0 failed.

Forks are the local read-only pins declared in `foundry.toml`: L1 post-U21 block 26,433,900, L1 pre-U21 block
26,430,858, and OP block 159,654,093. The two in-flight tests use real OP withdrawals and real
`L2ToL1MessagePasser` storage proofs against real game 21,377; proof submission, honest game resolution, clock warps,
and finalization happen only in the local fork from unprivileged addresses.
