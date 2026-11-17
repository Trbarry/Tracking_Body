# CATK-CMP1 local-fork harness

The test suite uses only the local aliases from the engagement template. It never broadcasts a
transaction. Copy `Base.sol`, `CATK_CMP1.t.sol`, `proves.json`, and
`active-zero-value-replays.json` into the template harness (`proves.json` and the replay JSON belong
at the harness root), then run:

```sh
forge test -j 1 -vv
```

`vm.prank` of the Optimism guardian and EtherFi operations multisig occurs only in negative tests
that model legitimate pause/blacklist actions. Every finalization and replay actor is the
unprivileged `0x...ca7c01`. The sibling portal prank in C09 proves an exact-address rejection and is
not an exploit precondition. `vm.etch` is limited to the carrier withdrawal's real EOA recipient to
create the already-established messenger reentrancy failure; the victim withdrawal, proof, game,
target, value, and application state are deployed objects.
