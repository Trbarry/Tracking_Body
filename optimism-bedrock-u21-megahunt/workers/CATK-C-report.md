# CATK-C independent mirror report

Model: **OpenAI Codex (GPT-5), CATK-C mirror**.

Independence: CATK-C did not read ATK-C worker output, attack-wave tests/evidence, ATK candidate/rejection files, or another mirror's files. Research used only shared engagement context, the lane brief, scoped source, passive fork reads, and this mirror's harness.

Safety: no transaction was broadcast. Public/shared RPC use was passive. All state changes occurred inside ephemeral Forge fork state. Forge ran with `-j 1`.

## Outcome

**No eligible candidate. No `CAND-CATK-C-*` file was created.**

The deployed bytecode proves two distinct outcomes:

1. If Portal2 reaches L1CDM and records `failedMessages`, direct replay is cheaper. The measured zero-payload ceilings are portal-deliver `15,382,429`, portal-finalize `15,510,449`, and direct-deliver `15,981,628`. An actual portal-created failure at `15,382,430` was delivered by the immediately following capped direct transaction.
2. Normal L2 creation can exceed initial portal capacity: at zero payload data, the demonstrated L2 word edge is 379,200 bytes while the portal edge is 323,168 bytes. Extreme gas metadata is also accepted. These states lack a naturally created failed entry and can require an upgrade, but they are sender-selected and exactly match the programme's explicit large-data/specific-gas exclusion.

## Experiments executed (9)

| ID | Test/command target | Hypothesis | Result | Disposition |
|---|---|---|---|---|
| E01 | `test_liveConstantsAndL2AcceptsExtremeMetadata` | L2 rejects unrelayable gas metadata | uint32 max accepted; `B=4,363,451,539` | Killed as sender-selected known class |
| E02 | `test_largeZeroPayloadRejectedByL2TransactionCap` | L2 block limit, not tx cap, permits 400k | Fails within normal L2 `2^24` entry budget | Establishes creation ceiling |
| E03 | `test_largeCalldataBracketsL2LimitAndStillFitsDirectReplay` | Largest L2 payload also exceeds direct gas | 379,200 fits L2 and direct gas; 379,232 fails L2 | No replay gas barrier given failed state |
| E04 | `test_capEdges_MinGas_ForcedFailureAlwaysHasCheaperReplay` | Third party can create permanent recorded failure | Real portal-created failure directly replayed; direct ceiling higher | Killed; score 1 |
| E05 | `test_largePayloadPortalBarrierIsBeforeDirectReplayBarrier` | L2-accepted max payload finalizes | Portal unfinalized; direct gas feasible only if failed state exists | True self-harm band; excluded |
| E06 | `test_emptyValueNewAccountAndDeployedBridgeTargets` | Value/new account/bridge blocks replay | All deliver; deployed bridge recipient receives ETH | Killed; score 0 |
| E07 | `test_newAccountReserveOnlyShrinksSelfChosenDirectWithdrawalBand` | 183.6k reserve enables third-party strand | Edge shifts 183,182, but target/gas are sender-committed | Killed; score 0 |
| E08 | `test_gasBurningTargetRecordsReplayableFailureNotLostState` | Full gas burn loses success/failure bookkeeping | `failedMessages` remains true on portal and replay attempts | Killed; score -1 |
| E09 | `test_portalPayloadEdgeIsExecutionBoundAndBelowL2Edge` | Portal/data gap is only calldata floor | 323,168 fits; 323,200 unfinalized at floor 3,260,880 | True execution gap; excluded score -4 |

Final command: `forge test -j 1 --match-path test/GasCapCATKC.t.sol -vv` — **9 passed, 0 failed, 0 skipped**. Formatting check passed. Test SHA-256: `43f7dec0039cb90191ba636e9fe2790f81d995937b9e05273fa18064ff5eabd5`.

## Rejection ledger

| File | Barrier |
|---|---|
| `rejected/ATTACK-CATK-C-01.md` | Every portal-created failure tested has a cheaper direct retry |
| `rejected/ATTACK-CATK-C-02.md` | Real data/gas gap is voluntarily selected and explicitly excluded |
| `rejected/ATTACK-CATK-C-03.md` | Value/new-account reserve and deployed bridge replay do not create third-party loss |
| `rejected/ATTACK-CATK-C-04.md` | Gas-burning target records failure; semantic target failure is not cap-state loss |

## Highest-value next experiment

Run one adaptive two-dimensional boundary sweep over `(message length, minGasLimit)` at 0/64k/128k/256k/near-323k payloads, preserving naturally portal-created `failedMessages` and immediately replaying each exact message. Add the deployed value-bearing StandardBridge target at the closest joint boundary. This would turn the structural direct-path dominance into measured coverage across the only residual combined-cost surface.
