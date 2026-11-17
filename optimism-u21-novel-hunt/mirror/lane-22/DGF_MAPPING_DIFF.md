# U21 DisputeGameFactory mapping diff (lane 22)

## Result

No layout corruption was found. `DisputeGameFactory` has a byte-identical storage snapshot in v7, v8, and v9. Its live implementation and init bonds were also unchanged across U21. The upgrade did, however, intentionally mutate dynamic `gameArgs` payloads that are not visible in a linear slot sweep:

- OP Mainnet type 5 changed only the proposer address.
- OP Mainnet, Ink, and Unichain type 9 changed only the first 32-byte `absolutePrestate`.
- Soneium kept respected game type 5 and has no type 9 implementation or arguments.

The mapping bases are `gameImpls` slot 101, `initBonds` slot 102, and `gameArgs` slot 105 (`op-v9.0.0/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json:37-70`). The owner-only setter writes both implementation and argument bytes and emits both events (`op-v9.0.0/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol:298-327`). `LibGameArgs` defines the packed fields and decoding offsets (`op-v9.0.0/packages/contracts-bedrock/src/dispute/lib/LibGameArgs.sol:9-23,42-103`) and the 40-byte super-permissioned ASR/proposer form (`.../LibGameArgs.sol:36-40,116-142`).

## Exhaustive live configuration check

At both N-1 (26430858) and N (26430859), types 0 through 10 were queried on all four factories. Only types 5 and 9 were nonzero; Soneium had only type 5. Values at later block 26433900 were also queried for types 5 and 9 and exactly matched N.

| Chain | Type | Implementation | Bond | N-1 → N payload delta |
|---|---:|---|---:|---|
| OP Mainnet | 5 | `0x5C3eb47cB0174aea522a2a9Ae79487139A53D691` | 0 | proposer `0x473300df21d047806a082244b417f96b32f13a33` → `0xc27ba3e0fc01567a5e57ae0c391aa98cecba5be0`; ASR unchanged |
| OP Mainnet | 9 | `0x19AF533Cc2A2A55786DCB8672aA5717e64213208` | 0.08 ETH | `absolutePrestate` changed; VM, ASR, WETH, and chain-id bytes unchanged |
| Ink | 5 | `0x5C3e…D691` | 0 | no change |
| Ink | 9 | `0x19AF…3208` | 0.08 ETH | same `absolutePrestate` delta; remaining fields unchanged |
| Soneium | 5 | `0x5C3e…D691` | 0 | no change; this is the respected type |
| Soneium | 9 | zero | 0 | empty before and after |
| Unichain | 5 | `0x5C3e…D691` | 0 | no change |
| Unichain | 9 | `0x19AF…3208` | 0.08 ETH | same `absolutePrestate` delta; remaining fields unchanged |

Type 9 first word:

```text
N-1  0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df
N    0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9
```

OP type 5 full payload:

```text
N-1  0x23b2c62946350f4246f9f9d027e071f0264fd113473300df21d047806a082244b417f96b32f13a33
N    0x23b2c62946350f4246f9f9d027e071f0264fd113c27ba3e0fc01567a5e57ae0c391aa98cecba5be0
```

Type 9 full payloads (the per-chain ASR/WETH suffix is shown explicitly):

```text
OP N-1 0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1dfacc005dcd857b401e4732e6f7837135a22825cfa23b2c62946350f4246f9f9d027e071f0264fd1131b6dbf05eaf22d4e70dc993e8a19dd9f3dcb31620000000000000000000000000000000000000000000000000000000000000000
OP N   0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9acc005dcd857b401e4732e6f7837135a22825cfa23b2c62946350f4246f9f9d027e071f0264fd1131b6dbf05eaf22d4e70dc993e8a19dd9f3dcb31620000000000000000000000000000000000000000000000000000000000000000

Ink N  0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9acc005dcd857b401e4732e6f7837135a22825cfaee018baf058227872540ac60efbd38b023d9dae257b4c29daee99a28e6e86778b499361294c134ea0000000000000000000000000000000000000000000000000000000000000000
Unichain N 0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9acc005dcd857b401e4732e6f7837135a22825cfa27cf508e4e3aa8d30b3226ac3b5ea0e8bcacaff974ad145ac900f1dd5551f0c9e143314dc4022fcf0000000000000000000000000000000000000000000000000000000000000000
```

## Killing fact

The changed bytes decode cleanly under the same v9 schema; no field boundary moved, no implementation/bond changed, Soneium's type-5 configuration was preserved, and the N values remained stable through 26433900. This is an owner-driven configuration update, not silent storage reinterpretation. See `REJ-2205`.
