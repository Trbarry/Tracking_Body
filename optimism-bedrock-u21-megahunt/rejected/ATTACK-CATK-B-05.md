# ATTACK-CATK-B-05 — ERC721 ordering lets another caller consume the escrow

## Hypothesis

After forced failure but before replay, another withdrawal or caller consumes the same NFT escrow bit, permanently blocking the victim or capturing the NFT.

## Exact sequence tried

Read the deployed OP L1ERC721Bridge configuration on the pinned fork and attempted direct finalization from the unprivileged attacker in `test_deployedERC721BridgeRequiresMessengerAndCommittedL2Bridge`. Audited the v9 finalization transition and replay authentication.

## Deterministic barrier

The deployed bridge requires `msg.sender == L1CDM` and `xDomainMessageSender == 0x420…0014`; direct attacker finalization reverts. `L1ERC721Bridge.sol:102-114` requires the exact `(local,remote,tokenId)` escrow bit, clears it, and performs `safeTransferFrom` atomically. A valid L2 withdrawal burns/escrows the corresponding representation, so no second valid withdrawal can consume that unique bit while A is waiting. Direct messenger replay restores the committed L2 bridge sender and committed recipient.

## Evidence

- `mirror/CATK-B/evidence/fork-test-output.txt`
- `mirror/CATK-B/evidence/source-barriers.md`
- `POST_U21_STATE.json` deployed proxy `0x5a7749…ef23D`

Decision: rejected; no permissionless competing state transition.
