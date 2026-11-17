# ATTACK-F-06 — Portal-originated permissionless calls (sibling-portal deposit, L1CDM.sendMessage with xDomainMessageSender = portal)

Lane ATK-F, Opus 5.5. Kill type: failing impact (self-funds only).

**Hypothesis.** The portal as caller of a sibling portal's `depositTransaction` or of its own L1CDM `sendMessage` creates an L2
message whose origin (alias(OP portal) on Ink, or `xDomainMessageSender == OP portal` on OP) is trusted by some L2 contract.

**Sequence executed.** `test_F01_targetMatrix` rows 31-32: both calls succeed; OP lockbox -1 ETH, Ink lockbox +1 ETH exactly
(attacker's own value, matching the L2 burn on OP and mint on Ink); shared-state hash unchanged.

**Barrier.** L2 trust in `xDomainMessageSender`: StandardBridge/ERC721Bridge (other bridge only, v9 src/universal/StandardBridge.sol:113,
ERC721Bridge.sol:66) and CrossDomainOwnable2/3 (src/L2/CrossDomainOwnable{2,3}.sol), which are user libraries not used by any
predeploy (grep src/L2: only their own files). Alias of the portal on L2 was killed in PASS A (D08). Self-funds only.
