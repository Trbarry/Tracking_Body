# F6 carry-through: failed messenger message 0x2c820221fbef636211cbff87243f637325f124f5e6c27c91929cb4854000f60f

fixture U14_V3/m3.json; produced by real tx 0xfef216e752eb239d6b16c1990e09724e73d67903e6d042185e67aef363760ef9 (portal finalize) at block 22774953.
Persistent account: L1CrossDomainMessenger proxy only. Replay attempts by a fresh EOA (0x000000000000000000000000000000a11ce0f6F6, 10000000 gas, no value) run inside a snapshot (reverted).

| stage | block | L1CDM | failedMessages | successfulMessages | permissionless replay attempt |
|---|---|---|---|---|---|
| failed (U14_V3) | 22774953 | 2.6.0 | true | false | ok FailedRelayedMessage |
| after U16_V4 replay | 22990599 | 2.9.0 | true | false | ok FailedRelayedMessage |
| after U16A_V4_1 replay | 23491328 | 2.10.0 | true | false | ok FailedRelayedMessage |
| after U17_V5 replay | 23877377 | 2.11.0 | true | false | ok FailedRelayedMessage |
| after U18_V6 replay | 24421512 | 2.11.0 | true | false | ok FailedRelayedMessage |
| after U19_V7 replay | 25397811 | 2.11.1 | true | false | ok FailedRelayedMessage |
| after U20_V8 replay | 26048619 | 2.11.1 | true | false | ok FailedRelayedMessage |
| after U21_V9 replay | 26430859 | 2.13.0 | true | false | ok FailedRelayedMessage |

## Final permissionless replay under v9 (L1CDM 2.13.0)

- outcome: ok, FailedRelayedMessage
- after: successfulMessages=false, failedMessages=true; target 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1 balance delta 0

## Carried-slot staleness (0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1 vs real end of block 26430859; values memorised BEFORE the final action)

12 distinct slots touched during the carry; 0 differ and were written when the local object was created; 0 other slots differ (stale or changed by later mainnet traffic):
