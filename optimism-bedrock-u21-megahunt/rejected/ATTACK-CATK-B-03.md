# ATTACK-CATK-B-03 — forced failure changes StandardBridge ETH/ERC20 settlement

## Hypothesis

A third party forces withdrawal A into `failedMessages`, lets later bridge state consume its backing, and replays A into underflow, miscredit, theft, or permanent separation.

## Exact sequence tried

Used a real proven 0.012091417834329393 ETH bridge withdrawal as carrier. Its real EOA recipient was code-substituted only to reject the first delivery and, on replay, nest-finalize a real victim. Victims were (a) a real 2,000 ETH StandardBridge withdrawal and (b) a real `finalizeBridgeERC20` withdrawal. No proof slot was fabricated and every exploit-phase caller was `0x…CA7B`. Tests: `test_realStandardBridgeVictimForcedFailedThenSettlesExactly` and `test_realERC20BridgeVictimForcedFailedThenSettlesExactly`.

## Deterministic barrier

The primitive works: the victim portal hash finalizes and value (if any) moves to L1CDM while the message becomes failed. But arbitrary direct replay then pays the committed ETH recipient or exact ERC20 recipient, drains messenger custody, marks success, and rejects a second replay. The caller gains zero. ETH settlement is atomic (`StandardBridge.sol:239-260`); ERC20 liabilities use additive deposits and atomically subtract/transfer (`:272-299`), so valid later withdrawals commute.

## Evidence

- `mirror/CATK-B/test/CATK_B.t.sol`
- `mirror/CATK-B/evidence/fork-test-output.txt`
- `mirror/CATK-B/evidence/source-barriers.md`

Honest score: **-1** (+9 reachability/PoC/repeatability/cross-contract; -4 known mechanic, -3 retryable inconvenience, -3 no eligible impact). Rejected.
