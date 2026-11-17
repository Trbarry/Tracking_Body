# ATTACK-T3-07 — U21 "L1 bridge hardening" / L1CrossDomainMessenger 2.13.0 changes how old in-flight bridge messages finalize

Lane ATK-T3 (bridge token identity / L1ERC721Bridge / OptimismMintableERC20Factory), Opus 5.5 (CLAUDE.md exception, Mythos 5.2 quota until 2026-11-22). Sources: op-contracts v9.0.0 (`/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src`). PoC: `test/poc/attack-wave/T3/test/T3.t.sol`; run output `evidence/attack-wave/T3/forge-final.txt` (9/9 PASS). Kill type: source diff + differential fork tests (N-1 vs post-U21).

**Hypothesis.** U21 changed bridge or messenger semantics so that an in-flight bridge message (new or migrated legacy format)
finalizes differently (pays twice, pays someone else, or becomes undeliverable) after the upgrade.

**Executed.** Source diff v8 -> v9: `StandardBridge.sol`, `L1StandardBridge.sol`, `L1ERC721Bridge.sol`, `ERC721Bridge.sol`,
factory, `OptimismMintableERC20.sol`: formatting only; the implementations are byte-identical and re-installed at the same address
(`U21_PROXY_IMPLEMENTATION_MAP.md` rows 61-63). L1CDM 2.11.1 -> 2.13.0: only the relay gas constants become local/remote
(`CrossDomainMessenger.sol` `_localRelayReservedGas`/`_localRelayGasCheckBuffer`, `baseGas` virtual) — gas bands are lane C's.
`test_D1`: fake ERC20, fake NFT, honest ERC20, honest NFT withdrawals captured from the L2 fork, finalized on `l1pre` (2.11.1) and
`l1` (2.13.0): identical outcomes (F, F, T, T), honest balances exact. `test_D2`: migrated legacy format (version-0 inner nonce,
`finalizeERC20Withdrawal` selector): honest pays exactly once, fake fails, identical pre and post.

**Barrier.** No semantic delta in any bridge; version-0 handling (`CrossDomainMessenger.sol:227-231`) unchanged. KILLED.
