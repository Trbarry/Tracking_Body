# CF4 fork-test results

Command (local read-only fork pinned at Ethereum block `26433900`):

```text
cd /home/user/u21-work/codex-CF4/h
forge test -j 1 --match-contract CF4StorageArchaeologyTest -vv
```

Result:

```text
Ran 2 tests for test/CF4StorageArchaeology.t.sol:CF4StorageArchaeologyTest
[PASS] testLegacyMessengerNamespacesRemainDisjointUnderJunk() (gas: 32813)
[PASS] testLegacyPortalProofSlot52IsNonzeroButV9DeleteDoesNotReachIt() (gas: 14959)
Suite result: ok. 2 passed; 0 failed; 0 skipped
```

The test source is `/home/user/u21-work/codex-CF4/h/test/CF4StorageArchaeology.t.sol`.
Both tests use `vm.store` only on the ephemeral fork selected by `vm.createSelectFork("l1")`;
no transaction is sent to any RPC endpoint.
