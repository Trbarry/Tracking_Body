# Lane 21 report — U21 upgrade execution and post-state

## Result

No permissionless, production-reachable vulnerability survived falsification. The executed transaction was atomic, installed the intended v9 runtime code, left every upgraded proxy initialized and every implementation singleton locked, and produced a same-chain wiring graph on OP Mainnet, Ink, Soneium, and Unichain. The only permissionless behavior with security relevance is deterministic proxy-address occupancy through the standalone Utils deployer (PRIM-2104); it did not affect this upgrade and no eligible current impact was demonstrated.

This lane independently inspected op-contracts/v9.0.0 at commit `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`, Ethereum blocks 26430858 (N-1), 26430859 (N), and 26433900 (later), the executed transaction and receipt, a passive upstream call trace, the local prestate diff, and N-fork tests. Machine-readable evidence is under [`mirror/lane-21`](../mirror/lane-21/).

## 1. Exact executed transaction

Transaction `0x024770b5fba87683ee1466562eefb1bcb408c29c764e24abd07c7d4050a82a99` was transaction 358 in block 26430859. It succeeded, used 6,534,939 gas, and emitted 307 logs. Sender `0xe10a25d4ec17a94ca455f3cda84137189843b4f2` called the Safe `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` with selector `0x6a761202` (`execTransaction`). Exact outer and inner calldata are in [`decoded-transaction.json`](../mirror/lane-21/artifacts/decoded-transaction.json).

The trace establishes this call-context chain:

```text
EOA
  CALL Safe proxy 0x5a0A...3d2A
    DELEGATECALL Safe implementation 0xd9DB...9552
      DELEGATECALL Multicall3 executor 0x93dc...f76a  aggregate3(...)
        DELEGATECALL OPCMv2 0x2d91...331f  upgradeSuperchain(...)
        DELEGATECALL OPCMv2 0x2d91...331f  upgrade(OP)
        DELEGATECALL OPCMv2 0x2d91...331f  upgrade(Ink)
        DELEGATECALL OPCMv2 0x2d91...331f  upgrade(Soneium)
        DELEGATECALL OPCMv2 0x2d91...331f  upgrade(Unichain)
          DELEGATECALL Utils 0xe1ea...c4c6
            CALL chain ProxyAdmin -> proxy
```

The Safe operation was `1` (DELEGATECALL), with zero value, gas price, gas token, and refund receiver. The five `aggregate3` entries all had `allowFailure=false`. OPCMv2 requires delegatecall at `packages/contracts-bedrock/src/L1/opcm/OPContractsManagerV2.sol:197-211,244-275,1073-1077`; OPCMv2 in turn delegatecalls Utils at `packages/contracts-bedrock/src/L1/opcm/OPContractsManagerUtilsCaller.sol:225-263`. Therefore ProxyAdmin sees the Safe as caller, which is why its `onlyOwner` routes at `packages/contracts-bedrock/src/universal/ProxyAdmin.sol:149-190` succeed. This is PRIM-2101, not an independent authorization bypass.

### Five aggregate entries

| # | selector / action | supplied target | game configuration / instructions |
|---:|---|---|---|
| 0 | `0x86fe1c66` `upgradeSuperchain` | SuperchainConfig `0x95703e0982140D16f8ebA6d158FccEde42f04a4C` | no extra instructions |
| 1 | `0x8a847e2e` `upgrade` | OP SystemConfig `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` | respected 9; type-5 proposer `0xc27ba3e0fc01567a5e57ae0c391aa98cecba5be0`; type 9 enabled |
| 2 | `0x8a847e2e` `upgrade` | Ink SystemConfig `0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364` | respected 9; proposer `0x3832bfbef03173e4c49a00ec0dd178817a02d177`; type 9 enabled |
| 3 | `0x8a847e2e` `upgrade` | Soneium SystemConfig `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3` | respected 5; proposer `0x400c164c4a8ca84385b70eed6eb03ea847c8e1b8`; type 9 disabled |
| 4 | `0x8a847e2e` `upgrade` | Unichain SystemConfig `0xc407398d063f942feBbcC6F80a156b47F3f1BDA6` | respected 9; proposer `0x86b392ca30ad7453c8d88b56eb5a04fd0e2175b7`; type 9 enabled |

For every chain, types 0, 1, 8, and 10 were disabled with zero bond and empty args. Type 5 was enabled with zero bond. Enabled type 9 used a 0.08 ETH bond and prestate `0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9`. Every chain also supplied `PermittedProxyDeployment = bytes("ETHLockbox")`; the respected-game override was 9/9/5/9. The six input configurations are validated at `OPContractsManagerV2.sol:684-796`. The exact ABI-decoded tuples, including all SystemConfig values, appear in [`U21_INITIALIZER_CALLS.md`](../mirror/lane-21/U21_INITIALIZER_CALLS.md).

### Per-chain instruction order

After validation and version-sequence checking, `_apply` executes SystemConfig; enables the lockbox feature if needed; Portal; ETHLockbox; optional liquidity migration; messenger; standard bridge; ERC721 bridge; mintable factory; DGF; DelayedWETH; ASR; then DGF configurations (`OPContractsManagerV2.sol:803-1008`). The four chain calls were ordered OP, Ink, Soneium, Unichain, after the shared SuperchainConfig call. Because each aggregate entry rejects failure and all execution is within one Safe call, neither cross-chain nor per-proxy intermediate state can persist after success or inner failure. A Safe-level failure could consume a Safe nonce and emit `ExecutionFailure`, but the aggregate subcall would have reverted all upgrade mutations. The actual receipt emitted `ExecutionSuccess`.

## 2. Every receipt log attributed

[`decoded-logs.json`](../mirror/lane-21/artifacts/decoded-logs.json) maps each of receipt positions 0 through 306 to chain, proxy, event, decoded fields, and the exact instruction. The complete accounting is:

| Event | Count | Producing instruction |
|---|---:|---|
| `Proxy.Upgraded` | 132 | four Utils transitions for each of 33 ERC1967 proxies |
| `AddressManager.AddressSet` | 16 | four equivalent transitions for each of four resolved messenger proxies |
| `Initialized` | 41 | one initializer for every touched proxy |
| `OwnershipTransferred` | 16 | two Ownable events each from SystemConfig and DGF on four chains |
| `SystemConfig.ConfigUpdate` | 12 | batcher hash, Ecotone gas config, and gas limit on each chain |
| `SuperchainConfig.ConfigUpdate` | 1 | guardian reinitialization |
| `ETHLockbox.PortalAuthorized` | 4 | each lockbox authorizes its own portal |
| `ImplementationSet` | 28 | seven DGF implementation writes per chain |
| `ImplementationArgsSet` | 28 | matching DGF argument writes |
| `InitBondUpdated` | 28 | matching DGF bond writes |
| `Safe.ExecutionSuccess` | 1 | successful Safe completion |

The seven DGF writes per chain are the six supplied types plus the unconditional clearing of retired `SUPER_CANNON` type 4 at `OPContractsManagerV2.sol:961-996`. ChugSplash bridge implementation writes use the legacy proxy storage route and emit no ERC1967 event; their initializer events are present.

### Why `StorageSetter -> real -> StorageSetter -> real`

The intermediate implementation is StorageSetter `0x2476c911E6D4D9411E677D8Faf15a64ac1fDEEe8`, v1.2.2. It exposes arbitrary slot setters and is explicitly only safe as an intermediate upgrade implementation (`packages/contracts-bedrock/src/universal/StorageSetter.sol:10-42`). Utils:

1. installs StorageSetter;
2. rejects an occupied OZ-v5 Initializable namespace;
3. clears one byte of the OZ-v4 initializer field in slot 0 (messenger byte offset 20, every other U21 target offset 0);
4. installs the real implementation and executes its initializer;
5. reinstalls StorageSetter solely to read and reject any newly written OZ-v5 initializer namespace; and
6. restores the real implementation without calldata.

This is the exact code at `OPContractsManagerUtils.sol:352-386`; messenger offset selection is `OPContractsManagerV2.sol:899-908`. The second StorageSetter pass does not alter an application slot. Resolved and ChugSplash proxies follow the same logical sequence through ProxyAdmin's type dispatch (`ProxyAdmin.sol:101-114,149-190`). The sequence is PRIM-2102. No transaction boundary or untrusted callback exists while a proxy is executing StorageSetter code.

## 3. Proxy implementations, initializers, and runtime code

The full 41-row map is [`U21_PROXY_IMPLEMENTATION_MAP.md`](../mirror/lane-21/U21_PROXY_IMPLEMENTATION_MAP.md), and every exact initializer argument is in [`U21_INITIALIZER_CALLS.md`](../mirror/lane-21/U21_INITIALIZER_CALLS.md).

- Touched set: one shared SuperchainConfig plus ten proxies on each of the four chains.
- Proxy types: 33 ERC1967, four RESOLVED messengers, four CHUGSPLASH standard bridges.
- Final pointer changes: 25. Sixteen proxies were deliberately reset and reinitialized at their existing implementation.
- Common implementation transitions: SuperchainConfig 2.4.3 -> 2.5.0; SystemConfig 4.0.0 -> 4.3.0; Portal 5.8.0 -> 6.1.0; ETHLockbox 1.3.1 -> 2.0.0; messenger 2.11.1 -> 2.13.0; DelayedWETH 1.5.1 -> 2.0.0; ASR 3.9.0 -> 4.0.0. StandardBridge 2.8.2, ERC721Bridge 2.9.1, MintableFactory 1.11.0, and DGF 1.6.1 stayed on their existing implementations.
- All eleven distinct final implementation runtimes plus StorageSetter exactly match the pinned local v9 artifacts after zeroing only artifact-declared immutable ranges; lengths match and no comparison failed. See [`runtime-bytecode-verification.json`](../mirror/lane-21/artifacts/runtime-bytecode-verification.json).
- Proxy initialized bytes were unchanged N-1 -> N: SuperchainConfig 2; SystemConfig, Portal, messenger, and both bridges 3; the other contracts 1. Every distinct final singleton had `0xff` at its initializer byte (messenger offset 20; otherwise offset 0). No singleton was left initializable.

Initializers are restricted to ProxyAdmin or its owner through `ProxyAdminOwnedBase.sol:88-105`, in addition to their version guards. The N-fork test `test_proxyAndImplementationInitializersAreNotReRunnable` confirms direct initializer calls against every proxy class and implementation singleton revert.

Untouched objects were expected: ProxyAdmins and AddressManagers are ownership infrastructure rather than implementation proxies; the Safe implementation, game implementation singletons, MIPS/preimage contracts, and existing game clones are not targets of standard OPCM proxy upgrades. The four AddressManagers changed only the resolved messenger implementation mapping.

## 4. Exact N-1 -> N storage ledger

The passive prestate diff contains 31 touched accounts and 47 final storage-slot changes. [`attributed-state-diff.json`](../mirror/lane-21/artifacts/attributed-state-diff.json) assigns every slot to an instruction; both `unmapped_storage_changes` and `unexpected_storage_changes` are empty.

| Final storage change | Count | Attribution |
|---|---:|---|
| ERC1967 implementation pointer | 21 | real implementation restored after Utils cycle |
| AddressManager messenger implementation mapping | 4 | RESOLVED equivalent of implementation pointer |
| `SystemConfig.lastUsedOPCM` | 4 | old `0x1951828C...896a` (8.0.1) -> `0x2d91e6F2...331f` (9.0.3) |
| `ETHLockbox.superchainConfig` slot 3 | 4 | zero -> shared SuperchainConfig |
| `DelayedWETH.ethLockbox` slot 5 | 4 | zero -> its same-chain lockbox |
| ASR packed slot 6 | 4 | adds its same-chain lockbox while preserving retirement timestamp and respected type |
| DGF type-9 game-args prestate word | 3 | old -> new prestate on OP, Ink, Unichain |
| OP DGF type-5 proposer words | 2 | `0x473300df21d047806a082244b417f96b32f13a33` -> decoded proposer above |
| Safe nonce slot 5 | 1 | 48 -> 49 |

No initializer byte is a final diff because each was restored to its prior release version. Same-implementation writes, unchanged DGF implementations/bonds, and repeated configuration setters emit logs but do not create final slot differences. The four `lastUsedOPCM` values remained v9.0.3 at the later block; exact reads are in [`validator-and-opcm-metadata.json`](../mirror/lane-21/artifacts/validator-and-opcm-metadata.json).

## 5. Four-chain post-upgrade wiring graph

[`post-upgrade-wiring.json`](../mirror/lane-21/artifacts/post-upgrade-wiring.json) executes all 283 zero-argument ABI getters that return or contain addresses across the 41 proxies, then checks explicit expected relationships. There are zero expectation mismatches and zero configuration changes through block 26433900.

For each chain, SystemConfig points to that chain's messenger, bridges, portal, mintable factory, DelayedWETH, DGF, current OPCM, and the shared SuperchainConfig. Portal points to its SystemConfig, ASR, and lockbox. Messenger and both bridges point to the same-chain siblings. MintableFactory points to its standard bridge. DGF, ASR, DelayedWETH, and lockbox ownership/admin references agree; ASR points to same-chain DGF and lockbox; DelayedWETH points to same-chain lockbox. Every nonzero anchor game is registered in that chain's DGF.

The four-by-four portal authorization matrix is diagonal: each lockbox authorizes only its own portal. No current lockbox is authorized as another lockbox. Thus no wrong-chain Portal, lockbox, ASR, DGF, WETH, messenger, bridge, or SuperchainConfig pointer survived. This kills REJ-2101.

## 6. Dispute-game boundary behavior

Post-U21, type 5 uses implementation `0x5C3eb47cB0174aea522a2a9Ae79487139A53D691`, arguments `[same-chain ASR, decoded proposer]`, and zero bond on all chains. Type 9 uses implementation `0x19AF533Cc2A2A55786DCB8672aA5717e64213208`, arguments `[new prestate, MIPS 0xacc005dcd857b401e4732e6f7837135a22825cfa, same-chain ASR, same-chain DelayedWETH, chainId=0]`, and a 0.08 ETH bond on OP, Ink, and Unichain; it is zeroed on Soneium. Utils constructs exactly these packed arguments at `OPContractsManagerUtils.sol:439-507`. Types 0, 1, 4, 8, and 10 are zeroed.

DGF snapshots `gameArgs` into each clone's immutable args at creation (`packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol:142-225`) and owner-only configuration writes occur at lines 298-322. Consequently, existing games were not retroactively reinterpreted:

| Chain | last pre-U21 respected game | type | pre/post/later result |
|---|---|---:|---|
| OP | `0x675E956B1912Df79108408CA524fB37810500d10` | 9 | old prestate; registered, respected, unretired, proper; status 0 |
| Ink | `0x40beC00713A38EE5fD697764D50f0055bA4942cc` | 9 | same |
| Soneium | `0xACe27C57c234E95D612d4E04233a367C3cE4E15e` | 5 | current proposer; registered/respected/proper; status 2 |
| Unichain | `0x3073a5f81798E353033Ba07cF19b49d6390a68d8` | 9 | old prestate; registered, respected, unretired, proper; status 0 |

All later type-9 games use the new prestate and same-chain ASR/WETH; later Soneium games remain type 5. ASR registration/respect/retirement/proper predicates are at `AnchorStateRegistry.sol:215-307`. This old/new prestate population is PRIM-2103. No evidence shows either prestate unsound, so it is not a candidate.

## 7. Validator, direct-call, and partial-state falsification

### Standard validator

The deployed StandardValidator `0x9E1D...41B2` returned an empty error string for OP, Ink, and Unichain when supplied the exact proposer/prestate inputs. It returned `SCKDG-SHAPE,SCKDG-10` for Soneium because Soneium deliberately disabled type 9 and selected permissioned type 5. The default-enabled super-root feature is defined at `packages/contracts-bedrock/src/libraries/DevFeatures.sol:46-61`; the standard validator expects both super permissioned and super permissionless shapes at `packages/contracts-bedrock/src/L1/OPContractsManagerStandardValidator.sol:958-987` and `StandardValidatorUtils.sol:162-181`. OPCMv2 itself only requires that the selected respected type is enabled (`OPContractsManagerV2.sol:782-795`).

This is a documented operational shape exception, not an exploit: Soneium's exact calldata, respected type, factory state, and wiring agree, and later type-5 games were created normally. No mutated field escaped the independent storage and wiring checks. REJ-2107 records the mismatch and killing facts.

### Permissionless/direct call surface

Six N-fork tests in [`U21ExecutionGuards.t.sol`](../mirror/lane-21/tests/U21ExecutionGuards.t.sol) pass:

1. direct calls to OPCMv2 `upgradeSuperchain`, `upgrade`, and `migrate` hit `OnlyDelegateCall`;
2. a shaped direct call to Migrator cannot use a real chain's ProxyAdmin authority;
3. direct ProxyAdmin and Utils upgrade attempts cannot change the production proxy;
4. direct StorageSetter calls alter only the singleton's own storage;
5. proxy and implementation initializers cannot be rerun; and
6. standalone Utils can permissionlessly occupy a predictable normal-proxy CREATE2 address.

ProxyAdmin mutations are owner-only (`ProxyAdmin.sol:133-190`), and proxy-side admin/owner assertions are `ProxyAdminOwnedBase.sol:79-105`. Container has only constructor-set data and view getters (`OPContractsManagerContainer.sol:67-105`). An attacker may delegatecall OPCMv2 from the attacker's own contract, but that context is not owner of the deployed ProxyAdmins.

The exception is `OPContractsManagerUtils.loadOrDeployProxy`, which is external and unauthenticated (`OPContractsManagerUtils.sol:225-302`). For a permitted normal-proxy name it reaches deterministic CREATE2 (`packages/contracts-bedrock/src/libraries/Blueprint.sol:116-134`). The fork test proves an attacker can occupy a predicted proxy address and make the identical second deployment collide, while gaining no ProxyAdmin authority. All U21 lockboxes already existed, so this path was not used to create a contestable address in the executed transaction. This is PRIM-2104 and REJ-2108, not a current candidate.

## 8. N -> block 26433900

No implementation, initializer byte, same-chain pointer, authorization, DGF configuration, respected type, retirement timestamp, or `lastUsedOPCM` value changed. [`n-to-later-state.json`](../mirror/lane-21/artifacts/n-to-later-state.json) observed only normal operation:

- Portal metering block parameters advanced on all four chains.
- Messenger nonces advanced on all four chains.
- DGF counts advanced OP 21,378 -> 21,389; Ink 2,639 -> 2,640; Soneium 8,533 -> 8,537; Unichain 17,681 -> 17,691.
- ASR anchor games/roots advanced on all four chains.
- OP DelayedWETH supply/balance increased by the 0.08 ETH game bond; OP and Unichain lockbox balances changed through normal use.

These later reads independently show that all four configurations continued operating after U21.

## 9. Primitives, rejected hypotheses, and candidates

- **PRIM-2101 — Safe-context delegatecall authority.** Nested delegatecall preserves the Safe as ProxyAdmin caller; direct OPCM calls fail.
- **PRIM-2102 — Atomic two-pass StorageSetter reinitialization.** A transient arbitrary-slot implementation is safe only because the four-step transition is atomic and has no untrusted callback.
- **PRIM-2103 — Old/new dispute-game prestate populations.** Existing clones retain old immutable args while future clones use the new factory args.
- **PRIM-2104 — Permissionless deterministic proxy-salt occupancy.** Standalone Utils can occupy a predictable normal-proxy CREATE2 address without gaining admin rights.

No `CAND-21xx` file was created. Eight killed hypotheses are recorded with their exact killing facts in [`REJ-2101`](../rejected/REJ-2101.md) through [`REJ-2108`](../rejected/REJ-2108.md): wrong/stale pointers; incomplete initialization; direct-call authority theft; partial bundle persistence; retroactive game reinterpretation; unexpected runtime/storage; exploitable validator mismatch; and current eligible impact from salt occupancy.

## 10. Compositions worth another lane's attention

1. **Safe delegatecall surface + ProxyAdmin ownership:** independently audit Safe modules/fallback handlers for any path that lets an unprivileged caller choose a delegatecall target. PRIM-2101 becomes critical only in that composition.
2. **Future mandatory fixed-salt deployment + permissionless Utils:** PRIM-2104 could become a same-block or predeployment DoS if a future migration must introduce a missing normal proxy with an immutable salt and cannot choose a fresh mixer.
3. **A concrete defect in the old type-9 prestate + preserved in-flight games:** PRIM-2103 matters if the old prestate itself is shown unsound, because pre-U21 respected games remain withdrawal-relevant by design.

## Evidence index

- Transaction/calldata: [`decoded-transaction.json`](../mirror/lane-21/artifacts/decoded-transaction.json)
- Call trace: [`u21-call-trace-upstream.json`](../mirror/lane-21/traces/u21-call-trace-upstream.json)
- All 307 logs: [`decoded-logs.json`](../mirror/lane-21/artifacts/decoded-logs.json)
- Exact initializers: [`decoded-initializers.json`](../mirror/lane-21/artifacts/decoded-initializers.json)
- Proxy map: [`proxy-implementation-map.json`](../mirror/lane-21/artifacts/proxy-implementation-map.json)
- Attributed storage: [`attributed-state-diff.json`](../mirror/lane-21/artifacts/attributed-state-diff.json)
- Wiring: [`post-upgrade-wiring.json`](../mirror/lane-21/artifacts/post-upgrade-wiring.json)
- Dispute state: [`dispute-state.json`](../mirror/lane-21/artifacts/dispute-state.json)
- Runtime matching: [`runtime-bytecode-verification.json`](../mirror/lane-21/artifacts/runtime-bytecode-verification.json)
- Later-state comparison: [`n-to-later-state.json`](../mirror/lane-21/artifacts/n-to-later-state.json)
- Validator/OPCM metadata: [`validator-and-opcm-metadata.json`](../mirror/lane-21/artifacts/validator-and-opcm-metadata.json)
- Fork-test output: [`forge-test-output.txt`](../mirror/lane-21/tests/forge-test-output.txt)
