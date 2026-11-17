# ATTACK-F-03 — Portal as caller of authority/config contracts of every generation

Lane ATK-F, Opus 5.5. Kill type: failing experiment.

**Hypothesis.** Some current or legacy system contract treats the portal (msg.sender of an attacker withdrawal) as an authority:
SystemConfig (setGasLimit, setFeature), ProxyAdmin (upgrade(portal), transferOwnership), AddressManager.setAddress,
SuperchainConfig.pause(lockbox), ASR v4 (setRespectedGameType, blacklistDisputeGame), ASR 2.0.0 0x18DAc71c, ASR 2.2.2 0x1c68ECfb,
DelayedWETH 2.0.0 (recover) and generation-1 0xE497B094 (hold), DisputeGameFactory.setImplementation, legacy L2OutputOracle
0xdfE97868 (deleteL2Outputs), OPContractsManagerV2.upgrade.

**Sequence executed.** `test_F01_targetMatrix` rows 16-30. Source-level sweep: grep over every tag v1.0.0..v9.0.0 for
`l2Sender()` / msg.sender==portal outside L2, validators and gas constants returns only ETHLockbox and L1CrossDomainMessenger.

**Barrier (per row, from the trace).** SystemConfig/DGF/ProxyAdmin/AddressManager: `Ownable: caller is not the owner` /
`ProxyAdminOwnedBase_NotProxyAdminOrProxyAdminOwner` (0xc4050a26); SuperchainConfig: `SuperchainConfig_OnlyGuardian` (0xafbe9bc6);
ASR v4: `AnchorStateRegistry_Unauthorized` (0x2e5321ac); old ASRs: selector absent (plain revert; their remaining setter
`setAnchorState` is guardian-gated in 1.x and validation-gated in 2.x, hist v1.8.0 src/dispute/AnchorStateRegistry.sol:107);
DelayedWETH: "DelayedWETH: not owner"; L2OO: "only the challenger address can delete outputs"; OPCMv2: revert.
After all 32 rows the keccak of 160+ authority/pause/custody/impl/admin reads across the four chains is identical.

**Evidence.** evidence/attack-wave/F/forge-test-vv.txt (trace: evidence/attack-wave/F/forge-test-vvvv.txt).
