# LANE B — HISTORICAL MESSENGER FAILURE / THIRD-PARTY FORCED FAILURE

Inputs: A-012, A-068, BW0-03, lead L3; PRIM-0304, PRIM-0401, PRIM-0803, PRIM-1202, PRIM-2306 (PASS A),
PRIM-CF6-02. Known mechanic (proven on a fork in PASS A, unchanged since v8): a third party can finalize
a victim's mature messenger withdrawal from inside a replay of its own failed message (L1CDM re-entrancy
branch), so the victim's message is recorded as failed, its ETH moves lockbox -> L1CDM, replayable once.

Mission:
1. Population scan on all four chains from each Portal's birth to block 26433900 (chunked eth_getLogs,
   <= 10k blocks, through the proxy; reuse `evidence/F6-failed-relayed-logs.json` (OP, 23 logs) and
   `evidence/F4/` withdrawal event files): `WithdrawalFinalized(hash, success=false)`; L1CDM
   `FailedRelayedMessage`; portal-finalized messenger withdrawals with NEITHER messenger mapping written
   (check `successfulMessages`/`failedMessages` at 26433900); non-zero-value failures. Write the census
   to `LIVE-OBJECTS-B.md` with ETH amounts.
2. Reconstruct each value-bearing case (calldata + storage) and replay it under v9 on a fork: is it
   still replayable, to whom does the ETH go, can anyone else trigger the replay, does the replay
   succeed with full gas?
3. Compose the nested-finalization primitive with targets where delayed replay is NOT equivalent to
   first delivery. Enumerate concrete production targets from real withdrawals (fixtures + the census):
   L1StandardBridge (ETH/ERC20 finalize — does `deposits[l1][l2]` accounting or token release ordering
   change if one withdrawal is forced to fail and a later one succeeds first?), L1ERC721Bridge, any
   target that checks `xDomainMessageSender()`/`portal.l2Sender()` in the same tx, deadlines/one-shot
   state, state consumed before replay, a pause or upgrade between failure and replay, replay
   capturable or blockable by another user.
4. Prove third-party-caused victim impact beyond one extra transaction: unrecoverable ETH, miscredit,
   capture, or permanent separation from the economic withdrawal. Reject ordinary replayable
   failedMessages and pure inconvenience (score -3 "retryable inconvenience").
