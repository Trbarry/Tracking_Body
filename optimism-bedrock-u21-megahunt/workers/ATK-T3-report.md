# ATK-T3 report — bridge token identity, L1ERC721Bridge, OptimismMintableERC20Factory

Model: **Opus 5.5** (`claude-opus-5-5`, CLAUDE.md exception: Mythos 5.2 quota exhausted until 2026-11-22 00:00 UTC).
Targets: OP Mainnet L1StandardBridge 2.8.2 `0x99C9…4bE1`, L1ERC721Bridge 2.9.1 `0x5a77…f23D`, OptimismMintableERC20Factory
1.11.0 `0x7550…Fa0F` (+ Ink/Soneium/Unichain siblings for the censuses). Result: **0 candidates, 8 kills** (`rejected/ATTACK-T3-01..08.md`).

PoC: `test/poc/attack-wave/T3/` (README has the command) — 9 fork tests, all PASS (`evidence/attack-wave/T3/forge-final.txt`).
Evidence: `evidence/attack-wave/T3/` (censuses, traces, `LIVE-OBJECTS-T3.md`).

| id | hypothesis | command / test | result | verdict |
|---|---|---|---|---|
| E01 | L1-mintable tokens exist with value (precondition for fake-remote mint) | `scripts/factory_scan.py` (4 L1 factories, 17.0M..26.43M) | OP 4 tokens, siblings 0; all L1 supply 0 | kill T3-02 |
| E02 | pair population of the OP L1SB | `scripts/l1sb_scan.py` ERC20BridgeFinalized since Bedrock | 13,992 withdrawals, 143 pairs | input |
| E03 | (a) deposits[l1][l2] < L2 supply for a real pair | `scripts/pair_census.py` | 131 covered; 7 self-test fake pairs (pWBTC/VIC) bounded by own deposits; 4 wrong-pair escrows (USDC->native USDC 205.75, DAI 61,210.94, SNX 102.5, rETH 8.89) | kill T3-04 (known foot gun) |
| E04 | ERC165Checker semantics change detection for a real L1/L2 token | `scripts/erc165_fix.py` | L1: 0/143 mintable (TheDAO answers 0xffffffff=true -> non-ERC165, consistent); L2: 139 mintable | kill T3-02/03 |
| E05 | real L2 token with l1Token() != remoteToken() | census on E03 rows | 0 disagreements (90 legacy-only, 47 both, 1 new-only) | kill T3-03 |
| E06 | fake L2 tokens (both/split/new-only/non-ERC165/legacy withdrawTo) release honest escrow | `test_B1_fakeL2Tokens_cannotReleaseHonestEscrow` | 5/5 portal-finalized, 5/5 failed at StandardBridge.sol:292 (panic 0x11), replays fail, escrow intact | kill T3-01 |
| E07 | per-pair barrier exactness (positive control) | `test_B2_perPairBarrier_isExact_selfFundedOnly` | self-funded 10 withdrawn exactly, +1 fails | kill T3-01 |
| E08 | fake remote mints L1-factory token; codeless remote escrow | `test_B3_l1Mintable_remoteIdentityBound` | fakes fail `_isCorrectTokenPair`; only M.remoteToken() mints; codeless remote reverts on L2 (OZ Address.sol:135) | kill T3-02 |
| E09 | ERC721 escrow census (4 chains) | `scripts/nft_scan.py` | OP 14,661 init / 398 fin; siblings 0 | input |
| E10 | ERC721 escrow flags lost across layouts | `scripts/nft_census.py` (slot 49) | 14,263/14,263 true | kill T3-05/06 |
| E11 | escrowed NFTs not held by the bridge | `scripts/nft_owner.py` (ownerOf, passive) | 14,261 bridge; 2 third-party-logic anomalies (out of authorization) | kill T3-05 |
| E12 | fake L2 NFT / L1 re-key / wrong recipient / double release | `test_C1_erc721_identityAndRecipient` | all refused; release only to L2-designated `_to` | kill T3-05 |
| E13 | real escrow key + direct finalize auth | `test_C2_realEscrow_flags_and_auth` | flag true (id 24900), other key false, direct calls revert | kill T3-05 |
| E14 | ERC721/L1SB pause source diverges from portal | `test_C3_pauseSource_consistent` + layout history v1.2.0..v9 | same SystemConfig 0x2290…B290; deposits slot 49 every version | kill T3-06 |
| E15 | U21 changes bridge outcomes (new format) | `test_D1_u21_differential_sameOutcomes` (l1pre 2.11.1 vs l1 2.13.0) | identical F,F,T,T | kill T3-07 |
| E16 | U21 changes migrated legacy-format outcome (v0 nonce, finalizeERC20Withdrawal) | `test_D2_legacyFormat_prePost_sameOutcome` | identical; honest paid once, fake fails | kill T3-07 |
| E17 | bridge/messenger semantic delta v8->v9 | source diff | bridges formatting-only, byte-identical impls; L1CDM gas constants only | kill T3-07 |
| E18 | factory squat / remote or bridge rebind | `test_F1_factory_identity_cannotBeRebound` | CREATE2 commits to all identity fields; no setter; initializer refused | kill T3-08 |
| E19 | sibling chains: L1-mintable tokens in active pairs | L1-only pair census Ink/Soneium/Unichain | Ink 0, Soneium 6, Unichain 15 pairs; 0 mintable | supports T3-02 (L2 half not checkable: no L2 RPC) |

Stopped / not done (and why):
- Wrong-pair escrows (USDC->native USDC, DAI, SNX) and the two odd NFT escrows: impact would run through third-party tokens and
  the depositor's own error -> recorded as passive context only, not tested on a fork (CADRE-LEGAL section 4).
- L2-side supply census for Ink/Soneium/Unichain: no L2 RPC for those chains in this infra.
- No safety-system stop occurred.

Highest-value next experiment: a census of pre-Bedrock (legacy, version-0) L2->L1 bridge withdrawals that were never relayed
(L2ToL1MessagePasser `sentMessages` is permanent), joined with today's `deposits` per pair, to find any pair whose outstanding
legacy claims exceed its current L1 escrow (the only path where two generations of messages could compete for one escrow);
then replay the largest such object with `test_D2`'s harness on `l1`.
