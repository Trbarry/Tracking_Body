#!/bin/bash
cd /home/user/u21-work/lane-11
ulimit -v 6000000
while [ ! -f data/gb.done ]; do sleep 10; done
for s in 3 1 2; do
  tag=-S$s; [ $s = 3 ] && tag=-P
  for try in 1 2 3; do
    U21_SET=$s U21_TAG=$tag U21_DENSE=200 U21_FORK=l1pre forge test -j 1 --match-path test/InjectedGas.t.sol --match-test test_injected -vv > data/inj-l1pre-S$s.log 2>&1
    grep -q "Suite result: ok\|cases with FINALIZED" data/inj-l1pre-S$s.log && break; sleep 15
  done
done
echo done > data/inj-l1pre.done
rm -f evidence/invariant-coverage.txt
FOUNDRY_INVARIANT_RUNS=24 FOUNDRY_INVARIANT_DEPTH=40 FOUNDRY_INVARIANT_FAIL_ON_REVERT=false forge test -j 1 --match-path test/PortalInvariants.t.sol -vv > data/invariants.log 2>&1
echo done > data/invariants.done
for fk in l1 l1pre; do
  FOUNDRY_FUZZ_RUNS=256 U21_FORK=$fk forge test -j 1 --match-path test/GasBoundary.t.sol --match-test testFuzz -vv > data/gbfuzz-$fk.log 2>&1
  FOUNDRY_FUZZ_RUNS=256 U21_FORK=$fk forge test -j 1 --match-path test/InjectedGas.t.sol --match-test testFuzz -vv > data/injfuzz-$fk.log 2>&1
done
echo done > data/queue.done
