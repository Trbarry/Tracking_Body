# Lane 23 independent state baseline

All values below are passive reads from the pinned local forks. Commands used
`cast call`, `cast balance`, `cast storage`, and `cast logs`; no state-changing RPC
was sent.

## OP Mainnet custody at N-1, N, and later

| State | block 26430858 | block 26430859 | block 26433900 |
|---|---:|---:|---:|
| Portal version | 5.8.0 | 6.1.0 | 6.1.0 |
| Portal ETH | 0 | 0 | 0 |
| Lockbox ETH (wei) | 182416306525160721816415 | 182420511216757812708529 | 182541068255115703234018 |
| Portal lockbox | `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43` | same | same |
| Lockbox authorizes portal | true | true | true |

N-1 -> N lockbox delta is 4,204,691,597,090,892,114 wei. The only OP lockbox
custody log in block N is `ETHLocked(portal, 4204691597090892114)` from transaction
`0x762e0faad7b2a2800bb7348e7444a4a0d76b7c5c1b43b84b6bc56c19326cfda2`,
transaction index 341, log index 633. U21 is index 358. Filtering the saved U21
receipt finds zero `ETHLocked`, `ETHUnlocked`, `ETHMigrated`,
`LiquidityMigrated`, `LiquidityReceived`, `TransactionDeposited`, or
`WithdrawalFinalized` events.

At N the feature reads are ETH_LOCKBOX=true, INTEROP=false,
CUSTOM_GAS_TOKEN=false; `paused()` is false and portal `l2Sender()` is
`0x000000000000000000000000000000000000dEaD`.

## Implementation boundary

EIP-1967 implementation-slot reads at N-1 -> N:

| Proxy | N-1 implementation | N implementation |
|---|---|---|
| Portal `0xbEb5...106Ed` | `0x1005217ad392dc64cef501fa1777a27d42166748` | `0xb20b23af6071405c37ddda0c0640e8ebb7899645` |
| Lockbox `0x322b...94D43` | `0xb3a24db07038b51962026329b62e7a965d56a6ad` | `0xdf75e6b07e98873e36ba5c05508f80c1454e0afe` |
| SystemConfig `0x2290...EB290` | `0x670b850a235a6fa98cd7a195eb139d0277e471fa` | `0xade27248542c0f3e89b49e4eb76155e267f14377` |

Versions read 1.3.1 -> 2.0.0 for the lockbox and 4.0.0 -> 4.3.0 for
SystemConfig. The upgrade receipt shows the expected intermediate StorageSetter
implementation and then the final implementation; final slot values above are the
end-of-block truth.

## Sibling-chain custody

Portal balances are zero at all three observation points for OP, Ink, Soneium, and
Unichain. Lockbox balances (wei) are:

| Chain | N-1 | N | later |
|---|---:|---:|---:|
| OP | 182416306525160721816415 | 182420511216757812708529 | 182541068255115703234018 |
| Ink | 23088758336628210326229 | same | same |
| Soneium | 2195560152606106316659 | same | same |
| Unichain | 18222347018032559647506 | same | 18266157945407766718622 |

Thus there is no U21-time cross-chain liquidity move. Later changes are ordinary
post-upgrade activity.

## Real mature withdrawal fixture

- Withdrawal hash: `0xb16e5fc2aab1c33e0426b1ad64aa82484b4fe2a637027d2854ad00677f7ed612`
- Proof transaction: `0x424a6ad7ef4500fb905359f319796f5b9396e1465e8ddffc8ff8152e4da3bae6`
- Proof block: 26382676
- Submitter: `0x67E10B7764A99165665557B3E6cF24555bfC88c3`
- Game: `0x90F9C9E91fc12E23d170fdeE06be3E00Db21B3F2`
- Stored proof timestamp: 1794291647
- Later-fork timestamp: 1794908075 (616,428 seconds later)
- Value: 638177259920741319864 wei
- `checkWithdrawal` at the later fork: success; finalized mapping: false

The unmodified deployed-code fork finalization succeeds. This is evidence for the
live value path; the separate target-substitution tests are explicitly modeled-only.

