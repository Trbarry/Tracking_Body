# Lane 04 PoC harness (withdrawal finalization and replay)

Copy of `/home/user/u21-work/lane-04` (forge-std only, fork tests against deployed bytecode).
Run from that directory: `forge test -vv` (37 tests) or `forge test --isolate -vv` (every top-level call is its
own transaction, i.e. cold access lists - use this for gas thresholds).

- `proves.json` - 43 real `proveWithdrawalTransaction` calldata blobs (L1 blocks 26425493..26433490) taken from
  `WithdrawalProven` logs of the OP Mainnet portal; the struct, game index, output-root proof and trie proof are
  decoded from the calldata, so every "real" test re-uses genuine provable material.
- `u21input.hex` - calldata of the real U21 transaction; `CrossVersion.t.sol` re-executes it on the `l1pre` fork
  (prank of the real sender EOA into the real Safe) to move state created under v8 across the upgrade.
- "FABRICATED" tests write `provenWithdrawals[hash][submitter]` with `vm.store` (slot 57) against a real,
  honestly resolved game. They characterise branch conditions only; they are not reachability proofs.
- `vm.etch` substitutions of target behaviour are flagged in the test comments.
