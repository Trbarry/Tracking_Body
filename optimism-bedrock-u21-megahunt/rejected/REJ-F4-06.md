REJ-ID: REJ-F4-06
Title: "A historical pause bit or deprecated config slot still set on OP Mainnet is read by v9 (portal `paused` slot 53[0], SuperchainConfig v1 hashed `paused`/`guardian`, SystemConfig `l2outputoracle`/`disputegamefactory`/`batchinbox`/gas-token, portal 56/58/59)"

Killing fact
- Values: portal slot 53[0] = 1 only 19233786 .. 19234081 (cast storage), 0 since; SuperchainConfig hashed `paused` = 1
  only 22482108 .. 22482159, hashed guardian zeroed by `upgrade()` at 22990599; SystemConfig `l2outputoracle` zeroed
  20062696, `disputegamefactory` zeroed 22990599, `batchinbox` zeroed 26048619; gas-token slots never written; portal 56
  (= DGF) and 59 (`0x66e1c083 00000000`) still non-zero, 58 never had an entry (0 `DisputeGameBlacklisted` logs).
- Readers: none in v9 production code (grep of sload/sstore/Storage.get*/vm.load over src at ba6fcadb, §5 of
  `STORAGE-ARCHAEOLOGY.md`); semantic poison of every one of them (paused = 1, guardian = attacker, blacklist[game] = 1,
  respectedGameType|UpdatedAt = max, superRootsActive = 1, deprecated hashed slots = junk) leaves getters, a real 119.6 ETH
  withdrawal and a deposit identical (`test_poisonedPreV7Slots_realWithdrawalAndDepositAreUnchanged`, PASS).
- `Paused(0x758e0ee6…)` at 25689317 targets a portal 5.2.0 of another chain (systemConfig 0xD3d4c6B7…), expired
  (`paused(addr) = false` @26433900); handed to B06.
