Lane 12 fork tests (negative-space / omitted-check analysis).

Run from a copy of the harness template:

    cp -r /home/user/u21-work/template /home/user/u21-work/<dir> && cp Lane12.t.sol /home/user/u21-work/<dir>/test/
    cd /home/user/u21-work/<dir> && forge test --match-path test/Lane12.t.sol -vv -j 2

All tests fork the shared `l1` anvil (Ethereum mainnet @ 26433900) and execute the deployed U21 implementations.
Nothing is broadcast. Withdrawal proofs are injected by writing the single `provenWithdrawals[hash][submitter]`
slot against the chain's real anchor game (see the note at the top of the file); Guardian actions (pause, blacklist)
are pranked and are states production can be in. Expected: 29 passed. Output of the last run:
evidence/lane12/lane12-forge-results.txt.
