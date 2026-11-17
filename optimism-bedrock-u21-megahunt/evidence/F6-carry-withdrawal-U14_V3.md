# F6 carry-through: withdrawal 0x3d0aacb45e026be98a0bf9c7cf1a9f75d00702260c524459f357ba25251b92bc

fixture U14_V3/p0.json; value 4000000000000000 wei; L2 sender 0x4200000000000000000000000000000000000007; real prove tx 0xbd14fb9d63ae46e531f70cee58d5b8b813f71736a979bede3e122e3afcc9ef23 at block 22985908.
The same prove calldata is sent from fresh submitter 0x0000000000000000000000000000F6F6F6c0fFEE (an object that never existed on mainnet). Persistent account: OptimismPortal only.
Finalize attempts in the table run inside a snapshot (reverted).

| stage | block | portal | proof (fresh submitter) | game | checkWithdrawal | finalize attempt |
|---|---|---|---|---|---|---|
| proven (U14_V3) | 22985908 | 3.14.0 | yes (ts 1753322543) | status 2 | revert Error(OptimismPortal: proven withdrawal has not matured yet) | revert Error(OptimismPortal: proven withdrawal has not matured yet) |
| after U16_V4 replay | 22990599 | 4.6.0 | yes (ts 1753322543) | status 2, NOT claimValid | revert 0xd9bc01be | revert 0xd9bc01be |
| after U16A_V4_1 replay | 23491328 | 5.0.0 | yes (ts 1753322543) | status 2, NOT claimValid | revert 0x332a57f8 | revert 0x332a57f8 |
| after U17_V5 replay | 23877377 | 5.1.1 | yes (ts 1753322543) | status 2, NOT claimValid | revert 0x332a57f8 | revert 0x332a57f8 |
| after U18_V6 replay | 24421512 | 5.2.0 | yes (ts 1753322543) | status 2, NOT claimValid | revert 0x332a57f8 | revert 0x332a57f8 |
| after U19_V7 replay | 25397811 | 5.6.1 | yes (ts 1753322543) | status 2, NOT claimValid | revert 0x332a57f8 | revert 0x332a57f8 |
| after U20_V8 replay | 26048619 | 5.8.0 | yes (ts 1753322543) | status 2, NOT claimValid | revert 0x332a57f8 | revert 0x332a57f8 |
| after U21_V9 replay | 26430859 | 6.1.0 | yes (ts 1753322543) | status 2, NOT claimValid | revert 0x332a57f8 | revert 0x332a57f8 |

## Final finalization under v9 (6.1.0)

- as-is at the U21 block (ts 1794871439): revert 0x332a57f8
- after permissionless resolution/warp (game 0x1e9498029c5B290aec0d38850ac0eb0b9Eb4a16a status 2, ts 1794871439): revert 0x332a57f8
- finalizedWithdrawals(hash) = false; lockbox delta = -0 wei (withdrawal value 4000000000000000)

## Carried-slot staleness (0xbEb5Fc579115071764c7423A4f12eDde41f106Ed vs real end of block 26430859; values memorised BEFORE the final action)

14 distinct slots touched during the carry; 1 differ and were written when the local object was created; 1 other slots differ (stale or changed by later mainnet traffic):
- slot 0x0000000000000000000000000000000000000000000000000000000000000001: carried 0x00000000018389d1000000000007df760000000000000000000000003b9aca00, real 0x0000000001934d8b000000000007df760000000000000000000000003b9aca00
