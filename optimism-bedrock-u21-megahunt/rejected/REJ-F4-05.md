REJ-ID: REJ-F4-05
Title: "Some historical upgrade left a proxy uninitialised across a transaction boundary, or a still-deployed implementation can be initialised by anyone in a way that matters"

Killing fact
- Every `Upgraded(StorageSetter)` and the following `Initialized` on 15 OP Mainnet proxies are in one transaction
  (`evidence/F4/op-all-proxies-upgraded-initialized.jsonl`, 236 logs, 17,300,000 .. 26,433,900, 0 failed chunks) and all 49
  ProxyAdminOwner Safe executions were traced (`op-proxyadminowner-safe-exec-classified.json`). Proxy creations had no
  implementation until the initialising `upgradeToAndCall` (calls revert in `Proxy._doProxyCall`). Ink / Soneium / Unichain
  portals: implementation set and `_initialized = 1` in the same block (cast @21344310 / 21314185 / 21116362).
- Implementations with slot 0 = 0 (L1StandardBridge 1.1.0 0xbfb731cd…, L1ERC721Bridge 1.0.0 0x3268ed09…, factories
  1.1.0/1.8.0, StorageSetters, one-off 0x6d971b07…): balance 0, no DELEGATECALL / SELFDESTRUCT opcode (cast disassemble
  @26433900); initialising them changes only their own storage, which no proxy reads.
- Limit: L1StandardBridge (ChugSplash `setStorage` emits no event) and L1CDM between 2023-06-06 and 2024-02-26 are covered
  only by the 20k-block sampler + `Initialized` census, not by traces.
