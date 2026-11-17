# LIVE-OBJECTS-C — production objects matching ATK-C preconditions

Population scanned (passive reads, local archive proxies):

| Scan | Range | Count | Max gasLimit | Max data | File |
|---|---|---|---|---|---|
| OP Mainnet `MessagePassed` (L2ToL1MessagePasser 0x42…16), every Bedrock-era withdrawal | L2 105,235,063 .. 159,654,093 | 35,579 (== `messageNonce` delta at the two blocks, complete) | 8,415,632 | 644 B | `messagepassed-scan-op.json`, `scan-op.log` |
| OP Mainnet legacy OVM-2 `SentMessage` (L2CDM) → migrated version-0 withdrawals | L2 0 .. 105,235,062 | 39,885 logs (legacy `messageNonce` = 139,885; the 100,000 offset predates the Nov-2021 regenesis and is not visible as logs) | migrated `B0 = 16·len + 1,300,873` → max ≈ 1.31 M (largest message 356 B) | 356 B | `legacy-sentmessage-scan-op.json` |

Edge of the deliverable region (measured, see `results.jsonl`): no OP Mainnet withdrawal ever created
comes within 2x of it. The objects nearest to the edge are the only ones with `gasLimit > 8M`:

| L2 block | withdrawalHash | kind | minGasLimit | gasLimit | value | status @ L1 26433900 | why it matches |
|---|---|---|---|---|---|---|---|
| 113,711,749 | `0x0adc3473dd8294ee774e763af2c9df4fe95c9f06d8140c61b06394a7fbab0dbe` | L2SB ERC20 withdraw → L1SB `finalizeBridgeERC20` (OS token `0x6100dd79…b771`, 26.5 OS to `0xd130…be91`) | 8,000,000 | 8,415,632 (Bedrock-era budget) | 0 | never proven, not finalized | m inside the forced-fail band (m ≥ 5.76 M for this budget generation) |
| 113,711,767 | `0x908556f7102b5037c6be3d8db42b6e627c439f6128dc79120adad63ea14464e3` | same | 8,000,000 | 8,415,632 | 0 | never proven | same |
| 113,711,779 | `0x5be066c469594a83e76a7b6809ca59e56436b55f464937567119b2eaf2b7bde1` | same | 8,000,000 | 8,415,632 | 0 | never proven | same |
| 113,711,803 | `0x067f9cb922fdfa18d93532ee8d3d2b243226b46c5562b643e4a6f891cd0506cf` | same | 8,000,000 | 8,415,632 | 0 | never proven | same |
| 115,891,218 | `0xd91ec183b9794540ee83f19c9f9ac73f6e351f0433acb7e7c10d270ac1c6b462` | same | 8,000,000 | 8,415,632 | 0 | proven L1 19,274,944, finalized L1 19,531,461 (success) | reference |

"never proven": no `WithdrawalProven` / `WithdrawalProvenExtension1` / `WithdrawalFinalized` log with
that hash on portal `0xbEb5…06Ed` in L1 blocks 18,000,000 .. 26,433,900 (same query returns the
reference object's prove and finalize logs). L1SB `deposits(OS, l2OS)` = 101,175.7 OS ≥ amount.
Decoded structs: `live-objects-8M.json`.
