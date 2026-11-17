# CATK-CMP1 pinned state and source barriers

All RPC observations below were passive reads. Ethereum pin: `26433900` unless noted; OP pin:
`159654093`. No state-changing RPC was issued.

## Real EtherFi withdrawal target

- Withdrawal fixture hash: `0x47b736f9bb45451aa7a7f9c334a97783616320467d52812cf80c3d237669b89a`.
- Value: `363.438235322873695226 ETH`; L1 target:
  `0x23CA5E5300d3b35a47DFeF6A36Ecba5AC0a96E03`; implementation:
  `0xc25b0d51cd9fd89f00b73f7b27ff9c91421fe5d8`.
- `getMessenger()` = OP L1CDM `0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1`.
- `getL1SyncPool()` = `0xD789870beA40D056A4d26055d0bEFcC8755DA146`; implementation:
  `0x5d310451276d28a90cc6910449052d29a41e3abd`.
- Pool `getReceiver(30111)` is the target and `getTotalUnbackedTokens()` is
  `46960416091474254981`.
- Verified implementation source decodes the committed tuple, checks the messenger and committed
  x-domain sender, then calls the pool. Pool `_finalizeDeposit` has no deadline, GUID-consumed map,
  or timestamp check. It checks ETH, `amountIn == msg.value`, receiver identity, reentrancy, and
  pause state. Its only temporal gate is a privileged pause.
- Role registry `0x62247D29B4B9BECf4BB73E0c722cf6445cfC7cE9` reports the sole
  `OPERATION_MULTISIG_ROLE` holder as `0x2aCA71020De61bb532008049e1Bd41E451aE8AdC`.
- Concatenated verified-source SHA-256:
  `35c54988546110e6bdf81d25389ec08593a5866c305a256795a3ed88ffa7dd7e`.

## Messenger, proof, pause, and cap barriers

- `CrossDomainMessenger.sol:234-295` commits sender, target, value, minimum gas, and message into the
  version-1 hash; a direct replay requires the prior failed bit; a successful bit is terminal.
- `SystemConfig.sol:574-575` resolves network pause through the portal's current lockbox.
  `L1CrossDomainMessenger.sol:98-100` uses that state. This is why both lockbox-local and global
  pauses stopped C03/C04 and why unpause restored the same immutable replay.
- `OptimismPortal2.sol:609-627` finalizes the withdrawal and transfers exact value before target
  execution. `OptimismPortal2.sol:671-704` is the proof/game gate. Once a nested messenger failure
  has occurred, direct replay no longer enters the portal or proof system.
- `OptimismPortal2.sol:711-727` deletes only the selected submitter's invalid proof. C05 blacklisted
  the real fixture's game, deleted that proof, and still settled the already-finalized message.
- `SafeCall.sol:103-145` enforces the minimum-gas inequality and reserves extra gas only for a
  value-bearing empty account. C06 settled the real application message inside a `16,000,000` gas
  subcall, below the `2^24` transaction cap.

## One-shot and target-identity objects

- Hop failed message `0x33f61390a17c6fc32db1a11557ae861c762d6784a3f4a493138c38051faee088`
  commits `confirmTransferRoot(10, 0xf47f...cb76, 8453, 12.827169467136773559 ETH,
  1711679503)`. Root id `0x57a69719b6d1bba62adf334d4424457861e031239ecabc36536442874d532e69`
  already has `transferRootCommittedAt(8453,id) = 1711679503`. Replay remains failed with zero value:
  the intended one-shot effect already exists.
- Synthetix failed message `0x43e0b78554c436637d3a3f6383edce9dd460777a14776a6b035c604c38bd0deb`
  commits target `0x39Ea01a0298C315d149a490E34B59Dbf2EC7e48F`; deployed replay still
  fails its `Must be proxy target` authorization. It has zero value and the replay caller cannot
  substitute the proxy.

## Lockbox and migration barriers

- OP lockbox authorizes only OP's portal among the four current portals (`true,false,false,false`).
- `ETHLockbox.sol:142-174` requires the exact authorized portal for lock/unlock and default portal
  `l2Sender` for unlock. `ETHLockbox.sol:180-215` makes lockbox authorization sticky but gates
  authorization and liquidity migration to the ProxyAdmin owner.
- C09 force-sent attacker ETH to the deployed lockbox; attacker `unlockETH` and an Ink-portal
  `lockETH` frame both failed, with the balance unchanged.
- A passive call by `0x...ca7c01` to `migrateToSharedDisputeGame(1,2)` reverted
  `0x4a651100 = OptimismPortal_NotUsingInterop()`. The production OP portal therefore cannot enter
  the planned shared migration path today; even once INTEROP is enabled,
  `OptimismPortal2.sol:528-570` requires unpaused state, ProxyAdmin ownership, a different ASR, and
  a lockbox that already authorizes the exact portal.

## Gas-sender population (R3)

Independent read-only census: `gas-sender-census.json`.

- 35,579 `MessagePassed`; 35,544 canonical L1CDM targets; 35,543 canonical outer L2CDM senders;
  zero relay decode failures; 46 inner senders (38 contracts); 47 inner targets.
- Maximum inner minimum gas: `8,000,000`; maximum outer gas: `8,415,632`; maximum inner message:
  416 bytes. All are below the post-cap undeliverable band.
- The five 8M objects have inner sender L2StandardBridge `0x4200...0010`, fixed target OP
  L1StandardBridge, and standard finalization selectors. `StandardBridge.sol:305-383` binds the
  caller-funded asset transfer and recipient into that fixed bridge message. No unrelated victim
  call is created by the gas choice.

## Live executor allowance (R4)

- USDC Approval event at block `25084528`: owner
  `0x66ba29ab634845a509d2718deab78dba28b43d79`, spender Unichain L1CDM
  `0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6`, amount `9,000,000` units.
- At the pin: allowance `9,000,000`, owner balance `2,531,863`, messenger balance `0`.
- This is spendable through an ordinary committed cross-domain call, but it is a user's voluntary
  approval to a generic executor and caps current loss at 2.531863 USDC. Messenger failure is
  atomic with the target call, while success sets the terminal message bit
  (`CrossDomainMessenger.sol:284-296`); forced failure adds no second spend.

## Trojan/old-prestate games (R5/R6)

- Newest sampled old-prestate OP game `0x675e956b1912df79108408ca524fb37810500d10`:
  `createdAt=1794870155`, type 9, status IN_PROGRESS, one claim, `isGameProper=true`,
  `isGameClaimValid=false` at the pin.
- `AnchorStateRegistry.sol:286-351` requires registered, nonblacklisted, nonretired, unpaused,
  respected, finalized, and DEFENDER_WINS. `OptimismPortal2.sol:701-704` consumes the combined
  predicate, not merely registration or recency.
- Proofs are keyed by `(withdrawalHash, proofSubmitter)`, so a trojan selected by an automatic
  prover cannot overwrite another submitter's proof. A failed/blacklisted choice can be deleted and
  re-proved. C05 further shows that proof invalidation has no reach into post-finalization replay.
- The censuses report 147 live old-program games at the engagement pin and 148 at the later
  `26435056` snapshot. This is a real temporary surface, but no user-constructible v1.7.0 vs
  v1.9.0 consensus delta or FPVM witness is known. Without that witness an attacker cannot force
  the required DEFENDER_WINS result; source inspection alone is not a live exploit.

## Source hashes

`OptimismPortal2.sol` `62c0cb...901a`; `ETHLockbox.sol` `747547...7dd`;
`L1CrossDomainMessenger.sol` `278a40...ddea`; `CrossDomainMessenger.sol` `77a1f8...e88c`;
`StandardBridge.sol` `714878...af4`; `AnchorStateRegistry.sol` `f6b521...ef3b`;
`SafeCall.sol` `d9dd13...d9c20` (SHA-256, local v9.0.0 checkout).
