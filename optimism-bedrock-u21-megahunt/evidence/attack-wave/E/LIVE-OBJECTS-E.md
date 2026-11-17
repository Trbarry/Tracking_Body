# LIVE-OBJECTS-E — production objects matching ATK-E preconditions (L1 block 26433900)

| chain | object | address / id | why it matches | ATK-E result |
|---|---|---|---|---|
| OP | gen-2 ASR v2.2.2 (orphaned U16) | 0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b, anchor 0x9C9ac0A3… | permissionless `setAnchorState` accepts live-registry game #20094 | moved by attacker (P1); never read by migrate (E-01) |
| UNI | gen-2 ASR v2.2.2 | 0xD5D0e176be44E61eaB3Cf1FA8153758dF603376f, anchor 0xcD1f9c0F… | accepts game #16394 | same |
| OP / UNI | gen-0 ASR v2.0.0 | 0x18DAc71c…e443 / 0x318A642d…643B | only writers: game-only `tryUpdateAnchorState`, guardian `setAnchorState` | not writable (E-02) |
| OP / UNI | live per-chain ASR | 0x23B2C629… (anchor 0x55A5CFd4…) / 0x27Cf508E… (anchor 0x944a783a…) | permissionless `setAnchorState`; re-initialised by migrate | no newer claim-valid game in the last 150; carried unchanged (E-04) |
| OP / UNI | per-chain DGF type 9 | 0xe5965Ab5… / 0x2F12d621…, bond 0.08 ETH | permissionless game creation up to the migration block | attacker games inert after migrate (E-05) |
| OP / UNI | per-chain lockbox | 0x322b47Ff… / 0x08bA0023… (182,541 / 18,266 ETH) | swept by migrate; forced-ETH target | conservation exact (E-03) |
| OP / UNI | portals | 0xbEb5Fc57… / 0x0bd48f6B… | `donateETH`, `depositTransaction`; validator MIG-150 | swept; post-migration 1 wei trips validator only (E-08, known) |
| OP | 6 legacy DelayedWETH | 0xE497B094, 0x9F9b897e, 0x82511d49, 0x323dFC63, 0xe214879a, 0xD061AB95 | permissionless deposit/self-unlock | not read by migrate (E-03) |
| UNI | 5 legacy DelayedWETH | 0x7d8Ea656, 0x84B268A4, 0xc9edb4E3, 0xa0157F07, 0x0bdbEc6b | same | same |
| OP / UNI | current DelayedWETH | 0x1B6DBF05… (becomes SHARED) / 0x74ad145a… (orphaned by SC) | re-initialised with the shared lockbox | identical writes clean vs poisoned |
| — | future shared lockbox/ASR/DGF (fork, same block) | 0x8cc1eE88… / 0x8A8053d2… / 0x52006e78… | CREATE2 from the Safe, salt mixes block.timestamp | pre-funding is surplus only (E-06) |
