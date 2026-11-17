# CHAIN-HISTORY DIFFERENTIAL — OP Mainnet vs Ink vs Soneium vs Unichain (worker F5, row B13)

Same v9 code (byte-identical deployments, PASS A) on four chains with different histories. One row per
divergence in persistent state at L1 block 26433900: the v9 code path that reads it, the behaviour per chain,
and whether an unprivileged actor reaches it. Facts come from `chains/<CHAIN>/{HISTORY.md,DEPLOYMENT.json,
STATE-U21.json,UPGRADE-PATH.json}` and `evidence/F5/*`. v9 lines refer to `/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src`.
Model: Opus 5.5 (CLAUDE.md exception validated by the user on 2026-11-17, Mythos 5.2 quota exhausted).

Fork tests (L1 fork `:8545` @ 26433900, real bytecode, a fresh EOA, no prank of a role, `-j 1`):
`test/F5/F5_ChainHistoryDifferential.t.sol` (2 tests) and `test/F5/F5_ChainHistoryDifferential2.t.sol`
(4 tests), run from `/home/user/u21-work/F5` — all 6 PASS. Outputs: `evidence/F5/F5-differential{,2,3}-output.txt`.

## Same permissionless sequence on four chains (`F5_ChainHistoryDifferential::test_same_sequence_four_chains`)

| chain | create(9) | create(5) | create(0/1/8) | setAnchorState(latest claim-valid legacy game) | prove(legacy claim-valid game, bogus proof) | prove(retired game) | respected | retirementTimestamp |
|---|---|---|---|---|---|---|---|---|
| OP | OK | BadAuth | NoImplementation | `AnchorStateRegistry_InvalidAnchorGame` | `InvalidOutputRootProof` (reaches root check) | `ImproperDisputeGame` | 9 | 1753379243 |
| INK | OK | BadAuth | NoImplementation | InvalidAnchorGame | InvalidOutputRootProof | ImproperDisputeGame | 9 | 1753379243 |
| SONEIUM | **NoImplementation** | BadAuth | NoImplementation | InvalidAnchorGame | InvalidOutputRootProof | ImproperDisputeGame | **5** | 1753380095 |
| UNICHAIN | OK | BadAuth | NoImplementation | InvalidAnchorGame | InvalidOutputRootProof | ImproperDisputeGame | 9 | 1753380731 |

Every chain gives the same result for every step except Soneium's game-type set. The legacy games (block-number domain, types 0/1/8)
are still claim-valid and provable on all four chains, and on none of them can they become the anchor (their block number is
below the timestamp-domain anchor).

## Divergence table

| # | Divergent state (evidence) | v9 reader | OP | Ink | Soneium | Unichain | Unprivileged reach | Security-relevant? / test |
|---|---|---|---|---|---|---|---|---|
| D1 | Game-type set and respected type (`HISTORY.md` §5; ASR slot 6 bisection) | `DisputeGameFactory.create` (`dispute/DisputeGameFactory.sol:147`), `ASR.isGameRespected` (`:242`), portal prove (`L1/OptimismPortal2.sol:390-415`) | types 5, 9 live; respected 0→8→9 | same as OP | types 5 only live; respected 1→5; never had 0/8/9 | same as OP (+ extra type-5 re-registration 26299517) | yes: `create(9)` works on OP/Ink/Unichain, NoImplementation on Soneium | Behaviour differs by design (permissioned chain). Test above |
| D2 | Registry generations behind one factory: gen1 / gen2 / live, with different gen1 versions (2.0.0 on OP and Unichain; 2.0.1-beta.3 on Ink and Soneium) and creation blocks (`<CHAIN>-stage2.json`) | `ASR.isGameRegistered` (`dispute/AnchorStateRegistry.sol:227`, factory-only, no binding) + `isGameRetired` (`:259`) | 3 generations | 3 | 3 | 3 (gen2 born 22254924, the others 22182531) | yes, any game in the factory can be passed in | Safety rests on retirement; exhaustive census: 0 non-retired games bound elsewhere on any chain; after-cut registrations 0 foreign (`registry-binding-check.txt`, closure C15; `test_a`) |
| D3 | Retirement cut and U16 transaction: OP and Ink were upgraded in the same tx 22990599; Soneium 22990670, Unichain 22990722 | `isGameRetired` (`:259`) | 1753379243 | 1753379243 | 1753380095 | 1753380731 | yes (read) | The first non-retired game on every chain is already bound to the live registry (OP 9828, Ink 922, Soneium 2841, Unichain 6186) |
| D4 | Orphaned gen2 registry (v2.2.2) pre-state: Soneium `anchorGame()==0`; the others hold a 2025 game | v2.2.2 `setAnchorState` (`hist/v3.0.0/.../dispute/AnchorStateRegistry.sol:239`), which mirrors the v9 portal getters (`L1/OptimismPortal2.sol:334,349,357`) | anchor 0x9C9a… | 0x6009… | **0x0** | 0xcD1f… | **yes**: on all four chains a fresh EOA can make the orphaned gen2 registry accept the LIVE registry's latest claim-valid legacy game as claim-valid and as its anchor | Uniform outcome (`test_d`). Inert: no live implementation binds to gen2 (census + `test_a`), and the anchor is only read inside a game's own `initialize` (`dispute/FaultDisputeGame.sol:265`, `SuperFaultDisputeGame.sol:282`, `SuperPermissionedDisputeGame.sol:63`). Super games revert on gen2 (no `l2BlockNumber()`, `test_c`). → PRIM-F5-01, REJ-F5-01 |
| D5 | Legacy slots that are non-zero on OP only: portal slot 54 (L2OutputOracle), L1CDM slots 51 / 151 (OVM owner / reentrancy), L1StandardBridge slot 1 (`0x4200…10`) | none: all are `spacer_*` in v9 `snapshots/storageLayout`, and no v9 `src/L1` code names them or uses `sload` | non-zero | 0 | 0 | 0 | no | No. PASS A C2 (junk-fill test). → REJ-F5-02 |
| D6 | Soneium portal slot 59 low bytes = 1 (legacy respectedGameType, set by `initialize` with no event); 0 on the others | none (spacer_59, v9 reads `anchorStateRegistry.respectedGameType()`, `L1/OptimismPortal2.sol:340`) | 0 | 0 | 1 | 0 | no | No |
| D7 | Custody path: OP has bridge→portal (Bedrock 17423158, 293,288 ETH), portal→lockbox 236,752; Ink 6,020.6; Soneium 8,877.1; Unichain 133,613.2. Portal / L1CDM / L1StandardBridge = 0 on all four at every block after U16 | `ETHLockbox.unlockETH`, portal finalize | lockbox 182,541.07 | 23,088.76 | 2,195.56 | 18,266.16 | finalize only with a valid withdrawal | No residue outside the lockbox (B03 input). L2 liability is not checkable from L1 (L9) |
| D8 | DelayedWETH generations still holding ETH: OP legacy 0.16 + 0.08 + 0.08, Ink 0.08, Unichain 0.08, Soneium 0; live OP 20.66, Ink 5.71, Unichain 21.42, Soneium 0 | legacy games' `claimCredit` / `closeGame` (`FaultDisputeGame.sol:979,1021`) | 7 WETH | 6 | 4 | 6 | bond claimants only | Bonds are carved out of Critical/High (B09 input) |
| D9 | Unichain legacy DelayedWETH `owner()` = Unichain Safe `0x6d5b183f…` (others `0x5a0Aae59…`); ProxyAdmin owned by that Safe until 2026-09-14 | `DelayedWETH.hold/recover` (owner-only) | — | — | — | different owner | no (privileged) | Privileged only, 0.08 ETH |
| D10 | Third-party invalid super games IN_PROGRESS: Ink #2638 and Unichain #17586 (wrong root vs the L2 header, countered) | `ASR.isGameClaimValid` (`:331`), portal prove (`:415`) and finalize (`:702`) | none | 1 | none | 1 | yes: anyone can create such a game (bond) | Not claim-valid; `resolve`, `setAnchorState` and `prove` revert (`test_b`); outcome depends on the honest challenger (known op-challenger / dispute-mon class) |
| D11 | Proposer sets: OP `0x473300df…` + `0xc27ba3e0…` (post-U21); Ink `0x65436ddc…` → `0x3832bfbe…`; Soneium `0x400c164c…` (permissioned); Unichain `0xd5f0e291…` + `0x86b392ca…` | `isGameClaimValid` | all roots match | all roots match | all roots match | all roots match | permissionless types only | No. Every claim-valid game on every chain has a header-matching root (`*-root-verification.txt`, `root-spotchecks.txt`) |
| D12 | SystemConfig L2 parameters: slot 106 is 0 on Ink only; minBaseFee is 12,000,000 wei on Soneium and 500,000 wei on Unichain; gasLimit is 30M / 40M / 40M / 60M | op-node / kona derivation (B12), not an L1 value path | set | 0 | set | set | no | Context (OPUS-13) |
| D13 | Pause history: only OP had portal-local pauses (2024-02-15). The shared SuperchainConfig had a global pause on 2025-05-13 (~10 min), and one identifier pause (Swellchain portal, 2026-08-05) that expired on 2026-11-04. None of the four chains' identifiers was ever paused | `paused()` (`dispute/AnchorStateRegistry.sol:136`, `L1/OptimismPortal2.sol:306`) | not paused | not paused | not paused | not paused | no | No (C8 unchanged) |
| D14 | Born-with generation: OP Bedrock 1.6.0 portal (L2OutputOracle era) with OVM-era L1CDM and bridge; the other three were born on op-contracts v1.6.0 (Portal2 3.10.0, DGF 1.0.0) | legacy `provenWithdrawals` / messenger mappings | L2OO-era proofs possible | none | none | none | — | B01 / B02 / B10 are OP-only questions (OPUS-02 / 03) |

## Conclusion

No row gives an unprivileged actor a different security-relevant outcome on one chain versus another. The
two divergences an unprivileged actor reaches are D1 (Soneium is permissioned, by design) and D4 (orphaned
gen2 registries are writable on all four chains, inert). The registry-binding assumption that
`isGameRegistered` now depends on holds for all 43,480 non-retired games on the four chains
(OP 11,561 · Ink 1,718 · Soneium 5,696 · Unichain 11,505).
