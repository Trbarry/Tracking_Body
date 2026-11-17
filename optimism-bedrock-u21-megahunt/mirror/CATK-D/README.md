# CATK-D trojan super-root reproduction

Outcome: the primitive is real on deployed OP Mainnet bytecode, but it is not an Immunefi candidate. A noncanonical type-9 game can expose a genuine chain-10 output root and accept a real withdrawal proof while `IN_PROGRESS`. The resulting proof is submitter-local and immediately replaceable by that same submitter with an honest-game proof. The full-root behavior is also explicitly known (CC25 3.1.6/3.1.7).

Exact command executed:

```bash
cd /home/user/u21-work/codex-CATK-D/h
forge test -j 1 --match-path test/TrojanSuperRoot.t.sol -vvv
```

Result: 8 passed, 0 failed, 0 skipped.

The runnable harness is `/home/user/u21-work/codex-CATK-D/h`. This mirror preserves the test, fixture loader, the two required mainnet fixtures, and the timestamp-aligned OP state proof. The harness was created from `/home/user/u21-work/template`; its `foundry.toml` uses `evm_version = "osaka"` and the passive pinned endpoints supplied by the engagement.

Tests:

- `test_createTrojanAndProveRealWithdrawal_deployedBytecode`
- `test_toolingCompatibleRecentRoot_provesPersistentRealWithdrawal`
- `test_attackerProofCannotOverwriteExistingSubmitterProof`
- `test_sameSubmitterCanImmediatelyReplaceTrojanProofWithHonestGame`
- `test_harnessStatusFlip_deleteAndReproveAgainstHonestGame`
- `test_liveChallengerWinsProofIsPermissionlesslyDeletable`
- `test_liveChallengerWinsRootBondIsCreditedToCounterer`
- `test_futureSharedShape_unsortedExtraChainAndDuplicateOpStillProves`

Important limitation: the lifecycle test labels its sole `vm.store` explicitly. It models the expected `CHALLENGER_WINS` status for the newly created malformed game; it does not claim to run Cannon/Kona. Separate tests use real game 21288, which actually resolved `CHALLENGER_WINS`, to prove deletion and root-bond payment behavior on deployed state.

Artifact SHA-256:

```text
a33e8484fcc5812190a2b28246c5dcb0ad441164569440f73f29fa8f2109dbfe  TrojanSuperRoot.t.sol
f6f69d750f7f2a6da34ff1f43c646789e0771363993034a71eab40068ac2ead0  U21Fixtures.sol
d2126df049a9df7aedb5d11a59e79816e5e0556d859e15230b7a71118c196894  latest-withdrawal-proof.json
f7a42fab59cdb3442a925b219e2ab455b209a28f4f3ec228f6a72140f306b569  f1.json
6118ff6e4a9779e18d4e53c0e2cf5742c49402ea000419ce56f6d5229f40ffe8  f9.json
```

