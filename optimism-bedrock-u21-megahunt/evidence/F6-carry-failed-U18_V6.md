# F6 carry-through: failed messenger message 0xe43cf22b3252c92cce6b3884f541ac9986c6859fd0b4421f8ab0a13db78c8802

fixture U18_V6/m0.json; produced by real tx 0xe1cb3df5f699f11795af81c218e51dbb68429748e1e0fc13e5056db9a26e171d (portal finalize) at block 24678043.
Persistent account: L1CrossDomainMessenger proxy only. Replay attempts by a fresh EOA (0x000000000000000000000000000000a11ce0f6F6, 10000000 gas, no value) run inside a snapshot (reverted).

| stage | block | L1CDM | failedMessages | successfulMessages | permissionless replay attempt |
|---|---|---|---|---|---|
| failed (U18_V6) | 24678043 | 2.11.0 | true | false | ok FailedRelayedMessage |
| after U19_V7 replay | 25397811 | 2.11.1 | true | false | ok FailedRelayedMessage |
| after U20_V8 replay | 26048619 | 2.11.1 | true | false | ok FailedRelayedMessage |
| after U21_V9 replay | 26430859 | 2.13.0 | true | false | ok FailedRelayedMessage |

## Final permissionless replay under v9 (L1CDM 2.13.0)

- outcome: ok, FailedRelayedMessage
- after: successfulMessages=false, failedMessages=true; target 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1 balance delta 0

## Carried-slot staleness (0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1 vs real end of block 26430859; values memorised BEFORE the final action)

11 distinct slots touched during the carry; 0 differ and were written when the local object was created; 0 other slots differ (stale or changed by later mainnet traffic):
