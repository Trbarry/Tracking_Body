# Lane 24 U21 proxy / implementation map

Pinned sources:

- v7 `a7c88c8d636ceb9944ea0edaf7d033da258778ab`
- v8 `f45a5ccfebcdf6da3f5b09cbc512667c063730b7`
- v9 `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`
- U21 tx `0x024770b5fba87683ee1466562eefb1bcb408c29c764e24abd07c7d4050a82a99`, block 26,430,859, receipt status 1.

## Relevant implementations

| Proxy | N-1 (26,430,858) | N (26,430,859) | Later (26,433,900) | Read method |
|---|---|---|---|---|
| OptimismPortal `0xbEb5…106Ed` | v5.8.0, `0x1005217ad392dc64cef501fa1777a27d42166748` | v6.1.0, `0xb20b23af6071405c37ddda0c0640e8ebb7899645` | same as N | EIP-1967 implementation slot + `version()` |
| L1CrossDomainMessenger `0x25ac…5fA1` | v2.11.1, `0x59D497530b00062f40950ba8EaB88868bf7F86f0` | v2.13.0, `0x7d4Ec7fB1A1b9e6D61c04d5e21E3d68cfF639448` | same as N | ProxyAdmin `0x543b…fB04.getProxyImplementation` + `version()` |

The messenger is a ResolvedDelegateProxy, so its EIP-1967 implementation slot reads zero; the ProxyAdmin getter is the authoritative implementation read.

## Portal wiring across the boundary

All three pinned states returned:

- SystemConfig `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290`
- AnchorStateRegistry `0x23B2C62946350F4246f9f9D027e071f0264FD113`
- ETHLockbox `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43`
- Portal/ASR/Lockbox paused: false
- ETH_LOCKBOX=true, CUSTOM_GAS_TOKEN=false, INTEROP=false
- Portal authorized by Lockbox: true

ASR values remained factory `0xe5965Ab5962eDc7477C8520243A95517CD252fA9`, respected type 9, retirement `1753379243`. The anchor game was `0x5102…eB1D` at N-1/N and advanced normally to `0x55A5…6f95` later.

## Storage compatibility

The v8/v9 storage-layout snapshot files are byte-identical:

| Layout | SHA-256 in both tags |
|---|---|
| OptimismPortal2 | `a8b04aeff8ef632889b997eeed7f367b4606e87593fb38d7fb86751a01f2547b` |
| L1CrossDomainMessenger | `75f195d43e2bd630561b6ac743722b458961a3603dab1756b151a4a4659a963c` |

Relevant state is therefore interpreted at unchanged slots: Portal finalized mapping 51, per-submitter proof mapping 57; messenger successful mapping 203 and failed mapping 206.
