# ATTACK-CATK-T3-07 — Old-format in-flight bridge message finalizes differently after U21

Model: Codex, configured by the worker brief as `gpt-daybreak-blue-latest`.

Verdict: **KILLED — real-proof differential produces identical exact delivery.**

## Hypothesis

A pre-U21 ERC721 message or migrated OVM ERC20 message using legacy `finalizeERC20Withdrawal` changes meaning under
Portal 6.1.0 / L1CrossDomainMessenger 2.13.0: reversed token order, a different recipient, failed delivery, or replay.

## Exact sequence tried

Use real game 21,377 and real `L2ToL1MessagePasser` storage proofs for two unfinalized production objects. On separate
N-1 (Portal 5.8.0) and post-U21 (6.1.0) forks, prove as one unprivileged address, resolve the real game honestly, mature,
finalize as another unprivileged address, measure exact bridge/token state, then finalize again.

Objects: ERC721 withdrawal `0x466d8922…5d4c5`; migrated OVM ERC20 withdrawal `0xcd782207…dae67`, nonce 100,135,
selector `0xa9f9e675`, 100 USDT.

## Barrier

The legacy wrapper forwards `(l1Token,l2Token,from,to,amount,data)` unchanged into the same
`finalizeBridgeERC20` (`L1StandardBridge.sol:235-246`). Pre and post both debit only the exact USDT pair, transfer
100,000,000 base units to the committed recipient, set the same versioned relay success key, and reject replay. The NFT
likewise clears only its exact triple and reaches only its committed recipient. L1CDM 2.13.0 changes gas budgeting, not
calldata meaning; sufficient transaction gas remains permissionlessly supplyable.

## Evidence

- PASS: `test_preU21_legacyERC20Wrapper_debitsExactPairOnce` and post-U21 counterpart.
- PASS: `test_preU21_inFlightERC721_deliversCommittedRecipientOnce` and post-U21 counterpart.
- Fixtures and proof roots: `mirror/CATK-T3/poc/test/fixtures/`.
