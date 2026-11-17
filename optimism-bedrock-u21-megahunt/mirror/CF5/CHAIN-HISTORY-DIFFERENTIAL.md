# CF5 — chain-history differential through Upgrade 21

## Answer

**Yes: two chains running the same v9 implementations can behave differently because v9 reads chain-local historical state.** The cleanest permissionless example is the dispute-game registry: OP Mainnet, Ink, and Unichain retain type 9 with a 0.08 ETH bond, while Soneium retains only proposer-restricted type 5. Identical `create(9, root, extraData)` calldata succeeds on OP and reverts `NoImplementation(9)` on Soneium. This is deliberate policy, not a vulnerability.

I found no chain-history differential that gives an unprivileged actor unauthorized withdrawal, ownership, pause, or custody control. The two unexpected live sibling games were ordinary permissionless invalid claims: neither output root matches the corresponding L2 header, and neither is claim-valid.

## Evidence and coverage

- L1 archive: passive `http://127.0.0.1:7545`, through block **26,433,900**. `evidence/pinned-cast-reads.txt:1-153` contains reproducible `cast` reads. No transaction was sent.
- Current code: `op-contracts/v9.0.0`, commit `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`. PASS A independently confirms the same implementation set on all four chains at block N and 26,433,900 (`U21_PROXY_IMPLEMENTATION_MAP.md:44-117,127-143`).
- Logs: every relevant current-proxy event from genesis; every factory implementation/args/bond event; and every anchor/blacklist/retirement/respected-type event for all 12 ASRs. The ASR scan contains **32,101 `AnchorUpdated` and zero blacklist events** (`evidence/historical-asr-events.json`).
- Governance: Safe setup, owner add/remove, and threshold events through the pinned head for every current governing Safe and both nested L1PAO owner Safes (`evidence/safe-owner-history.json`).
- Game census: every game at the pinned count for Ink (2,640), Soneium (8,537), and Unichain (17,691), Multicall3 batches of 20. OP's 21,389 games were additionally scanned to enumerate historical objects.
- L2 headers: passive `https://rpc-gel.inkonchain.com`, `https://rpc.soneium.org`, `https://mainnet.unichain.org`, and local pinned OP RPC `:7546`. Formula: `keccak(bytes32(0) || stateRoot || withdrawalsRoot || blockHash)`.

Per-chain exhaustive artifacts are `chains/<CHAIN>/{DEPLOYMENT.json,STATE-U21.json,UPGRADE-PATH.json,HISTORY.md}`. `UPGRADE-PATH.json` retains every event, sampled balance at every release, task transaction, method, OPCM, effective prestate history, and historical game object.

## Same implementation, different state

The core v9 implementations are identical: SystemConfig `0xade272…`, Portal `0xb20b23…`, DGF `0x72b971…`, ASR `0x2b2729…`, DelayedWETH `0xf024e9…`, ETHLockbox `0xdf75e6…`, and L1XDM `0x7d4Ec7…` (`U21_PROXY_IMPLEMENTATION_MAP.md:57-66,72-81,87-96,102-111`). The differences below are storage/history, not bytecode.

| divergent state | OP / Ink / Unichain | Soneium | v9 reader and reachability | result |
|---|---|---|---|---|
| registered/respected game | type 5 + type 9; respected 9; type-9 bond 0.08 ETH | type 5 only; respected 5; bondless | DGF reads `gameImpls` then `initBonds` (`DisputeGameFactory.sol:147-172`). Anyone may call. | Permissionless type-9 creation only on three chains. Intended. |
| game validity history | `wasRespectedGameTypeWhenCreated`, retirement, blacklist, resolution, finality | same predicates, different games/timestamps | ASR (`AnchorStateRegistry.sol:215-262,286-352`) and Portal (`OptimismPortal2.sol:411-442`). Proving is permissionless. | Different games can prove withdrawals, but only factory-registered, non-retired, respected-at-creation, finalized defender wins. |
| SystemConfig owner | `0x847B…` | `0x509182…` | owner-gated setters | Privileged divergence only. All ProxyAdmins/DGFs are now owned by root L1PAO `0x5a0A…`. |
| gas parameters at block 26,433,900 | OP 40m/250/2/0; Ink 30m/0/0/0; Uni 60m/250/12/500k | 40m/250/10/12m | SystemConfig getters and L2 derivation; reads at `pinned-cast-reads.txt:10-18,38-46,66-74,94-102` | L2 fee/limit behavior differs; no L1 privilege bypass. |
| custody amount | different lockbox balances | different balance | Portal delegates pause/custody to its lockbox (`OptimismPortal2.sol:305-323`) | Amount differs; authorization path does not. |
| OP legacy residue | four non-zero old slots | zero | all four are v9 private spacers | No runtime read; no behavior. |

All chains have custom-gas-token false, ETH-lockbox enabled, and interop disabled at U21. Guardian is shared `0x09f715…`; current portal pause is false on all four (`pinned-cast-reads.txt:14-23,42-51,70-79,98-107,122-132`).

## Birth and upgrade path

OP has the only Bedrock lineage: bridge/L1XDM code at blocks 12,686,786/12,686,757; current proxy shells at 17,365,800–804; SystemConfig initialized at 17,422,444, Portal at 17,423,158, and DGF at 19,884,570. Ink and Soneium were born atomically at L1 genesis blocks 21,344,310 and 21,314,185. Unichain shells were deployed at 21,116,347–356 and initialized at 21,116,362–372. Exact proxy dates, birth implementations, and born versions are in each `DEPLOYMENT.json`; registry genesis pins are `superchain/configs/mainnet/{op,ink,soneium,unichain}.toml:32-44`.

Every chain executed U2, U3, U16, U16a, U17, U18, U19, U20, and U21; none skipped a post-birth release. Execution dates differ for Unichain U2/U3/U16a/U17/U18/U19 and Soneium U16/U18. Each `releasePath` records all implementation snapshots and `unchangedAtRelease` records components skipped/no-op within a release. Every release was OPCM; manual operations were limited to game-prestate/proposer configuration and ownership transitions. `lastUsedOPCM` advances from v2 `0x026b…` through v9 `0x2d91…`; current reads match on all four (`pinned-cast-reads.txt:13,41,69,97`).

Notable manual history:

- Ink proposer rotation at block 25,674,914, then SystemConfig owner transfer at 25,834,840. The task explicitly preserved every game field except proposer (`superchain-ops/src/tasks/eth/061-ink-proposer-rotation/README.md:12-23`).
- Unichain ProxyAdmin/DGF transferred from its 3-of-3 to standard L1PAO at block 25,976,344, before U20 (`superchain-ops/src/tasks/eth/069-unichain-l1-ownership-transfers/README.md:7-14`), and its type-5 fallback proposer rotated at block 26,299,517 (`eth/078-unichain-proposer-rotation/README.md:7-15`).
- U21 rotated OP's type-5 fallback proposer but did not change the respected-type split (`eth/084-U21-op-ink-soneium-uni/README.md:16-38`).

Ownership event arrays include initializer emissions and temporary OPCM owner flips as well as durable changes; this avoids falsely interpreting an intra-transaction transfer as a governance epoch.

The root L1PAO is a 2-of-2 Safe. Its owners are the 5-of-7 Foundation Safe (`0x847B…`, also OP/Ink/Unichain SystemConfig owner) and a 10-of-13 Safe (`0xc281…`). Soneium's distinct SystemConfig owner (`0x509182…`) is 3-of-5. Full membership rotations and threshold history are embedded per chain as `governanceSafeHistory`; no current owner is an EOA.

## Custody and pause history

U16 created each current lockbox and atomically emitted `ETHMigrated`:

| chain | migrated wei | lockbox wei at 26,433,900 | Portal / L1XDM / L1 bridge wei |
|---|---:|---:|---:|
| OP | 236752243071584240518225 | 182541068255115703234018 | 0 / 0 / 0 |
| Ink | 6020610509607786200086 | 23088758336628210326229 | 0 / 0 / 0 |
| Soneium | 8877050938229307093797 | 2195560152606106316659 | 0 / 0 / 0 |
| Unichain | 133613248268096507106891 | 18266157945407766718622 | 0 / 0 / 0 |

Pinned balances are reproduced at `pinned-cast-reads.txt:33-37,61-65,89-93,117-121`. The apparent decline/growth between upgrades is normal withdrawal/deposit flow, not lost custody. U21 moved no ETH (`eth/084.../README.md:23-34`).

Before U16, Portal v3 read the shared global pause (`op-contracts/v3.0.0 OptimismPortal2.sol:235-238`). From U16, Portal/SystemConfig routed pause through the chain's lockbox identifier (`op-contracts/v4.0.0 OptimismPortal2.sol:293-296; SystemConfig.sol:487-493`); v9 makes the same relationship direct (`OptimismPortal2.sol:305-308; ETHLockbox.sol:111-114`).

The complete shared-SuperchainConfig log history contains:

- global pause, identifier “Deputy Guardian”, block 22,482,108 (2025-05-14 14:50:59 UTC), followed by unpause at 22,482,160, 636 seconds later;
- one address pause at block 25,689,317 for `0x758e…` (Swell portal), not any target identifier; it expired after three months under `SuperchainConfig.sol:139-162`;
- no target lockbox pause and no current global/local pause.

## Dispute objects, types, anchors, and prestates

Each chain has one persistent DGF proxy and exactly three ASRs ever referenced by a game. DelayedWETH lineages are OP 7, Ink 6, Soneium 4, Unichain 6. Current/past object addresses, first-code blocks, game-index ranges, versions, owner or lockbox, and balances are in `evidence/historical-game-objects.json` and each `HISTORY.md`.

Pinned DelayedWETH ETH totals are OP 20.982782, Ink 5.790376, Soneium 0, and Unichain 21.499797 ETH. These are per-game bond/refund custody; old nonzero objects remain callable by their games. I found no cross-game credit mutation or permissionless withdrawal of another claimant's credit. Economic impact confined to bonds is below the programme's direct-loss threshold.

Effective prestate epochs are explicitly normalized in `absolutePrestatePolicyHistory`:

| epoch | effective type/prestate policy |
|---|---|
| U2 | types 0/1 `0x039facea…` |
| U3 | types 0/1 `0x03ee2917…`; OP/Ink/Uni later `0x03682932…` Isthmus update |
| U16 | types 0/1 `0x03eb0710…` |
| U17 | types 0/1 `0x03caa187…` |
| U18 | 0/1 `0x033c0009…`; type 8 `0x0323914d…` where enabled |
| U19 | type 0 disabled; type 8 `0x0337ecb3…` on OP/Ink/Uni; Soneium stays type 1 |
| U20 | types 5/9 `0x031ac6f1…`; Soneium type 5 only |
| U21 | types 5/9 `0x03e5a548…`; Soneium type 5 only |

Newer shared blueprints store per-chain values in DGF `gameArgs`; a direct implementation `absolutePrestate()` read returning zero is not the effective prestate (`eth/061.../README.md:19-23`). The normalized task-signed values therefore take precedence.

Soneium respects type 5 **since U20 block 26,048,619** because it remained permissioned through U19 and had no permissionless Kona implementation to carry over. U20 deliberately mapped type 1→5 while the other three mapped 8→9 (`eth/071.../README.md:16-30`). U21 deliberately retained this (`eth/084.../README.md:16-29`).

Current retirement timestamps are OP/Ink 1,753,379,243; Soneium 1,753,380,095; Unichain 1,753,380,731. There are no later retirement or blacklist events. The current anchors continued advancing operationally after U21; every update is retained rather than treating the post-upgrade snapshot as static.

## Game census and L2-root verification

| chain | count | type counts | status 0/1/2 | claim-valid | raw non-current-proposer flags | after documented rotations | unexpected live result |
|---|---:|---|---|---:|---:|---:|---|
| Ink | 2,640 | 0:2076, 1:190, 8:256, 9:118 | 8/19/2613 | 1,685 | 1,475 | 1 | index 2638, type 9, in progress, claim-invalid |
| Soneium | 8,537 | 1:7955, 5:582 | 0/0/8537 | 5,668 | 0 | 0 | none |
| Unichain | 17,691 | 0:12616, 1:1865, 8:1914, 9:1296 | 85/16/17590 | 11,323 | 11,044 | 1 | index 17586, type 9, in progress, claim-invalid |

Large raw counts are old official proposers, not attackers: Ink `0x65436d…`→`0x3832bf…`; Unichain `0xd5f0e2…`→`0x86b392…`. The two truly unexpected games are permissionlessly creatable type-9 games:

- Ink game `0x40bec0…`: embedded root `0x4bf7…`, independently reconstructed `0xaf30…` at L2 timestamp 1,794,857,590 — mismatch.
- Unichain game `0xa41214…`: embedded root `0x0cf7…`, reconstructed `0x6b26…` at timestamp 1,794,531,731 — mismatch.

Both are unblacklisted but in progress and `isGameClaimValid == false`; an invalid proposal existing is expected fault-proof behavior. As an extra control, OP's only non-official claim-valid game (index 19,206, type 8) exactly matches local L2 block 155,450,031, demonstrating that third-party creation alone is not suspicious. Full headers and roots are in `evidence/output-root-verification.json`.

## Named differential fork test

`ChainHistoryDifferentialTest.test_sameType9CreationCallDiffersBecauseRegistrationHistoryDiffers` (`h/test/ChainHistoryDifferential.t.sol:14-40`) forks real L1 state at 26,433,900, funds an ordinary test caller, builds one valid super-root preimage, and sends byte-identical type-9 creation calldata with 0.08 ETH to OP and Soneium.

- OP: succeeds and deploys a game.
- Soneium: reverts selector `NoImplementation(uint32)`.
- `forge test -j 1`: 1 passed, 0 failed (`evidence/chain-history-differential-test.txt`).

This proves the thesis but not an exploit: the divergence is the documented permissionless/permissioned policy boundary.

## Falsification results

1. **Legacy-slot collision:** OP alone has nonzero XDM 51/151, bridge 1, and Portal 54 (`pinned-cast-reads.txt:133-153`). v9 declares them private spacers (`CrossDomainMessenger.sol:40,63; StandardBridge.sol:38; OptimismPortal2.sol:82`); no path reads them.
2. **Stale-ASR acceptance:** v9 factory-registration no longer compares a game's embedded ASR (`AnchorStateRegistry.sol:215-246`), but each U16 migration was atomic. Census boundaries show no game created after the new ASR retirement timestamp while retaining an old ASR. No blacklist/retirement anomaly exists.
3. **Unexpected proposer games:** sibling anomalies fail L2-root reconstruction and remain claim-invalid. OP's valid third-party root reconstructs exactly.
4. **Custody residue:** target Portal/L1XDM/bridge balances are zero; all migrated ETH is in authorized lockboxes. Historical WETH balances are bond credits, not portal liquidity.
5. **Pause drift:** the only target-wide pause was promptly reversed; the only local pause targeted another chain and expired.

## Conclusion and next edges

No bounty candidate survived falsification. The highest-value next wave is: (1) differential credit-withdrawal tests over every nonzero legacy DelayedWETH, especially owner-based v1.0/1.1 versus lockbox-based v2.0; (2) trace initializer/external-call ordering inside each ASR replacement transaction to rule out a reentrant transition window; and (3) replay the first post-U20 type-5/type-9 game on each chain to test `wasRespectedGameTypeWhenCreated` across the exact policy transition.

Limits: balances are sampled at births/releases/current head, not every intervening block; only unexpected live roots were independently reconstructed; L2 endpoint availability and the pinned L1 head bound the census; no live transaction or shared-fork mutation occurred.
