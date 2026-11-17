# ATK-CMP2 (COMPOSER-2, amplifier) — orchestrator note

Model: Opus 5.5 (CLAUDE.md exception). Status: STOPPED EARLY by a safety classifier partway through the
run. The worker did not continue that line of work and the orchestrator did not re-assign or re-phrase it.

Executed before the stop: reading of the attack-wave outputs; one passive read-only scan of OP Mainnet
L2CrossDomainMessenger `SentMessage` logs over L2 blocks 105,235,063..159,663,000 (35,543 messages;
lane C counted 35,579 withdrawals; the 36 difference fits withdrawals made without the messenger).
Script `scripts/attack-wave-CMP2/scan_sentmessage.py`, output `evidence/attack-wave/CMP2/op-l2cdm-sentmessage.json`.
Not analysed; no conclusion drawn.

Amplifications to a verdict: 0. New kills: 0. Candidates: 0. The barriers already recorded in
`ATTACK-MATRIX.md` for R1 (forced failure: known Trust M-1, retryable), R4 (allowance spend: user error,
~2.53 USDC), R5 (trojan games: known Cantina 2025-04 3.1.6) and R3 (sender-chosen bands) stand unchanged.
The COMPOSER-2 section of `workers/briefs/attack/COMPOSERS.md` is therefore INCOMPLETE.
