Lane 05 PoCs (fork tests against the real deployed post-U21 OP Mainnet contracts, `l1` anvil @ 26433900).

Run: `cp -r /home/user/u21-work/template /tmp/x && cp *.sol /tmp/x/test/ && cp *.json /tmp/x/ && cd /tmp/x && forge test -vv`
(working copy: `/home/user/u21-work/lane05`). Output of the last run: `evidence/lane05-forge-test-output.txt`.

- `Lifecycle.t.sol`   `DeletePredicateTest.test_predicate_matrix` - boundary matrix of `deleteProvenWithdrawal`.
- `CrossVersion.t.sol` - real v8-era proof (mainnet tx 0x1214545b...) finalizes under v9; shadow proofs; re-prove/duplicates; array growth.
- `Migration.t.sol`   - simulated future registry swap (ProxyAdminOwner pranks = documented governance action); proofs do not survive.
- `Trojan.t.sol`      - PRIM-0503: invalid super-root game embedding the correct chain-10 output root accepts an unmodified honest proof.
- `Survey.t.sol`      - 44 real proofs (41 v8-era, 3 v9-era): none deletable.
- `proofs.json`, `provetxs.json` - real WithdrawalProvenExtension1 logs / prove calldata (blocks 26424100..26433900).
