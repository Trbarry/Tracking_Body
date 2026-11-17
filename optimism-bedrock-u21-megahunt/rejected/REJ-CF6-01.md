# REJ-CF6-01 — v8/v9 corrupt or invalidate a valid v7 proven withdrawal

**Hypothesis.** A proof record created under v7 is rewritten, orphaned, or interpreted differently
after the v8 Super Root change or v9 withdrawal hardening, preventing finalization.

**Killing fact.** `CarryThroughTest::test_v7_proof_survives_v8_v9_and_finalizes` replays a real v7
proof transaction, then the official v8 and v9 governance transactions against deployed bytecode.
The `(game,timestamp)` record is identical at all three stages, v9 `checkWithdrawal` succeeds,
finalization sets the hash-global finalized bit, and the target receives exactly
`withdrawal.value`. The test passed with no storage injection; `vm.makePersistent` retains only the
protocol-created portal account while each new fork base supplies real pre-upgrade external state.

**Evidence.** Named fork test above; fixture
`mirror/CF6/fixtures/prove-v7-carry.json`; v7 proof write at pinned
`op-contracts/v7.0.0/src/L1/OptimismPortal2.sol:458-469`; v9 consumer at pinned
`op-contracts/v9.0.0/src/L1/OptimismPortal2.sol:671-731`.

**Scope of rejection.** One claim-valid type-8 plain withdrawal on OP Mainnet across v7 -> v8 ->
v9. This does not close older L2OutputOracle proofs, challenger-win games, or future migration.
