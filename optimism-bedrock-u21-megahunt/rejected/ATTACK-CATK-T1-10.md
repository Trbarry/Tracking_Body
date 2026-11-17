# ATTACK-CATK-T1-10 — initializer idempotence

## Hypothesis

A same-version or wrapped post-upgrade initializer call resets messenger reentrancy sentinel or
portal resource-metering state and enables replay/incorrect deposits.

## Original condition and changed precondition

The original fixes made initialization conditional: portal `l2Sender` only when zero
(`OptimismPortal2.sol:273-302`), messenger sender only when zero
(`CrossDomainMessenger.sol:422-433`), and metering only when `prevBlockNum==0`
(`ResourceMetering.sol:165-172`). OPCMv2's privileged initializer re-runs are known; the changed
precondition is a direct unprivileged same-version call against every deployed proxy.

## Exact sequence and result

Snapshot each portal's three resource parameters and L1CDM version. From the attacker call portal
`initialize(live SystemConfig,live ASR,live lockbox)` and messenger `initialize(live
SystemConfig,live portal)` on all four chains. Every call reverts. Parameters and versions are
unchanged.

## Barrier and evidence

`reinitializer(initVersion())` plus ProxyAdmin/owner authorization prevents permissionless entry;
the guarded field writes remain unreachable. Test
`test_T10_initializerIdempotenceCannotBeReachedPermissionlessly` passes at
`mirror/CATK-T1/test/FixRegressionCATKT1.t.sol:476`. Privileged OPCMv2 behavior is documented
(blacklist Part 2 item 11), so this is privileged-only/known. No candidate.

