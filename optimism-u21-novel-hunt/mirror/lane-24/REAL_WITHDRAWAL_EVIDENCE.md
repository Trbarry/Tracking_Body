# Lane 24 real withdrawal / message evidence

All public-chain operations below were passive reads. The only state-changing replay was sent to lane-private Anvil `:18240`, snapshotted first, then reverted.

## A. Withdrawal proved under v8 and retained under v9

### Transaction and event

- prove tx: `0xe7d32d524f4bb828a405871e8dd0e583c6a88838489534757cb31462b3e7c089`
- block: 26,429,992 (`0x1934a28`), before U21
- caller/proof submitter: `0x47728c875b7F52a40227d662f83a3C3d0f7E6FBB`
- `WithdrawalProven` hash: `0xcb4d1cae41ae4f41058343d205d1e295eb5e4a55a380f45694e2b88991a1651d`
- indexed from: L2CrossDomainMessenger `0x4200…0007`
- indexed to: L1CrossDomainMessenger `0x25ac…5fA1`
- game index: 21,373

Decoded withdrawal struct:

```
nonce    1766847064778384329583297500742918515827483896875618958121606201292655347
sender   0x4200000000000000000000000000000000000007
target   0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1
value    0
gasLimit 669875
data     relayMessage(version-1 nonce 0x…8acf, L2StandardBridge,
                      L1StandardBridge, value 0, minGas 350000,
                      finalizeBridgeETH(...))
```

### Cross-boundary storage reads

At N-1, N, and later post block, identically:

```
provenWithdrawals[hash][submitter].game      0x86512332B510F40Bb9361dE685cA1e4815dEe5fe
provenWithdrawals[hash][submitter].timestamp 1794861023
numProofSubmitters(hash)                     1
finalizedWithdrawals(hash)                   false
```

The game is registered/proper/respected and not blacklisted/retired, but remains IN_PROGRESS, so `isGameClaimValid=false`. Storage survived U21; current unresolved status is the only finalization blocker. Fork assertion: `tests/WithdrawalFinalization24.t.sol:532-543`.

## B. Real v8 failed message replayed through v9

### v8 failure

- finalization tx: `0x39d668d98f82c46c021edabfda5b7187012022e9d018aee4998852835a667155`
- block: 26,385,051
- outer withdrawal hash: `0x4f04ff252de2f69c20e7c447715aec8264fc9447dc330a9d3298b4f515974946`
- Portal event: `WithdrawalFinalized(hash, true)` because the Messenger itself returned normally
- Messenger event/hash: `FailedRelayedMessage(0x9546105b80a67d2890768f2cf1c9bfdbc6d855ed8e8d7f47373d491b8bb11312)`

Decoded relay:

```
nonce       1766847064778384329583297500742918515827483896875618958121606201292639349
xSender     0x136b1EC699c62b0606854056f02dC7Bb80482d63
target      0x39Ea01a0298C315d149a490E34B59Dbf2EC7e48F
value       0
minGasLimit 3000000
message     0xa6492fe273555344...1e084b60c83e680000
```

At N-1, N, and post-U21: `failedMessages=true`, `successfulMessages=false`. Thus U21 did not erase or reinterpret the replay right.

### Private-fork v9 replay

The exact inner calldata was sent from an unlocked local Anvil account to the deployed v9 Messenger implementation on private `:18240`, with an 8,000,000 gas cap. Local tx `0x3f68afcec1631d43229e7fcd3b3aa831a196777c8adedf38a7747f67fd5916e0`:

```
status  1
gasUsed 0x3d0ea
event   FailedRelayedMessage(0x9546…11312)
after   failed=true, successful=false
```

The application still rejects the message, but v9 completed normally and retained its replay bit. The Anvil snapshot was then reverted. In-process reproduction: `tests/WithdrawalFinalization24.t.sol:455-476`.

For comparison, another real v8 failure `0x4469…3276` (block 26,346,791, 236.749727508928692667 ETH) was successfully replayed in tx `0xc20bc9dc4439e093ec5a2424813dcf247f04080a6afa87eb25ea87b4c8ff4a33` at block 26,357,020. At N/post both its failed and successful bits are true, and the success bit prevents any further execution.

## C. Exhaustive observed `WithdrawalFinalized(false)` check

Portal v5.8.0 first appears at block 26,048,619 (block 26,048,618 reports v5.6.1). Logs were scanned in <=10,000-block windows from 25,900,000 through N-1 26,430,858, covering the entire v5.8 deployment plus an earlier margin:

```
WithdrawalFinalized events: 2508
success=false events:       1
RPC range errors:           0
```

The sole false event was:

- block 26,139,841;
- tx `0xcaaa4a154a865d2ab0264135001b1577b0cce0688de176fa1299e8f0b3992000`;
- withdrawal hash `0xad0a2811460d8a7f4ef1c467171ee312fb9b85f9ca8965fa44a7e9542cc68ec4`;
- outer sender/target were the genuine L2/L1 messengers, value 0;
- inner nonce 114402 was message version 0;
- v1 hash `0x69fa35cf1923ddf105269d0f3eb1384104f64f75c38711f886cb8386ae8d921a`: success=false, failed=false;
- legacy v0 hash `0xaef8e13f0a6fcac3ea486125f3666b13b0b0333971bd4257a11cdec35a4b574f`: success=true at N-1, N, and post.

Therefore the only observed pre-U21 Portal-level failure with no messenger failed bit was an already-relayed legacy duplicate, not an undelivered economic withdrawal. This precisely matches `OptimismPortal2.sol:643-647`.
