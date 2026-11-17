# ATK-F fork tests — unsafe withdrawal targets / surviving system-contract trust

Model: Opus 5.5 (CLAUDE.md exception, Mythos 5.2 quota exhausted until 2026-11-22).

Command (needs the shared pinned forks `:8545` L1 @ 26433900 and `:9545` OP Mainnet @ 159654093):

    cd /home/user/Tracking_Body/optimism-bedrock-u21-megahunt/test/poc/attack-wave/F
    forge test -j 1 -vv            # 4 tests, all PASS
    forge test -j 1 --match-test test_F01 -vvvv   # full trace of the 32-row matrix

`foundry.toml` = the u21-work template + `via_ir = true`. `lib/forge-std` is a symlink to the v9 checkout.

VEHICLE (stated): the L1 proof cell `provenWithdrawals[hash][submitter]` (v9 portal slot 57) is written with
`vm.store`, pointing at the portal's own claim-valid `anchorGame()`, proof timestamp = game.createdAt+1, then
`vm.warp(+8 days)`. All other code (checkWithdrawal, unlock, target call, relock, events) is deployed bytecode.
The attacker-authored L2 side of every F01 row is executed for real on the OP Mainnet fork
(`L2ToL1MessagePasser.initiateWithdrawal` from an unprivileged EOA; `sentMessages[hash] == true` is asserted for the
exact struct finalized on L1).

| Test | What it executes | Result |
|---|---|---|
| `test_F01_targetMatrix` | 32 attacker withdrawals finalized by the OP portal into sibling lockboxes (unlock/lock/receiveLiquidity), the lockbox implementation, all four L1CDMs (forged first relay), L1StandardBridge, L1ERC721Bridge, SystemConfig, ProxyAdmin, AddressManager, SuperchainConfig, ASR v4, ASR 2.0.0 (0x18DAc71c), ASR 2.2.2 (0x1c68ECfb), DelayedWETH v2 + g1, DGF, L2OutputOracle, OPCMv2, sibling portal deposit, own L1CDM sendMessage | 30 target calls fail, 2 succeed (attacker's own value only); hash of shared state on 4 chains unchanged; lockbox deltas exact |
| `test_F07_currentLockboxBlocked` | target = own lockbox / own portal on all four chains | `OptimismPortal_BadTarget` at finalize |
| `test_F08_deadSenderVsSiblingLockboxes` | unreachable sender 0x…dEaD (l2Sender stays DEFAULT) vs Ink/Soneium/Unichain lockboxes | `ETHLockbox_Unauthorized` (0x665a1d1c), nothing moves |
| `test_F09_liveAllowanceToMessenger` | live USDC allowance (9 USDC) of 0x66ba29ab… to the Unichain L1CDM spent via an L2CDM message | 2.531863 USDC moved — victim-error object, rejected (ATTACK-F-05) |
