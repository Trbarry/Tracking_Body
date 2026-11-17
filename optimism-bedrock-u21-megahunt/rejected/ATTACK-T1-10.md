# ATTACK-T1-10 — Initializer idempotence under OPCMv2 (re-run initializers reset sentinels / metering)

Lane ATK-T1, Opus 5.5. Target 10 (rows 15 and 5). Kill type: failing experiment, four chains + privileged/future-only.

**Original safety conditions.** Trust TRST-H-1: `xDomainMsgSender` written only if zero (v9 `CrossDomainMessenger.sol:429`) and
post-call assert; TRST-L-2: metering params initialised only when unset (`ResourceMetering.sol:168-172`). OPCMv2 re-runs every
initializer on every upgrade (answered by a review rule, OPCMv2 3.3.13).

**Sequence executed** (`T1_Portal.t.sol::test_T1_06_initializerSentinelsAndGuards`, L1 @ 26433900): on OP/Ink/Soneium/Unichain the
portal metering params are live (prevBlockNum 26,433,899 / 26,433,755, prevBaseFee 1 gwei), every L1CDM slot 204 ==
0x…dEaD, portal `l2Sender == 0x…dEaD`, ASR retirementTimestamp set; an unprivileged EOA calling `initialize` with the exact v9
signature on portal, L1CDM, ASR, SystemConfig, L1StandardBridge, L1ERC721Bridge, DGF and DelayedWETH (32 proxies) reverts
with `Initializable: contract is already initialized` (the reinitializer version is consumed; the ProxyAdmin gate is behind it);
the four ETHLockbox `initialize` calls also revert.

**Barrier.** Both guarded fields are intact after U21 on all four chains and no initializer is reachable by a non-admin. The
mutation ("initializer arguments that differ from live state") needs a future OPCM upgrade run by the ProxyAdmin owner
(privileged + future-only: -5 -5). Known: SPI 5.1.1, OPCMv2 3.3.13 (Part 2 #11). Output: `evidence/attack-wave/T1/T1_Portal_04_05_06.out.txt`.
