# ATTACK-F-04 — Sender 0x…dEaD keeps l2Sender == DEFAULT during the call (lockbox guard and re-entrancy guard off)

Lane ATK-F, Opus 5.5. Kill type: unreachable precondition (known, PASS A REJ-0309/REJ-0902) + failing experiment for today's state.

**Hypothesis.** With `_tx.sender == 0x…dEaD`, `ETHLockbox.unlockETH`'s l2Sender check passes; target a lockbox that authorizes
the portal but is not `ethLockbox` and drain it.

**Sequence executed.** `test_F08_deadSenderVsSiblingLockboxes`: vehicle proof for sender 0xdEaD, target Ink/Soneium/Unichain
lockbox `unlockETH(full balance)`, finalized on the OP portal.

**Barrier.** (1) Sender unreachable: L2 msg.sender 0x…dEaD needs its key or an L1 contract at 0x…dEaD - 0x1111…1111 (160-bit
preimage). (2) Even granting it, no lockbox other than the current one authorizes any of the four portals
(`ETHLockbox_Unauthorized`, ETHLockbox.sol:163); the current one is BadTarget (F07). Nothing moved; snapshot unchanged.

**Live object (attempt observed on mainnet).** OP portal `WithdrawalProven` 0x0cf8309e…7e4a at L1 block 26,404,222
(tx 0x294c0887…0a57), sender 0x…dEaD -> target 0x7813cc25… (EOA), proof cell -> game 0xa5714949… created by the same EOA,
CHALLENGER_WINS; `sentMessages` on OP L2 = false (forged). Unfinalizable and permissionlessly deletable.
