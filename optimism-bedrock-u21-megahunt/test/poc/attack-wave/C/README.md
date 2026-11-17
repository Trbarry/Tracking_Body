# ATK-C — EIP-7825 gas cap x cross-layer relay budget (permanent undeliverability)

Model: Opus 5.5 (`claude-opus-5-5`), per the user-approved exception in `/home/user/Tracking_Body/CLAUDE.md`
(Mythos 5.2 quota exhausted until 2026-11-22).

## Harness (real transactions on deployed bytecode)

Private anvil, lane port 19030, L1 forked from the archive proxy at block 26433900 (post-U21), hardfork osaka:

```bash
anvil --port 19030 --fork-url http://127.0.0.1:7545 --fork-block-number 26433900 --hardfork osaka --chain-id 1 --silent &
cd /home/user/Tracking_Body/optimism-bedrock-u21-megahunt/test/poc/attack-wave/C/scripts
python3 -I -u run_all.py ../../../../../evidence/attack-wave/C/results.jsonl      # whole battery (~1.5 h)
python3 -I -u run_all.py /tmp/x.jsonl E2_live                                     # one family only
python3 -I -u l2_accept.py                                                        # L2 side (OP fork :9545)
python3 -I scan_messagepassed.py <out.json>                                       # every Bedrock-era OP withdrawal
python3 -I scan_legacy_sentmessage.py <out.json>                                  # every legacy (OVM 2) message
```

`gascap.py` sends real `eth_sendTransaction`s from a fresh EOA (`0x0320…2c9d`, no code, no role;
impersonated only to skip local signing) and binary-searches (128-gas precision) the smallest
**transaction gas limit** for: finalize not reverting, finalize delivering, and (when the minimum
finalize records `failedMessages`) the smallest replay `relayMessage` tx after that forced failure.
Intrinsic gas, the EIP-7623 floor and warm/cold accounting are the node's. The local anvil does not
reject >2^24 transactions, so feasibility on mainnet is `min gas limit <= 16,777,216` (EIP-7825 is
live on L1, locked fact).

**Vehicle (stated):** the proof step is replaced by writing `provenWithdrawals[wh][attacker] =
(anchorGame 0x55A5…6f95, now − 7 d − 60 s)` with `anvil_setStorageAt` (slot 57, layout verified
against a real mainnet proof entry). Everything after that is deployed bytecode: portal 6.1.0,
L1CDM 2.13.0, L1StandardBridge 2.8.2, ETHLockbox, SuperchainConfig, real L1 token.
Withdrawal `gasLimit` comes from the LIVE L2CDM 2.2.1 `baseGas()` on `:9545`, or is the real struct
of a real in-flight OP Mainnet withdrawal (E2).

## Inequalities (v9 @ ba6fcadb unless noted)

- L2 budget, live L2CDM 2.2.1 (`op-v8.0.0/.../src/universal/CrossDomainMessenger.sol:357-395`):
  `B = 21000 + max(285000 + ⌊64m/63⌋ + 16(L+260), 40(L+260))`.
  Bedrock-era generation (live objects E2): `B_old = 285000 + 16L + ⌊64m/63⌋`
  (8,415,632 = 285,000 + 16·228 + ⌊64·8,000,000/63⌋ — matches the on-chain struct).
  Version-0 migrated: `B0 = min(25e6, 16·len(data) + 1,300,873)`, m = 0
  (`op-chain-ops/crossdomain/migrate.go:77-121`).
- Portal `finalizeWithdrawalTransactionExternalProof` (`src/L1/OptimismPortal2.sol:627`) →
  `SafeCall.callWithMinGas` (`src/libraries/SafeCall.sol:103-107,131`):
  `63·gasleft ≥ 64·B + 63·(40000 + N)`, `N = 183600` iff `value ≠ 0 ∧ target.codehash == 0`
  (never for messenger withdrawals: target is the L1CDM proxy). Else revert (retry).
  Forwards ALL gas (`:162`). L1CDM revert ⇒ portal reverts `OptimismPortal_L1CDMCallFailed` (`:651-653`).
- L1CDM `relayMessage` (`src/universal/CrossDomainMessenger.sol:265-281`):
  `63·gasleft ≥ 64·m + 63·(40000 + 135000 + 15000)` else `failedMessages = true` (replayable);
  target call `SafeCall.call(target, gasleft − 135000, …)` (`:285`).
- Replay (`:243-247`): any caller, `msg.value == 0`, requires `failedMessages[h]`; same check `:266`.
  Replay frame = tx → ResolvedDelegateProxy → impl; finalize frame = tx → portal → proxy → impl, so
  replay needs one fewer 64/63 factor, no portal pre-checks (~150k) and less calldata.
- Tx: `G ≥ 21000 + 4z + 16n + exec`, `G ≥ 21000 + 10(z + 4n)` (EIP-7623), `G ≤ 2^24` (EIP-7825).

See `/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/workers/ATK-C-report.md` for the results table.
