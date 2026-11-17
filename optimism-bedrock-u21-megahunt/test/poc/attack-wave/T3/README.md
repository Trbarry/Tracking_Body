# ATK-T3 — bridge token identity, L1ERC721Bridge, OptimismMintableERC20Factory (fork tests)

Model: Opus 5.5 (CLAUDE.md exception; Mythos 5.2 quota until 2026-11-22 00:00 UTC).

## Run (9 tests, all PASS; ~10 s warm)

    cp -r /home/user/u21-work/template /tmp/t3h        # forge-std + lib
    cp foundry.toml /tmp/t3h/ && cp test/T3.t.sol /tmp/t3h/test/ && rm -f /tmp/t3h/test/Sanity.t.sol
    cd /tmp/t3h && forge test -j 1 --match-contract T3Test -vv

Working copy used by the lane: `/home/user/u21-work/T3/h`. RPC endpoints (read-only shared forks):
`l1` :8545 (L1 26433900, post-U21), `l1pre` :8546 (L1 26430858, N-1), `l2` :9545 (OP 159654093).
Output of the final run: `evidence/attack-wave/T3/forge-final.txt`; -vvvv traces `evidence/attack-wave/T3/trace-*.txt`.

## What is deployed vs local

Deployed bytecode under test: L2StandardBridge 1.13.2, L2ERC721Bridge 1.10.1, L2CrossDomainMessenger 2.2.1,
L2ToL1MessagePasser, L2 factories (OP fork); OptimismPortal2, L1CrossDomainMessenger 2.13.0 (2.11.1 on l1pre),
L1StandardBridge 2.8.2 (impl 0xB37a11…), L1ERC721Bridge 2.9.1, OptimismMintableERC20Factory 1.11.0 (L1 fork).
Local only: attacker-deployed fake L2 tokens/NFT (on the L2 fork) and standard ERC20/ERC721 stand-ins for honest
L1 assets (on the L1 fork). No third-party contract is called by any test.

HARNESS-ONLY (same as lane B / PASS A NestedReplay): the attacker's own L2->L1 withdrawal, captured byte-exact from
the deployed L2 contracts' `MessagePassed`, is proven on L1 by `vm.store` of `provenWithdrawals[hash][SUB]` (slot 57)
against the real claim-valid anchor game, then finalized through the real permissionless
`finalizeWithdrawalTransactionExternalProof`. Honest-side L1->L2 deposit effects on L2 are replayed by pranking
the L2 bridge as minter (`test_C1`, `test_D1`), i.e. the exact effect of the honest deposit. The exploit phase
always starts from the unprivileged `ATTACKER` EOA.

| test | experiment |
|---|---|
| test_B1_fakeL2Tokens_cannotReleaseHonestEscrow | 5 attacker withdrawals (fake both-iface, split l1Token/remoteToken, new-iface-only, non-ERC165 fake escrow, legacy withdrawTo) vs honest escrow of 1000 X |
| test_B2_perPairBarrier_isExact_selfFundedOnly | positive control: self-funded fake pair withdraws exactly its own 10, 1 more fails |
| test_B3_l1Mintable_remoteIdentityBound | L1-factory mintable token M: fake remotes cannot mint; only M.remoteToken() can; codeless remote of real IBEX token cannot be escrowed on L2; 4 real L1-mintable tokens supply 0 |
| test_C1_erc721_identityAndRecipient | fake L2 NFT vs escrowed id; re-key escrow from L1; honest burn releases to the L2-designated `_to` only; no second release |
| test_C2_realEscrow_flags_and_auth | real escrow (0xE42c…/0x899e…, id 24900) flag; direct finalize auth |
| test_C3_pauseSource_consistent | both L1 bridges' pause source == portal SystemConfig |
| test_D1_u21_differential_sameOutcomes | same 4 withdrawals (fake ERC20, fake NFT, honest ERC20, honest NFT) on N-1 (L1CDM 2.11.1) vs post-U21 (2.13.0) |
| test_D2_legacyFormat_prePost_sameOutcome | migrated legacy format (v0 nonce, `finalizeERC20Withdrawal`) honest vs fake, pre vs post U21 |
| test_F1_factory_identity_cannotBeRebound | factory bridge/initializer, CREATE2 squat gives identical token, no rebind, only-bridge mint |

## Read-only census scripts (`scripts/`, run from a dir whose sibling is `../out`)

- `factory_scan.py` — OptimismMintableERC20Created on the 4 L1 factories (17,000,000..26,433,900).
- `l1sb_scan.py` — ERC20BridgeFinalized on the OP L1StandardBridge since Bedrock (143 pairs).
- `pair_census.py` + `erc165_fix.py` — deposits[l1][l2] vs OP L2 totalSupply / interfaces (ERC165Checker semantics).
- `nft_scan.py`, `nft_census.py`, `nft_owner.py` — L1ERC721Bridge events on 4 chains, escrow flags (slot 49), ownerOf.
All reads go through the read-only proxies :7545/:7546 in chunks (<= 1M blocks per getLogs, batches of 50 reads).
