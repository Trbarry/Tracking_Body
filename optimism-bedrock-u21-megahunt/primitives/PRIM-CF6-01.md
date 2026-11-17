# PRIM-CF6-01 — v7 proven-withdrawal record survives v8 and v9 unchanged

- **Earliest semantic ancestor:** `op-contracts/v7.0.0`; real proof tx
  `0x2a1b15e0ed21bc5d50cd75dd749740173c23e2d29171fdc4b79f942b785d0d1c`, L1 block 25797546.
- **Current consumer:** `op-contracts/v9.0.0` `OptimismPortal2.checkWithdrawal` and
  `finalizeWithdrawalTransactionExternalProof`.
- **Releases crossed:** v7 -> v8 -> v9.
- **Chains affected:** OP Mainnet demonstrated; other chains not tested for this object.
- **Source contracts + functions:** v7 `src/L1/OptimismPortal2.sol:368-469`
  (`proveWithdrawalTransaction` and record write); v9 `src/L1/OptimismPortal2.sol:577-731`
  (`finalizeWithdrawalTransactionExternalProof`, `checkWithdrawal`). Pinned commits:
  v7 `a7c88c8d636ceb9944ea0edaf7d033da258778ab`, v9
  `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`.
- **Persistent object or state:** `provenWithdrawals[withdrawalHash][proofSubmitter] =
  (disputeGameProxy, proofTimestamp)` and `finalizedWithdrawals[withdrawalHash]`.
- **Trigger:** replay the real v7 prove calldata through the public portal function, carry the
  portal account through the official v8 and v9 upgrade calls, then finalize through the public
  external-proof entry point.
- **Attacker-controlled inputs:** permissionless proof submitter and finalization caller. The
  withdrawal, trie proof, output-root proof, and dispute game are real historical inputs.
- **Required pre-state:** the fixture's type-8 game exists and later reaches
  `DEFENDER_WINS`/claim-valid state; lockbox is funded.
- **State mutation:** proof record written under v7; exact timestamp retained under v8/v9;
  v9 finalization sets `finalizedWithdrawals[hash] = true`.
- **External calls:** portal -> ETHLockbox unlock; portal -> plain withdrawal target.
- **Identity dependencies:** withdrawal hash, proof submitter, dispute game address, ASR validity,
  portal proxy identity, and unchanged lockbox identity.
- **Broken or weakened assumption:** none observed. This is a positive preservation primitive for
  later compositions.
- **Candidate compositions:** legacy proof + ASR retirement changes; proof + lockbox migration;
  proof-submitter identity + future proof deletion.
- **Current production evidence:** fixture event hash
  `0x612a0958aec8a039471bea6ddb916b6cf72caea5226574f0ae7857675ba3ad08`;
  `CarryThroughTest::test_v7_proof_survives_v8_v9_and_finalizes` passes against deployed bytecode.
- **Reason it may be benign:** observed behavior is exactly the intended carry-forward invariant.
- **Exact falsification experiment:** rerun the named test; it asserts the v7 timestamp is bit-equal
  after each official replay, v9 `checkWithdrawal` succeeds, finalization flips the hash-global bit,
  and target balance delta equals `withdrawal.value`.
- **Confidence:** high.
- **Audit coverage:**
- **Nearest known finding:**
