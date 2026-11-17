# F6 carry-through: withdrawal 0x604479f12ead21489e28cc39e77c44c154ffd010ac1824ee5bed12c7504fd830

fixture U16A_V4_1/p1.json; value 1919747470310000 wei; L2 sender 0x4200000000000000000000000000000000000007; real prove tx 0xd230cbdfc0fbf29b36b3c7b1fbff978208bf9078951d7df3744da2116553af47 at block 23872099.
The same prove calldata is sent from fresh submitter 0x0000000000000000000000000000F6F6F6c0fFEE (an object that never existed on mainnet). Persistent account: OptimismPortal only.
Finalize attempts in the table run inside a snapshot (reverted).

| stage | block | portal | proof (fresh submitter) | game | checkWithdrawal | finalize attempt |
|---|---|---|---|---|---|---|
| proven (U16A_V4_1) | 23872099 | 5.0.0 | yes (ts 1764028535) | status 0, NOT claimValid | revert 0xd9bc01be | revert 0xd9bc01be |
| after U17_V5 replay | 23877377 | 5.1.1 | yes (ts 1764028535) | status 0, NOT claimValid | revert 0xd9bc01be | revert 0xd9bc01be |
| after U18_V6 replay | 24421512 | 5.2.0 | yes (ts 1764028535) | status 2, claimValid | ok | ok (success=true) |
| after U19_V7 replay | 25397811 | 5.6.1 | yes (ts 1764028535) | status 2, claimValid | ok | ok (success=true) |
| after U20_V8 replay | 26048619 | 5.8.0 | yes (ts 1764028535) | status 2, claimValid | ok | ok (success=true) |
| after U21_V9 replay | 26430859 | 6.1.0 | yes (ts 1764028535) | status 2, claimValid | ok | ok (success=true) |

## Final finalization under v9 (6.1.0)

- as-is at the U21 block (ts 1794871439): ok, WithdrawalFinalized success=true
- finalizedWithdrawals(hash) = true; lockbox delta = -1919747470310000 wei (withdrawal value 1919747470310000)
- messenger: successfulMessages=true, failedMessages=false

## Carried-slot staleness (0xbEb5Fc579115071764c7423A4f12eDde41f106Ed vs real end of block 26430859; values memorised BEFORE the final action)

11 distinct slots touched during the carry; 1 differ and were written when the local object was created; 1 other slots differ (stale or changed by later mainnet traffic):
- slot 0x0000000000000000000000000000000000000000000000000000000000000001: carried 0x00000000018389d1000000000007df760000000000000000000000003b9aca00, real 0x0000000001934d8b000000000007df760000000000000000000000003b9aca00
