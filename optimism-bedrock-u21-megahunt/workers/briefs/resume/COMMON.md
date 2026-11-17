# RESUME WAVE (2026-11-17) — common rules

Read, in this order, and obey: `/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/CADRE-LEGAL.md` (above, the outer
limit), then `ATTACK_CONTEXT.md` (rules, infra, output rule, deliverables, candidate template and score), then
`ATTACK-MATRIX.md` (73 kills with barriers: do NOT re-run a killed hypothesis unless you change its precondition with
new evidence), `CLOSURE-MAP.md` (C1-C17), `DEAD-ENDS-NO-REDO.md`, `LIVE-OBJECTS.md`, `SCOPE.md` 1.2-1.4 and 1.8.
All paths are under `/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/`.

Model: Opus lanes run on Opus 5.5 (CLAUDE.md exception, Mythos 5.2 quota until 2026-11-22 00:00 UTC); Codex lanes on
gpt-daybreak-blue-latest. State the model in your report.

Scope discipline: the target must be an in-scope asset (SCOPE.md 1.2: the listed OP Mainnet L1 contracts and their
implementations, op-node, op-reth, op-dispute-mon, Primacy of Impact) and the impact one of SCOPE.md 1.4. Third-party
contracts are never targets (CADRE-LEGAL 4). Privileged-only, future-only, known/acknowledged issues: kill with the
reason. Resources: 4 cores shared by ~8 workers — `forge test -j 1`, `CARGO_BUILD_JOBS=1`, at most one private anvil on
your lane's ports, chunked `eth_getLogs` through the local proxies only.

Deliverables exactly as ATTACK_CONTEXT.md with X = your lane id (`rejected/ATTACK-<X>-nn.md`,
`candidates/CAND-ATK-<X>-nn.md` only with a passing fork test, `test/poc/attack-wave/<X>/`,
`evidence/attack-wave/<X>/`, `workers/ATK-<X>-report.md`). Codex mirrors write only under `mirror/C<X>/`,
`rejected/ATTACK-C<X>-nn.md`, `candidates/CAND-C<X>-nn.md`, `workers/C<X>-report.md`, and do not read the Opus lane's
outputs (`workers/ATK-<X>*`, `test/poc/attack-wave/<X>/`, `evidence/attack-wave/<X>/`, `rejected/ATTACK-<X>-*`).
Final message <= 400 words: experiments executed (count), candidates with honest scores, top kills with barrier, the
single highest-value next experiment, and any line of work you stopped (and why).
