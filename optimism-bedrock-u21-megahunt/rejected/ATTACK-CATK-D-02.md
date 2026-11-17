# ATTACK-CATK-D-02 — Overwrite a victim or shared-relayer withdrawal proof

## Hypothesis

Because a withdrawal may be proven repeatedly, an attacker can submit the victim's genuine withdrawal against a trojan game and replace the victim or a shared relayer's existing honest proof, resetting its timer or making it nonfinalizable.

## Exact sequence executed

1. Load fixture f1, whose `(withdrawalHash, proofSubmitter)` slot contains a real honest game and timestamp at the L1 pin.
2. Create a trojan type-9 game from an unrelated attacker address.
3. Prove the exact same withdrawal and MPT proof as the attacker.
4. Compare the fixture submitter's game/timestamp before and after.

Test: `test_attackerProofCannotOverwriteExistingSubmitterProof` — pass. The attacker receives a separate slot; both victim values are unchanged.

Passive population evidence found a high-volume dedicated proving EOA (`0x431f...ddf5`, 135/487 events), but no authoritative attribution. Whether it is a shared service does not change mapping isolation.

## Barrier / kill

`OptimismPortal2.sol:483-484` stores `provenWithdrawals[withdrawalHash][msg.sender]`. The attacker cannot choose the second key. `finalizeWithdrawalTransactionExternalProof` lets anyone finalize using a valid submitter slot, but does not let anyone replace that slot.

No leaked key, privileged role, signature replay, or forwarder-confusion path was found. The only way to poison a shared relayer slot is for that relayer itself to select/sign the trojan proof, which collapses into CATK-D-01's voluntary tooling-selection inconvenience.

Decision: deterministic kill; no victim state transition and no eligible impact.
