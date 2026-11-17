# LIVE-OBJECTS-D — production objects matching the trojan-game preconditions

Scan: `scanproofs.py` + `enrich.py` (this dir) over OptimismPortal 0xbEb5Fc57… `WithdrawalProvenExtension1` logs,
L1 blocks 26383500..26433900 (7 days), via the archive proxy :7545. Output: `op-proofs-selection-scan.json`.
`lag_games` = (newest type-9 game index in the factory at block-1) − (game index in the prove calldata).

| Object | Chain | Address / hash | Block | Why it matches |
|---|---|---|---|---|
| Respected permissionless super type | OP | DGF 0xe5965Ab5…, type 9, bond 0.08 ETH | 26433900 | anyone can register a trojan (PoC) |
| Honest proposal cadence | OP | games 21383..21388, creators 0x4733…3A33 (89/100) and 0xc27b…5bE0 (11/100) | 26433900 | one game every ~3,624 s; `op-last100-games-creators.txt` |
| Proof population | OP | 242 proofs, 39 submitters, 241 direct `proveWithdrawalTransaction` calls | 26384576..26433490 | 137 used the newest game (lag 0), 51 lag 1 → 78% pick from the 1–2 newest games, the fingerprint of latest/random-over-a-small-pool tooling |
| Auto-prover (relayer) | OP | 0x431f5015b7c05fe792aea2a05158919af1e8ddf5 | same window | 135 proofs of L2CDM→L1StandardBridge withdrawals (125 `finalizeBridgeETH`, 8 ERC20) for 74 distinct users, 13.63 ETH; lag 0 ×96, lag 1 ×39; it is the proof submitter (users finalize via external proof or it does) — identity not established on-chain |
| Fixed-old-game provers | OP | 0xa7fad3a7…4dda (27, lag 774), 0xa84ff98f…1ddf (9, lag 643) | same window | always reuse one old resolved game → NOT exposed to trojans |
| Victim fixtures | OP | L1 txs 0xc57d4b53…, 0x815fbca2…, 0x2b8325aa…; fresh L2 tx 0x010c5082… | — | real pending withdrawals used in the PoC |

Ink / Unichain: same type-9 implementation and gameArgs (PRIM-0903), mechanism identical; not scanned for proofs.
Soneium: type 5 (proposer-gated) — not exposed.
