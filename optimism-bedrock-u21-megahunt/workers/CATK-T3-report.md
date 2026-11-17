# CATK-T3 report — bridge token identity / ERC721 / mintable factory

Model: **Codex, configured by the worker brief as `gpt-daybreak-blue-latest`**.

Result: **19 experiments; 0 candidates; 7 deterministic kill files; 11/11 fork tests PASS.** No transaction was
signed or broadcast. All RPC activity was passive through the local proxies/pinned forks; all mutations occurred in
Foundry forks. The Opus T3 lane's outputs were not read.

## Experiments

| ID | Hypothesis / action | Command or test | Result | Output |
|---|---|---|---|---|
| E1 | Current ERC20 identity decision may mix interfaces | v9 source trace, lines 272-298/391-407 | exact branch and legacy precedence | T3-01/02 |
| E2 | Historical bridge versions changed pair meaning | `git show`/digest v2..v9 | universal StandardBridge identical | T3-02/06 |
| E3 | Active pair ledger diverges from mapping | offline event aggregate + pinned `deposits` | 11/11 exact | T3-04 |
| E4 | L2 supply exceeds exact L1 escrow | pinned `totalSupply` for top 11 | 0 excess; all below | T3-04 |
| E5 | Four-chain deployments/config differ | pinned getters for 12 proxies | shared correct implementations/config | T3-06 |
| E6 | U21 changes bridge/factory implementation | EIP-1967 reads at N-1/N | 12/12 unchanged | T3-06 |
| E7 | L1CDM 2.13 changes message meaning | AddressManager reads + v8/v9 diff | gas-budget delta only | T3-06/07 |
| E8 | Dual-interface token selects modern identity | `test_interfaceMatrix_dualInterfaceUsesLegacyIdentity` | modern mismatch reverts; legacy succeeds | T3-02 |
| E9 | Legacy-only/new-only paths overlap | `test_interfaceMatrix_legacyOnlyAndModernOnlyAreDisjoint` | disjoint, exact getter | T3-02 |
| E10 | Non-mintable deposits share remote accounting | `test_nonMintableAccounting_isIsolatedByExactRemoteAddress` | independent mapping cells | T3-04 |
| E11 | L1 factory duplicate/rebind/mint | `test_factory_sameRemoteCreatesDistinctImmutableIdentities` | distinct immutable tokens; collision/rebind fail | T3-03 |
| E12 | Arbitrary fake L2 token drains canonical escrow | `test_fakeL2Tokens_allInterfaceShapesRemainPairIsolatedOnL1` | every fake pair has zero canonical escrow | T3-01 |
| E13 | L2 factory token aliases canonical pair | `test_l2FactoryTokens_haveImmutableIdentityButNoCanonicalPairEscrow` | immutable; unauthorized mint fails; zero pair | T3-03 |
| E14 | ERC721 2.3.1..2.9.1 changed custody checks | tag-by-tag source diff | pause/init only; escrow/finalize stable | T3-05/06 |
| E15 | ERC721 remote/token-id cells collide | `test_erc721Deposit_isIsolatedByExactPairAndTokenId` | exact triples only; direct finalize fails | T3-05 |
| E16 | Real old NFT differs pre-U21 | `test_preU21_inFlightERC721_deliversCommittedRecipientOnce` | exact recipient once | T3-05/07 |
| E17 | Same NFT differs post-U21 | post-U21 counterpart | identical state delta | T3-05/07 |
| E18 | Real OVM ERC20 wrapper differs pre-U21 | `test_preU21_legacyERC20Wrapper_debitsExactPairOnce` | exact pair/recipient once | T3-07 |
| E19 | Same OVM ERC20 differs post-U21 | post-U21 counterpart | identical state delta | T3-07 |

## Main barriers

1. Non-mintable release subtracts the exact `(local,remote)` cell with checked arithmetic before transfer.
2. Dual-interface tokens always use legacy `l1Token()` precedence on both domains.
3. Factory identity and bridge are immutable; duplicate metadata creates a distinct local address, not a rebind.
4. ERC721 escrow is the exact `(local,remote,tokenId)` triple; it is cleared before callback and the message fixes `_to`.
5. U21 did not change any target bridge/factory implementation; L1CDM 2.13.0 changes gas budgets only.

## Candidates and stopped lines

Candidates: **none** (there is therefore no candidate score). No safety system stopped a line. Token-specific custom
bridge, oracle/price, and non-standard third-party supply semantics were recorded as out of authorization and not
pursued. A full Ink/Soneium/Unichain L2 supply census was stopped because this engagement exposes only the OP L2 local
archive proxy; guessing or using unapproved public RPCs would violate the access discipline.

## Highest-value next experiment

Provide authorized local archive proxies/pinned forks for Ink, Soneium and Unichain L2, then repeat the exact-pair
event/mapping/supply census and real-proof withdrawal differential on one high-activity pair per chain. This is the only
remaining production-state precondition not implied by the shared L1 implementation checks.

Reproducer: `mirror/CATK-T3/poc/`. Evidence: `mirror/CATK-T3/evidence/`.
