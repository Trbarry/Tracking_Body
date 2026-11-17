# ATTACK-T4-03 — Malformed TransactionDeposited encodings that kona and op-node decode differently

Lane ATK-T4. Model: Opus 5.5 (`claude-opus-5-5`, user-approved exception; Mythos 5.2 quota exhausted until 2026-11-22). All runs are local pure computation or passive reads through :7545/:7546. Harness: `test/poc/attack-wave/T4/` (kona-client v1.7.0 = old type-9 prestate 0x031ac6f1, kona-client v1.9.0 = new prestate 0x03e5a548, each built with its own tag Cargo.lock — 0 package versions outside the tag lock; op-node = /home/user/ethereum-optimism/op-v9.0.0).

**Real divergences found (both kona versions identical; all explained, `evidence/attack-wave/T4/synthetic-divergence-classes-seed*.txt`).**
| shape | kona (deposits.rs) | op-node (deposit_log.go) |
|---|---|---|
| non-zero ABI padding after opaqueData | rejects `InvalidOpaqueDataPadding` (:181) | accepts (no padding check) |
| extra 32-byte words after the padded opaqueData | accepts (ignores trailing data) | rejects, minimal-padding length check (:71) |
| non-zero high 12 bytes in the `from`/`to` topic | rejects `FromDecode` (:115) | truncates (`BytesToAddress(ev.Topics[1][12:])`, :52) |
| mint ≥ 2^128 | keeps the low 128 bits (`raw_mint = data[16..32]`, :220-223) | keeps the full big.Int |

**Hypothesis.** An attacker makes the deposit contract emit one of these shapes; kona and op-node then derive
different blocks (or op-node halts with a critical error), letting an invalid claim win.

**Barrier (no producer).** The only emitter is `OptimismPortal2.depositTransaction`:
`opaqueData = abi.encodePacked(msg.value, _value, _gasLimit, _isCreation, _data)` (`OptimismPortal2.sol:790`)
then `emit TransactionDeposited(from, _to, DEPOSIT_VERSION, opaqueData)` (:794). Solidity ABI-encodes the event's
`bytes` with offset 32, exact length and zero padding, and `from`/`_to` are `address` topics (high bytes 0).
`msg.value` is bounded by the caller's ETH balance (total supply < 2^87 wei), so mint ≥ 2^128 cannot occur.
derive_deposits filters on `address == deposit_contract_address` (stateful.rs:302; op-node `UserDeposits`), so no
other contract can inject a log. Real check: the scan found 1,669 portal deposit logs in 1,609 L1 blocks of
L1 26,380,000–26,430,700 (`evidence/attack-wave/T4/deposit-scan-26380000-26430700.json`); every deposit in the 190
sampled epochs (167 in the game windows + the 23 heaviest) was decoded identically to the canonical block.

**Verdict.** KILL (unreachable precondition). The divergences are latent robustness differences only; recorded for the
researcher, not reportable (no in-scope impact, no producer). Score 0.
