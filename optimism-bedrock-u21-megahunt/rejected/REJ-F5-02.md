REJ-ID: REJ-F5-02
Title: "OP-only legacy storage (OVM / L2OutputOracle era) is reinterpreted by v9 and makes OP behave differently from Ink / Soneium / Unichain"

Idea
- At 26433900, four legacy slots are non-zero on OP Mainnet only: OptimismPortal2 slot 54 = 0xdfe97868… (L2OutputOracle),
  L1CrossDomainMessenger slot 51 = 0x9ba6e03d… (OVM owner), slot 151 = 1 (OVM reentrancy status), L1StandardBridge slot 1 =
  0x4200…0010 (legacy l2TokenBridge). Soneium has portal slot 59 = 1 (legacy respected type) where the others have 0.

Killing fact
- In v9 every one of these is a `spacer_*` (op-v9.0.0 snapshots/storageLayout/OptimismPortal2.json slots 54/59,
  L1CrossDomainMessenger.json 51/151, L1StandardBridge.json 1). `grep` of op-v9.0.0 src/L1 and src/dispute for those spacer names,
  `sload(`, `vm.load` or `StorageSlot` finds no reader. The respected type is read from the ASR (L1/OptimismPortal2.sol:340).
- PASS A lane 02 `U21StorageReinit.t.sol` fills every legacy slot with junk on all four chains: 16 getters and a live deposit
  unchanged (closure C2).
- The same permissionless sequence on the four chains (`test/F5/F5_ChainHistoryDifferential.t.sol`) differs only in the game-type
  set (Soneium is permissioned).

Evidence
- chains/<CHAIN>/STATE-U21.json `legacySlots`; CHAIN-HISTORY-DIFFERENTIAL.md rows D5 and D6.
