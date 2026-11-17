# Fork-test result

Command:

```bash
cd /home/user/u21-work/codex-CATK-D/h
forge test -j 1 --match-path test/TrojanSuperRoot.t.sol -vvv
```

Output:

```text
Ran 8 tests for test/TrojanSuperRoot.t.sol:TrojanSuperRootTest
[PASS] test_attackerProofCannotOverwriteExistingSubmitterProof()
[PASS] test_createTrojanAndProveRealWithdrawal_deployedBytecode()
[PASS] test_futureSharedShape_unsortedExtraChainAndDuplicateOpStillProves()
[PASS] test_harnessStatusFlip_deleteAndReproveAgainstHonestGame()
[PASS] test_liveChallengerWinsProofIsPermissionlesslyDeletable()
[PASS] test_liveChallengerWinsRootBondIsCreditedToCounterer()
[PASS] test_sameSubmitterCanImmediatelyReplaceTrojanProofWithHonestGame()
[PASS] test_toolingCompatibleRecentRoot_provesPersistentRealWithdrawal()
Suite result: ok. 8 passed; 0 failed; 0 skipped
```

The test uses the deployed factory, portal, ASR, and type-9 implementation at the L1 pin. It creates games only in fork-local state with an unprivileged funded test address. `f1.json` and `f9.json` are captured mainnet proofs. The recent output proof was obtained by passive `eth_getProof` from the pinned OP endpoint.

Negative controls/barriers proven by tests:

1. The attacker gets only `provenWithdrawals[hash][attacker]`; an existing victim/relayer slot is byte-for-byte unchanged.
2. The legitimate submitter can overwrite its own trojan-bound slot with an honest game immediately, even while the trojan remains `IN_PROGRESS`.
3. Once a game really is `CHALLENGER_WINS`, any caller can delete its proof.
4. A real losing game credits the root counterer, not the malicious creator, with at least the 0.08 ETH root bond.

The one harness-only status mutation is isolated and plainly labelled in source. No result claims that this minimal suite executed the Kona proof program.
