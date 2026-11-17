# CATK-B source barriers

Pinned source: `op-contracts/v9.0.0`, commit `483fea3e2187151c7e8f17ec453a2ddf4d0c5ba9`.

- `packages/contracts-bedrock/src/universal/CrossDomainMessenger.sol:234-247`: the replay hash commits nonce, sender, target, value, minimum gas and message; direct replay requires zero `msg.value` and an existing failed mapping.
- `CrossDomainMessenger.sol:263-281`: reentrancy records failure and returns, creating the forced-failure primitive.
- `CrossDomainMessenger.sol:284-296`: every actual replay installs the committed cross-domain sender and calls the committed target with the committed value/message; success is single-use.
- `packages/contracts-bedrock/src/universal/StandardBridge.sol:239-260`: ETH finalization validates exact value and sends it to the committed recipient atomically.
- `StandardBridge.sol:272-299`: ERC20 finalization mints or subtracts the committed amount from aggregate deposits, transfers to the committed recipient, and reverts atomically on failure.
- `packages/contracts-bedrock/src/L1/L1ERC721Bridge.sol:88-118`: ERC721 finalization requires the exact escrow bit, clears it, and transfers the exact token in one reverting call.
- `StandardBridge.sol:110-117` and `packages/contracts-bedrock/src/universal/ERC721Bridge.sol:63-70`: both authenticate `msg.sender == messenger` and `messenger.xDomainMessageSender() == otherBridge`, which direct replay reconstructs.
