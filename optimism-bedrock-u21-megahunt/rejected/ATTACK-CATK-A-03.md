# ATTACK-CATK-A-03 — interop, Lagoon PostExec, and SDM fixes

## Hypothesis

The v1.7→v1.9 interop cycle, message validation, PostExec canonicality, or SDM refund fixes may
change a live old-prestate game's terminal root.

## Exact sequence tried

Reviewed commits `3db3be3`, `d2646b0`, `de34293`, `482a109`, `9a67c34`, `ec1e5f2`, `4958790`,
`187bb64`, `59cdf77`, `c3b34f1`, and `056afb5`; then checked deployed feature/activation state and
each live game's pinned timestamps.

## Barrier

Interop is disabled and there is no deployed dependency set. OP, Ink, and Unichain set Lagoon to
timestamp `1799683201` (`2027-01-11T16:00:01Z`), after the census timestamp `1794921779` and after
the fixed inputs of all live old-prestate games. These branches cannot execute in the target
proofs.

## Verdict

Deterministic activation kill. Exploitability for the scoped games: 0/10.

