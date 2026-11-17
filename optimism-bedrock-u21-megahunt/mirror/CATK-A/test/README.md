# CATK-A test commands

Harness location: `/home/user/u21-work/codex-CATK-A/h`.

```bash
cd /home/user/u21-work/codex-CATK-A/h
forge test -j 1 --match-contract CATKAOldPrestateForkTest -vvv
```

Expected: 2 passed, 0 failed. The configured `l1pre` and `l1` endpoints are read-only pinned forks;
the test performs no broadcast.

The exact-tag Kona regression was run from a temporary v1.9.0 worktree:

```bash
RUSTUP_TOOLCHAIN=stable \
CARGO_HOME=/tmp/catk-a-cargo \
CARGO_TARGET_DIR=/tmp/catk-a-kona-target \
cargo test -j 1 -p kona-derive \
  test_batch_validator_next_batch_parent_hash_mismatch -- --nocapture
```

Expected: 1 passed, 0 failed.

