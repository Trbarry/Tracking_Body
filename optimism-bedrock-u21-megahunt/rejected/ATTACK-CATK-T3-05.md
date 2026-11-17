# ATTACK-CATK-T3-05 — ERC721 pair/token confusion or callback releases the wrong NFT

Model: Codex, configured by the worker brief as `gpt-daybreak-blue-latest`.

Verdict: **KILLED — exact triple, committed recipient, clear-before-call, global replay guard.**

## Hypothesis

A malicious L2 ERC721 reports a mutable remote, substitutes a token ID or recipient, or reenters from
`safeTransferFrom` so L1ERC721Bridge releases a victim NFT deposited for another pair or releases the same NFT twice.

## Exact sequence tried

Deposit two locally owned NFTs through deployed L1ERC721Bridge using different remote addresses and assert all four
`(local,remote,id)` cells. Attempt direct finalization as an unprivileged caller. Then prove and finalize a real old OP
ERC721 withdrawal on both N-1 and post-U21 forks, measuring the escrow bit and `ownerOf`, followed by a second finalize.

## Barrier

The mapping is keyed by `(local,remote,tokenId)` (`L1ERC721Bridge.sol:28`). Finalize is `onlyOtherBridge`, requires the
exact bit, clears it before the external safe transfer, and transfers only to message field `_to` (`:88-117`). The real
withdrawal changed only its exact bit and delivered token 36,383 to committed recipient `0x1129DA…b3ec`; portal replay
failed. An attacker-created L2 NFT can affect a victim only if that victim voluntarily deposited into that exact
attacker-selected pair, the documented object-selection footgun rather than a permissionless bridge bypass.

## Evidence

- PASS: `test_erc721Deposit_isIsolatedByExactPairAndTokenId`.
- PASS: both `*inFlightERC721_deliversCommittedRecipientOnce` tests.
- Real object/proof: `mirror/CATK-T3/evidence/LIVE-OBJECTS-CATK-T3.md`.
