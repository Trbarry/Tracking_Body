# LANE 26 report — SystemConfig feature-state machine (mirror of lane 06)

## Result

No permissionless, production-reachable vulnerability survived falsification, so this lane writes **no CAND-26xx**. The two sharpest behaviors—runtime/reversible CUSTOM_GAS_TOKEN and prerequisite-free one-way INTEROP—are restricted to the ProxyAdmin or its owner, a role already able to upgrade every affected proxy (`op-v9.0.0/packages/contracts-bedrock/src/L1/SystemConfig.sol:528-568`; `src/universal/ProxyAdminOwnedBase.sol:102-105`). They are configuration hazards, suppressed by the engagement rules, not attacker paths.

The U21 pause migration is internally consistent on all four governed chains. A Guardian pause of each chain's lockbox paused Portal, SystemConfig, ASR, DelayedWETH's withdrawal path, L1CDM, both bridges, and lockbox unlock. No outbound L1 value-release bypass remained. Inbound deposits and zero-value bookkeeping intentionally remain live.

Research was blind and independent: only `LANE_CONTEXT.md`, allowed U21 transaction evidence, pinned source trees, passive RPC reads, and this lane's files/tests were used. No public-network transaction was sent.

## Artifacts

* `mirror/lane-26/FEATURE_STATE_MACHINE.md` — all 8 named-feature combinations, transitions, consumers, v7/v8 diff, L1/L2 split.
* `mirror/lane-26/CONSUMER_INVENTORY.md` — exhaustive production readers, separated by runtime versus object-creation/management time.
* `mirror/lane-26/PAUSE_MATRIX.md` — resolver graph, all four chains, value-entry matrix, expiry, CGT/shared-lockbox treatment.
* `mirror/lane-26/ONCHAIN_SYSTEMCONFIG_STATE.md` — full address/owner/feature/gas/fee/resource state.
* `mirror/lane-26/U21_PROXY_IMPLEMENTATION_MAP.md` — independent N-1/N proxy storage and implementation diff.
* `mirror/lane-26/TEST_RESULTS.md` and copied Foundry tests under `mirror/lane-26/test/`.

## 1. Feature lattice and transitions

v9 defines exactly ETH_LOCKBOX, CUSTOM_GAS_TOKEN, and INTEROP (`src/libraries/Features.sol:31-41`). From the live `(E,C,I)=(1,0,0)` state:

* E cannot move to 0 (`SystemConfig.sol:543-547`). OPCMv2 makes E=1 before Portal initialization and installs/initializes the lockbox (`src/L1/opcm/OPContractsManagerV2.sol:860-896`).
* C may move both ways through the generic setter. OPCM allows first enable only at initial deployment, but no equivalent rule exists in SystemConfig (`OPContractsManagerV2.sol:998-1008`). Portal reads C at prove/finalize/deposit execution time, not object creation (`src/L1/OptimismPortal2.sol:406-409,586-589,741-759,816-821`). Forking real OP state, PA-owner C=true immediately rejected a native deposit despite >182k ETH already in its lockbox; C=false restored the old mode.
* I may move 0->1 only. The generic setter does not validate shared contracts. The intended migrator validates same PA owner/SuperchainConfig, I=false, unique nonzero ordered L2 IDs, C=false, and current pause=false before atomically setting I and rewiring (`src/L1/opcm/OPContractsManagerMigrator.sol:287-327,483-543`). A premature direct PA write permanently prevents this migrator from acting, but is privileged self-bricking.
* Unknown feature names are two-way PA-only flags with no found consumer.

Stable standard states are `100` (all four now), `110` (CGT deployment), and `101` (proper interop migration). `111` is rejected by the standard migrator but constructible by the fully trusted generic setter. States with E=0 fail v9 Portal initialization (`OptimismPortal2.sol:831-842`). Full table: `FEATURE_STATE_MACHINE.md`.

v7/v8 selected Portal versus lockbox pause identifier dynamically and allowed an ETH disable only while no lockbox was configured (`op-v8.0.0/packages/contracts-bedrock/src/L1/SystemConfig.sol:543-588`). v9 makes both ETH and INTEROP one-way and resolves pause unconditionally through the current Portal lockbox (`op-v9.0.0/packages/contracts-bedrock/src/L1/SystemConfig.sol:543-576`).

## 2. Cache/assumption audit

Portal caches SystemConfig/ASR/lockbox but reads features and ResourceConfig at execution (`OptimismPortal2.sol:273-303,804-859`). L1CDM and both bridges cache SystemConfig yet read current `paused()` (`src/L1/L1CrossDomainMessenger.sol:98-105`; `src/L1/L1StandardBridge.sol:122-129`; `src/L1/L1ERC721Bridge.sol:68-75`). ASR and DelayedWETH cache lockbox directly (`src/dispute/AnchorStateRegistry.sol:58-59`; `src/dispute/DelayedWETH.sol:47-48`).

Legacy games cache old ASR/WETH object addresses. The planned migrator reinitializes those exact objects to the shared lockbox, so old games inherit the new pause rather than retaining a stale resolver (`OPContractsManagerMigrator.sol:265-272,412-430,545-555`). The transaction is atomic and rejects an active old pause before switching (`:494-500`).

Super-root proof selection reads the current `SystemConfig.l2ChainId()` (`OptimismPortal2.sol:437-445`). There is no public ID setter; standard v9 upgrade instructions do not permit an ID override and migration preserves it (`OPContractsManagerV2.sol:347-375,636-644`; `OPContractsManagerMigrator.sol:432-466`).

L1 and L2 feature maps are independent. Lagoon derivation injects L2 INTEROP before the L2CM bundle only for interop plus a multi-chain dependency set (`op-node/rollup/derive/lagoon_activation_transactions.go:14-22,80-101`; `op-node/rollup/derive/attributes.go:171-182`). L2CM reads L2 L1Block, not L1 SystemConfig (`src/L2/L2ContractsManager.sol:170-195`). Current OP L2 reads were C=false/I=false.

## 3. Pause resolution on chain

At N, each Portal, ASR, and DelayedWETH pointed at its chain's lockbox; each SystemConfig and lockbox pointed at the same SuperchainConfig. The lockbox IDs are OP `0x322b...94D43`, Ink `0xbd4A...25a14`, Soneium `0x67B4...22E31`, Unichain `0x08bA...df5C5`.

`ETHLockbox.paused()` queries local-or-global for itself (`src/L1/ETHLockbox.sol:111-114`); Portal and ASR query lockbox directly (`src/L1/OptimismPortal2.sol:305-307`; `src/dispute/AnchorStateRegistry.sol:135-143`); SystemConfig follows Portal's current lockbox (`src/L1/SystemConfig.sol:570-576`). The fork paused each ID as the real Guardian and observed every dependent resolver true.

All raw pause timestamps for global, four old Portal IDs, and four lockbox IDs were zero at N-1, N, and block 26,433,900. All four E flags were already true at N-1. Therefore U21 neither lost nor resurrected an active/expired pause; it changed direct wiring, not the effective identifier.

SuperchainConfig v2.5.0 expires a pause after exactly 7,884,000 seconds, but retains the timestamp. A new `pause(id)` then reverts until Guardian calls `extend` or `unpause`; `extend` reactivates an expired pause (`src/L1/SuperchainConfig.sol:31-40,79-163`). Fork behavior matched.

## 4. Value-path pause test

On real OP proxies under a lockbox pause:

* Live/inbound: Portal deposit, Messenger send, StandardBridge ETH deposit, lockbox lock, DelayedWETH deposit/unlock bookkeeping.
* Blocked/outbound: Portal prove/finalize, Messenger relay, StandardBridge finalize ETH/ERC20, ERC721 finalize, lockbox unlock, DelayedWETH withdraw, ASR anchor update, open-game close/claim.

Portal deliberately lacks a deposit pause check and lockbox says locks remain live while unlocks stop (`OptimismPortal2.sol:730-795`; `ETHLockbox.sol:142-175`). No ETH escaped.

One precise nuance: legacy Fault and ZK games return from `closeGame` before checking pause when already closed. Their first `claimCredit` phase may schedule/unlock DelayedWETH accounting, but the value phase calls the paused `DelayedWETH.withdraw` (`src/dispute/FaultDisputeGame.sol:979-1040`; `src/dispute/zk/ZKDisputeGame.sol:647-716`; `src/dispute/DelayedWETH.sol:98-108`). A real closed type-8 OP game demonstrated only zero-credit bookkeeping. SuperFault checks pause first (`src/dispute/SuperFaultDisputeGame.sol:945-995`).

For a synthetic CGT state, force-setting C=true did not change the lockbox resolver. For future interop, a shared lockbox necessarily makes one local identifier pause every member, not one chain independently. The migrator rewires all legacy resolvers and rejects an active old pause; no stale value path was found.

## 5. Chain/resource state and U21 diff

All four systems are init version 3 / semver 4.3.0, E=true/C=false/I=false, SuperchainConfig v2.5.0, last OPCM v9.0.3. ResourceConfig is identical: max resource 20m, elasticity 10, denominator 8, min resource base fee 1 gwei, system tx 1m, max base fee `2^128-1`; minimum/maximum gas limits are 21m/500m. Initialization enforces ResourceMetering invariants (`SystemConfig.sol:494-526`), and owner `setGasLimit` enforces both bounds (`:398-409`). No public ResourceConfig setter exists.

Only Ink's EIP-1559 fields, 0/0, looked surprising; they were already 0/0 at N-1. U21 did not cause it, and the owner setter rejects new values below one (`SystemConfig.sol:415-431`). Full per-chain scalars, min base fees, owners, batchers, signers, and address tuples are in `ONCHAIN_SYSTEMCONFIG_STATE.md`.

The N-1/N storage diff found the expected implementation changes, lastUsedOPCM update, and new lockbox pointers in lockbox/ASR/WETH. It found no feature, owner, identity, fee, resource, address, or pause mutation. Two OP changes came from an ordinary deposit at tx index 341; U21 was index 358. Details: `U21_PROXY_IMPLEMENTATION_MAP.md`.

## 6. Falsified hypotheses

* REJ-2601: old/stale pause identifier value bypass — killed by four-chain deployed resolver and value-path tests.
* REJ-2602: permissionless CGT flip — killed by PA/PA-owner authorization and OPCM initial-deploy rule.
* REJ-2603: attacker malformed/repeated INTEROP migration — killed by authorization plus migrator validation.
* REJ-2604: public chain-ID/resource mutation — no setter/override route; migration preserves, bounds hold.
* REJ-2605: legacy games retain stale pause after migration — old ASR/WETH are rewired in place atomically.
* REJ-2606: closed-game claim releases ETH while paused — bookkeeping may run, DelayedWETH value exit cannot.

## 7. Compositions worth another lane

1. Execute the exact future OP+Unichain migration calldata on a production-state fork and enumerate every legacy game/credit/WETH object before and after. Source analysis is strong, but no production migration had yet occurred.
2. Cross-check the planned L1 shared-contract migration block against Lagoon's L2 INTEROP injection/dependency-set activation. The maps are intentionally independent, so ordering/configuration is the remaining high-value systems seam.
3. Monitor for any future route that delegates feature writes below PA-owner authority. Runtime CGT transitions become materially dangerous only if that trust boundary changes.
