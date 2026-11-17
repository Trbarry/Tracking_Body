# ATK-T2 report — legacy carry-through (OVM 1.0 / OVM 2.0 / pre-fault-proof objects consumed by v9)

Model: **Opus 5.5** (`claude-opus-5-5`, CLAUDE.md exception: Mythos 5.2 quota exhausted until 2026-11-22 00:00 UTC).
Candidates: **0**. Kill files: `rejected/ATTACK-T2-01..06.md`. Fork tests: `test/poc/attack-wave/T2/` (9/9 PASS,
`evidence/attack-wave/T2/fork-test-output.txt`). Live objects: `evidence/attack-wave/T2/LIVE-OBJECTS-T2.md`.
Scripts: `scripts/attack-wave-T2/`. All RPC read-only through :7545/:7546 (~260 getLogs/getProof/getBlock calls,
~34k eth_call/getStorageAt in 50-request batches); state changes only inside `forge test` forks. Nothing broadcast.

Fork vehicle: real OP game #21388 (`0x668513Ab…`, L2 159,653,251) — output root recomputed from L2 header + `eth_getProof`
(= `rootClaimByChainId(10)` 0x05bfbbc4…); real storage proofs for each object; honest resolution by warp; unprivileged
submitter and finalizer. Note: the L2 proof window of :7546 is ~120k blocks, so fresh proofs must be fetched near head
(`build_fixtures.py`); the saved fixtures make the tests deterministic.

| # | Hypothesis | Command / test | Result | Verdict |
|---|---|---|---|---|
| E1 | census OVM 2.0 legacy messages | `legacy_census.py` (39,885 SentMessage, L2 0..105,235,062) | migration hash recomputed; 1,409 + 4 finalizations match | data |
| E2 | census OVM 1.0 migrated messages | `ovm1_census.py` (`ovm-messages.json`, 17,924) | 204 finalizations + 12 proofs match | data |
| E3 | L1 relays outside the scanned messenger history | binary search of L1CDM code; join 20,292 legacy RelayedMessage | proxy born 12,686,757; 12,780 + 7,512 = 20,292, none unmapped | T2-01 |
| E4 | pre-Bedrock relay invisible to v9 legacy branch (slot/proxy) | `storage_check.py` successfulMessages(v0) x20,292 | all true | T2-01 |
| E5 | migrated objects not live / formula wrong | sentMessages for 13,312 unrelayed (all value-bearing) | 13,312/13,312 live | T2-02 |
| E6 | Bedrock-era census by era/version/value/target/gas | `bedrock_census.py` (35,579) | 11,196 never finalized; 0 unsafe targets; all nonce v1; max gas 8.4M | T2-03, T2-04 |
| E7 | game root built from real L2 state | output root recompute (cast + script) | equal to game 21388 claim | vehicle |
| E8 | already-paid OVM 1.0 v0 (600 ETH) paid again | `test_T2a_ovm1_relayed_v0_600ETH_blocked` | proof OK, finalize reverts L1CDMCallFailed, 0 delta | KILL T2-01 |
| E9 | already-paid OVM 2.0 v0 (35,555.8 ETH) paid again | `test_T2a_ovm2_relayed_v0_35555ETH_blocked` | same | KILL T2-01 |
| E10 | unrelayed OVM 1.0 v0 (25.7 ETH) delivered with other meaning / twice | `test_T2a_ovm1_unrelayed_v0_deliveredOnce` | exact, once; replay reverts | KILL T2-02 |
| E11 | unrelayed OVM 2.0 v0 | `test_T2a_ovm2_unrelayed_v0_deliveredOnce` | exact, once | KILL T2-02 |
| E12 | oldest Regolith messenger withdrawal (old baseGas) | `test_T2b_bedrock_regolith_messenger_deliveredOnce` | exact | KILL T2-04 |
| E13 | Ecotone direct withdrawal | `test_T2b_ecotone_direct_eoa_deliveredOnce` | exact | KILL T2-04 |
| E14 | Isthmus fee-vault withdrawal 11.44 ETH | `test_T2b_isthmus_direct_feevault_deliveredOnce` | exact | KILL T2-04 |
| E15 | legacy pair over-release | `bridge_pairs.py` (324 pairs, escrow vs events) | 0 mismatches | KILL T2-05 |
| E16 | L2 supply vs L1 escrow | `l2_supply_vs_escrow.py` + mint/burn log sum | 8 apparent excesses explained (third-party bridge / non-standard totalSupply) | KILL T2-05 |
| E17 | escrow re-classified as mintable (ERC165, full checker semantics) | eth_call 0x01ffc9a7/0xffffffff/0x1d1d8b63/0xec4fc8e3 on 3 flagged tokens + L2 twin reads | 1 real object (EDU 90,170e18) | T2-06 |
| E18 | EDU escrow release under v9 | `test_T2c_legacyEscrowPair_reclassifiedMintable_frozen` | mint branch, token mint reverts, escrow frozen | KILL T2-06 (no impact, no attacker) |
| E19 | negative control | `test_T2c_negativeControl_nonMintableLegacyPair_releases` | WBTC pair releases exactly | control |

Side results: closes the unscanned legacy half of ATTACK-C-07 (max migrated gasLimit 1,310,665); unclaimed legacy ETH
liability 491.895 ETH (13,012 objects) + Bedrock-era never-finalized 6,253 ETH — inputs for lead L9 (lockbox vs L2
liability). Stopped lines: none by a safety system. Out of authorization (recorded, not pursued): 21,608 unrelayed legacy
messages to third-party L1 targets (Synthetix, DAI bridge, etc.) and custom-token pair semantics.
