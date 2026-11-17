# CATK-B fork tests

The tests execute only against the pinned, read-only L1 fork at block 26,433,900. They never broadcast a transaction.

From `/home/user/u21-work/codex-CATK-B/h`:

```bash
cp /home/user/Tracking_Body/optimism-bedrock-u21-megahunt/mirror/CATK-B/test/Base.sol test/Base.sol
cp /home/user/Tracking_Body/optimism-bedrock-u21-megahunt/mirror/CATK-B/test/CATK_B.t.sol test/CATK_B.t.sol
cp /home/user/Tracking_Body/optimism-bedrock-u21-megahunt/mirror/CATK-B/test/proves.json proves.json
cp /home/user/Tracking_Body/optimism-bedrock-u21-megahunt/mirror/CATK-B/test/active-zero-value-replays.json active-zero-value-replays.json
forge test -j 1 --match-path test/CATK_B.t.sol -vv
```

The harness must enable the optimizer and `via_ir = true`. `Base.sol` and `proves.json` are copied PASS-A fixtures. CATK-B independently supplies the compositions and assertions. The nested tests use real proven withdrawals and deployed portal/messenger/bridge bytecode; `vm.etch` changes only the real carrier recipient from an EOA into a first-call rejector/nested caller.
