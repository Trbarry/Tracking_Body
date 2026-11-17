# ATTACK-T3-05 — L1ERC721Bridge releases an escrowed NFT to someone other than the party the L2 burn designated

Lane ATK-T3 (bridge token identity / L1ERC721Bridge / OptimismMintableERC20Factory), Opus 5.5 (CLAUDE.md exception, Mythos 5.2 quota until 2026-11-22). Sources: op-contracts v9.0.0 (`/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src`). PoC: `test/poc/attack-wave/T3/test/T3.t.sol`; run output `evidence/attack-wave/T3/forge-final.txt` (9/9 PASS). Kill type: failing experiment + full escrow census.

**Hypothesis.** A fake L2 NFT (claims `remoteToken() = N`, `ownerOf` = attacker, no-op burn) or a re-key of the escrowed id under an
attacker remote on L1 releases an escrowed NFT; or a second release of one burn.

**Sequence executed** (`test_C1_erc721_identityAndRecipient`): honest deposit of N#7 for HN (real L2 ERC721 factory token); attacker
`L1NB.bridgeERC721To(N, 0xBEEF, attacker, 7)` reverts (from != owner); on L2 the deployed L2ERC721Bridge 1.10.1 emits
`finalizeBridgeERC721(N, fake, …, 7)` for the fake; attacker cannot bridge HN#7 he does not own; honest owner burns HN#7 with
`_to = 0xDE57`. On L1: fake withdrawal portal-finalizes and fails (also on replay), NFT stays escrowed; honest withdrawal releases
N#7 to exactly 0xDE57; re-finalizing the same withdrawal reverts. `test_C2`: real escrow 0xE42c…/0x899e…#24900 flag true,
other-remote key false; direct `finalizeBridgeERC721` by EOA or by the L1CDM outside a relay reverts.

**Barrier.** `src/L1/L1ERC721Bridge.sol:103-114` (exact (local, remote, id) bit, cleared before transfer to the committed `_to`),
`ERC721Bridge.sol:64-69` (onlyOtherBridge), L2 `L2ERC721Bridge` builds the message with the burned token's own address.
**Census** (`LIVE-OBJECTS-T3.md` section 3): 14,263 outstanding escrows (2,297 pairs, OP only; Ink/Soneium/Unichain 0 events),
14,263/14,263 flags true at slot 49 (layout continuous since 2022), 14,261 bridge-owned; 2 anomalies are third-party NFT logic
(out of authorization). KILLED.
