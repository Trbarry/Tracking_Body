# REJ-CF4-03 — Proxy or implementation initializer takeover

## Hypothesis

An upgrade leaves an implementation-active proxy with `_initialized == 0`, or an unlocked bare
implementation carries authority/balance that makes public initialization material.

## Falsification

Every modern implementation installation has a non-zero initializer byte in the post-block state.
StorageSetter resets are intra-transaction. Staged proxy intervals and two historical messenger
windows have implementation address zero, so calls cannot reach initializer logic. Among 102
observed implementation/helper addresses, all seven zero-byte cases are helper or constructor-only
contracts; no proxy authority was found. Current implementations are byte-255 locked except retired
legacy contracts with already-used initializer state. Exact reads and balances are in
`mirror/CF4/evidence/implementation-initializer-locks.json`.

## Verdict

Rejected. No material public initialization path reproduced.
