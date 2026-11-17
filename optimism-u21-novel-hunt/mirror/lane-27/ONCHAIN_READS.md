# Selected raw on-chain reads

All Ethereum calls below were passive `cast call`, `cast storage` or `cast code` reads against the pinned local forks. OP L2 header checks were passive reads; no transaction was sent.

## OP DGF at block N (`http://127.0.0.1:8547`)

```text
gameImpls(5) = 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691
gameArgs(5) =
0x23b2c62946350f4246f9f9d027e071f0264fd113c27ba3e0fc01567a5e57ae0c391aa98cecba5be0
initBonds(5) = 0

gameImpls(9) = 0x19AF533Cc2A2A55786DCB8672aA5717e64213208
gameArgs(9) =
0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9
  acc005dcd857b401e4732e6f7837135a22825cfa
  23b2c62946350f4246f9f9d027e071f0264fd113
  1b6dbf05eaf22d4e70dc993e8a19dd9f3dcb3162
  0000000000000000000000000000000000000000000000000000000000000000
initBonds(9) = 80000000000000000
```

Implementation reads:

```text
type-5 version() = "1.1.0"
type-9 version() = "0.8.0"
keccak(type-5 runtime) = 0xebf3dbbb410aa4e43f71d535fd6a0562eed700dd0de81cbcec047235889a41c9
keccak(type-9 runtime) = 0xa001bf4f37eca0afb87782c343553ea10ae7e8222b8da5b36bc5e1840698539c
```

At N-1, only these packed fields differed:

```text
type-5 proposer = 0x473300df21D047806A082244b417f96b32f13A33
type-9 prestate = 0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df
```

## Proxy implementation slot

EIP-1967 slot `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`:

```text
Portal N-1: 0x1005217ad392dc64cef501fa1777a27d42166748
Portal N:   0xb20b23af6071405c37ddda0c0640e8ebb7899645
ASR N-1:    0x8f40cc98d694ab986f026c5383a181fcc9b6b281
ASR N:      0x2b27299c577d4720100e2735b652444dcea652d0
```

## Anchor sequence

```text
N-1 and N:
anchorGame = 0x51024A83c2F94c8e70014A732d3e2559CdceeB1D
root       = 0x1780727e85b9a6a2f265739802b24afdeb1d3f86b6f8b0bdd762c7b0c6ff0846
sequence   = 1794262423

block 26433900:
anchorGame = 0x55A5CFd4270340b3822BB9D8eebdb450ac206f95
root       = 0xca640c8db165091618e7edc23995b250d4b3e6dfbe918bded900a38efbf76fbc
sequence   = 1794298459

all blocks: respectedGameType = 9; retirementTimestamp = 1753379243
```

## Old-game boundary and semantic samples

```text
index 9827: type 0, created 1753378031, game 0x9Ff603b362aF09d9080E215dB2A4Ba87acFE3a78,
            status DEFENDER_WINS, current isGameClaimValid=false
index 9828: type 0, created 1753381655, game 0x5812F56173A63B83664077c5210b55D6195411bd,
            status DEFENDER_WINS, sequence 138890875, current isGameClaimValid=true,
            root 0xe8ac8315972844981318ce2417cb99da047d0eb9380c61a1d4f67e63bdf6458a
```

For every row below, the on-chain game was `DEFENDER_WINS`, current-ASR claim-valid, and the root exactly matched the canonical OP L2 header computation:

| index | type | L2 sequence | root |
|---:|---:|---:|---|
| 10000 | 0 | 139200286 | `0xf0f6825f0d972b90dc7437dec4e69bef604d5eeaf058608a5ebaa32a6e97d8a2` |
| 12000 | 0 | 142798226 | `0x6b396ea59f20774949adbfdc0f23f96efa260fc1d3c2e42ce7647a0874eadcd3` |
| 14000 | 0 | 146395810 | `0xfcda946addf9e058a6994f07abd75e89752a65f8d515210413a17040278320ef` |
| 16000 | 0 | 149992881 | `0x120db768b7d899f61825b2836c7cae831e944fcb8ed8579af1563ff88e7ec6a9` |
| 17904 | 0 | 153413384 | `0xd3843039a4d640135e6bd3892ea2386540cdb5dc9c7a86e8d06507561f90b8cb` |
| 18500 | 8 | 154487708 | `0x5ace2178cfbaa6dedb717e2839c49c053ad5bd978508e39c5277c79398382009` |
| 20000 | 8 | 157167617 | `0xa0ce3a573b371121040a74b270e2627baf4dc037f7ad78fdcc28f691c29a075a` |
| 20094 | 8 | 157333888 | `0xe65aa4d63b3c23df95c8ee9afa27157ad8ef6c7d367d4bd928aa6eb3021a3a27` |

## Migration inputs currently wired on chain

```text
OP:  chainId=10,  portal=0xbEb5Fc579115071764c7423A4f12eDde41f106Ed,
     PA=0x543bA4AADBAb8f9025686Bd03993043599c6fB04,
     ASR=0x23B2C62946350F4246f9f9D027e071f0264FD113,
     DGF=0xe5965Ab5962eDc7477C8520243A95517CD252fA9
UNI: chainId=130, portal=0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2,
     PA=0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4,
     ASR=0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9,
     DGF=0x2F12d621a16e2d3285929C9996f478508951dFe4
both PA owners = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A
both SCC       = 0x95703e0982140D16f8ebA6d158FccEde42f04a4C
both last OPCM = 0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f, version 9.0.3
```
