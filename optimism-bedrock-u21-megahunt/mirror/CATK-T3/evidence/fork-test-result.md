# Fork-test result

Command:

```bash
forge test -j 1 --match-path test/CATK_T3.t.sol -vv
```

Result at 2026-11-17: **3 suites, 11 passed, 0 failed, 0 skipped**.

| Contract | Test | Result |
|---|---|---|
| `CATKT3FakeL2ForkTest` | `test_fakeL2Tokens_allInterfaceShapesRemainPairIsolatedOnL1` | PASS |
| `CATKT3FakeL2ForkTest` | `test_l2FactoryTokens_haveImmutableIdentityButNoCanonicalPairEscrow` | PASS |
| `CATKT3IdentityForkTest` | `test_interfaceMatrix_dualInterfaceUsesLegacyIdentity` | PASS |
| `CATKT3IdentityForkTest` | `test_interfaceMatrix_legacyOnlyAndModernOnlyAreDisjoint` | PASS |
| `CATKT3IdentityForkTest` | `test_nonMintableAccounting_isIsolatedByExactRemoteAddress` | PASS |
| `CATKT3IdentityForkTest` | `test_factory_sameRemoteCreatesDistinctImmutableIdentities` | PASS |
| `CATKT3IdentityForkTest` | `test_erc721Deposit_isIsolatedByExactPairAndTokenId` | PASS |
| `CATKT3InFlightNFTForkTest` | `test_preU21_inFlightERC721_deliversCommittedRecipientOnce` | PASS |
| `CATKT3InFlightNFTForkTest` | `test_postU21_sameInFlightERC721_deliversCommittedRecipientOnce` | PASS |
| `CATKT3InFlightNFTForkTest` | `test_preU21_legacyERC20Wrapper_debitsExactPairOnce` | PASS |
| `CATKT3InFlightNFTForkTest` | `test_postU21_sameLegacyERC20Wrapper_debitsExactPairOnce` | PASS |

The tests use deployed bridge, messenger, portal, factory, token and game bytecode. Mocks are confined to attacker-owned
tokens used to exercise interface shapes and to locally deposited test assets; no mock supplies authentication.
