# Lane 24 chain-state reads

All calls were passive. RPC aliases: N-1 `:8546`, N `:8547`, later post `:8545`, OP Mainnet `:9545`. No state-changing call was sent to a shared node.

## Versions and implementations

```
N-1 Portal:    version 5.8.0  impl 0x1005217ad392dc64cef501fa1777a27d42166748
N    Portal:    version 6.1.0  impl 0xb20b23af6071405c37ddda0c0640e8ebb7899645
post Portal:    version 6.1.0  impl 0xb20b23af6071405c37ddda0c0640e8ebb7899645

N-1 L1 CDM:     version 2.11.1 impl 0x59D497530b00062f40950ba8EaB88868bf7F86f0
N    L1 CDM:     version 2.13.0 impl 0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448
post L1 CDM:     version 2.13.0 impl 0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448
```

The L1 messenger's externally reported remote gas getters and `baseGas(0x,0)=310160` did not change across N. Internally, v9 L1 relay execution uses the new local reserve 135,000 and buffer 15,000; the public getters intentionally expose remote L2 budgets.

OP Mainnet L2CrossDomainMessenger remained v2.2.1 at the pinned L2 block; U21 did not hardfork/upgrade the L2 side.

## Current configuration

At N-1, N, and post:

```
Portal.systemConfig       0x229047fed2591dbec1eF1118d64F7aF3dB9EB290
Portal.anchorStateRegistry 0x23B2C62946350F4246f9f9D027e071f0264FD113
Portal.ethLockbox         0x322b47Ff1FA8D5611F761e3E275C45B71b294D43
Portal.paused             false
ASR.factory               0xe5965Ab5962eDc7477C8520243A95517CD252fA9
ASR.respectedGameType     9
ASR.retirementTimestamp   1753379243
ASR.paused                false
Lockbox.paused            false
Lockbox.authorizedPortal  true
ETH_LOCKBOX               true
CUSTOM_GAS_TOKEN          false
INTEROP                   false
```

## Real proof classification at later post block

For game `0x86512332B510F40Bb9361dE685cA1e4815dEe5fe`:

```
gameType                   9
createdAt                  1794857291
resolvedAt                 0
status                     IN_PROGRESS (0)
wasRespectedWhenCreated    true
ASR.registered             true
ASR.proper                 true
ASR.respected              true
ASR.blacklisted            false
ASR.retired                false
ASR.claimValid             false (unresolved)
```

This is why the real pre-U21 proof persists but cannot yet be finalized; it is not evidence of migration invalidation.

## New-account distinction

At post block, `0x0000000000000000000000000000000000000101` read balance 0, nonce 0, code `0x`; the fork observed `EXTCODEHASH=0`. A test-created then funded code-empty account observed `EXTCODEHASH=keccak256("")`. Both accepted 1 ETH through deployed v9 Portal with adequate outer gas.
