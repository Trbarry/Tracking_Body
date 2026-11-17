# Lane 24 v7 → v8 → v9 source-diff notes

Commits: v7 `a7c88c8…778ab`, v8 `f45a5ccf…30b7`, v9 `ba6fcadb…31e3`.

## OptimismPortal2

v7 (5.6.1) → v8 (5.8.0) did not change the withdrawal execution/replay state machine. The relevant Portal delta added migration zero-address/Lockbox-authorization checks.

v8 → v9 changed the withdrawal lane materially:

- imported `Predeploys` and, after the target call, added failure rollback only when encoded sender is the L2CrossDomainMessenger (`v9 OptimismPortal2.sol:639-653`);
- moved gas-estimation failure before that messenger check (`:632-653`);
- retained finalized-false behavior for all other failed target calls (`:655-665`);
- added permissionless deletion of permanently invalid proof records (`:707-728`);
- sourced Portal pause/guardian/SuperchainConfig through ETHLockbox and tightened active-Lockbox requirements (`:305-358,838-842`).

The prove encoding and withdrawal hash did not change: `keccak256(abi.encode(nonce,sender,target,value,gasLimit,data))` (`Hashing.sol:104-109`).

## CrossDomainMessenger

v8 → v9:

- `relayMessage` dynamic message parameter changed from calldata to memory, so ABI decoding copies before the internal gas check (`CrossDomainMessenger.sol:209-219`);
- one universal 40k/5k reserve became per-chain local/remote budgets; L1 local execution now uses 135k reserve + 15k buffer, L2 remains 40k + 5k (`GasConstants.sol:49-78`);
- `baseGas` became virtual and consumes remote-chain constants; compatibility getters expose remote budgets;
- successful/failed mapping logic and hash encoding were unchanged (`CrossDomainMessenger.sol:224-306`; `Hashing.sol:89-102`; `Encoding.sol:99-120`).

Memory-copy OOG before recording is not terminal for a genuine withdrawal: it makes the Portal→messenger call false, and v9 sender rollback keeps the Portal proof replayable.

## SafeCall

v8 → v9 added `NEW_ACCOUNT_STATE_GAS=183600` and passes it to `hasMinGas` for nonzero value to `target.codehash==0` (`SafeCall.sol:7-9,119-135`). Returndata remains uncopied (`:161-169`). Today the extra amount is conservative because Amsterdam is inactive; under a low outer gas attempt it reverts the full finalization rather than committing a false result.

## Storage

`diff` of v8/v9 storage-layout snapshots was empty. SHA-256:

```
OptimismPortal2.json       a8b04aeff8ef632889b997eeed7f367b4606e87593fb38d7fb86751a01f2547b
L1CrossDomainMessenger.json 75f195d43e2bd630561b6ac743722b458961a3603dab1756b151a4a4659a963c
```
