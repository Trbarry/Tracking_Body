# ATTACK-CATK-A-04 — previously critical trace-extension / zero-root findings

## Hypothesis

Old games might retain the known Kona faulty trace-extension or zero-initialized-tip behavior even
though the factory now uses a new prestate.

## Exact sequence tried

Direct-compared both deployed tag trees for `bin/client/src/single.rs` and
`crates/proof/proof/src/sync.rs`, and inspected the old tag's exact prologue.

## Barrier

There is no old→new diff. v1.7 already calls `prepare_derivation`, rejects claims before the safe
head and safe-head root mismatches, and permits zero-step trace extension only for the real agreed
root. Its `TipCursor` is initialized with `agreed_l2_output_root`, not zero. The known fixes predate
the old deployed prestate.

## Verdict

Deterministic source kill; blacklist findings 3.1.1/3.1.2 are not present in v1.7. Exploitability:
0/10.

