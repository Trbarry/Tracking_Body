# ATTACK-CATK-T1-11 — tx.origin proposer through wrapper

## Hypothesis

An attacker launders creator identity through a wrapper or sibling entrypoint, creates a
super-permissioned game that starts `DEFENDER_WINS`, and immediately supplies an authoritative root.

## Original condition and changed precondition

The safety condition is “only the configured proposer may create the game.” v9 enforces
`tx.origin == proposer()` and initializes defender-wins
(`SuperPermissionedDisputeGame.sol:51-72`). L7 had not traced a wrapper; this mutation explicitly
changes `msg.sender` while retaining the attacker origin and repeats it on all four live factories.

## Exact sequence and result

Encode a valid per-chain super root at `anchor+1`. Attempt DGF type-5 creation directly from
`0xA11CE`, then through a newly deployed wrapper. All eight calls revert, including Soneium where
type 5 is respected. No game count/valid root transition is produced.

## Barrier and evidence

An arbitrary call graph cannot change transaction origin; only the configured proposer can pass.
Compromised/malicious proposer behavior is excluded, and the `tx.origin` design is acknowledged
(blacklist Part 2 item 8). Test
`test_T11_type5TxOriginGateRejectsDirectAndWrappedAttacker` passes at
`mirror/CATK-T1/test/FixRegressionCATKT1.t.sol:501`. Deterministic authorization kill; no candidate.

