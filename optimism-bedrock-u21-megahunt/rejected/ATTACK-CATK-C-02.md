# ATTACK-CATK-C-02 — large-data and specific-gas creation/finalization gap

## Hypothesis

A normal OP Mainnet sender can create an L2 withdrawal whose committed payload or gas limit cannot be finalized on L1 under EIP-7825.

## Exact sequence tried

1. Apply the `2^24` cap and EIP-7623 intrinsic/floor to live L2CDM `sendMessage` calls.
2. Bracket all-zero payloads at 32-byte ABI edges against deployed L2 bytecode.
3. Submit the resulting withdrawal shape to deployed Portal2 under the L1 cap.
4. Separately measure deployed L1CDM replay gas with a fabricated failed entry, explicitly as a gas-feasibility vehicle rather than a claim that the initial portal path created that state.
5. Confirm that uint32-max `minGasLimit` metadata is accepted cheaply by L2CDM and yields a committed withdrawal gas limit above either transaction cap.

## Result and barrier

There is a real sender-selected gap. A 379,200-byte zero payload fits the demonstrated L2 word edge, while the portal's last delivered word edge is 323,168 bytes; 323,200 is already unfinalizable despite a 3,260,880 calldata floor. Likewise, extreme `minGasLimit` metadata is accepted on L2 but cannot pass the L1 envelope.

For an initially unfinalizable withdrawal, `failedMessages` is absent, so a gas-feasible direct call is not yet authorized. This is not presented as a recovery path. The candidate barrier is scope and attacker model: the sender voluntarily chooses the payload and gas metadata, and `SCOPE.md:311,409` expressly excludes large-data/specific-gas message griefing that strands the sender's funds and needs an upgrade. No third party can mutate the committed message into this band.

## Evidence

- Tests: `test_largeZeroPayloadRejectedByL2TransactionCap`, `test_largeCalldataBracketsL2LimitAndStillFitsDirectReplay`, `test_largePayloadPortalBarrierIsBeforeDirectReplayBarrier`, `test_portalPayloadEdgeIsExecutionBoundAndBelowL2Edge`, `test_liveConstantsAndL2AcceptsExtremeMetadata`
- Output/model: `mirror/CATK-C/evidence/TEST-RESULTS.md`, `SYMBOLIC-INEQUALITIES.md`

## Classification and honest score

Live and deterministic, but self-inflicted and exactly known/excluded. Score: **-4** (`+2 permissionless +2 current +2 deployed PoC +1 cross-version -4 voluntary selection -4 known issue -3 no eligible impact`). Rejected.

