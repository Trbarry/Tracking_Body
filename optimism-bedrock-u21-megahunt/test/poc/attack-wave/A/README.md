# ATK-A — old-prestate soundness (kona-client v1.7.0 vs v1.9.0)

Model: Opus 5.5 (user-approved exception, Mythos 5.2 quota exhausted until 2026-11-22). Result: no candidate;
kills ATTACK-A-01..05. All commands are read-only or run on local forks.

1. Fork test (production facts, L1 pinned at 26435056):
   `cd test/poc/attack-wave/A/forge && forge test -j 1 -vv` -> 2 pass (`evidence/attack-wave/A/forge-OldPrestateLive.txt`).
   `lib` is a symlink to `/home/user/u21-work/template/lib`.
2. Census of old-prestate games:
   `python3 -I test/poc/attack-wave/A/census_old_prestate.py http://127.0.0.1:7545 0x1935ef0` -> `census-26435056.txt`.
3. EVM differential (ATTACK-A-03):
   ```
   S=<scratch>; cd /home/user/ethereum-optimism/optimism
   for t in v1.7.0 v1.9.0; do mkdir -p $S/src-$t && git archive kona-client/$t rust/ | tar -x -C $S/src-$t; done
   # edit revm-diff/v1.x.0/Cargo.toml op-revm path to $S/src-v1.x.0/rust/op-revm ; Cargo.lock = that tag's rust/Cargo.lock
   (cd revm-diff/v1.7.0 && CARGO_TARGET_DIR=$S/t7 cargo build --release -j 2)
   (cd revm-diff/v1.9.0 && CARGO_TARGET_DIR=$S/t9 cargo build --release -j 2)
   for s in $(seq 1 10); do MIRROR_TRANSACT_RAW=1 $S/t7/release/revm-diff 20000 $s > o; MIRROR_TRANSACT_RAW=1 $S/t9/release/revm-diff 20000 $s > n; diff o n | grep -c '^<'; done   # 0 each
   $S/t7/release/revm-diff 3000 1 > o; $S/t9/release/revm-diff 3000 1 > n; diff o n   # negative control: 3 deposit>2^24 cases
   ```
4. Batch-type decoding (ATTACK-A-01), needs `pip install brotli`:
   `python -I test/poc/attack-wave/A/batch_types.py http://127.0.0.1:7545 https://ethereum-beacon-api.publicnode.com 26429059 26430859`
